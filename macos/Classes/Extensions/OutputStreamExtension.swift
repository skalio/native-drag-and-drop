//
//  OutputStreamExtension.swift
//  flutter_native_drag_n_drop
//
//  Created by Leon Hoppe on 27.04.22.
//

import Foundation

extension OutputStream {
  func write(data: Data) -> Int {
    return data.withUnsafeBytes {
      write($0.bindMemory(to: UInt8.self).baseAddress!, maxLength: data.count)
    }
  }
}
