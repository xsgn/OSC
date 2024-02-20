//
//  UDPSender.swift
//  
//
//  Created by kotan.kn on 10/27/22.
//
import Network
import Foundation.NSData
public final class UDPSender {
    @usableFromInline
    let fd: Int32
    @inlinable
    public init() {
        fd = socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP)
    }
    deinit {
        close(fd)
    }
}
extension UDPSender {
    @inlinable
    @inline(__always)
    final func send(to ref: UnsafePointer<sockaddr>, data: Data) {
        let sent = data.withUnsafeBytes {
            sendto(fd, $0.baseAddress, $0.count, 0, ref, .init(ref.pointee.sa_len))
        }
        assert(sent == data.count)
    }
    @inlinable
    @inline(__always)
    final func send(to sockaddr: sockaddr_in, data: Data) {
        sockaddr.bind {
            assert($0.pointee.sa_len == $1.pointee)
            send(to: $0, data: data)
        }
    }
    @inlinable
    @inline(__always)
    final func send(to sockaddr: sockaddr_in6, data: Data) {
        sockaddr.bind {
            assert($0.pointee.sa_len == $1.pointee)
            send(to: $0, data: data)
        }
    }
    @inlinable
    @inline(__always)
    final func send(to: (String, UInt16), data: Data) {
        send(to: sockaddr_in(host: to.0, port: to.1), data: data)
    }
    @inlinable
    @inline(__always)
    final func send(to: (in_addr, UInt16), data: Data) {
        send(to: sockaddr_in(host: to.0, port: to.1), data: data)
    }
}
extension UDPSender {
    @inlinable
    @inline(__always)
    public final func send(to target: (String, UInt16), message: Message) {
        send(to: target, data: .init(message: message))
    }
    @inlinable
    @inline(__always)
    public final func send(to target: (in_addr, UInt16), message: Message) {
        send(to: target, data: .init(message: message))
    }
    @inlinable
    @inline(__always)
    public final func send(to target: sockaddr_in, message: Message) {
        send(to: target, data: .init(message: message))
    }
    @inlinable
    @inline(__always)
    public final func send(to target: sockaddr_in6, message: Message) {
        send(to: target, data: .init(message: message))
    }
}
