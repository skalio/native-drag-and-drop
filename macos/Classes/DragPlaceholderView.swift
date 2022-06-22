//
//  DraggedView.swift
//  flutter_native_drag_n_drop
//
//  Created by Leon Hoppe on 23.03.22.
//

import AppKit

// Generic view to create drag image
class DragPlaceholderView: NSView {
    
    //MARK: Variables
    private var text: String
    
    //MARK: Init
    private override init(frame frameRect: NSRect) {
        fatalError("init(frame:) has not been implemented")
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    init(frame frameRect: NSRect, text: String) {
        self.text = text
        super.init(frame: frameRect)
        setupUI()
    }
    
    //MARK: Functions
    private func setupUI() {
        self.wantsLayer = true
        self.layer?.backgroundColor = .white
        
        let label = NSTextField(labelWithString: text)
        label.textColor = .black
        label.sizeToFit()
        addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        label.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
    }
    
    public func toImage() -> NSImage {
        let rep = bitmapImageRepForCachingDisplay(in: bounds)!
        cacheDisplay(in: bounds, to: rep)
        let image = NSImage(size: bounds.size)
        image.addRepresentation(rep)
        return image
    }
}
