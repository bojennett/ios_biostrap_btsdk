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
    
    internal var mBatteryLevelCharacteristic    : batteryLevelCharacteristic?
    
    @Published var batteryLevel: Int?
    
    //--------------------------------------------------------------------------------
    //
    // Return the service UUID string -> This is a class var, so you do not
    // need to create an instance of the object to use it
    //
    //--------------------------------------------------------------------------------
    override class var scan_service: CBUUID {
        return org_bluetooth_service.battery_service.UUID
    }
    
    override class func discover_characteristics() -> [ CBUUID ] {
        return [ org_bluetooth_characteristic.battery_level.UUID ]
    }
    
    override class func hit(_ characteristic: CBCharacteristic) -> Bool {
        if characteristic.uuid == org_bluetooth_characteristic.battery_level.UUID {
            return true
        }
        return false
    }
    
    override var configured: Bool {
        return mBatteryLevelCharacteristic?.configured ?? false
    }

    //--------------------------------------------------------------------------------
    // Function Name:
    //--------------------------------------------------------------------------------
    //
    //
    //
    //--------------------------------------------------------------------------------
    override func didDiscoverCharacteristic(_ characteristic: CBCharacteristic) {
        if characteristic.uuid == org_bluetooth_characteristic.battery_level.UUID {
            mBatteryLevelCharacteristic = batteryLevelCharacteristic(pPeripheral!, characteristic: characteristic, commandQ: pCommandQ)
            mBatteryLevelCharacteristic?.$batteryLevel
                .sink { [weak self] in
                    self?.batteryLevel = $0
                }
                .store(in: &pSubscriptions)
            
            mBatteryLevelCharacteristic?.didDiscover()
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
            mBatteryLevelCharacteristic?.didDiscoverDescriptor()
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
            mBatteryLevelCharacteristic?.didUpdateNotificationState()
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
            mBatteryLevelCharacteristic?.didUpdateValue()
        } else {
            globals.log.e ("\(pID): Unhandled characteristic update: \(characteristic.uuid)")
        }
    }

}
