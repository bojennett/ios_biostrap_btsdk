//
//  peripheralDelegate.swift
//  biostrapDeviceSDK
//
//  Created by Joseph A. Bennett on 4/2/21.
//

import Foundation
import CoreBluetooth

extension biostrapDeviceSDK: CBPeripheralDelegate {
	
	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	public func peripheralDidUpdateName(_ peripheral: CBPeripheral) {
		log?.i ("\(peripheral.prettyID): (do nothing)")
	}
	
	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	public func peripheralIsReady(toSendWriteWithoutResponse peripheral: CBPeripheral) {
		DispatchQueue.main.async {
			if let device = self.mConnectedDevices?[peripheral.prettyID], (device.peripheral == peripheral) {
				device.isReady()
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
	public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
		DispatchQueue.main.async {
			if let error = error {
				log?.e ("\(peripheral.prettyID): didDiscoverServices: Error: \(error.localizedDescription).  Disconnecting")
				self.mCentralManager?.cancelPeripheralConnection(peripheral)
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
	}
	
	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	public func peripheral(_ peripheral: CBPeripheral, didModifyServices invalidatedServices: [CBService]) {
		log?.v ("\(peripheral.prettyID): didModifyServices (do nothing)")
		log?.v ("Invalidated services: \(invalidatedServices.count)")
		for service in invalidatedServices {
			log?.v ("\(service.prettyID)")
		}
		mCentralManager?.cancelPeripheralConnection(peripheral)
	}
	
	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	public func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
		log?.v ("\(peripheral.prettyID): didReadRSSI (do nothing)")
	}
	
	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	public func peripheral(_ peripheral: CBPeripheral, didOpen channel: CBL2CAPChannel?, error: Error?) {
		log?.i ("\(peripheral.prettyID): didOpen channel (do nothing)")
	}
	
	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	public func peripheral(_ peripheral: CBPeripheral, didWriteValueFor descriptor: CBDescriptor, error: Error?) {
		log?.v ("\(peripheral.prettyID): didWriteValueFor descriptor: \(descriptor.prettyID)")
	}
	
	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor descriptor: CBDescriptor, error: Error?) {
		log?.v ("\(peripheral.prettyID): didUpdateValueFor descriptor: \(descriptor.prettyID)")
	}
	
	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
		DispatchQueue.main.async {
			if let error = error {
				log?.e ("\(peripheral.prettyID): didDiscoverCharacteristics for service: \(service.prettyID) - Error: \(error.localizedDescription).  Disconnecting")
				self.mCentralManager?.cancelPeripheralConnection(peripheral)
				return
			}
			
			if let characteristics = service.characteristics {
				for characteristic in characteristics {
					if let device = self.mConnectedDevices?[peripheral.prettyID], (device.peripheral == peripheral) {
						device.didDiscoverCharacteristic(characteristic)
						
						if (device.configured) {
							if (device.configuring) {
								device.connected = true
								self.connected?(peripheral.prettyID)
							}
						}
					}
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
	public func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
		log?.v ("\(peripheral.prettyID): didWriteValueFor characteristic: \(characteristic.prettyID)")
	}
		
	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
		DispatchQueue.main.async {
			if let error = error {
				log?.e ("\(peripheral.prettyID): didUpdateValue for characteristic: \(characteristic.prettyID) - Error: \(error.localizedDescription).  Disconnecting")
				//self.mCentralManager?.cancelPeripheralConnection(peripheral)
				//return
			}
			
			if let device = self.mConnectedDevices?[peripheral.prettyID], (device.peripheral == peripheral) {
				device.didUpdateValue(characteristic)
				
				if (device.configured) {
					if (device.configuring) {
						device.connected = true
						self.connected?(peripheral.prettyID)
					}
				}
			}
			else {
				log?.e ("\(peripheral.prettyID): didUpdateValue for characteristic: \(characteristic.prettyID) - No connected device found...")
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
	public func peripheral(_ peripheral: CBPeripheral, didDiscoverDescriptorsFor characteristic: CBCharacteristic, error: Error?) {
		log?.v ("\(peripheral.prettyID): didDiscoverDescriptorsFor characteristic: \(characteristic.prettyID)")
		
		DispatchQueue.main.async {
			if let error = error {
				log?.e ("\(peripheral.prettyID): didDiscoverDescriptors for characteristic: \(characteristic.prettyID) - Error: \(error.localizedDescription).  Skipping")
				//self.mCentralManager?.cancelPeripheralConnection(peripheral)
				return
			}
			
			if let descriptors = characteristic.descriptors {
				for descriptor in descriptors {
					if let device = self.mConnectedDevices?[peripheral.prettyID] {
						device.didDiscoverDescriptor(descriptor, forCharacteristic: characteristic)
					}
				}
			}
			else {
				log?.e ("\(peripheral.prettyID): didDiscoverDescriptor for characteristic \(characteristic.prettyID): No descriptors - do not know what to do")
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
	public func peripheral(_ peripheral: CBPeripheral, didDiscoverIncludedServicesFor service: CBService, error: Error?) {
		log?.v ("\(peripheral.prettyID): didDiscoverIncludedServicesFor service: \(service.prettyID)")
	}
	
	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	public func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
		
		DispatchQueue.main.async {
			if let error = error {
				log?.e ("\(peripheral.prettyID): didUpdateNotificationState for characteristic: \(characteristic.prettyID) - Error: '\(error.localizedDescription)'  Skipping")
				//self.mCentralManager?.cancelPeripheralConnection(peripheral)
				return
			}

			if let device = self.mConnectedDevices?[peripheral.prettyID], (device.peripheral == peripheral) {
				device.didUpdateNotificationState(characteristic)
				
				if (device.configured) {
					if (device.configuring) {
						device.connected = true
						self.connected?(peripheral.prettyID)
					}
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
	public func centralManager(_ central: CBCentralManager, didUpdateANCSAuthorizationFor peripheral: CBPeripheral) {
		log?.i ("\(peripheral.prettyID): didUpdateANCSAuthorization - (do nothing)")
	}
}
