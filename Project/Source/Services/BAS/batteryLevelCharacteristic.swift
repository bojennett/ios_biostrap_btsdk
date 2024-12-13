//
//  batteryCharacteristic.swift
//  biostrapDeviceSDK
//
//  Created by Joseph A. Bennett on 5/12/21.
//

import Foundation
import CoreBluetooth

class batteryLevelCharacteristic: CharacteristicTemplate {
	    
    @Published var batteryLevel: Int?

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	override func didUpdateValue() {
		if let characteristic, let data = characteristic.value {
            batteryLevel = Int(data[0])
		}
        else {
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
        discoverDescriptors()
    }

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	override func didUpdateNotificationState() {
		configured	= true
	}
	
}
