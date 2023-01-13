//
//  Socket.swift
//  
//
//  Created by kotan.kn on 11/15/22.
//
import Foundation
protocol SockaddrCompatible {
    @inline(__always)
    func Sockaddr<R>(closure: (UnsafePointer<sockaddr>, UnsafePointer<socklen_t>) throws -> R) rethrows -> R
}
extension sockaddr_in {
    @inlinable
    @inline(__always)
    init(host: String, port: UInt16) {
        self.init(sin_len: .init(MemoryLayout<Self>.size),
                  sin_family: .init(AF_INET),
                  sin_port: .init(bigEndian: port),
                  sin_addr: .init(s_addr: inet_addr(host)),
                  sin_zero: (0, 0, 0, 0, 0, 0, 0, 0))
    }
    @inlinable
    @inline(__always)
    init(host: in_addr, port: UInt16) {
        self.init(sin_len: .init(MemoryLayout<Self>.size),
                  sin_family: .init(AF_INET),
                  sin_port: .init(bigEndian: port),
                  sin_addr: host,
                  sin_zero: (0, 0, 0, 0, 0, 0, 0, 0))
    }
    @inlinable
    @inline(__always)
    init(byFilling: (UnsafeMutablePointer<sockaddr>?) -> Void) {
        self = .init()
        withUnsafeMutableBytes(of: &self) {
            byFilling($0.baseAddress?.assumingMemoryBound(to: sockaddr.self))
        }
    }
}
extension sockaddr_in : SockaddrCompatible {
    @inlinable
    @inline(__always)
    func Sockaddr<R>(closure: (UnsafePointer<sockaddr>, UnsafePointer<socklen_t>) throws -> R) rethrows -> R {
        try withUnsafePointer(to: self) {
            var len = socklen_t(sin_len)
            return try closure(UnsafeRawPointer($0).assumingMemoryBound(to: sockaddr.self), &len)
        }
    }
}
extension sockaddr_in6 {
    @inlinable
    @inline(__always)
    func asSockAddr<R>(closure: (UnsafePointer<sockaddr>) throws -> R) rethrows -> R {
        try withUnsafePointer(to: self) {
            try closure(UnsafeRawPointer($0).assumingMemoryBound(to: sockaddr.self))
        }
    }
}
extension sockaddr_in6 : SockaddrCompatible {
    @inlinable
    @inline(__always)
    func Sockaddr<R>(closure: (UnsafePointer<sockaddr>, UnsafePointer<socklen_t>) throws -> R) rethrows -> R {
        try withUnsafePointer(to: self) {
            var len = socklen_t(sin6_len)
            return try closure(UnsafeRawPointer($0).assumingMemoryBound(to: sockaddr.self), &len)
        }
    }
}
