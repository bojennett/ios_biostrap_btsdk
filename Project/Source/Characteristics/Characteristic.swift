//
//  Characteristic.swift
//  biostrapDeviceSDK
//
//  Created by Joseph A. Bennett on 5/12/21.
//

import Foundation
import CoreBluetooth

class Characteristic {
	
	// MARK: Internal Variables
	internal var pPeripheral		: CBPeripheral?
	internal var pCharacteristic	: CBCharacteristic?
	internal var pID				: String				= "UNKNOWN"
	internal var pConfigured		: Bool					= false

	// MARK: Public Variables
	var configured: Bool {
		return (pConfigured)
	}

	//--------------------------------------------------------------------------------
	//
	// Constructor
	//
	//--------------------------------------------------------------------------------
	init(_ peripheral: CBPeripheral, characteristic: CBCharacteristic) {
		pID				= peripheral.prettyID
		pPeripheral		= peripheral
		pCharacteristic	= characteristic
		pConfigured		= false
	}
	
	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func read() {
		log?.e ("\(pID): Did you mean to override?")
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func didWrite() {
		log?.e ("\(pID): Did you mean to override?")
	}
	
	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func didUpdateValue() {
		log?.e ("\(pID): Did you mean to override?")
	}
	
	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func didUpdateNotificationState() {
		log?.e ("\(pID): Did you mean to override?")
	}
	
	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func didDiscoverDescriptor() {
		if let peripheral = pPeripheral, let characteristic = pCharacteristic {
			peripheral.setNotifyValue(true, for: characteristic)
		}
	}
	
	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func discoverDescriptors() {
		if let peripheral = pPeripheral, let characteristic = pCharacteristic {
			peripheral.discoverDescriptors(for: characteristic)
		}
	}
	
	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	// Write without response is done.  Will only happen for OTA, since that uses
	// write without responses
	//
	//--------------------------------------------------------------------------------
	func isReady() {
		log?.e ("\(pID): Did you mean to override?")
	}
}
