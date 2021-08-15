import XCTest
@testable import NBT

final class NBTTests: XCTestCase {
    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        //XCTAssertEqual(NBT().text, "Hello, World!")
    }
    
    func testNBTToData() throws {
        let data = NBT.short(32767).toData()
        
        var expected = Data()
        expected.append(contentsOf: [0x7f, 0xff])
        
        XCTAssertEqual(data, expected)
    }
    
    func testNBTCompoundToData() throws {
        let nbt: NBT = ["name": "Bananrama"]
        let data = nbt.toData("hello world")
        
        var expected = Data()
        // Contents of https://raw.github.com/Dav1dde/nbd/master/test/hello_world.nbt
        expected.append(contentsOf: [
            0x0A, 0x00, 0x0B, 0x68, 0x65, 0x6C, 0x6C, 0x6F, 0x20, 0x77, 0x6F, 0x72, 0x6C,
            0x64, 0x08, 0x00, 0x04, 0x6E, 0x61, 0x6D, 0x65, 0x00, 0x09, 0x42, 0x61, 0x6E,
            0x61, 0x6E, 0x72, 0x61, 0x6D, 0x61, 0x00
        ])
        
        XCTAssertEqual(data, expected)
    }
    
    /// This test is flaky, as dictionary is not ordered
    func testNBTCompoundServers() throws {
        let nbt: NBT = ["servers": [
            [
                "ip": "manwe.kloenk.dev",
                "name": "Minecraft Server"
            ],
            [
                "ip": "mc.example.com",
                "name": "Example server"
            ]
        ]
        ]
        
        print("\(nbt)")
        
        let data = nbt.toData("")
        
        var expected = Data()
        expected.append(contentsOf: [0x0A, 0x00, 0x00, 0x09, 0x00, 0x07, 0x73,
                                     0x65, 0x72, 0x76, 0x65, 0x72, 0x73, 0x0A,
                                     0x00, 0x00, 0x00, 0x02, 0x08, 0x00, 0x02,
                                     0x69, 0x70, 0x00, 0x10, 0x6D, 0x61, 0x6E,
                                     0x77, 0x65, 0x2E, 0x6B, 0x6C, 0x6F, 0x65,
                                     0x6E, 0x6B, 0x2E, 0x64, 0x65, 0x76, 0x08,
                                     0x00, 0x04, 0x6E, 0x61, 0x6D, 0x65, 0x00,
                                     0x10, 0x4D, 0x69, 0x6E, 0x65, 0x63, 0x72,
                                     0x61, 0x66, 0x74, 0x20, 0x53, 0x65, 0x72,
                                     0x76, 0x65, 0x72, 0x00, 0x08, 0x00, 0x02,
                                     0x69, 0x70, 0x00, 0x0E, 0x6D, 0x63, 0x2E,
                                     0x65, 0x78, 0x61, 0x6D, 0x70, 0x6C, 0x65,
                                     0x2E, 0x63, 0x6F, 0x6D, 0x08, 0x00, 0x04,
                                     0x6E, 0x61, 0x6D, 0x65, 0x00, 0x0E, 0x45,
                                     0x78, 0x61, 0x6D, 0x70, 0x6C, 0x65, 0x20,
                                     0x73, 0x65, 0x72, 0x76, 0x65, 0x72, 0x00,
                                     0x00])
        
        try data.write(to: URL(fileURLWithPath: "./servers.out.dat"))
        
        XCTAssertEqual(data, expected)
    }
}

public extension Data {
    private static let hexAlphabet = Array("0123456789abcdef".unicodeScalars)
    func hexStringEncoded() -> String {
        String(reduce(into: "".unicodeScalars) { result, value in
            result.append(Self.hexAlphabet[Int(value / 0x10)])
            result.append(Self.hexAlphabet[Int(value % 0x10)])
        })
    }
}
