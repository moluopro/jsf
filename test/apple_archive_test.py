#!/usr/bin/env python3
"""Check the embedded SwiftPM framework in a finished iOS or macOS app."""

import argparse
import plistlib
import re
import subprocess
from pathlib import Path


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("app", type=Path, help="Path to the built .app bundle")
    args = parser.parse_args()
    app = args.app.resolve()
    macos = (app / "Contents/Info.plist").is_file()
    contents = app / "Contents" if macos else app
    with (contents / "Info.plist").open("rb") as file:
        executable_name = plistlib.load(file)["CFBundleExecutable"]
    executable = (
        contents / "MacOS" / executable_name if macos else app / executable_name
    )
    framework = contents / "Frameworks/jsf.framework/jsf"
    if not framework.is_file():
        raise SystemExit(f"Missing embedded JSF framework: {framework}")

    bindings = Path(__file__).resolve().parents[1] / "lib/src/native_bindings.dart"
    required = set(re.findall(r"'(JSF_[A-Za-z0-9_]+)'", bindings.read_text()))
    if not required:
        raise SystemExit("No FFI symbols found in the Dart bindings")
    architectures = subprocess.check_output(
        ["xcrun", "lipo", "-archs", str(executable)], text=True
    ).split()
    for arch in architectures:
        # JSF is pure C. Depending on Flutter here can introduce an extra
        # SwiftPM wrapper framework into the host app.
        dependencies = subprocess.check_output(
            ["xcrun", "otool", "-arch", arch, "-L", str(framework)], text=True
        )
        if re.search(
            r"@rpath/(?:Flutter(?:MacOS)?|FlutterFramework[^/]*)\.framework/",
            dependencies,
        ):
            raise SystemExit(f"{arch}: JSF unnecessarily links a Flutter framework")

        # Inspect dyld's exports, not the debug symbols in a matching dSYM.
        exports = subprocess.check_output(
            ["xcrun", "dyld_info", "-arch", arch, "-exports", str(framework)],
            text=True,
        )
        exported = set(re.findall(r"\b_(JSF_[A-Za-z0-9_]+)\b", exports))
        missing = required - exported
        if missing:
            raise SystemExit(
                f"{arch}: missing FFI exports: " + ", ".join(sorted(missing))
            )

        # The embedded framework must be loaded at startup so that
        # DynamicLibrary.process() can resolve its functions.
        load_commands = subprocess.check_output(
            ["xcrun", "otool", "-arch", arch, "-l", str(executable)], text=True
        )
        if not re.search(
            r"cmd LC_LOAD_DYLIB\s+cmdsize \d+\s+name @rpath/jsf\.framework/"
            r"(?:Versions/[^/\s]+/)?jsf\s",
            load_commands,
        ):
            raise SystemExit(
                f"{arch}: app does not load the embedded JSF framework at startup"
            )
        print(f"{arch}: embedded JSF framework exports all {len(required)} FFI symbols")


if __name__ == "__main__":
    main()
