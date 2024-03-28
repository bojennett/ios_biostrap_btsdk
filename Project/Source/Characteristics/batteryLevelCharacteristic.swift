//
//  batteryCharacteristic.swift
//  biostrapDeviceSDK
//
//  Created by Joseph A. Bennett on 5/12/21.
//

import Foundation
import CoreBluetooth

class batteryLevelCharacteristic: Characteristic {
	
	// MARK: Callbacks
	var updated: ((_ id: String, _ percentage: Int)->())?

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
		if let characteristic = pCharacteristic {
			if let data = characteristic.value { self.updated?(pID, Int(data[0])) }
			else {
				logX?.e ("\(pID): Missing data")
			}
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
	override func didUpdateNotificationState() {
		pConfigured	= true
	}
	
}
