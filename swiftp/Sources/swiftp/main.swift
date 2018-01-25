//
//  main.swift
//  PerfectMongoDBPackageDescription
//
//  Created by admindyn on 2018/1/24.
//




print("mongodb-connecting")

let client = try! MongoClient(uri: "mongodb://localhost")

print("mongodb-connecting-fetchdb")

let db = client.getDatabase(name: "test")

print("mongodb-connecting-fetchcollection")

let collection = db.getCollection(name: "testcollection")

print("mongodb-connecting-collected-result")

let fnd = collection?.find(query: BSON())

// Initialize empty array to receive formatted results
var arr = [String]()

// The "fnd" cursor is typed as MongoCursor, which is iterable
for x in fnd! {
    arr.append(x.asString)
}


defer {
    collection?.close()
    db.close()
    client.close()
}





