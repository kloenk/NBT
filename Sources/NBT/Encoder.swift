//
//  Encoder.swift
//  Ecnoder
//
//  Created by Finn Behrens on 14.08.21.
//

import Foundation
import Combine

public class NBTEncoder {
    
    // TODO: compression
    // TODO: arrays
    
    public func encode<T: Encodable>(_ value: T) throws -> Data {
        let nbtEncoding = NBTEncoding()
        try value.encode(to: nbtEncoding)
        return nbtEncoding.finish()
    }
}

extension NBTEncoder: TopLevelEncoder {
    public typealias Output = Data
}

fileprivate struct NBTEncoding: Encoder {
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
        fatalError("todo")
    }
    
    func singleValueContainer() -> SingleValueEncodingContainer {
        return NBTSingleValueEncoding(to: data, codingPath: codingPath)
    }
    
    func finish() -> Data {
        return data.finish()
    }
    
    fileprivate class NBTData {
        init() {
            self.data = Data()
            self.compounds = [:]
        }
        
        var data: Data
        var compounds: [String: NBTData]
        
        func append(_ otherData: Data) {
            data.append(otherData)
        }
        
        func append(contentsOf bytes: [UInt8]) {
            data.append(contentsOf: bytes)
        }
        
        
        func finish() -> Data {
            for (k, v) in compounds {
                print("processing compound: \(k)")
                let v = v.finish()
                var newData = Data()
                newData.append(NBTTag.compound.rawValue.nbtData)
                newData.append(k.nbtData)
                newData.append(v)
                newData.append(NBTTag.end.rawValue.nbtData)
                data.append(newData)
            }
            
            return data
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
        let newData = NBTEncoding.NBTData()
        data.compounds[key.stringValue] = newData
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
    var data: NBTEncoding.NBTData
    var type: NBTTag?
    
    init(to data: NBTEncoding.NBTData, codingPath path: [CodingKey]) {
        self.data = data
        self.codingPath = path
    }
    
    var codingPath: [CodingKey]
    
    var count: Int = 0
    
    private mutating func checkType(type forType: NBTTag) throws {
        guard let type = self.type else {
            self.type = forType
            return
        }
        
        if type != forType {
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
        count += 1
        data.append(value.nbtData)
    }
    
    mutating func encode(_ value: Double) throws {
        try checkType(type: .double)
        count += 1
        data.append(value.nbtData)
    }
    
    mutating func encode(_ value: Float) throws {
        try checkType(type: .float)
        count += 1
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
        count += 1
        data.append(value.nbtData)
    }
    
    mutating func encode(_ value: Int16) throws {
        try checkType(type: .short)
        count += 1
        data.append(value.nbtData)
    }
    
    mutating func encode(_ value: Int32) throws {
        try checkType(type: .int)
        count += 1
        data.append(value.nbtData)
    }
    
    mutating func encode(_ value: Int64) throws {
        try checkType(type: .long)
        count += 1
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
        count += 1
        data.append(value.nbtData)
    }
    
    mutating func encode(_ value: UInt16) throws {
        try checkType(type: .short)
        count += 1
        data.append(value.nbtData)
    }
    
    mutating func encode(_ value: UInt32) throws {
        try checkType(type: .int)
        count += 1
        data.append(value.nbtData)
    }
    
    mutating func encode(_ value: UInt64) throws {
        try checkType(type: .long)
        count += 1
        data.append(value.nbtData)
    }
    
    mutating func encode<T>(_ value: T) throws where T : Encodable {
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
}

public enum NBTEncodingError: Error {
    case wrongValueType
    case todo
}
