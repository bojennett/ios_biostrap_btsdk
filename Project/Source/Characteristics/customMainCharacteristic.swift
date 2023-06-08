//
//  customMainCharacteristic.swift
//  biostrapDeviceSDK
//
//  Created by Joseph A. Bennett on 5/12/21.
//

import Foundation
import CoreBluetooth
import zlib

class customMainCharacteristic: Characteristic {
	
	#if UNIVERSAL
	var type:	biostrapDeviceSDK.biostrapDeviceType	= .unknown
	#endif
	
	// MARK: Enumerations
	enum commands: UInt8 {
		case writeEpoch					= 0x00
		case getAllPackets				= 0x01
		case getNextPacket				= 0x02
		case getPacketCount				= 0x03
		case validateCRC				= 0x04
		case led						= 0x10
		case enterShipMode				= 0x11
		case readEpoch					= 0x12
		case endSleep					= 0x13
		#if UNIVERSAL || ETHOS
		case motor						= 0x14
		case debug						= 0x20
		#endif

		#if UNIVERSAL || ALTER || KAIROS || ETHOS
		case setAskForButtonResponse	= 0x50
		case getAskForButtonResponse	= 0x51
		case setHRZoneColor				= 0x60
		case getHRZoneColor				= 0x61
		case setHRZoneRange				= 0x62
		case getHRZoneRange				= 0x63
		case getPPGAlgorithm			= 0x64
		case setAdvertiseAsHRM			= 0x65
		case getAdvertiseAsHRM			= 0x66
		case setButtonCommand			= 0x67
		case getButtonCommand			= 0x68
		#endif
		
		case setDeviceParam				= 0x70
		case getDeviceParam				= 0x71
		case delDeviceParam				= 0x72
		case setSessionParam			= 0x80
		case getSessionParam			= 0x81
		case recalibratePPG				= 0xed
		
		#if UNIVERSAL || ETHOS
		case startLiveSync				= 0xee
		case stopLiveSync				= 0xef
		#endif
		
		#if UNIVERSAL || ALTER || KAIROS || ETHOS
		case airplaneMode				= 0xf4
		#endif
		
		case getRawLoggingStatus		= 0xf5
		case getWornOverrideStatus		= 0xf6
		case manufacturingTest			= 0xf7
		case allowPPG					= 0xf8
		case wornCheck					= 0xf9
		case logRaw						= 0xfa
		case disableWornDetect			= 0xfb
		case enableWornDetect			= 0xfc
		case startManual				= 0xfd
		case stopManual					= 0xfe
		case reset						= 0xff
	}
		
	enum wornResult: UInt8 {
		case broken						= 0x00
		case busy						= 0x01
		case ran						= 0x02
		
		var message: String {
			switch (self) {
			case .broken	: return "PPG cannot initialize"
			case .busy		: return "PPG is busy with another operation"
			case .ran		: return "Ran successfully"
			}
		}
	}
	
	// MARK: Callbacks
	var writeEpochComplete: ((_ successful: Bool)->())?
	var getAllPacketsComplete: ((_ successful: Bool)->())?
	var getNextPacketComplete: ((_ successful: Bool, _ error: nextPacketStatusType, _ caughtUp: Bool, _ packet: String)->())?
	var getPacketCountComplete: ((_ successful: Bool, _ count: Int)->())?
	var startManualComplete: ((_ successful: Bool)->())?
	var stopManualComplete: ((_ successful: Bool)->())?
	var ledComplete: ((_ successful: Bool)->())?
	#if UNIVERSAL || ETHOS
	var motorComplete: ((_ successful: Bool)->())?
	#endif
	var enterShipModeComplete: ((_ successful: Bool)->())?

	var writeSerialNumberComplete: ((_ successful: Bool)->())?
	var readSerialNumberComplete: ((_ successful: Bool, _ partID: String)->())?
	var deleteSerialNumberComplete: ((_ successful: Bool)->())?
	var writeAdvIntervalComplete: ((_ successful: Bool)->())?
	var readAdvIntervalComplete: ((_ successful: Bool, _ seconds: Int)->())?
	var deleteAdvIntervalComplete: ((_ successful: Bool)->())?
	var clearChargeCyclesComplete: ((_ successful: Bool)->())?
	var readCanLogDiagnosticsComplete: ((_ successful: Bool, _ allow: Bool)->())?
	var updateCanLogDiagnosticsComplete: ((_ successful: Bool)->())?

	var readChargeCyclesComplete: ((_ successful: Bool, _ cycles: Float)->())?
	var rawLoggingComplete: ((_ successful: Bool)->())?
	var allowPPGComplete: ((_ successful: Bool)->())?
	var wornCheckComplete: ((_ successful: Bool, _ type: String, _ value: Int)->())?
	var resetComplete: ((_ successful: Bool)->())?
	var readEpochComplete: ((_ successful: Bool, _ value: Int)->())?
	var disableWornDetectComplete: ((_ successful: Bool)->())?
	var enableWornDetectComplete: ((_ successful: Bool)->())?
	var endSleepComplete: ((_ successful: Bool)->())?
	var manufacturingTestComplete: ((_ successful: Bool)->())?

	var deviceWornStatus: ((_ isWorn: Bool)->())?
	var deviceChargingStatus: ((_ charging: Bool, _ on_charger: Bool, _ error: Bool)->())?
	var ppgMetrics: ((_ successful: Bool, _ packet: String)->())?
	var ppgFailed: ((_ code: Int)->())?
	var manufacturingTestResult: ((_ valid: Bool, _ result: String)->())?

	#if UNIVERSAL || ALTER || KAIROS || ETHOS
	var endSleepStatus: ((_ hasSleep: Bool)->())?
	var buttonClicked: ((_ presses: Int)->())?
	#endif
	
	#if UNIVERSAL || ETHOS
	var debugComplete: ((_ successful: Bool, _ device: debugDevice, _ data: Data)->())?
	#endif

	#if UNIVERSAL || ALTER || KAIROS || ETHOS
	var setAskForButtonResponseComplete: ((_ successful: Bool, _ enable: Bool)->())?
	var getAskForButtonResponseComplete: ((_ successful: Bool, _ enable: Bool)->())?
	var setHRZoneColorComplete: ((_ successful: Bool, _ type: hrZoneRangeType)->())?
	var getHRZoneColorComplete: ((_ successful: Bool, _ type: hrZoneRangeType, _ red: Bool, _ green: Bool, _ blue: Bool, _ on_ms: Int, _ off_ms: Int)->())?
	var setHRZoneRangeComplete: ((_ successful: Bool)->())?
	var getHRZoneRangeComplete: ((_ successful: Bool, _ enabled: Bool, _ high_value: Int, _ low_value: Int)->())?
	var getPPGAlgorithmComplete: ((_ successful: Bool, _ algorithm: ppgAlgorithmConfiguration, _ state: eventType)->())?
	var setAdvertiseAsHRMComplete: ((_ successful: Bool, _ asHRM: Bool)->())?
	var getAdvertiseAsHRMComplete: ((_ successful: Bool, _ asHRM: Bool)->())?
	var setButtonCommandComplete: ((_ successful: Bool, _ tap: buttonTapType, _ command: buttonCommandType)->())?
	var getButtonCommandComplete: ((_ successful: Bool, _ tap: buttonTapType, _ command: buttonCommandType)->())?
	#endif

	var dataPackets: ((_ packets: String)->())?
	var dataComplete: ((_ bad_fw_read_count: Int, _ bad_fw_parse_count: Int, _ overflow_count: Int, _ bad_sdk_parse_count: Int)->())?
	var dataFailure: (()->())?
		
	var recalibratePPGComplete: ((_ successful: Bool)->())?

	#if UNIVERSAL || ETHOS
	var startLiveSyncComplete: ((_ successful: Bool)->())?
	var stopLiveSyncComplete: ((_ successful: Bool)->())?
	#endif
	
	var setSessionParamComplete: ((_ successful: Bool, _ parameter: sessionParameterType)->())?
	var getSessionParamComplete: ((_ successful: Bool, _ parameter: sessionParameterType, _ value: Int)->())?
	var resetSessionParamsComplete: ((_ successful: Bool)->())?
	var acceptSessionParamsComplete: ((_ successful: Bool)->())?
	
	var getRawLoggingStatusComplete: ((_ successful: Bool, _ enabled: Bool)->())?
	var getWornOverrideStatusComplete: ((_ successful: Bool, _ overridden: Bool)->())?
	
	#if UNIVERSAL || ALTER || KAIROS || ETHOS
	var airplaneModeComplete: ((_ successful: Bool)->())?
	#endif
		
	var firmwareVersion						: String = ""
	
	internal var mDataPackets				: [biostrapDataPacket]!
	internal var mCRCOK						: Bool = true
	internal var mExpectedSequenceNumber	: Int = 0
	internal var mCRCFailCount				: Int = 0
	internal var mFailedDecodeCount			: Int = 0
	
	//--------------------------------------------------------------------------------
	//
	// Test Struct.  This lets things happen a certain number of times where it fails
	// until you hit the limit, then it succeeds
	//
	//--------------------------------------------------------------------------------
	struct testStruct {
		var name		: String
		var enable		: Bool
		var count		: Int
		var limit		: Int
		
		init() {
			name		= "Unknown"
			enable		= false
			count		= 0
			limit		= 2
		}
		
		init(name: String, enable: Bool, limit: Int) {
			self.name	= name
			self.enable	= enable
			self.count	= 0
			self.limit	= limit
		}
		
		mutating func check() -> Bool {
			if (enable == false) {
				//log?.v ("\(name): Not testing - allow")
				return true
			}
			
			count = count + 1
			if (count >= limit) {
				log?.v ("\(name): At limit - allow")
				count	= 0
				return true
			}
			else {
				log?.v ("\(name): Not at limit - disallow \(count) != \(limit)")
				return false
			}
		}
	}
	
	internal var mCRCIgnoreTest				: testStruct
	internal var mCRCFailTest				: testStruct
	
	//--------------------------------------------------------------------------------
	//
	// Constructor
	//
	//--------------------------------------------------------------------------------
	override init(_ peripheral: CBPeripheral, characteristic: CBCharacteristic) {
		mCRCIgnoreTest	= testStruct(name: "CRC Ignore", enable: false, limit: 3)
		mCRCFailTest	= testStruct(name: "CRC Fail", enable: false, limit: 3)
		
		mCRCOK					= false
		mExpectedSequenceNumber	= 0
		mCRCFailCount			= 0

		super.init(peripheral, characteristic: characteristic)
		
		mDataPackets = [biostrapDataPacket]()
		
	}
	
	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func writeEpoch(_ newEpoch: Int) {
		log?.v("\(pID): \(newEpoch)")

		if let peripheral = pPeripheral, let characteristic = pCharacteristic {
			var data = Data()
			data.append(commands.writeEpoch.rawValue)
			data.append(newEpoch.leData32)
			peripheral.writeValue(data, for: characteristic, type: .withResponse)
		}
		else { self.writeEpochComplete?(false) }
	}
	
	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func readEpoch() {
		log?.v("\(pID)")

		if let peripheral = pPeripheral, let characteristic = pCharacteristic {
			var data = Data()
			data.append(commands.readEpoch.rawValue)

			peripheral.writeValue(data, for: characteristic, type: .withResponse)
		}
		else { self.readEpochComplete?(false, 0) }
	}
	
	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func endSleep() {
		log?.v("\(pID)")

		if let peripheral = pPeripheral, let characteristic = pCharacteristic {
			var data = Data()
			data.append(commands.endSleep.rawValue)

			peripheral.writeValue(data, for: characteristic, type: .withResponse)
		}
		else { self.endSleepComplete?(false) }
	}
	
	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	#if UNIVERSAL || ETHOS
	func debug(_ device: debugDevice, data: Data) {
		log?.v("\(pID): \(device.name) -> \(data.hexString)")

		if let peripheral = pPeripheral, let characteristic = pCharacteristic {
			var commandData = Data()
			commandData.append(commands.debug.rawValue)
			commandData.append(device.rawValue)
			commandData.append(contentsOf: data)
			
			peripheral.writeValue(commandData, for: characteristic, type: .withResponse)
		}
		else { self.debugComplete?(false, device, Data()) }
	}
	#endif
	
	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	internal func mSimpleCommand(_ command: commands) -> Bool {
		if let peripheral = pPeripheral, let characteristic = pCharacteristic {
			var data = Data()
			data.append(command.rawValue)
			
			peripheral.writeValue(data, for: characteristic, type: .withResponse)
			return (true)
		}
		else { return false }
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func getNextPacket(_ single: Bool) {
		log?.v("\(pID): Single? \(single)")

		if let peripheral = pPeripheral, let characteristic = pCharacteristic {
			var data = Data()
			data.append(commands.getNextPacket.rawValue)
			data.append(single ? 0x01 : 0x00)

			peripheral.writeValue(data, for: characteristic, type: .withResponse)
		}
		else { self.getNextPacketComplete?(false, .missingDevice, true, "") }
	}
	
	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func getAllPackets() {
		log?.v("\(pID)")

		mFailedDecodeCount	= 0
		
		if (!mSimpleCommand(.getAllPackets)) { self.getAllPacketsComplete?(false) }
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func getPacketCount() {
		log?.v("\(pID)")

		if (!mSimpleCommand(.getPacketCount)) { self.getPacketCountComplete?(false, 0) }
	}
	
	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func disableWornDetect() {
		log?.v("\(pID)")

		if (!mSimpleCommand(.disableWornDetect)) { self.disableWornDetectComplete?(false) }
	}
	
	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func enableWornDetect() {
		log?.v("\(pID)")

		if (!mSimpleCommand(.enableWornDetect)) { self.enableWornDetectComplete?(false) }
	}
	
	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func startManual(_ algorithms: ppgAlgorithmConfiguration) {
		log?.v("\(pID)")
		
		if let peripheral = pPeripheral, let characteristic = pCharacteristic {
			var data = Data()
			data.append(commands.startManual.rawValue)
			data.append(algorithms.commandByte)

			peripheral.writeValue(data, for: characteristic, type: .withResponse)
		}
		else { self.startManualComplete?(false) }
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func stopManual() {
		log?.v("\(pID)")
		
		if (!mSimpleCommand(.stopManual)) { self.stopManualComplete?(false) }
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	#if UNIVERSAL || LIVOTAL
	func livotalLED(red: Bool, green: Bool, blue: Bool, blink: Bool, seconds: Int) {
		log?.v("\(pID): Red: \(red), Green: \(green), Blue: \(blue), Blink: \(blink), Seconds: \(seconds)")
		
		if let peripheral = pPeripheral, let characteristic = pCharacteristic {
			var data = Data()
			data.append(commands.led.rawValue)
			data.append(red ? 0x01 : 0x00)		// Red
			data.append(green ? 0x01 : 0x00)	// Green
			data.append(blue ? 0x01 : 0x00)		// Blue
			data.append(blink ? 0x01 : 0x00)	// Blink
			data.append(UInt8(seconds & 0xff))	// Seconds

			peripheral.writeValue(data, for: characteristic, type: .withResponse)
		}
		else { self.ledComplete?(false) }
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
	func ethosLED(red: Int, green: Int, blue: Int, mode: biostrapDeviceSDK.ethosLEDMode, seconds: Int, percent: Int) {
		log?.v("\(pID): Red: \(String(format: "0x%02X", red)), Green: \(String(format: "0x%02X", green)), Blue: \(String(format: "0x%02X", blue)), Mode: \(mode.title), Seconds: \(seconds), Percent: \(percent)")
		
		if let peripheral = pPeripheral, let characteristic = pCharacteristic {
			var data = Data()
			data.append(commands.led.rawValue)
			data.append(UInt8(red & 0xff))		// Red
			data.append(UInt8(green & 0xff))	// Green
			data.append(UInt8(blue & 0xff))		// Blue
			data.append(UInt8(mode.value))		// Mode
			data.append(UInt8(seconds & 0xff))	// Seconds
			data.append(UInt8(percent & 0xff))	// Percent

			peripheral.writeValue(data, for: characteristic, type: .withResponse)
		}
		else { self.ledComplete?(false) }
	}
	#endif
		
	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	#if UNIVERSAL || ALTER
	func alterLED(red: Bool, green: Bool, blue: Bool, blink: Bool, seconds: Int) {
		log?.v("\(pID): Red: \(red), Green: \(green), Blue: \(blue), Blink: \(blink), Seconds: \(seconds)")
		
		if let peripheral = pPeripheral, let characteristic = pCharacteristic {
			var data = Data()
			data.append(commands.led.rawValue)
			data.append(red ? 0x01 : 0x00)		// Red
			data.append(green ? 0x01 : 0x00)	// Green
			data.append(blue ? 0x01 : 0x00)		// Blue
			data.append(blink ? 0x01 : 0x00)	// Blink
			data.append(UInt8(seconds & 0xff))	// Seconds

			peripheral.writeValue(data, for: characteristic, type: .withResponse)
		}
		else { self.ledComplete?(false) }
	}
	#endif

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	#if UNIVERSAL || KAIROS
	func kairosLED(red: Bool, green: Bool, blue: Bool, blink: Bool, seconds: Int) {
		log?.v("\(pID): Red: \(red), Green: \(green), Blue: \(blue), Blink: \(blink), Seconds: \(seconds)")
		
		if let peripheral = pPeripheral, let characteristic = pCharacteristic {
			var data = Data()
			data.append(commands.led.rawValue)
			data.append(red ? 0x01 : 0x00)		// Red
			data.append(green ? 0x01 : 0x00)	// Green
			data.append(blue ? 0x01 : 0x00)		// Blue
			data.append(blink ? 0x01 : 0x00)	// Blink
			data.append(UInt8(seconds & 0xff))	// Seconds
			
			peripheral.writeValue(data, for: characteristic, type: .withResponse)
		}
		else { self.ledComplete?(false) }
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
	func motor(milliseconds: Int, pulses: Int) {
		log?.v("\(pID): milliseconds: \(milliseconds), pulses: \(pulses)")
		
		if let peripheral = pPeripheral, let characteristic = pCharacteristic {
			var data = Data()
			data.append(commands.motor.rawValue)
			data.append(contentsOf: milliseconds.leData32)
			data.append(UInt8(pulses & 0xff))

			peripheral.writeValue(data, for: characteristic, type: .withResponse)
		}
		else { self.motorComplete?(false) }
	}
	#endif

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func enterShipMode() {
		log?.v("\(pID)")
		
		if let peripheral = pPeripheral, let characteristic = pCharacteristic {
			var data = Data()
			data.append(commands.enterShipMode.rawValue)
			peripheral.writeValue(data, for: characteristic, type: .withResponse)
		}
		else { self.enterShipModeComplete?(false) }
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func writeSerialNumber(_ partID: String) {
		log?.v("\(pID): \(partID)")
		
		if let peripheral = pPeripheral, let characteristic = pCharacteristic {
			var data = Data()
			data.append(commands.setDeviceParam.rawValue)
			data.append(deviceParameterType.serialNumber.rawValue)
			data.append(contentsOf: [UInt8](partID.utf8))
			
			log?.v ("\(data.hexString)")

			peripheral.writeValue(data, for: characteristic, type: .withResponse)
		}
		else { self.writeSerialNumberComplete?(false) }
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func readSerialNumber() {
		log?.v("\(pID)")
		
		if let peripheral = pPeripheral, let characteristic = pCharacteristic {
			var data = Data()
			data.append(commands.getDeviceParam.rawValue)
			data.append(deviceParameterType.serialNumber.rawValue)
			peripheral.writeValue(data, for: characteristic, type: .withResponse)
		}
		else { self.readSerialNumberComplete?(false, "") }
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func deleteSerialNumber() {
		log?.v("\(pID)")
		
		if let peripheral = pPeripheral, let characteristic = pCharacteristic {
			var data = Data()
			data.append(commands.delDeviceParam.rawValue)
			data.append(deviceParameterType.serialNumber.rawValue)
			peripheral.writeValue(data, for: characteristic, type: .withResponse)
		}
		else { self.deleteSerialNumberComplete?(false) }
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func writeAdvInterval(_ seconds: Int) {
		log?.v("\(pID): \(seconds)")
		
		if let peripheral = pPeripheral, let characteristic = pCharacteristic {
			var data = Data()
			data.append(commands.setDeviceParam.rawValue)
			data.append(deviceParameterType.advertisingInterval.rawValue)
			data.append(contentsOf: seconds.leData32)
			
			log?.v ("\(data.hexString)")

			peripheral.writeValue(data, for: characteristic, type: .withResponse)
		}
		else { self.writeAdvIntervalComplete?(false) }
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func readAdvInterval() {
		log?.v("\(pID)")
		
		if let peripheral = pPeripheral, let characteristic = pCharacteristic {
			var data = Data()
			data.append(commands.getDeviceParam.rawValue)
			data.append(deviceParameterType.advertisingInterval.rawValue)
			peripheral.writeValue(data, for: characteristic, type: .withResponse)
		}
		else { self.readAdvIntervalComplete?(false, 0) }
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func deleteAdvInterval() {
		log?.v("\(pID)")
		
		if let peripheral = pPeripheral, let characteristic = pCharacteristic {
			var data = Data()
			data.append(commands.delDeviceParam.rawValue)
			data.append(deviceParameterType.advertisingInterval.rawValue)
			peripheral.writeValue(data, for: characteristic, type: .withResponse)
		}
		else { self.deleteAdvIntervalComplete?(false) }
	}
	
	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func clearChargeCycles() {
		log?.v("\(pID)")
		
		if let peripheral = pPeripheral, let characteristic = pCharacteristic {
			var data = Data()
			data.append(commands.setDeviceParam.rawValue)
			data.append(deviceParameterType.chargeCycle.rawValue)
			peripheral.writeValue(data, for: characteristic, type: .withResponse)
		}
		else { self.clearChargeCyclesComplete?(false) }
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func readChargeCycles() {
		log?.v("\(pID)")
		
		if let peripheral = pPeripheral, let characteristic = pCharacteristic {
			var data = Data()
			data.append(commands.getDeviceParam.rawValue)
			data.append(deviceParameterType.chargeCycle.rawValue)
			peripheral.writeValue(data, for: characteristic, type: .withResponse)
		}
		else { self.readChargeCyclesComplete?(false, 0.0) }
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func readCanLogDiagnostics() {
		log?.v("\(pID)")
		
		if let peripheral = pPeripheral, let characteristic = pCharacteristic {
			var data = Data()
			data.append(commands.getDeviceParam.rawValue)
			data.append(deviceParameterType.canLogDiagnostics.rawValue)
			peripheral.writeValue(data, for: characteristic, type: .withResponse)
		}
		else { self.readCanLogDiagnosticsComplete?(false, false) }
	}
	
	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func updateCanLogDiagnostics(_ allow: Bool) {
		log?.v("\(pID): Allow Diagnostics? \(allow)")
		
		if let peripheral = pPeripheral, let characteristic = pCharacteristic {
			var data = Data()
			data.append(commands.setDeviceParam.rawValue)
			data.append(deviceParameterType.canLogDiagnostics.rawValue)
			data.append(allow ? 0x01 : 0x00)
			
			log?.v ("\(data.hexString)")

			peripheral.writeValue(data, for: characteristic, type: .withResponse)
		}
		else { self.updateCanLogDiagnosticsComplete?(false) }
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func allowPPG(_ allow: Bool) {
		log?.v("\(pID)")
		
		if let peripheral = pPeripheral, let characteristic = pCharacteristic {
			var data = Data()
			data.append(commands.allowPPG.rawValue)
			data.append(allow ? 0x01 : 0x00)
			peripheral.writeValue(data, for: characteristic, type: .withResponse)
		}
		else { self.allowPPGComplete?(false) }
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func wornCheck() {
		log?.v("\(pID)")
		
		if let peripheral = pPeripheral, let characteristic = pCharacteristic {
			var data = Data()
			data.append(commands.wornCheck.rawValue)
			peripheral.writeValue(data, for: characteristic, type: .withResponse)
		}
		else { self.wornCheckComplete?(false, "No device", 0) }
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func rawLogging(_ enable: Bool) {
		log?.v("\(pID): \(enable)")
		
		if let peripheral = pPeripheral, let characteristic = pCharacteristic {
			var data = Data()
			data.append(commands.logRaw.rawValue)
			data.append(enable ? 0x01 : 0x00)
			peripheral.writeValue(data, for: characteristic, type: .withResponse)
		}
		else { self.rawLoggingComplete?(false) }
	}
	
	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func getRawLoggingStatus() {
		log?.v("\(pID)")
		
		if let peripheral = pPeripheral, let characteristic = pCharacteristic {
			var data = Data()
			data.append(commands.getRawLoggingStatus.rawValue)
			peripheral.writeValue(data, for: characteristic, type: .withResponse)
		}
		else { self.getRawLoggingStatusComplete?(false, false) }
	}
	
	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func getWornOverrideStatus() {
		log?.v("\(pID)")
		
		if let peripheral = pPeripheral, let characteristic = pCharacteristic {
			var data = Data()
			data.append(commands.getWornOverrideStatus.rawValue)
			peripheral.writeValue(data, for: characteristic, type: .withResponse)
		}
		else { self.getWornOverrideStatusComplete?(false, false) }
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	#if UNIVERSAL || ALTER || KAIROS || ETHOS
	func airplaneMode() {
		log?.v("\(pID)")
		
		if (!mSimpleCommand(.airplaneMode)) { self.airplaneModeComplete?(false) }
	}
	#endif

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func reset() {
		log?.v("\(pID)")

		if (!mSimpleCommand(.reset)) { self.resetComplete?(false) }
	}
	
	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func setSessionParam(_ parameter: sessionParameterType, value: Int) {
		log?.v("\(pID): \(parameter) - \(value)")
		
		if let peripheral = pPeripheral, let characteristic = pCharacteristic {
			var data = Data()
			data.append(commands.setSessionParam.rawValue)
			data.append(parameter.rawValue)
			data.append(value.leData32)
			peripheral.writeValue(data, for: characteristic, type: .withResponse)
		}
		else { self.setSessionParamComplete?(false, parameter) }
	}
	
	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func getSessionParam(_ parameter: sessionParameterType) {
		log?.v("\(pID): \(parameter)")
		
		if let peripheral = pPeripheral, let characteristic = pCharacteristic {
			var data = Data()
			data.append(commands.getSessionParam.rawValue)
			data.append(parameter.rawValue)
			peripheral.writeValue(data, for: characteristic, type: .withResponse)
		}
		else { self.getSessionParamComplete?(false, parameter, 0) }
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func resetSessionParams() {
		log?.v("\(pID)")
		
		if let peripheral = pPeripheral, let characteristic = pCharacteristic {
			var data = Data()
			data.append(commands.setSessionParam.rawValue)
			data.append(sessionParameterType.reset.rawValue)
			peripheral.writeValue(data, for: characteristic, type: .withResponse)
		}
		else { self.resetSessionParamsComplete?(false) }
	}
	
	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func acceptSessionParams() {
		log?.v("\(pID)")
		
		if let peripheral = pPeripheral, let characteristic = pCharacteristic {
			var data = Data()
			data.append(commands.setSessionParam.rawValue)
			data.append(sessionParameterType.accept.rawValue)
			peripheral.writeValue(data, for: characteristic, type: .withResponse)
		}
		else { self.acceptSessionParamsComplete?(false) }
	}

	//--------------------------------------------------------------------------------
	// Function Name: Manufacturing Test
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	#if LIVOTAL || UNIVERSAL
	func livotalManufacturingTest() {
		log?.v("\(pID)")
		
		if let peripheral = pPeripheral, let characteristic = pCharacteristic {
			var data = Data()
			data.append(commands.manufacturingTest.rawValue)
			peripheral.writeValue(data, for: characteristic, type: .withResponse)
		}
		else { self.manufacturingTestComplete?(false) }
	}
	#endif

	#if UNIVERSAL || ETHOS
	func ethosManufacturingTest(_ test: ethosManufacturingTestType) {
		log?.v("\(pID): \(test.title)")
		
		if let peripheral = pPeripheral, let characteristic = pCharacteristic {
			var data = Data()
			data.append(commands.manufacturingTest.rawValue)
			data.append(test.rawValue)
			peripheral.writeValue(data, for: characteristic, type: .withResponse)
		}
		else { self.manufacturingTestComplete?(false) }
	}
	#endif

	#if UNIVERSAL || ALTER
	func alterManufacturingTest(_ test: alterManufacturingTestType) {
		log?.v("\(pID): \(test.title)")
		
		if let peripheral = pPeripheral, let characteristic = pCharacteristic {
			var data = Data()
			data.append(commands.manufacturingTest.rawValue)
			data.append(test.rawValue)
			peripheral.writeValue(data, for: characteristic, type: .withResponse)
		}
		else { self.manufacturingTestComplete?(false) }
	}
	#endif

	#if UNIVERSAL || KAIROS
	func kairosManufacturingTest(_ test: kairosManufacturingTestType) {
		log?.v("\(pID): \(test.title)")
		
		if let peripheral = pPeripheral, let characteristic = pCharacteristic {
			var data = Data()
			data.append(commands.manufacturingTest.rawValue)
			data.append(test.rawValue)
			peripheral.writeValue(data, for: characteristic, type: .withResponse)
		}
		else { self.manufacturingTestComplete?(false) }
	}
	#endif
	
	#if UNIVERSAL || ETHOS
	//--------------------------------------------------------------------------------
	// Function Name: Live Sync start and stop
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func startLiveSync(_ configuration: liveSyncConfiguration) {
		log?.v("\(pID): \(configuration.commandString) -> \(String(format: "0x%02X", configuration.commandByte))")
		
		if let peripheral = pPeripheral, let characteristic = pCharacteristic {
			var data = Data()
			data.append(commands.startLiveSync.rawValue)
			data.append(configuration.commandByte)
			peripheral.writeValue(data, for: characteristic, type: .withResponse)
		}
		else { self.startLiveSyncComplete?(false) }
	}
	
	func stopLiveSync() {
		log?.v("\(pID)")
		
		if let peripheral = pPeripheral, let characteristic = pCharacteristic {
			var data = Data()
			data.append(commands.stopLiveSync.rawValue)
			peripheral.writeValue(data, for: characteristic, type: .withResponse)
		}
		else { self.stopLiveSyncComplete?(false) }
	}
	#endif
	
	#if UNIVERSAL || ALTER || KAIROS || ETHOS
	//--------------------------------------------------------------------------------
	// Function Name: setAskForButtonResponse
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func setAskForButtonResponse(_ enable: Bool) {
		log?.v("\(pID): Enabled = \(enable)")
		
		if let peripheral = pPeripheral, let characteristic = pCharacteristic {
			var data = Data()
			data.append(commands.setAskForButtonResponse.rawValue)
			data.append(enable ? 0x01 : 0x00)
			peripheral.writeValue(data, for: characteristic, type: .withResponse)
		}
		else { self.setAskForButtonResponseComplete?(false, enable) }
	}
	
	//--------------------------------------------------------------------------------
	// Function Name: getAskForButtonResponse
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func getAskForButtonResponse() {
		log?.v("\(pID)")
		
		if let peripheral = pPeripheral, let characteristic = pCharacteristic {
			var data = Data()
			data.append(commands.getAskForButtonResponse.rawValue)
			peripheral.writeValue(data, for: characteristic, type: .withResponse)
		}
		else { self.getAskForButtonResponseComplete?(false, false) }
	}

	//--------------------------------------------------------------------------------
	// Function Name: setHRZoneColor
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func setHRZoneColor(_ type: hrZoneRangeType, red: Bool, green: Bool, blue: Bool, on_milliseconds: Int, off_milliseconds: Int) {
		log?.v("\(pID): \(type.title) -> R \(red), G \(green), B \(blue).  On: \(on_milliseconds), Off: \(off_milliseconds)")
		
		if let peripheral = pPeripheral, let characteristic = pCharacteristic {
			var data = Data()
			data.append(commands.setHRZoneColor.rawValue)
			data.append(type.rawValue)
			data.append(red ? 0x01 : 0x00)
			data.append(green ? 0x01 : 0x00)
			data.append(blue ? 0x01 : 0x00)
			data.append(UInt8((on_milliseconds >> 0) & 0xff))
			data.append(UInt8((on_milliseconds >> 8) & 0xff))
			data.append(UInt8((off_milliseconds >> 0) & 0xff))
			data.append(UInt8((off_milliseconds >> 8) & 0xff))
			peripheral.writeValue(data, for: characteristic, type: .withResponse)
		}
		else { self.setHRZoneColorComplete?(false, type) }
	}
	
	//--------------------------------------------------------------------------------
	// Function Name: getHRZoneColor
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func getHRZoneColor(_ type: hrZoneRangeType) {
		log?.v("\(pID): \(type.title)")
		
		if let peripheral = pPeripheral, let characteristic = pCharacteristic {
			var data = Data()
			data.append(commands.getHRZoneColor.rawValue)
			data.append(type.rawValue)
			peripheral.writeValue(data, for: characteristic, type: .withResponse)
		}
		else { self.getHRZoneColorComplete?(false, type, false, false, false, 0, 0) }
	}
	
	//--------------------------------------------------------------------------------
	// Function Name: setHRZoneRange
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func setHRZoneRange(_ enabled: Bool, high_value: Int, low_value: Int) {
		log?.v("\(pID): Enabled: \(enabled) -> High Value: \(high_value), Low Value: \(low_value)")
		
		if let peripheral = pPeripheral, let characteristic = pCharacteristic {
			var data = Data()
			data.append(commands.setHRZoneRange.rawValue)
			data.append(enabled ? 0x01 : 0x00)
			data.append(UInt8(high_value))
			data.append(UInt8(low_value))
			peripheral.writeValue(data, for: characteristic, type: .withResponse)
		}
		else { self.setHRZoneRangeComplete?(false) }
	}
	
	//--------------------------------------------------------------------------------
	// Function Name: getHRZoneRange
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func getHRZoneRange() {
		log?.v("\(pID)")
		
		if let peripheral = pPeripheral, let characteristic = pCharacteristic {
			var data = Data()
			data.append(commands.getHRZoneRange.rawValue)
			peripheral.writeValue(data, for: characteristic, type: .withResponse)
		}
		else { self.getHRZoneRangeComplete?(false, false, 0, 0) }
	}
	
	//--------------------------------------------------------------------------------
	// Function Name: getPPGAlgorithm
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func getPPGAlgorithm() {
		log?.v("\(pID)")
		
		if let peripheral = pPeripheral, let characteristic = pCharacteristic {
			var data = Data()
			data.append(commands.getPPGAlgorithm.rawValue)
			peripheral.writeValue(data, for: characteristic, type: .withResponse)
		}
		else { self.getPPGAlgorithmComplete?(false, ppgAlgorithmConfiguration(), eventType.unknown) }
	}

	//--------------------------------------------------------------------------------
	// Function Name: setAdvertiseAsHRM
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func setAdvertiseAsHRM(_ asHRM: Bool) {
		log?.v("\(pID): As HRM? (\(asHRM)")
		
		if let peripheral = pPeripheral, let characteristic = pCharacteristic {
			var data = Data()
			data.append(commands.setAdvertiseAsHRM.rawValue)
			data.append(asHRM ? 0x01 : 0x00)
			peripheral.writeValue(data, for: characteristic, type: .withResponse)
		}
		else { self.setAdvertiseAsHRMComplete?(false, false) }
	}

	//--------------------------------------------------------------------------------
	// Function Name: getAdvertiseAsHRM
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func getAdvertiseAsHRM() {
		log?.v("\(pID)")
		
		if let peripheral = pPeripheral, let characteristic = pCharacteristic {
			var data = Data()
			data.append(commands.getAdvertiseAsHRM.rawValue)
			peripheral.writeValue(data, for: characteristic, type: .withResponse)
		}
		else { self.getAdvertiseAsHRMComplete?(false, false) }
	}
	
	//--------------------------------------------------------------------------------
	// Function Name: setButtonCommand
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func setButtonCommand(_ tap: buttonTapType, command: buttonCommandType) {
		log?.v("\(pID): \(tap.title) -> \(command.title)")
		
		if let peripheral = pPeripheral, let characteristic = pCharacteristic {
			var data = Data()
			data.append(commands.setButtonCommand.rawValue)
			data.append(tap.rawValue)
			data.append(command.rawValue)
			peripheral.writeValue(data, for: characteristic, type: .withResponse)
		}
		else { self.setButtonCommandComplete?(false, tap, command) }
	}
	
	//--------------------------------------------------------------------------------
	// Function Name: getButtonCommand
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func getButtonCommand(_ tap: buttonTapType) {
		log?.v("\(pID): \(tap.title)")
		
		if let peripheral = pPeripheral, let characteristic = pCharacteristic {
			var data = Data()
			data.append(commands.getButtonCommand.rawValue)
			data.append(tap.rawValue)
			peripheral.writeValue(data, for: characteristic, type: .withResponse)
		}
		else { self.getButtonCommandComplete?(false, tap, .unknown) }
	}
	#endif

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func recalibratePPG() {
		log?.v("\(pID)")
		
		if let peripheral = pPeripheral, let characteristic = pCharacteristic {
			var data = Data()
			data.append(commands.recalibratePPG.rawValue)
			peripheral.writeValue(data, for: characteristic, type: .withResponse)
		}
		else { self.recalibratePPGComplete?(false) }

	}
	
	//--------------------------------------------------------------------------------
	// Function Name: Validate CRC
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	internal func mValidateCRC() {
		//log?.v("\(pID): \(mCRCOK)")
		
		if (mCRCOK == false) {
			mCRCFailCount	= mCRCFailCount + 1
			if (mCRCFailCount == 10) { dataFailure?() }
		}
		else { mCRCFailCount	= 0 }
		
		if let peripheral = pPeripheral, let characteristic = pCharacteristic {
			var data = Data()
			data.append(commands.validateCRC.rawValue)
			data.append(mCRCOK ? 0x01 : 0x00)
			peripheral.writeValue(data, for: characteristic, type: .withResponse)
		}
		else {
			log?.e ("\(pID): I can't run the validate CRC command.  I don't know what to do here")
		}
		
		mCRCOK				= true
	}
	
	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//def reconstruct(dataComp8Bit):
	//	reconstructedData = []
	//	reconstructedData.append(dataComp8Bit.dataOffset)
	//
	//	for counter in range(0,dataComp8Bit.compressionCount):
	//		sign = dataComp8Bit.bitwiseSign & (1 << counter)
	//		if sign != 0:
	//			sign = -1
	//		else:
	//			sign = 1
	//
	//		reconstructedData.append(reconstructedData[0] + sign*dataComp8Bit.dataPointer[counter])
	//
	//	return reconstructedData
	//
	//--------------------------------------------------------------------------------
	internal func mDecompressPPGPackets(_ data: Data) -> [biostrapDataPacket] {
		var packets				= [biostrapDataPacket]()
		if let packetType = packetType(rawValue: data[0]) {
			let compressionCount	= Int(data[1])
			let bitwiseSign			= data[2]
			
			let firstSample			= (Int(data[3]) << 0) | (Int(data[4]) << 8) | (Int(data[5]) << 16)
			let packet				= biostrapDataPacket()
			packet.value			= firstSample
			packet.type				= packetType
			packet.raw_data			= data
			packet.raw_data_string	= data.hexString.replacingOccurrences(of: "[ ", with: "").replacingOccurrences(of: " ]", with: "")

			packets.append(packet)
			
			var index		= 0
			while (index < compressionCount) {
				let negative			= ((bitwiseSign & (0x01 << index)) != 0)
				let sample				= Int(data[index + 6])
				let packet				= biostrapDataPacket()
				packet.type				= packetType
				packet.raw_data			= data
				packet.raw_data_string	= data.hexString.replacingOccurrences(of: "[ ", with: "").replacingOccurrences(of: " ]", with: "")

				if (negative) {
					packet.value	= firstSample - sample
				}
				else {
					packet.value	= firstSample + sample
				}
				
				packets.append(packet)
				index = index + 1
			}
		}
		
		return (packets)
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	// Similar to PPG.  Differences:
	//    * firstSample is 2 bytes and signed
	//    * bitwiseSign is 2 bytes (total of 15 possible samples)
	//
	//--------------------------------------------------------------------------------
	internal func mDecompressIMUPackets(_ data: Data) -> [biostrapDataPacket] {
		var packets				= [biostrapDataPacket]()
		if let packetType = packetType(rawValue: data[0]) {
			let compressionCount	= Int(data[1])
			let bitwiseSign			= data.subdata(in: Range(2...3)).leUInt16
			
			let firstSample			= data.subdata(in: Range(4...5)).leInt16
			let packet				= biostrapDataPacket()
			packet.value			= firstSample
			packet.raw_data			= data
			packet.raw_data_string	= data.hexString.replacingOccurrences(of: "[ ", with: "").replacingOccurrences(of: " ]", with: "")
			packet.type				= packetType
			
			packets.append(packet)
			
			var index		= 0
			while (index < compressionCount) {
				let negative			= ((bitwiseSign & (0x01 << index)) != 0)
				let sample				= Int(data[index + 6])
				let packet				= biostrapDataPacket()
				packet.type				= packetType
				packet.raw_data			= data
				packet.raw_data_string	= data.hexString.replacingOccurrences(of: "[ ", with: "").replacingOccurrences(of: " ]", with: "")

				if (negative) {
					packet.value	= firstSample - sample
				}
				else {
					packet.value	= firstSample + sample
				}
				
				packets.append(packet)
				index = index + 1
			}
		}
		
		return (packets)
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	internal func mParsePackets(_ data: Data) -> ([biostrapDataPacket]) {
		//log?.v ("\(pID): Data: \(data.hexString)")
		
		var index = 0
		var dataPackets = [biostrapDataPacket]()
		
		let incomingDataDiagnostic				= biostrapDataPacket()
		incomingDataDiagnostic.raw_data			= data
		incomingDataDiagnostic.raw_data_string	= data.hexString.replacingOccurrences(of: "[ ", with: "").replacingOccurrences(of: " ]", with: "")
		incomingDataDiagnostic.type				= packetType.diagnostic
		incomingDataDiagnostic.diagnostic_type	= diagnosticType.bluetoothPacket

		dataPackets.append(incomingDataDiagnostic)
		
		while (index < data.count) {
			let (found, type, packet) = pParseSinglePacket(data, index: index)

			if (found) {
				switch (type) {
				case .diagnostic:
					index = index + packet.raw_data.count
					dataPackets.append(packet)
					
				case .rawAccelCompressedXADC,
						.rawAccelCompressedYADC,
						.rawAccelCompressedZADC:
					index = index + packet.raw_data.count
					
					let packets = mDecompressIMUPackets(packet.raw_data)
					dataPackets.append(contentsOf: packets)
					
				case .rawPPGCompressedGreen,
					 .rawPPGCompressedIR,
					 .rawPPGCompressedRed:
					index = index + packet.raw_data.count
					
					let packets = mDecompressPPGPackets(packet.raw_data)
					dataPackets.append(contentsOf: packets)
					
				#if UNIVERSAL || ETHOS
				case .rawPPGCompressedWhiteIRRPD,
					 .rawPPGCompressedWhiteWhitePD:
					index = index + packet.raw_data.count
					
					let packets = mDecompressPPGPackets(packet.raw_data)
					dataPackets.append(contentsOf: packets)

				case .rawGyroCompressedXADC,
					 .rawGyroCompressedYADC,
					 .rawGyroCompressedZADC:
					index = index + packet.raw_data.count
					
					let packets = mDecompressIMUPackets(packet.raw_data)
					dataPackets.append(contentsOf: packets)
				#endif
					
				#if UNIVERSAL || ALTER || KAIROS || ETHOS
				case .bbi:
					index = index + packet.raw_data.count
					dataPackets.append(packet)
					
				case .cadence:
					index = index + packet.raw_data.count
					dataPackets.append(packet)
				#endif

				default:
					index = index + type.length
					if (type != .unknown) { dataPackets.append(packet) }
				}
			}
			else {
				index = index + packetType.unknown.length
				mFailedDecodeCount	= mFailedDecodeCount + 1
			}			
		}
		
		return (dataPackets)
	}
	
	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	internal func mProcessUpdateValue(_ data: Data) {
		log?.v ("\(pID): \(data.hexString)")
		if let response = notifications(rawValue: data[0]) {
			switch (response) {
			case .completion:
				if (data.count >= 3) {
					if let command = commands(rawValue: data[1]) {
						let successful = (data[2] == 0x01)
						//log?.v ("\(pID): Got completion for '\(command)' with \(successful) status: Bytes = \(data.hexString)")
						switch (command) {
						case .writeEpoch	: self.writeEpochComplete?(successful)
						case .readEpoch		:
							if (data.count == 7) {
								let epoch = data.subdata(in: Range(3...6)).leInt32
								self.readEpochComplete?(successful, epoch)
							}
							else {
								self.readEpochComplete?(false, 0)
							}
						case .endSleep		: self.endSleepComplete?(successful)
						case .getAllPackets	:
							mCRCOK					= true
							mExpectedSequenceNumber	= 0
							self.getAllPacketsComplete?(successful)
						case .getNextPacket :
							if (data.count >= 5) {
								let error_code	= nextPacketStatusType(rawValue: data[3])
								let caughtUp	= (data[4] == 0x01)

								if (successful) {
									let dataPackets = self.mParsePackets(data.subdata(in: Range(5...(data.count - 1))))
									do {
										let jsonData = try JSONEncoder().encode(dataPackets)
										if let jsonString = String(data: jsonData, encoding: .utf8) {
											if let code = error_code {
												self.getNextPacketComplete?(true, code, caughtUp, jsonString)
											}
											else {
												self.getNextPacketComplete?(true, .unknown, caughtUp, jsonString)
											}
										}
										else { self.getNextPacketComplete?(false, .badJSON, caughtUp, "") }
									}
									catch { self.getNextPacketComplete?(false, .badSDKDecode, caughtUp, "") }
								}
								else {
									if let code = error_code {
										self.getNextPacketComplete?(false, code, caughtUp, "")
									}
									else {
										self.getNextPacketComplete?(false, .unknown, caughtUp, "")
									}
								}
							}
							else {
								self.getNextPacketComplete?(false, .unknown, false, "")
							}
						case .getPacketCount:
							if (successful) {
								if (data.count == 7) {
									let count = data.subdata(in: Range(3...6)).leInt32
									self.getPacketCountComplete?(true, count)
								}
								else {
									self.getPacketCountComplete?(false, 0)
								}
							}
							else {
								self.getPacketCountComplete?(false, 0)
							}

						#if UNIVERSAL || ETHOS
						case .debug:
							if (successful) {
								if (data.count == 12) {
									if let device = debugDevice(rawValue: data[3]) {
										let response_data = data.subdata(in: Range(4...11))
										self.debugComplete?(true, device, response_data)
									}
									else { self.debugComplete?(false, .unknownDevice, Data()) }
								}
								else { self.debugComplete?(false, .unknownDevice, Data()) }
							}
							else { self.debugComplete?(false, .unknownDevice, Data()) }
						#endif
							
						case .disableWornDetect	: self.disableWornDetectComplete?(successful)
						case .enableWornDetect	: self.enableWornDetectComplete?(successful)
						case .startManual		: self.startManualComplete?(successful)
						case .stopManual		: self.stopManualComplete?(successful)
						case .led				: self.ledComplete?(successful)
						#if UNIVERSAL || ETHOS
						case .motor				: self.motorComplete?(successful)
						#endif

						case .enterShipMode		: self.enterShipModeComplete?(successful)
						case .setDeviceParam	:
							if let parameter = deviceParameterType(rawValue: data[3]) {
								switch (parameter) {
								case .advertisingInterval	: self.writeAdvIntervalComplete?(successful)
								case .serialNumber			: self.writeSerialNumberComplete?(successful)
								case .chargeCycle			: self.clearChargeCyclesComplete?(successful)
								case .canLogDiagnostics		: self.updateCanLogDiagnosticsComplete?(successful)
								}
							}
							else {
								log?.e ("\(pID): Do not know what to do with parameter: \(String(format: "0x%02X", data[3]))")
							}
						case .getDeviceParam	:
							if let parameter = deviceParameterType(rawValue: data[3]) {
								if (data.count == 20) {
									switch (parameter) {
									case .advertisingInterval	:
										let seconds = data.subdata(in: Range(4...7)).leInt32
										self.readAdvIntervalComplete?(successful, seconds)
									case .serialNumber			:
										let snData		= String(decoding: data.subdata(in: Range(4...19)), as: UTF8.self)
										let nulls		= CharacterSet.whitespacesAndNewlines.union(CharacterSet(["\0"]))
										let snString	= snData.trimmingCharacters(in: nulls)
										self.readSerialNumberComplete?(successful, snString)
									case .chargeCycle			:
										log?.v ("\(pID): \(response): Data: \(data.hexString)")
										let cycles = data.subdata(in: Range(4...7)).leFloat
										self.readChargeCyclesComplete?(successful, cycles)
									case .canLogDiagnostics		:
										log?.v ("\(pID): \(response): Data: \(data.hexString)")
										let canLog = (data[4] != 0x00)
										self.readCanLogDiagnosticsComplete?(true, canLog)
									}
								}
								else {
									switch (parameter) {
									case .advertisingInterval	: self.readAdvIntervalComplete?(false, 0)
									case .serialNumber			: self.readSerialNumberComplete?(false, "")
									case .chargeCycle			: self.readChargeCyclesComplete?(false, 0.0)
									case .canLogDiagnostics		: self.readCanLogDiagnosticsComplete?(false, false)
									}
								}
							}
							else {
								log?.e ("\(pID): Do not know what to do with parameter: \(String(format: "0x%02X", data[3]))")
							}
						case .delDeviceParam	:
							if let parameter = deviceParameterType(rawValue: data[3]) {
								switch (parameter) {
								case .advertisingInterval	: self.deleteAdvIntervalComplete?(successful)
								case .serialNumber			: self.deleteSerialNumberComplete?(successful)
								case .chargeCycle			: log?.e ("\(pID): Should not have been able to delete \(parameter.title)")
								case .canLogDiagnostics		: log?.e ("\(pID): Should not have been able to delete \(parameter.title)")
								}
							}
							else {
								log?.e ("\(pID): Do not know what to do with parameter: \(String(format: "0x%02X", data[3]))")
							}
						case .setSessionParam		:
							if let enumParameter = sessionParameterType(rawValue: data[3]) {
								switch (enumParameter) {
								case .ppgCapturePeriod,
									 .ppgCaptureDuration,
									 .tag		: setSessionParamComplete?(successful, enumParameter)
								case .reset		: resetSessionParamsComplete?(successful)
								case .accept	: acceptSessionParamsComplete?(successful)
								case .unknown			:
									setSessionParamComplete?(false, enumParameter)					// Shouldn't get this ever!
									break
								}
							}
							else {
								log?.e ("\(pID): Was not able to encode parameter: \(String(format: "0x%02X", data[3]))")
							}

						case .getSessionParam		:
							if let enumParameter = sessionParameterType(rawValue: data[3]) {
								switch (enumParameter) {
								case .ppgCapturePeriod,
									 .ppgCaptureDuration,
									 .tag		:
									let value = data.subdata(in: Range(4...7)).leInt32
									getSessionParamComplete?(successful, enumParameter, value)
									break
								case .reset		: resetSessionParamsComplete?(false)		// Shouldn't get this on a get
								case .accept	: acceptSessionParamsComplete?(false)		// Shouldn't get this on a get
								case .unknown	:
									getSessionParamComplete?(false, enumParameter, 0)				// Shouldn't get this ever!
									break
								}

							}
							else {
								log?.e ("\(pID): Was not able to encode parameter: \(String(format: "0x%02X", data[3]))")
							}

						case .manufacturingTest	: self.manufacturingTestComplete?(successful)
						case .recalibratePPG	: self.recalibratePPGComplete?(successful)
						#if UNIVERSAL || ETHOS
						case .startLiveSync		: self.startLiveSyncComplete?(successful)
						case .stopLiveSync		: self.stopLiveSyncComplete?(successful)
						#endif
							
						#if UNIVERSAL || ALTER || KAIROS || ETHOS
						case .setAskForButtonResponse:
							if (data.count == 4) {
								let enable		= data[3] == 0x01 ? true : false
								self.setAskForButtonResponseComplete?(successful, enable)
							}
							else {
								self.setAskForButtonResponseComplete?(false, false)
							}
							
						case .getAskForButtonResponse:
							if (data.count == 4) {
								let enable		= data[3] == 0x01 ? true : false
								self.getAskForButtonResponseComplete?(successful, enable)
							}
							else {
								self.getAskForButtonResponseComplete?(false, false)
							}
							
						case .setHRZoneColor:
							if (data.count == 4) {
								if let zone = hrZoneRangeType(rawValue: data[3]) {
									self.setHRZoneColorComplete?(successful, zone)
								}
								else { self.setHRZoneColorComplete?(false, .unknown) }
							}
							else { self.setHRZoneColorComplete?(false, .unknown) }
							
						case .getHRZoneColor:
							if (data.count == 11) {
								if let zone = hrZoneRangeType(rawValue: data[3]) {
									let red		= (data[4] != 0x00)
									let green	= (data[5] != 0x00)
									let blue	= (data[6] != 0x00)
									let on_ms	= data.subdata(in: Range(7...8)).leInt16
									let off_ms	= data.subdata(in: Range(9...10)).leInt16
									self.getHRZoneColorComplete?(successful, zone, red, green, blue, on_ms, off_ms)
								}
								else { self.getHRZoneColorComplete?(false, .unknown, false, false, false, 0, 0) }
							}
							else { self.getHRZoneColorComplete?(false, .unknown, false, false, false, 0, 0) }
							
						case .setHRZoneRange:
							if (data.count == 3) { self.setHRZoneRangeComplete?(successful) }
							else { self.setHRZoneRangeComplete?(false) }
							
						case .getHRZoneRange:
							if (data.count == 6) {
								let enable		= (data[3] != 0x00)
								let high_value	= Int(data[4])
								let low_value	= Int(data[5])
								self.getHRZoneRangeComplete?(successful, enable, high_value, low_value)
							}
							else {
								self.getHRZoneRangeComplete?(false, false, 0, 0)
							}
						case .getPPGAlgorithm:
							if (data.count == 5) {
								let algorithm	= ppgAlgorithmConfiguration(data[3])
								
								if let type = eventType(rawValue: data[4]) {
									self.getPPGAlgorithmComplete?(successful, algorithm, type)
								}
								else {
									self.getPPGAlgorithmComplete?(successful, algorithm, eventType.unknown)
								}
							}
							else if (data.count == 4) {
								let algorithm	= ppgAlgorithmConfiguration(data[3])
								self.getPPGAlgorithmComplete?(successful, algorithm, eventType.unknown)
							}
							else {
								self.getPPGAlgorithmComplete?(false, ppgAlgorithmConfiguration(), eventType.unknown)
							}
							
						case .setAdvertiseAsHRM:
							if (data.count == 4) {
								let asHRM		= data[3] != 0x00
								self.setAdvertiseAsHRMComplete?(successful, asHRM)
							}
							else {
								self.setAdvertiseAsHRMComplete?(false, false)
							}

						case .getAdvertiseAsHRM:
							if (data.count == 4) {
								let asHRM		= data[3] != 0x00
								self.getAdvertiseAsHRMComplete?(successful, asHRM)
							}
							else {
								self.getAdvertiseAsHRMComplete?(false, false)
							}
							
						case .setButtonCommand:
							if (data.count == 5) {
								if let tap = buttonTapType(rawValue: data[3]), let command = buttonCommandType(rawValue: data[4]) {
									self.setButtonCommandComplete?(true, tap, command)
								}
								else {
									self.setButtonCommandComplete?(false, .unknown, .unknown)
								}
							}
							else {
								self.setButtonCommandComplete?(false, .unknown, .unknown)
							}

						case .getButtonCommand:
							if (data.count == 5) {
								if let tap = buttonTapType(rawValue: data[3]), let command = buttonCommandType(rawValue: data[4]) {
									self.getButtonCommandComplete?(true, tap, command)
								}
								else {
									self.getButtonCommandComplete?(false, .unknown, .unknown)
								}
							}
							else {
								self.getButtonCommandComplete?(false, .unknown, .unknown)
							}
						#endif

						case .allowPPG			: self.allowPPGComplete?(successful)
						case .wornCheck			:
							if (data.count == 8) {
								if let code = wornResult(rawValue: data[3]) {
									let value = data.subdata(in: Range(4...7)).leInt32
								
									if code == .ran {
										self.wornCheckComplete?(true, code.message, value)
									}
									else {
										self.wornCheckComplete?(false, code.message, 0)
									}
								}
								else {
									self.wornCheckComplete?(false, "Unknown code: \(String(format: "0x%02X", data[3]))", 0)
								}
							}
							
						case .logRaw			: self.rawLoggingComplete?(successful)
						case .getRawLoggingStatus	:
							if (data.count == 4) {
								self.getRawLoggingStatusComplete?(successful, (data[3] != 0x00))
							}
							else {
								self.getRawLoggingStatusComplete?(false, false)
							}
							
						case .getWornOverrideStatus	:
							if (data.count == 4) {
								self.getWornOverrideStatusComplete?(successful, (data[3] != 0x00))
							}
							else {
								self.getWornOverrideStatusComplete?(false, false)
							}
							
						#if UNIVERSAL || ALTER || KAIROS || ETHOS
						case .airplaneMode		: self.airplaneModeComplete?(successful)
						#endif
							
						case .reset				: self.resetComplete?(successful)
						case .validateCRC		: break
							//log?.v ("\(pID): Got Validate CRC completion: \(data.hexString)")
						}
					}
					else {
						log?.e ("\(pID): Unknown command: \(data.hexString)")
					}
				}
				else {
					log?.e ("\(pID): Incorrect length for completion: \(data.hexString)")
				}
				
			case .dataPacket:
				if (data.count > 3) {	// Accounts for header byte and sequence number
					//log?.v ("\(pID): \(data.subdata(in: Range(0...7)).hexString)")
					//log?.v ("\(pID): \(data.hexString)")
					let sequence_number = data.subdata(in: Range(1...2)).leUInt16
					if (sequence_number == mExpectedSequenceNumber) {
						//log?.v ("\(pID): Sequence Number Match: \(sequence_number).  Expected: \(mExpectedSequenceNumber)")
					}
					else {
						log?.e ("\(pID): \(response) - Sequence Number Fail: \(sequence_number). Expected: \(mExpectedSequenceNumber): \(data.hexString)")
						mCRCOK	= false
					}
					mExpectedSequenceNumber = mExpectedSequenceNumber + 1
					
					if (mCRCOK) {
						let dataPackets = self.mParsePackets(data.subdata(in: Range(3...(data.count - 1))))
						mDataPackets.append(contentsOf: dataPackets)
					}
				}
				else {
					log?.e ("\(pID): Bad data length for data packet: \(data.hexString)")
					mCRCOK	= false
				}
				
			case .worn:
				if      (data[1] == 0x00) { deviceWornStatus?(false) }
				else if (data[1] == 0x01) { deviceWornStatus?(true)  }
				else {
					log?.e ("\(pID): Cannot parse worn status: \(data[1])")
				}
							
			case .ppg_metrics:
				let (_, type, packet) = pParseSinglePacket(data, index: 1)
				if (type == .ppg_metrics) {
					do {
						let jsonData = try JSONEncoder().encode(packet)
						if let jsonString = String(data: jsonData, encoding: .utf8) {
							self.ppgMetrics?(true, jsonString)
						}
						else { self.ppgMetrics?(false, "") }
					}
					catch { self.ppgMetrics?(false, "") }
				}
				
			case .ppgFailed:
				if (data.count > 1) {
					self.ppgFailed?(Int(data[1]))
				}
				else {
					self.ppgFailed?(999)
				}
				
			case .dataCaughtUp:
				if (data.count > 1) {
					let bad_read_count	= Int(data.subdata(in: Range(1...2)).leUInt16)
					let bad_parse_count	= Int(data.subdata(in: Range(3...4)).leUInt16)
					let overflow_count	= Int(data.subdata(in: Range(5...6)).leUInt16)
					self.dataComplete?(bad_read_count, bad_parse_count, overflow_count, self.mFailedDecodeCount)
				}
				else {
					self.dataComplete?(-1, -1, -1, self.mFailedDecodeCount)
				}
				
			#if UNIVERSAL || ALTER || KAIROS || ETHOS
			case .endSleepStatus:
				if (data.count == 2) {
					let hasSleep	= data[1] == 0x01 ? true : false
					self.endSleepStatus?(hasSleep)
				}
				else {
					log?.e ("\(pID): Cannot parse 'endSleepStatus': \(data.hexString)")
				}
				
			case .buttonResponse:
				if (data.count == 2) {
					let presses	= Int(data[1])
					self.buttonClicked?(presses)
				}
				else {
					log?.e ("\(pID): Cannot parse 'buttonResponse': \(data.hexString)")
				}
			#endif
				
			case .validateCRC:
				//log?.v ("\(pID): \(response) - \(data.hexString)")
				
				let sequence_number = data.subdata(in: Range(1...2)).leUInt16
				if (sequence_number == mExpectedSequenceNumber) {
					//log?.v ("\(pID): SN Match: \(sequence_number).  Expected: \(mExpectedSequenceNumber)")
				}
				else {
					log?.e ("\(pID): \(response) - Sequence Number Fail: \(sequence_number). Expected: \(mExpectedSequenceNumber): \(data.hexString)")
					mCRCOK	= false
				}

				let allowResponse		= mCRCIgnoreTest.check()
				let allowGoodResponse	= mCRCFailTest.check()
										
				if (allowResponse) {
					if (allowGoodResponse) {
						if (mCRCOK == true) {
							//log?.v ("\(pID): Validate CRC Passed: Let received packets through")
							
							if (mDataPackets.count > 0) {
								do {
									let jsonData = try JSONEncoder().encode(mDataPackets)
									if let jsonString = String(data: jsonData, encoding: .utf8) {
									self.dataPackets?(jsonString)
								}
									else { log?.e ("\(pID): Cannot make string from json data") }
								}
								catch { log?.e ("\(pID): Cannot make JSON data") }
						   }
						}
						else {
							log?.v ("\(pID): \(response) Failed: Do not let packets through")
						}
					}
					else {
						mCRCOK	= false
					}

					self.mDataPackets.removeAll()
					self.mExpectedSequenceNumber	= 0

					DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(50), execute: {
						self.mValidateCRC()
					})
				}
				
			case .manufacturingTest:
				#if LIVOTAL
				let testResult = livotalManufacturingTestResult(data.subdata(in: Range(1...4)))
				do {
					let jsonData = try JSONEncoder().encode(testResult)
					if let jsonString = String(data: jsonData, encoding: .utf8) {
						self.manufacturingTestResult?(true, jsonString)
					}
					else {
						log?.e ("\(pID): Result jsonString Failed")
						self.manufacturingTestResult?(false, "")
					}
				}
				catch {
					log?.e ("\(pID): Result jsonData Failed")
					self.manufacturingTestResult?(false, "")
				}
				#endif
				
				#if ETHOS
				if (data.count == 3) {
					let testResult = ethosManufacturingTestResult(data.subdata(in: Range(1...2)))
					do {
						let jsonData = try JSONEncoder().encode(testResult)
						if let jsonString = String(data: jsonData, encoding: .utf8) {
							self.manufacturingTestResult?(true, jsonString)
						}
						else {
							log?.e ("\(pID): Result jsonString Failed")
							self.manufacturingTestResult?(false, "")
						}
					}
					catch {
						log?.e ("\(pID): Result jsonData Failed")
						self.manufacturingTestResult?(false, "")
					}
				}
				else {
					self.manufacturingTestResult?(false, "")
				}
				#endif
				
				#if ALTER
				if (data.count == 3) {
					let testResult = alterManufacturingTestResult(data.subdata(in: Range(1...2)))
					do {
						let jsonData = try JSONEncoder().encode(testResult)
						if let jsonString = String(data: jsonData, encoding: .utf8) {
							self.manufacturingTestResult?(true, jsonString)
						}
						else {
							log?.e ("\(pID): Result jsonString Failed")
							self.manufacturingTestResult?(false, "")
						}
					}
					catch {
						log?.e ("\(pID): Result jsonData Failed")
						self.manufacturingTestResult?(false, "")
					}
				}
				else {
					self.manufacturingTestResult?(false, "")
				}
				#endif

				#if KAIROS
				if (data.count == 3) {
					let testResult = kairosManufacturingTestResult(data.subdata(in: Range(1...2)))
					do {
						let jsonData = try JSONEncoder().encode(testResult)
						if let jsonString = String(data: jsonData, encoding: .utf8) {
							self.manufacturingTestResult?(true, jsonString)
						}
						else {
							log?.e ("\(pID): Result jsonString Failed")
							self.manufacturingTestResult?(false, "")
						}
					}
					catch {
						log?.e ("\(pID): Result jsonData Failed")
						self.manufacturingTestResult?(false, "")
					}
				}
				else {
					self.manufacturingTestResult?(false, "")
				}
				#endif

				#if UNIVERSAL
				switch (type) {
				case .livotal	:
					let testResult = livotalManufacturingTestResult(data.subdata(in: Range(1...4)))
					do {
						let jsonData = try JSONEncoder().encode(testResult)
						if let jsonString = String(data: jsonData, encoding: .utf8) {
							self.manufacturingTestResult?(true, jsonString)
						}
						else {
							log?.e ("\(pID): Result jsonString Failed")
							self.manufacturingTestResult?(false, "")
						}
					}
					catch {
						log?.e ("\(pID): Result jsonData Failed")
						self.manufacturingTestResult?(false, "")
					}

				case .ethos		:
					if (data.count == 3) {
						let testResult = ethosManufacturingTestResult(data.subdata(in: Range(1...2)))
						do {
							let jsonData = try JSONEncoder().encode(testResult)
							if let jsonString = String(data: jsonData, encoding: .utf8) {
								self.manufacturingTestResult?(true, jsonString)
							}
							else {
								log?.e ("\(pID): Result jsonString Failed")
								self.manufacturingTestResult?(false, "")
							}
						}
						catch {
							log?.e ("\(pID): Result jsonData Failed")
							self.manufacturingTestResult?(false, "")
						}
					}
					else {
						self.manufacturingTestResult?(false, "")
					}

				case .alter		:
					if (data.count == 3) {
						let testResult = alterManufacturingTestResult(data.subdata(in: Range(1...2)))
						do {
							let jsonData = try JSONEncoder().encode(testResult)
							if let jsonString = String(data: jsonData, encoding: .utf8) {
								self.manufacturingTestResult?(true, jsonString)
							}
							else {
								log?.e ("\(pID): Result jsonString Failed")
								self.manufacturingTestResult?(false, "")
							}
						}
						catch {
							log?.e ("\(pID): Result jsonData Failed")
							self.manufacturingTestResult?(false, "")
						}
					}
					else {
						self.manufacturingTestResult?(false, "")
					}

				case .kairos		:
					if (data.count == 3) {
						let testResult = kairosManufacturingTestResult(data.subdata(in: Range(1...2)))
						do {
							let jsonData = try JSONEncoder().encode(testResult)
							if let jsonString = String(data: jsonData, encoding: .utf8) {
								self.manufacturingTestResult?(true, jsonString)
							}
							else {
								log?.e ("\(pID): Result jsonString Failed")
								self.manufacturingTestResult?(false, "")
							}
						}
						catch {
							log?.e ("\(pID): Result jsonData Failed")
							self.manufacturingTestResult?(false, "")
						}
					}
					else {
						self.manufacturingTestResult?(false, "")
					}

				case .unknown	: break
				}
				#endif
				
			case .charging:
				let on_charger	= (data[1] == 0x01)
				let charging	= (data[2] == 0x01)
				let error		= (data[3] == 0x01)
				
				self.deviceChargingStatus?(charging, on_charger, error)
				
			case .streamPacket: log?.e ("\(pID): Should not get '\(response)' on this characteristic!")
			}
		}
		else {
			log?.e ("\(pID): Unknown update: \(data.hexString)")
		}
	}
	
	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	override func didUpdateValue() {
		if let characteristic = pCharacteristic {
			if let data = characteristic.value {
				
				// Packets have to be at least a header + CRC.  If not, do not parse
				if (data.count >= 4) {
					// Get the CRC.  Only process the packet if the CRC is good.
					let crc_received	= data.subdata(in: Range((data.count - 4)...(data.count - 1))).leInt32
					var input_bytes 	= data.subdata(in: Range(0...(data.count - 5))).bytes
					let crc_calculated	= crc32(uLong(0), &input_bytes, uInt(input_bytes.count))

					if (crc_received != crc_calculated) {
						log?.e ("\(pID): Hmmm..... Packet CRC Error! CRC : \(String(format:"0x%08X", crc_received)): \(String(format:"0x%08X", crc_calculated))")
						mCRCOK = false;
						mExpectedSequenceNumber = mExpectedSequenceNumber + 1	// go ahead and increase the expected sequence number.  already going to create retransmit.  this avoids other expected sequence checks from failling
					}

					mProcessUpdateValue(data.subdata(in: Range(0...(data.count - 5))))
				}
				else {
					log?.e ("\(pID): Cannot calculate packet CRC: Not enough data.  Length = \(data.count): \(data.hexString)")
					return
				}
				
			}
			else {
				log?.e ("\(pID): Missing data")
			}
		}
		else { log?.e ("\(pID): Missing characteristic") }
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	override func didUpdateNotificationState() {
		pConfigured	= true
	}
	
}
