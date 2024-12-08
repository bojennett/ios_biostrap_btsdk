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
    override class var scan_service: CBUUID {
        return org_bluetooth_service.battery_service.UUID
    }
        
    override class func hit(_ characteristic: CBCharacteristic) -> Bool {
        if characteristic.uuid == org_bluetooth_characteristic.battery_level.UUID {
            return true
        }
        return false
    }
    
    override var isConfigured: Bool {
        return mBatteryLevelCharacteristic.configured
    }
	
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	override init() {
		mBatteryLevelCharacteristic = batteryLevelCharacteristic()
		super.init()
		
		mBatteryLevelCharacteristic.$batteryLevel
			.sink { [weak self] in
				self?.batteryLevel = $0
			}
			.store(in: &pSubscriptions)
		
		mBatteryLevelCharacteristic.$configured
			.sink { [weak self] in
				self?.pConfigured = $0
			}
			.store(in: &pSubscriptions)

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
            globals.log.e ("\(pID): Unhandled: \(characteristic.uuid)")
        }
    }

}
