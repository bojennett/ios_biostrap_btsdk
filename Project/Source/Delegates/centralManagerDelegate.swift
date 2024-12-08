//
//  centralManagerDelegate.swift
//  biostrapDeviceSDK
//
//  Created by Joseph A. Bennett on 3/31/21.
//

import Foundation
import CoreBluetooth

extension CBManagerState {
	var title: String {
		switch self {
		case .poweredOff: return "poweredOff"
		case .poweredOn: return "poweredOn"
		case .resetting: return "resetting"
		case .unauthorized: return "unauthorized"
		case .unknown: return "unknown"
		case .unsupported: return "unsupported"
		@unknown default:
			return "Unknown condition from switch statement state: \(self.rawValue)"
		}
	}
	
	var description: String {
		switch self {
		case .poweredOff: return "Bluetooth is currently powered off."
		case .poweredOn: return "Bluetooth is currently powered on and available to use."
		case .resetting: return "The connection with the system service was momentarily lost."
		case .unauthorized: return "The application isn’t authorized to use the Bluetooth low energy role."
		case .unknown: return "The manager’s state is unknown."
		case .unsupported: return "Unsupported State"
		@unknown default:
			return "Unknown condition from switch statement state: \(self.rawValue)"
		}
	}
}

extension biostrapDeviceSDK: CBCentralManagerDelegate {
	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	public func centralManagerDidUpdateState(_ central: CBCentralManager) {
		globals.log.v("\(central.state.rawValue)")
		
		DispatchQueue.main.async {
			if central.state == .poweredOn {
				globals.log.e ("Bluetooth in powered on state and has permissions")
				self.bluetoothReady?(true)
				self.bluetoothAvailable = true
			}
			else {
				globals.log.e ("Bluetooth in state: \(central.state.title) - '\(central.state.description)'")
				self.discoveredDevices.removeAll()
				self.unnamedDevices.removeAll()

				for device in self.connectedDevices { self.mProcessDisconnection(device.id) }
				
				self.bluetoothReady?(false)
				self.bluetoothAvailable = false
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
	internal func mGetNameFromManufacturerData(_ advertisementData: [String : Any]) -> (Bool, biostrapDiscoveryType, Bool, String, service: CBUUID) {
		var valid = false
		var paired = biostrapDiscoveryType.unknown
		var has_serial = false
		var name = ""
		var service = org_bluetooth_service.user_data.UUID

		if let manufacturer_data = advertisementData[CBAdvertisementDataManufacturerDataKey] as? Data {
			if (manufacturer_data[0] == 0x42) && (manufacturer_data[1] == 0x53) {	// "BS" for "biostrap"
				//log?.v ("Manufacturer Data: \(manufacturer_data.hexString)")
				if (manufacturer_data.count == 3) {
					if ((manufacturer_data[2] & 0x80) == 0x00) { // if bit 7 is set, this has a name, so length should not be 3!
						globals.log.v (" --- No name: Flags = \(manufacturer_data.hexString)")
						valid = true
						if ((manufacturer_data[2] & 0x01) != 0x00) {
							paired = .paired_w_uuid
						}
						else {
							paired = .unpaired_w_uuid
						}
						
						has_serial = ((manufacturer_data[2] & 0x02) != 0x00)
					}
					else {
						globals.log.w (" --- has name, but length is weird: ${data.hexString()}")
					}
				}
				
				else if (manufacturer_data.count == 14) {
					//log?.v ("\(manufacturer_data.hexString)")
					let prefix = String(decoding: manufacturer_data.subdata(in: Range(3...5)), as: UTF8.self)
					if let deviceType = Device.prefixes(rawValue: prefix) {
						
						#if UNIVERSAL || ALTER
						if (deviceType == .alter) {
							valid = true
							service = Device.services.alter.UUID
						}
						#endif
												
						#if UNIVERSAL || KAIROS
						if (deviceType == .kairos) {
							valid = true
							service = Device.services.kairos.UUID
						}
						#endif
												
						if (valid) {
							if ((manufacturer_data[2] & 0x01) != 0x00) {
								paired = .paired
							}
							else {
								paired = .unpaired
							}
							has_serial = (manufacturer_data[2] & 0x02) != 0x00
							
							if (has_serial) {
								name = String(decoding: manufacturer_data.subdata(in: Range(6...13)), as: UTF8.self)	// Serial number
							}
							else {
								let mac_address = String(decoding: manufacturer_data.subdata(in: Range(6...13)), as: UTF8.self)	// MAC Address
								name = "\(prefix)-\(mac_address)"
							}
						}
					}
					
					else {
						globals.log.w ("Found a device with BS as the first two characters, but other advertising data I do not understand: \(manufacturer_data.hexString)")
					}
				}

			}
		}
		
		return (valid, paired, has_serial, name, service)
	}
	
	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	internal func setupCallbacks(_ device: Device) {
		device.lambdaConfigured = { id in  // Device already puts this on the main thread due to peripheral delegate
			if let discoveredDevice = self.discoveredDevices.first(where: { $0.id == id }) {
				self.discoveredDevices.removeAll(where: { $0.id == id })
				if self.connectedDevices.first(where: { $0.id == id }) == nil {
					self.connectedDevices.append(discoveredDevice)
					self.connected?(id)
				}
				else {
					globals.log.e ("Device was already in the connected list when i received 'configured' callback.  Weird.")
				}
			}
			else if let unnamedDevice = self.discoveredDevices.first(where: { $0.id == id }) {
				self.unnamedDevices.removeAll(where: { $0.id == id })
				if self.connectedDevices.first(where: { $0.id == id }) == nil {
					self.connectedDevices.append(unnamedDevice)
					self.connected?(id)
				}
				else {
					globals.log.e ("Device was already in the connected list when i received 'configured' callback.  Weird.")
				}
			}
			else {
				if let peripheral = device.peripheral {
					globals.log.e ("Received a configured callback, but my device is not in my discovered or unnamed list.  Very bizarre.  disconnect this")
					self.mCentralManager?.cancelPeripheralConnection(peripheral)
				}
				else {
					globals.log.e ("Received a configured callback, but my device is not in my discovered or unnamed list.  Very bizarre.  And don't have a peripheral to even disconnect.  What?!?!?")
				}
			}
		}
		
        device.lambdaBatteryLevelUpdated = { id, percentage in self.batteryLevel?(id, percentage) }
        device.lambdaHeartRateUpdated = { id, epoch, hr, rr in self.heartRate?(id, epoch, hr, rr) }
        device.lambdaWriteEpochComplete = { id, successful in self.writeEpochComplete?(id, successful) }
        device.lambdaReadEpochComplete = { id, successful, value in self.readEpochComplete?(id, successful, value) }
        device.lambdaEndSleepComplete = { id, successful in self.endSleepComplete?(id, successful) }
        device.lambdaGetAllPacketsComplete = { id, successful in self.getAllPacketsComplete?(id, successful) }
        device.lambdaGetAllPacketsAcknowledgeComplete = { id, successful, ack in self.getAllPacketsAcknowledgeComplete?(id, successful, ack) }
        device.lambdaGetPacketCountComplete = { id, successful, count in self.getPacketCountComplete?(id, successful, count) }
        device.lambdaStartManualComplete  = { id, successful in self.startManualComplete?(id, successful) }
        device.lambdaStopManualComplete  = { id, successful in self.stopManualComplete?(id, successful) }
        device.lambdaLEDComplete = { id, successful in self.ledComplete?(id, successful) }
        device.lambdaEnterShipModeComplete = { id, successful in self.enterShipModeComplete?(id, successful) }
        device.lamdaWriteSerialNumberComplete = { id, successful in self.writeSerialNumberComplete?(id, successful) }
        device.lambdaReadSerialNumberComplete = { id, successful, partID in self.readSerialNumberComplete?(id, successful, partID) }
        device.lambdaDeleteSerialNumberComplete = { id, successful in self.deleteSerialNumberComplete?(id, successful) }
        device.lambdaWriteAdvIntervalComplete = { id, successful in self.writeAdvIntervalComplete?(id, successful) }
        device.lambdaReadAdvIntervalComplete = { id, successful, seconds in self.readAdvIntervalComplete?(id, successful, seconds) }
        device.lambdaDeleteAdvIntervalComplete  = { id, successful in self.deleteAdvIntervalComplete?(id, successful) }
        device.lambdaClearChargeCyclesComplete = { id, successful in self.clearChargeCyclesComplete?(id, successful) }
        device.lambdaReadChargeCyclesComplete = { id, successful, cycles in self.readChargeCyclesComplete?(id, successful, cycles) }
        device.lambdaReadCanLogDiagnosticsComplete  = { id, successful, allow in self.readCanLogDiagnosticsComplete?(id, successful, allow) }
        device.lambdaUpdateCanLogDiagnosticsComplete  = { id, successful in self.updateCanLogDiagnosticsComplete?(id, successful) }
        device.lambdaWornCheckComplete = { id, successful, code, value in self.wornCheckComplete?(id, successful, code, value) }
        device.lambdaRawLoggingComplete = { id, successful in self.rawLoggingComplete?(id, successful) }
        device.lambdaGetRawLoggingStatusComplete  = { id, successful, enabled in self.getRawLoggingStatusComplete?(id, successful, enabled) }
        device.lambdaGetWornOverrideStatusComplete  = { id, successful, overridden in self.getWornOverrideStatusComplete?(id, successful, overridden) }
        device.lambdaAirplaneModeComplete = { id, successful in self.airplaneModeComplete?(id, successful) }
        device.lambdaResetComplete = { id, successful in self.resetComplete?(id, successful) }
        device.lambdaDisableWornDetectComplete = { id, successful in self.disableWornDetectComplete?(id, successful) }
        device.lambdaEnableWornDetectComplete = { id, successful in self.enableWornDetectComplete?(id, successful) }
        device.lambdaPPGMetrics      = { id, successful, packet in self.ppgMetrics?(id, successful, packet) }
        device.lambdaPPGFailed = { id, code in self.ppgFailed?(id, code) }
        
        device.lambdaDataPackets = { id, sequence_number, packets in
            if (self.dataPacketsOnBackgroundThread) { self.dataPackets?(id, sequence_number, packets) }
            else { self.dataPackets?(id, sequence_number, packets) }
        }
        
        device.lambdaStreamingPacket = { id, packet in self.streamingPacket?(id, packet) }
        device.lambdaDataAvailable = { id in self.dataAvailable?(id) }
        device.lambdaDataComplete = { id, bad_fw_read_count, bad_fw_packet_count, overflow_count, bad_sdk_parse_count, intermediate in self.dataComplete?(id, bad_fw_read_count, bad_fw_packet_count, overflow_count, bad_sdk_parse_count, intermediate) }
        device.lambdaDataFailure = { id in self.dataFailure?(id) }
        device.lambdaWornStatus = { id, isWorn in self.deviceWornStatus?(id, isWorn) }
        device.lambdaUpdateFirmwareFailed = { id, code, message in self.updateFirmwareFailed?(id, code, message) }
        device.lambdaUpdateFirmwareFinished = { id in self.updateFirmwareFinished?(id) }
        device.lambdaUpdateFirmwareStarted = { id in self.updateFirmwareStarted?(id) }
        device.lambdaUpdateFirmwareProgress = { id, percentage in self.updateFirmwareProgress?(id, percentage) }
        device.lambdaSetSessionParamComplete = { id, successful, parameter in self.setSessionParamComplete?(id, successful, parameter) }
        device.lambdaGetSessionParamComplete = { id, successful, parameter, value in self.getSessionParamComplete?(id, successful, parameter, value) }
        device.lambdaResetSessionParamsComplete = { id, successful in self.resetSessionParamsComplete?(id, successful) }
        device.lambdaAcceptSessionParamsComplete = { id, successful in self.acceptSessionParamsComplete?(id, successful) }
        device.lambdaManufacturingTestComplete = { id, successful in self.manufacturingTestComplete?(id, successful) }
        device.lambdaManufacturingTestResult = { id, valid, result in self.manufacturingTestResult?(id, valid, result) }
        device.lambdaChargingStatus = { id, charging, on_charger, error in self.deviceChargingStatus?(id, charging, on_charger, error) }
        device.lambdaSetHRZoneColorComplete = { id, successful, type in self.setHRZoneColorComplete?(id, successful, type) }
        device.lambdaGetHRZoneColorComplete = { id, successful, type, red, green, blue, on_ms, off_ms in self.getHRZoneColorComplete?(id, successful, type, red, green, blue, on_ms, off_ms) }
        device.lambdaSetHRZoneRangeComplete = { id, successful in self.setHRZoneRangeComplete?(id, successful) }
        device.lambdaGetHRZoneRangeComplete = { id, successful, enabled, high_value, low_value in self.getHRZoneRangeComplete?(id, successful, enabled, high_value, low_value) }
        device.lambdaGetPPGAlgorithmComplete = { id, successful, algorithm, state in self.getPPGAlgorithmComplete?(id, successful, algorithm, state) }
        device.lambdaSetAdvertiseAsHRMComplete = { id, successful, asHRM in self.setAdvertiseAsHRMComplete?(id, successful, asHRM) }
        device.lambdaGetAdvertiseAsHRMComplete = { id, successful, asHRM in self.getAdvertiseAsHRMComplete?(id, successful, asHRM) }
        device.lambdaSetButtonCommandComplete = { id, successful, tap, command in self.setButtonCommandComplete?(id, successful, tap, command) }
        device.lambdaGetButtonCommandComplete = { id, successful, tap, command in self.getButtonCommandComplete?(id, successful, tap, command) }
        device.lambdaSetPairedComplete = { id, successful in self.setPairedComplete?(id, successful) }
        device.lambdaSetUnpairedComplete = { id, successful in self.setUnpairedComplete?(id, successful) }
        device.lambdaGetPairedComplete = { id, successful, paired in self.getPairedComplete?(id, successful, paired) }
        device.lambdaSetPageThresholdComplete = { id, successful in self.setPageThresholdComplete?(id, successful) }
        device.lambdaGetPageThresholdComplete = { id, successful, threshold in self.getPageThresholdComplete?(id, successful, threshold) }
        device.lambdaDeletePageThresholdComplete = { id, successful in self.deletePageThresholdComplete?(id, successful) }
        device.lambdaSetAskForButtonResponseComplete = { id, successful, enable in self.setAskForButtonResponseComplete?(id, successful, enable) }
        device.lambdaGetAskForButtonResponseComplete = { id, successful, enable in self.getAskForButtonResponseComplete?(id, successful, enable) }
        device.lambdaEndSleepStatus  = { id, hasSleep in self.endSleepStatus?(id, hasSleep) }
        device.lambdaButtonClicked  = { id, presses in self.buttonClicked?(id, presses) }
	}
	
	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
		var valid = false
		var valid_type_but_no_name = false
		var discovery_type = biostrapDiscoveryType.unknown
		var has_serial = false
		var deviceName = ""
		var device_service = org_bluetooth_service.user_data.UUID
		var services = [CBUUID]()

		// Filter out all devices that i can't even connect to
		if let connectable = advertisementData[CBAdvertisementDataIsConnectable] as? Bool {
			if (!connectable) { return }
		}
		else {
			//log?.e ("\(peripheral.prettyID): Can't find connectable flag...")
			return
		}
		
		// Paired with UUID or legacy
		if let serviceUUIDs = advertisementData[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID] {

			// One of ours
			if (Device.scan_services.contains(serviceUUIDs[0])) {
				services = serviceUUIDs
				
				// New devices will also have manufacturer's data with the 128-bit UUID
				if let manufacturer_data = advertisementData[CBAdvertisementDataManufacturerDataKey] as? Data {
					if ((manufacturer_data[0] & 0x01) != 0x00) {
						discovery_type = .paired_w_uuid
					}
					else {
						discovery_type = .unpaired_w_uuid	// This really shouldn't happen.  If we have a UUID and are not legacy, firmware should have set the paired bit
					}
					has_serial = (manufacturer_data[0] & 0x02) != 0x00
					
					// Since we have a UUID in the advertisement, no room for a name.  Either this is a device we care about (in our paired list), or it's a device
					// we have found that must belong to somebody else (because it was advertising with a UUID and has manufacturer's data.  In the latter case,
					// we don't know the name.
					if let test = mPairedDeviceNames[peripheral.prettyID] {
						deviceName = test
						valid = true
					}
					else {
						deviceName = peripheral.prettyID 	// A paired device we don't own
						valid = false
						valid_type_but_no_name = true
					}
					
					// If we want both paired
					if (scanForPaired && scanForUnpaired) { }
					else {
						if (scanForPaired && discovery_type.isNotPaired) { // Not a paired device, and I want paired devices only
							valid = false
							if (scanInBackground) { valid_type_but_no_name = true }
						}
						
						if (scanForUnpaired && discovery_type.isPaired) {	// Paired device, and I want unpaired devices only
							valid = false
							if (scanInBackground) { valid_type_but_no_name = true }
						}
					}
				}
				
				// If no manufacturer's data, it's a legacy device
				else {
					discovery_type = .legacy	// Legacy device doesn't have manufacturer's data
					
					if !scanForLegacy && scanInBackground {	// We still need legacy devices to go through even if we don't want them, because in the background the OS will suspend us if we don't take action
						valid = false
						valid_type_but_no_name = true
						deviceName = peripheral.prettyID
					}
					else {
						
						// If this is a device I own, i definitely want it.
						if let test = mPairedDeviceNames[peripheral.prettyID] {
							deviceName = test
							valid = true
						}
						else {
							// Legacy Device has its name from scan response packet, but it doesn't always come through
							if let test = advertisementData[CBAdvertisementDataLocalNameKey] as? String {
								// Name came through
								deviceName = test
								if (scanForLegacy) { valid = true }
								else {
									valid = false
									valid_type_but_no_name = true
								}
							}
							else {
								// Name did not come through
								deviceName = peripheral.prettyID
								valid = false
								valid_type_but_no_name = true
							}
						}
					}
				}
			}
			
			// Heart rate monitor - still might be ours if it's new firmware.  This would be a paired device below the threshold, but with HRM advertising enabled
			else if (serviceUUIDs[0] == org_bluetooth_service.heart_rate.UUID) {
				(valid, discovery_type, has_serial, deviceName, device_service) = mGetNameFromManufacturerData(advertisementData)
				services.append(device_service)
				
				if (valid) {
					if let _ = mPairedDeviceNames[peripheral.prettyID] { }
					else {
						if (scanForPaired && scanForUnpaired) { }	// I want anything that is valid and is advertising with an HRM
						else {
							if (scanForPaired && discovery_type.isNotPaired) { 	// Not a paired device, and I want paired devices only
								valid = false
							}
							
							if (scanForUnpaired && discovery_type.isPaired) {	// Paired device, and I want unpaired devices only
								valid = false
							}
						}
					}

					services.append(contentsOf: serviceUUIDs)
					
					//log?.v ("\(peripheral.prettyID) - New FW: (HRM only) \(deviceName), paired = \(paired), has_serial = \(has_serial), \(services)")
				}
				else {
					if let test = mPairedDeviceNames[peripheral.prettyID] ?? advertisementData[CBAdvertisementDataLocalNameKey] as? String {
						deviceName = test
						//log?.v ("\(peripheral.prettyID) - Leg FW: \(deviceName) - \(serviceUUIDs)")
					}
				}
				services = serviceUUIDs
			}
		}
		
		// Paired without UUID or not paired
		else {
			(valid, discovery_type, has_serial, deviceName, device_service) = mGetNameFromManufacturerData(advertisementData)
			
			if (valid) {
				if let _ = mPairedDeviceNames[peripheral.prettyID] { }
				else {
					if (!scanForPaired && !scanForUnpaired) {	// I don't want anything
						valid = false
						valid_type_but_no_name = true
					}
					else if (scanForPaired && scanForUnpaired) { }	// I want anything that is valid
					else {
						if (scanForPaired && discovery_type.isNotPaired) { 	// Not a paired device, and I want paired devices only
							valid = false
							valid_type_but_no_name = true
						}
						
						if (scanForUnpaired && discovery_type.isPaired) {	// Paired device, and I want unpaired devices only
							valid = false
							valid_type_but_no_name = true
						}
					}
				}

				services.append(device_service)
				//log?.v ("\(peripheral.prettyID) - New FW: \(deviceName), paired = \(paired), has_serial = \(has_serial), \(device_service) [\(valid) - \(scanForPaired), \(scanForUnpaired)]")
			}
		}
		
		DispatchQueue.main.async { [self] in
			if let _ = self.connectedDevices.first(where: { $0.id == peripheral.prettyID }) {
				globals.log.e ("\(peripheral.prettyID): didDiscover: Discovered a device that is in my connected list.  Don't expect this...  Ignore")
			}
							
			for thisUUID in services {
#if UNIVERSAL || ALTER
				if (thisUUID == Device.services.alter.UUID) {
					
					if let device = self.discoveredDevices.first(where: { $0.id == peripheral.prettyID }) {
						if valid { discovered?(peripheral.prettyID, device) }
						else {
							if valid_type_but_no_name {
								globals.log.v ("\(peripheral.prettyID): didDiscover: Had already found this device, but it now has no name.  Strange...  Don't say it now has no name, though")
							}
						}
					}
					else {
#if UNIVERSAL
						let device = Device(deviceName, id: peripheral.prettyID, centralManager: mCentralManager, peripheral: peripheral, type: .alter, discoveryType: discovery_type)
#else
						let device = Device(deviceName, id: peripheral.prettyID, centralManager: mCentralManager, peripheral: peripheral, discoveryType: discovery_type)
#endif
						
						setupCallbacks(device)
						
						if valid {
							if let _ = self.unnamedDevices.first(where: { $0.id == peripheral.prettyID }) {
								globals.log.v ("\(peripheral.prettyID): didDiscover: Discovered a device that was unnamed but now has a name.  Update as named, and remove unnamed version")
								self.unnamedDevices.removeAll(where: { $0.id == peripheral.prettyID })
							}
							self.discoveredDevices.append(device)
							discovered?(peripheral.prettyID, device)
						}
						else {
							if valid_type_but_no_name {
								if self.unnamedDevices.first(where: { $0.id == peripheral.prettyID }) == nil { self.unnamedDevices.append(device) }
								self.discoveredUnnamed?(peripheral.prettyID, device)
							}
						}
					}
					
				}
#endif
				
#if UNIVERSAL || KAIROS
				if (thisUUID == Device.services.kairos.UUID) {
					
					if let device = self.discoveredDevices.first(where: { $0.id == peripheral.prettyID }) {
						if valid { discovered?(peripheral.prettyID, device) }
						else {
							if valid_type_but_no_name {
								globals.log.v ("\(peripheral.prettyID): didDiscover: Had already found this device, but it now has no name.  Strange...  Don't say it now has no name, though")
							}
						}
					}
					else {
#if UNIVERSAL
						let device = Device(deviceName, id: peripheral.prettyID, centralManager: mCentralManager, peripheral: peripheral, type: .kairos, discoveryType: discovery_type)
#else
						let device = Device(deviceName, id: peripheral.prettyID, centralManager: mCentralManager, peripheral: peripheral, discoveryType: discovery_type)
#endif
						
						setupCallbacks(device)
						
						if valid {
							if let _ = self.unnamedDevices.first(where: { $0.id == peripheral.prettyID }) {
								globals.log.v ("\(peripheral.prettyID): didDiscover: Discovered a device that was unnamed but now has a name.  Update as named, and remove unnamed version")
								self.unnamedDevices.removeAll(where: { $0.id == peripheral.prettyID })
							}
							self.discoveredDevices.append(device)
							discovered?(peripheral.prettyID, device)
						}
						else {
							if valid_type_but_no_name {
								if self.unnamedDevices.first(where: { $0.id == peripheral.prettyID }) == nil { self.unnamedDevices.append(device) }
								self.discoveredUnnamed?(peripheral.prettyID, device)
							}
						}
					}
				}
#endif
				
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
		globals.log.v("\(peripheral.prettyID): didConnect")
		
		DispatchQueue.main.async { [self] in
			if let device = discoveredDevices.first(where: { $0.id == peripheral.prettyID }) {
				if !device.didConnect() {
					globals.log.e ("Can't finish the didConnect for a device in my discovered list - disconnecting")
					mCentralManager?.cancelPeripheralConnection(peripheral)
				}
			}
			else if let device = unnamedDevices.first(where: { $0.id == peripheral.prettyID }) {
				if !device.didConnect() {
					globals.log.e ("Can't finish the didConnect for a device in my unnamed list - disconnecting")
					mCentralManager?.cancelPeripheralConnection(peripheral)
				}
			}
			else {
				globals.log.e ("\(peripheral.prettyID): didConnect - Connected to a device not in my discovered or unnamed list.  Disconnect")
				mCentralManager?.cancelPeripheralConnection(peripheral)
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
			if let device = self.unnamedDevices.first(where: { $0.id == id }) {
				if device.connectionState == .connecting || device.connectionState == .configuring {
					device.connectionState = .disconnected
				}
				else {
					globals.log.e ("\(id): Disconnected from an unnamed device that is in state '\(device.connectionState)'.  Weird!")
				}
				
				self.deviceDisconnected.send(device)
			}
			
			if let device = self.discoveredDevices.first(where: { $0.id == id }) {
				if device.connectionState == .connecting || device.connectionState == .configuring {
					device.connectionState = .disconnected
				}
				else {
					globals.log.e ("\(id): Disconnected from a discovered device that is in state '\(device.connectionState)'.  Weird!")
				}

				self.deviceDisconnected.send(device)
			}
			
			if let device = self.connectedDevices.first(where: { $0.id == id }) {
				if device.connectionState == .configured {
					device.connectionState = .disconnected
				}
				else {
					globals.log.e ("\(id): Disconnected from a connected device that is in state '\(device.connectionState)'.  Weird!")
				}
				
				self.deviceDisconnected.send(device)
			}

			self.unnamedDevices.removeAll(where: { $0.id == id })
			self.discoveredDevices.removeAll(where: { $0.id == id })
			self.connectedDevices.removeAll(where: { $0.id == id })

			self.disconnected?(id)
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
		globals.log.v("\(peripheral.prettyID): didDisconnectPeripheral")
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
		globals.log.v("\(peripheral.prettyID): didFailToConnect")
		self.mProcessDisconnection(peripheral.prettyID)
	}
	
	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	public func centralManager(_ central: CBCentralManager, willRestoreState dict: [String : Any]) {
		if let connectedperipherals = dict[CBCentralManagerRestoredStatePeripheralsKey] as? [CBPeripheral] {
			for peripheral in connectedperipherals {
				  connect(peripheral.prettyID)
			}
		}
	}
}

