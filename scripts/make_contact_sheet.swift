#!/usr/bin/env swift

import AppKit
import Foundation

guard CommandLine.arguments.count >= 4 else {
    fputs("Usage: make_contact_sheet.swift <image-dir> <output-path> <image>...\n", stderr)
    exit(2)
}

let imageDirectory = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
let outputURL = URL(fileURLWithPath: CommandLine.arguments[2])
let filenames = Array(CommandLine.arguments.dropFirst(3))

let columns = 3
let padding: CGFloat = 24
let gap: CGFloat = 18
let thumbWidth: CGFloat = 260
let labelHeight: CGFloat = 28
let thumbHeight: CGFloat = thumbWidth * 2688 / 1242
let cellWidth = thumbWidth
let cellHeight = thumbHeight + labelHeight
let rows = Int(ceil(Double(filenames.count) / Double(columns)))
let canvasSize = NSSize(
    width: padding * 2 + CGFloat(columns) * cellWidth + CGFloat(columns - 1) * gap,
    height: padding * 2 + CGFloat(rows) * cellHeight + CGFloat(rows - 1) * gap
)

let canvas = NSImage(size: canvasSize)
canvas.lockFocus()
NSColor(calibratedWhite: 0.97, alpha: 1).setFill()
NSRect(origin: .zero, size: canvasSize).fill()

let labelAttributes: [NSAttributedString.Key: Any] = [
    .font: NSFont.monospacedSystemFont(ofSize: 13, weight: .semibold),
    .foregroundColor: NSColor(calibratedWhite: 0.12, alpha: 1)
]

for (index, filename) in filenames.enumerated() {
    let imageURL = imageDirectory.appendingPathComponent(filename)
    guard let image = NSImage(contentsOf: imageURL) else {
        fputs("Unable to open image: \(imageURL.path)\n", stderr)
        exit(2)
    }

    let row = index / columns
    let column = index % columns
    let x = padding + CGFloat(column) * (cellWidth + gap)
    let top = canvasSize.height - padding - CGFloat(row) * (cellHeight + gap)
    let imageRect = NSRect(x: x, y: top - thumbHeight, width: thumbWidth, height: thumbHeight)
    let labelRect = NSRect(x: x, y: top - thumbHeight - labelHeight + 6, width: thumbWidth, height: labelHeight)

    NSColor.white.setFill()
    NSBezierPath(roundedRect: imageRect.insetBy(dx: -3, dy: -3), xRadius: 8, yRadius: 8).fill()
    image.draw(in: imageRect, from: .zero, operation: .sourceOver, fraction: 1)
    (filename as NSString).draw(in: labelRect, withAttributes: labelAttributes)
}

canvas.unlockFocus()

guard let tiffData = canvas.tiffRepresentation,
      let bitmap = NSBitmapImageRep(data: tiffData),
      let pngData = bitmap.representation(using: .png, properties: [:]) else {
    fputs("Unable to render contact sheet\n", stderr)
    exit(2)
}

try pngData.write(to: outputURL, options: [.atomic])
print(outputURL.path)
