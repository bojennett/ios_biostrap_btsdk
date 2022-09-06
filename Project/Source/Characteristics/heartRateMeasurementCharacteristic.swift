//
//  heartRateMeasurementCharacteristic.swift
//  biostrapDeviceSDK
//
//  Created by Joseph A. Bennett on 5/12/21.
//

import Foundation
import CoreBluetooth

class heartRateMeasurementCharacteristic: Characteristic {
	
	// MARK: Callbacks
	var updated: ((_ id: String, _ hr: Int, _ rr: [Double])->())?

	//--------------------------------------------------------------------------------
	// Function Name: mParse
	//--------------------------------------------------------------------------------
	//
	// Parse a bluetooth update from the Heart Rate Characteristic
	//
	//--------------------------------------------------------------------------------
	internal func mParse(_ data: Data?) -> (Int, [Double]) {
		var hr			: Int = 0
		var rr			: [Double] = [Double]()
		
		if let data = data {
			let hrflags		= data[0]
			
			let rr_present	: Bool = ((hrflags & 0x10) != 0)
			let ee_present	: Bool = ((hrflags & 0x08) != 0)
			let _			: Int  = ((Int(hrflags) & 0x06) >> 1)	// sc_status
			let hr_uint16	: Bool = ((hrflags & 0x01) != 0)
			
			if (hr_uint16 == true) {
				hr = (Int(data[2]) << 8) | Int(data[1])
			}
			else {
				hr = Int(data[1])
			}
			
			if (rr_present) {
				var index	= 2									// flags is byte 0, HR is byte 1
				if (hr_uint16 == true)	{ index = index + 1 }	// HR is also byte 2
				if (ee_present == true) { index = index + 2 }	// Energy Extended present (no callback for this, so skip it)
				
				while (index < data.count) {
					rr.append(1000.0 * Double((Int(data[index + 1]) << 8) | Int(data[index])) / 1024.0)
					index = index + 2
				}
			}
			
		}
		
		return (hr, rr)
	}

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
		if let characteristic = pCharacteristic {
			if let data = characteristic.value {
				let (hr, rr) = mParse(data)
				self.updated?(pID, hr, rr)
			}
			else {
				log?.e ("\(pID): Missing data")
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
