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

public enum BodySensorLocation: UInt8 {
    case chest = 0x01
    case wrist = 0x02
    case ankle = 0x04
    case wristWrist = 0x08
    case wristAnkle = 0x10
    case ankleAnkle = 0x20
    
    public var title: String {
        switch self {
        case .chest: return "Chest"
        case .wrist: return "Wrist"
        case .ankle: return "Ankle"
        case .wristWrist: return "Wrist Wrist"
        case .wristAnkle: return "Wrist Ankle"
        case .ankleAnkle: return "Ankle Ankle"
        }
    }
}

class bodySensorLocationCharacteristic: CharacteristicTemplate {

    @Published var location: BodySensorLocation?

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
        if let characteristic, let data = characteristic.value {
            if let location = BodySensorLocation(rawValue: data[0]) {
                globals.log.v ("\(id): Body sensor location: \(location.title)")
                self.location = location
            } else {
                globals.log.e ("\(id): Unknown body sensor location: \(data.hexString)")
            }
        } else {
            globals.log.e ("\(id): Missing characteristic and/or data")
        }
		
		configured = true
    }
}
