import GridWalkDesign
import GridWalkKit
import SwiftUI

struct CalendarResultText: View {
    let result: CalendarResult

    var body: some View {
        Group {
            switch result {
            case .added(let count):
                Text("Added \(count) events")
            case .failed(let error):
                Text(error.localizedDescription)
            }
        }
        .font(.caption)
        .foregroundStyle(Theme.secondaryText)
    }
}
