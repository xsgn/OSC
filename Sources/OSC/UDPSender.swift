//
//  UDPSender.swift
//  
//
//  Created by kotan.kn on 10/27/22.
//
import Network
public struct UDPSender {
    private let connection: NWConnection
    init(to target: (String, UInt16)) async throws {
        let (host, port) = target
        connection = .init(host: .init(host), port: .init(integerLiteral: port), using: .udp)
        connection.start(queue: .global(qos: .utility))
    }
    func send(message: Message) async throws {
        try await withCheckedThrowingContinuation { (future: CheckedContinuation<Void, Error>) in
            connection.send(content: .init(message: message), completion: .contentProcessed {
                switch $0 {
                case.none:
                    future.resume(returning: ())
                case.some(let error):
                    future.resume(throwing: error)
                }
            })
        }
    }
    static func send(host: String, port: UInt16, message: Message) async throws {
        try await withCheckedThrowingContinuation { (future: CheckedContinuation<Void, Error>) in
            let connection = NWConnection(host: .init(host), port: .init(integerLiteral: port), using: .udp)
            connection.stateUpdateHandler  = { state in
                print(state)
                switch state {
                case.ready:
                    connection.send(content: .init(message: message), completion: .contentProcessed {
                        switch $0 {
                        case.some(let error):
                            future.resume(throwing: error)
                        case.none:
                            future.resume(returning: ())
                        }
                    })
                case.failed(let error), .waiting(let error):
                    future.resume(throwing: error)
                case.cancelled:
                    future.resume(throwing: NWError.posix(.ECANCELED))
                case.preparing, .setup:
                    break
                @unknown default:
                    fatalError()
                }
            }
            connection.start(queue: .global(qos: .utility))
        }
    }
    static func send(host: String, port: UInt16, message: Message, future: @escaping(Void?, NWError?) -> Void) {
        let connection = NWConnection(host: .init(host), port: .init(integerLiteral: port), using: .udp)
        connection.stateUpdateHandler  = { state in
            switch state {
            case.ready:
                connection.send(content: .init(message: message), completion: .contentProcessed {
                    switch $0 {
                    case.some(let error):
                        future(.none, .some(error))
                    case.none:
                        future(.some(()), .none)
                    }
                })
            case.failed(let error), .waiting(let error):
                future(.none, .some(error))
            case.cancelled:
                future(.none, .some(.posix(.ECANCELED)))
            case.preparing, .setup:
                break
            @unknown default:
                fatalError()
            }
        }
        connection.start(queue: .global(qos: .utility))
    }
}
