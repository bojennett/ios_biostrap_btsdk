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
		case writeEpoch			= 0x00
		case getAllPackets		= 0x01
		case getNextPacket		= 0x02
		case getPacketCount		= 0x03
		case validateCRC		= 0x04
		case led				= 0x10
		case enterShipMode		= 0x11
		case readEpoch			= 0x12
		case endSleep			= 0x13
		#if UNIVERSAL || ETHOS
		case motor				= 0x14
		case debug				= 0x20
		#endif
		case setDeviceParam		= 0x70
		case getDeviceParam		= 0x71
		case delDeviceParam		= 0x72
		case setSessionParam	= 0x80
		case getSessionParam	= 0x81
		case recalibratePPG		= 0xed
		#if UNIVERSAL || ETHOS
		case startLiveSync		= 0xee
		case stopLiveSync		= 0xef
		#endif
		case getRawLoggingStatus	= 0xf5
		case getWornOverrideStatus	= 0xf6
		case manufacturingTest	= 0xf7
		case allowPPG			= 0xf8
		case wornCheck			= 0xf9
		case logRaw				= 0xfa
		case disableWornDetect	= 0xfb
		case enableWornDetect	= 0xfc
		case startManual		= 0xfd
		case stopManual			= 0xfe
		case reset				= 0xff
	}
	
	enum notifications: UInt8 {
		case completion			= 0x00
		case dataPacket			= 0x01
		case worn				= 0x02
		case ppgFailed			= 0x04
		case validateCRC		= 0x05
		case dataCaughtUp		= 0x06
		case manufacturingTest	= 0x07
		case charging			= 0x08
		case ppg_metrics		= 0x09
	}
	
	enum wornResult: UInt8 {
		case broken				= 0x00
		case busy				= 0x01
		case ran				= 0x02
		
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
	var ppgMetrics: ((_ successful: Bool, _ packet: String)->())?
	var ppgFailed: ((_ code: Int)->())?
	var disableWornDetectComplete: ((_ successful: Bool)->())?
	var enableWornDetectComplete: ((_ successful: Bool)->())?
	var endSleepComplete: ((_ successful: Bool)->())?
	#if UNIVERSAL || ETHOS
	var debugComplete: ((_ successful: Bool, _ device: debugDevice, _ data: Data)->())?
	#endif

	var dataPackets: ((_ packets: String)->())?
	var dataComplete: ((_ bad_fw_read_count: Int, _ bad_fw_parse_count: Int, _ overflow_count: Int, _ bad_sdk_parse_count: Int)->())?
	var dataFailure: (()->())?
	
	var manufacturingTestComplete: ((_ successful: Bool)->())?
	var manufacturingTestResult: ((_ valid: Bool, _ result: String)->())?
	
	var recalibratePPGComplete: ((_ successful: Bool)->())?

	#if UNIVERSAL || ETHOS
	var startLiveSyncComplete: ((_ successful: Bool)->())?
	var stopLiveSyncComplete: ((_ successful: Bool)->())?
	#endif
	
	var deviceChargingStatus: ((_ charging: Bool, _ on_charger: Bool, _ error: Bool)->())?

	var setSessionParamComplete: ((_ successful: Bool, _ parameter: sessionParameterType)->())?
	var getSessionParamComplete: ((_ successful: Bool, _ parameter: sessionParameterType, _ value: Int)->())?
	var resetSessionParamsComplete: ((_ successful: Bool)->())?
	var acceptSessionParamsComplete: ((_ successful: Bool)->())?
	
	var getRawLoggingStatusComplete: ((_ successful: Bool, _ enabled: Bool)->())?
	var getWornOverrideStatusComplete: ((_ successful: Bool, _ overridden: Bool)->())?
	
	var deviceWornStatus: ((_ isWorn: Bool)->())?
	
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
			
			log?.w ("\(commandData.hexString)")

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
		log?.v("\(pID): \(allow)")
		
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
		log?.v("\(parameter) - \(value)")
		
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
		log?.v("\(parameter)")
		
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
		log?.v("")
		
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
		log?.v("")
		
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
		log?.v("")
		
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
		log?.v("")
		
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
		log?.v("")
		
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
		log?.v("")
		
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
		log?.v("\(configuration.commandString) -> \(String(format: "0x%02X", configuration.commandByte))")
		
		if let peripheral = pPeripheral, let characteristic = pCharacteristic {
			var data = Data()
			data.append(commands.startLiveSync.rawValue)
			data.append(configuration.commandByte)
			peripheral.writeValue(data, for: characteristic, type: .withResponse)
		}
		else { self.startLiveSyncComplete?(false) }
	}
	
	func stopLiveSync() {
		log?.v("")
		
		if let peripheral = pPeripheral, let characteristic = pCharacteristic {
			var data = Data()
			data.append(commands.stopLiveSync.rawValue)
			peripheral.writeValue(data, for: characteristic, type: .withResponse)
		}
		else { self.stopLiveSyncComplete?(false) }
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
		log?.v("")
		
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
			log?.e ("I can't run the validate CRC command.  I don't know what to do here")
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
	internal func mParseSinglePacket(_ data: Data, index: Int) -> (Bool, packetType, biostrapDataPacket) {
		//log?.v ("\(index): \(String(format: "0x%02X", data[index]))")
		if let type = packetType(rawValue: data[index]) {
			switch (type) {
			case .diagnostic:
				if ((index + 1) < data.count) {
					let length = Int(data[index + 1]) + 1
					
					if ((index + length) <= data.count) {
						let packetData = data.subdata(in: Range(index...(index + length - 1)))
						return (true, type, biostrapDataPacket(packetData))
					}
					else {
						log?.e ("\(type.title): Index: \(index), Full Packet: \(data.hexString)")
						return (false, .unknown, biostrapDataPacket())
					}
				}
				else {
					log?.e ("\(type.title): Index: \(index), Full Packet: \(data.hexString)")
					return (false, .unknown, biostrapDataPacket())
				}

			case .rawPPGCompressedGreen,
				 .rawPPGCompressedIR,
				 .rawPPGCompressedRed:
				if ((index + 1) < data.count) {
					let length = Int(data[index + 1]) + 1 + 1 + 1 + 3
					if ((index + length) <= data.count) {
						let packetData = data.subdata(in: Range(index...(index + length - 1)))
						return (true, type, biostrapDataPacket(packetData))
					}
					else {
						log?.e ("\(type.title): Index: \(index), Full Packet: \(data.hexString)")
						return (false, .unknown, biostrapDataPacket())
					}
				}
				else {
					log?.e ("\(type.title): Index: \(index), Full Packet: \(data.hexString)")
					return (false, .unknown, biostrapDataPacket())
				}

			#if UNIVERSAL || ETHOS
			case .rawPPGCompressedWhiteIRRPD,
				 .rawPPGCompressedWhiteWhitePD:
				if ((index + 1) < data.count) {
					let length = Int(data[index + 1]) + 1 + 1 + 1 + 3
					if ((index + length) <= data.count) {
						let packetData = data.subdata(in: Range(index...(index + length - 1)))
						return (true, type, biostrapDataPacket(packetData))
					}
					else {
						log?.e ("\(type.title): Index: \(index), Full Packet: \(data.hexString)")
						return (false, .unknown, biostrapDataPacket())
					}
				}
				else {
					log?.e ("\(type.title): Index: \(index), Full Packet: \(data.hexString)")
					return (false, .unknown, biostrapDataPacket())
				}
			#endif
				
			case .rawAccelCompressedXADC,
				 .rawAccelCompressedYADC,
				 .rawAccelCompressedZADC:
				if ((index + 1) < data.count) {
					let length = Int(data[index + 1]) + 1 + 1 + 2 + 2
					if ((index + length) <= data.count) {
						let packetData = data.subdata(in: Range(index...(index + length - 1)))
						return (true, type, biostrapDataPacket(packetData))
					}
					else {
						log?.e ("\(type.title): Index: \(index), Full Packet: \(data.hexString)")
						return (false, .unknown, biostrapDataPacket())
					}
				}
				else {
					log?.e ("\(type.title): Index: \(index), Full Packet: \(data.hexString)")
					return (false, .unknown, biostrapDataPacket())
				}
				
			#if UNIVERSAL || ETHOS
			case .rawGyroCompressedXADC,
				 .rawGyroCompressedYADC,
				 .rawGyroCompressedZADC:
				if ((index + 1) < data.count) {
					let length = Int(data[index + 1]) + 1 + 1 + 2 + 2
					if ((index + length) <= data.count) {
						let packetData = data.subdata(in: Range(index...(index + length - 1)))
						return (true, type, biostrapDataPacket(packetData))
					}
					else {
						log?.e ("\(type.title): Index: \(index), Full Packet: \(data.hexString)")
						return (false, .unknown, biostrapDataPacket())
					}
				}
				else {
					log?.e ("\(type.title): Index: \(index), Full Packet: \(data.hexString)")
					return (false, .unknown, biostrapDataPacket())
				}
			#endif

			case .unknown:
				log?.e ("\(type.title): Index: \(index), Full Packet: \(data.hexString)")
				return (false, type, biostrapDataPacket())
				
			default:
				if ((index + type.length) <= data.count) {
					let packetData = data.subdata(in: Range((index)...(index + type.length - 1)))
					return (true, type, biostrapDataPacket(packetData))
				}
				else {
					log?.e ("\(type.title): '\(type.length)' from '\(index)' exceeds length of data '\(data.count)'")
					return (false, type, biostrapDataPacket())
				}
			}
			
		}
		else {
			log?.v ("Could not parse type: Remaining bytes: \(data.subdata(in: Range(index...(data.count - 1))).hexString)")
			return (false, .unknown, biostrapDataPacket())
		}
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
			let (found, type, packet) = mParseSinglePacket(data, index: index)

			if (found) {
				switch (type) {
				case .diagnostic:
					index = index + packet.raw_data.count
					dataPackets.append(packet)
					
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
				#endif

				case .rawAccelCompressedXADC,
					 .rawAccelCompressedYADC,
					 .rawAccelCompressedZADC:
					index = index + packet.raw_data.count
					
					let packets = mDecompressIMUPackets(packet.raw_data)
					dataPackets.append(contentsOf: packets)

				#if UNIVERSAL || ETHOS
				case .rawGyroCompressedXADC,
					 .rawGyroCompressedYADC,
					 .rawGyroCompressedZADC:
					index = index + packet.raw_data.count
					
					let packets = mDecompressIMUPackets(packet.raw_data)
					dataPackets.append(contentsOf: packets)
				#endif

				default:
					index = index + type.length
					if (type != .unknown) { dataPackets.append(packet) }
				}
			}
			else {
				index = index + type.length
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
		log?.v ("\(data.hexString)")
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
								log?.e ("Do not know what to do with parameter: \(String(format: "0x%02X", data[3]))")
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
										log?.v ("\(response): Data: \(data.hexString)")
										let cycles = data.subdata(in: Range(4...7)).leFloat
										self.readChargeCyclesComplete?(successful, cycles)
									case .canLogDiagnostics		:
										log?.v ("\(response): Data: \(data.hexString)")
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
								log?.e ("Do not know what to do with parameter: \(String(format: "0x%02X", data[3]))")
							}
						case .delDeviceParam	:
							if let parameter = deviceParameterType(rawValue: data[3]) {
								switch (parameter) {
								case .advertisingInterval	: self.deleteAdvIntervalComplete?(successful)
								case .serialNumber			: self.deleteSerialNumberComplete?(successful)
								case .chargeCycle			: log?.e ("Should not have been able to delete \(parameter.title)")
								case .canLogDiagnostics		: log?.e ("Should not have been able to delete \(parameter.title)")
								}
							}
							else {
								log?.e ("Do not know what to do with parameter: \(String(format: "0x%02X", data[3]))")
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
								log?.e ("Was not able to encode parameter: \(String(format: "0x%02X", data[3]))")
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
								log?.e ("Was not able to encode parameter: \(String(format: "0x%02X", data[3]))")
							}

						case .manufacturingTest	: self.manufacturingTestComplete?(successful)
						case .recalibratePPG	: self.recalibratePPGComplete?(successful)
						#if UNIVERSAL || ETHOS
						case .startLiveSync		: self.startLiveSyncComplete?(successful)
						case .stopLiveSync		: self.stopLiveSyncComplete?(successful)
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
						case .getRawLoggingStatus	: self.getRawLoggingStatusComplete?(successful, (data[3] != 0x00))
						case .getWornOverrideStatus	: self.getWornOverrideStatusComplete?(successful, (data[3] != 0x00))
						case .reset				: self.resetComplete?(successful)
						case .validateCRC		: break
							//log?.v ("Got Validate CRC completion: \(data.hexString)")
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
					//log?.v ("\(data.subdata(in: Range(0...7)).hexString)")
					//log?.v ("\(data.hexString)")
					let sequence_number = data.subdata(in: Range(1...2)).leUInt16
					if (sequence_number == mExpectedSequenceNumber) {
						//log?.v ("Sequence Number Match: \(sequence_number).  Expected: \(mExpectedSequenceNumber)")
					}
					else {
						log?.e ("\(response) - Sequence Number Fail: \(sequence_number). Expected: \(mExpectedSequenceNumber): \(data.hexString)")
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
				log?.v ("Worn State: \(data[1])")
				if      (data[1] == 0x00) { deviceWornStatus?(false) }
				else if (data[1] == 0x01) { deviceWornStatus?(true)  }
				else {
					log?.e ("Cannot parse worn status: \(data[1])")
				}
							
			case .ppg_metrics:
				log?.v ("PPG Metrics: \(data.hexString)")
				let (_, type, packet) = mParseSinglePacket(data, index: 1)
				if (type == .ppg_metrics) {
					do {
						let jsonData = try JSONEncoder().encode(packet)
						if let jsonString = String(data: jsonData, encoding: .utf8) {
							log?.v ("PPG Metrics JSON: \(jsonString)")
							self.ppgMetrics?(true, jsonString)
						}
						else { self.ppgMetrics?(false, "") }
					}
					catch { self.ppgMetrics?(false, "") }
				}
				
			case .ppgFailed:
				log?.v ("PPG Failed: \(data.hexString)")
				if (data.count > 1) {
					self.ppgFailed?(Int(data[1]))
					
				}
				else {
					self.ppgFailed?(999)
				}
				
			case .dataCaughtUp:
				log?.v ("\(response) - \(data.hexString)")
				if (data.count > 1) {
					let bad_read_count	= Int(data.subdata(in: Range(1...2)).leUInt16)
					let bad_parse_count	= Int(data.subdata(in: Range(3...4)).leUInt16)
					let overflow_count	= Int(data.subdata(in: Range(5...6)).leUInt16)
					self.dataComplete?(bad_read_count, bad_parse_count, overflow_count, self.mFailedDecodeCount)
				}
				else {
					self.dataComplete?(-1, -1, -1, self.mFailedDecodeCount)
				}
				
			case .validateCRC:
				//log?.v ("\(response) - \(data.hexString)")
				
				let sequence_number = data.subdata(in: Range(1...2)).leUInt16
				if (sequence_number == mExpectedSequenceNumber) {
					//log?.v ("SN Match: \(sequence_number).  Expected: \(mExpectedSequenceNumber)")
				}
				else {
					log?.e ("\(response) - Sequence Number Fail: \(sequence_number). Expected: \(mExpectedSequenceNumber): \(data.hexString)")
					mCRCOK	= false
				}

				let allowResponse		= mCRCIgnoreTest.check()
				let allowGoodResponse	= mCRCFailTest.check()
										
				if (allowResponse) {
					if (allowGoodResponse) {
						if (mCRCOK == true) {
							//log?.v ("Validate CRC Passed: Let received packets through")
							
							if (mDataPackets.count > 0) {
								do {
									let jsonData = try JSONEncoder().encode(mDataPackets)
									if let jsonString = String(data: jsonData, encoding: .utf8) {
									self.dataPackets?(jsonString)
								}
									else { log?.e ("Cannot make string from json data") }
								}
								catch { log?.e ("Cannot make JSON data") }
						   }
						}
						else {
							log?.v ("\(response) Failed: Do not let packets through")
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
				log?.v ("Data: \(data.hexString)")
				#if LIVOTAL
				let testResult = livotalManufacturingTestResult(data.subdata(in: Range(1...4)))
				do {
					let jsonData = try JSONEncoder().encode(testResult)
					if let jsonString = String(data: jsonData, encoding: .utf8) {
						self.manufacturingTestResult?(true, jsonString)
					}
					else {
						log?.e ("Result jsonString Failed")
						self.manufacturingTestResult?(false, "")
					}
				}
				catch {
					log?.e ("Result jsonData Failed")
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
							log?.e ("Result jsonString Failed")
							self.manufacturingTestResult?(false, "")
						}
					}
					catch {
						log?.e ("Result jsonData Failed")
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
							log?.e ("Result jsonString Failed")
							self.manufacturingTestResult?(false, "")
						}
					}
					catch {
						log?.e ("Result jsonData Failed")
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
							log?.e ("Result jsonString Failed")
							self.manufacturingTestResult?(false, "")
						}
					}
					catch {
						log?.e ("Result jsonData Failed")
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
							log?.e ("Result jsonString Failed")
							self.manufacturingTestResult?(false, "")
						}
					}
					catch {
						log?.e ("Result jsonData Failed")
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
								log?.e ("Result jsonString Failed")
								self.manufacturingTestResult?(false, "")
							}
						}
						catch {
							log?.e ("Result jsonData Failed")
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
								log?.e ("Result jsonString Failed")
								self.manufacturingTestResult?(false, "")
							}
						}
						catch {
							log?.e ("Result jsonData Failed")
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
								log?.e ("Result jsonString Failed")
								self.manufacturingTestResult?(false, "")
							}
						}
						catch {
							log?.e ("Result jsonData Failed")
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
						log?.e ("Hmmm..... Packet CRC Error! CRC : \(String(format:"0x%08X", crc_received)): \(String(format:"0x%08X", crc_calculated))")
						mCRCOK = false;
						mExpectedSequenceNumber = mExpectedSequenceNumber + 1	// go ahead and increase the expected sequence number.  already going to create retransmit.  this avoids other expected sequence checks from failling
					}

					mProcessUpdateValue(data.subdata(in: Range(0...(data.count - 5))))
				}
				else {
					log?.e ("Cannot calculate packet CRC: Not enough data.  Length = \(data.count): \(data.hexString)")
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
