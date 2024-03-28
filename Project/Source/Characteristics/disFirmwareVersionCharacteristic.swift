//
//  disFirmwareVersionCharacteristic.swift
//  biostrapDeviceSDK
//
//  Created by Joseph A. Bennett on 8/31/22.
//

import Foundation
import CoreBluetooth

class disFirmwareVersionCharacteristic: Characteristic {
	
	var value			: String	= ""
	
	internal var mMajor	: Int		= 0
	internal var mMinor	: Int		= 0
	internal var mBuild	: Int		= 0
	
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
				value = String(decoding: data, as: UTF8.self).trimmingCharacters(in: CharacterSet.whitespacesAndNewlines.union(CharacterSet(["\0"])))
				let values = value.split(separator: ".")
				
				if (values.count == 3) {
					if let test = Int(values[0]) { mMajor = test }
					if let test = Int(values[1]) { mMinor = test }
					if let test = Int(values[2]) { mBuild = test }
				}
			}
			else { logX?.e ("\(pID): Missing data") }
		}
		else { logX?.e ("\(pID): Missing characteristic") }
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
