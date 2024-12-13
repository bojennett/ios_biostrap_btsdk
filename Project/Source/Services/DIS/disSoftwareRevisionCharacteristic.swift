//
//  disSoftwareRevisionCharacteristic.swift
//  biostrapDeviceSDK
//
//  Created by Joseph A. Bennett on 10/14/22.
//

import Foundation
import CoreBluetooth

class disSoftwareRevisionCharacteristic: CharacteristicTemplate {
	
	@Published var bluetooth : String = ""
    @Published var algorithms : String = ""
    @Published var sleep : String = ""
	
	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	override func didUpdateValue() {
		configured = true
		
		if let characteristic, let data = characteristic.value {
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
        } else {
            globals.log.e ("\(id): Missing characteristic and/or data")
        }
	}

    //--------------------------------------------------------------------------------
    // Function Name:
    //--------------------------------------------------------------------------------
    //
    //
    //
    //--------------------------------------------------------------------------------
	override func didDiscover(_ characteristic: CBCharacteristic, commandQ: CommandQ?) {
		super.didDiscover(characteristic, commandQ: commandQ)
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
