//
//  customMainCharacteristic.swift
//  biostrapDeviceSDK
//
//  Created by Joseph A. Bennett on 5/12/21.
//

import Foundation
import CoreBluetooth
import Combine
import zlib

class customMainCharacteristic: CharacteristicTemplate {
	
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
    
    @Published private(set) var epoch: Int?
    @Published private(set) var worn: Bool?
    @Published private(set) var canLogDiagnostics: Bool?
    @Published private(set) var wornCheckResult: DeviceWornCheckResultType?
    @Published private(set) var charging: Bool?
    @Published private(set) var on_charger: Bool?
    @Published private(set) var charge_error: Bool?
    @Published private(set) var buttonTaps: Int?
    @Published private(set) var ppgMetrics: ppgMetricsType?
    @Published private(set) var hrZoneLEDBelow: hrZoneLEDValueType?
    @Published private(set) var hrZoneLEDWithin: hrZoneLEDValueType?
    @Published private(set) var hrZoneLEDAbove: hrZoneLEDValueType?
    @Published private(set) var hrZoneRange: hrZoneRangeValueType?
    @Published private(set) var ppgCapturePeriod: Int?
    @Published private(set) var ppgCaptureDuration: Int?
    @Published private(set) var tag: String?
    @Published private(set) var paired: Bool?
    @Published private(set) var advertisingPageThreshold: Int?
    @Published private(set) var singleButtonPressAction: buttonCommandType?
    @Published private(set) var doubleButtonPressAction: buttonCommandType?
    @Published private(set) var tripleButtonPressAction: buttonCommandType?
    @Published private(set) var longButtonPressAction: buttonCommandType?
    @Published private(set) var rawLogging: Bool?
    @Published private(set) var wornOverridden: Bool?
    @Published private(set) var advertisingInterval: Int?
    @Published private(set) var chargeCycles: Float?
    @Published private(set) var advertiseAsHRM: Bool?
    @Published private(set) var buttonResponseEnabled: Bool?

	// MARK: Callbacks
    let writeEpochComplete = PassthroughSubject<DeviceCommandCompletionStatus, Never>()
    let getAllPacketsComplete = PassthroughSubject<DeviceCommandCompletionStatus, Never>()
    let getAllPacketsAcknowledgeComplete = PassthroughSubject<(DeviceCommandCompletionStatus, Bool), Never>()
    let getNextPacketComplete = PassthroughSubject<(DeviceCommandCompletionStatus, nextPacketStatusType, Bool, String), Never>()
    let getPacketCountComplete = PassthroughSubject<(DeviceCommandCompletionStatus, Int), Never>()
    let startManualComplete = PassthroughSubject<DeviceCommandCompletionStatus, Never>()
    let stopManualComplete = PassthroughSubject<DeviceCommandCompletionStatus, Never>()
    let ledComplete = PassthroughSubject<DeviceCommandCompletionStatus, Never>()
    let enterShipModeComplete = PassthroughSubject<DeviceCommandCompletionStatus, Never>()

    let writeSerialNumberComplete = PassthroughSubject<DeviceCommandCompletionStatus, Never>()
    let readSerialNumberComplete = PassthroughSubject<(DeviceCommandCompletionStatus, String), Never>()
    let deleteSerialNumberComplete = PassthroughSubject<DeviceCommandCompletionStatus, Never>()
    let writeAdvIntervalComplete = PassthroughSubject<DeviceCommandCompletionStatus, Never>()
    let readAdvIntervalComplete = PassthroughSubject<(DeviceCommandCompletionStatus, Int), Never>()
    let deleteAdvIntervalComplete = PassthroughSubject<DeviceCommandCompletionStatus, Never>()
    let clearChargeCyclesComplete = PassthroughSubject<DeviceCommandCompletionStatus, Never>()
    let readCanLogDiagnosticsComplete = PassthroughSubject<(DeviceCommandCompletionStatus, Bool), Never>()
    let updateCanLogDiagnosticsComplete = PassthroughSubject<DeviceCommandCompletionStatus, Never>()

    let readChargeCyclesComplete = PassthroughSubject<(DeviceCommandCompletionStatus, Float), Never>()
    let rawLoggingComplete = PassthroughSubject<DeviceCommandCompletionStatus, Never>()
    let allowPPGComplete = PassthroughSubject<DeviceCommandCompletionStatus, Never>()
    let wornCheckComplete = PassthroughSubject<(DeviceCommandCompletionStatus, String, Int), Never>()
    let resetComplete = PassthroughSubject<DeviceCommandCompletionStatus, Never>()
    let readEpochComplete = PassthroughSubject<(DeviceCommandCompletionStatus, Int), Never>()
    let disableWornDetectComplete = PassthroughSubject<DeviceCommandCompletionStatus, Never>()
    let enableWornDetectComplete = PassthroughSubject<DeviceCommandCompletionStatus, Never>()
    let endSleepComplete = PassthroughSubject<DeviceCommandCompletionStatus, Never>()
    let manufacturingTestComplete = PassthroughSubject<DeviceCommandCompletionStatus, Never>()

    let ppgFailed = PassthroughSubject<Int, Never>()
    let manufacturingTestResult = PassthroughSubject<(Bool, String), Never>()

    let endSleepStatus = PassthroughSubject<Bool, Never>()
    
    let setAskForButtonResponseComplete = PassthroughSubject<(DeviceCommandCompletionStatus, Bool), Never>()
    let getAskForButtonResponseComplete = PassthroughSubject<(DeviceCommandCompletionStatus, Bool), Never>()
    let setHRZoneColorComplete = PassthroughSubject<(DeviceCommandCompletionStatus, hrZoneRangeType), Never>()
    let getHRZoneColorComplete = PassthroughSubject<(DeviceCommandCompletionStatus, hrZoneRangeType, Bool, Bool, Bool, Int, Int), Never>()
    let setHRZoneRangeComplete = PassthroughSubject<DeviceCommandCompletionStatus, Never>()
    let getHRZoneRangeComplete = PassthroughSubject<(DeviceCommandCompletionStatus, Bool, Int, Int), Never>()
    let getPPGAlgorithmComplete = PassthroughSubject<(DeviceCommandCompletionStatus, ppgAlgorithmConfiguration, eventType), Never>()
    let setAdvertiseAsHRMComplete = PassthroughSubject<(DeviceCommandCompletionStatus, Bool), Never>()
    let getAdvertiseAsHRMComplete = PassthroughSubject<(DeviceCommandCompletionStatus, Bool), Never>()
    let setButtonCommandComplete = PassthroughSubject<(DeviceCommandCompletionStatus, buttonTapType, buttonCommandType), Never>()
    let getButtonCommandComplete = PassthroughSubject<(DeviceCommandCompletionStatus, buttonTapType, buttonCommandType), Never>()
    let getPairedComplete = PassthroughSubject<(DeviceCommandCompletionStatus, Bool), Never>()
    let setPairedComplete = PassthroughSubject<DeviceCommandCompletionStatus, Never>()
    let setUnpairedComplete = PassthroughSubject<DeviceCommandCompletionStatus, Never>()
    let getPageThresholdComplete = PassthroughSubject<(DeviceCommandCompletionStatus, Int), Never>()
    let setPageThresholdComplete = PassthroughSubject<DeviceCommandCompletionStatus, Never>()
    let deletePageThresholdComplete = PassthroughSubject<DeviceCommandCompletionStatus, Never>()
    
    let dataPackets = PassthroughSubject<(Int, String), Never>()
    let dataComplete = PassthroughSubject<(Int, Int, Int, Int, Bool), Never>()
    let dataFailure = PassthroughSubject<Void, Never>()
        
    let recalibratePPGComplete = PassthroughSubject<DeviceCommandCompletionStatus, Never>()

    let setSessionParamComplete = PassthroughSubject<(DeviceCommandCompletionStatus, sessionParameterType), Never>()
    let getSessionParamComplete = PassthroughSubject<(DeviceCommandCompletionStatus, sessionParameterType, Int), Never>()
    let resetSessionParamsComplete = PassthroughSubject<DeviceCommandCompletionStatus, Never>()
    let acceptSessionParamsComplete = PassthroughSubject<DeviceCommandCompletionStatus, Never>()
    
    let getRawLoggingStatusComplete = PassthroughSubject<(DeviceCommandCompletionStatus, Bool), Never>()
    let getWornOverrideStatusComplete = PassthroughSubject<(DeviceCommandCompletionStatus, Bool), Never>()
    
    let airplaneModeComplete = PassthroughSubject<DeviceCommandCompletionStatus, Never>()
	
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
				//globals.log.v ("\(name): Not testing - allow")
				return true
			}
			
			count = count + 1
			if (count >= limit) {
				globals.log.v ("\(name): At limit - allow")
				count	= 0
				return true
			} else {
				globals.log.v ("\(name): Not at limit - disallow \(count) != \(limit)")
				return false
			}
		}
	}
	
	internal var mCRCIgnoreTest				: testStruct
	internal var mCRCFailTest				: testStruct
	
	override init() {
		mCRCIgnoreTest	= testStruct(name: "CRC Ignore", enable: false, limit: 3)
		mCRCFailTest	= testStruct(name: "CRC Fail", enable: false, limit: 3)
		
		mCRCOK					= false
		mExpectedSequenceNumber	= 0
		mCRCFailCount			= 0

		super.init()
		
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
		globals.log.v("\(id): \(newEpoch)")

		var data = Data()
		data.append(commands.writeEpoch.rawValue)
		data.append(newEpoch.leData32)
		commandQ?.write(characteristic, data: data, type: .withResponse)
	}
	
	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func readEpoch() {
		globals.log.v("\(id)")

		var data = Data()
		data.append(commands.readEpoch.rawValue)
		commandQ?.write(characteristic, data: data, type: .withResponse)
	}
	
	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func endSleep() {
		globals.log.v("\(id)")

		var data = Data()
		data.append(commands.endSleep.rawValue)
		commandQ?.write(characteristic, data: data, type: .withResponse)
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
		commandQ?.write(characteristic, data: data, type: .withResponse)
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
		globals.log.v("\(id): Single? \(single)")

		var data = Data()
		data.append(commands.getNextPacket.rawValue)
		data.append(single ? 0x01 : 0x00)
		commandQ?.write(characteristic, data: data, type: .withResponse)
	}
	
	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func getAllPackets(pages: Int, delay: Int, newStyle: Bool) {
		globals.log.v("\(id): Pages: \(pages), delay: \(delay) ms")

		self.pFailedDecodeCount	= 0
		
		var data = Data()
		data.append(commands.getAllPackets.rawValue)
			
		if (newStyle) {
			data.append(contentsOf: pages.leData16)
			data.append(contentsOf: delay.leData16)
		}

		commandQ?.write(characteristic, data: data, type: .withResponse)
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func getAllPacketsAcknowledge(_ ack: Bool) {
		globals.log.v("\(id): Ack: \(ack)")
		
		var data = Data()
		data.append(commands.getAllPacketsAcknowledge.rawValue)
		data.append(ack ? 0x01 : 0x00)
		commandQ?.write(characteristic, data: data, type: .withResponse)
	}
	
	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func getPacketCount() {
        if (!mSimpleCommand(.getPacketCount)) { self.getPacketCountComplete.send((.not_configured, 0)) }
	}
	
	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func disableWornDetect() {
        if (!mSimpleCommand(.disableWornDetect)) { self.disableWornDetectComplete.send(.not_configured) }
	}
	
	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func enableWornDetect() {
        if (!mSimpleCommand(.enableWornDetect)) { self.enableWornDetectComplete.send(.not_configured) }
	}
	
	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func startManual(_ algorithms: ppgAlgorithmConfiguration) {
		globals.log.v("\(id)")
		
		var data = Data()
		data.append(commands.startManual.rawValue)
		data.append(algorithms.commandByte)
		commandQ?.write(characteristic, data: data, type: .withResponse)
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func stopManual() {
		globals.log.v("\(id)")
		
        if (!mSimpleCommand(.stopManual)) { self.stopManualComplete.send(.not_configured) }
	}
	
	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func userLED(red: Bool, green: Bool, blue: Bool, blink: Bool, seconds: Int) {
		globals.log.v("\(id): Red: \(red), Green: \(green), Blue: \(blue), Blink: \(blink), Seconds: \(seconds)")
		
		var data = Data()
		data.append(commands.led.rawValue)
		data.append(red ? 0x01 : 0x00)		// Red
		data.append(green ? 0x01 : 0x00)	// Green
		data.append(blue ? 0x01 : 0x00)		// Blue
		data.append(blink ? 0x01 : 0x00)	// Blink
		data.append(UInt8(seconds & 0xff))	// Seconds

		commandQ?.write(characteristic, data: data, type: .withResponse)
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func enterShipMode() {
		globals.log.v("\(id)")
		
		var data = Data()
		data.append(commands.enterShipMode.rawValue)
		commandQ?.write(characteristic, data: data, type: .withResponse)
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func writeSerialNumber(_ partID: String) {
		globals.log.v("\(id): \(partID)")
		
		var data = Data()
		data.append(commands.setDeviceParam.rawValue)
		data.append(deviceParameterType.serialNumber.rawValue)
		data.append(contentsOf: [UInt8](partID.utf8))
		
		commandQ?.write(characteristic, data: data, type: .withResponse)
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func readSerialNumber() {
		globals.log.v("\(id)")
		
		var data = Data()
		data.append(commands.getDeviceParam.rawValue)
		data.append(deviceParameterType.serialNumber.rawValue)
		commandQ?.write(characteristic, data: data, type: .withResponse)
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func deleteSerialNumber() {
		globals.log.v("\(id)")
		
		var data = Data()
		data.append(commands.delDeviceParam.rawValue)
		data.append(deviceParameterType.serialNumber.rawValue)
		commandQ?.write(characteristic, data: data, type: .withResponse)
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func writeAdvInterval(_ seconds: Int) {
		globals.log.v("\(id): \(seconds)")
		
		var data = Data()
		data.append(commands.setDeviceParam.rawValue)
		data.append(deviceParameterType.advertisingInterval.rawValue)
		data.append(contentsOf: seconds.leData32)
		
		globals.log.v ("\(data.hexString)")

		commandQ?.write(characteristic, data: data, type: .withResponse)
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func readAdvInterval() {
		globals.log.v("\(id)")
		
		var data = Data()
		data.append(commands.getDeviceParam.rawValue)
		data.append(deviceParameterType.advertisingInterval.rawValue)
		commandQ?.write(characteristic, data: data, type: .withResponse)
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func deleteAdvInterval() {
		globals.log.v("\(id)")
		
		var data = Data()
		data.append(commands.delDeviceParam.rawValue)
		data.append(deviceParameterType.advertisingInterval.rawValue)
		commandQ?.write(characteristic, data: data, type: .withResponse)
	}
	
	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func clearChargeCycles() {
		globals.log.v("\(id)")
		
		var data = Data()
		data.append(commands.setDeviceParam.rawValue)
		data.append(deviceParameterType.chargeCycle.rawValue)
		commandQ?.write(characteristic, data: data, type: .withResponse)
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func readChargeCycles() {
		globals.log.v("\(id)")
		
		var data = Data()
		data.append(commands.getDeviceParam.rawValue)
		data.append(deviceParameterType.chargeCycle.rawValue)
		commandQ?.write(characteristic, data: data, type: .withResponse)
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func readCanLogDiagnostics() {
		globals.log.v("\(id)")
		
		var data = Data()
		data.append(commands.getDeviceParam.rawValue)
		data.append(deviceParameterType.canLogDiagnostics.rawValue)
		commandQ?.write(characteristic, data: data, type: .withResponse)
	}
	
	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func updateCanLogDiagnostics(_ allow: Bool) {
		globals.log.v("\(id): Allow Diagnostics? \(allow)")
		
		var data = Data()
		data.append(commands.setDeviceParam.rawValue)
		data.append(deviceParameterType.canLogDiagnostics.rawValue)
		data.append(allow ? 0x01 : 0x00)
		
		commandQ?.write(characteristic, data: data, type: .withResponse)
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func allowPPG(_ allow: Bool) {
		globals.log.v("\(id)")
		
		var data = Data()
		data.append(commands.allowPPG.rawValue)
		data.append(allow ? 0x01 : 0x00)
		commandQ?.write(characteristic, data: data, type: .withResponse)
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func wornCheck() {
		globals.log.v("\(id)")
		
		var data = Data()
		data.append(commands.wornCheck.rawValue)
		commandQ?.write(characteristic, data: data, type: .withResponse)
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func rawLogging(_ enable: Bool) {
		globals.log.v("\(id): \(enable)")
		
		var data = Data()
		data.append(commands.logRaw.rawValue)
		data.append(enable ? 0x01 : 0x00)
		commandQ?.write(characteristic, data: data, type: .withResponse)
	}
	
	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func getRawLoggingStatus() {
		globals.log.v("\(id)")
		
		var data = Data()
		data.append(commands.getRawLoggingStatus.rawValue)
		commandQ?.write(characteristic, data: data, type: .withResponse)
	}
	
	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func getWornOverrideStatus() {
		globals.log.v("\(id)")
		
		var data = Data()
		data.append(commands.getWornOverrideStatus.rawValue)
		commandQ?.write(characteristic, data: data, type: .withResponse)
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func airplaneMode() {
		globals.log.v("\(id)")
		
        if (!mSimpleCommand(.airplaneMode)) { self.airplaneModeComplete.send(.not_configured) }
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func reset() {
		globals.log.v("\(id)")

        if (!mSimpleCommand(.reset)) { self.resetComplete.send(.not_configured) }
	}
	
	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func setSessionParam(_ parameter: sessionParameterType, value: Int) {
		globals.log.v("\(id): \(parameter) - \(value)")
		
		var data = Data()
		data.append(commands.setSessionParam.rawValue)
		data.append(parameter.rawValue)
		data.append(value.leData32)
		commandQ?.write(characteristic, data: data, type: .withResponse)
	}
	
	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func getSessionParam(_ parameter: sessionParameterType) {
		globals.log.v("\(id): \(parameter)")
		
		var data = Data()
		data.append(commands.getSessionParam.rawValue)
		data.append(parameter.rawValue)
		commandQ?.write(characteristic, data: data, type: .withResponse)
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func resetSessionParams() {
		globals.log.v("\(id)")
		
		var data = Data()
		data.append(commands.setSessionParam.rawValue)
		data.append(sessionParameterType.reset.rawValue)
		commandQ?.write(characteristic, data: data, type: .withResponse)
	}
	
	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func acceptSessionParams() {
		globals.log.v("\(id)")
		
		var data = Data()
		data.append(commands.setSessionParam.rawValue)
		data.append(sessionParameterType.accept.rawValue)
		commandQ?.write(characteristic, data: data, type: .withResponse)
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
		globals.log.v("\(id): \(test.title)")
		
		var data = Data()
		data.append(commands.manufacturingTest.rawValue)
		data.append(test.rawValue)
		commandQ?.write(characteristic, data: data, type: .withResponse)
	}
	#endif

	#if UNIVERSAL || KAIROS
	func kairosManufacturingTest(_ test: kairosManufacturingTestType) {
		globals.log.v("\(id): \(test.title)")
		
		var data = Data()
		data.append(commands.manufacturingTest.rawValue)
		data.append(test.rawValue)
        commandQ?.write(characteristic, data: data, type: .withResponse)
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
		var data = Data()
		data.append(commands.setAskForButtonResponse.rawValue)
		data.append(enable ? 0x01 : 0x00)
		commandQ?.write(characteristic, data: data, type: .withResponse)
	}
	
	//--------------------------------------------------------------------------------
	// Function Name: getAskForButtonResponse
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func getAskForButtonResponse() {
		var data = Data()
		data.append(commands.getAskForButtonResponse.rawValue)
		commandQ?.write(characteristic, data: data, type: .withResponse)
	}

	//--------------------------------------------------------------------------------
	// Function Name: setHRZoneColor
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func setHRZoneColor(_ type: hrZoneRangeType, red: Bool, green: Bool, blue: Bool, on_milliseconds: Int, off_milliseconds: Int) {
		globals.log.v("\(id): \(type.title) -> R \(red), G \(green), B \(blue).  On: \(on_milliseconds), Off: \(off_milliseconds)")
		
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
		commandQ?.write(characteristic, data: data, type: .withResponse)
	}
	
	//--------------------------------------------------------------------------------
	// Function Name: getHRZoneColor
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func getHRZoneColor(_ type: hrZoneRangeType) {
		globals.log.v("\(id): \(type.title)")
		
		var data = Data()
		data.append(commands.getHRZoneColor.rawValue)
		data.append(type.rawValue)
		commandQ?.write(characteristic, data: data, type: .withResponse)
	}
	
	//--------------------------------------------------------------------------------
	// Function Name: setHRZoneRange
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func setHRZoneRange(_ enabled: Bool, high_value: Int, low_value: Int) {
		globals.log.v("\(id): Enabled: \(enabled) -> High Value: \(high_value), Low Value: \(low_value)")
		
		var data = Data()
		data.append(commands.setHRZoneRange.rawValue)
		data.append(enabled ? 0x01 : 0x00)
		data.append(UInt8(high_value))
		data.append(UInt8(low_value))
		commandQ?.write(characteristic, data: data, type: .withResponse)
	}
	
	//--------------------------------------------------------------------------------
	// Function Name: getHRZoneRange
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func getHRZoneRange() {
		globals.log.v("\(id)")
		
		var data = Data()
		data.append(commands.getHRZoneRange.rawValue)
		commandQ?.write(characteristic, data: data, type: .withResponse)
	}
	
	//--------------------------------------------------------------------------------
	// Function Name: getPPGAlgorithm
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func getPPGAlgorithm() {
		globals.log.v("\(id)")
		
		var data = Data()
		data.append(commands.getPPGAlgorithm.rawValue)
		commandQ?.write(characteristic, data: data, type: .withResponse)
	}

	//--------------------------------------------------------------------------------
	// Function Name: setAdvertiseAsHRM
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func setAdvertiseAsHRM(_ asHRM: Bool) {
		globals.log.v("\(id): As HRM? (\(asHRM)")
		
		var data = Data()
		data.append(commands.setAdvertiseAsHRM.rawValue)
		data.append(asHRM ? 0x01 : 0x00)
		commandQ?.write(characteristic, data: data, type: .withResponse)
	}

	//--------------------------------------------------------------------------------
	// Function Name: getAdvertiseAsHRM
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func getAdvertiseAsHRM() {
		globals.log.v("\(id)")
		
		var data = Data()
		data.append(commands.getAdvertiseAsHRM.rawValue)
		commandQ?.write(characteristic, data: data, type: .withResponse)
	}
	
	//--------------------------------------------------------------------------------
	// Function Name: setButtonCommand
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func setButtonCommand(_ tap: buttonTapType, command: buttonCommandType) {
		globals.log.v("\(id): \(tap.title) -> \(command.title)")
		
		var data = Data()
		data.append(commands.setButtonCommand.rawValue)
		data.append(tap.rawValue)
		data.append(command.rawValue)
		commandQ?.write(characteristic, data: data, type: .withResponse)
	}
	
	//--------------------------------------------------------------------------------
	// Function Name: getButtonCommand
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func getButtonCommand(_ tap: buttonTapType) {
		globals.log.v("\(id): \(tap.title)")
		
		var data = Data()
		data.append(commands.getButtonCommand.rawValue)
		data.append(tap.rawValue)
		commandQ?.write(characteristic, data: data, type: .withResponse)
	}
	
	//--------------------------------------------------------------------------------
	// Function Name: setPaired
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func setPaired() {
		globals.log.v("\(id)")
		
		var data = Data()
		data.append(commands.setDeviceParam.rawValue)
		data.append(deviceParameterType.paired.rawValue)
		data.append(0x01)
		commandQ?.write(characteristic, data: data, type: .withResponse)
	}
	
	//--------------------------------------------------------------------------------
	// Function Name: setUnpaired
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func setUnpaired() {
		globals.log.v("\(id)")
		
		var data = Data()
		data.append(commands.delDeviceParam.rawValue)
		data.append(deviceParameterType.paired.rawValue)
		commandQ?.write(characteristic, data: data, type: .withResponse)
	}
	

	//--------------------------------------------------------------------------------
	// Function Name: getPaired
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func getPaired() {
		globals.log.v("\(id)")
		
		var data = Data()
		data.append(commands.getDeviceParam.rawValue)
		data.append(deviceParameterType.paired.rawValue)
		commandQ?.write(characteristic, data: data, type: .withResponse)
	}
	
	//--------------------------------------------------------------------------------
	// Function Name: setPageThreshold
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func setPageThreshold(_ threshold: Int) {
		globals.log.v("\(id): \(threshold)")
		
		var data = Data()
		data.append(commands.setDeviceParam.rawValue)
		data.append(deviceParameterType.pageThreshold.rawValue)
		data.append(UInt8(threshold))
		commandQ?.write(characteristic, data: data, type: .withResponse)
	}
	
	//--------------------------------------------------------------------------------
	// Function Name: getPageThreshold
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func getPageThreshold() {
		globals.log.v("\(id)")
		
		var data = Data()
		data.append(commands.getDeviceParam.rawValue)
		data.append(deviceParameterType.pageThreshold.rawValue)
		commandQ?.write(characteristic, data: data, type: .withResponse)
	}
	
	
	//--------------------------------------------------------------------------------
	// Function Name: deletePageThreshold
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func deletePageThreshold() {
		globals.log.v("\(id)")
		
		var data = Data()
		data.append(commands.delDeviceParam.rawValue)
		data.append(deviceParameterType.pageThreshold.rawValue)
		commandQ?.write(characteristic, data: data, type: .withResponse)
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func recalibratePPG() {
		globals.log.v("\(id)")
		
		var data = Data()
		data.append(commands.recalibratePPG.rawValue)
		commandQ?.write(characteristic, data: data, type: .withResponse)
	}
	
	//--------------------------------------------------------------------------------
	// Function Name: Validate CRC
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	internal func mValidateCRC() {
		//globals.log.v("\(pID): \(mCRCOK)")
		
		if (mCRCOK == false) {
			mCRCFailCount	= mCRCFailCount + 1
            if (mCRCFailCount == 10) { dataFailure.send() }
		} else { mCRCFailCount	= 0 }
		
		var data = Data()
		data.append(commands.validateCRC.rawValue)
		data.append(mCRCOK ? 0x01 : 0x00)
		commandQ?.write(characteristic, data: data, type: .withResponse)
		
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
		globals.log.v ("\(id): \(data.hexString)")
		if let response = notifications(rawValue: data[0]) {
			switch (response) {
			case .completion:
				if (data.count >= 3) {
					if let command = commands(rawValue: data[1]) {
						let successful = (data[2] == 0x01)
						//globals.log.v ("\(pID): Got completion for '\(command)' with \(successful) status: Bytes = \(data.hexString)")
						switch (command) {
                        case .writeEpoch	: self.writeEpochComplete.send(successful ? .successful : .device_error)
						case .readEpoch		:
							if (data.count == 7) {
								let epoch = data.subdata(in: Range(3...6)).leInt32
                                if successful {
                                    self.epoch = epoch
                                }
                                self.readEpochComplete.send((successful ? .successful : .device_error, epoch))
							} else {
                                self.readEpochComplete.send((.device_error, 0))
							}
                        case .endSleep		: self.endSleepComplete.send(successful ? .successful : .device_error)
						case .getAllPackets	:
							mCRCOK					= true
							mExpectedSequenceNumber	= 0
                            self.getAllPacketsComplete.send(successful ? .successful : .device_error)
						case .getAllPacketsAcknowledge	:
							if (data.count == 4) {
                                self.getAllPacketsAcknowledgeComplete.send((successful ? .successful : .device_error, (data[3] == 0x01)))
							} else {
                                self.getAllPacketsAcknowledgeComplete.send((.device_error, false))
							}
						case .getNextPacket :
							if (data.count >= 5) {
								let error_code	= nextPacketStatusType(rawValue: data[3])
								let caughtUp	= (data[4] == 0x01)

								if (successful) {
                                    let dataPackets = self.pParseDataPackets(data.subdata(in: Range(5...(data.count - 1))), offset: 0)
									do {
										let jsonData = try JSONEncoder().encode(dataPackets)
										if let jsonString = String(data: jsonData, encoding: .utf8) {
											if let code = error_code {
                                                self.getNextPacketComplete.send((.successful, code, caughtUp, jsonString))
											} else {
                                                self.getNextPacketComplete.send((.successful, .unknown, caughtUp, jsonString))
											}
                                        } else {
                                            self.getNextPacketComplete.send((.device_error, .badJSON, caughtUp, ""))
                                        }
                                    } catch {
                                        self.getNextPacketComplete.send((.device_error, .badSDKDecode, caughtUp, ""))
                                    }
								} else {
									if let code = error_code {
                                        self.getNextPacketComplete.send((.device_error, code, caughtUp, ""))
									} else {
                                        self.getNextPacketComplete.send((.device_error, .unknown, caughtUp, ""))
									}
								}
							} else {
                                self.getNextPacketComplete.send((.device_error, .unknown, false, ""))
							}
						case .getPacketCount:
							if (successful) {
								if (data.count == 7) {
									let count = data.subdata(in: Range(3...6)).leInt32
                                    self.getPacketCountComplete.send((.successful, count))
								} else {
                                    self.getPacketCountComplete.send((.device_error, 0))
								}
							} else {
                                self.getPacketCountComplete.send((.device_error, 0))
							}

                        case .disableWornDetect	: self.disableWornDetectComplete.send(successful ? .successful : .device_error)
                        case .enableWornDetect	: self.enableWornDetectComplete.send(successful ? .successful : .device_error)
                        case .startManual		: self.startManualComplete.send(successful ? .successful : .device_error)
                        case .stopManual		: self.stopManualComplete.send(successful ? .successful : .device_error)
                        case .led				: self.ledComplete.send(successful ? .successful : .device_error)

                        case .enterShipMode		: self.enterShipModeComplete.send(successful ? .successful : .device_error)
						case .setDeviceParam	:
							if let parameter = deviceParameterType(rawValue: data[3]) {
								switch (parameter) {
                                case .advertisingInterval	: self.writeAdvIntervalComplete.send(successful ? .successful : .device_error)
                                case .serialNumber			: self.writeSerialNumberComplete.send(successful ? .successful : .device_error)
                                case .chargeCycle			:
                                    if successful { self.chargeCycles = nil }
                                    self.clearChargeCyclesComplete.send(successful ? .successful : .device_error)
                                case .canLogDiagnostics		: self.updateCanLogDiagnosticsComplete.send(successful ? .successful : .device_error)
                                case .paired				:
                                    self.setPairedComplete.send(successful ? .successful : .device_error)
                                case .pageThreshold			: self.setPageThresholdComplete.send(successful ? .successful : .device_error)
								}
							} else {
								globals.log.e ("\(id): Do not know what to do with parameter: \(String(format: "0x%02X", data[3]))")
							}
						case .getDeviceParam	:
							if let parameter = deviceParameterType(rawValue: data[3]) {
								if (data.count == 20) {
									switch (parameter) {
									case .advertisingInterval	:
										let seconds = data.subdata(in: Range(4...7)).leInt32
                                        if successful { self.advertisingInterval = seconds }
                                        self.readAdvIntervalComplete.send((successful ? .successful : .device_error, seconds))
									case .serialNumber			:
										let snData		= String(decoding: data.subdata(in: Range(4...19)), as: UTF8.self)
										let nulls		= CharacterSet.whitespacesAndNewlines.union(CharacterSet(["\0"]))
										let snString	= snData.trimmingCharacters(in: nulls)
                                        self.readSerialNumberComplete.send((successful ? .successful : .device_error, snString))
									case .chargeCycle			:
										let cycles = data.subdata(in: Range(4...7)).leFloat
                                        if successful { self.chargeCycles = cycles }
                                        self.readChargeCyclesComplete.send((successful ? .successful : .device_error, cycles))
									case .canLogDiagnostics		:
										let allow = (data[4] != 0x00)
                                        if successful { self.canLogDiagnostics = allow }
                                        self.readCanLogDiagnosticsComplete.send((successful ? .successful : .device_error, allow))
									case .paired:
										let paired = (data[4] != 0x00)
                                        if successful {
                                            self.paired = paired
                                        } else {
                                            self.paired = nil
                                        }
                                        self.getPairedComplete.send((successful ? .successful : .device_error, paired))
									case .pageThreshold:
                                        let threshold = Int(data[4])
                                        if successful {
                                            self.advertisingPageThreshold = threshold
                                        } else {
                                            self.advertisingPageThreshold = nil
                                        }
                                        self.getPageThresholdComplete.send((successful ? .successful : .device_error, threshold))
									}
								} else {
									switch (parameter) {
                                    case .advertisingInterval	: self.readAdvIntervalComplete.send((.device_error, 0))
                                    case .serialNumber			: self.readSerialNumberComplete.send((.device_error, ""))
                                    case .chargeCycle			: self.readChargeCyclesComplete.send((.device_error, 0.0))
                                    case .canLogDiagnostics		: self.readCanLogDiagnosticsComplete.send((.device_error, false))
                                    case .paired				: self.getPairedComplete.send((.device_error, false))
                                    case .pageThreshold			: self.getPageThresholdComplete.send((.device_error, 1))
									}
								}
							} else {
								globals.log.e ("\(id): Do not know what to do with parameter: \(String(format: "0x%02X", data[3]))")
							}
						case .delDeviceParam	:
							if let parameter = deviceParameterType(rawValue: data[3]) {
								switch (parameter) {
                                case .advertisingInterval	:
                                    if successful { self.advertisingInterval = nil }
                                    self.deleteAdvIntervalComplete.send(successful ? .successful : .device_error)
                                case .serialNumber			: self.deleteSerialNumberComplete.send(successful ? .successful : .device_error)
								case .chargeCycle			: globals.log.e ("\(id): Should not have been able to delete \(parameter.title)")
								case .canLogDiagnostics		: globals.log.e ("\(id): Should not have been able to delete \(parameter.title)")
                                case .paired				: self.setUnpairedComplete.send(successful ? .successful : .device_error)
                                case .pageThreshold			: self.deletePageThresholdComplete.send(successful ? .successful : .device_error)
								}
							} else {
								globals.log.e ("\(id): Do not know what to do with parameter: \(String(format: "0x%02X", data[3]))")
							}
						case .setSessionParam		:
							if let enumParameter = sessionParameterType(rawValue: data[3]) {
								switch (enumParameter) {
								case .ppgCapturePeriod,
									 .ppgCaptureDuration,
                                     .tag:
                                    setSessionParamComplete.send((successful ? .successful : .device_error, enumParameter))
                                case .reset: resetSessionParamsComplete.send(successful ? .successful : .device_error)
                                case .accept: acceptSessionParamsComplete.send((successful ? .successful : .device_error))
                                case .unknown:
                                    setSessionParamComplete.send((.device_error, enumParameter)) // Shouldn't get this ever!)
								}
							} else {
								globals.log.e ("\(id): Was not able to encode parameter: \(String(format: "0x%02X", data[3]))")
							}

						case .getSessionParam		:
							if let enumParameter = sessionParameterType(rawValue: data[3]) {
								switch (enumParameter) {
								case .ppgCapturePeriod,
									 .ppgCaptureDuration,
									 .tag		:
									let value = data.subdata(in: Range(4...7)).leInt32
                                    
                                    switch enumParameter {
                                    case .tag:
                                        var data = Data()
                                        data.append((UInt8((value >> 0) & 0xff)))
                                        data.append((UInt8((value >> 8) & 0xff)))
                                        if let strValue = String(data: data, encoding: .utf8) {
                                            self.tag = strValue
                                        } else {
                                            self.tag = "'\(String(format:"0x%04X", value))' - Could not make string"
                                        }
                                    case .ppgCapturePeriod: self.ppgCapturePeriod = value
                                    case .ppgCaptureDuration: self.ppgCaptureDuration = value
                                    default: break
                                    }

                                    getSessionParamComplete.send((successful ? .successful : .device_error, enumParameter, value))
									break
                                case .reset		: resetSessionParamsComplete.send(successful ? .successful : .device_error) // Shouldn't get this on a get
                                case .accept	: acceptSessionParamsComplete.send(successful ? .successful : .device_error) // Shouldn't get this on a get
								case .unknown	:
                                    getSessionParamComplete.send((successful ? .successful : .device_error, enumParameter, 0)) // Shouldn't get this ever!
									break
								}

							} else {
								globals.log.e ("\(id): Was not able to encode parameter: \(String(format: "0x%02X", data[3]))")
							}

                        case .manufacturingTest	: self.manufacturingTestComplete.send(successful ? .successful : .device_error)
                        case .recalibratePPG	: self.recalibratePPGComplete.send(successful ? .successful : .device_error)
							
						case .setAskForButtonResponse:
							if (data.count == 4) {
								let enable		= data[3] == 0x01 ? true : false
                                if successful { self.buttonResponseEnabled = enable }
								self.setAskForButtonResponseComplete.send((successful ? .successful : .device_error, enable))
							} else {
                                self.setAskForButtonResponseComplete.send((.device_error, false))
							}
							
						case .getAskForButtonResponse:
							if (data.count == 4) {
								let enable		= data[3] == 0x01 ? true : false
                                if successful { self.buttonResponseEnabled = enable }
                                self.getAskForButtonResponseComplete.send((successful ? .successful : .device_error, enable))
							} else {
								self.getAskForButtonResponseComplete.send((.device_error, false))
							}
							
						case .setHRZoneColor:
							if (data.count == 4) {
								if let zone = hrZoneRangeType(rawValue: data[3]) {
                                    self.setHRZoneColorComplete.send((successful ? .successful : .device_error, zone))
                                } else {
                                    self.setHRZoneColorComplete.send((.device_error, .unknown))
                                }
                            } else {
                                self.setHRZoneColorComplete.send((.device_error, .unknown))
                            }
							
						case .getHRZoneColor:
							if (data.count == 11) {
								if let zone = hrZoneRangeType(rawValue: data[3]) {
									let red		= (data[4] != 0x00)
									let green	= (data[5] != 0x00)
									let blue	= (data[6] != 0x00)
									let on_ms	= data.subdata(in: Range(7...8)).leInt16
									let off_ms	= data.subdata(in: Range(9...10)).leInt16
                                    
                                    if successful {
                                        switch (zone) {
                                        case .below: self.hrZoneLEDBelow = hrZoneLEDValueType(red: red, green: green, blue: blue, on_ms: on_ms, off_ms: off_ms)
                                        case .within: self.hrZoneLEDWithin = hrZoneLEDValueType(red: red, green: green, blue: blue, on_ms: on_ms, off_ms: off_ms)
                                        case .above: self.hrZoneLEDAbove = hrZoneLEDValueType(red: red, green: green, blue: blue, on_ms: on_ms, off_ms: off_ms)
                                        default: break
                                        }
                                    }

                                    self.getHRZoneColorComplete.send((successful ? .successful : .device_error, zone, red, green, blue, on_ms, off_ms))
                                } else {
                                    self.getHRZoneColorComplete.send((.device_error, .unknown, false, false, false, 0, 0))
                                }
                            } else {
                                self.getHRZoneColorComplete.send((.device_error, .unknown, false, false, false, 0, 0))
                            }
							
						case .setHRZoneRange:
                            if (data.count == 3) {
                                self.setHRZoneRangeComplete.send(successful ? .successful : .device_error)
                            } else {
                                self.setHRZoneRangeComplete.send(.device_error)
                            }
							
						case .getHRZoneRange:
							if (data.count == 6) {
								let enabled		= (data[3] != 0x00)
								let high_value	= Int(data[4])
								let low_value	= Int(data[5])
                                
                                if successful {
                                    self.hrZoneRange = hrZoneRangeValueType(enabled: enabled, lower: low_value, upper: high_value)
                                }

                                self.getHRZoneRangeComplete.send((successful ? .successful : .device_error, enabled, high_value, low_value))
							} else {
                                self.getHRZoneRangeComplete.send((.device_error, false, 0, 0))
							}
						case .getPPGAlgorithm:
							if (data.count == 5) {
								let algorithm	= ppgAlgorithmConfiguration(data[3])
								
								if let type = eventType(rawValue: data[4]) {
                                    self.getPPGAlgorithmComplete.send((successful ? .successful : .device_error, algorithm, type))
								} else {
                                    self.getPPGAlgorithmComplete.send((successful ? .successful : .device_error, algorithm, eventType.unknown))
								}
							}
							else if (data.count == 4) {
								let algorithm	= ppgAlgorithmConfiguration(data[3])
                                self.getPPGAlgorithmComplete.send((successful ? .successful : .device_error, algorithm, eventType.unknown))
							} else {
                                self.getPPGAlgorithmComplete.send((.device_error, ppgAlgorithmConfiguration(), eventType.unknown))
							}
							
						case .setAdvertiseAsHRM:
							if (data.count == 4) {
								let asHRM		= data[3] != 0x00
                                if successful {
                                    self.advertiseAsHRM = asHRM
                                }
                                self.setAdvertiseAsHRMComplete.send((successful ? .successful : .device_error, asHRM))
							} else {
                                self.setAdvertiseAsHRMComplete.send((.device_error, false))
							}

						case .getAdvertiseAsHRM:
							if (data.count == 4) {
								let asHRM		= data[3] != 0x00
                                if successful {
                                    self.advertiseAsHRM = asHRM
                                }
                                self.getAdvertiseAsHRMComplete.send((successful ? .successful : .device_error, asHRM))
							} else {
								self.getAdvertiseAsHRMComplete.send((.device_error, false))
							}
							
						case .setButtonCommand:
							if (data.count == 5) {
								if let tap = buttonTapType(rawValue: data[3]), let command = buttonCommandType(rawValue: data[4]) {
                                    if successful {
                                        switch tap {
                                        case .single: self.singleButtonPressAction = command
                                        case .double: self.doubleButtonPressAction = command
                                        case .triple: self.tripleButtonPressAction = command
                                        case .long: self.longButtonPressAction = command
                                        default: break
                                        }
                                    }

                                    self.setButtonCommandComplete.send((successful ? .successful : .device_error, tap, command))
								} else {
									self.setButtonCommandComplete.send((.device_error, .unknown, .unknown))
								}
							} else {
                                self.setButtonCommandComplete.send((.device_error, .unknown, .unknown))
							}

						case .getButtonCommand:
							if (data.count == 5) {
								if let tap = buttonTapType(rawValue: data[3]), let command = buttonCommandType(rawValue: data[4]) {
                                    if successful {
                                        switch tap {
                                        case .single: self.singleButtonPressAction = command
                                        case .double: self.doubleButtonPressAction = command
                                        case .triple: self.tripleButtonPressAction = command
                                        case .long: self.longButtonPressAction = command
                                        default: break
                                        }
                                    }

                                    self.getButtonCommandComplete.send((successful ? .successful : .device_error, tap, command))
								} else {
									self.getButtonCommandComplete.send((.device_error, .unknown, .unknown))
								}
							} else {
								self.getButtonCommandComplete.send((.device_error, .unknown, .unknown))
							}

                        case .allowPPG			: self.allowPPGComplete.send(successful ? .successful : .device_error)
						case .wornCheck			:
							if (data.count == 8) {
								if let code = wornResult(rawValue: data[3]) {
									let value = data.subdata(in: Range(4...7)).leInt32
								
									if code == .ran {
                                        self.wornCheckResult = DeviceWornCheckResultType(code: code.message, value: value)
                                        self.wornCheckComplete.send((successful ? .successful : .device_error, code.message, value))
									} else {
                                        self.wornCheckResult = DeviceWornCheckResultType(code: code.message, value: 0)
                                        self.wornCheckComplete.send((.device_error, code.message, 0))
									}
								} else {
                                    self.wornCheckComplete.send((.device_error, "Unknown code: \(String(format: "0x%02X", data[3]))", 0))
								}
							}
							
                        case .logRaw			: self.rawLoggingComplete.send(successful ? .successful : .device_error)
						case .getRawLoggingStatus	:
							if (data.count == 4) {
                                let enabled = (data[3] != 0x00)
                                if successful {
                                    self.rawLogging = enabled
                                } else {
                                    self.rawLogging = nil
                                }

                                self.getRawLoggingStatusComplete.send((successful ? .successful : .device_error, enabled))
							} else {
                                self.getRawLoggingStatusComplete.send((.device_error, false))
							}
							
						case .getWornOverrideStatus	:
							if (data.count == 4) {
                                let overridden = (data[3] != 0x00)
                                if successful {
                                    self.wornOverridden = overridden
                                } else {
                                    self.wornOverridden = nil
                                }
                                self.getWornOverrideStatusComplete.send((successful ? .successful : .device_error, overridden))
							} else {
                                self.getWornOverrideStatusComplete.send((.device_error, false))
							}
							
                        case .airplaneMode		: self.airplaneModeComplete.send(successful ? .successful : .device_error)
                        case .reset				: self.resetComplete.send(successful ? .successful : .device_error)
						case .validateCRC		: break
							//globals.log.v ("\(pID): Got Validate CRC completion: \(data.hexString)")
						}
					} else {
						globals.log.e ("\(id): Unknown command: \(data.hexString)")
					}
				} else {
					globals.log.e ("\(id): Incorrect length for completion: \(data.hexString)")
				}
				
                DispatchQueue.main.async {
                    self.commandQ?.remove() // These were updates from a write, so queue can now move on
                }
				
			case .dataPacket:
				if (data.count > 3) {	// Accounts for header byte and sequence number
					//globals.log.v ("\(pID): \(data.subdata(in: Range(0...7)).hexString)")
					//globals.log.v ("\(pID): \(data.hexString)")
					let sequence_number = data.subdata(in: Range(1...2)).leUInt16
					if (sequence_number == mExpectedSequenceNumber) {
						//globals.log.v ("\(pID): Sequence Number Match: \(sequence_number).  Expected: \(mExpectedSequenceNumber)")
					} else {
						globals.log.e ("\(id): \(response) - Sequence Number Fail: \(sequence_number). Expected: \(mExpectedSequenceNumber): \(data.hexString)")
						mCRCOK	= false
					}
					mExpectedSequenceNumber = mExpectedSequenceNumber + 1
					
					if (mCRCOK) {
                        let dataPackets = self.pParseDataPackets(data.subdata(in: Range(3...(data.count - 1))), offset: 0)
						mDataPackets.append(contentsOf: dataPackets)
					}
				} else {
					globals.log.e ("\(id): Bad data length for data packet: \(data.hexString)")
					mCRCOK	= false
				}
				
			case .worn:
                if      (data[1] == 0x00) { self.worn = false }
                else if (data[1] == 0x01) { self.worn = true  }
				else {
					globals.log.e ("\(id): Cannot parse worn status: \(data[1])")
				}
							
			case .ppg_metrics:
                let (_, type, packet) = pParseSinglePacket(data, index: 1, offset: 0)
				if (type == .ppg_metrics) {
                    let metrics = ppgMetricsType()
                    metrics.status = packet.ppg_metrics_status.title
                    if packet.hr_valid { metrics.hr = packet.hr_result }
                    if packet.hrv_valid { metrics.hrv = packet.hrv_result }
                    if packet.rr_valid { metrics.rr = packet.rr_result }
                    
                    ppgMetrics = metrics
				}
				
			case .ppgFailed:
				if (data.count > 1) {
                    self.ppgFailed.send(Int(data[1]))
				} else {
                    self.ppgFailed.send(999)
				}
				
			case .dataCaughtUp:
				if (data.count > 1) {
					let bad_read_count	= Int(data.subdata(in: Range(1...2)).leUInt16)
					let bad_parse_count	= Int(data.subdata(in: Range(3...4)).leUInt16)
					let overflow_count	= Int(data.subdata(in: Range(5...6)).leUInt16)
                    self.dataComplete.send((bad_read_count, bad_parse_count, overflow_count, self.pFailedDecodeCount, false))
				} else {
                    self.dataComplete.send((-1, -1, -1, self.pFailedDecodeCount, false))
				}
				
			case .endSleepStatus:
				if (data.count == 2) {
					let hasSleep	= data[1] == 0x01 ? true : false
                    self.endSleepStatus.send(hasSleep)
				} else {
					globals.log.e ("\(id): Cannot parse 'endSleepStatus': \(data.hexString)")
				}
				
			case .buttonResponse:
				if (data.count == 2) {
                    self.buttonTaps	= Int(data[1])
				} else {
					globals.log.e ("\(id): Cannot parse 'buttonResponse': \(data.hexString)")
				}
				
			case .validateCRC:
				//globals.log.v ("\(pID): \(response) - \(data.hexString)")
				
				let sequence_number = data.subdata(in: Range(1...2)).leUInt16
				if (sequence_number == mExpectedSequenceNumber) {
					//globals.log.v ("\(pID): SN Match: \(sequence_number).  Expected: \(mExpectedSequenceNumber)")
				} else {
					globals.log.e ("\(id): \(response) - Sequence Number Fail: \(sequence_number). Expected: \(mExpectedSequenceNumber): \(data.hexString)")
					mCRCOK	= false
				}

				let allowResponse		= mCRCIgnoreTest.check()
				let allowGoodResponse	= mCRCFailTest.check()
										
				if (allowResponse) {
					if (allowGoodResponse) {
						if (mCRCOK == true) {
							//globals.log.v ("\(pID): Validate CRC Passed: Let received packets through")
							
							if (mDataPackets.count > 0) {
								do {
									let jsonData = try JSONEncoder().encode(mDataPackets)
									if let jsonString = String(data: jsonData, encoding: .utf8) {
                                        self.dataPackets.send((-1, jsonString))
									} else { globals.log.e ("\(id): Cannot make string from json data") }
								} catch { globals.log.e ("\(id): Cannot make JSON data") }
						   }
						} else {
							globals.log.v ("\(id): \(response) Failed: Do not let packets through")
						}
					} else {
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
                            self.manufacturingTestResult.send((true, jsonString))
						} else {
							globals.log.e ("\(id): Result jsonString Failed")
                            self.manufacturingTestResult.send((false, ""))
						}
					} catch {
						globals.log.e ("\(id): Result jsonData Failed")
                        self.manufacturingTestResult.send((false, ""))
					}
				} else {
                    self.manufacturingTestResult.send((false, ""))
				}
				#endif

				#if KAIROS
				if (data.count == 3) {
					let testResult = kairosManufacturingTestResult(data.subdata(in: Range(1...2)))
					do {
						let jsonData = try JSONEncoder().encode(testResult)
						if let jsonString = String(data: jsonData, encoding: .utf8) {
                            self.manufacturingTestResult.send((true, jsonString))
						} else {
							globals.log.e ("\(id): Result jsonString Failed")
                            self.manufacturingTestResult.send((false, ""))
						}
					} catch {
						globals.log.e ("\(id): Result jsonData Failed")
                        self.manufacturingTestResult.send((false, ""))
					}
				} else {
                    self.manufacturingTestResult.send((false, ""))
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
                                self.manufacturingTestResult.send((true, jsonString))
							} else {
								globals.log.e ("\(id): Result jsonString Failed")
                                self.manufacturingTestResult.send((false, ""))
							}
						} catch {
							globals.log.e ("\(id): Result jsonData Failed")
                            self.manufacturingTestResult.send((false, ""))
						}
					} else {
                        self.manufacturingTestResult.send((false, ""))
					}

				case .kairos		:
					if (data.count == 3) {
						let testResult = kairosManufacturingTestResult(data.subdata(in: Range(1...2)))
						do {
							let jsonData = try JSONEncoder().encode(testResult)
							if let jsonString = String(data: jsonData, encoding: .utf8) {
                                self.manufacturingTestResult.send((true, jsonString))
							} else {
								globals.log.e ("\(id): Result jsonString Failed")
                                self.manufacturingTestResult.send((false, ""))
							}
						} catch {
							globals.log.e ("\(id): Result jsonData Failed")
                            self.manufacturingTestResult.send((false, ""))
						}
					} else {
                        self.manufacturingTestResult.send((false, ""))
					}

				case .unknown	: break
				}
				#endif
				
			case .charging:
                self.on_charger	= (data[1] == 0x01)
                self.charging = (data[2] == 0x01)
                self.charge_error = (data[3] == 0x01)
				
			case .streamPacket: globals.log.e ("\(id): Should not get '\(response)' on this characteristic!")
			case .dataAvailable: globals.log.e ("\(id): Should not get '\(response)' on this characteristic!")
			}
		} else {
			globals.log.e ("\(id): Unknown update: \(data.hexString)")
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
		if let characteristic, let data = characteristic.value {
            // Packets have to be at least a header + CRC.  If not, do not parse
            if (data.count >= 4) {
                // Get the CRC.  Only process the packet if the CRC is good.
                let crc_received	= data.subdata(in: Range((data.count - 4)...(data.count - 1))).leInt32
                var input_bytes 	= data.subdata(in: Range(0...(data.count - 5))).bytes
                let crc_calculated	= crc32(uLong(0), &input_bytes, uInt(input_bytes.count))

                if (crc_received != crc_calculated) {
                    globals.log.e ("\(id): Hmmm..... Packet CRC Error! CRC : \(String(format:"0x%08X", crc_received)): \(String(format:"0x%08X", crc_calculated))")
                    mCRCOK = false;
                    mExpectedSequenceNumber = mExpectedSequenceNumber + 1	// go ahead and increase the expected sequence number.  already going to create retransmit.  this avoids other expected sequence checks from failling
                }

                mProcessUpdateValue(data.subdata(in: Range(0...(data.count - 5))))
            } else {
                globals.log.e ("\(id): Cannot calculate packet CRC: Not enough data.  Length = \(data.count): \(data.hexString)")
                return
            }
				
        } else {
            globals.log.e ("\(id): Missing characteristic and/or data")
        }
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	override func didUpdateNotificationState() {
		configured	= true
	}
	
}
