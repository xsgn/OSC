//
//  File.swift
//  
//
//  Created by Kota Nakano on 10/28/22.
//
import XCTest
import OSC
import AVFoundation
final class UDPReceiverTestCases: XCTestCase {
    final func testAsciiCode() {
        ASCII.allCases.forEach {
            XCTAssertEqual($0.rawValue, String(describing: $0).first?.asciiValue)
        }
    }
//    final func testSend() {
//        var message = Message(address: "/filter")
//        message.append(10.0)
//        message.append("hello")
//        message.append(200)
//        UDPSender().send(to: ("127.0.0.1", 5005), message: message)
//    }
//    final func testReceive() {
//        withExtendedLifetime(DispatchSource.udpOSC(v4: "127.0.0.1", port: 5005) {
//            do {
//                let message = try $0.get()
//                switch message.address {
//                case "/filter":
//                    break
//                default:
//                    break
//                }
//            } catch {
//
//            }
//            return.none
//        }, RunLoop.current.run)
//    }
}
