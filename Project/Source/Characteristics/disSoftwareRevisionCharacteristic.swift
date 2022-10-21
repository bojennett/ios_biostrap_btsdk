//
//  disSoftwareRevisionCharacteristic.swift
//  biostrapDeviceSDK
//
//  Created by Joseph A. Bennett on 10/14/22.
//

import Foundation
import CoreBluetooth

class disSoftwareRevisionCharacteristic: Characteristic {
	
	var value				: [String]
		
	//--------------------------------------------------------------------------------
	//
	// Constructor
	//
	//--------------------------------------------------------------------------------
	override init(_ peripheral: CBPeripheral, characteristic: CBCharacteristic) {
		value	= [String]()
		super.init(peripheral, characteristic: characteristic)
	}
	
	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	override func read() {
		if let peripheral = pPeripheral, let characteristic = pCharacteristic {
			peripheral.readValue(for: characteristic)
		}
	}
	
	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	override func didUpdateValue() {
		pConfigured = true
		
		if let characteristic = pCharacteristic {
			if let data = characteristic.value {
				let dataString = String(decoding: data, as: UTF8.self).trimmingCharacters(in: CharacterSet.whitespacesAndNewlines.union(CharacterSet(["\0"])))
				let components = dataString.split(separator: "_")
				
				for component in components { value.append(String(component)) }
			}
			else { log?.e ("\(pID): Missing data") }
		}
		else { log?.e ("\(pID): Missing characteristic") }
	}

}
