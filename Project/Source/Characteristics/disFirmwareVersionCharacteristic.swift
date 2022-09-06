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
				value = String(decoding: data, as: UTF8.self)
				let values = value.split(separator: ".")
				
				if (values.count == 3) {
					if let test = Int(values[0]) { mMajor = test }
					if let test = Int(values[1]) { mMinor = test }
					if let test = Int(values[2]) { mBuild = test }
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
	func greaterThan(_ compare: String) -> Bool {
		let values = compare.split(separator: ".")
		
		if (values.count == 3) {
			if let test = Int(values[0]) {
				if (mMajor > test) { return (true) }
				if (mMajor < test) { return (false) }
			}
			else { return (false) }
			
			if let test = Int(values[1]) {
				if (mMinor > test) { return (true) }
				if (mMinor < test) { return (false) }
			}
			else { return (false) }
			
			if let test = Int(values[2]) {
				if (mBuild > test) { return (true) }
				if (mBuild < test) { return (false) }
			}
			else { return (false) }
		}

		return (false)
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func lessThan(_ compare: String) -> Bool {
		let values = compare.split(separator: ".")
		
		if (values.count == 3) {
			if let test = Int(values[0]) {
				if (mMajor < test) { return (true) }
				if (mMajor > test) { return (false) }
			}
			else { return (false) }
			
			if let test = Int(values[1]) {
				if (mMinor < test) { return (true) }
				if (mMinor > test) { return (false) }
			}
			else { return (false) }
			
			if let test = Int(values[2]) {
				if (mBuild < test) { return (true) }
				if (mBuild > test) { return (false) }
			}
			else { return (false) }
		}
		
		return (false)
	}


	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func equalTo(_ compare: String) -> Bool {
		let values = compare.split(separator: ".")
		
		if (values.count == 3) {
			if let test = Int(values[0]) {
				if (mMajor != test) { return (false) }
			}
			else { return (false) }
			
			if let test = Int(values[1]) {
				if (mMinor != test) { return (false) }
			}
			else { return (false) }
			
			if let test = Int(values[2]) {
				if (mBuild != test) { return (false) }
			}
			else { return (false) }
			
			return (true)
		}

		return (false)
	}

}
