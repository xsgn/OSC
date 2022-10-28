//
//  File.swift
//  
//
//  Created by Kota Nakano on 10/28/22.
//
import XCTest
@testable import OSC
final class UDPReceiverTestCases: XCTestCase {
    final func testSend() {
        var message = Message(address: "/logvolume", elements: [])
        message.append(10.0)
        UDPSender.send(host: "127.0.0.1", port: 5005, message: message)
        RunLoop.current.run()
    }
//    final func testBind() throws {
//        try withExtendedLifetime(UDPr(host: "127.0.0.1", port: 5005), RunLoop.main.run)
//    }
}
