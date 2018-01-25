BSON.swift

import PerfectCBSON
import Foundation


//BSON Error
public enum BSONError:Error {
    /*
     使用BSONError 调用该相关值方法 传入 我们的指定rawvalue  将原始值构造为 枚举的一个 枚举值
     不像以前的枚举一样直接定义枚举值  这样枚举值 是不是多元化了、
     棒极了
     */
    case syntaxError(String)

}




public class BSON:CustomStringConvertible{
    /*这个是继承 CustomStringConvertible 协议必须实现的一个存储属性 或者 说 计算属性*/
    public var description: String  {
        
        return asString
        
    }
    
    var doc:UnsafeMutablePointer<bson_t>?
    
    /*
     返回一个json string  扩展后的
     */
    
    //MARK:默认BSON 返回json对象的这个值字符串
    public var asString: String {
        var length = 0
        guard let doc = self.doc,let data = bson_as_json(doc,&length) else {
            
            return ""
        }
        //MARK:使用defer 语句 释放资源
        
        /*
        在错误处理过程中 无论陈功执行try语句还是有错误发生 并执行catch 代码块 都会执行defer 语句块 来释放资源
         类似 java finally 语句块
         */
        defer {
            bson_free(data)
        }
        
        return String(validatingUTF8:data) ?? ""
        
    }
    
    
    public var asArrayString:String {
        
        var length = 0
        
        guard let doc = self.doc,let data = bson_array_as_json(doc,&length) else {
            return ""
            
        }
        
        defer {
            bson_free(data)
        }
        
        return String(validatingUTF8:data) ?? ""
        
        
        
        
    }
    
    public var asBytes:[UInt8] {
        
        var ret = [UInt8]()
        
        guard let doc = self.doc,let data = bson_get_data(doc) else { return ret }
        
        let length = Int(doc.pointee.len)
        
        for i in 0..<length {
            
        ret.append(data[i])
            
        }
        
        return ret
        
        
        
    }
    
    //NARK:BSON 初始化方法
    public init() {
        
        doc = bson_new()
    }
    
    public init(bytes:[UInt8]) {
        
        doc = bson_new_from_data(bytes, bytes.count)
        
        
    }
    
    public init(json:String)throws {
        
        
        var error = bson_error_t()
        
        guard let doc = bson_new_from_json(json, json.utf8.count, &error) else {
            /*一种特殊闭包 情况 尾随闭包
             尾随闭包是一个书写在函数括号之后的闭包表达式，函数支持将其作为最后一个参数调用
             */
            let messgae = withUnsafePointer(to: &error.message){
                // 第一层闭包 $0
                $0.withMemoryRebound(to: CChar.self, capacity: 0) {
                    // 第二层闭包 $0
                    String(validatingUTF8:$0) ?? "Unknown error while parsing JSON"
                    
                }
            }
            throw BSONError.syntaxError(messgae)
            
            /*注意 上面的尾随闭包 抛出异常 需要 throw 语句 默认 在 {} 语句后 回车换行*/
        
        }
        
        self.doc = doc
        
        
        
    }
    
    
    public init(document:BSON) {
        
        doc = bson_copy(document.doc)
        
        
    }
    
    public init(map:[String:Any?]) {
        
        doc = bson_new()
        
        for (key,val) in map {
            
            if val is Int {
                
                append(key: key, int: val as! Int)
                
            } else if val is Double {
                
                append(key: key, double: val as!Double)
                
                
            } else if val is Bool {
                
            append(key: key, bool: val as! Bool)
                
            } else if val is [Int8] {
                
                append(key: key, bytes: val as! [UInt8])
                
                
            } else if val is [String:Any] {
                
                append(key: key, document:BSON(map:  val as!  [String:Any]))
                
                
            }else if val  is Date {
                
                append(key: key, date: val as! Date)
                
                
            } else if let val = val {
                
                append(key: key, string: "\(val)")
                
            } else {
                
                append(key: key)
            }
        }
    }
    
    init(rawBson:UnsafeMutablePointer<bson_t>?) {
        
        doc = rawBson
        
    }
    
    //MARK:deinit
    
    deinit {
       close()
    }
    
    
    //MARK:deinit close
    
    func close()  {
        
        guard let doc = self.doc else {
            
            return
            
        }
        
        bson_destroy(doc)
        
        self.doc = nil
        
        
    }
    
    //MATK:Func-append
    
    public func append(key k:String) -> Bool {
        
        guard let doc = self.doc else {
            
            return false
        }
        
        return bson_append_null(doc, k, -1)
        
        
        
    }
    
    public func append(key k:String,oid:bson_oid_t) -> Bool {
        
        guard let doc = self.doc else {
            
            return false
        }
        
        var cpy = oid
        
        return bson_append_oid(doc, k, -1, &cpy)
        
    }
    
    public func append(key k:String,int:Int)->Bool {
        
        guard let doc = self.doc else {
            
            return false
            
        }
          //MARK:这里我们看到 swift的 Int - Int64 互转 以及String的 处理使用
        return bson_append_int64(doc, k, -1, Int64(int))
    }
    
    public func append(key k:String,int32:Int32) -> Bool {
        
        guard let doc = self.doc else {
            
            return false
            
        }
        
        return bson_append_int32(doc, k, -1, int32)
        
        
        
    }
    
   public func append(key k:String,dateTime:Int64) -> Bool {
        
        guard let doc = self.doc else {
            
            return false
            
        }
        
        return bson_append_date_time(doc, k, -1, dateTime)
        
        
    }
    
   public func append(key k:String,date:Date) -> Bool {
        let ms = date.timeIntervalSince1970 * 1000
        
        return append(key: k, dateTime: Int64(ms))
        
    }
    
    
    func append(key k:String,time:time_t) -> Bool {
        
        
        guard let doc = self.doc else {
            return false
            
        }
        
        return bson_append_time_t(doc, k, -1, time)
        
    }
    
    func append(key k:String,double:Double) -> Bool {
        
        guard let doc = self.doc else {
            
            return false
            
        }
        
        return bson_append_double(doc, k, -1, double)
        
        
    }
    
    
    func append(key k:String,bool:Bool) -> Bool {
        
        guard let doc = self.doc else {
            return false
            
        }
        
        return bson_append_bool(doc, k, -1, bool)
        
    }
    
    func append(key k:String,string:String) -> Bool {
        
        guard let doc = self.doc else {
            return false
            
        }
        
        return bson_append_utf8(doc,k,-1,string,-1)
        
    }
    
    func append(key k:String,bytes:[UInt8]) -> Bool {
        
        
        guard let doc = self.doc else {
            
            return false
            
        }
        
        return bson_append_binary(doc, k, -1, BSON_SUBTYPE_BINARY, bytes, UInt32(bytes.count))
        
        
        
    }
    
    func append(key k:String,regex:String,options:String) -> Bool {
        
        guard let doc = self.doc else {
            return false
            
        }
        
        return bson_append_regex(doc, k, -1, regex, options)
    }
    
    func append(key k:String,document:BSON) -> Bool {
        
        guard let sDoc = self.doc,let dDoc = document.doc else {
            
            return false
            
        }
        
        return bson_append_document(sDoc, k, -1, dDoc)
        
    }
    
    //MARK:以上是基本方法
    
    //MARK:返回都少个键值对
    public func countKeys() ->Int {
        
        guard let doc = self.doc else {
            return 0
            
        }
        
        return Int(bson_count_keys(doc))
        
    }
    //MARK:检查键值存在
    
    func hasField(key k:String) -> Bool {
        
        guard let doc = self.doc else { return false }
        
        return bson_has_field(doc, k)
    }
    
    func appendArrayBegin(key k:String,child:BSON) -> Bool {
        guard let doc = self.doc,let cdoc = child.doc else {
            
            return false
            
        }
        
        return bson_append_array_begin(doc,k,-1,cdoc)
        
    }
    
    public func appendArrayEnd(child: BSON) -> Bool {
        guard let doc = self.doc, let cdoc = child.doc else {
            return false
        }
        return bson_append_array_end(doc, cdoc)
    }
    
    public func appendDocumentBegin(key k: String, child: BSON) -> Bool {
        guard let doc = self.doc, let cdoc = child.doc else {
            return false
        }
        return bson_append_document_begin(doc, k, -1, cdoc)
    }
    
    public func appendDocumentEnd(child: BSON) -> Bool {
        guard let doc = self.doc, let cdoc = child.doc else {
            return false
        }
        return bson_append_document_end(doc, cdoc)
    }
    //MARK:拼接 json？？
    public func concat(src: BSON) -> Bool {
        guard let doc = self.doc, let sdoc = src.doc else {
            return false
        }
        return bson_concat(doc, sdoc)
    }
    
    
    //MARK:内嵌一个结构体
     public struct OID:CustomStringConvertible {
        
        var oid:bson_oid_t?
        
        
        //遵守协议的一个结构体
        //和BSON 遵守的是同一个协议
        
        init(oid:bson_oid_t) {
            self.oid = oid
        }
        
        public init(_ string:String) {
            var  oid = bson_oid_t()
            
            bson_oid_init_from_string(&oid, string)
            
            self.oid = oid
            
            
        }
        
        public init() {
            
            var oid = bson_oid_t()
            
            bson_oid_init(&oid, nil)
            
            self.oid = oid
            
            
        }
        
        public static func newObjectId() -> String {
            
            return self.init().description
            
        }
        
        
        public var description: String {
            
            
            let up = UnsafeMutablePointer<Int8>.allocate(capacity: 25)
            
            defer {
                up.deallocate(capacity: 25)
                
            }
            
            var oid = self.oid
            
            bson_oid_to_string(&oid!, up)
            
            
            //MARK:这个方法 私有 并且 放在BSON类 外 定义实现1
            
            return  ptr2Str(up, length: 25) ?? ""
            
            
            
            
        }
        
        
        
    }
    
}
//扩展BSON  并继承协议 扩展功能 为两个BSON对象 比较

//MARK:以下都是扩展类对象 遵守运算符协议 运算符 重载
//MARK:两个BSON对象 比较

extension BSON:Equatable {
    
    static public func ==(lhs:BSON,rhs:BSON) ->Bool {
        
        guard let ldoc = lhs.doc ,let rdoc = rhs.doc else {
            
            return false
            
        }
        
        let cmp = bson_compare(ldoc, rdoc)
        
        return cmp == 0
        
    }
}


extension BSON:Comparable {
    
    static public func<(lhs:BSON,rhs:BSON)->Bool {
        guard let ldoc = lhs.doc,let rdoc = rhs.doc else { return false }
        
        let cmp = bson_compare(ldoc, rdoc)
        
        return cmp < 0
        
        
    }
    
}

//MARK:这个方法 私有 并且 放在BSON类 外 定义实现2
private func ptr2Str(_ ptr:UnsafeMutablePointer<Int8>!,length:Int) -> String? {
    
    //MARK:BufferPointer
    
    var ary = Array(UnsafeBufferPointer(start:ptr,count:Int(length)))
    
    ary.append(0)
    
    return String(validatingUTF8:ary)
    
}


extension BSON {
    
    /// An underlying BSON value type.
    public enum BSONType: UInt32 {
        case
        eod           = 0x00,
        double        = 0x01,
        utf8          = 0x02,
        document      = 0x03,
        array         = 0x04,
        binary        = 0x05,
        undefined     = 0x06,
        oid           = 0x07,
        bool          = 0x08,
        dateTime      = 0x09,
        null          = 0x0A,
        regex         = 0x0B,
        dbpointer     = 0x0C,
        code          = 0x0D,
        symbol        = 0x0E,
        codewscope    = 0x0F,
        int32         = 0x10,
        timestamp     = 0x11,
        int64         = 0x12,
        maxKey        = 0x7F,
        minKey        = 0xFF
    }
    
    /// A BSONValue produced by iterating a document's keys.
    
    //MARK:从BSON 数据集中 取出的每条数据的 数据值 数据结构
    
    public struct BSONValue {
        private enum Base {
            case double(Double), string(String), bytes([UInt8])
        }
        /// The Mongo type for the value.
        public let type: BSONType
        
        public let double: Double
        public let string: String?
        public let bytes: [UInt8]?
        public let oid: OID?
        public let doc: BSON?
        
        /// The value as an int, if possible.
        public var int: Int? {
            return Int(double)
        }
        
        /// The value as an bool, if possible.
        public var bool: Bool {
            return double != 0.0
        }
        
        // these *bson_value_t are not to be saved or modified
        // the data is saved off into 1 or more base types depending on the value's type
        init?(value: UnsafePointer<bson_value_t>, iter: UnsafePointer<bson_iter_t>) {
            guard let type = BSONType(rawValue: value.pointee.value_type.rawValue) else {
                return nil
            }
            self.type = type
            switch type {
            case .eod,
                 .undefined, .null, .dbpointer,
                 .maxKey, .minKey:
                return nil
            case .double:
                double = value.pointee.value.v_double
                string = String(double)
                bytes = nil
                oid = nil
                doc = nil
            case .utf8:
                let utf8 = value.pointee.value.v_utf8
                bytes = nil
                string = ptr2Str(utf8.str, length: Int(utf8.len))
                double = Double(string ?? "0.0") ?? 0.0
                oid = nil
                doc = nil
            case .array:
                double = 0.0
                string = nil
                bytes = nil
                oid = nil
                doc = nil
            case .document:
                var data = UnsafePointer<UInt8>(bitPattern: 0)
                var len = 0 as UInt32
                bson_iter_document(iter, &len, &data)
                let bson = bson_new_from_data(data, Int(len))
                self.doc = BSON(rawBson: bson)
                bytes = nil
                string = nil
                double = 0.0
                oid = nil
            case .binary:
                let b = value.pointee.value.v_binary
                guard BSON_SUBTYPE_BINARY.rawValue == b.subtype.rawValue else {
                    return nil
                }
                bytes = Array(UnsafeBufferPointer(start: b.data, count: Int(b.data_len)))
                string = nil
                double = 0.0
                oid = nil
                doc = nil
            case .oid:
                let oid = value.pointee.value.v_oid
                self.oid = OID(oid: oid)
                string = self.oid?.description
                double = 0.0
                bytes = []
                doc = nil
            case .bool:
                double = value.pointee.value.v_bool ? 1.0 : 0.0
                string = nil
                bytes = nil
                oid = nil
                doc = nil
            case .dateTime:
                double = Double(value.pointee.value.v_datetime)
                string = nil
                bytes = nil
                oid = nil
                doc = nil
            case .regex:
                let regex = value.pointee.value.v_regex
                
                let rstr = String(validatingUTF8: regex.regex)
                let ostr = String(validatingUTF8: regex.options)
                
                double = 0.0
                string = "/\(rstr ?? "")/\(ostr ?? "")"
                bytes = nil
                oid = nil
                doc = nil
            case .code:
                let code = value.pointee.value.v_code
                bytes = nil
                string = ptr2Str(code.code, length: Int(code.code_len))
                double = 0.0
                oid = nil
                doc = nil
            case .symbol:
                let symbol = value.pointee.value.v_symbol
                bytes = nil
                string = ptr2Str(symbol.symbol, length: Int(symbol.len))
                double = 0.0
                oid = nil
                doc = nil
            case .codewscope:
                double = 0.0
                string = nil
                bytes = nil
                oid = nil
                doc = nil
            case .int32:
                double = Double(value.pointee.value.v_int32)
                string = String(Int32(double))
                bytes = nil
                oid = nil
                doc = nil
            case .timestamp:
                double = 0.0
                string = nil
                bytes = nil
                oid = nil
                doc = nil
            case .int64:
                double = Double(value.pointee.value.v_int64)
                string = String(Int64(double))
                bytes = nil
                oid = nil
                doc = nil
            }
        }
    }
    
    /// An iterator for BSON keys and values.
    
    //MARK:从BSON 数据集中 取出的每条数据的 数据值 数据结构 迭代器
    public struct Iterator {
        var iter = bson_iter_t()
        /// The type of the current value.
        public var currentType: BSONType? {
            var cpy = iter
            return BSONType(rawValue: bson_iter_type(&cpy).rawValue)
        }
        /// The key for the current value.
        public var currentKey: String? {
            var cpy = iter
            guard let c = bson_iter_key(&cpy) else {
                return nil
            }
            return String(validatingUTF8: c)
        }
        /// If the current value is an narray or document, this returns an iterator
        /// which can be used to walk it.
        public var currentChildIterator: Iterator? {
            guard let currentType = self.currentType else {
                return nil
            }
            switch currentType {
            case .array, .document:
                return Iterator(recursing: self.iter)
            default:
                return nil
            }
        }
        /// The BSON value for the current element.
        public var currentValue: BSONValue? {
            var cpy = iter
            guard let b = bson_iter_value(&cpy) else {
                return nil
            }
            return BSONValue(value: b, iter: &cpy)
        }
        
        private init() {}
        
        init?(bson: BSON) {
            guard bson_iter_init(&iter, bson.doc) else {
                return nil
            }
        }
        
        init?(recursing: bson_iter_t) {
            var c1 = recursing
            guard bson_iter_recurse(&c1, &iter) else {
                return nil
            }
        }
        
        /// Advance to the next element.
        /// Note that all iterations must begin by first calling next.
        public mutating func next() -> Bool {
            return bson_iter_next(&iter)
        }
        /// Located the key and advance the iterator to point at it.
        /// If `withCase` is false then the search will be case in-sensitive.
        public mutating func find(key: String, withCase: Bool = true) -> Bool {
            return withCase ? bson_iter_find(&iter, key) : bson_iter_find_case(&iter, key)
        }
        /// Follow standard MongoDB dot notation to recurse into subdocuments.
        /// Returns nil if the descendant is not found.
        public mutating func findDescendant(key: String) -> Iterator? {
            // NOTE:
            // the mongo-c function bson_iter_find_descendant was crashing on macOS
            guard !key.isEmpty else {
                return self
            }
            var keys = key.split(separator: ".").makeIterator()
            guard let subKey = keys.next() else {
                return nil
            }
            return findDescendant(key: String(subKey), keyIt: keys)
        }
        
        private mutating func findDescendant(key: String, keyIt: IndexingIterator<[String.SubSequence]>) -> Iterator? {
            guard find(key: String(key)) else {
                return nil
            }
            var it = keyIt
            if let subKey = it.next() {
                guard var sub = currentChildIterator else {
                    return nil
                }
                return sub.findDescendant(key: String(subKey), keyIt: it)
            }
            return self
        }
    }
    /// Return a new iterator for this document.
    public func iterator() -> Iterator? {
        return Iterator(bson: self)
    }
}









