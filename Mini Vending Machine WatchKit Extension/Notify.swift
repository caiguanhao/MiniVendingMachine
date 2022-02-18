//
//  Notify.swift
//  Mini Vending Machine WatchKit Extension
//
//  Created by CGH on 2022/2/16.
//

import Foundation

enum NotificationName {
    case PeripheralDiscovered
    case PeripheralConnected
    case ServicesDiscovered
    case CharacteristicsDiscovered
}

class Notify {
    private var notifies = [String:NSObjectProtocol]()

    func subscribe(_ name: NotificationName, using block: @escaping (Notification) -> Void) {
        let nameStr = "\(name)"
        if let token = notifies[nameStr] {
            NotificationCenter.default.removeObserver(token)
            notifies.removeValue(forKey: nameStr)
            print("unsubscribe \(nameStr)")
        }
        let token = NotificationCenter.default.addObserver(forName: NSNotification.Name(nameStr),
                                                           object: nil, queue: nil, using: block)
        notifies[nameStr] = token
        print("subscribe \(nameStr)")
    }

    func unsubscribeAll() {
        for (name, token) in notifies {
            NotificationCenter.default.removeObserver(token)
            notifies.removeValue(forKey: name)
            print("unsubscribe \(name)")
        }
    }

    static func send(_ name: NotificationName, _ object: Any?) {
        NotificationCenter.default.post(name: NSNotification.Name("\(name)"), object: object)
    }
}
