//
//  File.swift
//  
//
//  Created by Kota Nakano on 10/28/22.
//
import Foundation
public struct Message {
    enum Element {
        case S(String)
        case I(Int32)
        case F(Float32)
        case B(Data)
    }
    let address: String
    var elements: Array<Element> = []
}
extension Message {
    mutating func append(_ value: some BinaryInteger) {
        elements.append(.I(.init(value)))
    }
    mutating func append(_ value: some BinaryFloatingPoint) {
        elements.append(.F(.init(value)))
    }
    mutating func append(_ value: String) {
        elements.append(.S(value))
    }
}
extension Data {
    @inline(__always)
    private func data(wrap data: Data) -> Data {
        data + Data(count: 4 - data.count % 4)
    }
    @inline(__always)
    private func data(wrap string: String) -> Data {
        data(wrap: string.data(using: .ascii)!)
    }
    @inline(__always)
    private func data<T: FixedWidthInteger>(byte binary: T) -> Data {
        withUnsafeTemporaryAllocation(of: T.self, capacity: 1) {
            $0.baseAddress?.pointee = binary.bigEndian
            return Data(buffer: $0)
        }
    }
    public init(message: Message) {
        self.init(count: 0)
        var head = Array<UInt8>()
        var body = Data()
        message.elements.forEach {
            switch $0 {
            case.S(let s):
                head.append(0x73)
                body.append(data(wrap: s))
            case.I(let i):
                head.append(0x69)
                body.append(data(byte: i))
            case.F(let f):
                head.append(0x66)
                body.append(data(byte: f.bitPattern))
            case.B(let b) where b.count == 4:
                fatalError()
            default:
                fatalError()
            }
        }
        append(data(wrap: message.address))
        append(data(wrap: Data(head)))
        append(data(wrap: body))
    }
}
