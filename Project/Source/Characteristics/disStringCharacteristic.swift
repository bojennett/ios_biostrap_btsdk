//
//  disStringCharacteristic.swift
//  biostrapDeviceSDK
//
//  Created by Joseph A. Bennett on 5/12/21.
//

import Foundation
import CoreBluetooth

class disStringCharacteristic: Characteristic {
	
	@Published var value : String = ""
	
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
}
