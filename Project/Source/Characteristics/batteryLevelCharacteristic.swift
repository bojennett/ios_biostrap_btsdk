//
//  batteryCharacteristic.swift
//  biostrapDeviceSDK
//
//  Created by Joseph A. Bennett on 5/12/21.
//

import Foundation
import CoreBluetooth

class batteryLevelCharacteristic: Characteristic {
	    
    @Published var batteryLevel: Int?

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	override func didUpdateValue() {
		if let characteristic = pCharacteristic {
            if let data = characteristic.value {
                batteryLevel = Int(data[0])
            } else {
				globals.log.e ("\(pID): Missing data")
			}
		}
		else { globals.log.e ("\(pID): Missing characteristic") }
	}
    
    //--------------------------------------------------------------------------------
    // Function Name:
    //--------------------------------------------------------------------------------
    //
    //
    //
    //--------------------------------------------------------------------------------
    override func didDiscover() {
        globals.log.v ("\(pID): Read it and enable notifications")
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
		pConfigured	= true
	}
	
}
