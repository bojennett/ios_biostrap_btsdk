//
//  disStringCharacteristic.swift
//  biostrapDeviceSDK
//
//  Created by Joseph A. Bennett on 5/12/21.
//

import Foundation
import CoreBluetooth

class disStringCharacteristic: Characteristic {
	
	var value	: String	= ""
	
	//--------------------------------------------------------------------------------
	//
	// Constructor
	//
	//--------------------------------------------------------------------------------
	override init(_ peripheral: CBPeripheral, characteristic: CBCharacteristic, commandQ: CommandQ?) {
		super.init (peripheral, characteristic: characteristic, commandQ: commandQ)
	}
	
	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	override func read() {
		pCommandQ?.read(pCharacteristic)
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
				let result = String(decoding: data, as: UTF8.self)
				
				value = ""
				for char in result {
					if (char.isASCII) {
						if ((char.asciiValue! >= 0x20) && (char.asciiValue! <= 0x7E)) {
							value = "\(value)\(char)"
						}
						else { break }
					}
				}
			}
			else { log?.e ("\(pID): Missing data") }
		}
		else { log?.e ("\(pID): Missing characteristic") }
	}
}
