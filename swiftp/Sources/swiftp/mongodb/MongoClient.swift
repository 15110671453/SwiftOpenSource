//
//  MongoClient.swift
//  swiftpPackageDescription
//
//  Created by admindyn on 2018/1/25.
//


import PerfectCMongo

public enum MongoResult {
    
    case success
    
    case error(UInt32,UInt32,String)
    
    case replyDoc(BSON)
    
    case replyInt(Int)
    
    case replyCollection(MongoCollection)
    
    static func fromError(_ error:bson_error_t)-> MongoResult {
        
        var vError = error
        
        let message = withUnsafePointer(to: &vError.message) {
            
            return $0.withMemoryRebound(to: CChar.self, capacity: 0) {
                
                String(validatingUTF8:$0) ?? "unknown error"
                
            }
            
        }
        
        
        return .error(error.domain, error.code, message)
        
        
    }
    
}

public enum MongoClientError:Error {
    
    case initError(String)
    
}


public class MongoClient {
    
    var ptr  = OpaquePointer(bitPattern:0)
    
    //MARK:临时类型 起别名 要用public 标注 否则作为函数返回值类型 报错
    
    public typealias Result = MongoResult
    
    public init(uri:String) throws {
        
        //MARK:建立连接
        
        guard let ptr = mongoc_client_new(uri) else {
            
            throw MongoClientError.initError("Could not parse URI '\(uri)'")
            
            
        }
        
        
        
        self.ptr = ptr
    }
    
    
    init(pointer:OpaquePointer?) {
        ptr = pointer
    }
    
    
    deinit {
        close()
    }
    //MARK:关闭数据库连接
    public func close() {
        
        guard let ptr = self.ptr else {
            return
            
        }
        mongoc_client_destroy(ptr)
        
        self.ptr = nil
        
    
    }
    
    //MARK:仅返回 数据库连接下的 指定数据库
    
    public func getDatabase(name databaseName:String) -> MongoDatabase {
        
        return MongoDatabase(client:self,databaseName:databaseName)
    }
    
    //MARK:返回当前数据库连接下 某个数据库的 某个数据集
    public func geiCollection(databaseName:String,collectionName:String) -> MongoCollection {
        
        return  MongoCollection(client: self, databaseName: databaseName, collectionName: collectionName)
    }
    
    public func serverStatus() -> Result {
        
        var error = bson_error_t()
        
        let readPrefs = mongoc_read_prefs_new(MONGOC_READ_PRIMARY)
        
        defer {
            mongoc_read_prefs_destroy(readPrefs)
        }
        
        let bson = BSON()
        
        guard let doc = bson.doc else {
            return .error(1, 1, "Invalid BSON doc")
            
        }
        
        guard mongoc_client_get_server_status(self.ptr, readPrefs, doc, &error) else { return Result.fromError(error) }
        
    
        
        return .replyDoc(bson)
        
        
        
        
    }
    
    
    
    
    
}







