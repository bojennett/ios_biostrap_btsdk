//
//  bodySensorLocationCharacteristic.swift
//  biostrapDeviceSDK
//
//  Created by Joseph Bennett on 12/7/24.
//

import Foundation

import Foundation
import CoreBluetooth
import Combine

class bodySensorLocationCharacteristic: CharacteristicTemplate {
    
    // MARK: Callbacks
    var lambdaUpdated: ((_ id: String, _ epoch: Int, _ hr: Int, _ rr: [Double])->())?
    let updated = PassthroughSubject<(Int, Int, [Double]), Never>()

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
                globals.log.v ("\(pID): \(data.hexString)")
            }
            else {
                globals.log.e ("\(pID): Missing data")
            }
        }
        else { globals.log.e ("\(pID): Missing characteristic") }
		
		configured = true
    }
}
