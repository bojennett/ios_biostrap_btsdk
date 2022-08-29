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
				
				if let connectedDevices = self.mConnectedDevices {
					for (id, _) in connectedDevices { self.mProcessDisconnection(id) }
				}
				
				//self.mConnectedDevices?.removeAll()
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

		DispatchQueue.main.async {
			if let _ = self.mDiscoveredDevices?[peripheral.prettyID] {
				// Do nothing
			}
			else if let _ = self.mConnectedDevices?[peripheral.prettyID] {
				log?.e ("\(peripheral.prettyID): didDiscover: Discovered a device that is in my connected list.  Don't expect this...  Don't do anything, though")
				//self.mConnectedDevices?.removeValue(forKey: peripheral.prettyID)
				//self.disconnected?(peripheral.prettyID)
			}
			else {
				// Local Name
				if let name = advertisementData[CBAdvertisementDataLocalNameKey] as? String {
					
					let serviceUUIDs	= advertisementData[CBAdvertisementDataServiceUUIDsKey] as! Array<CBUUID>

					for thisUUID in serviceUUIDs {
						#if UNIVERSAL || ALTER
						if (thisUUID == Device.services.alterService.UUID) {
							
							if let _ = self.mDiscoveredDevices?[peripheral.prettyID] { }
							else {
								#if UNIVERSAL
								let device = Device(name, id: peripheral.prettyID, peripheral: peripheral, type: .alter)
								#else
								let device = Device(name, id: peripheral.prettyID, peripheral: peripheral)
								#endif

								device.epoch					= Date().timeIntervalSince1970

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

								device.writeSerialNumberComplete			= { id, successful in
									DispatchQueue.main.async { self.writeSerialNumberComplete?(id, successful) }
								}

								device.readSerialNumberComplete			= { id, successful, partID in
									DispatchQueue.main.async { self.readSerialNumberComplete?(id, successful, partID) }
								}

								device.deleteSerialNumberComplete			= { id, successful in
									DispatchQueue.main.async { self.deleteSerialNumberComplete?(id, successful) }
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

								device.allowPPGComplete			= { id, successful in
									DispatchQueue.main.async { self.allowPPGComplete?(id, successful) }
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

								device.ppgFailed				= { id, code in
									DispatchQueue.main.async { self.ppgFailed?(id, code) }
								}

								device.dataPackets				= { id, packets in
									if (self.dataPacketsOnBackgroundThread) {
										self.dataPackets?(id, packets)
									}
									else {
										DispatchQueue.main.async { self.dataPackets?(id, packets) }
									}
								}

								device.dataComplete				= { id, bad_fw_read_count, bad_fw_packet_count, overflow_count, bad_sdk_parse_count in
									DispatchQueue.main.async { self.dataComplete?(id, bad_fw_read_count, bad_fw_packet_count, overflow_count, bad_sdk_parse_count) }
								}

								device.dataFailure				= { id in
									DispatchQueue.main.async { self.dataFailure?(id) }
								}

								device.deviceWornStatus			= { id, isWorn in
									DispatchQueue.main.async { self.deviceWornStatus?(id, isWorn) }
								}

								device.updateFirmwareFailed		= { id, code, message in
									DispatchQueue.main.async { self.updateFirmwareFailed?(id, code, message) }
								}

								device.updateFirmwareFinished	= { id in
									DispatchQueue.main.async { self.updateFirmwareFinished?(id) }
								}

								device.updateFirmwareStarted	= { id in
									DispatchQueue.main.async { self.updateFirmwareStarted?(id) }
								}

								device.updateFirmwareProgress	= { id, percentage in
									DispatchQueue.main.async { self.updateFirmwareProgress?(id, percentage) }
								}

								device.setSessionParamComplete		= { id, successful, parameter in
									DispatchQueue.main.async { self.setSessionParamComplete?(id, successful, parameter) }
								}

								device.getSessionParamComplete		= { id, successful, parameter, value in
									DispatchQueue.main.async { self.getSessionParamComplete?(id, successful, parameter, value) }
								}

								device.resetSessionParamsComplete	= { id, successful in
									DispatchQueue.main.async { self.resetSessionParamsComplete?(id, successful) }
								}

								device.acceptSessionParamsComplete	= { id, successful in
									DispatchQueue.main.async { self.acceptSessionParamsComplete?(id, successful) }
								}

								device.manufacturingTestComplete	= { id, successful in
									DispatchQueue.main.async { self.manufacturingTestComplete?(id, successful) }
								}

								device.manufacturingTestResult		= { id, valid, result in
									DispatchQueue.main.async { self.manufacturingTestResult?(id, valid, result) }
								}
								
								self.mDiscoveredDevices?[peripheral.prettyID] = device
							}
							
							log?.v("\(peripheral.prettyID): didDiscover: \(name)")

							#if UNIVERSAL
							self.discovered?(peripheral.prettyID, .alter)
							#else
							self.discovered?(peripheral.prettyID)
							#endif
						}
						#endif
						
						#if UNIVERSAL || ETHOS
						if (thisUUID == Device.services.ethosService.UUID) {
							
							if let _ = self.mDiscoveredDevices?[peripheral.prettyID] { }
							else {

								#if UNIVERSAL
								let device = Device(name, id: peripheral.prettyID, peripheral: peripheral, type: .ethos)
								#else
								let device = Device(name, id: peripheral.prettyID, peripheral: peripheral)
								#endif

								device.epoch					= Date().timeIntervalSince1970

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

								device.motorComplete			= { id, successful in
									DispatchQueue.main.async { self.motorComplete?(id, successful) }
								}

								device.enterShipModeComplete	= { id, successful in
									DispatchQueue.main.async { self.enterShipModeComplete?(id, successful) }
								}
								
								device.writeSerialNumberComplete			= { id, successful in
									DispatchQueue.main.async { self.writeSerialNumberComplete?(id, successful) }
								}
								
								device.readSerialNumberComplete			= { id, successful, partID in
									DispatchQueue.main.async { self.readSerialNumberComplete?(id, successful, partID) }
								}
								
								device.deleteSerialNumberComplete			= { id, successful in
									DispatchQueue.main.async { self.deleteSerialNumberComplete?(id, successful) }
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
								
								device.allowPPGComplete			= { id, successful in
									DispatchQueue.main.async { self.allowPPGComplete?(id, successful) }
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
								
								device.ppgFailed				= { id, code in
									DispatchQueue.main.async { self.ppgFailed?(id, code) }
								}

								device.dataPackets				= { id, packets in
									if (self.dataPacketsOnBackgroundThread) {
										self.dataPackets?(id, packets)
									}
									else {
										DispatchQueue.main.async { self.dataPackets?(id, packets) }
									}
								}

								device.dataComplete				= { id, bad_fw_read_count, bad_fw_packet_count, overflow_count, bad_sdk_parse_count in
									DispatchQueue.main.async { self.dataComplete?(id, bad_fw_read_count, bad_fw_packet_count, overflow_count, bad_sdk_parse_count) }
								}

								device.dataFailure				= { id in
									DispatchQueue.main.async { self.dataFailure?(id) }
								}
								
								device.deviceWornStatus			= { id, isWorn in
									DispatchQueue.main.async { self.deviceWornStatus?(id, isWorn) }
								}

								device.updateFirmwareFailed		= { id, code, message in
									DispatchQueue.main.async { self.updateFirmwareFailed?(id, code, message) }
								}
								
								device.updateFirmwareFinished	= { id in
									DispatchQueue.main.async { self.updateFirmwareFinished?(id) }
								}

								device.updateFirmwareStarted	= { id in
									DispatchQueue.main.async { self.updateFirmwareStarted?(id) }
								}

								device.updateFirmwareProgress	= { id, percentage in
									DispatchQueue.main.async { self.updateFirmwareProgress?(id, percentage) }
								}

								device.setSessionParamComplete		= { id, successful, parameter in
									DispatchQueue.main.async { self.setSessionParamComplete?(id, successful, parameter) }
								}

								device.getSessionParamComplete		= { id, successful, parameter, value in
									DispatchQueue.main.async { self.getSessionParamComplete?(id, successful, parameter, value) }
								}

								device.resetSessionParamsComplete	= { id, successful in
									DispatchQueue.main.async { self.resetSessionParamsComplete?(id, successful) }
								}

								device.acceptSessionParamsComplete	= { id, successful in
									DispatchQueue.main.async { self.acceptSessionParamsComplete?(id, successful) }
								}
								
								device.manufacturingTestComplete	= { id, successful in
									DispatchQueue.main.async { self.manufacturingTestComplete?(id, successful) }
								}

								device.manufacturingTestResult		= { id, valid, result in
									DispatchQueue.main.async { self.manufacturingTestResult?(id, valid, result) }
								}
								
								device.startLiveSyncComplete		= { id, successful in
									DispatchQueue.main.async { self.startLiveSyncComplete?(id, successful) }
								}
								
								device.stopLiveSyncComplete			= { id, successful in
									DispatchQueue.main.async { self.stopLiveSyncComplete?(id, successful) }
								}

								device.recalibratePPGComplete		= { id, successful in
									DispatchQueue.main.async { self.recalibratePPGComplete?(id, successful) }
								}

								device.deviceChargingStatus			= { id, charging, on_charger, error in
									DispatchQueue.main.async { self.deviceChargingStatus?(id, charging, on_charger, error) }
								}

								self.mDiscoveredDevices?[peripheral.prettyID] = device
							}
							
							log?.v("\(peripheral.prettyID): didDiscover: \(name)")

							#if UNIVERSAL
							self.discovered?(peripheral.prettyID, .ethos)
							#else
							self.discovered?(peripheral.prettyID)
							#endif
						}
						#endif
						
						#if UNIVERSAL || LIVOTAL
						if (thisUUID == Device.services.livotalService.UUID) {
							
							if let _ = self.mDiscoveredDevices?[peripheral.prettyID] { }
							else {

								#if UNIVERSAL
								let device = Device(name, id: peripheral.prettyID, peripheral: peripheral, type: .livotal)
								#else
								let device = Device(name, id: peripheral.prettyID, peripheral: peripheral)
								#endif

								device.epoch					= Date().timeIntervalSince1970

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

								device.getNextPacketComplete		= { id, successful, packet in
									DispatchQueue.main.async { self.getNextPacketComplete?(id, successful, packet) }
								}

								device.getPacketCountComplete		= { id, successful, count in
									DispatchQueue.main.async { self.getPacketCountComplete?(id, successful, count) }
								}

								device.startManualComplete			= { id, successful in
									DispatchQueue.main.async { self.startManualComplete?(id, successful) }
								}
								
								device.stopManualComplete			= { id, successful in
									DispatchQueue.main.async { self.stopManualComplete?(id, successful) }
								}
								
								device.ledComplete					= { id, successful in
									DispatchQueue.main.async { self.ledComplete?(id, successful) }
								}
								
								device.enterShipModeComplete		= { id, successful in
									DispatchQueue.main.async { self.enterShipModeComplete?(id, successful) }
								}
								
								device.writeSerialNumberComplete	= { id, successful in
									DispatchQueue.main.async { self.writeSerialNumberComplete?(id, successful) }
								}
								
								device.readSerialNumberComplete		= { id, successful, partID in
									DispatchQueue.main.async { self.readSerialNumberComplete?(id, successful, partID) }
								}
								
								device.deleteSerialNumberComplete	= { id, successful in
									DispatchQueue.main.async { self.deleteSerialNumberComplete?(id, successful) }
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
								
								device.allowPPGComplete			= { id, successful in
									DispatchQueue.main.async { self.allowPPGComplete?(id, successful) }
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
								
								device.ppgFailed				= { id, code in
									DispatchQueue.main.async { self.ppgFailed?(id, code) }
								}

								device.dataPackets				= { id, packets in
									if (self.dataPacketsOnBackgroundThread) {
										self.dataPackets?(id, packets)
									}
									else {
										DispatchQueue.main.async { self.dataPackets?(id, packets) }
									}
								}

								device.dataComplete				= { id, bad_fw_read_count, bad_fw_packet_count, overflow_count, bad_sdk_parse_count in
									DispatchQueue.main.async { self.dataComplete?(id, bad_fw_read_count, bad_fw_packet_count, overflow_count, bad_sdk_parse_count) }
								}

								device.dataFailure				= { id in
									DispatchQueue.main.async { self.dataFailure?(id) }
								}
								
								device.deviceWornStatus			= { id, isWorn in
									DispatchQueue.main.async { self.deviceWornStatus?(id, isWorn) }
								}

								device.updateFirmwareFailed		= { id, code, message in
									DispatchQueue.main.async { self.updateFirmwareFailed?(id, code, message) }
								}
								
								device.updateFirmwareFinished	= { id in
									DispatchQueue.main.async { self.updateFirmwareFinished?(id) }
								}

								device.updateFirmwareStarted	= { id in
									DispatchQueue.main.async { self.updateFirmwareStarted?(id) }
								}

								device.updateFirmwareProgress	= { id, percentage in
									DispatchQueue.main.async { self.updateFirmwareProgress?(id, percentage) }
								}
								
								device.setSessionParamComplete		= { id, successful, parameter in
									DispatchQueue.main.async { self.setSessionParamComplete?(id, successful, parameter) }
								}

								device.getSessionParamComplete		= { id, successful, parameter, value in
									DispatchQueue.main.async { self.getSessionParamComplete?(id, successful, parameter, value) }
								}

								device.resetSessionParamsComplete	= { id, successful in
									DispatchQueue.main.async { self.resetSessionParamsComplete?(id, successful) }
								}

								device.acceptSessionParamsComplete	= { id, successful in
									DispatchQueue.main.async { self.acceptSessionParamsComplete?(id, successful) }
								}

								device.manufacturingTestComplete	= { id, successful in
									DispatchQueue.main.async { self.manufacturingTestComplete?(id, successful) }
								}

								device.manufacturingTestResult		= { id, valid, result in
									DispatchQueue.main.async { self.manufacturingTestResult?(id, valid, result) }
								}

								device.deviceChargingStatus			= { id, charging, on_charger, error in
									DispatchQueue.main.async { self.deviceChargingStatus?(id, charging, on_charger, error) }
								}
								
								self.mDiscoveredDevices?[peripheral.prettyID] = device
							}
							
							log?.v("\(peripheral.prettyID): didDiscover: \(name)")

							#if UNIVERSAL
							self.discovered?(peripheral.prettyID, .livotal)
							#else
							self.discovered?(peripheral.prettyID)
							#endif
						}
						
						if (thisUUID == Device.services.nordicDFUService.UUID) {
							log?.v("\(peripheral.prettyID): didDiscover: \(name) -> DFU mode!")
							
							if (name == gblDFUName) {
								if (!dfu.active) {
									log?.v("\(peripheral.prettyID): didDiscover: And it happens to be who I am looking for!")
									dfu.update(peripheral)
								}
								else {
									log?.e("\(peripheral.prettyID): didDiscover: I should have started by now...")
								}
							}
							else {
								log?.e("\(peripheral.prettyID): didDiscover: This is not who I am looking for, though...")
							}
						}
						#endif
					}
				}
				else {
					log?.e("\(peripheral.prettyID): didDiscover: No name given, not indicating discovered")
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
		log?.v("\(peripheral.prettyID): didConnect")
		
		DispatchQueue.main.async {
			if let device = self.mDiscoveredDevices?[peripheral.prettyID] {
				if (device.connecting) {
					if let devicePeripheral = device.peripheral {
						if (peripheral == devicePeripheral) {
							devicePeripheral.delegate = self
							device.peripheral	= devicePeripheral
							device.epoch		= Date().timeIntervalSince1970
							device.configuring	= true
							self.mDiscoveredDevices?.removeValue(forKey: peripheral.prettyID)
							self.mConnectedDevices?[peripheral.prettyID] = device
							devicePeripheral.discoverServices(nil)
						}
					}
				}
				else {
					log?.e ("\(peripheral.prettyID): didConnect: Connected to a device that isn't requesting connection.  Weird!")
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
					log?.e ("\(id): Disconnected from a discovered device that isn't requesting connection.  Weird!")
				}
				
				self.disconnected?(id)
				return
			}

			if let device = self.mConnectedDevices?[id] {
				if (device.configuring || device.connected) {
					self.mConnectedDevices?.removeValue(forKey: id)
				}
				else {
					log?.e ("\(id): Disconnected from a connected device that isn't discovering services or fully connected.  Weird!")
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
		log?.v("\(peripheral.prettyID): didDisconnectPeripheral")
		self.mProcessDisconnection(peripheral.prettyID)
	}
	
	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	public func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
		log?.v("\(peripheral.prettyID): didFailToConnect")
		self.mProcessDisconnection(peripheral.prettyID)
	}
	
}

