//
//  disSoftwareRevisionCharacteristic.swift
//  biostrapDeviceSDK
//
//  Created by Joseph A. Bennett on 10/14/22.
//

import Foundation
import CoreBluetooth

class disSoftwareRevisionCharacteristic: Characteristic {
	
	var bluetooth			: String	= ""
	var algorithms			: String	= ""
	var medtor				: String	= ""
		
	//--------------------------------------------------------------------------------
	//
	// Constructor
	//
	//--------------------------------------------------------------------------------
	override init(_ peripheral: CBPeripheral, characteristic: CBCharacteristic) {
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
				bluetooth	= ""
				algorithms	= ""
				medtor		= ""

				let dataString = String(decoding: data, as: UTF8.self).trimmingCharacters(in: CharacterSet.whitespacesAndNewlines.union(CharacterSet(["\0"])))
				let components = dataString.split(separator: "_")
				
				var index = 0
				for component in components {
					if (index == 0) { bluetooth		= String(component) }
					if (index == 1) { algorithms	= String(component) }
					if (index == 2) { medtor		= String(component) }
					
					index = index + 1
				}
			}
			else { log?.e ("\(pID): Missing data") }
		}
		else { log?.e ("\(pID): Missing characteristic") }
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func bluetoothGreaterThan(_ compare: String) -> Bool { return bluetooth.versionGreaterThan(compare, separator: ".") }
	func bluetoothLessThan(_ compare: String) -> Bool { return bluetooth.versionLessThan(compare, separator: ".") }
	func bluetoothEqualTo(_ compare: String) -> Bool { return bluetooth.versionEqualTo(compare, separator: ".") }

	func algorithmsGreaterThan(_ compare: String) -> Bool { return algorithms.versionGreaterThan(compare, separator: ".") }
	func algorithmsLessThan(_ compare: String) -> Bool { return algorithms.versionLessThan(compare, separator: ".") }
	func algorithmsEqualTo(_ compare: String) -> Bool { return algorithms.versionEqualTo(compare, separator: ".") }

	#if UNIVERSAL || ETHOS
	func medtorGreaterThan(_ compare: String) -> Bool { return medtor.versionGreaterThan(compare, separator: ".") }
	func medtorLessThan(_ compare: String) -> Bool { return medtor.versionLessThan(compare, separator: ".") }
	func medtorEqualTo(_ compare: String) -> Bool { return medtor.versionEqualTo(compare, separator: ".") }
	#endif
}
