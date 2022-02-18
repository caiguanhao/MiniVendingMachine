//
//  Bluetooth.swift
//  Mini Vending Machine WatchKit Extension
//
//  Created by CGH on 2022/2/15.
//

import Foundation
import CoreBluetooth

class Bluetooth: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    static let shared = Bluetooth()

    private var peripheral : CBPeripheral!
    private var manager : CBCentralManager!

    #if targetEnvironment(simulator)
    func startScan() {
        randomStarted = true
        randomUpdates(nil)
    }

    func stopScan() {
        randomStarted = false
    }

    private func randomName(_ length: Int) -> String {
        let vowels = "AEIOUY"
        let letters = "BCDFGHJKLMNPQRSTVWXZ"
        var out = ""
        for i in 0..<length {
            if i % 2 == 0 {
                out += String(letters.randomElement()!)
            } else {
                out += String(vowels.randomElement()!)
            }
        }
        return out.prefix(1).uppercased() + out.dropFirst().lowercased()
    }

    private var randomStarted = false

    private func randomUpdates(_ input: [UUID:String]?) {
        if !self.randomStarted {
            return
        }
        let data: [UUID:String]
        if input == nil {
            let names = [UUID?](repeating: nil, count: 5).map { _ in (UUID(), randomName(5) + " " + randomName(5)) }
            data = Dictionary(uniqueKeysWithValues: names)
        } else {
            data = input!
        }
        for (uuid, name) in data {
            Timer.scheduledTimer(withTimeInterval: Double.random(in: 0.2..<1.0), repeats: false) { _ in
                let quality = Int.random(in: 40..<100)
                let device = Device(id: uuid, name: name, quality: "\(quality)%")
                Notify.send(.PeripheralDiscovered, device)
            }
        }
        Timer.scheduledTimer(withTimeInterval: 1.2, repeats: false) { _ in
            self.randomUpdates(data)
        }
    }
    #else
    func startScan() {
        self.manager = CBCentralManager.init(delegate: self, queue: DispatchQueue.main)
    }

    func stopScan() {
        if self.manager == nil {
            return
        }
        self.manager.stopScan()
    }
    #endif

    func disconnect() {
        if self.peripheral != nil {
            self.manager.cancelPeripheralConnection(self.peripheral)
            self.peripheral = nil
        }
    }

    func connect(uuid: UUID) {
        self.peripheral = self.manager.retrievePeripherals(withIdentifiers: [uuid]).first
        if self.peripheral != nil {
            self.manager.connect(self.peripheral, options: nil)
        }
    }

    func write(_ service: String, _ char: String, _ data: Data) {
        if self.peripheral != nil {
            if let s = self.peripheral.services?.filter({ $0.uuid.uuidString == service }).first {
                if let c = s.characteristics?.filter({ $0.uuid.uuidString == char }).first {
                    self.peripheral.writeValue(data, for: c, type: .withResponse)
                }
            }
        }
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            self.manager.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
        default:
            break
        }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        if peripheral.name == nil {
            return
        }
        let name = peripheral.name ?? "(NO NAME)"
        let quality = min(max(2 * (RSSI.intValue + 100), 0), 100)
        let device = Device(id: peripheral.identifier, name: name, quality: "\(quality)%")
        Notify.send(.PeripheralDiscovered, device)
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        Notify.send(.ServicesDiscovered, peripheral.services)
        for service in peripheral.services! {
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        Notify.send(.CharacteristicsDiscovered, service)
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        Notify.send(.PeripheralConnected, true)
        peripheral.delegate = self
        peripheral.discoverServices(nil)
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        Notify.send(.PeripheralConnected, false)
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        let hexString = characteristic.value!.map { String(format: "%02hhx", $0) }.joined()
        print("RECEIVED", hexString)
    }
}

