//
//  disFirmwareVersionCharacteristic.swift
//  biostrapDeviceSDK
//
//  Created by Joseph A. Bennett on 8/31/22.
//

import Foundation
import CoreBluetooth

class disFirmwareVersionCharacteristic: CharacteristicTemplate {
	
    @Published var value : String = ""
	
	internal var mMajor	: Int = 0
	internal var mMinor	: Int = 0
	internal var mBuild	: Int = 0
	
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
            value = String(decoding: data, as: UTF8.self).trimmingCharacters(in: CharacterSet.whitespacesAndNewlines.union(CharacterSet(["\0"])))
            let values = value.split(separator: ".")
            
            if (values.count == 3) {
                if let test = Int(values[0]) { mMajor = test }
                if let test = Int(values[1]) { mMinor = test }
                if let test = Int(values[2]) { mBuild = test }
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
	func greaterThan(_ compare: String) -> Bool { return value.versionGreaterThan(compare, separator: ".") }
	func lessThan(_ compare: String) -> Bool { return value.versionLessThan(compare, separator: ".") }
	func equalTo(_ compare: String) -> Bool { return value.versionEqualTo(compare, separator: ".") }
}
