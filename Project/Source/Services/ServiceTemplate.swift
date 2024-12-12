//
//  ServiceTemplate.swift
//  biostrapDeviceSDK
//
//  Created by Joseph Bennett on 12/6/24.
//

import Foundation
import CoreBluetooth
import Combine

class ServiceTemplate {
    internal var pID: String = "UNKNOWN"
    internal var subscriptions = Set<AnyCancellable>()

    @Published var configured: Bool = false
    
    //--------------------------------------------------------------------------------
    //
    // Return the service UUID string -> This is a class var, so you do not
    // need to create an instance of the object to use it
    //
    //--------------------------------------------------------------------------------
    class var scan_services: [ CBUUID ] {
        globals.log.e ("Don't know what to do here.  Perhaps need to override?")
        return [ org_bluetooth_service.generic_access.UUID ]
    }
    
    class func hit(_ characteristic: CBCharacteristic) -> Bool {
        globals.log.e ("Don't know what to do here.  Perhaps need to override?")
        return (false)
    }
    
    //--------------------------------------------------------------------------------
    // Function Name:
    //--------------------------------------------------------------------------------
    //
    // Write without response is done.
    //
    //--------------------------------------------------------------------------------
    func didWriteWithoutResponseReady() {
        globals.log.e ("Don't know what to do here.  Perhaps this needs to override?")
    }

    //--------------------------------------------------------------------------------
    // Function Name:
    //--------------------------------------------------------------------------------
    //
    //
    //
    //--------------------------------------------------------------------------------
    func didConnect(_ peripheral: CBPeripheral) {
        pID = peripheral.prettyID
    }
    
    //--------------------------------------------------------------------------------
    // Function Name:
    //--------------------------------------------------------------------------------
    //
    //
    //
    //--------------------------------------------------------------------------------
    func didDisconnect() {
        globals.log.e ("Don't know what to do here.  Perhaps this needs to override?")
    }
    
    //--------------------------------------------------------------------------------
    // Function Name:
    //--------------------------------------------------------------------------------
    //
    //
    //
    //--------------------------------------------------------------------------------
	func didDiscoverCharacteristic(_ characteristic: CBCharacteristic, commandQ: CommandQ?) {
        globals.log.e ("Don't know what to do here.  Perhaps this needs to override?")
    }
    
    //--------------------------------------------------------------------------------
    // Function Name:
    //--------------------------------------------------------------------------------
    //
    //
    //
    //--------------------------------------------------------------------------------
    func didDiscoverDescriptor(_ characteristic: CBCharacteristic) {
        globals.log.e ("Don't know what to do here.  Perhaps this needs to override?")
    }
    
    //--------------------------------------------------------------------------------
    // Function Name:
    //--------------------------------------------------------------------------------
    //
    //
    //
    //--------------------------------------------------------------------------------
    func didWriteValue(_ characteristic: CBCharacteristic) {
        if let value = characteristic.value {
            globals.log.e ("Don't know what to do here.  Perhaps this needs to override? (0x\(value.hexString)")
        } else {
            globals.log.e ("Don't know what to do here.  Perhaps this needs to override? (No data)")
        }
    }
    
    //--------------------------------------------------------------------------------
    // Function Name:
    //--------------------------------------------------------------------------------
    //
    //
    //
    //--------------------------------------------------------------------------------
    func didUpdateValue(_ characteristic: CBCharacteristic) {
        if let value = characteristic.value {
            globals.log.e ("Don't know what to do here.  Perhaps this needs to override? (0x\(value.hexString)")
        } else {
            globals.log.e ("Don't know what to do here.  Perhaps this needs to override? (No data)")
        }
    }
    
    //--------------------------------------------------------------------------------
    // Function Name:
    //--------------------------------------------------------------------------------
    //
    //
    //
    //--------------------------------------------------------------------------------
    func didUpdateNotificationState(_ characteristic: CBCharacteristic) {
        globals.log.e ("Don't know what to do here for \(characteristic.prettyID).  Perhaps this needs to override? (No data)")
    }
}
