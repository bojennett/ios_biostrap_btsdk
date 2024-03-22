//
//  ambiqOTATXCharacteristic.swift
//  AmbiqOTATest
//
//  Created by Joseph Bennett on 9/21/21.
//

import Foundation
import CoreBluetooth

class ambiqOTATXCharacteristic: Characteristic {
	
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
	override func didUpdateNotificationState() {
		pConfigured	= true
	}
	

}
