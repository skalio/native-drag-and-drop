//
//  NSPointExtension.swift
//  flutter_native_drag_n_drop
//
//  Created by Leon Hoppe on 29.04.22.
//

import AppKit

extension NSPoint {
    
    // flip the point horizontally
    func flip(in frame: NSRect) -> NSPoint {
        let y = frame.size.height - self.y
        return NSPoint(x: self.x, y: y)
    }
    
    func toList() -> [CGFloat] {
        return [self.x, self.y]
    }
}

