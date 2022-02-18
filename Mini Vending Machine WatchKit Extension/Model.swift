//
//  Model.swift
//  Mini Vending Machine WatchKit Extension
//
//  Created by CGH on 2022/2/15.
//

import Foundation

struct Device: Identifiable {
    let id: UUID
    var name: String
    var quality: String
}

struct Service: Identifiable {
    let id = UUID()
    let uuid: String
}

struct Characteristic: Identifiable {
    let id = UUID()
    let uuid: String
    let serviceUuid: String
}
