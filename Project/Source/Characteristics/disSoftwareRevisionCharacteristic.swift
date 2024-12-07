//
//  disSoftwareRevisionCharacteristic.swift
//  biostrapDeviceSDK
//
//  Created by Joseph A. Bennett on 10/14/22.
//

import Foundation
import CoreBluetooth

class disSoftwareRevisionCharacteristic: Characteristic {
	
	@Published var bluetooth : String = ""
    @Published var algorithms : String = ""
    @Published var sleep : String = ""
	
	#if UNIVERSAL
	var type : biostrapDeviceSDK.biostrapDeviceType	= .unknown
	#endif
		
	//--------------------------------------------------------------------------------
	//
	// Constructor
	//
	//--------------------------------------------------------------------------------
	#if UNIVERSAL
	init(_ peripheral: CBPeripheral, characteristic: CBCharacteristic, commandQ: CommandQ?, type: biostrapDeviceSDK.biostrapDeviceType) {
		super.init(peripheral, characteristic: characteristic, commandQ: commandQ)
		
		self.type	= type
	}
	#else
	override init(_ peripheral: CBPeripheral, characteristic: CBCharacteristic, commandQ: CommandQ?) {
		super.init(peripheral, characteristic: characteristic, commandQ: commandQ)
	}
	#endif
	
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
				bluetooth = ""
				algorithms = ""
				sleep = ""

				let dataString = String(decoding: data, as: UTF8.self).trimmingCharacters(in: CharacterSet.whitespacesAndNewlines.union(CharacterSet(["\0"])))
				let components = dataString.split(separator: "_")
				
				var index = 0
				for component in components {
					if (index == 0) { bluetooth = String(component) }
					if (index == 1) { algorithms = String(component) }
					if (index == 2) { sleep = String(component) }

					index = index + 1
				}
			}
			else { globals.log.e ("\(pID): Missing data") }
		}
		else { globals.log.e ("\(pID): Missing characteristic") }
	}

    //--------------------------------------------------------------------------------
    // Function Name:
    //--------------------------------------------------------------------------------
    //
    //
    //
    //--------------------------------------------------------------------------------
    override func didDiscover() {
        read()
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
}
