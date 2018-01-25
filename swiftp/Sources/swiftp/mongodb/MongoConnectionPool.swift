//
//  MongoConnectionPool.swift
//  swiftpPackageDescription
//
//  Created by admindyn on 2018/1/25.
//

import PerfectCMongo
import Foundation

//MARK:这个类 实现定义文件代码 比较少
/*
 大部分都在MongoClient 与 MongoCollection 中 已经定义了
 */

public class MongoClientPool {
    
    var ptr = OpaquePointer(bitPattern:0)
    
    public init(uri:String) {
        
        let uriPointer = mongoc_uri_new(uri)
        
        ptr = mongoc_client_pool_new(uriPointer)
        
        
    }
    
    deinit {
        if ptr != nil {
        mongoc_client_pool_destroy(ptr)
        }
    }
    
    public func tryPopClient() -> MongoClient? {
        
        let clientPointer = mongoc_client_pool_try_pop(ptr)
        
        if clientPointer != nil {
            return MongoClient(pointer: mongoc_client_pool_pop(clientPointer))
        }
        return nil
        
        
    }
    
    public func popClient() -> MongoClient {
        return MongoClient(pointer: mongoc_client_pool_pop(ptr))
    }
    
    public func pushClient(_ client: MongoClient) {
        mongoc_client_pool_push(ptr, client.ptr)
        client.ptr = nil
    }
    
    /**
     *  Automatically pops a client, makes it available within the block and pushes it back.
     *
     *  - parameter block: block to be executed with popped client
     */
    public func executeBlock(_ block: (_ client: MongoClient) -> Void) {
        let client = popClient()
        block(client)
        pushClient(client)
    }
    
}






















