//
//  File.swift
//  
//
//  Created by Kota Nakano on 10/27/22.
//
import Foundation
import Dispatch
import Combine
import Network
public class UDPr {
    let listener: NWListener
    init(host: String, port: UInt16) throws {
        let p = NWParameters.udp
        p.allowLocalEndpointReuse = true
//        p.requiredLocalEndpoint = true
        listener = try NWListener(using: p, on: .init(integerLiteral: port))
        listener.newConnectionHandler = { connection in
            connection.parameters.attribution = .user
            connection.stateUpdateHandler = { state in
                switch state {
                case.ready:
                    print("ready")
                case let s:
                    print(s)
                }
            }
            connection.receiveMessage {
                print($3)
                guard let data = $0 else {
                    return
                }
                print(data.withUnsafeBytes {
                    $0.bindMemory(to: UInt8.self).map { String($0, radix: 16) }.joined(separator: ", ")
                })
                print(data.withUnsafeBytes {
                    String(cString: $0.bindMemory(to: UInt8.self).baseAddress!)
                })
            }
            connection.start(queue: .global(qos: .utility))
        }
        listener.start(queue: .global(qos: .background))
    }
}

public struct UDPReceiver {
    let source: DispatchSourceRead
}
public extension UDPReceiver {
    init(address: String, port: UInt16) {
        source = withUnsafeTemporaryAllocation(byteCount: MemoryLayout<sockaddr_in>.size, alignment: MemoryLayout<sockaddr_in>.alignment) {
            bzero($0.baseAddress, $0.count)
            let source = DispatchSource.makeReadSource(fileDescriptor: .init(socket(AF_INET, SOCK_DGRAM, SOCK_STREAM)))
            do {
                let in4 = $0.bindMemory(to: sockaddr_in.self).baseAddress
                in4?.pointee.sin_family = .init(AF_INET)
                in4?.pointee.sin_port = port
            }
            bind(.init(source.handle), $0.baseAddress?.assumingMemoryBound(to: sockaddr.self), .init($0.count))
            return source
        }
        source.setEventHandler(handler: handler)
        source.setCancelHandler(handler: cancel)
        source.resume()
    }
    func handler() {
        let result = withUnsafeTemporaryAllocation(byteCount: MemoryLayout<sockaddr_in>.size, alignment: MemoryLayout<sockaddr_in>.alignment) {
            let result = Data(count: .init(source.data))
            var socklen = socklen_t(MemoryLayout<sockaddr_in>.size)
            recvfrom(.init(source.handle),
                                  result.withUnsafeBytes { .init(mutating: $0.baseAddress) },
                                  result.count,
                                  0,
                                  $0.bindMemory(to: sockaddr.self).baseAddress,
                                  &socklen)
            return result
        }
        let x = result[0..<10].withUnsafeBytes {
            String.init(utf8String: $0)
        }
        print(x)
    }
    func cancel() {
        close(.init(source.handle))
    }
}
