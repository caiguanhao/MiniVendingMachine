//
//  PeripheralView.swift
//  Mini Vending Machine WatchKit Extension
//
//  Created by CGH on 2022/2/15.
//

import SwiftUI
import CoreBluetooth

struct PeripheralView: View {
    let device: Device

    @State var connected = false
    @State var services: [Service] = []
    @State var characteristics: [Characteristic] = []

    var service: String? { services.filter({ $0.uuid == "0783B03E-8535-B5A0-7140-A304F013C3B7" }).first?.uuid }
    var writeCh: String? { characteristics.filter({ $0.uuid == "0783B03E-8535-B5A0-7140-A304F013C3BA" }).first?.uuid }
    var readCh: String?  { characteristics.filter({ $0.uuid == "0783B03E-8535-B5A0-7140-A304F013C3B8" }).first?.uuid }

    var canControl: Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        return service != nil && writeCh != nil && readCh != nil
        #endif
    }

    @State var disabled = [Int:Bool]()

    func Cell(number: Int) -> some View {
        return Button(action: {
            #if targetEnvironment(simulator)
            print("ONLY AVAILABLE ON REAL DEVICE")
            #else
            disabled[number] = true
            Bluetooth.shared.write(service!, writeCh!, self.handshake(name: self.device.name))
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                Bluetooth.shared.write(service!, writeCh!, self.openCell(name: self.device.name, number: number))
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    disabled[number] = false
                }
            }
            #endif
        }) {
            Text("\(number)")
                .foregroundColor(.white)
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 44)
        }
        .buttonStyle(BorderlessButtonStyle())
        .background(Color.accentColor)
        .cornerRadius(11)
        .disabled(disabled[number] ?? false)
    }

    private let notifies = Notify()

    var body: some View {
        List {
            Button(action: {
                if connected {
                    Bluetooth.shared.disconnect()
                } else {
                    services.removeAll()
                    characteristics.removeAll()
                    Bluetooth.shared.connect(uuid: device.id)
                }
            }) {
                Text(connected ? "Disconnect": "Connect")
                    .foregroundColor(connected ? .red : .green)
            }
            if canControl {
                Section(content: {
                    VStack(alignment: .center, spacing: 10) {
                        ForEach(1...2, id: \.self) { row in
                            HStack(alignment: .center, spacing: 10) {
                                ForEach(1...3, id: \.self) { col in
                                    let cell = (row - 1) * 3 + col
                                    Cell(number: cell)
                                }
                            }
                        }
                    }
                    .listRowInsets(EdgeInsets())
                    .listRowPlatterColor(.clear)
                }, header: {
                    Text("CONTROLS")
                })
            }
            ForEach(services) { service in
                Section(content: {
                    ForEach(characteristics.filter { $0.serviceUuid == service.uuid }) { c in
                        Text("CHARACTERISTIC \(c.uuid)")
                    }
                }, header: {
                    Text("SERVICE \(service.uuid)")
                })
            }
        }
        .navigationTitle(device.name)
        .onAppear {
            notifies.subscribe(.PeripheralConnected) { n in
                if let bool = n.object as? Bool {
                    connected = bool
                }
            }
            notifies.subscribe(.ServicesDiscovered) { n in
                if let cbServices = n.object as? [CBService]? {
                    for cbService in cbServices! {
                        services.append(Service(uuid: cbService.uuid.uuidString))
                    }
                }
            }
            notifies.subscribe(.CharacteristicsDiscovered) { n in
                if let cbService = n.object as? CBService {
                    for ch in cbService.characteristics! {
                        characteristics.append(Characteristic(uuid: ch.uuid.uuidString, serviceUuid: cbService.uuid.uuidString))
                    }
                }
            }
        }
        .onDisappear {
            notifies.unsubscribeAll()
        }
    }

    private func handshake(name: String) -> Data {
        return self.build([ 0xff, 0x55, 0x12, 0x01, 0x07 ] +
                          self.nameToUint8Array(name) +
                          [ 0x01, 0x6C, 0x6F, 0x67, 0x69, 0x6E ])
    }

    private func openCell(name: String, number: Int) -> Data {
        return self.build([ 0xff, 0x55, 0x12, 0x01, 0x08 ] +
                          self.nameToUint8Array(name) +
                          [ 0x02, 0x00, 0x00, UInt8(number), 0x00, 0x00 ])
    }

    private func nameToUint8Array(_ name: String) -> [UInt8] {
        return stride(from: 0, to: name.count, by: 2)
            .map { name[name.index(name.startIndex, offsetBy: $0)...name.index(name.startIndex, offsetBy: $0+1)] }
            .compactMap { UInt8($0, radix: 16) }
    }

    private func build(_ bytes: [UInt8]) -> Data {
        var sum : UInt8 = 0
        for b in bytes {
            sum = sum ^ b
        }
        var data = Data(bytes: bytes, count: bytes.count)
        data.append(sum)
        return data
    }
}
