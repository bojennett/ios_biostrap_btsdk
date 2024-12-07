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

    @Published var pConfigured: Bool = false
    
    internal var pCommandQ: CommandQ?

    //--------------------------------------------------------------------------------
    //
    // Return the service UUID string -> This is a class var, so you do not
    // need to create an instance of the object to use it
    //
    //--------------------------------------------------------------------------------
    class var scan_service: CBUUID {
        globals.log.e ("Don't know what to do here.  Perhaps need to override?")
        return org_bluetooth_service.generic_access.UUID
    }
    
    class func hit(_ characteristic: CBCharacteristic) -> Bool {
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
    var isConfigured: Bool { return false }

    //--------------------------------------------------------------------------------
    // Function Name:
    //--------------------------------------------------------------------------------
    //
    //
    //
    //--------------------------------------------------------------------------------
    func didConnect(_ peripheral: CBPeripheral) {
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
    func getAttributes() -> [ String : String ] { return (pAttributes) }

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
    func didDiscoverCharacteristic(_ characteristic: CBCharacteristic) {
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
