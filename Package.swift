// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SpeechToTextMac",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "SpeechToTextMac",
            targets: ["SpeechToTextMac"]
        )
    ],
    targets: [
        .executableTarget(
            name: "SpeechToTextMac",
            path: "SpeechToTextMac"
        )
    ]
)
