# Summary

A minimum implementation to send or receive OSC

# Usage

## Send OSC message

```swift
var message = Message(address: "/filter")
message.append("lpf")
message.append(440 as Float32)
message.append(1 as Float32)
message.append(0 as Int32)

let sender = UDPSender()
sender.send(to: ("127.0.0.1", 5005), message: message)
```

## Receive OSC handler

```swift
let source = DispatchSource.udpOSC(host: "127.0.0.1", port: 5005) {
    let message = try!$0.get()
    switch message.address {
        case "/address":
            let freq = message[0] as? Float32
            let Q = message[1] as? Float32
            let index = message[2] as? Int32
        default:
            break
    } 
}
```
