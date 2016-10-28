//
//  ViewController.swift
//  ResourceMaker
//
//  Created by ding.shengge on 10/26/16.
//  Copyright © 2016 ding.shengge. All rights reserved.
//

import Cocoa

class TileGenerator {
    var row:Int?
    var line:Int?
    var tiles: [NSImage] = []
    let fileManager = FileManager.default

    func cutLine() -> NSBezierPath {
        let path = NSBezierPath()
        path.lineWidth = 1.0
        path.lineJoinStyle = .roundLineJoinStyle
        path.lineCapStyle = .roundLineCapStyle
        return path
    }

    init(_ row:Int, _ line:Int) {
        self.row = row
        self.line = line
    }

    func generateTiles(image: NSImage, dstSize: NSSize) {
        tiles.removeAll()
        let vStride = image.size.width / CGFloat(row!)
        let hStride = image.size.height / CGFloat(line!)
        print("\(vStride),\(hStride)")
        for j in 0...Int(line!)-1 {
            for i in 0...Int(row!)-1 {
                let size = NSSize(width: vStride, height: hStride)
                let archor = CGPoint(x:CGFloat(i)*vStride, y:CGFloat(j)*hStride)
                print("\(size),\(archor)")
                let tile = image.getTileSquare32x(pos: archor, size: size, dstSize: dstSize)
                tiles.append(tile!)
            }
        }
        
        // draw vertical lines
        image.lockFocus()
        let cutLine = self.cutLine()
        for i in 1...Int(row!-1) {
            cutLine.move(to: NSPoint(x: CGFloat(i)*vStride, y: 0))
            cutLine.line(to: NSPoint(x: CGFloat(i)*vStride, y: image.size.height))
        }
        
        for i in 1...Int(line!-1) {
            cutLine.move(to: NSPoint(x: 0, y: CGFloat(i)*hStride))
            cutLine.line(to: NSPoint(x: image.size.width, y: CGFloat(i)*hStride))
        }
        cutLine.close()

        NSColor.black.set()
        cutLine.stroke()

        image.unlockFocus()
    }

    func outputAtlas(dir: URL, basename: String) {
        let atlas = dir.appendingPathComponent(basename + ".atlas")
        do {
            try fileManager.createDirectory(at: atlas, withIntermediateDirectories: true,
                                            attributes: [:])
        } catch {
            return
        }
        for (i, tile) in tiles.enumerated() {
            let outFile = atlas.appendingPathComponent("\(i).png")

            do {
                try tile.savePNGRepresentationToURL(url: outFile)
            } catch {
                return
            }
        }
    }
}

extension NSImage {

    var height: CGFloat {
        return self.size.height
    }

    var width: CGFloat {
        return self.size.width
    }

    var PNGRepresentation: NSData? {
        if let tiff = self.tiffRepresentation, let tiffData = NSBitmapImageRep(data: tiff) {
            return tiffData.representation(using: NSPNGFileType, properties: [:]) as NSData?
        }

        return nil
    }


    func getTileSquare32x(pos: CGPoint, size: NSSize, dstSize: NSSize) -> NSImage? {
        let tile = NSMakeRect(pos.x, pos.y, size.width, size.height)

        guard let rep = self.bestRepresentation(for: tile, context: nil, hints: nil) else {
            return nil
        }
        let img = NSImage(size:dstSize)
        img.lockFocus()
        defer { img.unlockFocus() }

        if (rep.draw(in: NSMakeRect(0, 0, img.size.width, img.size.height),
                 from: tile,
                 operation: NSCompositingOperation.copy,
                 fraction: CGFloat(1.0),
                 respectFlipped: false,
                 hints: [:])) {
            return img
        }

        return nil
    }
    
    func savePNGRepresentationToURL(url: URL) throws {
        if let png = self.PNGRepresentation {
            try png.write(to: url, options: .atomicWrite)
        }
    }
}

class ViewController: NSViewController {
    @IBOutlet weak var ivMain: NSImageView!
    @IBOutlet weak var rowCount: NSTextField!
    @IBOutlet weak var lineCount: NSTextField!
    @IBOutlet weak var atlasName: NSTextField!
    @IBOutlet weak var tileSize: NSTextField!

    var tileGenerator: TileGenerator?
    var inputFile: URL?
    var outputDir: URL?

    override func viewDidLoad() {
        super.viewDidLoad()
        tileGenerator = TileGenerator(1,1)
        rowCount.intValue = 3
        lineCount.intValue = 4
        tileSize.intValue = 32
        atlasName.stringValue = "Sample"
        // Do any additional setup after loading the view.
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    func updateTiles() {
        let picImport = NSImage(contentsOf: inputFile!)
        let finalSize = NSSize(width: Int(tileSize.intValue), height: Int(tileSize.intValue))
        if ((picImport) != nil) {
            tileGenerator?.generateTiles(image: picImport!, dstSize: finalSize)
        }
        
        ivMain.image = picImport
    }

    @IBAction func preview(_ sender: AnyObject) {
        self.tileGenerator?.row = Int(rowCount.intValue)
        self.tileGenerator?.line = Int(lineCount.intValue)

        if ((self.tileGenerator?.row!)! <= 1 || (self.tileGenerator?.line!)! <= 1) {
            return
        }

        if (inputFile == nil) {
            return
        }

        self.updateTiles()
    }

    @IBAction func btnImport(_ sender: AnyObject) {
        let rpFilePicker: NSOpenPanel = NSOpenPanel()

        rpFilePicker.allowsMultipleSelection = false
        rpFilePicker.canChooseFiles = true
        rpFilePicker.canChooseDirectories = false
        rpFilePicker.runModal()

        inputFile = rpFilePicker.url

        if ((inputFile) != nil) {
            let picImport = NSImage(contentsOf: inputFile!)
            //ivMain.imageScaling = NSImageScaling.scaleAxesIndependently
            ivMain.image = picImport
        }
    }

    @IBAction func imageExport(_ sender: AnyObject) {
        let rpFilePicker: NSOpenPanel = NSOpenPanel()
        
        rpFilePicker.allowsMultipleSelection = false
        rpFilePicker.canChooseFiles = false
        rpFilePicker.canChooseDirectories = true
        rpFilePicker.runModal()
        
        outputDir = rpFilePicker.url
        let basename = atlasName.stringValue
        self.updateTiles()
        tileGenerator?.outputAtlas(dir: outputDir!, basename: basename)
    }
}
