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
	var ID: String { return self.identifier.uuidString.uppercased() }
}

//--------------------------------------------------------------------------------
//
//
//
//--------------------------------------------------------------------------------
extension CBDescriptor {
	var prettyID: String { return self.uuid.uuidString.uppercased() }
}

//--------------------------------------------------------------------------------
//
//
//
//--------------------------------------------------------------------------------
extension CBService {
	var prettyID: String { return self.uuid.uuidString.uppercased() }
}

//--------------------------------------------------------------------------------
//
//
//
//--------------------------------------------------------------------------------
extension CBCharacteristic {
	var prettyID: String { return self.uuid.uuidString.uppercased() }
}

