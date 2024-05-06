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
