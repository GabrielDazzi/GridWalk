#!/bin/zsh
# Pulls new string keys from the last Mac + iOS builds into the String Catalogs.
# Build both first (see CONTRIBUTING.md), then run this and add the Portuguese values.
set -e
cd "$(dirname "$0")/.."
derived="${1:-build/dd}"
intermediates="$derived/Build/Intermediates.noindex"

sync() {
  local catalog="$1" pattern="$2"
  local files=("${(@f)$(find "$intermediates" -path "$pattern" -name '*.stringsdata' | grep -v 'GeneratedAssetSymbols\|ExtractedAppShortcutsMetadata')}")
  if [ -z "${files[1]}" ]; then
    echo "no stringsdata for $catalog, build first" >&2
    exit 1
  fi
  local args=()
  for file in $files; do args+=(--stringsdata "$file"); done
  xcrun xcstringstool sync "$catalog" $args
  echo "synced $catalog (${#files} files)"
}

sync "Grid Walk/Localizable.xcstrings" "*/Grid Walk.build/Objects-normal/*"
sync "Grid Walk Widget/Localizable.xcstrings" "*/Grid Walk Widget.build/Objects-normal/*"
sync "GridWalkKit/Sources/GridWalkKit/Resources/Localizable.xcstrings" "*/GridWalkKit-t.build/Objects-normal/*"
sync "GridWalkKit/Sources/GridWalkDesign/Resources/Localizable.xcstrings" "*/GridWalkDesign-t.build/Objects-normal/*"
