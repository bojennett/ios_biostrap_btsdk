//
//  ambiqOTATXCharacteristic.swift
//  AmbiqOTATest
//
//  Created by Joseph Bennett on 9/21/21.
//

import Foundation
import CoreBluetooth

class ambiqOTATXCharacteristic: Characteristic {
	
    override class var uuid: CBUUID {
        return CBUUID(string: "00002760-08C2-11E1-9073-0E8AC72E0002")
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
