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
				self.mDiscoveredDevices.removeAll()
				
				for (id, _) in self.mConnectedDevices { self.mProcessDisconnection(id) }
				
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
						log?.v (" --- No name: Flags = \(manufacturer_data.hexString)")
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
						log?.w (" --- has name, but length is weird: ${data.hexString()}")
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
						
#if UNIVERSAL || ETHOS
						if (deviceType == .ethos) {
							valid = true
							service = Device.services.ethos.UUID
						}
#endif
						
#if UNIVERSAL || KAIROS
						if (deviceType == .kairos) {
							valid = true
							service = Device.services.kairos.UUID
						}
#endif
						
#if UNIVERSAL || LIVOTAL
						if (deviceType == .livotal) {
							valid = true
							service = Device.services.livotal.UUID
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
						log?.w ("Found a device with BS as the first two characters, but other advertising data I do not understand: \(manufacturer_data.hexString)")
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
			if let _ = self.mConnectedDevices[peripheral.prettyID] {
				log?.e ("\(peripheral.prettyID): didDiscover: Discovered a device that is in my connected list.  Don't expect this...  Ignore")
			}
							
			for thisUUID in services {
#if UNIVERSAL || ALTER
				if (thisUUID == Device.services.alter.UUID) {
					
					if let device = self.mDiscoveredDevices[peripheral.prettyID] {
						if valid { discovered?(peripheral.prettyID, device) }
						else {
							if valid_type_but_no_name { self.discoveredUnnamed?(peripheral.prettyID, device) }
						}
					}
					else {
#if UNIVERSAL
						let device = Device(deviceName, id: peripheral.prettyID, peripheral: peripheral, type: .alter, discoveryType: discovery_type)
#else
						let device = Device(deviceName, id: peripheral.prettyID, peripheral: peripheral, discoveryType: discovery_type)
#endif
						
						device.epoch					= Date().timeIntervalSince1970
						
						device.lambdaBatteryLevelUpdated					= { id, percentage in DispatchQueue.main.async { self.batteryLevel?(id, percentage) } }
						device.lambdaHeartRateUpdated						= { id, epoch, hr, rr in DispatchQueue.main.async { self.heartRate?(id, epoch, hr, rr) } }
						device.lambdaWriteEpochComplete = { id, successful in DispatchQueue.main.async { self.writeEpochComplete?(id, successful) } }
						device.lambdaReadEpochComplete = { id, successful, value in DispatchQueue.main.async { self.readEpochComplete?(id, successful, value) } }
						device.lambdaEndSleepComplete						= { id, successful in DispatchQueue.main.async { self.endSleepComplete?(id, successful) } }
						device.lambdaGetAllPacketsComplete				= { id, successful in DispatchQueue.main.async { self.getAllPacketsComplete?(id, successful) } }
						device.lambdaGetAllPacketsAcknowledgeComplete		= { id, successful, ack in DispatchQueue.main.async { self.getAllPacketsAcknowledgeComplete?(id, successful, ack) } }
						device.lambdaGetNextPacketComplete				= { id, successful, error_code, caughtUp, packet in DispatchQueue.main.async { self.getNextPacketComplete?(id, successful, error_code, caughtUp, packet) } }
						device.lambdaGetPacketCountComplete				= { id, successful, count in DispatchQueue.main.async { self.getPacketCountComplete?(id, successful, count) } }
						device.lambdaStartManualComplete 					= { id, successful in DispatchQueue.main.async { self.startManualComplete?(id, successful) } }
						device.lambdaStopManualComplete 					= { id, successful in DispatchQueue.main.async { self.stopManualComplete?(id, successful) } }
						device.lambdaLEDComplete							= { id, successful in DispatchQueue.main.async { self.ledComplete?(id, successful) } }
						device.lambdaEnterShipModeComplete				= { id, successful in DispatchQueue.main.async { self.enterShipModeComplete?(id, successful) } }
						device.lamdaWriteSerialNumberComplete			= { id, successful in DispatchQueue.main.async { self.writeSerialNumberComplete?(id, successful) } }
						device.lambdaReadSerialNumberComplete				= { id, successful, partID in DispatchQueue.main.async { self.readSerialNumberComplete?(id, successful, partID) } }
						device.lambdaDeleteSerialNumberComplete			= { id, successful in DispatchQueue.main.async { self.deleteSerialNumberComplete?(id, successful) } }
						device.lambdaWriteAdvIntervalComplete				= { id, successful in DispatchQueue.main.async { self.writeAdvIntervalComplete?(id, successful) } }
						device.lambdaReadAdvIntervalComplete				= { id, successful, seconds in DispatchQueue.main.async { self.readAdvIntervalComplete?(id, successful, seconds) } }
						device.lambdaDeleteAdvIntervalComplete 			= { id, successful in DispatchQueue.main.async { self.deleteAdvIntervalComplete?(id, successful) } }
						device.lambdaClearChargeCyclesComplete			= { id, successful in DispatchQueue.main.async { self.clearChargeCyclesComplete?(id, successful) } }
						device.lambdaReadChargeCyclesComplete				= { id, successful, cycles in DispatchQueue.main.async { self.readChargeCyclesComplete?(id, successful, cycles) } }
						device.lambdaReadCanLogDiagnosticsComplete 		= { id, successful, allow in DispatchQueue.main.async { self.readCanLogDiagnosticsComplete?(id, successful, allow) } }
						device.lambdaUpdateCanLogDiagnosticsComplete 		= { id, successful in DispatchQueue.main.async { self.updateCanLogDiagnosticsComplete?(id, successful) } }
						device.lambdaAllowPPGComplete						= { id, successful in DispatchQueue.main.async { self.allowPPGComplete?(id, successful) } }
						device.lambdaWornCheckComplete					= { id, successful, code, value in DispatchQueue.main.async { self.wornCheckComplete?(id, successful, code, value) } }
						device.lambdaRawLoggingComplete					= { id, successful in DispatchQueue.main.async { self.rawLoggingComplete?(id, successful) } }
						device.lambdaGetRawLoggingStatusComplete 			= { id, successful, enabled in DispatchQueue.main.async { self.getRawLoggingStatusComplete?(id, successful, enabled) } }
						device.lambdaGetWornOverrideStatusComplete 		= { id, successful, overridden in DispatchQueue.main.async { self.getWornOverrideStatusComplete?(id, successful, overridden) } }
						device.lambdaAirplaneModeComplete					= { id, successful in DispatchQueue.main.async { self.airplaneModeComplete?(id, successful) } }
						device.lambdaResetComplete						= { id, successful in DispatchQueue.main.async { self.resetComplete?(id, successful) } }
						device.lambdaDisableWornDetectComplete			= { id, successful in DispatchQueue.main.async { self.disableWornDetectComplete?(id, successful) } }
						device.lambdaEnableWornDetectComplete				= { id, successful in DispatchQueue.main.async { self.enableWornDetectComplete?(id, successful) } }
						device.lambdaPPGMetrics     						= { id, successful, packet in DispatchQueue.main.async { self.ppgMetrics?(id, successful, packet) } }
						device.lambdaPPGFailed							= { id, code in DispatchQueue.main.async { self.ppgFailed?(id, code) } }
						
						device.lambdaDataPackets							= { id, sequence_number, packets in
							if (self.dataPacketsOnBackgroundThread) { self.dataPackets?(id, sequence_number, packets) }
							else { DispatchQueue.main.async { self.dataPackets?(id, sequence_number, packets) } }
						}
						
						device.lambdaStreamingPacket						= { id, packet in DispatchQueue.main.async { self.streamingPacket?(id, packet) } }
						device.lambdaDataAvailable						= { id in DispatchQueue.main.async { self.dataAvailable?(id) }}
						device.lambdaDataComplete							= { id, bad_fw_read_count, bad_fw_packet_count, overflow_count, bad_sdk_parse_count, intermediate in DispatchQueue.main.async { self.dataComplete?(id, bad_fw_read_count, bad_fw_packet_count, overflow_count, bad_sdk_parse_count, intermediate) } }
						device.lambdaDataFailure							= { id in DispatchQueue.main.async { self.dataFailure?(id) } }
						device.lambdaWornStatus						= { id, isWorn in DispatchQueue.main.async { self.deviceWornStatus?(id, isWorn) } }
						device.lambdaUpdateFirmwareFailed					= { id, code, message in DispatchQueue.main.async { self.updateFirmwareFailed?(id, code, message) } }
						device.lambdaUpdateFirmwareFinished				= { id in DispatchQueue.main.async { self.updateFirmwareFinished?(id) } }
						device.lambdaUpdateFirmwareStarted				= { id in DispatchQueue.main.async { self.updateFirmwareStarted?(id) } }
						device.lambdaUpdateFirmwareProgress				= { id, percentage in DispatchQueue.main.async { self.updateFirmwareProgress?(id, percentage) } }
						device.lambdaSetSessionParamComplete				= { id, successful, parameter in DispatchQueue.main.async { self.setSessionParamComplete?(id, successful, parameter) } }
						device.lambdaGetSessionParamComplete				= { id, successful, parameter, value in DispatchQueue.main.async { self.getSessionParamComplete?(id, successful, parameter, value) } }
						device.lambdaResetSessionParamsComplete			= { id, successful in DispatchQueue.main.async { self.resetSessionParamsComplete?(id, successful) } }
						device.lambdaAcceptSessionParamsComplete			= { id, successful in DispatchQueue.main.async { self.acceptSessionParamsComplete?(id, successful) } }
						device.lambdaManufacturingTestComplete			= { id, successful in DispatchQueue.main.async { self.manufacturingTestComplete?(id, successful) } }
						device.lambdaManufacturingTestResult				= { id, valid, result in DispatchQueue.main.async { self.manufacturingTestResult?(id, valid, result) } }
						device.lambdaRecalibratePPGComplete				= { id, successful in DispatchQueue.main.async { self.recalibratePPGComplete?(id, successful) } }
						device.lambdaChargingStatus					= { id, charging, on_charger, error in DispatchQueue.main.async { self.deviceChargingStatus?(id, charging, on_charger, error) } }
						device.lambdaSetHRZoneColorComplete				= { id, successful, type in DispatchQueue.main.async { self.setHRZoneColorComplete?(id, successful, type) } }
						device.lambdaGetHRZoneColorComplete				= { id, successful, type, red, green, blue, on_ms, off_ms in DispatchQueue.main.async { self.getHRZoneColorComplete?(id, successful, type, red, green, blue, on_ms, off_ms) } }
						device.lambdaSetHRZoneRangeComplete				= { id, successful in DispatchQueue.main.async { self.setHRZoneRangeComplete?(id, successful) } }
						device.lambdaGetHRZoneRangeComplete				= { id, successful, enabled, high_value, low_value in DispatchQueue.main.async { self.getHRZoneRangeComplete?(id, successful, enabled, high_value, low_value) } }
						device.lambdaGetPPGAlgorithmComplete				= { id, successful, algorithm, state in DispatchQueue.main.async { self.getPPGAlgorithmComplete?(id, successful, algorithm, state) } }
						device.lambdaSetAdvertiseAsHRMComplete			= { id, successful, asHRM in DispatchQueue.main.async { self.setAdvertiseAsHRMComplete?(id, successful, asHRM) } }
						device.lambdaGetAdvertiseAsHRMComplete			= { id, successful, asHRM in DispatchQueue.main.async { self.getAdvertiseAsHRMComplete?(id, successful, asHRM) } }
						device.lambdaSetButtonCommandComplete				= { id, successful, tap, command in DispatchQueue.main.async { self.setButtonCommandComplete?(id, successful, tap, command) } }
						device.lambdaGetButtonCommandComplete				= { id, successful, tap, command in DispatchQueue.main.async { self.getButtonCommandComplete?(id, successful, tap, command) } }
						device.lambdaSetPairedComplete					= { id, successful in DispatchQueue.main.async { self.setPairedComplete?(id, successful) } }
						device.lambdaSetUnpairedComplete					= { id, successful in DispatchQueue.main.async { self.setUnpairedComplete?(id, successful) } }
						device.lambdaGetPairedComplete					= { id, successful, paired in DispatchQueue.main.async { self.getPairedComplete?(id, successful, paired) } }
						device.lambdaSetPageThresholdComplete				= { id, successful in DispatchQueue.main.async { self.setPageThresholdComplete?(id, successful) } }
						device.lambdaGetPageThresholdComplete				= { id, successful, threshold in DispatchQueue.main.async { self.getPageThresholdComplete?(id, successful, threshold) } }
						device.lambdaDeletePageThresholdComplete			= { id, successful in DispatchQueue.main.async { self.deletePageThresholdComplete?(id, successful) } }
						device.lambdaSetAskForButtonResponseComplete		= { id, successful, enable in DispatchQueue.main.async { self.setAskForButtonResponseComplete?(id, successful, enable) } }
						device.lambdaGetAskForButtonResponseComplete		= { id, successful, enable in DispatchQueue.main.async { self.getAskForButtonResponseComplete?(id, successful, enable) } }
						device.lambdaEndSleepStatus 						= { id, hasSleep in DispatchQueue.main.async { self.endSleepStatus?(id, hasSleep) } }
						device.lambdaButtonClicked 						= { id, presses in DispatchQueue.main.async { self.buttonClicked?(id, presses) } }
						
						if valid {
							self.mDiscoveredDevices[peripheral.prettyID] = device
							discovered?(peripheral.prettyID, device)
						}
						else {
							if valid_type_but_no_name { self.discoveredUnnamed?(peripheral.prettyID, device) }
						}
					}
					
				}
#endif
				
#if UNIVERSAL || KAIROS
				if (thisUUID == Device.services.kairos.UUID) {
					
					if let device = mDiscoveredDevices[peripheral.prettyID] {
						if valid { discovered?(peripheral.prettyID, device) }
						else {
							if valid_type_but_no_name { self.discoveredUnnamed?(peripheral.prettyID, device) }
						}
					}
					else {
#if UNIVERSAL
						let device = Device(deviceName, id: peripheral.prettyID, peripheral: peripheral, type: .kairos, discoveryType: discovery_type)
#else
						let device = Device(deviceName, id: peripheral.prettyID, peripheral: peripheral, discoveryType: discovery_type)
#endif
						
						device.epoch					= Date().timeIntervalSince1970
						
						device.lambdaBatteryLevelUpdated					= { id, percentage in DispatchQueue.main.async { self.batteryLevel?(id, percentage) } }
						device.lambdaHeartRateUpdated						= { id, epoch, hr, rr in DispatchQueue.main.async { self.heartRate?(id, epoch, hr, rr) } }
						device.lambdaWriteEpochComplete = { id, successful in DispatchQueue.main.async { self.writeEpochComplete?(id, successful) } }
						device.lambdaReadEpochComplete = { id, successful, value in DispatchQueue.main.async { self.readEpochComplete?(id, successful, value) } }
						device.lambdaEndSleepComplete						= { id, successful in DispatchQueue.main.async { self.endSleepComplete?(id, successful) } }
						device.lambdaGetAllPacketsComplete				= { id, successful in DispatchQueue.main.async { self.getAllPacketsComplete?(id, successful) } }
						device.lambdaGetAllPacketsAcknowledgeComplete		= { id, successful, ack in DispatchQueue.main.async { self.getAllPacketsAcknowledgeComplete?(id, successful, ack) } }
						device.lambdaGetNextPacketComplete				= { id, successful, error_code, caughtUp, packet in DispatchQueue.main.async { self.getNextPacketComplete?(id, successful, error_code, caughtUp, packet) } }
						device.lambdaGetPacketCountComplete				= { id, successful, count in DispatchQueue.main.async { self.getPacketCountComplete?(id, successful, count) } }
						device.lambdaStartManualComplete 					= { id, successful in DispatchQueue.main.async { self.startManualComplete?(id, successful) } }
						device.lambdaStopManualComplete 					= { id, successful in DispatchQueue.main.async { self.stopManualComplete?(id, successful) } }
						device.lambdaLEDComplete							= { id, successful in DispatchQueue.main.async { self.ledComplete?(id, successful) } }
						device.lambdaEnterShipModeComplete				= { id, successful in DispatchQueue.main.async { self.enterShipModeComplete?(id, successful) } }
						device.lamdaWriteSerialNumberComplete			= { id, successful in DispatchQueue.main.async { self.writeSerialNumberComplete?(id, successful) } }
						device.lambdaReadSerialNumberComplete				= { id, successful, partID in DispatchQueue.main.async { self.readSerialNumberComplete?(id, successful, partID) } }
						device.lambdaDeleteSerialNumberComplete			= { id, successful in DispatchQueue.main.async { self.deleteSerialNumberComplete?(id, successful) } }
						device.lambdaWriteAdvIntervalComplete				= { id, successful in DispatchQueue.main.async { self.writeAdvIntervalComplete?(id, successful) } }
						device.lambdaReadAdvIntervalComplete				= { id, successful, seconds in DispatchQueue.main.async { self.readAdvIntervalComplete?(id, successful, seconds) } }
						device.lambdaDeleteAdvIntervalComplete 			= { id, successful in DispatchQueue.main.async { self.deleteAdvIntervalComplete?(id, successful) } }
						device.lambdaClearChargeCyclesComplete			= { id, successful in DispatchQueue.main.async { self.clearChargeCyclesComplete?(id, successful) } }
						device.lambdaReadChargeCyclesComplete				= { id, successful, cycles in DispatchQueue.main.async { self.readChargeCyclesComplete?(id, successful, cycles) } }
						device.lambdaReadCanLogDiagnosticsComplete 		= { id, successful, allow in DispatchQueue.main.async { self.readCanLogDiagnosticsComplete?(id, successful, allow) } }
						device.lambdaUpdateCanLogDiagnosticsComplete 		= { id, successful in DispatchQueue.main.async { self.updateCanLogDiagnosticsComplete?(id, successful) } }
						device.lambdaAllowPPGComplete						= { id, successful in DispatchQueue.main.async { self.allowPPGComplete?(id, successful) } }
						device.lambdaWornCheckComplete					= { id, successful, code, value in DispatchQueue.main.async { self.wornCheckComplete?(id, successful, code, value) } }
						device.lambdaRawLoggingComplete					= { id, successful in DispatchQueue.main.async { self.rawLoggingComplete?(id, successful) } }
						device.lambdaGetRawLoggingStatusComplete 			= { id, successful, enabled in DispatchQueue.main.async { self.getRawLoggingStatusComplete?(id, successful, enabled) } }
						device.lambdaGetWornOverrideStatusComplete 		= { id, successful, overridden in DispatchQueue.main.async { self.getWornOverrideStatusComplete?(id, successful, overridden) } }
						device.lambdaAirplaneModeComplete					= { id, successful in DispatchQueue.main.async { self.airplaneModeComplete?(id, successful) } }
						device.lambdaResetComplete						= { id, successful in DispatchQueue.main.async { self.resetComplete?(id, successful) } }
						device.lambdaDisableWornDetectComplete			= { id, successful in DispatchQueue.main.async { self.disableWornDetectComplete?(id, successful) } }
						device.lambdaEnableWornDetectComplete				= { id, successful in DispatchQueue.main.async { self.enableWornDetectComplete?(id, successful) } }
						device.lambdaPPGMetrics     						= { id, successful, packet in DispatchQueue.main.async { self.ppgMetrics?(id, successful, packet) } }
						device.lambdaPPGFailed							= { id, code in DispatchQueue.main.async { self.ppgFailed?(id, code) } }
						
						device.lambdaDataPackets							= { id, sequence_number, packets in
							if (self.dataPacketsOnBackgroundThread) { self.dataPackets?(id, sequence_number, packets) }
							else { DispatchQueue.main.async { self.dataPackets?(id, sequence_number, packets) } }
						}
						
						device.lambdaStreamingPacket						= { id, packet in DispatchQueue.main.async { self.streamingPacket?(id, packet) } }
						device.lambdaDataAvailable						= { id in DispatchQueue.main.async { self.dataAvailable?(id) }}
						device.lambdaDataComplete							= { id, bad_fw_read_count, bad_fw_packet_count, overflow_count, bad_sdk_parse_count, intermediate in DispatchQueue.main.async { self.dataComplete?(id, bad_fw_read_count, bad_fw_packet_count, overflow_count, bad_sdk_parse_count, intermediate) } }
						device.lambdaDataFailure							= { id in DispatchQueue.main.async { self.dataFailure?(id) } }
						device.lambdaWornStatus						= { id, isWorn in DispatchQueue.main.async { self.deviceWornStatus?(id, isWorn) } }
						device.lambdaUpdateFirmwareFailed					= { id, code, message in DispatchQueue.main.async { self.updateFirmwareFailed?(id, code, message) } }
						device.lambdaUpdateFirmwareFinished				= { id in DispatchQueue.main.async { self.updateFirmwareFinished?(id) } }
						device.lambdaUpdateFirmwareStarted				= { id in DispatchQueue.main.async { self.updateFirmwareStarted?(id) } }
						device.lambdaUpdateFirmwareProgress				= { id, percentage in DispatchQueue.main.async { self.updateFirmwareProgress?(id, percentage) } }
						device.lambdaSetSessionParamComplete				= { id, successful, parameter in DispatchQueue.main.async { self.setSessionParamComplete?(id, successful, parameter) } }
						device.lambdaGetSessionParamComplete				= { id, successful, parameter, value in DispatchQueue.main.async { self.getSessionParamComplete?(id, successful, parameter, value) } }
						device.lambdaResetSessionParamsComplete			= { id, successful in DispatchQueue.main.async { self.resetSessionParamsComplete?(id, successful) } }
						device.lambdaAcceptSessionParamsComplete			= { id, successful in DispatchQueue.main.async { self.acceptSessionParamsComplete?(id, successful) } }
						device.lambdaManufacturingTestComplete			= { id, successful in DispatchQueue.main.async { self.manufacturingTestComplete?(id, successful) } }
						device.lambdaManufacturingTestResult				= { id, valid, result in DispatchQueue.main.async { self.manufacturingTestResult?(id, valid, result) } }
						device.lambdaRecalibratePPGComplete				= { id, successful in DispatchQueue.main.async { self.recalibratePPGComplete?(id, successful) } }
						device.lambdaChargingStatus					= { id, charging, on_charger, error in DispatchQueue.main.async { self.deviceChargingStatus?(id, charging, on_charger, error) } }
						device.lambdaSetHRZoneColorComplete				= { id, successful, type in DispatchQueue.main.async { self.setHRZoneColorComplete?(id, successful, type) } }
						device.lambdaGetHRZoneColorComplete				= { id, successful, type, red, green, blue, on_ms, off_ms in DispatchQueue.main.async { self.getHRZoneColorComplete?(id, successful, type, red, green, blue, on_ms, off_ms) } }
						device.lambdaSetHRZoneRangeComplete				= { id, successful in DispatchQueue.main.async { self.setHRZoneRangeComplete?(id, successful) } }
						device.lambdaGetHRZoneRangeComplete				= { id, successful, enabled, high_value, low_value in DispatchQueue.main.async { self.getHRZoneRangeComplete?(id, successful, enabled, high_value, low_value) } }
						device.lambdaGetPPGAlgorithmComplete				= { id, successful, algorithm, state in DispatchQueue.main.async { self.getPPGAlgorithmComplete?(id, successful, algorithm, state) } }
						device.lambdaSetAdvertiseAsHRMComplete			= { id, successful, asHRM in DispatchQueue.main.async { self.setAdvertiseAsHRMComplete?(id, successful, asHRM) } }
						device.lambdaGetAdvertiseAsHRMComplete			= { id, successful, asHRM in DispatchQueue.main.async { self.getAdvertiseAsHRMComplete?(id, successful, asHRM) } }
						device.lambdaSetButtonCommandComplete				= { id, successful, tap, command in DispatchQueue.main.async { self.setButtonCommandComplete?(id, successful, tap, command) } }
						device.lambdaGetButtonCommandComplete				= { id, successful, tap, command in DispatchQueue.main.async { self.getButtonCommandComplete?(id, successful, tap, command) } }
						device.lambdaSetPairedComplete					= { id, successful in DispatchQueue.main.async { self.setPairedComplete?(id, successful) } }
						device.lambdaSetUnpairedComplete					= { id, successful in DispatchQueue.main.async { self.setUnpairedComplete?(id, successful) } }
						device.lambdaGetPairedComplete					= { id, successful, paired in DispatchQueue.main.async { self.getPairedComplete?(id, successful, paired) } }
						device.lambdaSetPageThresholdComplete				= { id, successful in DispatchQueue.main.async { self.setPageThresholdComplete?(id, successful) } }
						device.lambdaGetPageThresholdComplete				= { id, successful, threshold in DispatchQueue.main.async { self.getPageThresholdComplete?(id, successful, threshold) } }
						device.lambdaDeletePageThresholdComplete			= { id, successful in DispatchQueue.main.async { self.deletePageThresholdComplete?(id, successful) } }
						device.lambdaSetAskForButtonResponseComplete		= { id, successful, enable in DispatchQueue.main.async { self.setAskForButtonResponseComplete?(id, successful, enable) } }
						device.lambdaGetAskForButtonResponseComplete		= { id, successful, enable in DispatchQueue.main.async { self.getAskForButtonResponseComplete?(id, successful, enable) } }
						device.lambdaEndSleepStatus 						= { id, hasSleep in DispatchQueue.main.async { self.endSleepStatus?(id, hasSleep) } }
						device.lambdaButtonClicked 						= { id, presses in DispatchQueue.main.async { self.buttonClicked?(id, presses) } }
						
						if valid {
							self.mDiscoveredDevices[peripheral.prettyID] = device
							discovered?(peripheral.prettyID, device)
						}
						else {
							if valid_type_but_no_name { self.discoveredUnnamed?(peripheral.prettyID, device) }
						}
					}
				}
#endif
				
#if UNIVERSAL || ETHOS
				if (thisUUID == Device.services.ethos.UUID) {
					
					if let device = self.mDiscoveredDevices[peripheral.prettyID] {
						if valid { discovered?(peripheral.prettyID, device) }
						else {
							if valid_type_but_no_name { self.discoveredUnnamed?(peripheral.prettyID, device) }
						}
					}
					else {
#if UNIVERSAL
						let device = Device(deviceName, id: peripheral.prettyID, peripheral: peripheral, type: .ethos, discoveryType: discovery_type)
#else
						let device = Device(deviceName, id: peripheral.prettyID, peripheral: peripheral, discoveryType: discovery_type)
#endif
						
						device.epoch					= Date().timeIntervalSince1970
						
						device.lambdaBatteryLevelUpdated					= { id, percentage in DispatchQueue.main.async { self.batteryLevel?(id, percentage) } }
						device.lambdaPulseOxUpdated						= { id, spo2, hr in DispatchQueue.main.async { self.pulseOx?(id, spo2, hr) } }
						device.lambdaHeartRateUpdated						= { id, epoch, hr, rr in DispatchQueue.main.async { self.heartRate?(id, epoch, hr, rr) } }
						device.lambdaWriteEpochComplete = { id, successful in DispatchQueue.main.async { self.writeEpochComplete?(id, successful) } }
						device.lambdaReadEpochComplete = { id, successful, value in DispatchQueue.main.async { self.readEpochComplete?(id, successful, value) } }
						device.lambdaEndSleepComplete						= { id, successful in DispatchQueue.main.async { self.endSleepComplete?(id, successful) } }
						device.lambdaDebugComplete						= { id, successful, device, data in DispatchQueue.main.async { self.debugComplete?(id, successful, device, data) } }
						device.lambdaGetAllPacketsComplete				= { id, successful in DispatchQueue.main.async { self.getAllPacketsComplete?(id, successful) } }
						device.lambdaGetAllPacketsAcknowledgeComplete		= { id, successful, ack in DispatchQueue.main.async { self.getAllPacketsAcknowledgeComplete?(id, successful, ack) } }
						device.lambdaGetNextPacketComplete				= { id, successful, error_code, caughtUp, packet in DispatchQueue.main.async { self.getNextPacketComplete?(id, successful, error_code, caughtUp, packet) } }
						device.lambdaGetPacketCountComplete				= { id, successful, count in DispatchQueue.main.async { self.getPacketCountComplete?(id, successful, count) } }
						device.lambdaStartManualComplete 					= { id, successful in DispatchQueue.main.async { self.startManualComplete?(id, successful) } }
						device.lambdaStopManualComplete 					= { id, successful in DispatchQueue.main.async { self.stopManualComplete?(id, successful) } }
						device.lambdaLEDComplete							= { id, successful in DispatchQueue.main.async { self.ledComplete?(id, successful) } }
						device.lambdaMotorComplete						= { id, successful in DispatchQueue.main.async { self.motorComplete?(id, successful) } }
						device.lambdaEnterShipModeComplete				= { id, successful in DispatchQueue.main.async { self.enterShipModeComplete?(id, successful) } }
						device.lamdaWriteSerialNumberComplete			= { id, successful in DispatchQueue.main.async { self.writeSerialNumberComplete?(id, successful) } }
						device.lambdaReadSerialNumberComplete				= { id, successful, partID in DispatchQueue.main.async { self.readSerialNumberComplete?(id, successful, partID) } }
						device.lambdaDeleteSerialNumberComplete			= { id, successful in DispatchQueue.main.async { self.deleteSerialNumberComplete?(id, successful) } }
						device.lambdaWriteAdvIntervalComplete				= { id, successful in DispatchQueue.main.async { self.writeAdvIntervalComplete?(id, successful) } }
						device.lambdaReadAdvIntervalComplete				= { id, successful, seconds in DispatchQueue.main.async { self.readAdvIntervalComplete?(id, successful, seconds) } }
						device.lambdaDeleteAdvIntervalComplete 			= { id, successful in DispatchQueue.main.async { self.deleteAdvIntervalComplete?(id, successful) } }
						device.lambdaClearChargeCyclesComplete			= { id, successful in DispatchQueue.main.async { self.clearChargeCyclesComplete?(id, successful) } }
						device.lambdaReadChargeCyclesComplete				= { id, successful, cycles in DispatchQueue.main.async { self.readChargeCyclesComplete?(id, successful, cycles) } }
						device.lambdaReadCanLogDiagnosticsComplete 		= { id, successful, allow in DispatchQueue.main.async { self.readCanLogDiagnosticsComplete?(id, successful, allow) } }
						device.lambdaUpdateCanLogDiagnosticsComplete 		= { id, successful in DispatchQueue.main.async { self.updateCanLogDiagnosticsComplete?(id, successful) } }
						device.lambdaAllowPPGComplete						= { id, successful in DispatchQueue.main.async { self.allowPPGComplete?(id, successful) } }
						device.lambdaWornCheckComplete					= { id, successful, code, value in DispatchQueue.main.async { self.wornCheckComplete?(id, successful, code, value) } }
						device.lambdaRawLoggingComplete					= { id, successful in DispatchQueue.main.async { self.rawLoggingComplete?(id, successful) } }
						device.lambdaGetRawLoggingStatusComplete 			= { id, successful, enabled in DispatchQueue.main.async { self.getRawLoggingStatusComplete?(id, successful, enabled) } }
						device.lambdaGetWornOverrideStatusComplete 		= { id, successful, overridden in DispatchQueue.main.async { self.getWornOverrideStatusComplete?(id, successful, overridden) } }
						device.lambdaAirplaneModeComplete					= { id, successful in DispatchQueue.main.async { self.airplaneModeComplete?(id, successful) } }
						device.lambdaResetComplete						= { id, successful in DispatchQueue.main.async { self.resetComplete?(id, successful) } }
						device.lambdaDisableWornDetectComplete			= { id, successful in DispatchQueue.main.async { self.disableWornDetectComplete?(id, successful) } }
						device.lambdaEnableWornDetectComplete				= { id, successful in DispatchQueue.main.async { self.enableWornDetectComplete?(id, successful) } }
						device.lambdaPPGMetrics     						= { id, successful, packet in DispatchQueue.main.async { self.ppgMetrics?(id, successful, packet) } }
						device.lambdaPPGFailed							= { id, code in DispatchQueue.main.async { self.ppgFailed?(id, code) } }
						
						device.lambdaDataPackets							= { [self] id, sequence_number, packets in
							if (dataPacketsOnBackgroundThread) { dataPackets?(id, sequence_number, packets) }
							else { DispatchQueue.main.async { self.dataPackets?(id, sequence_number, packets) }
							}
						}
						
						device.lambdaStreamingPacket						= { id, packet in DispatchQueue.main.async { self.streamingPacket?(id, packet) } }
						device.lambdaDataAvailable						= { id in DispatchQueue.main.async { self.dataAvailable?(id) }}
						device.lambdaDataComplete							= { id, bad_fw_read_count, bad_fw_packet_count, overflow_count, bad_sdk_parse_count, intermediate in DispatchQueue.main.async { self.dataComplete?(id, bad_fw_read_count, bad_fw_packet_count, overflow_count, bad_sdk_parse_count, intermediate) } }
						device.lambdaDataFailure							= { id in DispatchQueue.main.async { self.dataFailure?(id) } }
						device.lambdaWornStatus						= { id, isWorn in DispatchQueue.main.async { self.deviceWornStatus?(id, isWorn) } }
						device.lambdaUpdateFirmwareFailed					= { id, code, message in DispatchQueue.main.async { self.updateFirmwareFailed?(id, code, message) } }
						device.lambdaUpdateFirmwareFinished				= { id in DispatchQueue.main.async { self.updateFirmwareFinished?(id) } }
						device.lambdaUpdateFirmwareStarted				= { id in DispatchQueue.main.async { self.updateFirmwareStarted?(id) } }
						device.lambdaUpdateFirmwareProgress				= { id, percentage in DispatchQueue.main.async { self.updateFirmwareProgress?(id, percentage) } }
						device.lambdaSetSessionParamComplete				= { id, successful, parameter in DispatchQueue.main.async { self.setSessionParamComplete?(id, successful, parameter) } }
						device.lambdaGetSessionParamComplete				= { id, successful, parameter, value in DispatchQueue.main.async { self.getSessionParamComplete?(id, successful, parameter, value) } }
						device.lambdaResetSessionParamsComplete			= { id, successful in DispatchQueue.main.async { self.resetSessionParamsComplete?(id, successful) } }
						device.lambdaAcceptSessionParamsComplete			= { id, successful in DispatchQueue.main.async { self.acceptSessionParamsComplete?(id, successful) } }
						device.lambdaManufacturingTestComplete			= { id, successful in DispatchQueue.main.async { self.manufacturingTestComplete?(id, successful) } }
						device.lambdaManufacturingTestResult				= { id, valid, result in DispatchQueue.main.async { self.manufacturingTestResult?(id, valid, result) } }
						device.lambdaStartLiveSyncComplete				= { id, successful in DispatchQueue.main.async { self.startLiveSyncComplete?(id, successful) } }
						device.lambdaStopLiveSyncComplete					= { id, successful in DispatchQueue.main.async { self.stopLiveSyncComplete?(id, successful) } }
						device.lambdaRecalibratePPGComplete				= { id, successful in DispatchQueue.main.async { self.recalibratePPGComplete?(id, successful) } }
						device.lambdaChargingStatus					= { id, charging, on_charger, error in DispatchQueue.main.async { self.deviceChargingStatus?(id, charging, on_charger, error) } }
						device.lambdaSetHRZoneColorComplete				= { id, successful, type in DispatchQueue.main.async { self.setHRZoneColorComplete?(id, successful, type) } }
						device.lambdaGetHRZoneColorComplete				= { id, successful, type, red, green, blue, on_ms, off_ms in DispatchQueue.main.async { self.getHRZoneColorComplete?(id, successful, type, red, green, blue, on_ms, off_ms) } }
						device.lambdaSetHRZoneRangeComplete				= { id, successful in DispatchQueue.main.async { self.setHRZoneRangeComplete?(id, successful) } }
						device.lambdaGetHRZoneRangeComplete				= { id, successful, enabled, high_value, low_value in DispatchQueue.main.async { self.getHRZoneRangeComplete?(id, successful, enabled, high_value, low_value) } }
						device.lambdaGetPPGAlgorithmComplete				= { id, successful, algorithm, state in DispatchQueue.main.async { self.getPPGAlgorithmComplete?(id, successful, algorithm, state) } }
						device.lambdaSetAdvertiseAsHRMComplete			= { id, successful, asHRM in DispatchQueue.main.async { self.setAdvertiseAsHRMComplete?(id, successful, asHRM) } }
						device.lambdaGetAdvertiseAsHRMComplete			= { id, successful, asHRM in DispatchQueue.main.async { self.getAdvertiseAsHRMComplete?(id, successful, asHRM) } }
						device.lambdaSetButtonCommandComplete				= { id, successful, tap, command in DispatchQueue.main.async { self.setButtonCommandComplete?(id, successful, tap, command) } }
						device.lambdaGetButtonCommandComplete				= { id, successful, tap, command in DispatchQueue.main.async { self.getButtonCommandComplete?(id, successful, tap, command) } }
						device.lambdaSetPairedComplete					= { id, successful in DispatchQueue.main.async { self.setPairedComplete?(id, successful) } }
						device.lambdaSetUnpairedComplete					= { id, successful in DispatchQueue.main.async { self.setUnpairedComplete?(id, successful) } }
						device.lambdaGetPairedComplete					= { id, successful, paired in DispatchQueue.main.async { self.getPairedComplete?(id, successful, paired) } }
						device.lambdaSetPageThresholdComplete				= { id, successful in DispatchQueue.main.async { self.setPageThresholdComplete?(id, successful) } }
						device.lambdaGetPageThresholdComplete				= { id, successful, threshold in DispatchQueue.main.async { self.getPageThresholdComplete?(id, successful, threshold) } }
						device.lambdaDeletePageThresholdComplete			= { id, successful in DispatchQueue.main.async { self.deletePageThresholdComplete?(id, successful) } }
						device.lambdaSetAskForButtonResponseComplete		= { id, successful, enable in DispatchQueue.main.async { self.setAskForButtonResponseComplete?(id, successful, enable) } }
						device.lambdaGetAskForButtonResponseComplete		= { id, successful, enable in DispatchQueue.main.async { self.getAskForButtonResponseComplete?(id, successful, enable) } }
						device.lambdaEndSleepStatus 						= { id, hasSleep in DispatchQueue.main.async { self.endSleepStatus?(id, hasSleep) } }
						device.lambdaButtonClicked 						= { id, presses in DispatchQueue.main.async { self.buttonClicked?(id, presses) } }
						
						if valid {
							self.mDiscoveredDevices[peripheral.prettyID] = device
							discovered?(peripheral.prettyID, device)
						}
						else {
							if valid_type_but_no_name { self.discoveredUnnamed?(peripheral.prettyID, device) }
						}
					}
				}
#endif
				
#if UNIVERSAL || LIVOTAL
				if (thisUUID == Device.services.livotal.UUID) {
					
					if let device = self.mDiscoveredDevices[peripheral.prettyID] {
						if valid { discovered?(peripheral.prettyID, device) }
						else {
							if valid_type_but_no_name { self.discoveredUnnamed?(peripheral.prettyID, device) }
						}
					}
					else {
						
#if UNIVERSAL
						let device = Device(deviceName, id: peripheral.prettyID, peripheral: peripheral, type: .livotal, discoveryType: discovery_type)
#else
						let device = Device(deviceName, id: peripheral.prettyID, peripheral: peripheral, discoveryType: discovery_type)
#endif
						
						device.epoch					= Date().timeIntervalSince1970
						
						device.lambdaBatteryLevelUpdated					= { id, percentage in DispatchQueue.main.async { self.batteryLevel?(id, percentage) } }
						device.lambdaWriteEpochComplete = { id, successful in DispatchQueue.main.async { self.writeEpochComplete?(id, successful) } }
						device.lambdaReadEpochComplete = { id, successful, value in DispatchQueue.main.async { self.readEpochComplete?(id, successful, value) } }
						device.lambdaEndSleepComplete						= { id, successful in DispatchQueue.main.async { self.endSleepComplete?(id, successful) } }
						device.lambdaGetAllPacketsComplete				= { id, successful in DispatchQueue.main.async { self.getAllPacketsComplete?(id, successful) } }
						device.lambdaGetAllPacketsAcknowledgeComplete		= { id, successful, ack in DispatchQueue.main.async { self.getAllPacketsAcknowledgeComplete?(id, successful, ack) } }
						device.lambdaGetNextPacketComplete				= { id, successful, error_code, caughtUp, packet in DispatchQueue.main.async { self.getNextPacketComplete?(id, successful, error_code, caughtUp, packet) } }
						device.lambdaGetPacketCountComplete				= { id, successful, count in DispatchQueue.main.async { self.getPacketCountComplete?(id, successful, count) } }
						device.lambdaStartManualComplete					= { id, successful in DispatchQueue.main.async { self.startManualComplete?(id, successful) } }
						device.lambdaStopManualComplete					= { id, successful in DispatchQueue.main.async { self.stopManualComplete?(id, successful) } }
						device.lambdaLEDComplete							= { id, successful in DispatchQueue.main.async { self.ledComplete?(id, successful) } }
						device.lambdaEnterShipModeComplete				= { id, successful in DispatchQueue.main.async { self.enterShipModeComplete?(id, successful) } }
						device.lamdaWriteSerialNumberComplete			= { id, successful in DispatchQueue.main.async { self.writeSerialNumberComplete?(id, successful) } }
						device.lambdaReadSerialNumberComplete				= { id, successful, partID in DispatchQueue.main.async { self.readSerialNumberComplete?(id, successful, partID) } }
						device.lambdaDeleteSerialNumberComplete			= { id, successful in DispatchQueue.main.async { self.deleteSerialNumberComplete?(id, successful) } }
						device.lambdaWriteAdvIntervalComplete				= { id, successful in DispatchQueue.main.async { self.writeAdvIntervalComplete?(id, successful) } }
						device.lambdaReadAdvIntervalComplete				= { id, successful, seconds in DispatchQueue.main.async { self.readAdvIntervalComplete?(id, successful, seconds) } }
						device.lambdaDeleteAdvIntervalComplete 			= { id, successful in DispatchQueue.main.async { self.deleteAdvIntervalComplete?(id, successful) } }
						device.lambdaClearChargeCyclesComplete			= { id, successful in DispatchQueue.main.async { self.clearChargeCyclesComplete?(id, successful) } }
						device.lambdaReadChargeCyclesComplete				= { id, successful, cycles in DispatchQueue.main.async { self.readChargeCyclesComplete?(id, successful, cycles) } }
						device.lambdaReadCanLogDiagnosticsComplete 		= { id, successful, allow in DispatchQueue.main.async { self.readCanLogDiagnosticsComplete?(id, successful, allow) } }
						device.lambdaUpdateCanLogDiagnosticsComplete 		= { id, successful in DispatchQueue.main.async { self.updateCanLogDiagnosticsComplete?(id, successful) } }
						device.lambdaAllowPPGComplete						= { id, successful in DispatchQueue.main.async { self.allowPPGComplete?(id, successful) } }
						device.lambdaWornCheckComplete					= { id, successful, code, value in DispatchQueue.main.async { self.wornCheckComplete?(id, successful, code, value) } }
						device.lambdaRawLoggingComplete					= { id, successful in DispatchQueue.main.async { self.rawLoggingComplete?(id, successful) } }
						device.lambdaGetRawLoggingStatusComplete 			= { id, successful, enabled in DispatchQueue.main.async { self.getRawLoggingStatusComplete?(id, successful, enabled) } }
						device.lambdaGetWornOverrideStatusComplete 		= { id, successful, overridden in DispatchQueue.main.async { self.getWornOverrideStatusComplete?(id, successful, overridden) } }
						device.lambdaResetComplete						= { id, successful in DispatchQueue.main.async { self.resetComplete?(id, successful) } }
						device.lambdaDisableWornDetectComplete			= { id, successful in DispatchQueue.main.async { self.disableWornDetectComplete?(id, successful) } }
						device.lambdaEnableWornDetectComplete				= { id, successful in DispatchQueue.main.async { self.enableWornDetectComplete?(id, successful) } }
						device.lambdaPPGMetrics     						= { id, successful, packet in DispatchQueue.main.async { self.ppgMetrics?(id, successful, packet) } }
						device.lambdaPPGFailed							= { id, code in DispatchQueue.main.async { self.ppgFailed?(id, code) } }
						
						device.lambdaDataPackets							= { id, sequence_number, packets in
							if (self.dataPacketsOnBackgroundThread) { self.dataPackets?(id, sequence_number, packets) }
							else { DispatchQueue.main.async { self.dataPackets?(id, sequence_number, packets) }
							}
						}
						device.lambdaStreamingPacket						= { id, packet in DispatchQueue.main.async { self.streamingPacket?(id, packet) } }
						device.lambdaDataComplete							= { id, bad_fw_read_count, bad_fw_packet_count, overflow_count, bad_sdk_parse_count, intermediate in DispatchQueue.main.async { self.dataComplete?(id, bad_fw_read_count, bad_fw_packet_count, overflow_count, bad_sdk_parse_count, intermediate) } }
						device.lambdaDataFailure							= { id in DispatchQueue.main.async { self.dataFailure?(id) } }
						device.lambdaWornStatus						= { id, isWorn in DispatchQueue.main.async { self.deviceWornStatus?(id, isWorn) } }
						device.lambdaUpdateFirmwareFailed					= { id, code, message in DispatchQueue.main.async { self.updateFirmwareFailed?(id, code, message) } }
						device.lambdaUpdateFirmwareFinished				= { id in DispatchQueue.main.async { self.updateFirmwareFinished?(id) } }
						device.lambdaUpdateFirmwareStarted				= { id in DispatchQueue.main.async { self.updateFirmwareStarted?(id) } }
						device.lambdaUpdateFirmwareProgress				= { id, percentage in DispatchQueue.main.async { self.updateFirmwareProgress?(id, percentage) } }
						device.lambdaSetSessionParamComplete				= { id, successful, parameter in DispatchQueue.main.async { self.setSessionParamComplete?(id, successful, parameter) } }
						device.lambdaGetSessionParamComplete				= { id, successful, parameter, value in DispatchQueue.main.async { self.getSessionParamComplete?(id, successful, parameter, value) } }
						device.lambdaResetSessionParamsComplete			= { id, successful in DispatchQueue.main.async { self.resetSessionParamsComplete?(id, successful) } }
						device.lambdaAcceptSessionParamsComplete			= { id, successful in DispatchQueue.main.async { self.acceptSessionParamsComplete?(id, successful) } }
						device.lambdaManufacturingTestComplete			= { id, successful in DispatchQueue.main.async { self.manufacturingTestComplete?(id, successful) } }
						device.lambdaManufacturingTestResult				= { id, valid, result in DispatchQueue.main.async { self.manufacturingTestResult?(id, valid, result) } }
						device.lambdaRecalibratePPGComplete				= { id, successful in DispatchQueue.main.async { self.recalibratePPGComplete?(id, successful) } }
						device.lambdaChargingStatus					= { id, charging, on_charger, error in DispatchQueue.main.async { self.deviceChargingStatus?(id, charging, on_charger, error) } }
												
						if valid {
							self.mDiscoveredDevices[peripheral.prettyID] = device
							discovered?(peripheral.prettyID, device)
						}
						else {
							if valid_type_but_no_name { self.discoveredUnnamed?(peripheral.prettyID, device) }
						}
					}
				}
				
				if (thisUUID == Device.services.nordicDFU.UUID) {
					//log?.v("\(peripheral.prettyID): didDiscover: \(deviceName) -> DFU mode!")
					
					if (deviceName == gblDFUName) {
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
		
		DispatchQueue.main.async { [self] in
			if let device = mDiscoveredDevices[peripheral.prettyID] {
				if (device.connecting) {
					if let devicePeripheral = device.peripheral {
						if (peripheral == devicePeripheral) {
							devicePeripheral.delegate = self
							device.peripheral	= devicePeripheral
							device.epoch		= Date().timeIntervalSince1970
							device.configuring	= true
							mDiscoveredDevices.removeValue(forKey: peripheral.prettyID)
							mConnectedDevices[peripheral.prettyID] = device
							devicePeripheral.discoverServices(nil)
						}
						else {
							log?.e ("\(peripheral.prettyID): didConnect - Connected to a devcie that is in my list, exists, but isn't the same?  Weird!  Disconnect")
							mCentralManager?.cancelPeripheralConnection(peripheral)
						}
					}
					else {
						log?.e ("\(peripheral.prettyID): didConnect - Connected to a device that is in my list, but is not valid.  Weird!  Disconnect")
						mCentralManager?.cancelPeripheralConnection(peripheral)
					}
				}
				else {
					log?.e ("\(peripheral.prettyID): didConnect - Connected to a device that isn't requesting connection.  Weird!  Disconnect")
					mCentralManager?.cancelPeripheralConnection(peripheral)
				}
			}
			else {
				log?.e ("\(peripheral.prettyID): didConnect - Connected to a device not in my discovered list.  Disconnect")
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
			if let device = self.mDiscoveredDevices[id] {
				if (device.connecting) {
					self.mDiscoveredDevices.removeValue(forKey: id)
				}
				else {
					log?.e ("\(id): Disconnected from a discovered device that isn't requesting connection.  Weird!")
				}
				
				self.disconnected?(id)
				return
			}

			if let device = self.mConnectedDevices[id] {
				if (device.configuring || device.connected) {
					self.mConnectedDevices.removeValue(forKey: id)
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

