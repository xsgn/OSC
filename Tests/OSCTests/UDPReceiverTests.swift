//
//  File.swift
//  
//
//  Created by Kota Nakano on 10/28/22.
//
import XCTest
@testable import OSC
import AVFoundation
final class UDPReceiverTestCases: XCTestCase {
//    final func testSend() async throws {
//        var message = Message(address: "/filter")
//        message.append(10.0)
//        message.append("hello")
//        message.append(200)
//        try await UDPSender(to: ("127.0.0.1", 5005))
//            .send(message: message)
//    }
    final func testReceive() {
        let k = DispatchSource.udpSource(v4: "127.0.0.1", port: 5005) {
            print(1, $0)
            return.none
        }
        withExtendedLifetime(k, RunLoop.main.run)
    }
}
