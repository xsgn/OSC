//
//  File.swift
//  
//
//  Created by Kota Nakano on 10/27/22.
//
import Network
public struct UDPSender {
    static func send(host: String, port: UInt16, message: Message) {
        let connection = NWConnection(host: .init(host), port: .init(integerLiteral: port), using: .udp)
        connection.stateUpdateHandler = { state in
            switch state {
            case.ready:
                try!connection.send(content: .init(message: message), completion: .idempotent)
            default:
                break
            }
        }
        connection.start(queue: .global(qos: .utility))
    }
}
