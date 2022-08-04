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
		#if UNIVERSAL || ALTER
		case alterService			= "883BBA2C-8E31-40BB-A859-D59A2FB38EC0"
		#endif
		
		#if UNIVERSAL || ETHOS
		case ethosService			= "B30E0F19-A021-45F3-8661-4255CBD49E10"
		#endif

		#if UNIVERSAL || ALTER || ETHOS
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
			#if UNIVERSAL || ALTER
			case .alterService		: return "Alter Service"
			#endif

			#if UNIVERSAL || ETHOS
			case .ethosService		: return "Ethos Service"
			#endif

			#if UNIVERSAL || ETHOS || ALTER
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
		#if UNIVERSAL || ALTER
		case alterCharacteristic		= "883BBA2C-8E31-40BB-A859-D59A2FB38EC1"
		#endif

		#if UNIVERSAL || ETHOS
		case ethosCharacteristic		= "B30E0F19-A021-45F3-8661-4255CBD49E11"
		#endif
		
		#if UNIVERSAL || ETHOS || ALTER
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
			#if UNIVERSAL || ALTER
			case .alterCharacteristic		: return "Alter Characteristic"
			#endif

			#if UNIVERSAL || ETHOS
			case .ethosCharacteristic		: return "Ethos Characteristic"
			#endif

			#if UNIVERSAL || ETHOS || ALTER
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
	@objc public var type	: biostrapDeviceSDK.biostrapDeviceType
	#endif
	
	var peripheral			: CBPeripheral?
	@objc public var name	: String
	@objc public var id		: String
	var epoch				: TimeInterval
	
	// MARK: Callbacks
	var batteryLevelUpdated: ((_ id: String, _ percentage: Int)->())?

	var writeEpochComplete: ((_ id: String, _ successful: Bool)->())?
	var getAllPacketsComplete: ((_ id: String, _ successful: Bool)->())?
	var getNextPacketComplete: ((_ id: String, _ successful: Bool, _ packet: String)->())?
	var getPacketCountComplete: ((_ id: String, _ successful: Bool, _ count: Int)->())?
	var startManualComplete: ((_ id: String, _ successful: Bool)->())?
	var stopManualComplete: ((_ id: String, _ successful: Bool)->())?
	var ledComplete: ((_ id: String, _ successful: Bool)->())?
	#if UNIVERSAL || ETHOS
	var motorComplete: ((_ id: String, _ successful: Bool)->())?
	#endif
	var enterShipModeComplete: ((_ id: String, _ successful: Bool)->())?
	var writeSerialNumberComplete: ((_ id: String, _ successful: Bool)->())?
	var readSerialNumberComplete: ((_ id: String, _ successful: Bool, _ partID: String)->())?
	var deleteSerialNumberComplete: ((_ id: String, _ successful: Bool)->())?
	var writeAdvIntervalComplete: ((_ id: String, _ successful: Bool)->())?
	var readAdvIntervalComplete: ((_ id: String, _ successful: Bool, _ seconds: Int)->())?
	var deleteAdvIntervalComplete: ((_ id: String, _ successful: Bool)->())?
	var clearChargeCyclesComplete: ((_ id: String, _ successful: Bool)->())?
	var readChargeCyclesComplete: ((_ id: String, _ successful: Bool, _ cycles: Float)->())?
	var allowPPGComplete: ((_ id: String, _ successful: Bool)->())?
	var wornCheckComplete: ((_ id: String, _ successful: Bool, _ code: String, _ value: Int)->())?
	var rawLoggingComplete: ((_ id: String, _ successful: Bool)->())?
	var resetComplete: ((_ id: String, _ successful: Bool)->())?
	var endSleepComplete: ((_ id: String, _ successful: Bool)->())?
	var readEpochComplete: ((_ id: String, _ successful: Bool, _ value: Int)->())?
    var manualResult: ((_ id: String, _ successful: Bool, _ packet: String)->())?
	var ppgFailed: ((_ id: String, _ code: Int)->())?
	var disableWornDetectComplete: ((_ id: String, _ successful: Bool)->())?
	var enableWornDetectComplete: ((_ id: String, _ successful: Bool)->())?

	var dataPackets: ((_ id: String, _ packets: String)->())?
	var dataComplete: ((_ id: String, _ bad_fw_read_count: Int, _ bad_fw_parse_count: Int, _ overflow_count: Int, _ bad_sdk_parse_count: Int)->())?
	var dataFailure: ((_ id: String)->())?
	
	var deviceWornStatus: ((_ id: String, _ isWorn: Bool)->())?

	var updateFirmwareStarted: ((_ id: String)->())?
	var updateFirmwareFinished: ((_ id: String)->())?
	var updateFirmwareProgress: ((_ id: String, _ percentage: Float)->())?
	var updateFirmwareFailed: ((_ id: String, _ code: Int, _ message: String)->())?

	var manufacturingTestComplete: ((_ id: String, _ successful: Bool)->())?
	var manufacturingTestResult: ((_ id: String, _ valid: Bool, _ result: String)->())?
	
	#if UNIVERSAL || ETHOS || ALTER
	var startLiveSyncComplete: ((_ id: String, _ successful: Bool)->())?
	var stopLiveSyncComplete: ((_ id: String, _ successful: Bool)->())?
	var recalibratePPGComplete: ((_ id: String, _ successful: Bool)->())?
	#endif

	var deviceChargingStatus: ((_ id: String, _ charging: Bool, _ on_charger: Bool, _ error: Bool)->())?

	var setSessionParamComplete: ((_ id: String, _ successful: Bool, _ parameter: sessionParameterType)->())?
	var getSessionParamComplete: ((_ id: String, _ successful: Bool, _ parameter: sessionParameterType, _ value: Int)->())?
	var resetSessionParamsComplete: ((_ id: String, _ successful: Bool)->())?
	var acceptSessionParamsComplete: ((_ id: String, _ successful: Bool)->())?

	@objc public var batteryLevel	: Int = 0
	@objc public var wornStatus		: String = "Not worn"
	@objc public var chargingStatus	: String = "Not charging"

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

	@objc public var serialNumber : String {
		if let serialNumber = mSerialNumber { return serialNumber.value }
		else { return ("???") }
	}

	internal var mModelNumber					: disStringCharacteristic?
	internal var mFirmwareVersion				: disStringCharacteristic?
	internal var mHardwareRevision				: disStringCharacteristic?
	internal var mManufacturerName				: disStringCharacteristic?
	internal var mSerialNumber					: disStringCharacteristic?
	
	internal var mBatteryLevelCharacteristic	: batteryLevelCharacteristic?
	internal var mCustomCharacteristic			: customCharacteristic?

	#if UNIVERSAL || LIVOTAL
	internal var mNordicDFUCharacteristic		: nordicDFUCharacteristic?
	#endif

	#if UNIVERSAL || ETHOS || ALTER
	internal var mAmbiqOTARXCharacteristic		: ambiqOTARXCharacteristic?
	internal var mAmbiqOTATXCharacteristic		: ambiqOTATXCharacteristic?
	#endif
	
	class var scan_services: [CBUUID] {
		#if UNIVERSAL
		if (gblLimitLivotal) {
			return [services.livotalService.UUID, services.nordicDFUService.UUID]
		}
		else if (gblLimitEthos) {
			return [services.ethosService.UUID]
		}
		else if (gblLimitAlter) {
			return [services.alterService.UUID]
		}
		else {
			return [services.livotalService.UUID, services.nordicDFUService.UUID, services.ethosService.UUID, services.alterService.UUID]
		}
		#endif
		
		#if LIVOTAL
		return [services.livotalService.UUID, services.nordicDFUService.UUID]
		#endif
		
		#if ETHOS
		return [services.ethosService.UUID]
		#endif

		#if ALTER
		return [services.alterService.UUID]
		#endif
	}
	
	class func hit(_ service: CBService) -> Bool {
		if let peripheral = service.peripheral {
			if let standardService = org_bluetooth_service(rawValue: service.prettyID) {
				log?.v ("\(peripheral.prettyID): '\(standardService.title)'")
				switch standardService {
				case .device_information: return (true)
				case .battery_service: return (true)
				default:
					log?.e ("\(peripheral.prettyID): (unknown): '\(standardService.title)'")
					return (false)
				}
			}
			else if let customService = Device.services(rawValue: service.prettyID) {
				log?.v ("\(peripheral.prettyID): '\(customService.title)'")
				return (true)
			}
			else {
				log?.e ("\(peripheral.prettyID): \(service.prettyID) - don't know what to do!!!!")
				return (false)
			}
		}
		else {
			return (false)
		}
	}

	override init() {
		self.mState						= .disconnected
		
		self.name						= "UNKNOWN"
		self.id							= "UNKNOWN"
		self.epoch						= TimeInterval(0)
		
		#if UNIVERSAL
		self.type						= .unknown
		#endif
	}

	#if UNIVERSAL
	convenience init(_ name: String, id: String, peripheral: CBPeripheral?, type: biostrapDeviceSDK.biostrapDeviceType) {
		self.init()
		
		self.name		= name
		self.id			= id
		self.peripheral	= peripheral
		self.type		= type
	}
	#endif

	convenience init(_ name: String, id: String, peripheral: CBPeripheral?) {
		self.init()
		
		self.name		= name
		self.id			= id
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
		if let firmwareVesion = mFirmwareVersion, let customCharacteristic = mCustomCharacteristic {
			customCharacteristic.firmwareVersion = firmwareVesion.value
		}

		#if UNIVERSAL
		switch type {
		case .livotal:
			if let firmwareVersion = mFirmwareVersion {
				if (firmwareVersion.value < "1.2.4") {
					if let modelNumber = mModelNumber, let hardwareRevision = mHardwareRevision, let manufacturerName = mManufacturerName, let nordicDFUCharacteristic = mNordicDFUCharacteristic, let customCharacteristic = mCustomCharacteristic, let batteryCharacteristic = mBatteryLevelCharacteristic {
						
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
				}
				else {
					if let modelNumber = mModelNumber, let hardwareRevision = mHardwareRevision, let manufacturerName = mManufacturerName, let serialNumber = mSerialNumber, let nordicDFUCharacteristic = mNordicDFUCharacteristic, let customCharacteristic = mCustomCharacteristic, let batteryCharacteristic = mBatteryLevelCharacteristic {
						
						//log?.v ("MN: \(modelNumber.configured), HV: \(hardwareRevision.configured), FV: \(firmwareVersion.configured), Name: \(manufacturerName.configured), SN: \(serialNumber.configured), LIV: \(customCharacteristic.configured), BAT: \(batteryCharacteristic.configured), DFU: \(dfuCharacteristic.configured)")

						return (modelNumber.configured &&
								hardwareRevision.configured &&
								firmwareVersion.configured &&
								manufacturerName.configured &&
								serialNumber.configured &&
								batteryCharacteristic.configured &&
								customCharacteristic.configured &&
								nordicDFUCharacteristic.configured)
					}
					else { return (false) }
				}
			}
			else { return (false) }
		case .ethos:
			if let modelNumber = mModelNumber, let hardwareRevision = mHardwareRevision, let firmwareVersion = mFirmwareVersion, let manufacturerName = mManufacturerName, let ambiqOTARXCharacteristic = mAmbiqOTARXCharacteristic, let ambiqOTATXCharacteristic = mAmbiqOTATXCharacteristic, let customCharacteristic = mCustomCharacteristic, let batteryCharacteristic = mBatteryLevelCharacteristic {
				
				//log?.v ("MN: \(modelNumber.configured), HV: \(hardwareRevision.configured), FV: \(firmwareVersion.configured), Name: \(manufacturerName.configured), ETH: \(customCharacteristic.configured), BAT: \(batteryCharacteristic.configured), OTARX: \(ethosOTARXCharacteristic.configured), OTATX: \(ethosOTATXCharacteristic.configured)")

				return (modelNumber.configured &&
						hardwareRevision.configured &&
						firmwareVersion.configured &&
						manufacturerName.configured &&
						batteryCharacteristic.configured &&
						customCharacteristic.configured &&
						ambiqOTARXCharacteristic.configured &&
						ambiqOTATXCharacteristic.configured
				)
			}
			else {
				return (false)
			}
			
		case .alter: return false
		case .unknown: return false
		}
		
		#elseif LIVOTAL
		if let firmwareVersion = mFirmwareVersion {
			if (firmwareVersion.value < "1.2.4") {
				if let modelNumber = mModelNumber, let hardwareRevision = mHardwareRevision, let manufacturerName = mManufacturerName, let nordicDFUCharacteristic = mNordicDFUCharacteristic, let customCharacteristic = mCustomCharacteristic, let batteryCharacteristic = mBatteryLevelCharacteristic {
					
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
			}
			else {
				if let modelNumber = mModelNumber, let hardwareRevision = mHardwareRevision, let manufacturerName = mManufacturerName, let serialNumber = mSerialNumber, let nordicDFUCharacteristic = mNordicDFUCharacteristic, let customCharacteristic = mCustomCharacteristic, let batteryCharacteristic = mBatteryLevelCharacteristic {
					
					//log?.v ("MN: \(modelNumber.configured), HV: \(hardwareRevision.configured), FV: \(firmwareVersion.configured), Name: \(manufacturerName.configured), SN: \(serialNumber.configured), LIV: \(customCharacteristic.configured), BAT: \(batteryCharacteristic.configured), DFU: \(nordicDFUCharacteristic.configured)")

					return (modelNumber.configured &&
							hardwareRevision.configured &&
							firmwareVersion.configured &&
							manufacturerName.configured &&
							serialNumber.configured &&
							batteryCharacteristic.configured &&
							customCharacteristic.configured &&
							nordicDFUCharacteristic.configured)
				}
				else { return (false) }
			}
		}
		else { return (false) }
		
		#elseif ETHOS
		if let modelNumber = mModelNumber, let hardwareRevision = mHardwareRevision, let firmwareVersion = mFirmwareVersion, let manufacturerName = mManufacturerName, let ambiqOTARXCharacteristic = mAmbiqOTARXCharacteristic, let ambiqOTATXCharacteristic = mAmbiqOTATXCharacteristic, let customCharacteristic = mCustomCharacteristic, let batteryCharacteristic = mBatteryLevelCharacteristic {
			
			//log?.v ("MN: \(modelNumber.configured), HV: \(hardwareRevision.configured), FV: \(firmwareVersion.configured), Name: \(manufacturerName.configured), ETH: \(customCharacteristic.configured), BAT: \(batteryCharacteristic.configured), OTARX: \(ambiqOTARXCharacteristic.configured), OTATX: \(ambiqOTATXCharacteristic.configured)")

			return (modelNumber.configured &&
					hardwareRevision.configured &&
					firmwareVersion.configured &&
					manufacturerName.configured &&
					batteryCharacteristic.configured &&
					customCharacteristic.configured &&
					ambiqOTARXCharacteristic.configured &&
					ambiqOTATXCharacteristic.configured
			)
		}
		else { return (false) }
		
		#elseif ALTER
		if let modelNumber = mModelNumber, let hardwareRevision = mHardwareRevision, let firmwareVersion = mFirmwareVersion, let manufacturerName = mManufacturerName, let ambiqOTARXCharacteristic = mAmbiqOTARXCharacteristic, let ambiqOTATXCharacteristic = mAmbiqOTATXCharacteristic, let customCharacteristic = mCustomCharacteristic, let batteryCharacteristic = mBatteryLevelCharacteristic {
			
			//log?.v ("MN: \(modelNumber.configured), HV: \(hardwareRevision.configured), FV: \(firmwareVersion.configured), Name: \(manufacturerName.configured), ETH: \(customCharacteristic.configured), BAT: \(batteryCharacteristic.configured), OTARX: \(ambiqOTARXCharacteristic.configured), OTATX: \(ambiqOTATXCharacteristic.configured)")

			return (modelNumber.configured &&
					hardwareRevision.configured &&
					firmwareVersion.configured &&
					manufacturerName.configured &&
					batteryCharacteristic.configured &&
					customCharacteristic.configured &&
					ambiqOTARXCharacteristic.configured &&
					ambiqOTATXCharacteristic.configured
			)
		}
		else { return (false) }
		

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
	func endSleep(_ id: String) {
		if let customCharacteristic = mCustomCharacteristic {
			customCharacteristic.endSleep()
		}
		else { self.endSleepComplete?(id, false) }
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
	func startManual(_ id: String, algorithms: ppgAlgorithmConfiguration) {
		if let customCharacteristic = mCustomCharacteristic {
			customCharacteristic.startManual(algorithms)
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
	#if UNIVERSAL || LIVOTAL
	func livotalLED(_ id: String, red: Bool, green: Bool, blue: Bool, blink: Bool, seconds: Int) {
		if let customCharacteristic = mCustomCharacteristic {
			customCharacteristic.livotalLED(red: red, green: green, blue: blue, blink: blink, seconds: seconds)
		}
		else { self.ledComplete?(id, false) }
	}
	#endif

	#if UNIVERSAL || ETHOS
	func ethosLED(_ id: String, red: Int, green: Int, blue: Int, mode: biostrapDeviceSDK.ethosLEDMode, seconds: Int, percent: Int) {
		if let customCharacteristic = mCustomCharacteristic {
			customCharacteristic.ethosLED(red: red, green: green, blue: blue, mode: mode, seconds: seconds, percent: percent)
		}
		else { self.ledComplete?(id, false) }
	}
	#endif

	#if UNIVERSAL || ALTER
	func alterLED(_ id: String, red: Int, green: Int, blue: Int, mode: biostrapDeviceSDK.alterLEDMode, seconds: Int, percent: Int) {
		if let customCharacteristic = mCustomCharacteristic {
			customCharacteristic.alterLED(red: red, green: green, blue: blue, mode: mode, seconds: seconds, percent: percent)
		}
		else { self.ledComplete?(id, false) }
	}
	#endif

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	#if UNIVERSAL || ETHOS
	func motor(_ id: String, milliseconds: Int, pulses: Int) {
		if let customCharacteristic = mCustomCharacteristic {
			customCharacteristic.motor(milliseconds: milliseconds, pulses: pulses)
		}
		else { self.motorComplete?(id, false) }
	}
	#endif

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
	func writeSerialNumber(_ id: String, partID: String) {
		if let customCharacteristic = mCustomCharacteristic {
			customCharacteristic.writeSerialNumber(partID)
		}
		else { self.writeSerialNumberComplete?(id, false) }
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func readSerialNumber(_ id: String) {
		if let customCharacteristic = mCustomCharacteristic {
			customCharacteristic.readSerialNumber()
		}
		else { self.readSerialNumberComplete?(id, false, "") }
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func deleteSerialNumber(_ id: String) {
		if let customCharacteristic = mCustomCharacteristic {
			customCharacteristic.deleteSerialNumber()
		}
		else { self.deleteSerialNumberComplete?(id, false) }
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
	func allowPPG(_ id: String, allow: Bool) {
		if let customCharacteristic = mCustomCharacteristic {
			customCharacteristic.allowPPG(allow)
		}
		else { self.allowPPGComplete?(id, false) }
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func manufacturingTest(_ id: String) {
		if let customCharacteristic = mCustomCharacteristic {
			customCharacteristic.manufacturingTest()
		}
		else { self.manufacturingTestComplete?(id, false) }
	}

	#if ETHOS || UNIVERSAL
	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func startLiveSync(_ id: String, configuration: liveSyncConfiguration) {
		if let customCharacteristic = mCustomCharacteristic {
			customCharacteristic.startLiveSync(configuration)
		}
		else { self.startLiveSyncComplete?(id, false) }
	}
	
	func stopLiveSync(_ id: String) {
		if let customCharacteristic = mCustomCharacteristic {
			customCharacteristic.stopLiveSync()
		}
		else { self.stopLiveSyncComplete?(id, false) }
	}
	
	func recalibratePPG(_ id: String) {
		if let customCharacteristic = mCustomCharacteristic {
			customCharacteristic.recalibratePPG()
		}
		else { self.recalibratePPGComplete?(id, false) }
	}
	#endif

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
		#if UNIVERSAL
		switch (type) {
		case .livotal:
			if let nordicDFUCharacteristic = mNordicDFUCharacteristic { nordicDFUCharacteristic.start(file) }
			else { updateFirmwareFailed?(self.id, 10001, "No DFU characteristic to update") }
		case .ethos:
			if let ambiqOTARXCharacteristic = mAmbiqOTARXCharacteristic {
				do {
					let contents = try Data(contentsOf: file)
					ambiqOTARXCharacteristic.start(contents)
				}
				catch {
					log?.e ("Cannot open file")
					self.updateFirmwareFailed?(self.id, 10001, "Cannot parse file for update")
				}
			}
			else { updateFirmwareFailed?(self.id, 10001, "No OTA RX characteristic to update") }
		default: updateFirmwareFailed?(self.id, 10001, "Do not understand type to update: \(type.title)")
		}
		#elseif LIVOTAL
		if let nordicDFUCharacteristic = mNordicDFUCharacteristic { nordicDFUCharacteristic.start(file) }
		else { updateFirmwareFailed?(self.id, 10001, "No DFU characteristic to update") }
		#elseif ETHOS
		if let ambiqOTARXCharacteristic = mAmbiqOTARXCharacteristic {
			do {
				let contents = try Data(contentsOf: file)
				ambiqOTARXCharacteristic.start(contents)
			}
			catch {
				log?.e ("Cannot open file")
				self.updateFirmwareFailed?(self.id, 10001, "Cannot parse file for update")
			}
		}
		else { updateFirmwareFailed?(self.id, 10001, "No OTA RX characteristic to update") }
		#else
		updateFirmwareFailed?(self.id, 10001, "Cannot do this yet")
		#endif
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func cancelFirmwareUpdate() {
		#if UNIVERSAL || LIVOTAL
		if let nordicDFUCharacteristic = mNordicDFUCharacteristic { nordicDFUCharacteristic.cancel() }
		else { updateFirmwareFailed?(self.id, 10001, "No DFU characteristic to update") }
		#else
		updateFirmwareFailed?(self.id, 10001, "Cannot do this yet")
		#endif
	}

	
	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func setSessionParam(_ parameter: sessionParameterType, value: Int) {
		log?.v("\(self.id): \(parameter)")

		if let customCharacteristic = mCustomCharacteristic {
			customCharacteristic.setSessionParam(parameter, value: value)
		}
		else { self.setSessionParamComplete?(self.id, false, parameter) }

	}
	
	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func getSessionParam(_ parameter: sessionParameterType) {
		log?.v("\(self.id): \(parameter)")

		if let customCharacteristic = mCustomCharacteristic {
			customCharacteristic.getSessionParam(parameter)
		}
		else { self.getSessionParamComplete?(self.id, false, parameter, 0) }
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func resetSessionParams() {
		log?.v("\(self.id)")

		if let customCharacteristic = mCustomCharacteristic {
			customCharacteristic.resetSessionParams()
		}
		else { self.resetSessionParamsComplete?(self.id, false) }
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func acceptSessionParams() {
		log?.v("\(self.id)")

		if let customCharacteristic = mCustomCharacteristic {
			customCharacteristic.acceptSessionParams()
		}
		else { self.acceptSessionParamsComplete?(self.id, false) }
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
				case .serial_number_string:
					mSerialNumber = disStringCharacteristic(peripheral, characteristic: characteristic)
					mSerialNumber?.read()
				case .battery_level:
					log?.v ("\(self.id) '\(testCharacteristic.title)' - read it and enable notifications")
					mBatteryLevelCharacteristic	= batteryLevelCharacteristic(peripheral, characteristic: characteristic)
					mBatteryLevelCharacteristic?.updated	= { id, percentage in
						self.batteryLevel = percentage
						self.batteryLevelUpdated?(id, percentage)
					}
					mBatteryLevelCharacteristic?.read()
					mBatteryLevelCharacteristic?.discoverDescriptors()
				case .body_sensor_location:
					log?.v ("\(self.id) '\(testCharacteristic.title)' - read it")
					peripheral.readValue(for: characteristic)
				default:
					if let service = characteristic.service {
						log?.e ("\(self.id) for service: \(service.prettyID) - '\(testCharacteristic.title)' - do not know what to do")
					}
					else {
						log?.e ("\(self.id) for nil service - '\(testCharacteristic.title)' - do not know what to do")
					}
				}
			}
			else if let testCharacteristic = Device.characteristics(rawValue: characteristic.prettyID) {
				switch (testCharacteristic) {

				#if UNIVERSAL || ETHOS
				case .ethosCharacteristic:
					mCustomCharacteristic	= customCharacteristic(peripheral, characteristic: characteristic)
					#if UNIVERSAL
					mCustomCharacteristic?.type	= .ethos
					#endif
					mCustomCharacteristic?.startManualComplete = { successful in self.startManualComplete?(self.id, successful) }
					mCustomCharacteristic?.stopManualComplete = { successful in self.stopManualComplete?(self.id, successful) }
					mCustomCharacteristic?.ledComplete = { successful in self.ledComplete?(self.id, successful) }
					mCustomCharacteristic?.motorComplete = { successful in self.motorComplete?(self.id, successful) }
					mCustomCharacteristic?.enterShipModeComplete = { successful in self.enterShipModeComplete?(self.id, successful) }
					mCustomCharacteristic?.writeSerialNumberComplete = { successful in self.writeSerialNumberComplete?(self.id, successful) }
					mCustomCharacteristic?.readSerialNumberComplete = { successful, partID in self.readSerialNumberComplete?(self.id, successful, partID) }
					mCustomCharacteristic?.deleteSerialNumberComplete = { successful in self.deleteSerialNumberComplete?(self.id, successful) }
					mCustomCharacteristic?.writeAdvIntervalComplete = { successful in self.writeAdvIntervalComplete?(self.id, successful) }
					mCustomCharacteristic?.readAdvIntervalComplete = { successful, seconds in self.readAdvIntervalComplete?(self.id, successful, seconds) }
					mCustomCharacteristic?.deleteAdvIntervalComplete = { successful in self.deleteAdvIntervalComplete?(self.id, successful) }
					mCustomCharacteristic?.clearChargeCyclesComplete = { successful in self.clearChargeCyclesComplete?(self.id, successful) }
					mCustomCharacteristic?.readChargeCyclesComplete = { successful, cycles in self.readChargeCyclesComplete?(self.id, successful, cycles) }
					mCustomCharacteristic?.rawLoggingComplete = { successful in self.rawLoggingComplete?(self.id, successful) }
					mCustomCharacteristic?.allowPPGComplete = { successful in self.allowPPGComplete?(self.id, successful)}
					mCustomCharacteristic?.wornCheckComplete = { successful, code, value in self.wornCheckComplete?(self.id, successful, code, value )}
					mCustomCharacteristic?.resetComplete = { successful in self.resetComplete?(self.id, successful) }
					mCustomCharacteristic?.manualResult = { successful, packet in self.manualResult?(self.id, successful, packet) }
					mCustomCharacteristic?.ppgFailed = { code in self.ppgFailed?(self.id, code) }
					mCustomCharacteristic?.writeEpochComplete = { successful in self.writeEpochComplete?(self.id, successful) }
					mCustomCharacteristic?.readEpochComplete = { successful, value in self.readEpochComplete?(self.id, successful,  value) }
					mCustomCharacteristic?.endSleepComplete = { successful in self.endSleepComplete?(self.id, successful) }
					mCustomCharacteristic?.getAllPacketsComplete = { successful in self.getAllPacketsComplete?(self.id, successful) }
					mCustomCharacteristic?.getNextPacketComplete = { successful, packet in self.getNextPacketComplete?(self.id, successful, packet) }
					mCustomCharacteristic?.getPacketCountComplete = { successful, count in self.getPacketCountComplete?(self.id, successful, count) }
					mCustomCharacteristic?.disableWornDetectComplete = { successful in self.disableWornDetectComplete?(self.id, successful) }
					mCustomCharacteristic?.enableWornDetectComplete = { successful in self.enableWornDetectComplete?(self.id, successful) }
					mCustomCharacteristic?.dataPackets = { packets in self.dataPackets?(self.id, packets) }
					mCustomCharacteristic?.dataComplete = { bad_fw_read_count, bad_fw_parse_count, overflow_count, bad_sdk_parse_count in self.dataComplete?(self.id, bad_fw_read_count, bad_fw_parse_count, overflow_count, bad_sdk_parse_count) }
					mCustomCharacteristic?.dataFailure = { self.dataFailure?(self.id) }
					mCustomCharacteristic?.deviceWornStatus = { isWorn in
						if (isWorn) { self.wornStatus = "Worn" }
						else { self.wornStatus = "Not Worn" }
						self.deviceWornStatus?(self.id, isWorn)
					}
					mCustomCharacteristic?.setSessionParamComplete = { successful, parameter in self.setSessionParamComplete?(self.id, successful, parameter) }
					mCustomCharacteristic?.getSessionParamComplete = { successful, parameter, value in self.getSessionParamComplete?(self.id, successful, parameter, value) }
					mCustomCharacteristic?.acceptSessionParamsComplete	= { successful in self.acceptSessionParamsComplete?(self.id, successful) }
					mCustomCharacteristic?.resetSessionParamsComplete	= { successful in self.resetSessionParamsComplete?(self.id, successful) }
					mCustomCharacteristic?.manufacturingTestComplete	= { successful in self.manufacturingTestComplete?(self.id, successful) }
					mCustomCharacteristic?.manufacturingTestResult		= { valid, result in self.manufacturingTestResult?(self.id, valid, result) }
					mCustomCharacteristic?.startLiveSyncComplete		= { successful in self.startLiveSyncComplete?(self.id, successful) }
					mCustomCharacteristic?.stopLiveSyncComplete			= { successful in self.stopLiveSyncComplete?(self.id, successful) }
					mCustomCharacteristic?.recalibratePPGComplete		= { successful in self.recalibratePPGComplete?(self.id, successful) }
					mCustomCharacteristic?.deviceChargingStatus			= { charging, on_charger, error in
						if (charging) { self.chargingStatus	= "Charging" }
						else if (on_charger) { self.chargingStatus = "On Charger" }
						else if (error) { self.chargingStatus = "Charging Error" }
						else { self.chargingStatus = "Not Charging" }
						self.deviceChargingStatus?(self.id, charging, on_charger, error) }
					mCustomCharacteristic?.discoverDescriptors()
				#endif

				#if UNIVERSAL || ALTER
				case .alterCharacteristic:
					mCustomCharacteristic	= customCharacteristic(peripheral, characteristic: characteristic)
					#if UNIVERSAL
					mCustomCharacteristic?.type	= .alter
					#endif
					mCustomCharacteristic?.startManualComplete = { successful in self.startManualComplete?(self.id, successful) }
					mCustomCharacteristic?.stopManualComplete = { successful in self.stopManualComplete?(self.id, successful) }
					mCustomCharacteristic?.ledComplete = { successful in self.ledComplete?(self.id, successful) }
					mCustomCharacteristic?.enterShipModeComplete = { successful in self.enterShipModeComplete?(self.id, successful) }
					mCustomCharacteristic?.writeSerialNumberComplete = { successful in self.writeSerialNumberComplete?(self.id, successful) }
					mCustomCharacteristic?.readSerialNumberComplete = { successful, partID in self.readSerialNumberComplete?(self.id, successful, partID) }
					mCustomCharacteristic?.deleteSerialNumberComplete = { successful in self.deleteSerialNumberComplete?(self.id, successful) }
					mCustomCharacteristic?.writeAdvIntervalComplete = { successful in self.writeAdvIntervalComplete?(self.id, successful) }
					mCustomCharacteristic?.readAdvIntervalComplete = { successful, seconds in self.readAdvIntervalComplete?(self.id, successful, seconds) }
					mCustomCharacteristic?.deleteAdvIntervalComplete = { successful in self.deleteAdvIntervalComplete?(self.id, successful) }
					mCustomCharacteristic?.clearChargeCyclesComplete = { successful in self.clearChargeCyclesComplete?(self.id, successful) }
					mCustomCharacteristic?.readChargeCyclesComplete = { successful, cycles in self.readChargeCyclesComplete?(self.id, successful, cycles) }
					mCustomCharacteristic?.rawLoggingComplete = { successful in self.rawLoggingComplete?(self.id, successful) }
					mCustomCharacteristic?.allowPPGComplete = { successful in self.allowPPGComplete?(self.id, successful)}
					mCustomCharacteristic?.wornCheckComplete = { successful, code, value in self.wornCheckComplete?(self.id, successful, code, value )}
					mCustomCharacteristic?.resetComplete = { successful in self.resetComplete?(self.id, successful) }
					mCustomCharacteristic?.manualResult = { successful, packet in self.manualResult?(self.id, successful, packet) }
					mCustomCharacteristic?.ppgFailed = { code in self.ppgFailed?(self.id, code) }
					mCustomCharacteristic?.writeEpochComplete = { successful in self.writeEpochComplete?(self.id, successful) }
					mCustomCharacteristic?.readEpochComplete = { successful, value in self.readEpochComplete?(self.id, successful,  value) }
					mCustomCharacteristic?.endSleepComplete = { successful in self.endSleepComplete?(self.id, successful) }
					mCustomCharacteristic?.getAllPacketsComplete = { successful in self.getAllPacketsComplete?(self.id, successful) }
					mCustomCharacteristic?.getNextPacketComplete = { successful, packet in self.getNextPacketComplete?(self.id, successful, packet) }
					mCustomCharacteristic?.getPacketCountComplete = { successful, count in self.getPacketCountComplete?(self.id, successful, count) }
					mCustomCharacteristic?.disableWornDetectComplete = { successful in self.disableWornDetectComplete?(self.id, successful) }
					mCustomCharacteristic?.enableWornDetectComplete = { successful in self.enableWornDetectComplete?(self.id, successful) }
					mCustomCharacteristic?.dataPackets = { packets in self.dataPackets?(self.id, packets) }
					mCustomCharacteristic?.dataComplete = { bad_fw_read_count, bad_fw_parse_count, overflow_count, bad_sdk_parse_count in self.dataComplete?(self.id, bad_fw_read_count, bad_fw_parse_count, overflow_count, bad_sdk_parse_count) }
					mCustomCharacteristic?.dataFailure = { self.dataFailure?(self.id) }
					mCustomCharacteristic?.deviceWornStatus = { isWorn in
						if (isWorn) { self.wornStatus = "Worn" }
						else { self.wornStatus = "Not Worn" }
						self.deviceWornStatus?(self.id, isWorn)
					}
					mCustomCharacteristic?.setSessionParamComplete = { successful, parameter in self.setSessionParamComplete?(self.id, successful, parameter) }
					mCustomCharacteristic?.getSessionParamComplete = { successful, parameter, value in self.getSessionParamComplete?(self.id, successful, parameter, value) }
					mCustomCharacteristic?.acceptSessionParamsComplete	= { successful in self.acceptSessionParamsComplete?(self.id, successful) }
					mCustomCharacteristic?.resetSessionParamsComplete	= { successful in self.resetSessionParamsComplete?(self.id, successful) }
					mCustomCharacteristic?.manufacturingTestComplete	= { successful in self.manufacturingTestComplete?(self.id, successful) }
					mCustomCharacteristic?.manufacturingTestResult		= { valid, result in self.manufacturingTestResult?(self.id, valid, result) }
					mCustomCharacteristic?.startLiveSyncComplete		= { successful in self.startLiveSyncComplete?(self.id, successful) }
					mCustomCharacteristic?.stopLiveSyncComplete			= { successful in self.stopLiveSyncComplete?(self.id, successful) }
					mCustomCharacteristic?.recalibratePPGComplete		= { successful in self.recalibratePPGComplete?(self.id, successful) }
					mCustomCharacteristic?.deviceChargingStatus			= { charging, on_charger, error in
						if (charging) { self.chargingStatus	= "Charging" }
						else if (on_charger) { self.chargingStatus = "On Charger" }
						else if (error) { self.chargingStatus = "Charging Error" }
						else { self.chargingStatus = "Not Charging" }
						self.deviceChargingStatus?(self.id, charging, on_charger, error) }
					mCustomCharacteristic?.discoverDescriptors()
				#endif

				#if UNIVERSAL || ETHOS || ALTER
				case .ambiqOTARXCharacteristic:
					if let service = characteristic.service {
						log?.v ("\(self.id) for service: \(service.prettyID) - '\(testCharacteristic.title)'")
					}
					else {
						log?.v ("\(self.id) for nil service - '\(testCharacteristic.title)'")
					}
					
					mAmbiqOTARXCharacteristic = ambiqOTARXCharacteristic(peripheral, characteristic: characteristic)
					mAmbiqOTARXCharacteristic?.started	= { self.updateFirmwareStarted?(self.id) }
					mAmbiqOTARXCharacteristic?.finished = { self.updateFirmwareFinished?(self.id) }
					mAmbiqOTARXCharacteristic?.failed	= { code, message in self.updateFirmwareFailed?(self.id, code, message) }
					mAmbiqOTARXCharacteristic?.progress	= { percent in self.updateFirmwareProgress?(self.id, percent) }
					
				case .ambiqOTATXCharacteristic:
					if let service = characteristic.service {
						log?.v ("\(self.id) for service: \(service.prettyID) - '\(testCharacteristic.title)'")
					}
					else {
						log?.v ("\(self.id) for nil service - '\(testCharacteristic.title)'")
					}
					
					mAmbiqOTATXCharacteristic = ambiqOTATXCharacteristic(peripheral, characteristic: characteristic)
					mAmbiqOTATXCharacteristic?.discoverDescriptors()
				#endif
				
				#if UNIVERSAL || LIVOTAL
				case .livotalCharacteristic:
					mCustomCharacteristic	= customCharacteristic(peripheral, characteristic: characteristic)
					#if UNIVERSAL
					mCustomCharacteristic?.type	= .livotal
					#endif
					mCustomCharacteristic?.startManualComplete = { successful in self.startManualComplete?(self.id, successful) }
					mCustomCharacteristic?.stopManualComplete = { successful in self.stopManualComplete?(self.id, successful) }
					mCustomCharacteristic?.ledComplete = { successful in self.ledComplete?(self.id, successful) }
					mCustomCharacteristic?.enterShipModeComplete = { successful in self.enterShipModeComplete?(self.id, successful) }
					mCustomCharacteristic?.writeSerialNumberComplete = { successful in self.writeSerialNumberComplete?(self.id, successful) }
					mCustomCharacteristic?.readSerialNumberComplete = { successful, partID in self.readSerialNumberComplete?(self.id, successful, partID) }
					mCustomCharacteristic?.deleteSerialNumberComplete = { successful in self.deleteSerialNumberComplete?(self.id, successful) }
					mCustomCharacteristic?.writeAdvIntervalComplete = { successful in self.writeAdvIntervalComplete?(self.id, successful) }
					mCustomCharacteristic?.readAdvIntervalComplete = { successful, seconds in self.readAdvIntervalComplete?(self.id, successful, seconds) }
					mCustomCharacteristic?.deleteAdvIntervalComplete = { successful in self.deleteAdvIntervalComplete?(self.id, successful) }
					mCustomCharacteristic?.clearChargeCyclesComplete = { successful in self.clearChargeCyclesComplete?(self.id, successful) }
					mCustomCharacteristic?.readChargeCyclesComplete = { successful, cycles in self.readChargeCyclesComplete?(self.id, successful, cycles) }
					mCustomCharacteristic?.rawLoggingComplete = { successful in self.rawLoggingComplete?(self.id, successful) }
					mCustomCharacteristic?.allowPPGComplete = { successful in self.allowPPGComplete?(self.id, successful)}
					mCustomCharacteristic?.wornCheckComplete = { successful, code, value in self.wornCheckComplete?(self.id, successful, code, value )}
					mCustomCharacteristic?.resetComplete = { successful in self.resetComplete?(self.id, successful) }
					mCustomCharacteristic?.manualResult = { successful, packet in self.manualResult?(self.id, successful, packet) }
					mCustomCharacteristic?.ppgFailed = { code in self.ppgFailed?(self.id, code) }
					mCustomCharacteristic?.writeEpochComplete = { successful in self.writeEpochComplete?(self.id, successful) }
					mCustomCharacteristic?.readEpochComplete = { successful, value in self.readEpochComplete?(self.id, successful,  value) }
					mCustomCharacteristic?.endSleepComplete = { successful in self.endSleepComplete?(self.id, successful) }
					mCustomCharacteristic?.getAllPacketsComplete = { successful in self.getAllPacketsComplete?(self.id, successful) }
					mCustomCharacteristic?.getNextPacketComplete = { successful, packet in self.getNextPacketComplete?(self.id, successful, packet) }
					mCustomCharacteristic?.getPacketCountComplete = { successful, count in self.getPacketCountComplete?(self.id, successful, count) }
					mCustomCharacteristic?.disableWornDetectComplete = { successful in self.disableWornDetectComplete?(self.id, successful) }
					mCustomCharacteristic?.enableWornDetectComplete = { successful in self.enableWornDetectComplete?(self.id, successful) }
					mCustomCharacteristic?.dataPackets = { packets in self.dataPackets?(self.id, packets) }
					mCustomCharacteristic?.dataComplete = { bad_fw_read_count, bad_fw_parse_count, overflow_count, bad_sdk_parse_count in self.dataComplete?(self.id, bad_fw_read_count, bad_fw_parse_count, overflow_count, bad_sdk_parse_count) }
					mCustomCharacteristic?.dataFailure = { self.dataFailure?(self.id) }
					mCustomCharacteristic?.deviceWornStatus = { isWorn in
						if (isWorn) { self.wornStatus = "Worn" }
						else { self.wornStatus = "Not Worn" }
						self.deviceWornStatus?(self.id, isWorn)
					}
					mCustomCharacteristic?.setSessionParamComplete = { successful, parameter in self.setSessionParamComplete?(self.id, successful, parameter) }
					mCustomCharacteristic?.getSessionParamComplete = { successful, parameter, value in self.getSessionParamComplete?(self.id, successful, parameter, value) }
					mCustomCharacteristic?.acceptSessionParamsComplete	= { successful in self.acceptSessionParamsComplete?(self.id, successful) }
					mCustomCharacteristic?.resetSessionParamsComplete	= { successful in self.resetSessionParamsComplete?(self.id, successful) }
					mCustomCharacteristic?.manufacturingTestComplete	= { successful in self.manufacturingTestComplete?(self.id, successful) }
					mCustomCharacteristic?.manufacturingTestResult		= { valid, result in self.manufacturingTestResult?(self.id, valid, result)}
					mCustomCharacteristic?.deviceChargingStatus			= { charging, on_charger, error in
						if (charging) { self.chargingStatus	= "Charging" }
						else if (on_charger) { self.chargingStatus = "On Charger" }
						else if (error) { self.chargingStatus = "Charging Error" }
						else { self.chargingStatus = "Not Charging" }
						self.deviceChargingStatus?(self.id, charging, on_charger, error) }
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
				if let service = characteristic.service {
					log?.e ("\(self.id) for service: \(service.prettyID) - \(characteristic.prettyID) - UNKNOWN")
				}
				else {
					log?.e ("\(self.id) for nil service - \(characteristic.prettyID) - UNKNOWN")
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
	//
	//
	//--------------------------------------------------------------------------------
	func didDiscoverDescriptor (_ descriptor: CBDescriptor, forCharacteristic characteristic: CBCharacteristic) {
		if let standardDescriptor = org_bluetooth_descriptor(rawValue: descriptor.prettyID) {
			switch (standardDescriptor) {
			case .client_characteristic_configuration:
				if let enumerated = Device.characteristics(rawValue: characteristic.prettyID) {
					log?.v ("\(self.id): \(standardDescriptor.title) '\(enumerated.title)'")
					switch (enumerated) {
					#if UNIVERSAL || ETHOS
					case .ethosCharacteristic		: mCustomCharacteristic?.didDiscoverDescriptor()
					#endif

					#if UNIVERSAL || ALTER
					case .alterCharacteristic		: mCustomCharacteristic?.didDiscoverDescriptor()
					#endif

					#if UNIVERSAL || ETHOS || ALTER
					case .ambiqOTARXCharacteristic	: log?.e ("\(self.id) '\(enumerated.title)' - should not be here")
					case .ambiqOTATXCharacteristic	: mAmbiqOTATXCharacteristic?.didDiscoverDescriptor()
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
						log?.e ("\(self.id) '\(enumerated.title)' - don't know what to do")
					}
				}
				
			case .characteristic_user_description:
				break

			default:
				log?.e ("\(self.id) for characteristic: \(characteristic.prettyID) - '\(standardDescriptor.title)'.  Do not know what to do - skipping")
			}
		}
		else {
			log?.e ("\(self.id) for characteristic \(characteristic.prettyID): \(descriptor.prettyID) - do not know what to do")
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
		if let enumerated = org_bluetooth_characteristic(rawValue: characteristic.prettyID) {
			switch (enumerated) {
			case .model_number_string		: mModelNumber?.didUpdateValue()
			case .hardware_revision_string	: mHardwareRevision?.didUpdateValue()
			case .firmware_revision_string	:
				mFirmwareVersion?.didUpdateValue()
				
			case .manufacturer_name_string	: mManufacturerName?.didUpdateValue()
			case .serial_number_string		: mSerialNumber?.didUpdateValue()
			case .battery_level				: mBatteryLevelCharacteristic?.didUpdateValue()
			case .body_sensor_location:
				if let value = characteristic.value {
					log?.v ("\(self.id): '\(enumerated.title)' - \(value.hexString)")
				}
				else { log?.e ("No valid \(enumerated.title) data!") }
			default:
				log?.e ("\(self.id) for characteristic: '\(enumerated.title)' - do not know what to do")
			}
		}
		else if let enumerated = Device.characteristics(rawValue: characteristic.prettyID) {
			switch (enumerated) {
			#if UNIVERSAL || ETHOS
			case .ethosCharacteristic		: mCustomCharacteristic?.didUpdateValue()
			#endif

			#if UNIVERSAL || ALTER
			case .alterCharacteristic		: mCustomCharacteristic?.didUpdateValue()
			#endif

			#if UNIVERSAL || ETHOS || ALTER
			case .ambiqOTARXCharacteristic	: log?.e ("\(self.id) '\(enumerated.title)' - should not be here")
			case .ambiqOTATXCharacteristic	:
				// Commands to RX come in on TX, causes RX to do next step
				if let value = characteristic.value {
					mAmbiqOTARXCharacteristic?.didUpdateTXValue(value)
				}
				else {
					log?.e ("\(self.id) '\(enumerated.title)' - No data received for RX command")
				}
			#endif
			
			#if UNIVERSAL || LIVOTAL
			case .livotalCharacteristic		: mCustomCharacteristic?.didUpdateValue()
			case .nordicDFUCharacteristic	: mNordicDFUCharacteristic?.didUpdateValue()
			#endif
			}
		}
		else {
			log?.v ("\(self.id) for characteristic: \(characteristic.prettyID)")
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
					log?.v ("\(self.id): '\(enumerated.title)'")
					
					switch (enumerated) {
					#if UNIVERSAL || ETHOS
					case .ethosCharacteristic		: mCustomCharacteristic?.didUpdateNotificationState()
					#endif

					#if UNIVERSAL || ALTER
					case .alterCharacteristic		: mCustomCharacteristic?.didUpdateNotificationState()
					#endif

					#if UNIVERSAL || ETHOS || ALTER
					case .ambiqOTARXCharacteristic	: log?.e ("\(self.id) '\(enumerated.title)' - should not be here")
					case .ambiqOTATXCharacteristic	: mAmbiqOTATXCharacteristic?.didUpdateNotificationState()
					#endif

					#if UNIVERSAL || LIVOTAL
					case .livotalCharacteristic		: mCustomCharacteristic?.didUpdateNotificationState()
					case .nordicDFUCharacteristic	: mNordicDFUCharacteristic?.didUpdateNotificationState()
					#endif
					}
				}
				else if let enumerated = org_bluetooth_characteristic(rawValue: characteristic.prettyID) {
					log?.v ("\(self.id): '\(enumerated.title)'")
					
					switch (enumerated) {
					case .battery_level		: mBatteryLevelCharacteristic?.didUpdateNotificationState()
					default					: log?.e ("\(self.id): '\(enumerated.title)'.  Do not know what to do - skipping")
					}
				}
				else {
					log?.e ("\(self.id): \(characteristic.prettyID) - do not know what to do")
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
		mAmbiqOTARXCharacteristic?.isReady()
		#endif
	}

}
