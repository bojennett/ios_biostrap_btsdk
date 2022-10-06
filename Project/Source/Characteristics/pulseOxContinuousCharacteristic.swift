//
//  pulseOxContinuousCharacteristic.swift
//  biostrapDeviceSDK
//
//  Created by Joseph A. Bennett on 10/6/22.
//

import Foundation
import CoreBluetooth

class pulseOxContinuousCharacteristic: Characteristic {
	
	// MARK: Callbacks
	var updated: ((_ id: String, _ spo2: Float, _ hr: Float)->())?

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
				if (data.count >= 5) {
					//let flags		= data[0]	// TODO: this would need to be checked for 'fast', 'slow', other fields

					let spo2		= data.subdata(in: Range(NSMakeRange( 1, 2))!).leFloat16
					let hr			= data.subdata(in: Range(NSMakeRange( 3, 2))!).leFloat16
					
					self.updated?(pID, spo2, hr)
				}
				else {
					log?.e ("\(pID): Need at least 5 bytes (flags + spo2 + hr).  Only have \(data.count)")
				}				
			}
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
	override func didUpdateNotificationState() {
		pConfigured	= true
	}

}
