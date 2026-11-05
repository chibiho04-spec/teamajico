// .ai（PDF互換）の1ページ目を透過PNGに書き出す
// 使い方: swift tools/render-logo.swift <入力.ai> <出力.png> <幅px>
import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

let args = CommandLine.arguments
guard args.count == 4, let width = Int(args[3]) else {
    FileHandle.standardError.write("usage: render-logo.swift <in.ai> <out.png> <width>\n".data(using: .utf8)!)
    exit(1)
}
let inURL = URL(fileURLWithPath: args[1])
let outURL = URL(fileURLWithPath: args[2])

guard let doc = CGPDFDocument(inURL as CFURL), let page = doc.page(at: 1) else {
    FileHandle.standardError.write("PDFとして開けません: \(args[1])\n".data(using: .utf8)!)
    exit(2)
}
// 作図範囲（ArtBox があればそれ、なければ MediaBox）
var box = page.getBoxRect(.artBox)
if box.isEmpty { box = page.getBoxRect(.cropBox) }
if box.isEmpty { box = page.getBoxRect(.mediaBox) }
let scale = CGFloat(width) / box.width
let height = Int((box.height * scale).rounded())

let cs = CGColorSpaceCreateDeviceRGB()
guard let ctx = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0,
                          space: cs, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
    exit(3)
}
ctx.clear(CGRect(x: 0, y: 0, width: width, height: height)) // 透明
ctx.interpolationQuality = .high
ctx.setAllowsAntialiasing(true)
ctx.scaleBy(x: scale, y: scale)
ctx.translateBy(x: -box.origin.x, y: -box.origin.y)
ctx.drawPDFPage(page)

guard let img = ctx.makeImage(),
      let dest = CGImageDestinationCreateWithURL(outURL as CFURL, UTType.png.identifier as CFString, 1, nil) else {
    exit(4)
}
CGImageDestinationAddImage(dest, img, nil)
if !CGImageDestinationFinalize(dest) { exit(5) }
print("wrote \(args[2]) \(width)x\(height)")
