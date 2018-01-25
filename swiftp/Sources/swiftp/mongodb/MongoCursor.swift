//
//  MongoCursor.swift
//  swiftpPackageDescription
//
//  Created by admindyn on 2018/1/25.
//
import PerfectCMongo

/// The Mongo Cursor interface
public class MongoCursor: Sequence, IteratorProtocol {
    
    var ptr = OpaquePointer(bitPattern: 0)
    
    /// JSON string representation.
    public var jsonString: String {
        
        var results = [String]()
        
        for object in self {
            results.append(object.asString)
        }
        
        return "[\(results.joined(separator: ","))]"
    }
    
    init(rawPtr: OpaquePointer?) {
        self.ptr = rawPtr
    }
    
    deinit {
        close()
    }
    
    /// Close and destroy current cursor
    public func close() {
        if self.ptr != nil {
            mongoc_cursor_destroy(self.ptr!)
            self.ptr = nil
        }
    }
    
    /// - returns: next document if available, else nil
    public func next() -> BSON? {
        guard let ptr = self.ptr else {
            return nil
        }
        var bson = UnsafePointer<bson_t>(nil as OpaquePointer?)
        if mongoc_cursor_next(ptr, &bson) {
            return NoDestroyBSON(rawBson: UnsafeMutablePointer<bson_t>(mutating: bson))
        }
        return nil
    }
}
