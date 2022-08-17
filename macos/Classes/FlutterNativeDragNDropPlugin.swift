import AppKit
import FlutterMacOS
import UniformTypeIdentifiers

public class FlutterNativeDragNDropPlugin: NSObject, FlutterPlugin {
    
    //MARK: Variables
    static var channel: FlutterMethodChannel!
    static var filePromiseTasks: [String: [FilePromiseTask]] = [:]
    private var draggableViews: [String: DraggableView] = [:]
    private var dropTargetView: DropTargetView?
    
    //MARK: Plugin Init
    public static func register(with registrar: FlutterPluginRegistrar) {
        channel = FlutterMethodChannel(name: "flutter_native_drag_n_drop", binaryMessenger: registrar.messenger)
        let instance = FlutterNativeDragNDropPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "setDraggableView":
            setDraggableView(call, result: result)
        case "removeDraggableView":
            removeDraggableView(call, result: result)
        case "feedFileStream":
            feedFileStream(call, result: result)
        case "updateProgress":
            updateProgress(call, result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    //MARK: Method Calls
    private func setDraggableView(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let vc = NSApplication.shared.mainWindow?.contentViewController as? FlutterViewController else { return }
        setDropTargetView()
        
        let arguments = call.arguments as! Dictionary<String, Any>
        let id = arguments["id"] as! String
        let x = arguments["x"] as! Double
        let y = arguments["y"] as! Double
        let width = arguments["width"] as! Double
        let height = arguments["height"] as! Double
        let names = arguments["names"] as! [String]
        let fileNames = arguments["fileNames"] as? [String]
        let fileSizes = arguments["fileSizes"] as? [Int]
        var dragImage: NSImage?
        if let data = (arguments["image"] as? FlutterStandardTypedData) {
            dragImage = NSImage(data: data.data)
        }
        
        // flip the lower-left point of the view cause the coordinate origin in macOS is in the lower-left corner
        let origin = CGPoint(x: x, y: y + height).flip(in: vc.view.bounds)
        let size = CGSize(width: width, height: height)
        let frame = NSRect(origin: origin, size: size)
        
        let draggableView = DraggableView(frame: frame, id: id, dragImage: dragImage, names: names, fileNames: fileNames, fileSizes: fileSizes, channel: FlutterNativeDragNDropPlugin.channel)
        
        /*
        // only for debugging
        draggableView.wantsLayer = true
        draggableView.layer?.backgroundColor = NSColor.blue.withAlphaComponent(0.3).cgColor
         */
        
        draggableViews[id]?.removeFromSuperview()
        draggableViews[id] = draggableView
        vc.view.addSubview(draggableView)
    }
    
    private func removeDraggableView(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let arguments = call.arguments as! Dictionary<String, Any>
        let id = arguments["id"] as! String
        
        draggableViews[id]?.removeFromSuperview()
        draggableViews[id] = nil
    }
    
    private func setDropTargetView() {
        guard let vc = NSApplication.shared.mainWindow?.contentViewController as? FlutterViewController else { return }
        
        dropTargetView = DropTargetView(frame: vc.view.bounds, channel: FlutterNativeDragNDropPlugin.channel)
        dropTargetView!.autoresizingMask = [.width, .height]
        dropTargetView!.registerForDraggedTypes(NSFilePromiseReceiver.readableDraggedTypes.map { NSPasteboard.PasteboardType($0) } + [NSPasteboard.PasteboardType("public.folder")])
        vc.view.addSubview(dropTargetView!)
    }
    
    private func removeDropTargetView() {
        dropTargetView?.removeFromSuperview()
        dropTargetView = nil
    }
    
    private func feedFileStream(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let arguments = call.arguments as! Dictionary<String, Any>
        let id = arguments["id"] as! String
        let fileName = arguments["fileName"] as! String
        let status = arguments["status"] as! String
        
        guard let status = FilePromiseTask.FileStreamStatus(rawValue: status) else {
            result(FlutterError(code: "missingOrInvalidArg", message: "pass wrong status or missing file data", details: nil))
            return
        }
        
        if let filePromiseTasks = FlutterNativeDragNDropPlugin.filePromiseTasks[id] {
            let index = filePromiseTasks.firstIndex { t in
                return t.fileName == fileName
            }
            
            let fileData: Data? = (arguments["data"] as? FlutterStandardTypedData)?.data
            filePromiseTasks[index!].feedFileStream(data: fileData, status: status)
            
            if status == .ended {
                FlutterNativeDragNDropPlugin.filePromiseTasks[id]!.remove(at: index!)
                if FlutterNativeDragNDropPlugin.filePromiseTasks[id]!.isEmpty {
                    FlutterNativeDragNDropPlugin.filePromiseTasks.removeValue(forKey: id)
                }
            }
        }
    }
    
    private func updateProgress(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let arguments = call.arguments as! Dictionary<String, Any>
        let id = arguments["id"] as! String
        let fileName = arguments["fileName"] as! String
        let count = arguments["count"] as! Int
        
        if let filePromiseTasks = FlutterNativeDragNDropPlugin.filePromiseTasks[id] {
            let task = filePromiseTasks.first { t in
                return t.fileName == fileName
            }
            
            task!.updateProgress(unitCount: count)
        }
    }
}
