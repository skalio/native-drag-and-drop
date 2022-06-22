//
//  FilePromiseTask.swift
//  flutter_native_drag_n_drop
//
//  Created by Leon Hoppe on 27.04.22.
//

import Foundation
import FlutterMacOS

class FilePromiseTask: NSObject, NSFilePromiseProviderDelegate {
    
    enum FileStreamStatus: String {
        case writing = "kWriting"
        case ended = "kEnded"
    }
    
    //MARK: Variables
    private let id: String
    private let channel: FlutterMethodChannel
    private(set) var fileName: String
    private(set) var fileSize: Int
    private var fileStreamHandler: ((Data?, FileStreamStatus) -> Void)?
    private var progress: Progress?
    
    private lazy var workQueue: OperationQueue = {
        let providerQueue = OperationQueue()
        providerQueue.qualityOfService = .userInitiated
        return providerQueue
    }()
    
    //MARK: Init
    init(id: String, channel: FlutterMethodChannel, fileName: String, fileSize: Int) {
        self.id = id
        self.channel = channel
        self.fileName = fileName
        self.fileSize = fileSize
        super.init()
    }
    
    //MARK: Functions
    public func feedFileStream(data: Data?, status: FileStreamStatus) {
        fileStreamHandler?(data, status)
    }
    
    public func updateProgress(unitCount: Int) {
        guard let progress = progress else { return }

        progress.completedUnitCount = Int64(unitCount)
    }
    
    public func filePromiseProvider(_ filePromiseProvider: NSFilePromiseProvider, fileNameForType fileType: String) -> String {
        let userInfo = filePromiseProvider.userInfo as! [String: Any?]
        let fileName = userInfo["fileName"] as! String
        return fileName
    }
    
    public func filePromiseProvider(_ filePromiseProvider: NSFilePromiseProvider, writePromiseTo url: URL, completionHandler: @escaping (Error?) -> Void) {
        let userInfo = filePromiseProvider.userInfo as! [String: Any?]
        let id = userInfo["id"]
        let fileName = userInfo["fileName"] as! String
        let urlString = url.absoluteString
        
        let outputStream = OutputStream(url: url, append: true)
        outputStream!.open()
        
        var p = Progress(parent: nil, userInfo: [.fileOperationKindKey: Progress.FileOperationKind.downloading, .fileURLKey: url])
        p = Progress(parent: nil, userInfo: [.fileOperationKindKey: Progress.FileOperationKind.downloading, .fileURLKey: url])
        p.isCancellable = false
        p.isPausable = false
        p.kind = .file
        p.totalUnitCount = Int64(fileSize)
        p.publish()
        self.progress = p
        
        fileStreamHandler = { (data, status) in
            switch status {
            case .ended:
                outputStream!.close()
                self.progress?.unpublish()
                completionHandler(nil)
                return
            case .writing:
                guard let data = data else  {
                    completionHandler(CocoaError(CocoaError.fileWriteUnknown))
                    return
                }
                _ = outputStream!.write(data: data)
            }
        }
        
        channel.invokeMethod("fileStreamCallback", arguments: ["id": id, "fileName": fileName, "url": urlString])
    }
    
    public func operationQueue(for filePromiseProvider: NSFilePromiseProvider) -> OperationQueue {
        return workQueue
    }
}
