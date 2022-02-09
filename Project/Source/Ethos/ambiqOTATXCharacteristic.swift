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
	override init(_ peripheral: CBPeripheral, characteristic: CBCharacteristic) {
		super.init (peripheral, characteristic: characteristic)
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
