//
//  Device.swift
//  biostrapDeviceSDK
//
//  Created by Joseph A. Bennett on 3/31/21.
//

import Foundation
import CoreBluetooth

public class Device: NSObject {
	
	
	enum services: String {
		#if UNIVERSAL || ETHOS
		case ethosService			= "B30E0F19-A021-45F3-8661-4255CBD49E10"
		case ambiqOTAService		= "00002760-08C2-11E1-9073-0E8AC72E1001"
		#endif
		
		#if UNIVERSAL || LIVOTAL
		case livotalService			= "58950000-A53F-11EB-BCBC-0242AC130002"
		case nordicDFUService		= "FE59"
		#endif

		var UUID: CBUUID {
			return CBUUID(string: self.rawValue)
		}
		
		var title: String {
			switch (self) {
			#if UNIVERSAL || ETHOS
			case .ethosService		: return "Ethos Service"
			case .ambiqOTAService	: return "Ambiq OTA Service"
			#endif

			#if UNIVERSAL || LIVOTAL
			case .livotalService	: return "Livotal Service"
			case .nordicDFUService	: return "Nordic DFU Service"
			#endif
			}
		}
	}

	enum characteristics: String {
		#if UNIVERSAL || ETHOS
		case ethosCharacteristic		= "B30E0F19-A021-45F3-8661-4255CBD49E11"
		case ambiqOTARXCharacteristic	= "00002760-08C2-11E1-9073-0E8AC72E0001"
		case ambiqOTATXCharacteristic	= "00002760-08C2-11E1-9073-0E8AC72E0002"
		#endif

		#if UNIVERSAL || LIVOTAL
		case livotalCharacteristic		= "58950001-A53F-11EB-BCBC-0242AC130002"
		case nordicDFUCharacteristic	= "8EC90003-F315-4F60-9FB8-838830DAEA50"
		#endif

		var UUID: CBUUID {
			return CBUUID(string: self.rawValue)
		}
		
		var title: String {
			switch (self) {
			#if UNIVERSAL || ETHOS
			case .ethosCharacteristic		: return "Ethos Characteristic"
			case .ambiqOTARXCharacteristic	: return "Ambiq OTA RX Characteristic"
			case .ambiqOTATXCharacteristic	: return "Ambiq OTA TX Characteristic"
			#endif

			#if UNIVERSAL || LIVOTAL
			case .livotalCharacteristic		: return "Livotal Characteristic"
			case .nordicDFUCharacteristic	: return "Nordic DFU Characteristic"
			#endif
			}
		}
	}

	internal enum ConnectionState {
		case disconnected
		case connecting
		case configuring
		case connected
	}
	
	internal var mState		: ConnectionState!
	#if UNIVERSAL
	var type				: biostrapDeviceSDK.biostrapDeviceType
	#endif
	
	var peripheral			: CBPeripheral?
	@objc public var name	: String
	internal var mID		: String
	
	// MARK: Callbacks
	var batteryLevelUpdated: ((_ id: String, _ percentage: Int)->())?

	var writeEpochComplete: ((_ id: String, _ successful: Bool)->())?
	var getAllPacketsComplete: ((_ id: String, _ successful: Bool)->())?
	var getNextPacketComplete: ((_ id: String, _ successful: Bool, _ packet: String)->())?
	var getPacketCountComplete: ((_ id: String, _ successful: Bool, _ count: Int)->())?
	var startManualComplete: ((_ id: String, _ successful: Bool)->())?
	var stopManualComplete: ((_ id: String, _ successful: Bool)->())?
	var blinkLEDComplete: ((_ id: String, _ successful: Bool)->())?
	var enterShipModeComplete: ((_ id: String, _ successful: Bool)->())?
	var writeIDComplete: ((_ id: String, _ successful: Bool)->())?
	var readIDComplete: ((_ id: String, _ successful: Bool, _ partID: String)->())?
	var deleteIDComplete: ((_ id: String, _ successful: Bool)->())?
	var writeAdvIntervalComplete: ((_ id: String, _ successful: Bool)->())?
	var readAdvIntervalComplete: ((_ id: String, _ successful: Bool, _ seconds: Int)->())?
	var deleteAdvIntervalComplete: ((_ id: String, _ successful: Bool)->())?
	var clearChargeCyclesComplete: ((_ id: String, _ successful: Bool)->())?
	var readChargeCyclesComplete: ((_ id: String, _ successful: Bool, _ cycles: Float)->())?
	var wornCheckComplete: ((_ id: String, _ successful: Bool, _ code: String, _ value: Int)->())?
	var rawLoggingComplete: ((_ id: String, _ successful: Bool)->())?
	var resetComplete: ((_ id: String, _ successful: Bool)->())?
	var readEpochComplete: ((_ id: String, _ successful: Bool, _ value: Int)->())?
	var setLEDComplete: ((_ id: String, _ successful: Bool)->())?
    var manualResult: ((_ id: String, _ successful: Bool, _ packet: String)->())?
	var ppgBroken: ((_ id: String)->())?
	var disableWornDetectComplete: ((_ id: String, _ successful: Bool)->())?
	var enableWornDetectComplete: ((_ id: String, _ successful: Bool)->())?

	var dataPackets: ((_ id: String, _ packets: String)->())?
	var dataComplete: ((_ id: String)->())?
	
	var deviceWornStatus: ((_ id: String, _ isWorn: Bool)->())?

	var updateFirmwareStarted: ((_ id: String)->())?
	var updateFirmwareFinished: ((_ id: String)->())?
	var updateFirmwareProgress: ((_ id: String, _ percentage: Float)->())?
	var updateFirmwareFailed: ((_ id: String, _ code: Int, _ message: String)->())?

	@objc public var batteryLevel	: Int = 0
	@objc public var wornStatus		: String = "Not worn"

	@objc public var modelNumber : String {
		if let modelNumber = mModelNumber { return modelNumber.value }
		else { return ("???") }
	}

	@objc public var firmwareRevision : String {
		if let firmwareRevision = mFirmwareVersion { return firmwareRevision.value }
		else { return ("???") }
	}

	@objc public var hardwareRevision : String {
		if let hardwareRevision = mHardwareRevision { return hardwareRevision.value }
		else { return ("???") }
	}

	@objc public var manufacturerName : String {
		if let manufacturerName = mManufacturerName { return manufacturerName.value }
		else { return ("???") }
	}

	internal var mModelNumber					: disStringCharacteristic?
	internal var mFirmwareVersion				: disStringCharacteristic?
	internal var mHardwareRevision				: disStringCharacteristic?
	internal var mManufacturerName				: disStringCharacteristic?
	
	internal var mBatteryLevelCharacteristic	: batteryLevelCharacteristic?
	internal var mCustomCharacteristic			: customCharacteristic?
	#if UNIVERSAL || LIVOTAL
	internal var mNordicDFUCharacteristic		: nordicDFUCharacteristic?
	#endif

	#if UNIVERSAL || ETHOS
	internal var mEthosOTARXCharacteristic		: ethosOTARXCharacteristic?
	internal var mEthosOTATXCharacteristic		: ethosOTATXCharacteristic?
	#endif
	
	class var scan_services: [CBUUID] {
		#if UNIVERSAL
		if (gblLimitLivotal) {
			return [services.livotalService.UUID, services.nordicDFUService.UUID]
		}
		else {
			return [services.livotalService.UUID, services.nordicDFUService.UUID, services.ethosService.UUID]
		}
		#elseif LIVOTAL
		return [services.livotalService.UUID, services.nordicDFUService.UUID]
		#elseif ETHOS
		return [services.ethosService.UUID]
		#else
		return []
		#endif
	}
	
	class func hit(_ service: CBService) -> Bool {
		if let standardService = org_bluetooth_service(rawValue: service.prettyID) {
			log?.v ("\(gblReturnID(service.peripheral)): '\(standardService.title)'")
			switch standardService {
			case .device_information: return (true)
			case .battery_service: return (true)
			default:
				log?.e ("\(gblReturnID(service.peripheral)): (unknown): '\(standardService.title)'")
				return (false)
			}
		}
		else if let customService = Device.services(rawValue: service.prettyID) {
			log?.v ("\(gblReturnID(service.peripheral)): '\(customService.title)'")
			return (true)
		}
		else {
			log?.e ("\(gblReturnID(service.peripheral)): \(service.prettyID) - don't know what to do!!!!")
			return (false)
		}
	}

	override init() {
		self.mState						= .disconnected
		
		self.name						= "UNKNOWN"
		self.mID						= "UNKNOWN"
		
		#if UNIVERSAL
		self.type						= .unknown
		#endif
	}

	#if UNIVERSAL
	convenience init(_ name: String, id: String, peripheral: CBPeripheral?, type: biostrapDeviceSDK.biostrapDeviceType) {
		self.init()
		
		self.name		= name
		self.mID		= id
		self.peripheral	= peripheral
		self.type		= type
	}
	#endif

	convenience init(_ name: String, id: String, peripheral: CBPeripheral?) {
		self.init()
		
		self.name		= name
		self.mID		= id
		self.peripheral	= peripheral
	}

	var disconnected: Bool {
		get { return (mState == .disconnected) }
		set { if (newValue) { mState = .disconnected } }
	}
	
	var connecting: Bool {
		get { return (mState == .connecting) }
		set { if (newValue) { mState = .connecting } }
	}

	var configuring: Bool {
		get { return (mState == .configuring) }
		set { if (newValue) { mState = .configuring } }
	}

	var connected: Bool {
		get { return (mState == .connected) }
		set { if (newValue) { mState = .connected } }
	}
	
	var configured: Bool {
		#if UNIVERSAL
		switch type {
		case .livotal:
			if let modelNumber = mModelNumber, let hardwareRevision = mHardwareRevision, let firmwareVersion = mFirmwareVersion, let manufacturerName = mManufacturerName, let nordicDFUCharacteristic = mNordicDFUCharacteristic, let customCharacteristic = mCustomCharacteristic, let batteryCharacteristic = mBatteryLevelCharacteristic {
				
				//log?.v ("MN: \(modelNumber.configured), HV: \(hardwareRevision.configured), FV: \(firmwareVersion.configured), Name: \(manufacturerName.configured), LIV: \(customCharacteristic.configured), BAT: \(batteryCharacteristic.configured), DFU: \(dfuCharacteristic.configured)")

				return (modelNumber.configured &&
						hardwareRevision.configured &&
						firmwareVersion.configured &&
						manufacturerName.configured &&
						batteryCharacteristic.configured &&
						customCharacteristic.configured &&
						nordicDFUCharacteristic.configured)
			}
			else {
				return (false)
			}
		case .ethos:
			if let modelNumber = mModelNumber, let hardwareRevision = mHardwareRevision, let firmwareVersion = mFirmwareVersion, let manufacturerName = mManufacturerName, let ethosOTARXCharacteristic = mEthosOTARXCharacteristic, let ethosOTATXCharacteristic = mEthosOTATXCharacteristic, let customCharacteristic = mCustomCharacteristic, let batteryCharacteristic = mBatteryLevelCharacteristic {
				
				//log?.v ("MN: \(modelNumber.configured), HV: \(hardwareRevision.configured), FV: \(firmwareVersion.configured), Name: \(manufacturerName.configured), ETH: \(customCharacteristic.configured), BAT: \(batteryCharacteristic.configured), OTARX: \(ethosOTARXCharacteristic.configured), OTATX: \(ethosOTATXCharacteristic.configured)")

				return (modelNumber.configured &&
						hardwareRevision.configured &&
						firmwareVersion.configured &&
						manufacturerName.configured &&
						batteryCharacteristic.configured &&
						customCharacteristic.configured &&
						ethosOTARXCharacteristic.configured &&
						ethosOTATXCharacteristic.configured
				)
			}
			else {
				return (false)
			}
			
		case .alter: return false
		case .unknown: return false
		}
		#elseif LIVOTAL
		if let modelNumber = mModelNumber, let hardwareRevision = mHardwareRevision, let firmwareVersion = mFirmwareVersion, let manufacturerName = mManufacturerName, let nordicDFUCharacteristic = mNordicDFUCharacteristic, let customCharacteristic = mCustomCharacteristic, let batteryCharacteristic = mBatteryLevelCharacteristic {
			
			//log?.v ("MN: \(modelNumber.configured), HV: \(hardwareRevision.configured), FV: \(firmwareVersion.configured), Name: \(manufacturerName.configured), LIV: \(customCharacteristic.configured), BAT: \(batteryCharacteristic.configured), DFU: \(dfuCharacteristic.configured)")

			return (modelNumber.configured &&
					hardwareRevision.configured &&
					firmwareVersion.configured &&
					manufacturerName.configured &&
					batteryCharacteristic.configured &&
					customCharacteristic.configured &&
					nordicDFUCharacteristic.configured)
		}
		else {
			return (false)
		}
		#elseif ETHOS
		if let modelNumber = mModelNumber, let hardwareRevision = mHardwareRevision, let firmwareVersion = mFirmwareVersion, let manufacturerName = mManufacturerName, let ethosOTARXCharacteristic = mEthosOTARXCharacteristic, let ethosOTATXCharacteristic = mEthosOTATXCharacteristic, let customCharacteristic = mCustomCharacteristic, let batteryCharacteristic = mBatteryLevelCharacteristic {
			
			log?.v ("MN: \(modelNumber.configured), HV: \(hardwareRevision.configured), FV: \(firmwareVersion.configured), Name: \(manufacturerName.configured), ETH: \(customCharacteristic.configured), BAT: \(batteryCharacteristic.configured), OTARX: \(ethosOTARXCharacteristic.configured), OTATX: \(ethosOTATXCharacteristic.configured)")

			return (modelNumber.configured &&
					hardwareRevision.configured &&
					firmwareVersion.configured &&
					manufacturerName.configured &&
					batteryCharacteristic.configured &&
					customCharacteristic.configured &&
					ethosOTARXCharacteristic.configured &&
					ethosOTATXCharacteristic.configured
			)
		}
		else {
			return (false)
		}
		
		#elseif ALTER
		return (false)
		
		#else
		return (false)
		#endif
	}
	
	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	internal func mGetStringFromCharacteristic (_ characteristic: CBCharacteristic) -> String {
		if let value = characteristic.value {
			let valueString = String(decoding: value, as: UTF8.self)
			return valueString
		}
		else {
			log?.e ("Cannot get value from string for \(characteristic.prettyID)")
			return ("")
		}
	}
	
	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func writeEpoch(_ id: String, newEpoch: Int) {
		if let customCharacteristic = mCustomCharacteristic {
			customCharacteristic.writeEpoch(newEpoch)
		}
		else { self.writeEpochComplete?(id, false) }
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func readEpoch(_ id: String) {
		if let customCharacteristic = mCustomCharacteristic {
			customCharacteristic.readEpoch()
		}
		else { self.readEpochComplete?(id, false, 0) }
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func getAllPackets(_ id: String) {
		if let customCharacteristic = mCustomCharacteristic {
			customCharacteristic.getAllPackets()
		}
		else { self.getAllPacketsComplete?(id, false) }
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func getNextPacket(_ id: String) {
		if let customCharacteristic = mCustomCharacteristic {
			customCharacteristic.getNextPacket()
		}
		else { self.getNextPacketComplete?(id, false, "") }
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func getPacketCount(_ id: String) {
		if let customCharacteristic = mCustomCharacteristic {
			customCharacteristic.getPacketCount()
		}
		else { self.getPacketCountComplete?(id, false, 0) }
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func disableWornDetect(_ id: String) {
		if let customCharacteristic = mCustomCharacteristic {
			customCharacteristic.disableWornDetect()
		}
		else { self.disableWornDetectComplete?(id, false) }
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func enableWornDetect(_ id: String) {
		if let customCharacteristic = mCustomCharacteristic {
			customCharacteristic.enableWornDetect()
		}
		else { self.enableWornDetectComplete?(id, false) }
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func startManual(_ id: String, leds: livotalLEDConfiguration, algorithms: livotalAlgorithmConfiguration) {
		if let customCharacteristic = mCustomCharacteristic {
			customCharacteristic.startManual(leds: leds, algorithms: algorithms)
		}
		else { self.startManualComplete?(id, false) }
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func stopManual(_ id: String) {
		if let customCharacteristic = mCustomCharacteristic {
			customCharacteristic.stopManual()
		}
		else { self.stopManualComplete?(id, false) }
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func blinkLED(_ id: String, red: Bool, green: Bool, blue: Bool, seconds: Int) {
		if let customCharacteristic = mCustomCharacteristic {
			customCharacteristic.blinkLED(red: red, green: green, blue: blue, seconds: seconds)
		}
		else { self.blinkLEDComplete?(id, false) }
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func setLED(_ id: String, red: Bool, green: Bool, blue: Bool) {
		if let customCharacteristic = mCustomCharacteristic {
			customCharacteristic.setLED(red: red, green: green, blue: blue)
		}
		else { self.setLEDComplete?(id, false) }
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func enterShipMode(_ id: String) {
		if let customCharacteristic = mCustomCharacteristic {
			customCharacteristic.enterShipMode()
		}
		else { self.enterShipModeComplete?(id, false) }
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func writeID(_ id: String, partID: String) {
		if let customCharacteristic = mCustomCharacteristic {
			customCharacteristic.writeID(partID)
		}
		else { self.writeIDComplete?(id, false) }
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func readID(_ id: String) {
		if let customCharacteristic = mCustomCharacteristic {
			customCharacteristic.readID()
		}
		else { self.readIDComplete?(id, false, "") }
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func deleteID(_ id: String) {
		if let customCharacteristic = mCustomCharacteristic {
			customCharacteristic.deleteID()
		}
		else { self.deleteIDComplete?(id, false) }
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func writeAdvInterval(_ id: String, seconds: Int) {
		if let customCharacteristic = mCustomCharacteristic {
			customCharacteristic.writeAdvInterval(seconds)
		}
		else { self.writeAdvIntervalComplete?(id, false) }
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func readAdvInterval(_ id: String) {
		if let customCharacteristic = mCustomCharacteristic {
			customCharacteristic.readAdvInterval()
		}
		else { self.readAdvIntervalComplete?(id, false, 0) }
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func deleteAdvInterval(_ id: String) {
		if let customCharacteristic = mCustomCharacteristic {
			customCharacteristic.deleteAdvInterval()
		}
		else { self.deleteAdvIntervalComplete?(id, false) }
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func clearChargeCycles(_ id: String) {
		if let customCharacteristic = mCustomCharacteristic {
			customCharacteristic.clearChargeCycles()
		}
		else { self.clearChargeCyclesComplete?(id, false) }
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func readChargeCycles(_ id: String) {
		if let customCharacteristic = mCustomCharacteristic {
			customCharacteristic.readChargeCycles()
		}
		else { self.readChargeCyclesComplete?(id, false, 0.0) }
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func wornCheck(_ id: String) {
		if let customCharacteristic = mCustomCharacteristic {
			customCharacteristic.wornCheck()
		}
		else { self.wornCheckComplete?(id, false, "Missing Characteristic", 0) }
	}


	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func rawLogging(_ id: String, enable: Bool) {
		if let customCharacteristic = mCustomCharacteristic {
			customCharacteristic.rawLogging(enable)
		}
		else { self.rawLoggingComplete?(id, false) }
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func reset(_ id: String) {
		if let customCharacteristic = mCustomCharacteristic {
			customCharacteristic.reset()
		}
		else { self.resetComplete?(id, false) }
	}
	
	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func updateFirmware(_ file: URL) {
		if let nordicDFUCharacteristic = mNordicDFUCharacteristic { nordicDFUCharacteristic.start(file) }
		else { updateFirmwareFailed?(mID, 10001, "No DFU characteristic to update") }
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func cancelFirmwareUpdate() {
		if let nordicDFUCharacteristic = mNordicDFUCharacteristic { nordicDFUCharacteristic.cancel() }
		else { updateFirmwareFailed?(mID, 10001, "No DFU characteristic to update") }
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func didDiscoverCharacteristic(_ characteristic: CBCharacteristic) {
		if let peripheral = peripheral {
			if let testCharacteristic = org_bluetooth_characteristic(rawValue: characteristic.prettyID) {
				switch (testCharacteristic) {
				case .model_number_string:
					mModelNumber = disStringCharacteristic(peripheral, characteristic: characteristic)
					mModelNumber?.read()
				case .hardware_revision_string:
					mHardwareRevision = disStringCharacteristic(peripheral, characteristic: characteristic)
					mHardwareRevision?.read()
				case .firmware_revision_string:
					mFirmwareVersion = disStringCharacteristic(peripheral, characteristic: characteristic)
					mFirmwareVersion?.read()
				case .manufacturer_name_string:
					mManufacturerName = disStringCharacteristic(peripheral, characteristic: characteristic)
					mManufacturerName?.read()
				case .battery_level:
					log?.v ("\(gblReturnID(peripheral)) '\(testCharacteristic.title)' - read it and enable notifications")
					mBatteryLevelCharacteristic	= batteryLevelCharacteristic(peripheral, characteristic: characteristic)
					mBatteryLevelCharacteristic?.updated	= { id, percentage in
						self.batteryLevel = percentage
						self.batteryLevelUpdated?(id, percentage)
					}
					mBatteryLevelCharacteristic?.read()
					mBatteryLevelCharacteristic?.discoverDescriptors()
				case .body_sensor_location:
					log?.v ("\(gblReturnID(peripheral)) '\(testCharacteristic.title)' - read it")
					peripheral.readValue(for: characteristic)
				default:
					log?.e ("\(gblReturnID(peripheral)) for service: \(characteristic.service.prettyID) - '\(testCharacteristic.title)' - do not know what to do")
				}
			}
			else if let testCharacteristic = Device.characteristics(rawValue: characteristic.prettyID) {
				switch (testCharacteristic) {

				#if UNIVERSAL || ETHOS
				case .ethosCharacteristic:
					mCustomCharacteristic	= customCharacteristic(peripheral, characteristic: characteristic)
					mCustomCharacteristic?.startManualComplete = { successful in self.startManualComplete?(self.mID, successful) }
					mCustomCharacteristic?.stopManualComplete = { successful in self.stopManualComplete?(self.mID, successful) }
					mCustomCharacteristic?.blinkLEDComplete = { successful in self.blinkLEDComplete?(self.mID, successful) }
					mCustomCharacteristic?.setLEDComplete = { successful in self.setLEDComplete?(self.mID, successful) }
					mCustomCharacteristic?.enterShipModeComplete = { successful in self.enterShipModeComplete?(self.mID, successful) }
					mCustomCharacteristic?.writeIDComplete = { successful in self.writeIDComplete?(self.mID, successful) }
					mCustomCharacteristic?.readIDComplete = { successful, partID in self.readIDComplete?(self.mID, successful, partID) }
					mCustomCharacteristic?.deleteIDComplete = { successful in self.deleteIDComplete?(self.mID, successful) }
					mCustomCharacteristic?.writeAdvIntervalComplete = { successful in self.writeAdvIntervalComplete?(self.mID, successful) }
					mCustomCharacteristic?.readAdvIntervalComplete = { successful, seconds in self.readAdvIntervalComplete?(self.mID, successful, seconds) }
					mCustomCharacteristic?.deleteAdvIntervalComplete = { successful in self.deleteAdvIntervalComplete?(self.mID, successful) }
					mCustomCharacteristic?.clearChargeCyclesComplete = { successful in self.clearChargeCyclesComplete?(self.mID, successful) }
					mCustomCharacteristic?.readChargeCyclesComplete = { successful, cycles in self.readChargeCyclesComplete?(self.mID, successful, cycles) }
					mCustomCharacteristic?.rawLoggingComplete = { successful in self.rawLoggingComplete?(self.mID, successful) }
					mCustomCharacteristic?.wornCheckComplete = { successful, code, value in self.wornCheckComplete?(self.mID, successful, code, value )}
					mCustomCharacteristic?.resetComplete = { successful in self.resetComplete?(self.mID, successful) }
					mCustomCharacteristic?.manualResult = { successful, packet in self.manualResult?(self.mID, successful, packet) }
					mCustomCharacteristic?.ppgBroken = { self.ppgBroken?(self.mID) }
					mCustomCharacteristic?.writeEpochComplete = { successful in self.writeEpochComplete?(self.mID, successful) }
					mCustomCharacteristic?.readEpochComplete = { successful, value in self.readEpochComplete?(self.mID, successful,  value) }
					mCustomCharacteristic?.getAllPacketsComplete = { successful in self.getAllPacketsComplete?(self.mID, successful) }
					mCustomCharacteristic?.getNextPacketComplete = { successful, packet in self.getNextPacketComplete?(self.mID, successful, packet) }
					mCustomCharacteristic?.getPacketCountComplete = { successful, count in self.getPacketCountComplete?(self.mID, successful, count) }
					mCustomCharacteristic?.disableWornDetectComplete = { successful in self.disableWornDetectComplete?(self.mID, successful) }
					mCustomCharacteristic?.enableWornDetectComplete = { successful in self.enableWornDetectComplete?(self.mID, successful) }
					mCustomCharacteristic?.dataPackets = { packets in self.dataPackets?(self.mID, packets) }
					mCustomCharacteristic?.dataComplete = { self.dataComplete?(self.mID) }
					mCustomCharacteristic?.deviceWornStatus = { isWorn in
						if (isWorn) { self.wornStatus = "Worn" }
						else { self.wornStatus = "Not Worn" }
						self.deviceWornStatus?(self.mID, isWorn)
					}
					mCustomCharacteristic?.discoverDescriptors()
					
				case .ambiqOTARXCharacteristic:
					log?.v ("\(gblReturnID(peripheral)) for service: \(characteristic.service.prettyID) - '\(testCharacteristic.title)'")
					
					mEthosOTARXCharacteristic = ethosOTARXCharacteristic(peripheral, characteristic: characteristic)
					
					mEthosOTARXCharacteristic?.started = { self.updateFirmwareStarted?(self.mID) }
					mEthosOTARXCharacteristic?.finished = { self.updateFirmwareFinished?(self.mID) }
					mEthosOTARXCharacteristic?.failed = { code, message in self.updateFirmwareFailed?(self.mID, code, message) }
					mEthosOTARXCharacteristic?.progress = { percent in self.updateFirmwareProgress?(self.mID, percent) }

					
				case .ambiqOTATXCharacteristic:
					log?.v ("\(gblReturnID(peripheral)) for service: \(characteristic.service.prettyID) - '\(testCharacteristic.title)'")
					
					mEthosOTATXCharacteristic = ethosOTATXCharacteristic(peripheral, characteristic: characteristic)
					mEthosOTATXCharacteristic?.discoverDescriptors()
					//peripheral.setNotifyValue(true, for: characteristic)
				#endif
				
				#if UNIVERSAL || LIVOTAL
				case .livotalCharacteristic:
					mCustomCharacteristic	= customCharacteristic(peripheral, characteristic: characteristic)
					mCustomCharacteristic?.startManualComplete = { successful in self.startManualComplete?(self.mID, successful) }
					mCustomCharacteristic?.stopManualComplete = { successful in self.stopManualComplete?(self.mID, successful) }
					mCustomCharacteristic?.blinkLEDComplete = { successful in self.blinkLEDComplete?(self.mID, successful) }
					mCustomCharacteristic?.setLEDComplete = { successful in self.setLEDComplete?(self.mID, successful) }
					mCustomCharacteristic?.enterShipModeComplete = { successful in self.enterShipModeComplete?(self.mID, successful) }
					mCustomCharacteristic?.writeIDComplete = { successful in self.writeIDComplete?(self.mID, successful) }
					mCustomCharacteristic?.readIDComplete = { successful, partID in self.readIDComplete?(self.mID, successful, partID) }
					mCustomCharacteristic?.deleteIDComplete = { successful in self.deleteIDComplete?(self.mID, successful) }
					mCustomCharacteristic?.writeAdvIntervalComplete = { successful in self.writeAdvIntervalComplete?(self.mID, successful) }
					mCustomCharacteristic?.readAdvIntervalComplete = { successful, seconds in self.readAdvIntervalComplete?(self.mID, successful, seconds) }
					mCustomCharacteristic?.deleteAdvIntervalComplete = { successful in self.deleteAdvIntervalComplete?(self.mID, successful) }
					mCustomCharacteristic?.clearChargeCyclesComplete = { successful in self.clearChargeCyclesComplete?(self.mID, successful) }
					mCustomCharacteristic?.readChargeCyclesComplete = { successful, cycles in self.readChargeCyclesComplete?(self.mID, successful, cycles) }
					mCustomCharacteristic?.rawLoggingComplete = { successful in self.rawLoggingComplete?(self.mID, successful) }
					mCustomCharacteristic?.wornCheckComplete = { successful, code, value in self.wornCheckComplete?(self.mID, successful, code, value )}
					mCustomCharacteristic?.resetComplete = { successful in self.resetComplete?(self.mID, successful) }
					mCustomCharacteristic?.manualResult = { successful, packet in self.manualResult?(self.mID, successful, packet) }
					mCustomCharacteristic?.ppgBroken = { self.ppgBroken?(self.mID) }
					mCustomCharacteristic?.writeEpochComplete = { successful in self.writeEpochComplete?(self.mID, successful) }
					mCustomCharacteristic?.readEpochComplete = { successful, value in self.readEpochComplete?(self.mID, successful,  value) }
					mCustomCharacteristic?.getAllPacketsComplete = { successful in self.getAllPacketsComplete?(self.mID, successful) }
					mCustomCharacteristic?.getNextPacketComplete = { successful, packet in self.getNextPacketComplete?(self.mID, successful, packet) }
					mCustomCharacteristic?.getPacketCountComplete = { successful, count in self.getPacketCountComplete?(self.mID, successful, count) }
					mCustomCharacteristic?.disableWornDetectComplete = { successful in self.disableWornDetectComplete?(self.mID, successful) }
					mCustomCharacteristic?.enableWornDetectComplete = { successful in self.enableWornDetectComplete?(self.mID, successful) }
					mCustomCharacteristic?.dataPackets = { packets in self.dataPackets?(self.mID, packets) }
					mCustomCharacteristic?.dataComplete = { self.dataComplete?(self.mID) }
					mCustomCharacteristic?.deviceWornStatus = { isWorn in
						if (isWorn) { self.wornStatus = "Worn" }
						else { self.wornStatus = "Not Worn" }
						self.deviceWornStatus?(self.mID, isWorn)
					}
					mCustomCharacteristic?.discoverDescriptors()
				
				case .nordicDFUCharacteristic:
					if let name = peripheral.name {
						mNordicDFUCharacteristic	= nordicDFUCharacteristic(peripheral, characteristic: characteristic, name: name)
					}
					else {
						mNordicDFUCharacteristic	= nordicDFUCharacteristic(peripheral, characteristic: characteristic)
					}
					mNordicDFUCharacteristic?.failed = { id, code, message in self.updateFirmwareFailed?(id, code, message) }
					mNordicDFUCharacteristic?.discoverDescriptors()
				#endif

				}
			}
			else {
				log?.e ("\(gblReturnID(peripheral)) for service: \(characteristic.service.prettyID) - \(characteristic.prettyID) - UNKNOWN")
			}
		}
		else {
			log?.e ("Peripheral object is nil - do nothing")
		}
	}
	
	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func didDiscoverDescriptor (_ descriptor: CBDescriptor, forCharacteristic characteristic: CBCharacteristic) {
		if let peripheral = peripheral {
			if let standardDescriptor = org_bluetooth_descriptor(rawValue: descriptor.prettyID) {
				switch (standardDescriptor) {
				case .client_characteristic_configuration:
					if let enumerated = Device.characteristics(rawValue: characteristic.prettyID) {
						log?.v ("\(gblReturnID(peripheral)): \(standardDescriptor.title) '\(enumerated.title)'")
						switch (enumerated) {
						#if UNIVERSAL || ETHOS
						case .ethosCharacteristic		: mCustomCharacteristic?.didDiscoverDescriptor()
						case .ambiqOTARXCharacteristic	: log?.e ("\(gblReturnID(peripheral)) '\(enumerated.title)' - should not be here")
						case .ambiqOTATXCharacteristic	: mEthosOTATXCharacteristic?.didDiscoverDescriptor()
						#endif
						
						#if UNIVERSAL || LIVOTAL
						case .livotalCharacteristic		: mCustomCharacteristic?.didDiscoverDescriptor()
						case .nordicDFUCharacteristic	: mNordicDFUCharacteristic?.didDiscoverDescriptor()
						#endif
						}
					}
					else if let enumerated = org_bluetooth_characteristic(rawValue: characteristic.prettyID) {
						switch (enumerated) {
						case .battery_level				: mBatteryLevelCharacteristic?.didDiscoverDescriptor()
						default:
							log?.e ("\(gblReturnID(peripheral)) '\(enumerated.title)' - don't know what to do")
						}
					}
					
				case .characteristic_user_description:
					break

				default:
					log?.e ("\(gblReturnID(peripheral)) for characteristic: \(characteristic.prettyID) - '\(standardDescriptor.title)'.  Do not know what to do - skipping")
				}
			}
			else {
				log?.e ("\(gblReturnID(peripheral)) for characteristic \(characteristic.prettyID): \(descriptor.prettyID) - do not know what to do")
			}
		}
		else {
			log?.e ("Peripheral object is nil - do nothing")
		}
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func didUpdateValue (_ characteristic: CBCharacteristic) {
		if let peripheral = peripheral {
			if let enumerated = org_bluetooth_characteristic(rawValue: characteristic.prettyID) {
				switch (enumerated) {
				case .model_number_string		: mModelNumber?.didUpdateValue()
				case .hardware_revision_string	: mHardwareRevision?.didUpdateValue()
				case .firmware_revision_string	: mFirmwareVersion?.didUpdateValue()
				case .manufacturer_name_string	: mManufacturerName?.didUpdateValue()
				case .battery_level				: mBatteryLevelCharacteristic?.didUpdateValue()
				case .body_sensor_location:
					if let value = characteristic.value {
						log?.v ("\(gblReturnID(peripheral)): '\(enumerated.title)' - \(value.hexString)")
					}
					else { log?.e ("No valid \(enumerated.title) data!") }
				default:
					log?.e ("\(gblReturnID(peripheral)) for characteristic: '\(enumerated.title)' - do not know what to do")
				}
			}
			else if let enumerated = Device.characteristics(rawValue: characteristic.prettyID) {
				switch (enumerated) {
				#if UNIVERSAL || ETHOS
				case .ethosCharacteristic		: mCustomCharacteristic?.didUpdateValue()
				case .ambiqOTARXCharacteristic	: log?.e ("\(gblReturnID(peripheral)) '\(enumerated.title)' - should not be here")
				case .ambiqOTATXCharacteristic	: mEthosOTARXCharacteristic?.didUpdateValue()	// Comes in on TX, causes RX to do next step
				#endif
				
				#if UNIVERSAL || LIVOTAL
				case .livotalCharacteristic		: mCustomCharacteristic?.didUpdateValue()
				case .nordicDFUCharacteristic	: mNordicDFUCharacteristic?.didUpdateValue()
				#endif
				}
			}
			else {
				log?.v ("\(gblReturnID(peripheral)) for characteristic: \(characteristic.prettyID)")
			}
		}
		else {
			log?.e ("Peripheral object is nil - do nothing")
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
		if let _ = peripheral {
			if (characteristic.isNotifying) {
				if let enumerated = Device.characteristics(rawValue: characteristic.prettyID) {
					log?.v ("\(gblReturnID(characteristic.service.peripheral)): '\(enumerated.title)'")
					switch (enumerated) {
					#if UNIVERSAL || ETHOS
					case .ethosCharacteristic		: mCustomCharacteristic?.didUpdateNotificationState()
					case .ambiqOTARXCharacteristic	: log?.e ("\(gblReturnID(characteristic.service.peripheral)) '\(enumerated.title)' - should not be here")
					case .ambiqOTATXCharacteristic	: mEthosOTATXCharacteristic?.didUpdateNotificationState()
					#endif

					#if UNIVERSAL || LIVOTAL
					case .livotalCharacteristic		: mCustomCharacteristic?.didUpdateNotificationState()
					case .nordicDFUCharacteristic	: mNordicDFUCharacteristic?.didUpdateNotificationState()
					#endif
					}
				}
				else if let enumerated = org_bluetooth_characteristic(rawValue: characteristic.prettyID) {
					log?.v ("\(gblReturnID(characteristic.service.peripheral)): '\(enumerated.title)'")
					switch (enumerated) {
					case .battery_level				: mBatteryLevelCharacteristic?.didUpdateNotificationState()
					default:
						log?.e ("\(gblReturnID(characteristic.service.peripheral)): '\(enumerated.title)'.  Do not know what to do - skipping")
					}
				}
				else {
					log?.e ("\(gblReturnID(characteristic.service.peripheral)): \(characteristic.prettyID) - do not know what to do")
				}
			}
		}
		else {
			log?.e ("Peripheral object is nil - do nothing")
		}
	}

	
	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	// Write without response is done.  Will only happen for OTA, since that uses
	// write without responses
	//
	//--------------------------------------------------------------------------------
	func isReady() {
		#if UNIVERSAL || ETHOS
		mEthosOTARXCharacteristic?.isReady()
		#endif
	}

}
