//
//  DraggableView.swift
//  flutter_native_drag_n_drop
//
//  Created by Leon Hoppe on 10.02.22.
//

import AppKit
import FlutterMacOS
import UniformTypeIdentifiers

class DraggableView: NSView, NSDraggingSource {
    
    //MARK: Variables
    private let id: String
    private let dragImage: NSImage?
    private let names: [String]
    private let fileNames: [String]?
    private let fileSizes: [Int]?
    private let channel: FlutterMethodChannel
    private var mouseDownLocation: CGPoint?
    private let kMouseDragTriggerOffset: CGFloat = 3
    
    //MARK: Init
    init(frame frameRect: NSRect, id: String, dragImage: NSImage?, names: [String], fileNames: [String]?, fileSizes: [Int]?, channel: FlutterMethodChannel) {
        self.id = id
        self.dragImage = dragImage
        self.names = names
        self.fileNames = fileNames
        self.fileSizes = fileSizes
        self.channel = channel
        super.init(frame: frameRect)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK: Functions
    override func mouseDown(with event: NSEvent) {
        super.mouseDown(with: event)
        mouseDownLocation = self.window?.contentView?.convert(event.locationInWindow, to: self)
    }
    
    
    override func mouseDragged(with event: NSEvent) {
        super.mouseDragged(with: event)
        
        var draggingItems: [NSDraggingItem] = []
        var filePromiseTasks: [FilePromiseTask] = []
        
        if let fileNames = fileNames, let fileSizes = fileSizes {
            for (n, fileName) in fileNames.enumerated() {
                let (item, task) = createFilePromiseDraggingItem(for: fileName, with: fileSizes[n])
                draggingItems.append(item)
                filePromiseTasks.append(task)
            }
        } else {
            for name in names {
                let item = createPasteboardItemDraggingItem(for: name)
                draggingItems.append(item)
            }
        }
        
        if !filePromiseTasks.isEmpty {
            FlutterNativeDragNDropPlugin.filePromiseTasks[id] = filePromiseTasks
        }
        
        if let mouseDownLocation = mouseDownLocation {
            let newPoint = self.window?.contentView?.convert(event.locationInWindow, to: self)
            let offset = NSPoint(x: newPoint!.x - mouseDownLocation.x, y: newPoint!.y - mouseDownLocation.y)
            
            if offset.x > kMouseDragTriggerOffset || offset.y > kMouseDragTriggerOffset {
                self.mouseDownLocation = nil
                self.beginDraggingSession(with: draggingItems, event: event, source: self)
            }
        }
        
        //self.beginDraggingSession(with: draggingItems, event: event, source: self)
    }
    
    private func createFilePromiseDraggingItem(for fileName: String, with fileSize: Int) -> (NSDraggingItem, FilePromiseTask) {
        let filePromiseTask = FilePromiseTask(id: id, channel: channel, fileName: fileName, fileSize: fileSize)
        var filePromise = NSFilePromiseProvider(fileType: "public.file-url", delegate: filePromiseTask)
        if #available(macOS 11.0, *) {
            filePromise = NSFilePromiseProvider(fileType: UTType.fileURL.identifier, delegate: filePromiseTask)
        }
        filePromise.userInfo = ["id": self.id, "fileName": fileName]
        
        let draggingItem = NSDraggingItem(pasteboardWriter: filePromise)
        var draggingImage = DragPlaceholderView(frame: CGRect(origin: bounds.origin, size: CGSize(width: 300, height: bounds.height)), text: fileName).toImage()
        if let dragImage = self.dragImage {
            draggingImage = dragImage
        }
        
        let mainWindow = NSApplication.shared.mainWindow!
        let mouseLocation = mainWindow.mouseLocationOutsideOfEventStream
        let localMouseLocation = mainWindow.contentViewController!.view.convert(mouseLocation, to: self)
        draggingItem.setDraggingFrame(NSRect(origin: localMouseLocation, size: draggingImage.size), contents: draggingImage)
        
        return (draggingItem, filePromiseTask)
    }
    
    private func createPasteboardItemDraggingItem(for name: String) -> NSDraggingItem {
        let pasteboardItem = NSPasteboardItem()
        pasteboardItem.setString("", forType: NSPasteboard.PasteboardType("public.folder"))
        
        let draggingItem = NSDraggingItem(pasteboardWriter: pasteboardItem)
        var draggingImage = DragPlaceholderView(frame: CGRect(origin: bounds.origin, size: CGSize(width: 300, height: bounds.height)), text: name).toImage()
        if let dragImage = self.dragImage {
            draggingImage = dragImage
        }
        
        let mainWindow = NSApplication.shared.mainWindow!
        let mouseLocation = mainWindow.mouseLocationOutsideOfEventStream
        let localMouseLocation = mainWindow.contentViewController!.view.convert(mouseLocation, to: self)
        draggingItem.setDraggingFrame(NSRect(origin: localMouseLocation, size: draggingImage.size), contents: draggingImage)
        
        return draggingItem
    }
    
    //MARK: NSDraggingSource Overrides
    func draggingSession(_ session: NSDraggingSession, sourceOperationMaskFor context: NSDraggingContext) -> NSDragOperation {
        switch context {
        case .outsideApplication:
            return .copy
        case .withinApplication:
            return .move
        @unknown default:
            return .generic
        }
    }
    
    func draggingSession(_ session: NSDraggingSession, willBeginAt screenPoint: NSPoint) {
        channel.invokeMethod("draggingBegin", arguments: ["id": id, "position": (screenPoint.flip(in: NSScreen.main!.frame).toList())])
    }
    
    func draggingSession(_ session: NSDraggingSession, movedTo screenPoint: NSPoint) {
        channel.invokeMethod("draggingMoved", arguments: ["id": id, "position": (screenPoint.flip(in: NSScreen.main!.frame).toList())])
    }
    
    func draggingSession(_ session: NSDraggingSession, endedAt screenPoint: NSPoint, operation: NSDragOperation) {
        channel.invokeMethod("draggingEnded", arguments: ["id": id, "position": (screenPoint.flip(in: NSScreen.main!.frame).toList())])
        
        // remove filePromiseTask from dictionary if drag ended within application, otherwise it would be live forever in memory
        if let mainWindow = NSApplication.shared.windows.first {
            if mainWindow.frame.contains(screenPoint) {
                FlutterNativeDragNDropPlugin.filePromiseTasks.removeValue(forKey: id)
            }
        }
    }
}
