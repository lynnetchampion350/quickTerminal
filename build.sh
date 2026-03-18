#!/bin/bash
set -e
cd "$(dirname "$0")"

echo "Building SystemTrayTerminal..."
swiftc -O systemtrayterminal.swift -o SystemTrayTerminal -framework Cocoa -framework Carbon -framework AVKit -framework WebKit \
  -Xlinker -sectcreate -Xlinker __FONTS -Xlinker __jbmono -Xlinker _JetBrainsMono-LightItalic-terminal.ttf \
  -Xlinker -sectcreate -Xlinker __FONTS -Xlinker __monocraft -Xlinker _Monocraft-terminal.ttf \
  -Xlinker -sectcreate -Xlinker __DATA -Xlinker __readme -Xlinker README.md \
  -Xlinker -sectcreate -Xlinker __DATA -Xlinker __commands -Xlinker COMMANDS.md \
  -Xlinker -sectcreate -Xlinker __DATA -Xlinker __changelog -Xlinker CHANGELOG.md
echo "Done! Run with: ./SystemTrayTerminal"

echo ""
echo "Running tests..."
swift tests.swift
echo ""
