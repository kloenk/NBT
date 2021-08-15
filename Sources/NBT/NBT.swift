import Foundation

public enum NBT {
    case end
    case byte(Int8)
    case short(Int16)
    case int(Int32)
    case long(Int64)
    case float(Float)
    case double(Double)
    case byteArray([Int8])
    case string(String)
    case list([NBT])
    case compound([String: NBT])
    case intArray([Int32])
    case longArray([Int64])
    case boxed(BoxedNBT)
    
    public var tag: NBTTag {
        switch self {
        case .end:
            return .end
        case .byte(_):
            return .byte
        case .short(_):
            return .short
        case .int(_):
            return .int
        case .long(_):
            return .long
        case .float(_):
            return .float
        case .double(_):
            return .double
        case .byteArray(_):
            return .byteArray
        case .string(_):
            return .string
        case .list(_):
            return .list
        case .compound(_):
            return .compound
        case .intArray(_):
            return .intArray
        case .longArray(_):
            return .longArray
        case .boxed(let box):
            return box.tag
        }
    }
    
    // TODO: Compression
    public func toData(_ rootCompoundName: String) -> Data {
        var data = NBTTag.compound.nbtData
        data.append(rootCompoundName.nbtData)
        data.append(self.toData())
        return data
    }
    
    public func toData() -> Data {
        switch self {
        case .end:
            return NBTTag.end.nbtData
        case .byte(let v):
            return v.nbtData
        case .short(let v):
            return v.nbtData
        case .int(let v):
            return v.nbtData
        case .long(let v):
            return v.nbtData
        case .float(let v):
            return v.nbtData
        case .double(let v):
            return v.nbtData
        case .byteArray(let v):
            var data = Int32(v.count).nbtData
            for v in v {
                data.append(v.nbtData)
            }
            return data
        case .string(let v):
            var data = Int16(v.count).nbtData
            data.append(Data(v.utf8))
            return data
        case .list(let v):
            var data = (v.first?.tag ?? .end).nbtData
            data.append(Int32(v.count).nbtData)
            
            for v in v {
                data.append(v.toData())
            }
            
            return data
        case .compound(let v):
            var data = Data()
            
            for (k, v) in v {
                data.append(v.tag.nbtData)
                data.append(k.nbtData)
                data.append(v.toData())
            }
            data.append(NBTTag.end.nbtData)
            return data
        case .intArray(let v):
            var data = Int32(v.count).nbtData
            for v in v {
                data.append(v.nbtData)
            }
            return data
        case .longArray(let v):
            var data = Int32(v.count).nbtData
            for v in v {
                data.append(v.nbtData)
            }
            return data
        case .boxed(let box):
            return box.toData()
        }
    }
}

extension NBT: ExpressibleByStringLiteral {
    public typealias StringLiteralType = String
    
    public init(stringLiteral value: StringLiteralType) {
        self = NBT.string(value)
    }
}

extension NBT: ExpressibleByDictionaryLiteral {
    public init(dictionaryLiteral elements: (String, NBT)...) {
        var list: [String: NBT] = [:]
        for (name, value) in elements {
            list[name] = value
        }
        self = NBT.compound(list)
    }
}

extension NBT: ExpressibleByFloatLiteral {
    public init(floatLiteral: Float) {
        self = NBT.float(floatLiteral)
    }
}

extension NBT: ExpressibleByBooleanLiteral {
    public init(booleanLiteral: Bool) {
        self = NBT.byte(booleanLiteral ? 1 : 0 as Int8)
    }
}

extension NBT: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: IntegerLiteralType) {
        self = NBT.long(Int64(value))
    }
}

extension NBT: ExpressibleByArrayLiteral {
    public typealias ArrayLiteralElement = NBT
    
    public init(arrayLiteral elements: NBT...) {
        self = NBT.list(elements)
        print(self)
    }
    
}

public class BoxedNBT: CustomDebugStringConvertible {
    var nbt: NBT
    
    init(_ nbt: NBT = .end) {
        self.nbt = nbt
    }
    
    var tag: NBTTag {
        nbt.tag
    }
    
    func toData() -> Data {
        nbt.toData()
    }
    
    public var debugDescription: String {
        String(describing: self.nbt)
    }
}

public enum NBTTag: UInt8 {
    case end
    case byte
    case short
    case int
    case long
    case float
    case double
    case byteArray
    case string
    case list
    case compound
    case intArray
    case longArray
}

extension NBTTag {
    var nbtData: Data {
        self.rawValue.nbtData
    }
}

extension String {
    var nbtData: Data {
        var data = Data()
        data.append(UInt16(self.count).nbtData)
        data.append(Data(self.utf8))
        return data
    }
}

extension Int8 {
    var nbtData: Data {
        var data = Data()
        data.append(contentsOf: [UInt8(self)])
        return data
    }
}

extension Int16 {
    var nbtData: Data {
        var source = self.bigEndian
        return Data(bytes: &source, count: MemoryLayout<Self>.size)
    }
}

extension Int32 {
    var nbtData: Data {
        var source = self.bigEndian
        return Data(bytes: &source, count: MemoryLayout<Self>.size)
    }
}

extension Int64 {
    var nbtData: Data {
        var source = self.bigEndian
        return Data(bytes: &source, count: MemoryLayout<Self>.size)
    }
}

extension UInt8 {
    var nbtData: Data {
        var data = Data()
        data.append(contentsOf: [self])
        return data
    }
}

extension UInt16 {
    var nbtData: Data {
        var source = self.bigEndian
        return Data(bytes: &source, count: MemoryLayout<Self>.size)
    }
}

extension UInt32 {
    var nbtData: Data {
        var source = self.bigEndian
        return Data(bytes: &source, count: MemoryLayout<Self>.size)
    }
}

extension UInt64 {
    var nbtData: Data {
        var source = self.bigEndian
        return Data(bytes: &source, count: MemoryLayout<Self>.size)
    }
}

extension Float {
    var nbtData: Data {
        // nbtData makes bigEndian
        return self.bitPattern.nbtData
    }
}

extension Double {
    var nbtData: Data {
        // nbtData makes bigEndian
        return self.bitPattern.nbtData
    }
}
