//
//  CoreBluetoothExtensions.swift
//  universalBTSDK
//
//  Created by Joseph A. Bennett on 1/28/22.
//

import Foundation
import CoreBluetooth

//--------------------------------------------------------------------------------
//
//
//
//--------------------------------------------------------------------------------
extension CBPeripheral {
	var prettyID: String { return self.identifier.uuidString.uppercased() }
}

//--------------------------------------------------------------------------------
//
//
//
//--------------------------------------------------------------------------------
extension CBDescriptor {
	var prettyID: String { return self.uuid.uuidString.uppercased() }
    var deviceID: String {
        if let characteristic = self.characteristic {
            return characteristic.deviceID
        } else {
            return "\(self.prettyID): UNKNOWN (characteristic)"
        }
    }
}

//--------------------------------------------------------------------------------
//
//
//
//--------------------------------------------------------------------------------
extension CBService {
	var prettyID: String { return self.uuid.uuidString.uppercased() }
    var deviceID: String {
        if let peripheral = self.peripheral {
            return peripheral.prettyID
        } else {
            return "\(self.prettyID): UNKNOWN (peripheral)"
        }
    }
}

//--------------------------------------------------------------------------------
//
//
//
//--------------------------------------------------------------------------------
extension CBCharacteristic {
	var prettyID: String { return self.uuid.uuidString.uppercased() }
    var deviceID: String {
        if let service = self.service {
            return service.deviceID
        } else {
            return "\(self.prettyID): UNKNOWN (service)"
        }
    }
}

