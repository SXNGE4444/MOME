import AppKit
import Foundation

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let iconset = root.appendingPathComponent("dist/MOME.iconset")
let output = root.appendingPathComponent("dist/MOME.icns")

try? FileManager.default.removeItem(at: iconset)
try FileManager.default.createDirectory(at: iconset, withIntermediateDirectories: true)

let specs: [(String, Int)] = [
    ("icon_16x16.png", 16),
    ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32),
    ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128),
    ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256),
    ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512),
    ("icon_512x512@2x.png", 1024)
]

func drawIcon(size: Int) throws -> Data {
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()

    NSColor(calibratedWhite: 0.97, alpha: 1).setFill()
    NSBezierPath(rect: NSRect(x: 0, y: 0, width: size, height: size)).fill()

    let inset = CGFloat(size) * 0.095
    let tile = NSRect(x: inset, y: inset, width: CGFloat(size) - inset * 2, height: CGFloat(size) - inset * 2)
    let path = NSBezierPath(roundedRect: tile, xRadius: CGFloat(size) * 0.185, yRadius: CGFloat(size) * 0.185)
    NSColor(calibratedWhite: 0.075, alpha: 1).setFill()
    path.fill()

    let fontSize = CGFloat(size) * 0.47
    let paragraph = NSMutableParagraphStyle()
    paragraph.alignment = .center
    let attrs: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: fontSize, weight: .black),
        .foregroundColor: NSColor.white,
        .paragraphStyle: paragraph
    ]
    let text = "M" as NSString
    let textRect = NSRect(x: 0, y: CGFloat(size) * 0.255, width: CGFloat(size), height: CGFloat(size) * 0.55)
    text.draw(in: textRect, withAttributes: attrs)

    let accentWidth = CGFloat(size) * 0.39
    let accentHeight = max(2, CGFloat(size) * 0.028)
    let accent = NSRect(
        x: (CGFloat(size) - accentWidth) / 2,
        y: CGFloat(size) * 0.20,
        width: accentWidth,
        height: accentHeight
    )
    NSColor(calibratedRed: 0.28, green: 0.88, blue: 0.62, alpha: 1).setFill()
    NSBezierPath(roundedRect: accent, xRadius: accentHeight / 2, yRadius: accentHeight / 2).fill()

    image.unlockFocus()

    guard let tiff = image.tiffRepresentation,
          let rep = NSBitmapImageRep(data: tiff),
          let png = rep.representation(using: .png, properties: [:]) else {
        throw NSError(domain: "MOMEIcon", code: 1)
    }
    return png
}

for (name, size) in specs {
    try drawIcon(size: size).write(to: iconset.appendingPathComponent(name))
}

let process = Process()
process.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
process.arguments = ["-c", "icns", iconset.path, "-o", output.path]
try process.run()
process.waitUntilExit()
guard process.terminationStatus == 0 else {
    throw NSError(domain: "MOMEIcon", code: Int(process.terminationStatus))
}

try? FileManager.default.removeItem(at: iconset)
print(output.path)
