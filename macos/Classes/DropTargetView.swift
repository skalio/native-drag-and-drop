//
//  DropTargetView.swift
//  flutter_native_drag_n_drop
//
//  Created by Leon Hoppe on 15.03.22.
//

import AppKit
import FlutterMacOS

class DropTargetView: NSView {
    
    //MARK: Variables
    private let channel: FlutterMethodChannel

    //MARK: Init
    init(frame frameRect: NSRect, channel: FlutterMethodChannel) {
        self.channel = channel
        super.init(frame: frameRect)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    //MARK: Functions
    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        channel.invokeMethod("draggingEntered", arguments: (sender.draggingLocation.flip(in: bounds).toList()))
        return .move
    }

    override func draggingUpdated(_ sender: NSDraggingInfo) -> NSDragOperation {
        channel.invokeMethod("draggingUpdated", arguments: (sender.draggingLocation.flip(in: bounds).toList()))
        return .move
    }

    override func draggingExited(_ sender: NSDraggingInfo?) {
        channel.invokeMethod("draggingExited", arguments: nil)
    }

    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        channel.invokeMethod("performDragOperation", arguments: nil)
        return true
    }
}
