//
//  File.swift
//  File
//
//  Created by Finn Behrens on 14.08.21.
//

import Foundation
import XCTest
@testable import NBT

final class NBTEncodingTests: XCTestCase {
    /*func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(NBT().text, "Hello, World!")
    }*/
    
    func testEncodingShort() throws {
        let encoder = NBTEncoder()
        
        let data = try encoder.encode(UInt16(32767))
        
        var expected = Data()
        expected.append(contentsOf: [0x7f, 0xff])
        
        XCTAssertEqual(data, expected)
    }
    
    func testEncodingStructSimple() throws {
        struct Root: Encodable {
            var content: Content
            
            enum CodingKeys: String, CodingKey {
                case content = "hello world"
            }
            
            struct Content: Encodable {
                var name: String
            }
        }
        
        let root = Root(content: Root.Content(name: "Bananrama"))
        
        
        let encoder = NBTEncoder()
        
        let data = try encoder.encode(root)
        
        var expected = Data()
        // Contents of https://raw.github.com/Dav1dde/nbd/master/test/hello_world.nbt
        expected.append(contentsOf: [
            0x0A, 0x00, 0x0B, 0x68, 0x65, 0x6C, 0x6C, 0x6F, 0x20, 0x77, 0x6F, 0x72, 0x6C,
            0x64, 0x08, 0x00, 0x04, 0x6E, 0x61, 0x6D, 0x65, 0x00, 0x09, 0x42, 0x61, 0x6E,
            0x61, 0x6E, 0x72, 0x61, 0x6D, 0x61, 0x00
        ])
        
        XCTAssertEqual(data, expected)
    }
}
