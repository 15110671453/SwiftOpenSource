//
//  MongoJSONConvertables.swift
//  swiftpPackageDescription
//
//  Created by admindyn on 2018/1/25.
//
import PerfectLib
import Foundation

/// This file is meant for MongoDB specific JSONConvertible types

extension Date: JSONConvertible {
    public func jsonEncodedString() throws -> String {
        return "{\"$date\":{\"$numberLong\":\"\(Int64(self.timeIntervalSince1970 * 1000))\"}}"
    }
}
