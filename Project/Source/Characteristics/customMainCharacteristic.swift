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
		case getAllPacketsAcknowledge	= 0x05
		case led						= 0x10
		case enterShipMode				= 0x11
		case readEpoch					= 0x12
		case endSleep					= 0x13
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
		case setDeviceParam				= 0x70
		case getDeviceParam				= 0x71
		case delDeviceParam				= 0x72
		case setSessionParam			= 0x80
		case getSessionParam			= 0x81
		case recalibratePPG				= 0xed
		case airplaneMode				= 0xf4
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
	var getAllPacketsAcknowledgeComplete: ((_ successful: Bool, _ ack: Bool)->())?
	var getNextPacketComplete: ((_ successful: Bool, _ error: nextPacketStatusType, _ caughtUp: Bool, _ packet: String)->())?
	var getPacketCountComplete: ((_ successful: Bool, _ count: Int)->())?
	var startManualComplete: ((_ successful: Bool)->())?
	var stopManualComplete: ((_ successful: Bool)->())?
	var ledComplete: ((_ successful: Bool)->())?
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

	var endSleepStatus: ((_ hasSleep: Bool)->())?
	var buttonClicked: ((_ presses: Int)->())?
	
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
	var getPairedComplete: ((_ successful: Bool, _ paired: Bool)->())?
	var setPairedComplete: ((_ successful: Bool)->())?
	var setUnpairedComplete: ((_ successful: Bool)->())?
	var getPageThresholdComplete: ((_ successful: Bool, _ threshold: Int)->())?
	var setPageThresholdComplete: ((_ successful: Bool)->())?
	var deletePageThresholdComplete: ((_ successful: Bool)->())?
	
	var dataPackets: ((_ packets: String)->())?
	var dataComplete: ((_ bad_fw_read_count: Int, _ bad_fw_parse_count: Int, _ overflow_count: Int, _ bad_sdk_parse_count: Int)->())?
	var dataFailure: (()->())?
		
	var recalibratePPGComplete: ((_ successful: Bool)->())?

	var setSessionParamComplete: ((_ successful: Bool, _ parameter: sessionParameterType)->())?
	var getSessionParamComplete: ((_ successful: Bool, _ parameter: sessionParameterType, _ value: Int)->())?
	var resetSessionParamsComplete: ((_ successful: Bool)->())?
	var acceptSessionParamsComplete: ((_ successful: Bool)->())?
	
	var getRawLoggingStatusComplete: ((_ successful: Bool, _ enabled: Bool)->())?
	var getWornOverrideStatusComplete: ((_ successful: Bool, _ overridden: Bool)->())?
	
	var airplaneModeComplete: ((_ successful: Bool)->())?
		
	var firmwareVersion						: String = ""
	
	internal var mDataPackets				: [biostrapDataPacket]!
	internal var mCRCOK						: Bool = true
	internal var mExpectedSequenceNumber	: Int = 0
	internal var mCRCFailCount				: Int = 0
	
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
				//logX?.v ("\(name): Not testing - allow")
				return true
			}
			
			count = count + 1
			if (count >= limit) {
				logX?.v ("\(name): At limit - allow")
				count	= 0
				return true
			}
			else {
				logX?.v ("\(name): Not at limit - disallow \(count) != \(limit)")
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
	override init(_ peripheral: CBPeripheral, characteristic: CBCharacteristic, commandQ: CommandQ?) {
		mCRCIgnoreTest	= testStruct(name: "CRC Ignore", enable: false, limit: 3)
		mCRCFailTest	= testStruct(name: "CRC Fail", enable: false, limit: 3)
		
		mCRCOK					= false
		mExpectedSequenceNumber	= 0
		mCRCFailCount			= 0

		super.init (peripheral, characteristic: characteristic, commandQ: commandQ)

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
		logX?.v("\(pID): \(newEpoch)")

		var data = Data()
		data.append(commands.writeEpoch.rawValue)
		data.append(newEpoch.leData32)
		pCommandQ?.write(pCharacteristic, data: data, type: .withResponse)
	}
	
	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func readEpoch() {
		logX?.v("\(pID)")

		var data = Data()
		data.append(commands.readEpoch.rawValue)
		pCommandQ?.write(pCharacteristic, data: data, type: .withResponse)
	}
	
	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func endSleep() {
		logX?.v("\(pID)")

		var data = Data()
		data.append(commands.endSleep.rawValue)
		pCommandQ?.write(pCharacteristic, data: data, type: .withResponse)
	}
	
	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	internal func mSimpleCommand(_ command: commands) -> Bool {
		var data = Data()
		data.append(command.rawValue)
		pCommandQ?.write(pCharacteristic, data: data, type: .withResponse)
		return (true)
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func getNextPacket(_ single: Bool) {
		logX?.v("\(pID): Single? \(single)")

		var data = Data()
		data.append(commands.getNextPacket.rawValue)
		data.append(single ? 0x01 : 0x00)
		pCommandQ?.write(pCharacteristic, data: data, type: .withResponse)
	}
	
	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func getAllPackets(pages: Int, delay: Int, newStyle: Bool) {
		logX?.v("\(pID): Pages: \(pages), delay: \(delay) ms")

		self.pFailedDecodeCount	= 0
		
		var data = Data()
		data.append(commands.getAllPackets.rawValue)
			
		if (newStyle) {
			data.append(contentsOf: pages.leData16)
			data.append(contentsOf: delay.leData16)
		}

		pCommandQ?.write(pCharacteristic, data: data, type: .withResponse)
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func getAllPacketsAcknowledge(_ ack: Bool) {
		logX?.v("\(pID): Ack: \(ack)")
		
		var data = Data()
		data.append(commands.getAllPacketsAcknowledge.rawValue)
		data.append(ack ? 0x01 : 0x00)
		pCommandQ?.write(pCharacteristic, data: data, type: .withResponse)
	}
	
	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func getPacketCount() {
		logX?.v("\(pID)")

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
		logX?.v("\(pID)")

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
		logX?.v("\(pID)")

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
		logX?.v("\(pID)")
		
		var data = Data()
		data.append(commands.startManual.rawValue)
		data.append(algorithms.commandByte)
		pCommandQ?.write(pCharacteristic, data: data, type: .withResponse)
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func stopManual() {
		logX?.v("\(pID)")
		
		if (!mSimpleCommand(.stopManual)) { self.stopManualComplete?(false) }
	}
	
	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func userLED(red: Bool, green: Bool, blue: Bool, blink: Bool, seconds: Int) {
		logX?.v("\(pID): Red: \(red), Green: \(green), Blue: \(blue), Blink: \(blink), Seconds: \(seconds)")
		
		var data = Data()
		data.append(commands.led.rawValue)
		data.append(red ? 0x01 : 0x00)		// Red
		data.append(green ? 0x01 : 0x00)	// Green
		data.append(blue ? 0x01 : 0x00)		// Blue
		data.append(blink ? 0x01 : 0x00)	// Blink
		data.append(UInt8(seconds & 0xff))	// Seconds

		pCommandQ?.write(pCharacteristic, data: data, type: .withResponse)
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func enterShipMode() {
		logX?.v("\(pID)")
		
		var data = Data()
		data.append(commands.enterShipMode.rawValue)
		pCommandQ?.write(pCharacteristic, data: data, type: .withResponse)
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func writeSerialNumber(_ partID: String) {
		logX?.v("\(pID): \(partID)")
		
		var data = Data()
		data.append(commands.setDeviceParam.rawValue)
		data.append(deviceParameterType.serialNumber.rawValue)
		data.append(contentsOf: [UInt8](partID.utf8))
		
		pCommandQ?.write(pCharacteristic, data: data, type: .withResponse)
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func readSerialNumber() {
		logX?.v("\(pID)")
		
		var data = Data()
		data.append(commands.getDeviceParam.rawValue)
		data.append(deviceParameterType.serialNumber.rawValue)
		pCommandQ?.write(pCharacteristic, data: data, type: .withResponse)
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func deleteSerialNumber() {
		logX?.v("\(pID)")
		
		var data = Data()
		data.append(commands.delDeviceParam.rawValue)
		data.append(deviceParameterType.serialNumber.rawValue)
		pCommandQ?.write(pCharacteristic, data: data, type: .withResponse)
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func writeAdvInterval(_ seconds: Int) {
		logX?.v("\(pID): \(seconds)")
		
		var data = Data()
		data.append(commands.setDeviceParam.rawValue)
		data.append(deviceParameterType.advertisingInterval.rawValue)
		data.append(contentsOf: seconds.leData32)
		
		logX?.v ("\(data.hexString)")

		pCommandQ?.write(pCharacteristic, data: data, type: .withResponse)
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func readAdvInterval() {
		logX?.v("\(pID)")
		
		var data = Data()
		data.append(commands.getDeviceParam.rawValue)
		data.append(deviceParameterType.advertisingInterval.rawValue)
		pCommandQ?.write(pCharacteristic, data: data, type: .withResponse)
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func deleteAdvInterval() {
		logX?.v("\(pID)")
		
		var data = Data()
		data.append(commands.delDeviceParam.rawValue)
		data.append(deviceParameterType.advertisingInterval.rawValue)
		pCommandQ?.write(pCharacteristic, data: data, type: .withResponse)
	}
	
	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func clearChargeCycles() {
		logX?.v("\(pID)")
		
		var data = Data()
		data.append(commands.setDeviceParam.rawValue)
		data.append(deviceParameterType.chargeCycle.rawValue)
		pCommandQ?.write(pCharacteristic, data: data, type: .withResponse)
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func readChargeCycles() {
		logX?.v("\(pID)")
		
		var data = Data()
		data.append(commands.getDeviceParam.rawValue)
		data.append(deviceParameterType.chargeCycle.rawValue)
		pCommandQ?.write(pCharacteristic, data: data, type: .withResponse)
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func readCanLogDiagnostics() {
		logX?.v("\(pID)")
		
		var data = Data()
		data.append(commands.getDeviceParam.rawValue)
		data.append(deviceParameterType.canLogDiagnostics.rawValue)
		pCommandQ?.write(pCharacteristic, data: data, type: .withResponse)
	}
	
	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func updateCanLogDiagnostics(_ allow: Bool) {
		logX?.v("\(pID): Allow Diagnostics? \(allow)")
		
		var data = Data()
		data.append(commands.setDeviceParam.rawValue)
		data.append(deviceParameterType.canLogDiagnostics.rawValue)
		data.append(allow ? 0x01 : 0x00)
		
		pCommandQ?.write(pCharacteristic, data: data, type: .withResponse)
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func allowPPG(_ allow: Bool) {
		logX?.v("\(pID)")
		
		var data = Data()
		data.append(commands.allowPPG.rawValue)
		data.append(allow ? 0x01 : 0x00)
		pCommandQ?.write(pCharacteristic, data: data, type: .withResponse)
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func wornCheck() {
		logX?.v("\(pID)")
		
		var data = Data()
		data.append(commands.wornCheck.rawValue)
		pCommandQ?.write(pCharacteristic, data: data, type: .withResponse)
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func rawLogging(_ enable: Bool) {
		logX?.v("\(pID): \(enable)")
		
		var data = Data()
		data.append(commands.logRaw.rawValue)
		data.append(enable ? 0x01 : 0x00)
		pCommandQ?.write(pCharacteristic, data: data, type: .withResponse)
	}
	
	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func getRawLoggingStatus() {
		logX?.v("\(pID)")
		
		var data = Data()
		data.append(commands.getRawLoggingStatus.rawValue)
		pCommandQ?.write(pCharacteristic, data: data, type: .withResponse)
	}
	
	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func getWornOverrideStatus() {
		logX?.v("\(pID)")
		
		var data = Data()
		data.append(commands.getWornOverrideStatus.rawValue)
		pCommandQ?.write(pCharacteristic, data: data, type: .withResponse)
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func airplaneMode() {
		logX?.v("\(pID)")
		
		if (!mSimpleCommand(.airplaneMode)) { self.airplaneModeComplete?(false) }
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func reset() {
		logX?.v("\(pID)")

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
		logX?.v("\(pID): \(parameter) - \(value)")
		
		var data = Data()
		data.append(commands.setSessionParam.rawValue)
		data.append(parameter.rawValue)
		data.append(value.leData32)
		pCommandQ?.write(pCharacteristic, data: data, type: .withResponse)
	}
	
	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func getSessionParam(_ parameter: sessionParameterType) {
		logX?.v("\(pID): \(parameter)")
		
		var data = Data()
		data.append(commands.getSessionParam.rawValue)
		data.append(parameter.rawValue)
		pCommandQ?.write(pCharacteristic, data: data, type: .withResponse)
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func resetSessionParams() {
		logX?.v("\(pID)")
		
		var data = Data()
		data.append(commands.setSessionParam.rawValue)
		data.append(sessionParameterType.reset.rawValue)
		pCommandQ?.write(pCharacteristic, data: data, type: .withResponse)
	}
	
	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func acceptSessionParams() {
		logX?.v("\(pID)")
		
		var data = Data()
		data.append(commands.setSessionParam.rawValue)
		data.append(sessionParameterType.accept.rawValue)
		pCommandQ?.write(pCharacteristic, data: data, type: .withResponse)
	}

	//--------------------------------------------------------------------------------
	// Function Name: Manufacturing Test
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	#if UNIVERSAL || ALTER
	func alterManufacturingTest(_ test: alterManufacturingTestType) {
		logX?.v("\(pID): \(test.title)")
		
		var data = Data()
		data.append(commands.manufacturingTest.rawValue)
		data.append(test.rawValue)
		pCommandQ?.write(pCharacteristic, data: data, type: .withResponse)
	}
	#endif

	#if UNIVERSAL || KAIROS
	func kairosManufacturingTest(_ test: kairosManufacturingTestType) {
		logX?.v("\(pID): \(test.title)")
		
		var data = Data()
		data.append(commands.manufacturingTest.rawValue)
		data.append(test.rawValue)
		pCommandQ?.write(pCharacteristic, data: data, type: .withResponse)
	}
	#endif
		
	//--------------------------------------------------------------------------------
	// Function Name: setAskForButtonResponse
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func setAskForButtonResponse(_ enable: Bool) {
		logX?.v("\(pID): Enabled = \(enable)")
		
		var data = Data()
		data.append(commands.setAskForButtonResponse.rawValue)
		data.append(enable ? 0x01 : 0x00)
		pCommandQ?.write(pCharacteristic, data: data, type: .withResponse)
	}
	
	//--------------------------------------------------------------------------------
	// Function Name: getAskForButtonResponse
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func getAskForButtonResponse() {
		logX?.v("\(pID)")
		
		var data = Data()
		data.append(commands.getAskForButtonResponse.rawValue)
		pCommandQ?.write(pCharacteristic, data: data, type: .withResponse)
	}

	//--------------------------------------------------------------------------------
	// Function Name: setHRZoneColor
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func setHRZoneColor(_ type: hrZoneRangeType, red: Bool, green: Bool, blue: Bool, on_milliseconds: Int, off_milliseconds: Int) {
		logX?.v("\(pID): \(type.title) -> R \(red), G \(green), B \(blue).  On: \(on_milliseconds), Off: \(off_milliseconds)")
		
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
		pCommandQ?.write(pCharacteristic, data: data, type: .withResponse)
	}
	
	//--------------------------------------------------------------------------------
	// Function Name: getHRZoneColor
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func getHRZoneColor(_ type: hrZoneRangeType) {
		logX?.v("\(pID): \(type.title)")
		
		var data = Data()
		data.append(commands.getHRZoneColor.rawValue)
		data.append(type.rawValue)
		pCommandQ?.write(pCharacteristic, data: data, type: .withResponse)
	}
	
	//--------------------------------------------------------------------------------
	// Function Name: setHRZoneRange
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func setHRZoneRange(_ enabled: Bool, high_value: Int, low_value: Int) {
		logX?.v("\(pID): Enabled: \(enabled) -> High Value: \(high_value), Low Value: \(low_value)")
		
		var data = Data()
		data.append(commands.setHRZoneRange.rawValue)
		data.append(enabled ? 0x01 : 0x00)
		data.append(UInt8(high_value))
		data.append(UInt8(low_value))
		pCommandQ?.write(pCharacteristic, data: data, type: .withResponse)
	}
	
	//--------------------------------------------------------------------------------
	// Function Name: getHRZoneRange
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func getHRZoneRange() {
		logX?.v("\(pID)")
		
		var data = Data()
		data.append(commands.getHRZoneRange.rawValue)
		pCommandQ?.write(pCharacteristic, data: data, type: .withResponse)
	}
	
	//--------------------------------------------------------------------------------
	// Function Name: getPPGAlgorithm
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func getPPGAlgorithm() {
		logX?.v("\(pID)")
		
		var data = Data()
		data.append(commands.getPPGAlgorithm.rawValue)
		pCommandQ?.write(pCharacteristic, data: data, type: .withResponse)
	}

	//--------------------------------------------------------------------------------
	// Function Name: setAdvertiseAsHRM
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func setAdvertiseAsHRM(_ asHRM: Bool) {
		logX?.v("\(pID): As HRM? (\(asHRM)")
		
		var data = Data()
		data.append(commands.setAdvertiseAsHRM.rawValue)
		data.append(asHRM ? 0x01 : 0x00)
		pCommandQ?.write(pCharacteristic, data: data, type: .withResponse)
	}

	//--------------------------------------------------------------------------------
	// Function Name: getAdvertiseAsHRM
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func getAdvertiseAsHRM() {
		logX?.v("\(pID)")
		
		var data = Data()
		data.append(commands.getAdvertiseAsHRM.rawValue)
		pCommandQ?.write(pCharacteristic, data: data, type: .withResponse)
	}
	
	//--------------------------------------------------------------------------------
	// Function Name: setButtonCommand
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func setButtonCommand(_ tap: buttonTapType, command: buttonCommandType) {
		logX?.v("\(pID): \(tap.title) -> \(command.title)")
		
		var data = Data()
		data.append(commands.setButtonCommand.rawValue)
		data.append(tap.rawValue)
		data.append(command.rawValue)
		pCommandQ?.write(pCharacteristic, data: data, type: .withResponse)
	}
	
	//--------------------------------------------------------------------------------
	// Function Name: getButtonCommand
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func getButtonCommand(_ tap: buttonTapType) {
		logX?.v("\(pID): \(tap.title)")
		
		var data = Data()
		data.append(commands.getButtonCommand.rawValue)
		data.append(tap.rawValue)
		pCommandQ?.write(pCharacteristic, data: data, type: .withResponse)
	}
	
	//--------------------------------------------------------------------------------
	// Function Name: setPaired
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func setPaired() {
		logX?.v("\(pID)")
		
		var data = Data()
		data.append(commands.setDeviceParam.rawValue)
		data.append(deviceParameterType.paired.rawValue)
		data.append(0x01)
		pCommandQ?.write(pCharacteristic, data: data, type: .withResponse)
	}
	
	//--------------------------------------------------------------------------------
	// Function Name: setUnpaired
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func setUnpaired() {
		logX?.v("\(pID)")
		
		var data = Data()
		data.append(commands.delDeviceParam.rawValue)
		data.append(deviceParameterType.paired.rawValue)
		pCommandQ?.write(pCharacteristic, data: data, type: .withResponse)
	}
	

	//--------------------------------------------------------------------------------
	// Function Name: getPaired
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func getPaired() {
		logX?.v("\(pID)")
		
		var data = Data()
		data.append(commands.getDeviceParam.rawValue)
		data.append(deviceParameterType.paired.rawValue)
		pCommandQ?.write(pCharacteristic, data: data, type: .withResponse)
	}
	
	//--------------------------------------------------------------------------------
	// Function Name: setPageThreshold
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func setPageThreshold(_ threshold: Int) {
		logX?.v("\(pID): \(threshold)")
		
		var data = Data()
		data.append(commands.setDeviceParam.rawValue)
		data.append(deviceParameterType.pageThreshold.rawValue)
		data.append(UInt8(threshold))
		pCommandQ?.write(pCharacteristic, data: data, type: .withResponse)
	}
	
	//--------------------------------------------------------------------------------
	// Function Name: getPageThreshold
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func getPageThreshold() {
		logX?.v("\(pID)")
		
		var data = Data()
		data.append(commands.getDeviceParam.rawValue)
		data.append(deviceParameterType.pageThreshold.rawValue)
		pCommandQ?.write(pCharacteristic, data: data, type: .withResponse)
	}
	
	
	//--------------------------------------------------------------------------------
	// Function Name: deletePageThreshold
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func deletePageThreshold() {
		logX?.v("\(pID)")
		
		var data = Data()
		data.append(commands.delDeviceParam.rawValue)
		data.append(deviceParameterType.pageThreshold.rawValue)
		pCommandQ?.write(pCharacteristic, data: data, type: .withResponse)
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func recalibratePPG() {
		logX?.v("\(pID)")
		
		var data = Data()
		data.append(commands.recalibratePPG.rawValue)
		pCommandQ?.write(pCharacteristic, data: data, type: .withResponse)
	}
	
	//--------------------------------------------------------------------------------
	// Function Name: Validate CRC
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	internal func mValidateCRC() {
		//logX?.v("\(pID): \(mCRCOK)")
		
		if (mCRCOK == false) {
			mCRCFailCount	= mCRCFailCount + 1
			if (mCRCFailCount == 10) { dataFailure?() }
		}
		else { mCRCFailCount	= 0 }
		
		var data = Data()
		data.append(commands.validateCRC.rawValue)
		data.append(mCRCOK ? 0x01 : 0x00)
		pCommandQ?.write(pCharacteristic, data: data, type: .withResponse)
		
		mCRCOK				= true
	}
	
	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	internal func mProcessUpdateValue(_ data: Data) {
		logX?.v ("\(pID): \(data.hexString)")
		if let response = notifications(rawValue: data[0]) {
			switch (response) {
			case .completion:
				if (data.count >= 3) {
					if let command = commands(rawValue: data[1]) {
						let successful = (data[2] == 0x01)
						//logX?.v ("\(pID): Got completion for '\(command)' with \(successful) status: Bytes = \(data.hexString)")
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
						case .getAllPacketsAcknowledge	:
							if (data.count == 4) {
								self.getAllPacketsAcknowledgeComplete?(successful, (data[3] == 0x01))
							}
							else {
								self.getAllPacketsAcknowledgeComplete?(false, false)
							}
						case .getNextPacket :
							if (data.count >= 5) {
								let error_code	= nextPacketStatusType(rawValue: data[3])
								let caughtUp	= (data[4] == 0x01)

								if (successful) {
									let dataPackets = self.pParseDataPackets(data.subdata(in: Range(5...(data.count - 1))))
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

						case .disableWornDetect	: self.disableWornDetectComplete?(successful)
						case .enableWornDetect	: self.enableWornDetectComplete?(successful)
						case .startManual		: self.startManualComplete?(successful)
						case .stopManual		: self.stopManualComplete?(successful)
						case .led				: self.ledComplete?(successful)

						case .enterShipMode		: self.enterShipModeComplete?(successful)
						case .setDeviceParam	:
							if let parameter = deviceParameterType(rawValue: data[3]) {
								switch (parameter) {
								case .advertisingInterval	: self.writeAdvIntervalComplete?(successful)
								case .serialNumber			: self.writeSerialNumberComplete?(successful)
								case .chargeCycle			: self.clearChargeCyclesComplete?(successful)
								case .canLogDiagnostics		: self.updateCanLogDiagnosticsComplete?(successful)
								case .paired				: self.setPairedComplete?(successful)
								case .pageThreshold			: self.setPageThresholdComplete?(successful)
								}
							}
							else {
								logX?.e ("\(pID): Do not know what to do with parameter: \(String(format: "0x%02X", data[3]))")
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
										let cycles = data.subdata(in: Range(4...7)).leFloat
										self.readChargeCyclesComplete?(successful, cycles)
									case .canLogDiagnostics		:
										let canLog = (data[4] != 0x00)
										self.readCanLogDiagnosticsComplete?(successful, canLog)
									case .paired:
										let paired = (data[4] != 0x00)
										self.getPairedComplete?(successful, paired)
									case .pageThreshold:
										logX?.v ("\(pID): \(response): Data: \(data.hexString)")
										self.getPageThresholdComplete?(successful, Int(data[4]))
									}
								}
								else {
									switch (parameter) {
									case .advertisingInterval	: self.readAdvIntervalComplete?(false, 0)
									case .serialNumber			: self.readSerialNumberComplete?(false, "")
									case .chargeCycle			: self.readChargeCyclesComplete?(false, 0.0)
									case .canLogDiagnostics		: self.readCanLogDiagnosticsComplete?(false, false)
									case .paired				: self.getPairedComplete?(false, false)
									case .pageThreshold			: self.getPageThresholdComplete?(false, 1)
									}
								}
							}
							else {
								logX?.e ("\(pID): Do not know what to do with parameter: \(String(format: "0x%02X", data[3]))")
							}
						case .delDeviceParam	:
							if let parameter = deviceParameterType(rawValue: data[3]) {
								switch (parameter) {
								case .advertisingInterval	: self.deleteAdvIntervalComplete?(successful)
								case .serialNumber			: self.deleteSerialNumberComplete?(successful)
								case .chargeCycle			: logX?.e ("\(pID): Should not have been able to delete \(parameter.title)")
								case .canLogDiagnostics		: logX?.e ("\(pID): Should not have been able to delete \(parameter.title)")
								case .paired				: self.setUnpairedComplete?(successful)
								case .pageThreshold			: self.deletePageThresholdComplete?(successful)
								}
							}
							else {
								logX?.e ("\(pID): Do not know what to do with parameter: \(String(format: "0x%02X", data[3]))")
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
								logX?.e ("\(pID): Was not able to encode parameter: \(String(format: "0x%02X", data[3]))")
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
								logX?.e ("\(pID): Was not able to encode parameter: \(String(format: "0x%02X", data[3]))")
							}

						case .manufacturingTest	: self.manufacturingTestComplete?(successful)
						case .recalibratePPG	: self.recalibratePPGComplete?(successful)
							
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
							
						case .airplaneMode		: self.airplaneModeComplete?(successful)
						case .reset				: self.resetComplete?(successful)
						case .validateCRC		: break
							//logX?.v ("\(pID): Got Validate CRC completion: \(data.hexString)")
						}
					}
					else {
						logX?.e ("\(pID): Unknown command: \(data.hexString)")
					}
				}
				else {
					logX?.e ("\(pID): Incorrect length for completion: \(data.hexString)")
				}
				
				pCommandQ?.remove() // These were updates from a write, so queue can now move on
				
			case .dataPacket:
				if (data.count > 3) {	// Accounts for header byte and sequence number
					//logX?.v ("\(pID): \(data.subdata(in: Range(0...7)).hexString)")
					//logX?.v ("\(pID): \(data.hexString)")
					let sequence_number = data.subdata(in: Range(1...2)).leUInt16
					if (sequence_number == mExpectedSequenceNumber) {
						//logX?.v ("\(pID): Sequence Number Match: \(sequence_number).  Expected: \(mExpectedSequenceNumber)")
					}
					else {
						logX?.e ("\(pID): \(response) - Sequence Number Fail: \(sequence_number). Expected: \(mExpectedSequenceNumber): \(data.hexString)")
						mCRCOK	= false
					}
					mExpectedSequenceNumber = mExpectedSequenceNumber + 1
					
					if (mCRCOK) {
						let dataPackets = self.pParseDataPackets(data.subdata(in: Range(3...(data.count - 1))))
						mDataPackets.append(contentsOf: dataPackets)
					}
				}
				else {
					logX?.e ("\(pID): Bad data length for data packet: \(data.hexString)")
					mCRCOK	= false
				}
				
			case .worn:
				if      (data[1] == 0x00) { deviceWornStatus?(false) }
				else if (data[1] == 0x01) { deviceWornStatus?(true)  }
				else {
					logX?.e ("\(pID): Cannot parse worn status: \(data[1])")
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
					self.dataComplete?(bad_read_count, bad_parse_count, overflow_count, self.pFailedDecodeCount)
				}
				else {
					self.dataComplete?(-1, -1, -1, self.pFailedDecodeCount)
				}
				
			case .endSleepStatus:
				if (data.count == 2) {
					let hasSleep	= data[1] == 0x01 ? true : false
					self.endSleepStatus?(hasSleep)
				}
				else {
					logX?.e ("\(pID): Cannot parse 'endSleepStatus': \(data.hexString)")
				}
				
			case .buttonResponse:
				if (data.count == 2) {
					let presses	= Int(data[1])
					self.buttonClicked?(presses)
				}
				else {
					logX?.e ("\(pID): Cannot parse 'buttonResponse': \(data.hexString)")
				}
				
			case .validateCRC:
				//logX?.v ("\(pID): \(response) - \(data.hexString)")
				
				let sequence_number = data.subdata(in: Range(1...2)).leUInt16
				if (sequence_number == mExpectedSequenceNumber) {
					//logX?.v ("\(pID): SN Match: \(sequence_number).  Expected: \(mExpectedSequenceNumber)")
				}
				else {
					logX?.e ("\(pID): \(response) - Sequence Number Fail: \(sequence_number). Expected: \(mExpectedSequenceNumber): \(data.hexString)")
					mCRCOK	= false
				}

				let allowResponse		= mCRCIgnoreTest.check()
				let allowGoodResponse	= mCRCFailTest.check()
										
				if (allowResponse) {
					if (allowGoodResponse) {
						if (mCRCOK == true) {
							//logX?.v ("\(pID): Validate CRC Passed: Let received packets through")
							
							if (mDataPackets.count > 0) {
								do {
									let jsonData = try JSONEncoder().encode(mDataPackets)
									if let jsonString = String(data: jsonData, encoding: .utf8) {
									self.dataPackets?(jsonString)
								}
									else { logX?.e ("\(pID): Cannot make string from json data") }
								}
								catch { logX?.e ("\(pID): Cannot make JSON data") }
						   }
						}
						else {
							logX?.v ("\(pID): \(response) Failed: Do not let packets through")
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
				#if ALTER
				if (data.count == 3) {
					let testResult = alterManufacturingTestResult(data.subdata(in: Range(1...2)))
					do {
						let jsonData = try JSONEncoder().encode(testResult)
						if let jsonString = String(data: jsonData, encoding: .utf8) {
							self.manufacturingTestResult?(true, jsonString)
						}
						else {
							logX?.e ("\(pID): Result jsonString Failed")
							self.manufacturingTestResult?(false, "")
						}
					}
					catch {
						logX?.e ("\(pID): Result jsonData Failed")
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
							logX?.e ("\(pID): Result jsonString Failed")
							self.manufacturingTestResult?(false, "")
						}
					}
					catch {
						logX?.e ("\(pID): Result jsonData Failed")
						self.manufacturingTestResult?(false, "")
					}
				}
				else {
					self.manufacturingTestResult?(false, "")
				}
				#endif

				#if UNIVERSAL
				switch (type) {
				case .alter		:
					if (data.count == 3) {
						let testResult = alterManufacturingTestResult(data.subdata(in: Range(1...2)))
						do {
							let jsonData = try JSONEncoder().encode(testResult)
							if let jsonString = String(data: jsonData, encoding: .utf8) {
								self.manufacturingTestResult?(true, jsonString)
							}
							else {
								logX?.e ("\(pID): Result jsonString Failed")
								self.manufacturingTestResult?(false, "")
							}
						}
						catch {
							logX?.e ("\(pID): Result jsonData Failed")
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
								logX?.e ("\(pID): Result jsonString Failed")
								self.manufacturingTestResult?(false, "")
							}
						}
						catch {
							logX?.e ("\(pID): Result jsonData Failed")
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
				
			case .streamPacket: logX?.e ("\(pID): Should not get '\(response)' on this characteristic!")
			case .dataAvailable: logX?.e ("\(pID): Should not get '\(response)' on this characteristic!")
			}
		}
		else {
			logX?.e ("\(pID): Unknown update: \(data.hexString)")
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
						logX?.e ("\(pID): Hmmm..... Packet CRC Error! CRC : \(String(format:"0x%08X", crc_received)): \(String(format:"0x%08X", crc_calculated))")
						mCRCOK = false;
						mExpectedSequenceNumber = mExpectedSequenceNumber + 1	// go ahead and increase the expected sequence number.  already going to create retransmit.  this avoids other expected sequence checks from failling
					}

					mProcessUpdateValue(data.subdata(in: Range(0...(data.count - 5))))
				}
				else {
					logX?.e ("\(pID): Cannot calculate packet CRC: Not enough data.  Length = \(data.count): \(data.hexString)")
					return
				}
				
			}
			else {
				logX?.e ("\(pID): Missing data")
			}
		}
		else { logX?.e ("\(pID): Missing characteristic") }
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
