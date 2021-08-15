import Foundation

public struct NBT {
    public private(set) var text = "Hello, World!"

    public init() {
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


/*extension Numeric {
    var nbtData: Data {
        var source = self
        return Data(bytes: &source, count: MemoryLayout<Self>.size)
    }
}*/

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
