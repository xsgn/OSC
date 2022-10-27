//
//  File.swift
//  
//
//  Created by Kota Nakano on 10/27/22.
//
import Foundation
import Dispatch
public struct UDPReceiver {
    let source: DispatchSourceRead
}
public extension UDPReceiver {
    init(address: String, port: UInt16) {
        let __socket = socket(AF_INET, SOCK_DGRAM, SOCK_STREAM)
        source = DispatchSource.makeReadSource(fileDescriptor: .init(__socket), queue: .global(qos: .utility))
        source.setEventHandler(handler: handler)
        source.resume()
        let status = withUnsafeTemporaryAllocation(of: sockaddr_in.self, capacity: 1) {
            bzero($0.baseAddress, $0.count * MemoryLayout<sockaddr_in>.stride)
            var ref = $0.baseAddress?.pointee
            ref?.sin_family = .init(AF_INET)
            ref?.sin_port = port
//            inet_pton(__socket, address, .none)
            return $0.withMemoryRebound(to: sockaddr.self) {
                bind(__socket, $0.baseAddress, .init(MemoryLayout<sockaddr_in>.size))
            }
        }
        precondition(status == 0)
    }
    func handler() {
        
    }
}
