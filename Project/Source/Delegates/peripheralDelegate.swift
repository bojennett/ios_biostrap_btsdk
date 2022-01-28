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
		log?.i ("\(gblReturnID(peripheral)): (do nothing)")
	}
	
	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	public func peripheralIsReady(toSendWriteWithoutResponse peripheral: CBPeripheral) {		
		let id = gblReturnID(peripheral)

		DispatchQueue.main.async {
			if let device = self.mConnectedDevices?[id], (device.peripheral == peripheral) {
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
				log?.e ("\(gblReturnID(peripheral)): didDiscoverServices: Error: \(error.localizedDescription).  Disconnecting")
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
		log?.v ("\(gblReturnID(peripheral)): didModifyServices (do nothing)")
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
		log?.v ("\(gblReturnID(peripheral)): didReadRSSI (do nothing)")
	}
	
	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	public func peripheral(_ peripheral: CBPeripheral, didOpen channel: CBL2CAPChannel?, error: Error?) {
		log?.i ("\(gblReturnID(peripheral)): didOpen channel (do nothing)")
	}
	
	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	public func peripheral(_ peripheral: CBPeripheral, didWriteValueFor descriptor: CBDescriptor, error: Error?) {
		log?.v ("\(gblReturnID(peripheral)): didWriteValueFor descriptor: \(descriptor.prettyID)")
	}
	
	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor descriptor: CBDescriptor, error: Error?) {
		log?.v ("\(gblReturnID(peripheral)): didUpdateValueFor descriptor: \(descriptor.prettyID)")
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
				log?.e ("\(gblReturnID(peripheral)): didDiscoverCharacteristics for service: \(service.prettyID) - Error: \(error.localizedDescription).  Disconnecting")
				self.mCentralManager?.cancelPeripheralConnection(peripheral)
				return
			}
			
			let id = gblReturnID(peripheral)

			if let characteristics = service.characteristics {
				for characteristic in characteristics {
					if let device = self.mConnectedDevices?[id], (device.peripheral == peripheral) {
						device.didDiscoverCharacteristic(characteristic)
						
						if (device.configured) {
							if (device.configuring) {
								device.connected = true
								self.connected?(id)
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
		log?.v ("\(gblReturnID(peripheral)): didWriteValueFor characteristic: \(characteristic.prettyID)")
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
				log?.e ("\(gblReturnID(peripheral)): didUpdateValue for characteristic: \(characteristic.prettyID) - Error: \(error.localizedDescription).  Disconnecting")
				//self.mCentralManager?.cancelPeripheralConnection(peripheral)
				//return
			}
			
			let id = gblReturnID(peripheral)

			if let device = self.mConnectedDevices?[id], (device.peripheral == peripheral) {
				device.didUpdateValue(characteristic)
				
				if (device.configured) {
					if (device.configuring) {
						device.connected = true
						self.connected?(id)
					}
				}
			}
			else {
				log?.e ("\(gblReturnID(peripheral)): didUpdateValue for characteristic: \(characteristic.prettyID) - No connected device found...")
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
		log?.v ("\(gblReturnID(peripheral)): didDiscoverDescriptorsFor characteristic: \(characteristic.prettyID)")
		
		DispatchQueue.main.async {
			if let error = error {
				log?.e ("\(gblReturnID(peripheral)): didDiscoverDescriptors for characteristic: \(characteristic.prettyID) - Error: \(error.localizedDescription).  Skipping")
				//self.mCentralManager?.cancelPeripheralConnection(peripheral)
				return
			}
			
			let id = gblReturnID(peripheral)

			if let descriptors = characteristic.descriptors {
				for descriptor in descriptors {
					if let device = self.mConnectedDevices?[id] {
						device.didDiscoverDescriptor(descriptor, forCharacteristic: characteristic)
					}
				}
			}
			else {
				log?.e ("\(gblReturnID(peripheral)): didDiscoverDescriptor for characteristic \(characteristic.prettyID): No descriptors - do not know what to do")
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
		log?.v ("\(gblReturnID(peripheral)): didDiscoverIncludedServicesFor service: \(service.prettyID)")
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
				log?.e ("\(gblReturnID(peripheral)): didUpdateNotificationState for characteristic: \(characteristic.prettyID) - Error: '\(error.localizedDescription)'  Skipping")
				//self.mCentralManager?.cancelPeripheralConnection(peripheral)
				return
			}

			let id = gblReturnID(peripheral)

			if let device = self.mConnectedDevices?[id], (device.peripheral == peripheral) {
				device.didUpdateNotificationState(characteristic)
				
				if (device.configured) {
					if (device.configuring) {
						device.connected = true
						self.connected?(id)
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
		log?.i ("\(gblReturnID(peripheral)): didUpdateANCSAuthorization - (do nothing)")
	}
}
