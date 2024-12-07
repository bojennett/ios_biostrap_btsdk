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

class bodySensorLocationCharacteristic: Characteristic {
    
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
    override func didDiscover() {
        globals.log.v ("\(pID): read")
        pConfigured = true
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
    }
}
