#!/usr/bin/env swift

import AppKit
import CoreGraphics
import Foundation

guard CommandLine.arguments.count == 3 else {
    fputs("Usage: flatten_png.swift <input-png> <output-png>\n", stderr)
    exit(2)
}

let inputURL = URL(fileURLWithPath: CommandLine.arguments[1])
let outputURL = URL(fileURLWithPath: CommandLine.arguments[2])

guard let image = NSImage(contentsOf: inputURL),
      let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
    fputs("Unable to open image: \(inputURL.path)\n", stderr)
    exit(2)
}

let width = cgImage.width
let height = cgImage.height
let colorSpace = CGColorSpaceCreateDeviceRGB()
let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipLast.rawValue)

guard let context = CGContext(
    data: nil,
    width: width,
    height: height,
    bitsPerComponent: 8,
    bytesPerRow: 0,
    space: colorSpace,
    bitmapInfo: bitmapInfo.rawValue
) else {
    fputs("Unable to create output context\n", stderr)
    exit(2)
}

let rect = CGRect(x: 0, y: 0, width: width, height: height)
context.setFillColor(NSColor.white.cgColor)
context.fill(rect)
context.interpolationQuality = .high
context.draw(cgImage, in: rect)

guard let flattenedImage = context.makeImage() else {
    fputs("Unable to flatten image\n", stderr)
    exit(2)
}

let bitmap = NSBitmapImageRep(cgImage: flattenedImage)
guard let pngData = bitmap.representation(using: .png, properties: [:]) else {
    fputs("Unable to encode PNG\n", stderr)
    exit(2)
}

try pngData.write(to: outputURL, options: [.atomic])
