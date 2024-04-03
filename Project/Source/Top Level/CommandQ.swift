//
//  CommandQ.swift
//  biostrapDeviceSDK
//
//  Created by Joseph Bennett on 3/21/24.
//

import Foundation
import CoreBluetooth

class CommandQ {
	
	internal var entries: [Command]
	internal var peripheral: CBPeripheral?

	init(_ peripheral: CBPeripheral?) {
		self.entries = [Command]()
		self.peripheral = peripheral
	}
	
	//----------------------------------------------------------------------------
	// Function Name:
	//----------------------------------------------------------------------------
	//
	//
	//
	//----------------------------------------------------------------------------
	func read(_ characteristic: CBCharacteristic?) {
		let command = Command(characteristic)
		add(command)
	}
	
	//----------------------------------------------------------------------------
	// Function Name:
	//----------------------------------------------------------------------------
	//
	//
	//
	//----------------------------------------------------------------------------
	func write(_ characteristic: CBCharacteristic?, data: Data, type: CBCharacteristicWriteType) {
		let command = Command(characteristic, data: data, type: type)
		add(command)
	}
	
	//----------------------------------------------------------------------------
	// Function Name:
	//----------------------------------------------------------------------------
	//
	//
	//
	//----------------------------------------------------------------------------
	internal func add(_ command: Command) {
		entries.append(command)
		if (entries.count == 1) { next() }
	}
	
	//----------------------------------------------------------------------------
	// Function Name:
	//----------------------------------------------------------------------------
	//
	//
	//
	//----------------------------------------------------------------------------
	internal func next() {
		if let peripheral, let entry = entries.first, let characteristic = entry.characteristic {
			switch (entry.command) {
			case .read:
				peripheral.readValue(for: characteristic)
				remove() // Can remove immediately as these cannot be gates for anything by their very nature
			case .write:
				if let data = entry.data, let type = entry.type {
					peripheral.writeValue(data, for: characteristic, type: type)
					
					// If no response required, nothing is going to come in to tell me to remove the item from the queue
					if (type == .withoutResponse) { remove() }
				}
				else {
					if entry.data == nil {
						globals.log.e ("No data to write for \(characteristic.prettyID)")
					}
					
					if entry.type == nil {
						globals.log.e ("No write type for \(characteristic.prettyID)")
					}
					remove()
				}
			default:
				globals.log.e ("Command not defined!")
				remove()
			}
		}
		else {
			if peripheral == nil { globals.log.e ("No peripheral") }
			else if let entry = entries.first {
				if entry.characteristic == nil { globals.log.e ("No characteristic") }
			}
			else { globals.log.e ("Command queue empty") }
		}
	}
	
	//----------------------------------------------------------------------------
	// Function Name:
	//----------------------------------------------------------------------------
	//
	//
	//
	//----------------------------------------------------------------------------
	internal func remove() {
		if (entries.count > 0) {
			entries.removeFirst()
			if entries.count > 0 { next() }
		}
		else {
			globals.log.e ("No commands to remove")
		}
	}

	//----------------------------------------------------------------------------
	// Function Name:
	//----------------------------------------------------------------------------
	//
	//
	//
	//----------------------------------------------------------------------------
	internal func flush() {
		while (entries.count > 0) {
			if let current = entries.first {
				if let command = current.command {
					globals.log.e ("Flush: \(command.title)")
				}
				else {
					globals.log.e ("Flush: Unknown command")
				}
			}
			entries.removeFirst()
		}
		
		globals.log.v ("All commands flushed")
	}

}
