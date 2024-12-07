//
//  ambiqOTAService.swift
//  biostrapDeviceSDK
//
//  Created by Joseph Bennett on 12/7/24.
//

import Foundation
import CoreBluetooth
import Combine

class ambiqOTAService: ServiceTemplate {
    
    internal var rxCharacteristic: ambiqOTARXCharacteristic?
    internal var txCharacteristic: ambiqOTATXCharacteristic?

    // Lambdas
    var lambdaStarted: (()->())?
    var lambdaFinished: (()->())?
    var lambdaFailed: ((_ code: Int, _ message: String)->())?
    var lambdaProgress: ((_ percentage: Float)->())?

    let started = PassthroughSubject<Void, Never>()
    let finished = PassthroughSubject<Void, Never>()
    let progress = PassthroughSubject<Float, Never>()
    let failed = PassthroughSubject<(Int, String), Never>()

    //--------------------------------------------------------------------------------
    //
    //
    //
    //--------------------------------------------------------------------------------
    override class var scan_service: CBUUID {
        return CBUUID(string: "00002760-08C2-11E1-9073-0E8AC72E1001")
    }
    
    override class func discover_characteristics() -> [ CBUUID ] {
        return [ org_bluetooth_characteristic.heart_rate_measurement.UUID ]
    }
    
    override class func hit(_ characteristic: CBCharacteristic) -> Bool {
        switch characteristic.uuid {
        case ambiqOTARXCharacteristic.uuid: return true
        case ambiqOTATXCharacteristic.uuid: return true
        default: return false
        }
    }
    
    override var configured: Bool {
        if let rxCharacteristic, let txCharacteristic {
            return txCharacteristic.configured && rxCharacteristic.configured
        }
        
        return false
    }

    //--------------------------------------------------------------------------------
    // Function Name:
    //--------------------------------------------------------------------------------
    //
    //
    //
    //--------------------------------------------------------------------------------
    override func didDiscoverCharacteristic(_ characteristic: CBCharacteristic) {
        switch characteristic.uuid {
        case ambiqOTARXCharacteristic.uuid:
            rxCharacteristic = ambiqOTARXCharacteristic(pPeripheral!, characteristic: characteristic, commandQ: pCommandQ)
            rxCharacteristic?.lambdaStarted = { self.lambdaStarted?() }
            rxCharacteristic?.lambdaFinished = { self.lambdaFinished?() }
            rxCharacteristic?.lambdaFailed = { code, message in self.lambdaFailed?(code, message) }
            rxCharacteristic?.lambdaProgress = { percent in self.lambdaProgress?(percent) }
            
            rxCharacteristic?.started
                .sink { self.started.send() }
                .store(in: &pSubscriptions)

            rxCharacteristic?.finished
                .sink { self.finished.send() }
                .store(in: &pSubscriptions)
            
            rxCharacteristic?.failed
                .sink { code, message in self.failed.send((code, message)) }
                .store(in: &pSubscriptions)

            rxCharacteristic?.progress
                .sink { percent in self.progress.send(percent) }
                .store(in: &pSubscriptions)

        case ambiqOTATXCharacteristic.uuid:
            txCharacteristic = ambiqOTATXCharacteristic(pPeripheral!, characteristic: characteristic, commandQ: pCommandQ)
            txCharacteristic?.discoverDescriptors()
            
        default: return
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
        switch characteristic.uuid {
        case ambiqOTARXCharacteristic.uuid: globals.log.e ("\(pID) RX chacteristic - should not be here")
        case ambiqOTATXCharacteristic.uuid: txCharacteristic?.didDiscoverDescriptor()
        default: globals.log.e ("\(pID): Unhandled: \(characteristic.uuid)");
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
        switch characteristic.uuid {
        case ambiqOTARXCharacteristic.uuid: globals.log.e ("\(pID) 'RX Characteristic' - should not be here")
        case ambiqOTATXCharacteristic.uuid: txCharacteristic?.didUpdateNotificationState()
        default: globals.log.e ("\(pID): Unhandled: \(characteristic.uuid)");
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
        switch characteristic.uuid {
        case ambiqOTARXCharacteristic.uuid: globals.log.e ("\(pID) 'RX characteristic' - should not be here")
        case ambiqOTATXCharacteristic.uuid:
            // Commands to RX come in on TX, causes RX to do next step
            if let value = characteristic.value {
                rxCharacteristic?.didUpdateTXValue(value)
            } else {
                globals.log.e ("\(pID) 'TX Characteristic' - No data received for RX command")
            }
        default: globals.log.e ("\(pID): Unhandled: \(characteristic.uuid)");
        }
    }
}
