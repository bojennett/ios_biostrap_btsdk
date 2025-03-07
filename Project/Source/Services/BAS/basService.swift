//
//  basService.swift
//  biostrapDeviceSDK
//
//  Created by Joseph Bennett on 12/6/24.
//

import Foundation
import CoreBluetooth
import Combine

class basService: ServiceTemplate {
    internal var mBatteryLevelCharacteristic: batteryLevelCharacteristic
    
    @Published var batteryLevel: Int?

    //--------------------------------------------------------------------------------
    //
    //
    //
    //--------------------------------------------------------------------------------
    override class var scan_services: [ CBUUID ] {
        return [ org_bluetooth_service.battery_service.UUID ]
    }
        
    override class func hit(_ characteristic: CBCharacteristic) -> Bool {
        if characteristic.uuid == org_bluetooth_characteristic.battery_level.UUID {
            return true
        }
        return false
    }
    
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	override init() {
		mBatteryLevelCharacteristic = batteryLevelCharacteristic()
		super.init()
		
		mBatteryLevelCharacteristic.$batteryLevel.sink { [weak self] in self?.batteryLevel = $0 }.store(in: &subscriptions)
		mBatteryLevelCharacteristic.$configured.sink { [weak self] in self?.configured = $0 }.store(in: &subscriptions)
	}

    //--------------------------------------------------------------------------------
    // Function Name:
    //--------------------------------------------------------------------------------
    //
    //
    //
    //--------------------------------------------------------------------------------
	override func didDiscoverCharacteristic(_ characteristic: CBCharacteristic, commandQ: CommandQ?) {
        if characteristic.uuid == org_bluetooth_characteristic.battery_level.UUID {
			mBatteryLevelCharacteristic.didDiscover(characteristic, commandQ: commandQ)
        } else {
            globals.log.e ("\(id): Unhandled: \(characteristic.uuid)")
        }
    }
    
    //--------------------------------------------------------------------------------
    // Function Name:
    //--------------------------------------------------------------------------------
    //
    //
    //
    //--------------------------------------------------------------------------------
    override func didDiscoverDescriptor(_ characteristic: CBCharacteristic) {
        if characteristic.uuid == org_bluetooth_characteristic.battery_level.UUID {
            mBatteryLevelCharacteristic.didDiscoverDescriptor()
        } else {
            globals.log.e ("\(id): Unhandled: \(characteristic.uuid)")
        }
    }

    //--------------------------------------------------------------------------------
    // Function Name:
    //--------------------------------------------------------------------------------
    //
    //
    //
    //--------------------------------------------------------------------------------
    override func didUpdateNotificationState(_ characteristic: CBCharacteristic) {
        if characteristic.uuid == org_bluetooth_characteristic.battery_level.UUID {
            mBatteryLevelCharacteristic.didUpdateNotificationState()
        } else {
            globals.log.e ("\(id): Unhandled: \(characteristic.uuid)")
        }
    }

    //--------------------------------------------------------------------------------
    // Function Name:
    //--------------------------------------------------------------------------------
    //
    //
    //
    //--------------------------------------------------------------------------------
    override func didUpdateValue(_ characteristic: CBCharacteristic) {
        if characteristic.uuid == org_bluetooth_characteristic.battery_level.UUID {
            mBatteryLevelCharacteristic.didUpdateValue()
        } else {
            globals.log.e ("\(id): Unhandled: \(characteristic.uuid)")
        }
    }

}
