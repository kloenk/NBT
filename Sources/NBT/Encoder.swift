//
//  Encoder.swift
//  Ecnoder
//
//  Created by Finn Behrens on 14.08.21.
//

import Foundation
import Combine

public class NBTEncoder {
    
    init(_ rootKeyName: String? = nil) {
        self.name = rootKeyName
    }
    
    var name: String?
    // TODO: compression
    // TODO: arrays
    
    public func encode<T: Encodable>(_ value: T) throws -> Data {
        let nbtEncoding = NBTEncoding()
        try value.encode(to: nbtEncoding)
        // TODO: rootKeyName
        print(nbtEncoding.data.data)
        
        if let name = name {
            return nbtEncoding.data.data.toData(name)
        } else {
            return nbtEncoding.data.data.toData()
        }
    }
}

extension NBTEncoder: TopLevelEncoder {
    public typealias Output = Data
}

fileprivate struct NBTEncoding: Encoder {
    
    var codingPath: [CodingKey]
    
    var userInfo: [CodingUserInfoKey : Any] = [:]
    
    var data: NBTData
    
    init(to data: NBTData = NBTData(), codingPath path: [CodingKey] = []) {
        self.codingPath = path
        self.data = data
    }
    
    func container<Key>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> where Key : CodingKey {
        let container = NBTKeyedEncoding<Key>(to: data, codingPath: codingPath)
        return KeyedEncodingContainer(container)
    }
    
    func unkeyedContainer() -> UnkeyedEncodingContainer {
        return NBTUnkeyedEncoding(to: data, codingPath: codingPath)
    }
    
    func singleValueContainer() -> SingleValueEncodingContainer {
        return NBTSingleValueEncoding(to: data, codingPath: codingPath)
    }
    
    fileprivate class NBTData {
        var data: NBT
        
        init(data: NBT = .boxed(BoxedNBT())) {
            self.data = data
        }
        
        func addForKey(key: String, _ value: NBT) throws {
            switch self.data {
            case .boxed(let boxed):
                switch boxed.nbt {
                case .compound(var compound):
                    compound[key] = value
                case .end:
                    boxed.nbt = .compound([key: value])
                default:
                    throw NBTEncodingError.wrongValueType
                }
            default:
                throw NBTEncodingError.wrongValueType
            }
        }
        
        func append(_ value: NBT) throws {
            // TODO: check for type
            switch self.data {
            case .boxed(let box):
                switch box.nbt {
                case .list(var list):
                    list.append(value)
                default:
                    throw NBTEncodingError.wrongValueType
                }
            default:
                throw NBTEncodingError.wrongValueType
            }
        }
        
        func encode(_ value: NBT) throws {
            switch self.data {
            case .boxed(let box):
                box.nbt = value
            default:
                throw NBTEncodingError.wrongValueType
            }
        }
        
        var count: Int? {
            switch self.data {
            case .boxed(let boxed):
                switch boxed.nbt {
                case .list(let list):
                    return list.count
                    // TODO: count for compound?
                default:
                    return nil
                }
            default:
                return nil
            }
        }
        
    }
}

fileprivate struct NBTKeyedEncoding<Key: CodingKey>: KeyedEncodingContainerProtocol {
    init(to data: NBTEncoding.NBTData, codingPath path: [CodingKey] = []) {
        self.data = data
        self.codingPath = path
    }
    
    var data : NBTEncoding.NBTData
    
    var codingPath: [CodingKey]
    
    mutating func encodeNil(forKey key: Key) throws {
        // Nil is Nil, encoding nothing
    }
    
    mutating func encode(_ value: Bool, forKey key: Key) throws {
        let nbt = NBT(booleanLiteral: value)
        try data.addForKey(key: key.stringValue, nbt)
    }
    
    mutating func encode(_ value: String, forKey key: Key) throws {
        let nbt = NBT(stringLiteral: value)
        try data.addForKey(key: key.stringValue, nbt)
    }
    
    mutating func encode(_ value: Double, forKey key: Key) throws {
        let nbt = NBT.double(value)
        try data.addForKey(key: key.stringValue, nbt)
    }
    
    mutating func encode(_ value: Float, forKey key: Key) throws {
        let nbt = NBT.float(value)
        try data.addForKey(key: key.stringValue, nbt)
    }
    
    mutating func encode(_ value: Int, forKey key: Key) throws {
        try self.encode(Int64(value), forKey: key)
    }
    
    mutating func encode(_ value: Int8, forKey key: Key) throws {
        let nbt = NBT.byte(value)
        try data.addForKey(key: key.stringValue, nbt)
    }
    
    mutating func encode(_ value: Int16, forKey key: Key) throws {
        let nbt = NBT.short(value)
        try data.addForKey(key: key.stringValue, nbt)
    }
    
    mutating func encode(_ value: Int32, forKey key: Key) throws {
        let nbt = NBT.int(value)
        try data.addForKey(key: key.stringValue, nbt)
    }
    
    mutating func encode(_ value: Int64, forKey key: Key) throws {
        let nbt = NBT.long(value)
        try data.addForKey(key: key.stringValue, nbt)
    }
    
    mutating func encode(_ value: UInt, forKey key: Key) throws {
        try self.encode(Int64(value), forKey: key)
    }
    
    mutating func encode(_ value: UInt8, forKey key: Key) throws {
        try self.encode(Int8(value), forKey: key)
    }
    
    mutating func encode(_ value: UInt16, forKey key: Key) throws {
        try self.encode(Int16(value), forKey: key)
    }
    
    mutating func encode(_ value: UInt32, forKey key: Key) throws {
        try self.encode(Int32(value), forKey: key)
    }
    
    mutating func encode(_ value: UInt64, forKey key: Key) throws {
        try self.encode(Int64(value), forKey: key)
    }
    
    mutating func encode<T>(_ value: T, forKey key: Key) throws where T : Encodable {
        let nbt: NBT = .boxed(BoxedNBT())
        try data.addForKey(key: key.stringValue, nbt)
        let nbtData = NBTEncoding.NBTData(data: nbt)
        let encoding = NBTEncoding(to: nbtData, codingPath: codingPath + [key])
        try value.encode(to: encoding)
    }
    
    mutating func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type, forKey key: Key) -> KeyedEncodingContainer<NestedKey> where NestedKey : CodingKey {
        let nbt: NBT = .boxed(BoxedNBT(.compound([:])))
        try? data.addForKey(key: key.stringValue, nbt)
        let nbtData = NBTEncoding.NBTData(data: nbt)
        let container = NBTKeyedEncoding<NestedKey>(to: nbtData, codingPath: codingPath + [key])
        return KeyedEncodingContainer(container)
    }
    
    mutating func nestedUnkeyedContainer(forKey key: Key) -> UnkeyedEncodingContainer {
        let nbt: NBT = .boxed(BoxedNBT(.compound([:])))
        try? data.addForKey(key: key.stringValue, nbt)
        let nbtData = NBTEncoding.NBTData(data: nbt)
        return NBTUnkeyedEncoding(to: nbtData, codingPath: codingPath + [key])
    }
    
    mutating func superEncoder() -> Encoder {
        let superKey = Key(stringValue: "super")!
        return superEncoder(forKey: superKey)
    }
    
    mutating func superEncoder(forKey key: Key) -> Encoder {
        let nbt: NBT = .boxed(BoxedNBT())
        try? data.addForKey(key: key.stringValue, nbt)
        let nbtData = NBTEncoding.NBTData(data: nbt)
        return NBTEncoding(to: nbtData, codingPath: codingPath + [key])
    }
    
}

fileprivate struct NBTUnkeyedEncoding: UnkeyedEncodingContainer {
    
    var data: NBTEncoding.NBTData
    
    init(to data: NBTEncoding.NBTData, codingPath path: [CodingKey]) {
        self.data = data
        self.codingPath = path
    }
    
    var codingPath: [CodingKey]
    
    var count: Int {
        self.data.count ?? 0
    }
    
    mutating func encodeNil() throws {
        // Nil is nil, doing nothing
    }
    
    mutating func encode(_ value: Bool) throws {
        let nbt = NBT(booleanLiteral: value)
        try data.append(nbt)
    }
    
    mutating func encode(_ value: String) throws {
        try data.append(.string(value))
    }
    
    mutating func encode(_ value: Double) throws {
        try data.append(.double(value))
    }
    
    mutating func encode(_ value: Float) throws {
        try data.append(.float(value))
    }
    
    mutating func encode(_ value: Int) throws {
        try encode(Int64(value))
    }
    
    mutating func encode(_ value: Int8) throws {
        try data.append(.byte(value))
    }
    
    mutating func encode(_ value: Int16) throws {
        try data.append(.short(value))
    }
    
    mutating func encode(_ value: Int32) throws {
        try data.append(.int(value))
    }
    
    mutating func encode(_ value: Int64) throws {
        try data.append(.long(value))
    }
    
    mutating func encode(_ value: UInt) throws {
        try encode(Int64(value))
    }
    
    mutating func encode(_ value: UInt8) throws {
        try encode(Int8(value))
    }
    
    mutating func encode(_ value: UInt16) throws {
        try encode(Int16(value))
    }
    
    mutating func encode(_ value: UInt32) throws {
        try encode(Int32(value))
    }
    
    mutating func encode(_ value: UInt64) throws {
        try encode(Int64(value))
    }
    
    mutating func encode<T>(_ value: T) throws where T : Encodable {
        let nbt: NBT = .boxed(BoxedNBT())
        try data.append(nbt)
        let nbtData = NBTEncoding.NBTData(data: nbt)
        // TODO: is the codingPath correct?
        let encoding = NBTEncoding(to: nbtData, codingPath: codingPath)
        try value.encode(to: encoding)
    }
    
    mutating func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type) -> KeyedEncodingContainer<NestedKey> where NestedKey : CodingKey {
        let nbt = NBT.boxed(BoxedNBT())
        try? data.append(nbt)
        let nbtData = NBTEncoding.NBTData(data: nbt)
        // TODO: is the codingPath correct?
        let container = NBTKeyedEncoding<NestedKey>(to: nbtData, codingPath: codingPath)
        return KeyedEncodingContainer(container)
    }
    
    mutating func nestedUnkeyedContainer() -> UnkeyedEncodingContainer {
        let nbt = NBT.boxed(BoxedNBT())
        try? data.append(nbt)
        let nbtData = NBTEncoding.NBTData(data: nbt)
        // TODO: is the codingPath correct?
        return NBTUnkeyedEncoding(to: nbtData, codingPath: codingPath)
    }
    
    mutating func superEncoder() -> Encoder {
        let nbt: NBT = .boxed(BoxedNBT())
        try? data.append(nbt)
        let nbtData = NBTEncoding.NBTData(data: nbt)
        // TODO: is the codingPath correct?
        return NBTEncoding(to: nbtData, codingPath: codingPath)
    }
    
}

fileprivate struct NBTSingleValueEncoding: SingleValueEncodingContainer {
    private var data:NBTEncoding.NBTData
    
    init(to data: NBTEncoding.NBTData, codingPath path: [CodingKey] = []) {
        self.data = data
        self.codingPath = path
    }
    
    var codingPath: [CodingKey]
    
    mutating func encodeNil() throws {
        // What to do?
    }
    
    mutating func encode(_ value: Bool) throws {
        let nbt = NBT(booleanLiteral: value)
        try data.encode(nbt)
    }
    
    mutating func encode(_ value: String) throws {
        try data.encode(.string(value))
    }
    
    mutating func encode(_ value: Double) throws {
        try data.encode(.double(value))
    }
    
    mutating func encode(_ value: Float) throws {
        try data.encode(.float(value))
    }
    
    mutating func encode(_ value: Int) throws {
        try encode(Int64(value))
    }
    
    mutating func encode(_ value: Int8) throws {
        try data.encode(.byte(value))
    }
    
    mutating func encode(_ value: Int16) throws {
        try data.encode(.short(value))
    }
    
    mutating func encode(_ value: Int32) throws {
        try data.encode(.int(value))
    }
    
    mutating func encode(_ value: Int64) throws {
        try data.encode(.long(value))
    }
    
    mutating func encode(_ value: UInt) throws {
        try encode(Int64(value))
    }
    
    mutating func encode(_ value: UInt8) throws {
        try encode(Int8(value))
    }
    
    mutating func encode(_ value: UInt16) throws {
        try encode(Int16(value))
    }
    
    mutating func encode(_ value: UInt32) throws {
        try encode(Int32(value))
    }
    
    mutating func encode(_ value: UInt64) throws {
        try encode(Int64(value))
    }
    
    mutating func encode<T>(_ value: T) throws where T : Encodable {
        let nbtEncoding = NBTEncoding(to: data, codingPath: codingPath)
        try value.encode(to: nbtEncoding)
    }
}

/*fileprivate struct NBTEncoding: Encoder {
    var codingPath: [CodingKey]
    
    var userInfo: [CodingUserInfoKey : Any] = [:]
    
    var data: NBTData
    
    init(to encodedData: NBTData = NBTData(), codingPath path: [CodingKey] = []) {
        self.data = encodedData
        self.codingPath = path
    }
    
    func container<Key>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> where Key : CodingKey {
        var container = NBTKeyedEncoding<Key>(to: data)
        container.codingPath = codingPath
        return KeyedEncodingContainer(container)
    }
    
    func unkeyedContainer() -> UnkeyedEncodingContainer {
        let array = NBTData.NBTArray()
        data.arrays["list"] = array
        return NBTUnkeyedEncoding(to: array, codingPath: codingPath)
    }
    
    func singleValueContainer() -> SingleValueEncodingContainer {
        return NBTSingleValueEncoding(to: data, codingPath: codingPath)
    }
    
    func finish() throws -> Data {
        return try data.finish()
    }
    
    fileprivate class NBTData {
        init(data: Data = Data()) {
            self.data = data
            self.compounds = [:]
            self.arrays = [:]
        }
        
        var data: Data
        var compounds: [String: NBTData]
        var arrays: [String: NBTArray]
        
        func append(_ otherData: Data) {
            data.append(otherData)
        }
        
        func append(contentsOf bytes: [UInt8]) {
            data.append(contentsOf: bytes)
        }
        
        
        func finish() throws -> Data {
            if data.isEmpty && compounds.isEmpty && arrays.count == 1 {
                guard let array = arrays["list"] else {
                    print("list not found")
                    throw NBTEncodingError.todo
                }
                
                data.append(array.tagType.nbtData)
                data.append(try array.finish())
            }
            
            for (k, v) in compounds {
                print("processing compound: \(k)")
                let v = try v.finish()
                var newData = Data()
                newData.append(NBTTag.compound.rawValue.nbtData)
                newData.append(k.nbtData)
                newData.append(v)
                newData.append(NBTTag.end.rawValue.nbtData)
                data.append(newData)
            }
            
            for (k, v) in arrays {
                var newData = Data()
                newData.append(v.tagType.nbtData)
                newData.append(k.nbtData)
                newData.append(try v.finish())
                
                data.append(newData)
            }
            
            return data
        }
        
        fileprivate class NBTArray {
            init(type: NBTTag = .end) {
                self.type = type
                self.array = []
            }
            
            var type: NBTTag
            var array: [NBTData]
            
            func append(_ otherData: Data) {
                self.array.append(NBTData(data: otherData))
            }
            
            func child() -> NBTData {
                var newData = NBTData()
                self.array.append(newData)
                return newData
            }
            
            func finish() throws -> Data {
                if self.type == .end && self.array.count != 0 {
                    throw NBTEncodingError.typeNotSet
                }
                
                var data = Data()
                
                if self.tagType == .list {
                    data.append(self.type.nbtData)
                }
                data.append(Int32(self.array.count).nbtData)
                
                for v in array {
                    data.append(try v.finish())
                }
                return data
            }
         
            var tagType: NBTTag {
                switch self.type {
                case .byte:
                    return .byteArray
                case .int:
                    return .intArray
                case .long:
                    return .longArray
                default:
                    return .list
                }
            }
            var count: Int {
                self.array.count
            }
        }
    }
}


fileprivate struct NBTKeyedEncoding<Key: CodingKey>: KeyedEncodingContainerProtocol {
    init(to data: NBTEncoding.NBTData, codingPath path: [CodingKey] = []) {
        self.data = data
        self.codingPath = path
    }
  
    var data: NBTEncoding.NBTData
    
    var codingPath: [CodingKey]
    
    mutating func encodeNil(forKey key: Key) throws {
        // Nil is Nil, doing nothing
    }
    
    mutating func encode(_ value: Bool, forKey key: Key) throws {
        try encode(value ? 1 : 0 as UInt8, forKey: key)
    }
    
    mutating func encode(_ value: String, forKey key: Key) throws {
        try self.addTypeAndKey(type: .string, key: key)
        data.append(value.nbtData)
    }
    
    mutating func encode(_ value: Double, forKey key: Key) throws {
        try self.addTypeAndKey(type: .double, key: key)
        data.append(value.nbtData)
    }
    
    mutating func encode(_ value: Float, forKey key: Key) throws {
        try self.addTypeAndKey(type: .float, key: key)
        data.append(value.nbtData)
    }
    
    mutating func encode(_ value: Int, forKey key: Key) throws {
        if Int.bitWidth == Int64.bitWidth {
            try self.encode(Int64(value), forKey: key)
        } else {
            try self.encode(Int32(value), forKey: key)
        }
    }
    
    mutating func encode(_ value: Int8, forKey key: Key) throws {
        try self.addTypeAndKey(type: .byte, key: key)
        data.append(value.nbtData)
    }
    
    mutating func encode(_ value: Int16, forKey key: Key) throws {
        try self.addTypeAndKey(type: .short, key: key)
        data.append(value.nbtData)
    }
    
    mutating func encode(_ value: Int32, forKey key: Key) throws {
        try self.addTypeAndKey(type: .int, key: key)
        data.append(value.nbtData)
    }
    
    mutating func encode(_ value: Int64, forKey key: Key) throws {
        try self.addTypeAndKey(type: .long, key: key)
        data.append(value.nbtData)
    }
    
    mutating func encode(_ value: UInt, forKey key: Key) throws {
        if UInt.bitWidth == UInt64.bitWidth {
            try self.encode(UInt64(value), forKey: key)
        } else {
            try self.encode(UInt32(value), forKey: key)
        }

    }
    
    mutating func encode(_ value: UInt8, forKey key: Key) throws {
        try self.addTypeAndKey(type: .byte, key: key)
        data.append(value.nbtData)
    }
    
    mutating func encode(_ value: UInt16, forKey key: Key) throws {
        try self.addTypeAndKey(type: .short, key: key)
        data.append(value.nbtData)
    }
    
    mutating func encode(_ value: UInt32, forKey key: Key) throws {
        try self.addTypeAndKey(type: .int, key: key)
        data.append(value.nbtData)
    }
    
    mutating func encode(_ value: UInt64, forKey key: Key) throws {
        try self.addTypeAndKey(type: .long, key: key)
        data.append(value.nbtData)
    }
    
    mutating func encode<T>(_ value: T, forKey key: Key) throws where T : Encodable {
        let newData = NBTEncoding.NBTData()
        data.compounds[key.stringValue] = newData
        var nbtEncoding = NBTEncoding(to: newData)
        nbtEncoding.codingPath.append(key)
        try value.encode(to: nbtEncoding)
    }
    
    mutating func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type, forKey key: Key) -> KeyedEncodingContainer<NestedKey> where NestedKey : CodingKey {
        let newData = NBTEncoding.NBTData()
        data.compounds[key.stringValue] = newData
        let container = NBTKeyedEncoding<NestedKey>(to: newData, codingPath: codingPath + [key])
        return KeyedEncodingContainer(container)
    }
    
    mutating func nestedUnkeyedContainer(forKey key: Key) -> UnkeyedEncodingContainer {
        let newData = NBTEncoding.NBTData.NBTArray()
        data.arrays[key.stringValue] = newData
        return NBTUnkeyedEncoding(to: newData, codingPath: codingPath + [key])
    }
    
    mutating func superEncoder() -> Encoder {
        let superKey = Key(stringValue: "super")!
        return superEncoder(forKey: superKey)
    }
    
    mutating func superEncoder(forKey key: Key) -> Encoder {
        let newData = NBTEncoding.NBTData()
        data.compounds[key.stringValue] = newData
        var nbtEncoding = NBTEncoding(to: newData)
        nbtEncoding.codingPath = codingPath + [key]
        return nbtEncoding
    }
    
    private mutating func addTypeAndKey(type: NBTTag, key: Key) throws {
        data.append(contentsOf: [type.rawValue])
        data.append(key.stringValue.nbtData)
    }
}

fileprivate struct NBTUnkeyedEncoding: UnkeyedEncodingContainer {
    var data: NBTEncoding.NBTData.NBTArray
    
    init(to data: NBTEncoding.NBTData.NBTArray, codingPath path: [CodingKey]) {
        self.data = data
        self.codingPath = path
    }
    
    var codingPath: [CodingKey]
    
    var count: Int {
        self.data.count
    }
    
    private mutating func checkType(type forType: NBTTag) throws {
        if self.data.type == .end {
            self.data.type = forType
        }
        
        if self.data.type != forType {
            throw NBTEncodingError.wrongValueType
        }
    }
    
    mutating func encodeNil() throws {
        throw NBTEncodingError.wrongValueType
    }
    
    mutating func encode(_ value: Bool) throws {
        try encode(value ? 1 : 0 as UInt8)
    }
    
    mutating func encode(_ value: String) throws {
        try checkType(type: .string)
        data.append(value.nbtData)
    }
    
    mutating func encode(_ value: Double) throws {
        try checkType(type: .double)
        data.append(value.nbtData)
    }
    
    mutating func encode(_ value: Float) throws {
        try checkType(type: .float)
        data.append(value.nbtData)
    }
    
    mutating func encode(_ value: Int) throws {
        if Int.bitWidth == Int64.bitWidth {
            try self.encode(Int64(value))
        } else {
            try self.encode(Int32(value))
        }
    }
    
    mutating func encode(_ value: Int8) throws {
        try checkType(type: .byte)
        data.append(value.nbtData)
    }
    
    mutating func encode(_ value: Int16) throws {
        try checkType(type: .short)
        data.append(value.nbtData)
    }
    
    mutating func encode(_ value: Int32) throws {
        try checkType(type: .int)
        data.append(value.nbtData)
    }
    
    mutating func encode(_ value: Int64) throws {
        try checkType(type: .long)
        data.append(value.nbtData)
    }
    
    mutating func encode(_ value: UInt) throws {
        if UInt.bitWidth == UInt64.bitWidth {
            try self.encode(UInt64(value))
        } else {
            try self.encode(UInt32(value))
        }
    }
    
    mutating func encode(_ value: UInt8) throws {
        try checkType(type: .byte)
        data.append(value.nbtData)
    }
    
    mutating func encode(_ value: UInt16) throws {
        try checkType(type: .short)
        data.append(value.nbtData)
    }
    
    mutating func encode(_ value: UInt32) throws {
        try checkType(type: .int)
        data.append(value.nbtData)
    }
    
    mutating func encode(_ value: UInt64) throws {
        try checkType(type: .long)
        data.append(value.nbtData)
    }
    
    mutating func encode<T>(_ value: T) throws where T : Encodable {
        /*var newData = data.child()
        var encoding = NBTEncoding(to: newData, codingPath: codingPath + [self.count + 1])
        try value.encode(to: encoding)*/
        throw NBTEncodingError.todo
    }
 
    mutating func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type) -> KeyedEncodingContainer<NestedKey> where NestedKey : CodingKey {
        fatalError("todo")
    }
    
    mutating func nestedUnkeyedContainer() -> UnkeyedEncodingContainer {
        fatalError("todo")
    }
    
    mutating func superEncoder() -> Encoder {
        fatalError("todo")
    }
}

/*
fileprivate struct NbtUnkeyedEncoding: UnkeyedEncodingContainer {
    var data: NBTEncoding.NBTData
    
    init(to data: NBTEncoding.NBTData) {
        self.data = data
    }
    
    var codingPath: [CodingKey]
    
    private(set) var count: Int
    
    
    
    mutating func encodeNil() throws {
        // TODO: throw as this is wrong
    }
    
    mutating func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type) -> KeyedEncodingContainer<NestedKey> where NestedKey : CodingKey {
        <#code#>
    }
    
    mutating func nestedUnkeyedContainer() -> UnkeyedEncodingContainer {
        <#code#>
    }
    
    mutating func superEncoder() -> Encoder {
        <#code#>
    }
    
    
}*/

fileprivate struct NBTSingleValueEncoding: SingleValueEncodingContainer {
    private let data: NBTEncoding.NBTData
    
    init(to data: NBTEncoding.NBTData, codingPath path: [CodingKey] = []) {
        self.data = data
        self.codingPath = path
    }
    
    var codingPath: [CodingKey]
    
    mutating func encodeNil() throws {
        // FIXME: NIL is ???
    }
    
    mutating func encode(_ value: Bool) throws {
        try encode(value ? 1 : 0 as UInt8)
    }
    
    mutating func encode(_ value: String) throws {
        data.append(value.nbtData)
    }
    
    mutating func encode(_ value: Double) throws {
        data.append(value.nbtData)
    }
    
    mutating func encode(_ value: Float) throws {
        data.append(value.nbtData)
    }
    
    mutating func encode(_ value: Int) throws {
        if Int.bitWidth == Int64.bitWidth {
            try self.encode(Int64(value))
        } else {
            try self.encode(Int32(value))
        }
    }
    
    mutating func encode(_ value: Int8) throws {
        data.append(value.nbtData)
    }
    
    mutating func encode(_ value: Int16) throws {
        data.append(value.nbtData)
    }
    
    mutating func encode(_ value: Int32) throws {
        data.append(value.nbtData)
    }
    
    mutating func encode(_ value: Int64) throws {
        data.append(value.nbtData)
    }
    
    mutating func encode(_ value: UInt) throws {
        if UInt.bitWidth == UInt64.bitWidth {
            try self.encode(UInt64(value))
        } else {
            try self.encode(UInt32(value))
        }
    }
    
    mutating func encode(_ value: UInt8) throws {
        data.append(value.nbtData)
    }
    
    mutating func encode(_ value: UInt16) throws {
        data.append(value.nbtData)
    }
    
    mutating func encode(_ value: UInt32) throws {
        data.append(value.nbtData)
    }
    
    mutating func encode(_ value: UInt64) throws {
        data.append(value.nbtData)
    }
    
    mutating func encode<T>(_ value: T) throws where T : Encodable {
        var nbtEncoding = NBTEncoding(to: data)
        nbtEncoding.codingPath = codingPath
        try value.encode(to: nbtEncoding)
    }
}*/

public enum NBTEncodingError: Error {
    case wrongValueType
    case typeNotSet
    case todo
}
