//
//  devicePeripheralDelegate.swift
//  biostrapDeviceSDK
//
//  Created by Joseph Bennett on 3/22/24.
//

import Foundation
import CoreBluetooth

extension Device: CBPeripheralDelegate {
		
	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	public func peripheralDidUpdateName(_ peripheral: CBPeripheral) {
		globals.log.i ("\(peripheral.prettyID): (do nothing)")
	}
	
	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	public func peripheralIsReady(toSendWriteWithoutResponse peripheral: CBPeripheral) {
        didWriteWithoutResponseReady()
	}
	
	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error = error {
            globals.log.e ("\(peripheral.prettyID): didDiscoverServices: Error: \(error.localizedDescription).  Disconnecting")
            self.centralManager?.cancelPeripheralConnection(peripheral)
            return
        }
        
        if let services = peripheral.services {
            for service in services {
                if (Device.hit(service)) {
                    peripheral.discoverCharacteristics(nil, for: service)
                }
            }
        }
	}
	
	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	public func peripheral(_ peripheral: CBPeripheral, didModifyServices invalidatedServices: [CBService]) {
		globals.log.v ("\(peripheral.prettyID): didModifyServices (do nothing)")
        if !invalidatedServices.isEmpty {
            globals.log.v ("Invalidated services: \(invalidatedServices.count)")
            for service in invalidatedServices {
                globals.log.v ("\(service.prettyID)")
            }
        }
		centralManager?.cancelPeripheralConnection(peripheral)
	}
	
	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	public func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
        self.didReadRSSI(RSSI.intValue)
	}
	
	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	public func peripheral(_ peripheral: CBPeripheral, didOpen channel: CBL2CAPChannel?, error: Error?) {
		globals.log.i ("\(peripheral.prettyID): didOpen channel (do nothing)")
	}
	
	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	public func peripheral(_ peripheral: CBPeripheral, didWriteValueFor descriptor: CBDescriptor, error: Error?) {
		globals.log.v ("\(peripheral.prettyID): didWriteValueFor descriptor: \(descriptor.prettyID)")
	}
	
	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor descriptor: CBDescriptor, error: Error?) {
		globals.log.v ("\(peripheral.prettyID): didUpdateValueFor descriptor: \(descriptor.prettyID)")
	}
	
	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let error = error {
            globals.log.e ("\(peripheral.prettyID): didDiscoverCharacteristics for service: \(service.prettyID) - Error: \(error.localizedDescription).  Disconnecting")
            self.centralManager?.cancelPeripheralConnection(peripheral)
            return
        }
        
        if let characteristics = service.characteristics {
            for characteristic in characteristics {
                self.didDiscoverCharacteristic(characteristic)
            }
        }
	}
	
	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	public func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
		//globals.log.v ("\(peripheral.prettyID): didWriteValueFor characteristic: \(characteristic.prettyID)")
	}
		
	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
		if let error = error {
			globals.log.e ("\(peripheral.prettyID): didUpdateValue for characteristic: \(characteristic.prettyID) - Error: \(error.localizedDescription)")
			//self.mCentralManager?.cancelPeripheralConnection(peripheral)
			//return
		}

		self.didUpdateValue(characteristic)
	}
	
	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	public func peripheral(_ peripheral: CBPeripheral, didDiscoverDescriptorsFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            globals.log.e ("\(peripheral.prettyID): didDiscoverDescriptors for characteristic: \(characteristic.prettyID) - Error: \(error.localizedDescription).  Skipping")
            self.centralManager?.cancelPeripheralConnection(peripheral)
            return
        }
        
        if let descriptors = characteristic.descriptors {
            for descriptor in descriptors {
                self.didDiscoverDescriptor(descriptor, forCharacteristic: characteristic)
            }
        } else {
            globals.log.e ("\(peripheral.prettyID): didDiscoverDescriptor for characteristic \(characteristic.prettyID): No descriptors - do not know what to do")
        }
	}
	
	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	public func peripheral(_ peripheral: CBPeripheral, didDiscoverIncludedServicesFor service: CBService, error: Error?) {
		globals.log.v ("\(peripheral.prettyID): didDiscoverIncludedServicesFor service: \(service.prettyID)")
	}
	
	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	public func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            globals.log.e ("\(peripheral.prettyID): didUpdateNotificationState for characteristic: \(characteristic.prettyID) - Error: '\(error.localizedDescription)'  Skipping")
            self.centralManager?.cancelPeripheralConnection(peripheral)
            return
        }
        
        self.didUpdateNotificationState(characteristic)
	}
	
	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	public func centralManager(_ central: CBCentralManager, didUpdateANCSAuthorizationFor peripheral: CBPeripheral) {
		globals.log.i ("\(peripheral.prettyID): didUpdateANCSAuthorization - (do nothing)")
	}
}
