//
//  UDPReceiver.swift
//  
//
//  Created by kotan.kn on 10/27/22.
//
import Foundation.NSData
extension Int32 {
    @inlinable
    @inline(__always)
    init(v4 host: String, port: UInt16) {
        self = socket(PF_INET, SOCK_DGRAM, 0)
        let status = sockaddr_in(host: host, port: port).Sockaddr { (mem, _) in
            bindresvport_sa(self, .init(mutating: mem))
        }
        precondition(status == 0, "bind failure")
    }
}
extension Data {
    @inlinable
    @inline(__always)
    init(capacity: Int, byFilling: (UnsafeMutableRawBufferPointer) -> Optional<Int>) {
        self.init(count: capacity)
        count = withUnsafeBytes {
            byFilling(.init(mutating: $0)) ?? count
        }
    }
}
extension DispatchSource {
    @inlinable
    @inline(__always)
    static func udpSource(v4 host: String, port: UInt16, work: @escaping(Data) -> Optional<Data>) -> DispatchSourceRead {
        let source = DispatchSource.makeReadSource(fileDescriptor: .init(v4: host, port: port), queue: .global(qos: .utility))
        source.setEventHandler {[weak source]in
            guard let source else { return }
            withUnsafeTemporaryAllocation(byteCount: MemoryLayout<sockaddr_in>.size,
                                          alignment: MemoryLayout<sockaddr_in>.alignment) {
                var len = socklen_t($0.count)
                let mem = $0.baseAddress?.assumingMemoryBound(to: sockaddr.self)
                let req = Data(capacity: .init(source.data)) {
                    recvfrom(.init(source.handle),
                             $0.baseAddress,
                             $0.count,
                             0,
                             mem,
                             &len)
                }
                precondition(len == .init($0.count))
                work(req).map {
                    let sent = $0.withUnsafeBytes {
                        sendto(.init(source.handle),
                               $0.baseAddress,
                               $0.count,
                               0,
                               mem,
                               len)
                    }
                    precondition(sent == $0.count)
                }
            }
        }
        source.setCancelHandler {[weak source]in
            guard let source else { return }
            close(.init(source.handle))
        }
        source.activate()
        return source
    }
    @inline(__always)
    public static func udpOSC(v4 host: String, port: UInt16, handle: @escaping(Result<Message, Error>) -> Optional<Message>) -> DispatchSourceRead {
        udpSource(v4: host, port: port) {
            do {
                return try handle(.success(.init(parse: $0))).map(Data.init)
            } catch {
                return handle(.failure(error)).map(Data.init)
            }
        }
    }
}
