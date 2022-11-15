//
//  Message.swift
//  
//
//  Created by kotan.kn on 10/28/22.
//
import Foundation.NSData
public struct Message {
    fileprivate enum Element {
        case S(String)
        case I(Int32)
        case F(Float32)
        case B(Data)
    }
    let address: String
    fileprivate var elements: Array<Element>
    init(address target: String) {
        address = target
        elements = []
    }
    init(parse memory: Data) throws {
        var cursor = 0
        do {
            var a = Array<UInt8>()
            while cursor < memory.count, memory[cursor] != 0 {
                a.append(memory[cursor])
                cursor += 1
            }
            self.init(address: .init(cString: a))
            cursor += 4 - cursor % 4
        }
        guard memory[cursor] == 0x2C else { fatalError() }
        do {
            var h = Array<UInt8>()
            while cursor < memory.count, memory[cursor] != 0 {
                h.append(memory[cursor])
                cursor += 1
            }
            cursor += 4 - cursor % 4
            h.forEach {
                switch $0 {
                case 0x73://S
                    var s = Array<UInt8>()
                    while cursor < memory.count, memory[cursor] != 0 {
                        s.append(memory[cursor])
                        cursor += 1
                    }
                    append(String(cString: s))
                    cursor += 4 - cursor % 4
                case 0x69://I
                    let i = (0..<4).reduce(UInt32(0)) {
                        $0 << 8 + Int32(memory[cursor + $1])
                    }
                    append(Int32(bitPattern: i))
                    cursor += 4
                case 0x66://F
                    let i = (0..<4).reduce(UInt32(0)) {
                        $0 << 8 + Int32(memory[cursor + $1])
                    }
                    append(Float32(bitPattern: i))
                    cursor += 4
                case 0x62://B
                    let i = (0..<4).reduce(UInt32(0)) {
                        $0 << 8 + Int32(memory[cursor + $1])
                    }
                    append(Data(buffer: [i]))
                    cursor += 4
                default:
                    break
                }
            }
        }
        print(self)
    }
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
    mutating func append(_ data: Data) {
        precondition(data.count % 0x4 == 0, "blob length should be 4-aligned")
        stride(from: 0, to: data.count, by: 4).forEach {
            elements.append(.B(data[$0..<$0+4]))
        }
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
        var head = [0x2C] as Array<UInt8>
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
            case.B(let b) where b.count <= 4:
                head.append(0x62)
                body.append(data(wrap: b))
            default:
                fatalError()
            }
        }
        append(data(wrap: message.address))
        append(data(wrap: Data(head)))
        append(data(wrap: body))
    }
}
