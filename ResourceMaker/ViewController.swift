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

    init(_ row:Int, _ line:Int) {
        self.row = row
        self.line = line
    }

    func showGrids(image:NSImage) {
        print("show grids")
    }

    func generateTiles(image: NSImage) {
        tiles.removeAll()
        let vStride = image.size.width / CGFloat(row!)
        let hStride = image.size.height / CGFloat(line!)
        print("\(vStride),\(hStride)")
        for i in 0...Int(row!)-1 {
            for j in 0...Int(line!)-1 {
                let size = NSSize(width: vStride, height: hStride)
                let archor = CGPoint(x:CGFloat(i)*vStride, y:CGFloat(j)*hStride)
                print("\(size),\(archor)")
                let tile = image.getTileSquare32x(pos: archor, size: size)
                tiles.append(tile!)
            }
        }
    }

    func outputAtlas(url: NSURL) {

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

    func getTileSquare32x(pos: CGPoint, size: NSSize) -> NSImage? {
        let tile = NSMakeRect(pos.x, pos.y, size.width, size.height)

        guard let rep = self.bestRepresentation(for: tile, context: nil, hints: nil) else {
            return nil
        }
        let img = NSImage(size:NSSize(width:32, height:32))
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
}

class ViewController: NSViewController {
    @IBOutlet weak var ivMain: NSImageView!
    @IBOutlet weak var rowCount: NSTextField!
    @IBOutlet weak var lineCount: NSTextField!

    let tileGenerator = TileGenerator(1,1)
    var picImport: NSImage?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    @IBAction func preview(_ sender: AnyObject) {
        self.tileGenerator.row = Int(rowCount.intValue)
        self.tileGenerator.line = Int(lineCount.intValue)
        print("\(rowCount.intValue), \(lineCount.intValue)")

        if ((picImport) != nil) {
            tileGenerator.showGrids(image: picImport!)
            tileGenerator.generateTiles(image: picImport!)
        }
        ivMain.image = tileGenerator.tiles[0]
    }

    @IBAction func btnImport(_ sender: AnyObject) {
        let rpFilePicker: NSOpenPanel = NSOpenPanel()

        rpFilePicker.allowsMultipleSelection = false
        rpFilePicker.canChooseFiles = true
        rpFilePicker.canChooseDirectories = false

        rpFilePicker.runModal()

        let chosenFile = rpFilePicker.url

        if ((chosenFile) != nil) {
            picImport = NSImage(contentsOf: chosenFile!)

            ivMain.image = picImport
            print("\(chosenFile)")

        }
    }
}
