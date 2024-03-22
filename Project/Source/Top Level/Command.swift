//
//  Cmomand.swift
//  biostrapDeviceSDK
//
//  Created by Joseph Bennett on 3/21/24.
//

import Foundation
import CoreBluetooth

class Command {
	
	enum commandType {
		case read
		case write
		
		var title: String {
			switch (self) {
			case .read: return "Read"
			case .write: return "Write"
			}
		}
	}
	
	var command: commandType?
	var characteristic: CBCharacteristic?
	var data: Data?
	var type: CBCharacteristicWriteType?

	// Read
	init(_ characteristic: CBCharacteristic?) {
		self.command = .read
		self.characteristic = characteristic
	}

	// Write
	init(_ characteristic: CBCharacteristic?, data: Data, type: CBCharacteristicWriteType) {
		self.command = .write
		self.characteristic = characteristic
		self.data = data
		self.type = type
	}
}

