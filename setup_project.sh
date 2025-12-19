#!/bin/bash

# 1. Organize Files into MVC Structure (If not already done)
echo "📂 Organizing Files..."

mkdir -p Agents Core Models Services Views/Screens Views/Components Tests Resources

# Move files if they exist in root (idempotent check)
[ -f DecoderAgent.swift ] && mv *Agent.swift Agents/
[ -f AmbrosiaManager.swift ] && mv AmbrosiaManager.swift Core/
[ -f Models.swift ] && mv Models.swift Models/
[ -f GeminiService.swift ] && mv GeminiService.swift Services/
[ -f ContentView.swift ] && mv ContentView.swift Views/Screens/
[ -f CameraScannerView.swift ] && mv CameraScannerView.swift Views/Components/
[ -f LiquidDesign.swift ] && mv LiquidDesign.swift Views/Components/
[ -f AmbrosiaTests.swift ] && mv AmbrosiaTests.swift Tests/
[ -f Info.plist ] && mv Info.plist Resources/
[ -f README.md ] && mv README.md Resources/

# 2. Check for XcodeGen
if ! command -v xcodegen &> /dev/null; then
    echo "⚙️  XcodeGen not found. Installing via Homebrew..."
    if ! command -v brew &> /dev/null; then
        echo "❌ Homebrew not found. Please install XcodeGen manually: 'brew install xcodegen'"
        exit 1
    fi
    brew install xcodegen
fi

# 3. Generate Project
echo "🛠  Generating Ambrosia.xcodeproj..."
xcodegen generate

echo "✅ Done! Open Ambrosia.xcodeproj to run."
