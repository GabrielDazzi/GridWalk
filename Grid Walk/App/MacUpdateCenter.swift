#if os(macOS)
import AppKit
import Darwin
import Foundation
import GridWalkKit

// asks GitHub for a newer direct download and swaps the app in place
@MainActor
@Observable
final class MacUpdateCenter {
    private(set) var release: AppRelease?
    private(set) var phase: Phase = .idle
    private var appModel: AppModel?
    private var loop: Task<Void, Never>?

    enum Phase: Equatable {
        case idle
        case checking
        case ready
        case downloading
        case installing
        case failed
    }

    // App Store copies are updated by the store. Xcode builds must not replace themselves.
    static var canReplaceThisCopy: Bool {
        guard !isStoreBuild, !isDeveloperBuild else { return false }
        let folder = (Bundle.main.bundlePath as NSString).deletingLastPathComponent
        return FileManager.default.isWritableFile(atPath: folder)
    }

    static var isStoreBuild: Bool {
        guard let receipt = Bundle.main.appStoreReceiptURL else { return false }
        return FileManager.default.fileExists(atPath: receipt.path)
    }

    static var isDeveloperBuild: Bool {
        let path = Bundle.main.bundlePath
        return path.contains("DerivedData") || path.contains("/Library/Developer/")
    }

    func bind(_ model: AppModel) {
        appModel = model
        guard loop == nil else { return }
        loop = Task { await run() }
    }

    func checkNow() async {
        await check()
    }

    func install() async {
        guard let release, Self.canReplaceThisCopy else {
            phase = .failed
            return
        }
        phase = .downloading
        do {
            let (file, response) = try await URLSession.shared.download(from: release.diskImageURL)
            guard let http = response as? HTTPURLResponse,
                (200..<300).contains(http.statusCode),
                let finalURL = http.url,
                ReleaseLookup.allowsDownloadRedirect(from: finalURL)
            else {
                phase = .failed
                return
            }
            let disk = FileManager.default.temporaryDirectory.appendingPathComponent("GridWalk-update.dmg")
            try? FileManager.default.removeItem(at: disk)
            try FileManager.default.moveItem(at: file, to: disk)
            if let expected = release.byteCount {
                let values = try disk.resourceValues(forKeys: [.fileSizeKey])
                guard values.fileSize.map(Int64.init) == expected else {
                    try? FileManager.default.removeItem(at: disk)
                    phase = .failed
                    return
                }
            }
            phase = .installing
            try MacUpdateInstaller.replaceRunningApp(withDiskImage: disk)
        } catch {
            phase = .failed
        }
    }

    private func run() async {
        guard !Self.isStoreBuild else { return }
        while !Task.isCancelled {
            if appModel?.preferences.checksForAppUpdates == true {
                await check()
            }
            try? await Task.sleep(for: .seconds(60 * 60))
        }
    }

    private func check() async {
        guard phase != .downloading, phase != .installing else { return }
        guard let url = ReleaseLookup.latestURL() else { return }
        phase = .checking
        do {
            let current = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0"
            var request = URLRequest(url: url)
            request.setValue("GridWalk/\(current)", forHTTPHeaderField: "User-Agent")
            request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                phase = .failed
                return
            }
            // no published release yet
            if http.statusCode == 404 {
                release = nil
                phase = .idle
                return
            }
            guard http.statusCode == 200,
                let finalURL = http.url,
                ReleaseLookup.allowsDownload(from: finalURL)
            else {
                phase = .failed
                return
            }
            release = try ReleaseLookup.newerRelease(current: current, json: data)
            phase = release == nil ? .idle : .ready
        } catch {
            phase = .failed
        }
    }

}

private enum MacUpdateInstaller {
    // quits after a detached script mounts the disk image and copies the new app over this one
    static func replaceRunningApp(withDiskImage disk: URL) throws {
        let script = FileManager.default.temporaryDirectory
            .appendingPathComponent("gridwalk-update-\(ProcessInfo.processInfo.processIdentifier).sh")
        try installerScript.write(to: script, atomically: true, encoding: .utf8)
        try DetachedShell.spawn(
            executable: "/bin/sh",
            arguments: [
                script.path,
                Bundle.main.bundlePath,
                disk.path,
                "\(ProcessInfo.processInfo.processIdentifier)",
            ]
        )
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(400))
            NSApp.terminate(nil)
        }
    }

    // waits until this process is gone, then swaps the bundle and opens it
    private static let installerScript = """
        #!/bin/sh
        set -eu
        app="$1"
        dmg="$2"
        pid="$3"
        i=0
        while kill -0 "$pid" 2>/dev/null; do
          i=$((i + 1))
          if [ "$i" -gt 150 ]; then exit 1; fi
          sleep 0.2
        done
        mount=$(mktemp -d /tmp/gridwalk-update.XXXXXX)
        hdiutil attach "$dmg" -nobrowse -readonly -mountpoint "$mount"
        src=$(find "$mount" -maxdepth 2 -name '*.app' -print -quit)
        if [ -z "$src" ]; then
          hdiutil detach "$mount" || true
          exit 1
        fi
        stage="$app.gridwalk-next"
        previous="$app.gridwalk-previous"
        rm -rf "$stage"
        ditto "$src" "$stage"
        xattr -dr com.apple.quarantine "$stage" || true
        hdiutil detach "$mount" || true
        rmdir "$mount" || true
        rm -rf "$previous"
        mv "$app" "$previous"
        if mv "$stage" "$app"; then
          rm -rf "$previous"
        else
          mv "$previous" "$app"
          exit 1
        fi
        open "$app"
        """
}

private enum DetachedShell {
    static func spawn(executable: String, arguments: [String]) throws {
        var pid: pid_t = 0
        var attributes: posix_spawnattr_t?
        guard posix_spawnattr_init(&attributes) == 0 else { throw CocoaError(.fileWriteUnknown) }
        defer { posix_spawnattr_destroy(&attributes) }
        // new session so quitting the app doesn't take the installer down with it
        guard posix_spawnattr_setflags(&attributes, Int16(POSIX_SPAWN_SETSID)) == 0 else {
            throw CocoaError(.fileWriteUnknown)
        }

        let argv = [executable] + arguments
        var copies: [UnsafeMutablePointer<CChar>] = []
        defer {
            for copy in copies {
                free(copy)
            }
        }
        for argument in argv {
            guard let copy = strdup(argument) else { throw CocoaError(.fileWriteUnknown) }
            copies.append(copy)
        }
        var cargv: [UnsafeMutablePointer<CChar>?] = copies.map { $0 }
        cargv.append(nil)
        let status = cargv.withUnsafeMutableBufferPointer { buffer in
            posix_spawn(&pid, executable, nil, &attributes, buffer.baseAddress, nil)
        }
        guard status == 0 else { throw CocoaError(.fileWriteUnknown) }
    }
}
#endif
