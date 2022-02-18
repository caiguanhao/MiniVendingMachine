//
//  ContentView.swift
//  Mini Vending Machine WatchKit Extension
//
//  Created by CGH on 2022/2/15.
//

import SwiftUI

struct ContentView: View {
    @State var devices: [Device] = []
    @State var scanning = false

    private let notifies = Notify()

    var body: some View {
        NavigationView {
            ScrollView {
                Button(action: {
                    if scanning {
                        Bluetooth.shared.stopScan()
                    } else {
                        devices.removeAll()
                        Bluetooth.shared.startScan()
                    }
                    scanning = !scanning
                }) {
                    Text(scanning ? "Stop Scan" : "Scan")
                        .foregroundColor(scanning ? .red : .green)
                }
                ForEach(devices) { device in
                    NavigationLink(destination: PeripheralView(device: device)) {
                        HStack {
                            Text(device.name).multilineTextAlignment(.leading)
                            Spacer()
                            Text(device.quality).foregroundColor(.gray)
                        }
                    }
                }
            }
        }
        .navigationTitle("Bluetooth")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            notifies.subscribe(.PeripheralDiscovered) { n in
                if let device = n.object as? Device {
                    if let idx = devices.firstIndex(where: { $0.id == device.id }) {
                        devices[idx].name = device.name
                        devices[idx].quality = device.quality
                    } else {
                        devices.append(device)
                    }
                    devices.sort { a, b in
                        a.name < b.name
                    }
                }
            }
        }
        .onDisappear {
            if scanning {
                Bluetooth.shared.stopScan()
                scanning = false
            }
            notifies.unsubscribeAll()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
