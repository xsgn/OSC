//
//  UDPSender.swift
//  
//
//  Created by kotan.kn on 10/27/22.
//
import Foundation.NSData
public final class UDPSender {
    private let fd: Int32
    public init() {
        fd = socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP)
    }
    deinit {
        close(fd)
    }
}
extension UDPSender {
    public final func send(to: (String, UInt16), data: Data) {
        let sent = sockaddr_in(host: to.0, port: to.1).Sockaddr { (mem, len) in
            data.withUnsafeBytes {
                sendto(fd, $0.baseAddress, $0.count, 0, mem, len.pointee)
            }
        }
        assert(sent == data.count)
    }
}
