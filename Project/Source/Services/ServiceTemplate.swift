//
//  ServiceTemplate.swift
//  biostrapDeviceSDK
//
//  Created by Joseph Bennett on 12/6/24.
//

import Foundation
import CoreBluetooth
import Combine

open class ServiceTemplate: ObservableObject {
    open var pPeripheral: CBPeripheral?
    open var pID: String = "UNKNOWN"

    open var pAttributes: [ String : String ]
    open var pSubscriptions = Set<AnyCancellable>()

    var allConfigured: (()->())?

    internal var pCommandQ: CommandQ?

    //--------------------------------------------------------------------------------
    //
    // Return the service UUID string -> This is a class var, so you do not
    // need to create an instance of the object to use it
    //
    //--------------------------------------------------------------------------------
    open class var scan_service: CBUUID {
        globals.log.e ("Don't know what to do here.  Perhaps need to override?")
        return org_bluetooth_service.generic_access.UUID
    }
    
    open class func discover_characteristics() -> [ CBUUID ] {
        globals.log.e ("Don't know what to do here.  Perhaps need to override?")
        return ([ CBUUID ]())
    }
    
    open class func hit(_ characteristic: CBCharacteristic) -> Bool {
        globals.log.e ("Don't know what to do here.  Perhaps need to override?")
        return (false)
    }
    
    //--------------------------------------------------------------------------------
    // Function Name:
    //--------------------------------------------------------------------------------
    //
    //
    //
    //--------------------------------------------------------------------------------
    init(_ commandQ: CommandQ?) {
        pAttributes = [ String : String ]()
        pCommandQ = commandQ
    }
    
    //--------------------------------------------------------------------------------
    // Function Name:
    //--------------------------------------------------------------------------------
    //
    //
    //
    //--------------------------------------------------------------------------------
    open var configured: Bool { return false }

    //--------------------------------------------------------------------------------
    // Function Name:
    //--------------------------------------------------------------------------------
    //
    //
    //
    //--------------------------------------------------------------------------------
    open func didConnect(_ peripheral: CBPeripheral) {
        pPeripheral = peripheral
        pID = peripheral.prettyID
    }
    
    //--------------------------------------------------------------------------------
    // Function Name:
    //--------------------------------------------------------------------------------
    //
    //
    //
    //--------------------------------------------------------------------------------
    open func getAttributes() -> [ String : String ] { return (pAttributes) }

    //--------------------------------------------------------------------------------
    // Function Name:
    //--------------------------------------------------------------------------------
    //
    //
    //
    //--------------------------------------------------------------------------------
    open func didDisconnect() {
    }
    
    //--------------------------------------------------------------------------------
    // Function Name:
    //--------------------------------------------------------------------------------
    //
    //
    //
    //--------------------------------------------------------------------------------
    open func didDiscoverCharacteristic(_ characteristic: CBCharacteristic) {
        globals.log.e ("Don't know what to do here.  Perhaps this needs to override?")
    }
    
    //--------------------------------------------------------------------------------
    // Function Name:
    //--------------------------------------------------------------------------------
    //
    //
    //
    //--------------------------------------------------------------------------------
    open func didDiscoverDescriptor(_ characteristic: CBCharacteristic) {
        globals.log.e ("Don't know what to do here.  Perhaps this needs to override?")
    }
    
    //--------------------------------------------------------------------------------
    // Function Name:
    //--------------------------------------------------------------------------------
    //
    //
    //
    //--------------------------------------------------------------------------------
    open func didWriteValue(_ characteristic: CBCharacteristic) {
        if let value = characteristic.value {
            globals.log.e ("Don't know what to do here.  Perhaps this needs to override? (0x\(value.hexString)")
        }
        else {
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
    open func didUpdateValue(_ characteristic: CBCharacteristic) {
        if let value = characteristic.value {
            globals.log.e ("Don't know what to do here.  Perhaps this needs to override? (0x\(value.hexString)")
        }
        else {
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
    open func didUpdateNotificationState(_ characteristic: CBCharacteristic) {
        globals.log.e ("Don't know what to do here for \(characteristic.prettyID).  Perhaps this needs to override? (No data)")
    }
}
