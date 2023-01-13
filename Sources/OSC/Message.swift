//
//  Message.swift
//  
//
//  Created by kotan.kn on 10/28/22.
//
import Foundation.NSData
enum ASCII: UInt8, CaseIterable {
    case b = 0x62
    case f = 0x66
    case i = 0x69
    case s = 0x73
}
public struct Message {
    @usableFromInline
    internal enum Element {
        case S(String)
        case I(Int32)
        case F(Float32)
        case B(Data)
    }
    public let address: String
    @usableFromInline
    internal var elements: Array<Element>
    public init(address target: String) {
        address = target
        elements = []
    }
    @inline(__always)
    init(parse memory: Data) throws {
        var cursor = 0
        do {
            var a = Array<UInt8>()
            while cursor < memory.count, memory[cursor] != 0 {
                a.append(memory[cursor])
                cursor += 1
            }
            a.append(0)
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
                switch ASCII(rawValue: $0) {
                case.some(.s)://S
                    var s = Array<UInt8>()
                    while cursor < memory.count, memory[cursor] != 0 {
                        s.append(memory[cursor])
                        cursor += 1
                    }
                    append(String(cString: s))
                    cursor += 4 - cursor % 4
                case.some(.i)://I
                    let i = (0..<4).reduce(UInt32(0)) {
                        $0 << 8 + UInt32(memory[cursor + $1])
                    }
                    append(Int32(bitPattern: i))
                    cursor += 4
                case.some(.f)://F
                    let i = (0..<4).reduce(UInt32(0)) {
                        $0 << 8 + UInt32(memory[cursor + $1])
                    }
                    append(Float32(bitPattern: i))
                    cursor += 4
                case.some(.b)://B
                    let b = (0..<4).reduce(into: Data()) {
                        $0.append(memory[cursor + $1])
                    }
                    append(b)
                    cursor += 4
                default:
                    break
                }
            }
        }
    }
}
extension Message {
    @inlinable
    @inline(__always)
    public func unwrap(at index: Int) -> (String?, Int32?, Float32?, Data?) {
        guard elements.indices.contains(index) else { return(.none, .none, .none, .none) }
        return elements[index].unwrap
    }
    @inlinable
    @inline(__always)
    public subscript(at index: Int) -> Optional<Any> {
        guard elements.indices.contains(index) else { return.none }
        return.some(elements[index].value)
    }
    @inlinable
    @inline(__always)
    public var count: Int { elements.count }
}
extension Message.Element {
    @inlinable
    @inline(__always)
    var unwrap: (String?, Int32?, Float32?, Data?) {
        switch self {
        case.S(let s):
            return (s, .none, .none, .none)
        case.I(let i):
            return (.none, i, .none, .none)
        case.F(let f):
            return (.none, .none, f, .none)
        case.B(let b):
            return (.none, .none, .none, b)
        }
    }
    @inlinable
    @inline(__always)
    var value: Any {
        switch self {
        case.S(let s):
            return s
        case.I(let i):
            return i
        case.F(let f):
            return f
        case.B(let b):
            return b
        }
    }
}
extension Message : CustomStringConvertible {
    @inlinable
    @inline(__always)
    public var description: String {
        address + " " + elements.map {
            switch $0 {
            case.S(let s):
                return s
            case.F(let f):
                return String(describing: f)
            case.I(let i):
                return String(describing: i)
            case.B(let b):
                return String(describing: b)
            }
        }.joined(separator: ", ")
    }
}
extension Message {
    @inlinable
    public
    mutating func append(_ value: some BinaryInteger) {
        elements.append(.I(.init(value)))
    }
    @inlinable
    public
    mutating func append(_ value: some BinaryFloatingPoint) {
        elements.append(.F(.init(value)))
    }
    @inlinable
    public
    mutating func append(_ value: String) {
        elements.append(.S(value))
    }
    @inlinable
    public
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
                head.append(ASCII.s.rawValue)
                body.append(data(wrap: s))
            case.I(let i):
                head.append(ASCII.i.rawValue)
                body.append(data(byte: i))
            case.F(let f):
                head.append(ASCII.f.rawValue)
                body.append(data(byte: f.bitPattern))
            case.B(let b) where b.count <= 4:
                head.append(ASCII.b.rawValue)
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
