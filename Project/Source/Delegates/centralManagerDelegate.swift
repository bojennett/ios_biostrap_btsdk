//
//  centralManagerDelegate.swift
//  biostrapDeviceSDK
//
//  Created by Joseph A. Bennett on 3/31/21.
//

import Foundation
import CoreBluetooth

extension biostrapDeviceSDK: CBCentralManagerDelegate {
	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	public func centralManagerDidUpdateState(_ central: CBCentralManager) {
		log?.v("\(central.state.rawValue)")
		
		DispatchQueue.main.async {
			if (central.state != .poweredOn) {
				self.mDiscoveredDevices?.removeAll()
				self.mConnectedDevices?.removeAll()
				self.bluetoothReady?(false)
			}
			else {
				self.bluetoothReady?(true)
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
	public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
		
		if (advertisementData[CBAdvertisementDataServiceUUIDsKey] == nil) { return }
		let id = peripheral.ID

		DispatchQueue.main.async {
			if let _ = self.mDiscoveredDevices?[gblReturnID(id)] {
				// Do nothing
			}
			else if let _ = self.mConnectedDevices?[gblReturnID(id)] {
				log?.v ("Discovered a device that is in my connected list... remove that and mark as disconnected...")
				self.mConnectedDevices?.removeValue(forKey: gblReturnID(id))
				self.disconnected?(gblReturnID(id))
			}
			else {
				// Local Name
				if let name = advertisementData[CBAdvertisementDataLocalNameKey] as? String {
					
					let serviceUUIDs	= advertisementData[CBAdvertisementDataServiceUUIDsKey] as! Array<CBUUID>

					for thisUUID in serviceUUIDs {
						#if UNIVERSAL || ETHOS
						if (thisUUID == Device.services.ethosService.UUID) {
							#if UNIVERSAL
							let device = Device(name, id: gblReturnID(id), peripheral: peripheral, type: .ethos)
							#else
							let device = Device(name, id: gblReturnID(id), peripheral: peripheral)
							#endif
							
							device.batteryLevelUpdated		= { id, percentage in
								DispatchQueue.main.async { self.batteryLevel?(id, percentage) }
							}
							
							device.writeEpochComplete		= { id, successful in
								DispatchQueue.main.async { self.writeEpochComplete?(id, successful) }
							}

							device.readEpochComplete		= { id, successful, value in
								DispatchQueue.main.async { self.readEpochComplete?(id, successful, value) }
							}

							device.endSleepComplete			= { id, successful in
								DispatchQueue.main.async { self.endSleepComplete?(id, successful) }
							}

							device.getAllPacketsComplete	= { id, successful in
								DispatchQueue.main.async { self.getAllPacketsComplete?(id, successful) }
							}

							device.getNextPacketComplete	= { id, successful, packet in
								DispatchQueue.main.async { self.getNextPacketComplete?(id, successful, packet) }
							}

							device.getPacketCountComplete	= { id, successful, count in
								DispatchQueue.main.async { self.getPacketCountComplete?(id, successful, count) }
							}

							device.startManualComplete = { id, successful in
								DispatchQueue.main.async { self.startManualComplete?(id, successful) }
							}
							
							device.stopManualComplete = { id, successful in
								DispatchQueue.main.async { self.stopManualComplete?(id, successful) }
							}
							
							device.ledComplete			= { id, successful in
								DispatchQueue.main.async { self.ledComplete?(id, successful) }
							}
							
							device.enterShipModeComplete	= { id, successful in
								DispatchQueue.main.async { self.enterShipModeComplete?(id, successful) }
							}
							
							device.writeIDComplete			= { id, successful in
								DispatchQueue.main.async { self.writeIDComplete?(id, successful) }
							}
							
							device.readIDComplete			= { id, successful, partID in
								DispatchQueue.main.async { self.readIDComplete?(id, successful, partID) }
							}
							
							device.deleteIDComplete			= { id, successful in
								DispatchQueue.main.async { self.deleteIDComplete?(id, successful) }
							}

							device.writeAdvIntervalComplete	= { id, successful in
								DispatchQueue.main.async { self.writeAdvIntervalComplete?(id, successful) }
							}
							
							device.readAdvIntervalComplete	= { id, successful, seconds in
								DispatchQueue.main.async { self.readAdvIntervalComplete?(id, successful, seconds) }
							}
							
							device.deleteAdvIntervalComplete = { id, successful in
								DispatchQueue.main.async { self.deleteAdvIntervalComplete?(id, successful) }
							}

							device.clearChargeCyclesComplete	= { id, successful in
								DispatchQueue.main.async { self.clearChargeCyclesComplete?(id, successful) }
							}
							
							device.readChargeCyclesComplete	= { id, successful, cycles in
								DispatchQueue.main.async { self.readChargeCyclesComplete?(id, successful, cycles) }
							}
							
							device.wornCheckComplete		= { id, successful, code, value in
								DispatchQueue.main.async { self.wornCheckComplete?(id, successful, code, value) }
							}
							
							device.rawLoggingComplete		= { id, successful in
								DispatchQueue.main.async { self.rawLoggingComplete?(id, successful) }
							}
							
							device.resetComplete			= { id, successful in
								DispatchQueue.main.async { self.resetComplete?(id, successful) }
							}
							
							device.disableWornDetectComplete	= { id, successful in
								DispatchQueue.main.async { self.disableWornDetectComplete?(id, successful) }
							}

							device.enableWornDetectComplete	= { id, successful in
								DispatchQueue.main.async { self.enableWornDetectComplete?(id, successful) }
							}

							device.manualResult     		= { id, successful, packet in
								DispatchQueue.main.async { self.manualResult?(id, successful, packet) }
							}
							
							device.ppgBroken				= { id in
								DispatchQueue.main.async { self.ppgBroken?(id) }
							}

							device.dataPackets				= { id, packets in
								DispatchQueue.main.async { self.dataPackets?(id, packets) }
							}

							device.dataComplete				= { id in
								DispatchQueue.main.async { self.dataComplete?(id) }
							}
							
							device.deviceWornStatus			= { id, isWorn in
								DispatchQueue.main.async { self.deviceWornStatus?(id, isWorn) }
							}

							device.updateFirmwareFailed		= { id, code, message in
								DispatchQueue.main.async { self.updateFirmwareFailed?(id, code, message) }
							}
							
							self.mDiscoveredDevices?[gblReturnID(id)] = device
							log?.v("didDiscover: \(name)")
							
							#if UNIVERSAL
							self.discovered?(gblReturnID(id), .ethos)
							#else
							self.discovered?(gblReturnID(id))
							#endif
						}
						#endif
						
						#if UNIVERSAL || LIVOTAL
						if (thisUUID == Device.services.livotalService.UUID) {
							#if UNIVERSAL
							let device = Device(name, id: gblReturnID(id), peripheral: peripheral, type: .livotal)
							#else
							let device = Device(name, id: gblReturnID(id), peripheral: peripheral)
							#endif
							
							device.batteryLevelUpdated		= { id, percentage in
								DispatchQueue.main.async { self.batteryLevel?(id, percentage) }
							}
							
							device.writeEpochComplete		= { id, successful in
								DispatchQueue.main.async { self.writeEpochComplete?(id, successful) }
							}

							device.readEpochComplete		= { id, successful, value in
								DispatchQueue.main.async { self.readEpochComplete?(id, successful, value) }
							}

							device.endSleepComplete			= { id, successful in
								DispatchQueue.main.async { self.endSleepComplete?(id, successful) }
							}

							device.getAllPacketsComplete	= { id, successful in
								DispatchQueue.main.async { self.getAllPacketsComplete?(id, successful) }
							}

							device.getNextPacketComplete	= { id, successful, packet in
								DispatchQueue.main.async { self.getNextPacketComplete?(id, successful, packet) }
							}

							device.getPacketCountComplete	= { id, successful, count in
								DispatchQueue.main.async { self.getPacketCountComplete?(id, successful, count) }
							}

							device.startManualComplete		= { id, successful in
								DispatchQueue.main.async { self.startManualComplete?(id, successful) }
							}
							
							device.stopManualComplete		= { id, successful in
								DispatchQueue.main.async { self.stopManualComplete?(id, successful) }
							}
							
							device.ledComplete				= { id, successful in
								DispatchQueue.main.async { self.ledComplete?(id, successful) }
							}
							
							device.enterShipModeComplete	= { id, successful in
								DispatchQueue.main.async { self.enterShipModeComplete?(id, successful) }
							}
							
							device.writeIDComplete			= { id, successful in
								DispatchQueue.main.async { self.writeIDComplete?(id, successful) }
							}
							
							device.readIDComplete			= { id, successful, partID in
								DispatchQueue.main.async { self.readIDComplete?(id, successful, partID) }
							}
							
							device.deleteIDComplete			= { id, successful in
								DispatchQueue.main.async { self.deleteIDComplete?(id, successful) }
							}

							device.writeAdvIntervalComplete	= { id, successful in
								DispatchQueue.main.async { self.writeAdvIntervalComplete?(id, successful) }
							}
							
							device.readAdvIntervalComplete	= { id, successful, seconds in
								DispatchQueue.main.async { self.readAdvIntervalComplete?(id, successful, seconds) }
							}
							
							device.deleteAdvIntervalComplete = { id, successful in
								DispatchQueue.main.async { self.deleteAdvIntervalComplete?(id, successful) }
							}

							device.clearChargeCyclesComplete	= { id, successful in
								DispatchQueue.main.async { self.clearChargeCyclesComplete?(id, successful) }
							}
							
							device.readChargeCyclesComplete	= { id, successful, cycles in
								DispatchQueue.main.async { self.readChargeCyclesComplete?(id, successful, cycles) }
							}
							
							device.wornCheckComplete		= { id, successful, code, value in
								DispatchQueue.main.async { self.wornCheckComplete?(id, successful, code, value) }
							}
							
							device.rawLoggingComplete		= { id, successful in
								DispatchQueue.main.async { self.rawLoggingComplete?(id, successful) }
							}
							
							device.resetComplete			= { id, successful in
								DispatchQueue.main.async { self.resetComplete?(id, successful) }
							}
							
							device.disableWornDetectComplete	= { id, successful in
								DispatchQueue.main.async { self.disableWornDetectComplete?(id, successful) }
							}

							device.enableWornDetectComplete	= { id, successful in
								DispatchQueue.main.async { self.enableWornDetectComplete?(id, successful) }
							}

							device.manualResult     		= { id, successful, packet in
								DispatchQueue.main.async { self.manualResult?(id, successful, packet) }
							}
							
							device.ppgBroken				= { id in
								DispatchQueue.main.async { self.ppgBroken?(id) }
							}

							device.dataPackets				= { id, packets in
								DispatchQueue.main.async { self.dataPackets?(id, packets) }
							}

							device.dataComplete				= { id in
								DispatchQueue.main.async { self.dataComplete?(id) }
							}
							
							device.deviceWornStatus			= { id, isWorn in
								DispatchQueue.main.async { self.deviceWornStatus?(id, isWorn) }
							}

							device.updateFirmwareFailed		= { id, code, message in
								DispatchQueue.main.async { self.updateFirmwareFailed?(id, code, message) }
							}
							
							self.mDiscoveredDevices?[gblReturnID(id)] = device
							log?.v("didDiscover: \(name)")
							
							#if UNIVERSAL
							self.discovered?(gblReturnID(id), .livotal)
							#else
							self.discovered?(gblReturnID(id))
							#endif
						}
						
						if (thisUUID == Device.services.nordicDFUService.UUID) {
							log?.v("didDiscover: \(name) -> DFU mode!")
							
							if (name == gblDFUName) {
								if (!dfu.active) {
									log?.v("didDiscover: And it happens to be who I am looking for!")
									dfu.update(peripheral)
								}
								else {
									log?.e("didDiscover: I should have started by now...")
								}
							}
							else {
								log?.e("didDiscover: This is not who I am looking for, though...")
							}
						}
						#endif
					}
				}
				else {
					log?.e("didDiscover: \(id), but no name given, not indicating discovered")
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
	public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
		let id = gblReturnID(peripheral.ID)
		
		log?.v("\(id): didConnect")
		
		DispatchQueue.main.async {
			if let device = self.mDiscoveredDevices?[id] {
				if (device.connecting) {
					if let devicePeripheral = device.peripheral {
						if (peripheral == devicePeripheral) {
							devicePeripheral.delegate = self
							device.peripheral = devicePeripheral
							device.configuring = true
							self.mDiscoveredDevices?.removeValue(forKey: id)
							self.mConnectedDevices?[id] = device
							devicePeripheral.discoverServices(nil)
						}
					}
				}
				else {
					log?.e ("Connected to a device that isn't requesting connection.  Weird!")
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
	internal func mProcessDisconnection(_ id: String) {
		DispatchQueue.main.async {
			if let device = self.mDiscoveredDevices?[id] {
				if (device.connecting) {
					self.mDiscoveredDevices?.removeValue(forKey: id)
				}
				else {
					log?.e ("Disconnected from a discovered device that isn't requesting connection.  Weird!")
				}
				
				self.disconnected?(id)
				return
			}

			if let device = self.mConnectedDevices?[id] {
				if (device.configuring || device.connected) {
					self.mConnectedDevices?.removeValue(forKey: id)
				}
				else {
					log?.e ("Disconnected from a connected device that isn't discovering services or fully connected.  Weird!")
				}
				
				self.disconnected?(id)
				return
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
	public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
		let id = gblReturnID(peripheral.ID)

		log?.v("didDisconnectPeripheral: \(id)")
		self.mProcessDisconnection(id)
	}
	
	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	public func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
		let id = gblReturnID(peripheral.ID)

		log?.v("didFailToConnect: \(id)")
		self.mProcessDisconnection(id)
	}
	
}

