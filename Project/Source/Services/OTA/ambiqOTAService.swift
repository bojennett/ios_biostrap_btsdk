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
    
    internal var rxCharacteristic: ambiqOTARXCharacteristic
    internal var txCharacteristic: ambiqOTATXCharacteristic

    let started = PassthroughSubject<Void, Never>()
    let finished = PassthroughSubject<Void, Never>()
    let progress = PassthroughSubject<Float, Never>()
    let failed = PassthroughSubject<(Int, String), Never>()

    //--------------------------------------------------------------------------------
    //
    //
    //
    //--------------------------------------------------------------------------------
    override class var scan_services: [ CBUUID ] {
        return [ CBUUID(string: "00002760-08C2-11E1-9073-0E8AC72E1001") ]
    }
    
    override class func hit(_ characteristic: CBCharacteristic) -> Bool {
        switch characteristic.uuid {
        case ambiqOTARXCharacteristic.uuid: return true
        case ambiqOTATXCharacteristic.uuid: return true
        default: return false
        }
    }
    
	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	private func setupSubscribers() {
		rxCharacteristic.started
			.sink { self.started.send() }
			.store(in: &pSubscriptions)

		rxCharacteristic.finished
			.sink { self.finished.send() }
			.store(in: &pSubscriptions)
		
		rxCharacteristic.failed
			.sink { code, message in self.failed.send((code, message)) }
			.store(in: &pSubscriptions)

		rxCharacteristic.progress
			.sink { percent in self.progress.send(percent) }
			.store(in: &pSubscriptions)
				
		Publishers.CombineLatest(txCharacteristic.$configured, rxCharacteristic.$configured)
			.sink { [weak self] txConfigured, rxConfigured in
				self?.pConfigured = txConfigured && rxConfigured
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
    override init() {
		rxCharacteristic = ambiqOTARXCharacteristic()
		txCharacteristic = ambiqOTATXCharacteristic()
        super.init()
		
		setupSubscribers()
    }

    //--------------------------------------------------------------------------------
    // Function Name:
    //--------------------------------------------------------------------------------
    //
    //
    //
    //--------------------------------------------------------------------------------
    func start(_ data: Data) {
        rxCharacteristic.start(data)
    }
    
    //--------------------------------------------------------------------------------
    // Function Name:
    //--------------------------------------------------------------------------------
    //
    //
    //
    //--------------------------------------------------------------------------------
    func cancel() {
        rxCharacteristic.cancel()
    }
    
    //--------------------------------------------------------------------------------
    // Function Name:
    //--------------------------------------------------------------------------------
    //
    //
    //
    //--------------------------------------------------------------------------------
    override func isReady() {
        rxCharacteristic.isReady()
    }
    
    //--------------------------------------------------------------------------------
    // Function Name:
    //--------------------------------------------------------------------------------
    //
    //
    //
    //--------------------------------------------------------------------------------
	override func didDiscoverCharacteristic(_ characteristic: CBCharacteristic, commandQ: CommandQ?) {
        switch characteristic.uuid {
        case ambiqOTARXCharacteristic.uuid:
			rxCharacteristic.didDiscover(characteristic, commandQ: commandQ)
            
        case ambiqOTATXCharacteristic.uuid:
			txCharacteristic.didDiscover(characteristic, commandQ: commandQ)
            
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
        case ambiqOTATXCharacteristic.uuid: txCharacteristic.didDiscoverDescriptor()
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
        case ambiqOTATXCharacteristic.uuid: txCharacteristic.didUpdateNotificationState()
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
                rxCharacteristic.didUpdateTXValue(value)
            } else {
                globals.log.e ("\(pID) 'TX Characteristic' - No data received for RX command")
            }
        default: globals.log.e ("\(pID): Unhandled: \(characteristic.uuid)");
        }
    }
}
