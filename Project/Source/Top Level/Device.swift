//
//  Device.swift
//  biostrapDeviceSDK
//
//  Created by Joseph A. Bennett on 3/31/21.
//

import Foundation
import CoreBluetooth
import Combine

public enum DeviceCommandCompletionStatus {
	case successful
	case not_configured
	case device_error
	
	public var title: String {
		switch self {
		case .successful: return ""
		case .not_configured: return "Not configured"
		case .device_error: return "Device returned error"
		}
	}
	
	public var successful: Bool {
		return self == .successful
	}
}

public class hrZoneLEDValueType: ObservableObject {
	@Published public var red: Bool
	@Published public var green: Bool
	@Published public var blue: Bool
	@Published public var on_ms: Int
	@Published public var off_ms: Int
	
	public init() {
		self.red = false
		self.green = false
		self.blue = false
		self.on_ms = 0
		self.off_ms = 0
	}
	
	public init(red: Bool, green: Bool, blue: Bool, on_ms: Int, off_ms: Int) {
		self.red = red
		self.green = green
		self.blue = blue
		self.on_ms = on_ms
		self.off_ms = off_ms
	}
	
	public var stringValue: String {
		return ("Red: \(self.red), green: \(self.green), blue: \(self.blue), on_ms: \(self.on_ms), off_ms: \(self.off_ms)")
	}
}

public class hrZoneRangeValueType: ObservableObject {
	@Published public var enabled: Bool = false
	@Published public var lower: Int = 0
	@Published public var upper: Int = 0
	
	public init() {
		self.enabled = false
		self.lower = 0
		self.upper = 0
	}
	
	public init(enabled: Bool, lower: Int, upper: Int) {
		self.enabled = enabled
		self.lower = lower
		self.upper = upper
	}
	
	public var stringValue: String {
		return ("Enabled: \(self.enabled), lower: \(self.lower), upper: \(self.upper)")
	}
}

public class wornCheckResultType: ObservableObject {
	@Published public var code: String = ""
	@Published public var value: Int = 0
	
	public init() {
		self.code = ""
		self.value = 0
	}
	
	public init(code: String, value: Int) {
		self.code = code
		self.value = value
	}
}

public class ppgMetricsType: ObservableObject {
	@Published public var status = ""
	@Published public var hr: Float?
	@Published public var hrv: Float?
	@Published public var rr: Float?
	//@Published public var spo2 = Float(0.0)
	
	init(_ jsonPacket: String) {
		do {
			if let jsonData = jsonPacket.data(using: .utf8) {
				let packet  = try JSONDecoder().decode(biostrapDataPacket.self, from: jsonData)
				
				status = packet.ppg_metrics_status.title
				
				if (packet.hr_valid) { hr = packet.hr_result }
				if (packet.hrv_valid) { hrv = packet.hrv_result }
				if (packet.rr_valid) { rr = packet.rr_result }
				//if (packet.spo2_valid) { spo2	= packet.spo2_result }
			}
			else {
				log?.e ("Cannot get PPG Metrics data from json String")
				status = "Cannot get PPG Metrics data from json String"
			}
		}
		catch {
			log?.e ("\(error.localizedDescription)")
			status = error.localizedDescription
		}
	}
}

public class Device: NSObject, ObservableObject {
	
	enum prefixes: String {
		#if UNIVERSAL || ALTER
		case alter = "ALT"
		#endif
		
		#if UNIVERSAL || KAIROS
		case kairos = "KAI"
		#endif
				
		case unknown = "UNK"
	}
		
	enum services: String {
		#if UNIVERSAL || ALTER
		case alter			= "883BBA2C-8E31-40BB-A859-D59A2FB38EC0"
		#endif
		
		#if UNIVERSAL || KAIROS
		case kairos			= "140BB753-9845-4C0E-B61A-E6BAE41712F0"
		#endif

		case ambiqOTA		= "00002760-08C2-11E1-9073-0E8AC72E1001"
		
		var UUID: CBUUID {
			return CBUUID(string: self.rawValue)
		}
		
		var title: String {
			switch (self) {
			#if UNIVERSAL || ALTER
			case .alter		: return "Alter Service"
			#endif

			#if UNIVERSAL || KAIROS
			case .kairos	: return "Kairos Service"
			#endif
				
			case .ambiqOTA	: return "Ambiq OTA Service"
			}
		}
	}

	enum characteristics: String {
		#if UNIVERSAL || ALTER
		case alterMainCharacteristic	= "883BBA2C-8E31-40BB-A859-D59A2FB38EC1"
		case alterDataCharacteristic	= "883BBA2C-8E31-40BB-A859-D59A2FB38EC2"
		case alterStrmCharacteristic	= "883BBA2C-8E31-40BB-A859-D59A2FB38EC3"
		#endif

		#if UNIVERSAL || KAIROS
		case kairosMainCharacteristic	= "140BB753-9845-4C0E-B61A-E6BAE41712F1"
		case kairosDataCharacteristic	= "140BB753-9845-4C0E-B61A-E6BAE41712F2"
		case kairosStrmCharacteristic	= "140BB753-9845-4C0E-B61A-E6BAE41712F3"
		#endif

		case ambiqOTARXCharacteristic	= "00002760-08C2-11E1-9073-0E8AC72E0001"
		case ambiqOTATXCharacteristic	= "00002760-08C2-11E1-9073-0E8AC72E0002"

		var UUID: CBUUID {
			return CBUUID(string: self.rawValue)
		}
		
		var title: String {
			switch (self) {
			#if UNIVERSAL || ALTER
			case .alterMainCharacteristic	: return "Alter Command Characteristic"
			case .alterDataCharacteristic	: return "Alter Data Characteristic"
			case .alterStrmCharacteristic	: return "Alter Streaming Characteristic"
			#endif

			#if UNIVERSAL || KAIROS
			case .kairosMainCharacteristic	: return "Kairos Command Characteristic"
			case .kairosDataCharacteristic	: return "Kairos Data Characteristic"
			case .kairosStrmCharacteristic	: return "Kairos Streaming Characteristic"
			#endif
				
			case .ambiqOTARXCharacteristic	: return "Ambiq OTA RX Characteristic"
			case .ambiqOTATXCharacteristic	: return "Ambiq OTA TX Characteristic"
			}
		}
	}

	public enum ConnectionState {
		case disconnected
		case connecting
		case configuring
		case connected
	}
	
	@Published public var connectionState : ConnectionState = .disconnected
	
	#if UNIVERSAL
	@objc public var type	: biostrapDeviceSDK.biostrapDeviceType
	#endif
	
	var peripheral			: CBPeripheral?
	
	// MARK: Publishee properties
	@Published public var name: String
	@Published public var id: String
	@Published public var discovery_type: biostrapDeviceSDK.biostrapDiscoveryType
	@Published public var epoch: Int?
	
	@Published public var batteryValid: Bool = false
	@Published public var batteryLevel: Int = 0
	@Published public var wornStatus: String = "Not worn"
	@Published public var chargingStatus: String = "Not charging"

	@Published public var modelNumber: String = "???"
	@Published public var firmwareRevision: String = "???"
	@Published public var hardwareRevision: String = "???"
	@Published public var manufacturerName: String = "???"
	@Published public var serialNumber: String = "???"
	@Published public var bluetoothSoftwareRevision: String = "???"
	@Published public var algorithmsSoftwareRevision: String = "???"
	@Published public var sleepSoftwareRevision: String = "???"
	
	@Published public var canLogDiagnostics: Bool?
	
	@Published public var wornCheckResult = wornCheckResultType()

	@Published public var advertisingInterval: Int?
	@Published public var chargeCycles: Float?
	@Published public var advertiseAsHRM: Bool?
	@Published public var rawLogging: Bool?
	@Published public var wornOverridden: Bool?
	@Published public var buttonResponseEnabled: Bool?
	
	@Published public var singleButtonPressAction: buttonCommandType?
	@Published public var doubleButtonPressAction: buttonCommandType?
	@Published public var tripleButtonPressAction: buttonCommandType?
	@Published public var longButtonPressAction: buttonCommandType?

	@Published public var hrZoneLEDBelow = hrZoneLEDValueType()
	@Published public var hrZoneLEDWithin = hrZoneLEDValueType()
	@Published public var hrZoneLEDAbove = hrZoneLEDValueType()
	@Published public var hrZoneRange = hrZoneRangeValueType()
	
	@Published public var buttonPresses = 0

	@Published public var paired: Bool?
	@Published public var advertisingPageThreshold: Int?
	
	@Published public var ppgCapturePeriod: Int?
	@Published public var ppgCaptureDuration: Int?
	@Published public var tag: String?
	
	@Published public var ppgMetrics: ppgMetricsType?

	var creation_epoch: TimeInterval
	
	// MARK: Passthrough Subjects (Completions)
	public let readEpochComplete = PassthroughSubject<DeviceCommandCompletionStatus, Never>()
	public let writeEpochComplete = PassthroughSubject<DeviceCommandCompletionStatus, Never>()

	public let startManualComplete = PassthroughSubject<DeviceCommandCompletionStatus, Never>()
	public let stopManualComplete = PassthroughSubject<DeviceCommandCompletionStatus, Never>()
	
	public let ledComplete = PassthroughSubject<DeviceCommandCompletionStatus, Never>()
	
	public let getRawLoggingStatusComplete = PassthroughSubject<DeviceCommandCompletionStatus, Never>()
	public let getWornOverrideStatusComplete = PassthroughSubject<DeviceCommandCompletionStatus, Never>()
	
	public let writeSerialNumberComplete = PassthroughSubject<DeviceCommandCompletionStatus, Never>()
	public let readSerialNumberComplete = PassthroughSubject<DeviceCommandCompletionStatus, Never>()
	public let deleteSerialNumberComplete = PassthroughSubject<DeviceCommandCompletionStatus, Never>()
	
	public let writeAdvIntervalComplete = PassthroughSubject<DeviceCommandCompletionStatus, Never>()
	public let readAdvIntervalComplete = PassthroughSubject<DeviceCommandCompletionStatus, Never>()
	public let deleteAdvIntervalComplete = PassthroughSubject<DeviceCommandCompletionStatus, Never>()
	
	public let clearChargeCyclesComplete = PassthroughSubject<DeviceCommandCompletionStatus, Never>()
	public let readChargeCyclesComplete = PassthroughSubject<DeviceCommandCompletionStatus, Never>()

	public let setAdvertiseAsHRMComplete = PassthroughSubject<DeviceCommandCompletionStatus, Never>()
	public let getAdvertiseAsHRMComplete = PassthroughSubject<DeviceCommandCompletionStatus, Never>()

	public let setButtonCommandComplete = PassthroughSubject<(DeviceCommandCompletionStatus, buttonTapType), Never>()
	public let getButtonCommandComplete = PassthroughSubject<(DeviceCommandCompletionStatus, buttonTapType), Never>()
	
	public let setAskForButtonResponseComplete = PassthroughSubject<DeviceCommandCompletionStatus, Never>()
	public let getAskForButtonResponseComplete = PassthroughSubject<DeviceCommandCompletionStatus, Never>()
	
	public let setHRZoneColorComplete = PassthroughSubject<(DeviceCommandCompletionStatus, hrZoneRangeType), Never>()
	public let getHRZoneColorComplete = PassthroughSubject<(DeviceCommandCompletionStatus, hrZoneRangeType), Never>()
	public let setHRZoneRangeComplete = PassthroughSubject<DeviceCommandCompletionStatus, Never>()
	public let getHRZoneRangeComplete = PassthroughSubject<DeviceCommandCompletionStatus, Never>()
	public let getPPGAlgorithmComplete = PassthroughSubject<(Bool, ppgAlgorithmConfiguration, eventType), Never>()
	
	public let endSleepComplete = PassthroughSubject<DeviceCommandCompletionStatus, Never>()

	public let disableWornDetectComplete = PassthroughSubject<DeviceCommandCompletionStatus, Never>()
	public let enableWornDetectComplete = PassthroughSubject<DeviceCommandCompletionStatus, Never>()

	public let wornCheckResultComplete = PassthroughSubject<DeviceCommandCompletionStatus, Never>()
	
	public let setSessionParamComplete = PassthroughSubject<(DeviceCommandCompletionStatus, sessionParameterType), Never>()
	public let getSessionParamComplete = PassthroughSubject<(DeviceCommandCompletionStatus, sessionParameterType), Never>()
	public let resetSessionParamsComplete = PassthroughSubject<DeviceCommandCompletionStatus, Never>()
	public let acceptSessionParamsComplete = PassthroughSubject<DeviceCommandCompletionStatus, Never>()
	
	public let readCanLogDiagnosticsComplete = PassthroughSubject<DeviceCommandCompletionStatus, Never>()
	public let updateCanLogDiagnosticsComplete = PassthroughSubject<DeviceCommandCompletionStatus, Never>()

	public let enterShipModeComplete = PassthroughSubject<DeviceCommandCompletionStatus, Never>()
	public let resetComplete = PassthroughSubject<DeviceCommandCompletionStatus, Never>()
	public let airplaneModeComplete = PassthroughSubject<DeviceCommandCompletionStatus, Never>()

	public let getPacketCountComplete = PassthroughSubject<(DeviceCommandCompletionStatus, Int), Never>()
	public let getAllPacketsComplete = PassthroughSubject<DeviceCommandCompletionStatus, Never>()
	public let getAllPacketsAcknowledgeComplete = PassthroughSubject<(DeviceCommandCompletionStatus, Bool), Never>()

	public let manufacturingTestComplete = PassthroughSubject<DeviceCommandCompletionStatus, Never>()
	public let rawLoggingComplete = PassthroughSubject<DeviceCommandCompletionStatus, Never>()
	
	public let getPairedComplete = PassthroughSubject<DeviceCommandCompletionStatus, Never>()
	public let setPairedComplete = PassthroughSubject<DeviceCommandCompletionStatus, Never>()
	public let setUnpairedComplete = PassthroughSubject<DeviceCommandCompletionStatus, Never>()
	
	public let getPageThresholdComplete = PassthroughSubject<DeviceCommandCompletionStatus, Never>()
	public let setPageThresholdComplete = PassthroughSubject<DeviceCommandCompletionStatus, Never>()
	public let deletePageThresholdComplete = PassthroughSubject<DeviceCommandCompletionStatus, Never>()
	
	// MARK: Passthrough subjects (Notifications)
	public let updateFirmwareStarted = PassthroughSubject<Void, Never>()
	public let updateFirmwareFinished = PassthroughSubject<Void, Never>()
	public let updateFirmwareProgress = PassthroughSubject<Float, Never>()
	public let updateFirmwareFailed = PassthroughSubject<(Int, String), Never>()
	
	public let heartRateUpdated = PassthroughSubject<(Int, Int, [Double]), Never>()
	public let endSleepStatus = PassthroughSubject<Bool, Never>()
	public let manufacturingTestResult = PassthroughSubject<(Bool, String), Never>()

	public let ppgFailed = PassthroughSubject<Int, Never>()
	public let streamingPacket = PassthroughSubject<String, Never>()

	public let dataPackets = PassthroughSubject<(Int, String), Never>()
	public let dataComplete = PassthroughSubject<(Int, Int, Int, Int, Bool), Never>()
	public let dataFailure = PassthroughSubject<Void, Never>()

	// MARK: Lambda Completions
	var lambdaWriteEpochComplete: ((_ id: String, _ successful: Bool)->())?
	var lambdaReadEpochComplete: ((_ id: String, _ successful: Bool, _ value: Int)->())?

	var lambdaGetPacketCountComplete: ((_ id: String, _ successful: Bool, _ count: Int)->())?
	var lambdaGetAllPacketsComplete: ((_ id: String, _ successful: Bool)->())?
	var lambdaGetAllPacketsAcknowledgeComplete: ((_ id: String, _ successful: Bool, _ ack: Bool)->())?
	
	var lambdaStartManualComplete: ((_ id: String, _ successful: Bool)->())?
	var lambdaStopManualComplete: ((_ id: String, _ successful: Bool)->())?
	
	var lambdaLEDComplete: ((_ id: String, _ successful: Bool)->())?
	
	var lambdaEnterShipModeComplete: ((_ id: String, _ successful: Bool)->())?
	var lambdaResetComplete: ((_ id: String, _ successful: Bool)->())?
	var lambdaAirplaneModeComplete: ((_ id: String, _ successful: Bool)->())?

	var lamdaWriteSerialNumberComplete: ((_ id: String, _ successful: Bool)->())?
	var lambdaReadSerialNumberComplete: ((_ id: String, _ successful: Bool, _ partID: String)->())?
	var lambdaDeleteSerialNumberComplete: ((_ id: String, _ successful: Bool)->())?
	
	var lambdaWriteAdvIntervalComplete: ((_ id: String, _ successful: Bool)->())?
	var lambdaReadAdvIntervalComplete: ((_ id: String, _ successful: Bool, _ seconds: Int)->())?
	var lambdaDeleteAdvIntervalComplete: ((_ id: String, _ successful: Bool)->())?
	
	var lambdaClearChargeCyclesComplete: ((_ id: String, _ successful: Bool)->())?
	var lambdaReadChargeCyclesComplete: ((_ id: String, _ successful: Bool, _ cycles: Float)->())?
	
	var lambdaReadCanLogDiagnosticsComplete: ((_ id: String, _ successful: Bool, _ allow: Bool)->())?
	var lambdaUpdateCanLogDiagnosticsComplete: ((_ id: String, _ successful: Bool)->())?

	var lambdaRawLoggingComplete: ((_ id: String, _ successful: Bool)->())?

	var lambdaWornCheckComplete: ((_ id: String, _ successful: Bool, _ code: String, _ value: Int)->())?
	var lambdaEndSleepComplete: ((_ id: String, _ successful: Bool)->())?
	
	var lambdaDisableWornDetectComplete: ((_ id: String, _ successful: Bool)->())?
	var lambdaEnableWornDetectComplete: ((_ id: String, _ successful: Bool)->())?
	
	var lambdaSetHRZoneColorComplete: ((_ id: String, _ successful: Bool, _ type: hrZoneRangeType)->())?
	var lambdaGetHRZoneColorComplete: ((_ id: String, _ successful: Bool, _ type: hrZoneRangeType, _ red: Bool, _ green: Bool, _ blue: Bool, _ on_ms: Int, _ off_ms: Int)->())?
	var lambdaSetHRZoneRangeComplete: ((_ id: String, _ successful: Bool)->())?
	var lambdaGetHRZoneRangeComplete: ((_ id: String, _ successful: Bool, _ enabled: Bool, _ high_value: Int, _ low_value: Int)->())?
	var lambdaGetPPGAlgorithmComplete: ((_ id: String, _ successful: Bool, _ algorithm: ppgAlgorithmConfiguration, _ state: eventType)->())?
	
	var lambdaSetAskForButtonResponseComplete: ((_ id: String, _ successful: Bool, _ enable: Bool)->())?
	var lambdaGetAskForButtonResponseComplete: ((_ id: String, _ successful: Bool, _ enable: Bool)->())?
	
	var lambdaSetAdvertiseAsHRMComplete: ((_ id: String, _ successful: Bool, _ asHRM: Bool)->())?
	var lambdaGetAdvertiseAsHRMComplete: ((_ id: String, _ successful: Bool, _ asHRM: Bool)->())?
	
	var lambdaSetButtonCommandComplete: ((_ id: String, _ successful: Bool, _ tap: buttonTapType, _ command: buttonCommandType)->())?
	var lambdaGetButtonCommandComplete: ((_ id: String, _ successful: Bool, _ tap: buttonTapType, _ command: buttonCommandType)->())?
	
	var lambdaGetPairedComplete: ((_ id: String, _ successful: Bool, _ paired: Bool)->())?
	var lambdaSetPairedComplete: ((_ id: String, _ successful: Bool)->())?
	var lambdaSetUnpairedComplete: ((_ id: String, _ successful: Bool)->())?
	
	var lambdaGetPageThresholdComplete: ((_ id: String, _ successful: Bool, _ threshold: Int)->())?
	var lambdaSetPageThresholdComplete: ((_ id: String, _ successful: Bool)->())?
	var lambdaDeletePageThresholdComplete: ((_ id: String, _ successful: Bool)->())?

	var lambdaManufacturingTestComplete: ((_ id: String, _ successful: Bool)->())?
	var lambdaManufacturingTestResult: ((_ id: String, _ valid: Bool, _ result: String)->())?

	var lambdaGetRawLoggingStatusComplete: ((_ id: String, _ successful: Bool, _ enabled: Bool)->())?
	var lambdaGetWornOverrideStatusComplete: ((_ id: String, _ successful: Bool, _ overridden: Bool)->())?

	var lambdaSetSessionParamComplete: ((_ id: String, _ successful: Bool, _ parameter: sessionParameterType)->())?
	var lambdaGetSessionParamComplete: ((_ id: String, _ successful: Bool, _ parameter: sessionParameterType, _ value: Int)->())?
	var lambdaResetSessionParamsComplete: ((_ id: String, _ successful: Bool)->())?
	var lambdaAcceptSessionParamsComplete: ((_ id: String, _ successful: Bool)->())?

	// MARK: Lambda Notifications
	var lambdaBatteryLevelUpdated: ((_ id: String, _ percentage: Int)->())?

	var lambdaPPGMetrics: ((_ id: String, _ successful: Bool, _ packet: String)->())?
	var lambdaPPGFailed: ((_ id: String, _ code: Int)->())?
	var lambdaStreamingPacket: ((_ id: String, _ packet: String)->())?

	var lambdaHeartRateUpdated: ((_ id: String, _ epoch: Int, _ hr: Int, _ rr: [Double])->())?
	var lambdaEndSleepStatus: ((_ id: String, _ hasSleep: Bool)->())?
	var lambdaButtonClicked: ((_ id: String, _ presses: Int)->())?
	var lambdaDataAvailable: ((_ id: String)->())?

	var lambdaDataPackets: ((_ id: String, _ sequence_number: Int, _ packets: String)->())?
	var lambdaDataComplete: ((_ id: String, _ bad_fw_read_count: Int, _ bad_fw_parse_count: Int, _ overflow_count: Int, _ bad_sdk_parse_count: Int, _ intermediate: Bool)->())?
	var lambdaDataFailure: ((_ id: String)->())?
	
	var lambdaWornStatus: ((_ id: String, _ isWorn: Bool)->())?
	var lambdaChargingStatus: ((_ id: String, _ charging: Bool, _ on_charger: Bool, _ error: Bool)->())?

	var lambdaUpdateFirmwareStarted: ((_ id: String)->())?
	var lambdaUpdateFirmwareFinished: ((_ id: String)->())?
	var lambdaUpdateFirmwareProgress: ((_ id: String, _ percentage: Float)->())?
	var lambdaUpdateFirmwareFailed: ((_ id: String, _ code: Int, _ message: String)->())?

	internal var mModelNumber					: disStringCharacteristic?
	internal var mFirmwareVersion				: disFirmwareVersionCharacteristic?
	internal var mSoftwareRevision				: disSoftwareRevisionCharacteristic?
	internal var mHardwareRevision				: disStringCharacteristic?
	internal var mManufacturerName				: disStringCharacteristic?
	internal var mSerialNumber					: disStringCharacteristic?
	internal var mDISCharacteristicCount		: Int = 0
	internal var mDISCharacteristicsDiscovered	: Bool = false
	
	internal var mBatteryLevelCharacteristic	: batteryLevelCharacteristic?
	internal var mMainCharacteristic			: customMainCharacteristic?
	internal var mDataCharacteristic			: customDataCharacteristic?
	internal var mStreamingCharacteristic		: customStreamingCharacteristic?

	internal var mHeartRateMeasurementCharacteristic	: heartRateMeasurementCharacteristic?
	internal var mAmbiqOTARXCharacteristic				: ambiqOTARXCharacteristic?
	internal var mAmbiqOTATXCharacteristic				: ambiqOTATXCharacteristic?
	
	class var manufacturer_prefixes: [String] {
		#if UNIVERSAL
		return [prefixes.alter.rawValue, prefixes.kairos.rawValue]
		#endif
				
		#if ALTER
		return [prefixes.alter.rawValue]
		#endif
		
		#if KAIROS
		return [prefixes.kairos.rawValue]
		#endif
	}
	
	class var scan_services: [CBUUID] {
		#if UNIVERSAL
		return [services.alter.UUID, services.kairos.UUID]
		#endif
				
		#if ALTER
		return [services.alter.UUID]
		#endif
		
		#if KAIROS
		return [services.kairos.UUID]
		#endif
	}
	
	class func hit(_ service: CBService) -> Bool {
		if let peripheral = service.peripheral {
			if let standardService = org_bluetooth_service(rawValue: service.prettyID) {
				log?.v ("\(peripheral.prettyID): '\(standardService.title)'")
				switch standardService {
				case .device_information,
					 .battery_service,
					 .pulse_oximeter,
					 .heart_rate			: return (true)
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

	override public init() {
		self.connectionState = .disconnected
		
		self.name							= "UNKNOWN"
		self.id								= "UNKNOWN"
		self.creation_epoch = TimeInterval(0)
		self.mDISCharacteristicCount		= 0
		self.mDISCharacteristicsDiscovered	= false
		self.discovery_type					= .unknown
		
		#if UNIVERSAL
		self.type							= .unknown
		#endif
	}

	#if UNIVERSAL
	convenience public init(_ name: String, id: String, peripheral: CBPeripheral?, type: biostrapDeviceSDK.biostrapDeviceType, discoveryType: biostrapDeviceSDK.biostrapDiscoveryType) {
		self.init()
		
		self.name		= name
		self.id			= id
		self.peripheral	= peripheral
		self.type		= type
		self.discovery_type = discoveryType
	}
	#endif

	convenience public init(_ name: String, id: String, peripheral: CBPeripheral?, discoveryType: biostrapDeviceSDK.biostrapDiscoveryType) {
		self.init()
		
		self.name		= name
		self.id			= id
		self.peripheral	= peripheral
		self.discovery_type = discoveryType
	}
	
	#if UNIVERSAL || ALTER
	private var mAlterConfigured: Bool {
		if let ambiqOTARXCharacteristic = mAmbiqOTARXCharacteristic, let ambiqOTATXCharacteristic = mAmbiqOTATXCharacteristic, let mainCharacteristic = mMainCharacteristic, let batteryCharacteristic = mBatteryLevelCharacteristic {
			
			if let dataCharacteristic = mDataCharacteristic, let strmCharacteristic = mStreamingCharacteristic {
				//log?.v ("ALTER MAIN: \(mainCharacteristic.configured), ALTER DATA: \(dataCharacteristic.configured), BAT: \(batteryCharacteristic.configured), OTARX: \(ambiqOTARXCharacteristic.configured), OTATX: \(ambiqOTATXCharacteristic.configured)")
				
				return (mDISCharacteristicsDiscovered && mDISCharacteristicCount == 0 &&
						batteryCharacteristic.configured &&
						mainCharacteristic.configured &&
						dataCharacteristic.configured &&
						strmCharacteristic.configured &&
						ambiqOTARXCharacteristic.configured &&
						ambiqOTATXCharacteristic.configured
				)
			}
			else {
				//log?.v ("ALTER: \(mainCharacteristic.configured), BAT: \(batteryCharacteristic.configured), OTARX: \(ambiqOTARXCharacteristic.configured), OTATX: \(ambiqOTATXCharacteristic.configured)")
				
				return (mDISCharacteristicsDiscovered && mDISCharacteristicCount == 0 &&
						batteryCharacteristic.configured &&
						mainCharacteristic.configured &&
						ambiqOTARXCharacteristic.configured &&
						ambiqOTATXCharacteristic.configured
				)
			}
		}
		else { return (false) }
	}
	#endif

	#if UNIVERSAL || KAIROS
	private var mKairosConfigured: Bool {
		if let ambiqOTARXCharacteristic = mAmbiqOTARXCharacteristic, let ambiqOTATXCharacteristic = mAmbiqOTATXCharacteristic, let mainCharacteristic = mMainCharacteristic, let batteryCharacteristic = mBatteryLevelCharacteristic {
			
			if let dataCharacteristic = mDataCharacteristic, let strmCharacteristic = mStreamingCharacteristic {
				//log?.v ("ALTER MAIN: \(mainCharacteristic.configured), ALTER DATA: \(dataCharacteristic.configured), BAT: \(batteryCharacteristic.configured), OTARX: \(ambiqOTARXCharacteristic.configured), OTATX: \(ambiqOTATXCharacteristic.configured)")
				
				return (mDISCharacteristicsDiscovered && mDISCharacteristicCount == 0 &&
						batteryCharacteristic.configured &&
						mainCharacteristic.configured &&
						dataCharacteristic.configured &&
						strmCharacteristic.configured &&
						ambiqOTARXCharacteristic.configured &&
						ambiqOTATXCharacteristic.configured
				)
			}
			else {
				//log?.v ("ALTER: \(mainCharacteristic.configured), BAT: \(batteryCharacteristic.configured), OTARX: \(ambiqOTARXCharacteristic.configured), OTATX: \(ambiqOTATXCharacteristic.configured)")
				
				return (mDISCharacteristicsDiscovered && mDISCharacteristicCount == 0 &&
						batteryCharacteristic.configured &&
						mainCharacteristic.configured &&
						ambiqOTARXCharacteristic.configured &&
						ambiqOTATXCharacteristic.configured
				)
			}
		}
		else { return (false) }
	}
	#endif

	var configured: Bool {
		if let firmwareVesion = mFirmwareVersion, let customCharacteristic = mMainCharacteristic {
			customCharacteristic.firmwareVersion = firmwareVesion.value
		}
		
		#if UNIVERSAL
		switch type {
		case .alter		: return mAlterConfigured
		case .kairos	: return mKairosConfigured
		case .unknown	: return false
		}
		#endif
				
		#if ALTER
		return mAlterConfigured
		#endif
		
		#if KAIROS
		return mKairosConfigured
		#endif
	}
	
	//--------------------------------------------------------------------------------
	// Function Name: writeEpoch
	//--------------------------------------------------------------------------------
	//
	// Two ways to get here - one is from the SDK wrapper (internal), and one is
	// directly (public).
	//
	//--------------------------------------------------------------------------------
	func writeEpochInternal(_ newEpoch: Int) {
		if let mainCharacteristic = mMainCharacteristic {
			mainCharacteristic.writeEpoch(newEpoch)
		}
		else { self.lambdaWriteEpochComplete?(id, false) }
	}

	public func writeEpoch(_ newEpoch: Int) {
		if let mainCharacteristic = mMainCharacteristic {
			mainCharacteristic.writeEpoch(newEpoch)
		}
		else {
			DispatchQueue.main.async { self.writeEpochComplete.send(.not_configured) }
		}
	}

	//--------------------------------------------------------------------------------
	// Function Name: readEpoch
	//--------------------------------------------------------------------------------
	//
	// Two ways to get here - one is from the SDK wrapper (internal), and one is
	// directly (public).
	//
	//--------------------------------------------------------------------------------
	func readEpochInternal() {
		if let mainCharacteristic = mMainCharacteristic {
			mainCharacteristic.readEpoch()
		}
		else { self.lambdaReadEpochComplete?(id, false, 0) }
	}

	public func readEpoch() {
		if let mainCharacteristic = mMainCharacteristic {
			mainCharacteristic.readEpoch()
		}
		else {
			DispatchQueue.main.async {
				self.epoch = nil
				self.readEpochComplete.send(.not_configured)
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
	func endSleepInternal() {
		if let mainCharacteristic = mMainCharacteristic {
			mainCharacteristic.endSleep()
		}
		else { self.lambdaEndSleepComplete?(id, false) }
	}
	
	public func endSleep() {
		if let mainCharacteristic = mMainCharacteristic {
			mainCharacteristic.endSleep()
		}
		else {
			DispatchQueue.main.async { self.endSleepComplete.send(.not_configured) }
		}
	}


	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func getAllPacketsInternal(pages: Int, delay: Int) {
		var newStyle	= false
		
		if let mainCharacteristic = mMainCharacteristic {
			if let softwareVersion = mSoftwareRevision {
				if (softwareVersion.bluetoothGreaterThan("2.0.4")) {
					log?.v ("Bluetooth library version: '\(softwareVersion.bluetooth)' - Use new style")
					newStyle	= true
				}
				else {
					log?.v ("Bluetooth library version: '\(softwareVersion.bluetooth)' - Use old style")
				}
			}
			else {
				log?.e ("Can't find the software version, i guess i will use the old style")
			}

			mainCharacteristic.getAllPackets(pages: pages, delay: delay, newStyle: newStyle)
		}
		else { self.lambdaGetAllPacketsComplete?(id, false) }
	}

	public func getAllPackets(pages: Int, delay: Int) {
		var newStyle	= false
		
		if let mainCharacteristic = mMainCharacteristic {
			if let softwareVersion = mSoftwareRevision {
				if (softwareVersion.bluetoothGreaterThan("2.0.4")) {
					log?.v ("Bluetooth library version: '\(softwareVersion.bluetooth)' - Use new style")
					newStyle	= true
				}
				else {
					log?.v ("Bluetooth library version: '\(softwareVersion.bluetooth)' - Use old style")
				}
			}
			else {
				log?.e ("Can't find the software version, i guess i will use the old style")
			}

			mainCharacteristic.getAllPackets(pages: pages, delay: delay, newStyle: newStyle)
		}
		else {
			DispatchQueue.main.async {
				self.getAllPacketsComplete.send(.not_configured)
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
	func getAllPacketsAcknowledgeInternal(_ ack: Bool) {
		if let mainCharacteristic = mMainCharacteristic {
			mainCharacteristic.getAllPacketsAcknowledge(ack)
		}
		else { self.lambdaGetAllPacketsAcknowledgeComplete?(id, false, ack) }
	}
	
	public func getAllPacketsAcknowledge(_ ack: Bool) {
		if let mainCharacteristic = mMainCharacteristic {
			mainCharacteristic.getAllPacketsAcknowledge(ack)
		}
		else {
			DispatchQueue.main.async {
				self.getAllPacketsAcknowledgeComplete.send((.not_configured, ack))
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
	func getPacketCountInternal() {
		if let mainCharacteristic = mMainCharacteristic {
			mainCharacteristic.getPacketCount()
		}
		else { self.lambdaGetPacketCountComplete?(id, false, 0) }
	}

	public func getPacketCount() {
		if let mainCharacteristic = mMainCharacteristic {
			mainCharacteristic.getPacketCount()
		}
		else {
			DispatchQueue.main.async {
				self.getPacketCountComplete.send((.not_configured, 0))
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
	func disableWornDetectInternal() {
		if let mainCharacteristic = mMainCharacteristic {
			mainCharacteristic.disableWornDetect()
		}
		else { self.lambdaDisableWornDetectComplete?(id, false) }
	}

	public func disableWornDetect() {
		if let mainCharacteristic = mMainCharacteristic {
			mainCharacteristic.disableWornDetect()
		}
		else {
			DispatchQueue.main.async { self.disableWornDetectComplete.send(.not_configured) }
		}
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func enableWornDetectInternal() {
		if let mainCharacteristic = mMainCharacteristic {
			mainCharacteristic.enableWornDetect()
		}
		else { self.lambdaEnableWornDetectComplete?(id, false) }
	}

	public func enableWornDetect() {
		if let mainCharacteristic = mMainCharacteristic {
			mainCharacteristic.enableWornDetect()
		}
		else {
			DispatchQueue.main.async { self.enableWornDetectComplete.send(.not_configured) }
		}
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func startManualInternal(_ algorithms: ppgAlgorithmConfiguration) {
		if let mainCharacteristic = mMainCharacteristic {
			mainCharacteristic.startManual(algorithms)
		}
		else { self.lambdaStartManualComplete?(id, false) }
	}

	public func startManual(_ algorithms: ppgAlgorithmConfiguration) {
		if let mainCharacteristic = mMainCharacteristic {
			mainCharacteristic.startManual(algorithms)
		}
		else {
			DispatchQueue.main.async { self.startManualComplete.send(.not_configured) }
		}
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func stopManualInternal() {
		if let mainCharacteristic = mMainCharacteristic {
			mainCharacteristic.stopManual()
		}
		else { self.lambdaStopManualComplete?(id, false) }
	}
	
	public func stopManual() {
		if let mainCharacteristic = mMainCharacteristic {
			mainCharacteristic.stopManual()
		}
		else {
			DispatchQueue.main.async { self.stopManualComplete.send(.not_configured) }
		}
	}

	#if UNIVERSAL || ALTER
	func alterLEDInternal(red: Bool, green: Bool, blue: Bool, blink: Bool, seconds: Int) {
		if let mainCharacteristic = mMainCharacteristic {
			mainCharacteristic.alterLED(red: red, green: green, blue: blue, blink: blink, seconds: seconds)
		}
		else { self.lambdaLEDComplete?(id, false) }
	}
	
	public func alterLED(red: Bool, green: Bool, blue: Bool, blink: Bool, seconds: Int) {
		if let mainCharacteristic = mMainCharacteristic {
			mainCharacteristic.alterLED(red: red, green: green, blue: blue, blink: blink, seconds: seconds)
		}
		else {
			DispatchQueue.main.async { self.ledComplete.send(.not_configured) }
		}
	}
	#endif

	#if UNIVERSAL || KAIROS
	func kairosLEDInternal(red: Bool, green: Bool, blue: Bool, blink: Bool, seconds: Int) {
		if let mainCharacteristic = mMainCharacteristic {
			mainCharacteristic.kairosLED(red: red, green: green, blue: blue, blink: blink, seconds: seconds)
		}
		else { self.lambdaLEDComplete?(id, false) }
	}
	
	public func kairosLED(red: Bool, green: Bool, blue: Bool, blink: Bool, seconds: Int) {
		if let mainCharacteristic = mMainCharacteristic {
			mainCharacteristic.kairosLED(red: red, green: green, blue: blue, blink: blink, seconds: seconds)
		}
		else {
			DispatchQueue.main.async { self.ledComplete.send(.not_configured) }
		}
	}
	#endif

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func enterShipModeInternal() {
		if let mainCharacteristic = mMainCharacteristic {
			mainCharacteristic.enterShipMode()
		}
		else { self.lambdaEnterShipModeComplete?(id, false) }
	}

	public func enterShipMode() {
		if let mainCharacteristic = mMainCharacteristic {
			mainCharacteristic.enterShipMode()
		}
		else {
			DispatchQueue.main.async {
				self.enterShipModeComplete.send(.not_configured)
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
	func resetInternal() {
		if let mainCharacteristic = mMainCharacteristic {
			mainCharacteristic.reset()
		}
		else { self.lambdaResetComplete?(id, false) }
	}
	
	public func reset() {
		if let mainCharacteristic = mMainCharacteristic {
			mainCharacteristic.reset()
		}
		else {
			DispatchQueue.main.async {
				self.resetComplete.send(.not_configured)
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
	func airplaneModeInternal() {
		if let mainCharacteristic = mMainCharacteristic {
			mainCharacteristic.airplaneMode()
		}
		else { self.lambdaAirplaneModeComplete?(id, false) }
	}

	public func airplaneMode() {
		if let mainCharacteristic = mMainCharacteristic {
			mainCharacteristic.airplaneMode()
		}
		else {
			DispatchQueue.main.async {
				self.airplaneModeComplete.send(.not_configured)
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
	func writeSerialNumberInternal(_ partID: String) {
		if let mainCharacteristic = mMainCharacteristic {
			mainCharacteristic.writeSerialNumber(partID)
		}
		else { self.lamdaWriteSerialNumberComplete?(id, false) }
	}

	public func writeSerialNumber(_ partID: String) {
		if let mainCharacteristic = mMainCharacteristic {
			mainCharacteristic.writeSerialNumber(partID)
		}
		else {
			DispatchQueue.main.async {
				self.writeSerialNumberComplete.send(.not_configured)
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
	func readSerialNumberInternal() {
		if let mainCharacteristic = mMainCharacteristic {
			mainCharacteristic.readSerialNumber()
		}
		else { self.lambdaReadSerialNumberComplete?(id, false, "") }
	}

	public func readSerialNumber() {
		if let mainCharacteristic = mMainCharacteristic {
			mainCharacteristic.readSerialNumber()
		}
		else {
			DispatchQueue.main.async {
				self.readSerialNumberComplete.send(.not_configured)
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
	func deleteSerialNumberInternal() {
		if let mainCharacteristic = mMainCharacteristic {
			mainCharacteristic.deleteSerialNumber()
		}
		else { self.lambdaDeleteSerialNumberComplete?(id, false) }
	}

	public func deleteSerialNumber() {
		if let mainCharacteristic = mMainCharacteristic {
			mainCharacteristic.deleteSerialNumber()
		}
		else {
			DispatchQueue.main.async {
				self.deleteSerialNumberComplete.send(.not_configured)
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
	func writeAdvIntervalInternal(_ seconds: Int) {
		if let mainCharacteristic = mMainCharacteristic {
			mainCharacteristic.writeAdvInterval(seconds)
		}
		else { self.lambdaWriteAdvIntervalComplete?(id, false) }
	}

	public func writeAdvInterval(_ seconds: Int) {
		if let mainCharacteristic = mMainCharacteristic {
			mainCharacteristic.writeAdvInterval(seconds)
		}
		else {
			DispatchQueue.main.async {
				self.writeAdvIntervalComplete.send(.not_configured)
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
	func readAdvIntervalInternal() {
		if let mainCharacteristic = mMainCharacteristic {
			mainCharacteristic.readAdvInterval()
		}
		else { self.lambdaReadAdvIntervalComplete?(id, false, 0) }
	}

	public func readAdvInterval() {
		if let mainCharacteristic = mMainCharacteristic {
			mainCharacteristic.readAdvInterval()
		}
		else {
			DispatchQueue.main.async {
				self.readAdvIntervalComplete.send(.not_configured)
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
	func deleteAdvIntervalInternal() {
		if let mainCharacteristic = mMainCharacteristic {
			mainCharacteristic.deleteAdvInterval()
		}
		else { self.lambdaDeleteAdvIntervalComplete?(id, false) }
	}

	public func deleteAdvInterval() {
		if let mainCharacteristic = mMainCharacteristic {
			mainCharacteristic.deleteAdvInterval()
		}
		else {
			DispatchQueue.main.async {
				self.deleteAdvIntervalComplete.send(.not_configured)
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
	func clearChargeCyclesInternal() {
		if let mainCharacteristic = mMainCharacteristic {
			mainCharacteristic.clearChargeCycles()
		}
		else { self.lambdaClearChargeCyclesComplete?(id, false) }
	}

	public func clearChargeCycles() {
		if let mainCharacteristic = mMainCharacteristic {
			mainCharacteristic.clearChargeCycles()
		}
		else {
			DispatchQueue.main.async {
				self.clearChargeCyclesComplete.send(.not_configured)
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
	func readChargeCyclesInternal() {
		if let mainCharacteristic = mMainCharacteristic {
			mainCharacteristic.readChargeCycles()
		}
		else { self.lambdaReadChargeCyclesComplete?(id, false, 0.0) }
	}

	public func readChargeCycles() {
		if let mainCharacteristic = mMainCharacteristic {
			mainCharacteristic.readChargeCycles()
		}
		else {
			DispatchQueue.main.async {
				self.readChargeCyclesComplete.send(.not_configured)
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
	func readCanLogDiagnosticsInternal() {
		if let mainCharacteristic = mMainCharacteristic {
			mainCharacteristic.readCanLogDiagnostics()
		}
		else { self.lambdaReadCanLogDiagnosticsComplete?(id, false, false) }
	}
	
	public func readCanLogDiagnostics() {
		if let mainCharacteristic = mMainCharacteristic {
			mainCharacteristic.readCanLogDiagnostics()
		}
		else {
			DispatchQueue.main.async {
				self.canLogDiagnostics = nil
				self.readCanLogDiagnosticsComplete.send(.not_configured)
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
	func updateCanLogDiagnosticsInternal(_ allow: Bool) {
		if let mainCharacteristic = mMainCharacteristic {
			mainCharacteristic.updateCanLogDiagnostics(allow)
		}
		else { self.lambdaUpdateCanLogDiagnosticsComplete?(id, false) }
	}
		
	public func updateCanLogDiagnostics(_ allow: Bool) {
		if let mainCharacteristic = mMainCharacteristic {
			mainCharacteristic.updateCanLogDiagnostics(allow)
		}
		else {
			DispatchQueue.main.async {
				self.updateCanLogDiagnosticsComplete.send(.not_configured)
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
	#if UNIVERSAL || ALTER
	func alterManufacturingTestInternal(_ test: alterManufacturingTestType) {
		if let mainCharacteristic = mMainCharacteristic {
			mainCharacteristic.alterManufacturingTest(test)
		}
		else { self.lambdaManufacturingTestComplete?(id, false) }
	}
	
	public func alterManufacturingTest(_ test: alterManufacturingTestType) {
		if let mainCharacteristic = mMainCharacteristic {
			mainCharacteristic.alterManufacturingTest(test)
		}
		else {
			DispatchQueue.main.async {
				self.manufacturingTestComplete.send(.not_configured)
			}
		}
	}
	#endif

	#if UNIVERSAL || KAIROS
	func kairosManufacturingTestInternal(_ test: kairosManufacturingTestType) {
		if let mainCharacteristic = mMainCharacteristic {
			mainCharacteristic.kairosManufacturingTest(test)
		}
		else { self.lambdaManufacturingTestComplete?(id, false) }
	}
	
	public func kairosManufacturingTest(_ test: kairosManufacturingTestType) {
		if let mainCharacteristic = mMainCharacteristic {
			mainCharacteristic.kairosManufacturingTest(test)
		}
		else {
			DispatchQueue.main.async {
				self.manufacturingTestComplete.send(.not_configured)
			}
		}
	}
	#endif

	//--------------------------------------------------------------------------------
	// Function Name: setAskForButtonResponse
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func setAskForButtonResponseInternal(_ enable: Bool) {
		if let mainCharacteristic = mMainCharacteristic { mainCharacteristic.setAskForButtonResponse(enable) }
		else { self.lambdaSetAskForButtonResponseComplete?(self.id, false, enable) }
	}
	
	public func setAskForButtonResponse(_ enable: Bool) {
		if let mainCharacteristic = mMainCharacteristic { mainCharacteristic.setAskForButtonResponse(enable) }
		else {
			DispatchQueue.main.async {
				self.setAskForButtonResponseComplete.send(.not_configured)
			}
		}
	}
	
	//--------------------------------------------------------------------------------
	// Function Name: getAskForButtonResponse
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func getAskForButtonResponseInternal() {
		if let mainCharacteristic = mMainCharacteristic { mainCharacteristic.getAskForButtonResponse() }
		else { self.lambdaGetAskForButtonResponseComplete?(self.id, false, false) }
	}
	
	public func getAskForButtonResponse() {
		if let mainCharacteristic = mMainCharacteristic { mainCharacteristic.getAskForButtonResponse() }
		else {
			DispatchQueue.main.async {
				self.getAskForButtonResponseComplete.send(.not_configured)
			}
		}
	}
	
	//--------------------------------------------------------------------------------
	// Function Name: setHRZoneColor
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func setHRZoneColorInternal(_ type: hrZoneRangeType, red: Bool, green: Bool, blue: Bool, on_milliseconds: Int, off_milliseconds: Int) {
		if let mainCharacteristic = mMainCharacteristic {
			mainCharacteristic.setHRZoneColor(type, red: red, green: green, blue: blue, on_milliseconds: on_milliseconds, off_milliseconds: off_milliseconds)
		}
		else { self.lambdaSetHRZoneColorComplete?(self.id, false, type) }
	}

	public func setHRZoneColor(_ type: hrZoneRangeType, red: Bool, green: Bool, blue: Bool, on_milliseconds: Int, off_milliseconds: Int) {
		if let mainCharacteristic = mMainCharacteristic {
			mainCharacteristic.setHRZoneColor(type, red: red, green: green, blue: blue, on_milliseconds: on_milliseconds, off_milliseconds: off_milliseconds)
		}
		else {
			DispatchQueue.main.async {
				self.setHRZoneColorComplete.send((.not_configured, type))
			}
		}
	}

	//--------------------------------------------------------------------------------
	// Function Name: getHRZoneColor
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func getHRZoneColorInternal(_ type: hrZoneRangeType) {
		if let mainCharacteristic = mMainCharacteristic {
			mainCharacteristic.getHRZoneColor(type)
		}
		else { self.lambdaGetHRZoneColorComplete?(self.id, false, type, false, false, false, 0, 0) }
	}
	
	public func getHRZoneColor(_ type: hrZoneRangeType) {
		if let mainCharacteristic = mMainCharacteristic {
			mainCharacteristic.getHRZoneColor(type)
		}
		else {
			DispatchQueue.main.async {
				self.getHRZoneColorComplete.send((.not_configured, type))
			}
		}
	}
	
	//--------------------------------------------------------------------------------
	// Function Name: setHRZoneRange
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func setHRZoneRangeInternal(_ enabled: Bool, high_value: Int, low_value: Int) {
		if let mainCharacteristic = mMainCharacteristic {
			mainCharacteristic.setHRZoneRange(enabled, high_value: high_value, low_value: low_value)
		}
		else { self.lambdaSetHRZoneRangeComplete?(self.id, false) }
	}
	
	public func setHRZoneRange(_ enabled: Bool, high_value: Int, low_value: Int) {
		if let mainCharacteristic = mMainCharacteristic {
			mainCharacteristic.setHRZoneRange(enabled, high_value: high_value, low_value: low_value)
		}
		else {
			DispatchQueue.main.async {
				self.setHRZoneRangeComplete.send(.not_configured)
			}
		}
	}
	
	//--------------------------------------------------------------------------------
	// Function Name: getHRZoneRange
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func getHRZoneRangeInternal() {
		if let mainCharacteristic = mMainCharacteristic {
			mainCharacteristic.getHRZoneRange()
		}
		else { self.lambdaGetHRZoneRangeComplete?(self.id, false, false, 0, 0) }
	}
	
	public func getHRZoneRange() {
		if let mainCharacteristic = mMainCharacteristic {
			mainCharacteristic.getHRZoneRange()
		}
		else {
			DispatchQueue.main.async {
				self.getHRZoneRangeComplete.send(.not_configured)
			}
		}
	}
	
	//--------------------------------------------------------------------------------
	// Function Name: getPPGAlgorithm
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func getPPGAlgorithmInternal() {
		if let mainCharacteristic = mMainCharacteristic { mainCharacteristic.getPPGAlgorithm() }
		else { self.lambdaGetPPGAlgorithmComplete?(self.id, false, ppgAlgorithmConfiguration(), eventType.unknown) }
	}
	
	public func getPPGAlgorithm() {
		if let mainCharacteristic = mMainCharacteristic { mainCharacteristic.getPPGAlgorithm() }
		else {
			DispatchQueue.main.async {
				self.getPPGAlgorithmComplete.send((false, ppgAlgorithmConfiguration(), eventType.unknown))
			}
		}
	}

	//--------------------------------------------------------------------------------
	// Function Name: setAdvertiseAsHRM
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func setAdvertiseAsHRMInternal(_ asHRM: Bool) {
		if let mainCharacteristic = mMainCharacteristic { mainCharacteristic.setAdvertiseAsHRM(asHRM) }
		else { self.lambdaSetAdvertiseAsHRMComplete?(self.id, false, false) }
	}

	public func setAdvertiseAsHRM(_ asHRM: Bool) {
		if let mainCharacteristic = mMainCharacteristic { mainCharacteristic.setAdvertiseAsHRM(asHRM) }
		else {
			DispatchQueue.main.async {
				self.advertiseAsHRM = nil
				self.setAdvertiseAsHRMComplete.send(.not_configured)
			}
		}
	}

	//--------------------------------------------------------------------------------
	// Function Name: getAdvertiseAsHRM
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func getAdvertiseAsHRMInternal() {
		if let mainCharacteristic = mMainCharacteristic { mainCharacteristic.getAdvertiseAsHRM() }
		else { self.lambdaGetAdvertiseAsHRMComplete?(self.id, false, false) }
	}

	public func getAdvertiseAsHRM() {
		if let mainCharacteristic = mMainCharacteristic { mainCharacteristic.getAdvertiseAsHRM() }
		else {
			DispatchQueue.main.async {
				self.getAdvertiseAsHRMComplete.send(.not_configured)
			}
		}
	}

	//--------------------------------------------------------------------------------
	// Function Name: setButtonCommand
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func setButtonCommandInternal(_ tap: buttonTapType, command: buttonCommandType) {
		if let mainCharacteristic = mMainCharacteristic { mainCharacteristic.setButtonCommand(tap, command: command) }
		else { self.lambdaSetButtonCommandComplete?(self.id, false, tap, command) }
	}

	public func setButtonCommand(_ tap: buttonTapType, command: buttonCommandType) {
		if let mainCharacteristic = mMainCharacteristic { mainCharacteristic.setButtonCommand(tap, command: command) }
		else {
			DispatchQueue.main.async {
				self.setButtonCommandComplete.send((.not_configured, tap))
			}
		}
	}

	//--------------------------------------------------------------------------------
	// Function Name: getButtonCommand
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func getButtonCommandInternal(_ tap: buttonTapType) {
		if let mainCharacteristic = mMainCharacteristic { mainCharacteristic.getButtonCommand(tap) }
		else { self.lambdaGetButtonCommandComplete?(self.id, false, tap, .unknown) }
	}
	
	public func getButtonCommand(_ tap: buttonTapType) {
		if let mainCharacteristic = mMainCharacteristic { mainCharacteristic.getButtonCommand(tap) }
		else {
			DispatchQueue.main.async {
				self.getButtonCommandComplete.send((.not_configured, tap))
			}
		}
	}
	
	//--------------------------------------------------------------------------------
	// Function Name: setPaired
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func setPairedInternal() {
		if let mainCharacteristic = mMainCharacteristic { mainCharacteristic.setPaired() }
		else { self.lambdaSetPairedComplete?(self.id, false) }
	}

	public func setPaired() {
		if let mainCharacteristic = mMainCharacteristic { mainCharacteristic.setPaired() }
		else {
			self.setPairedComplete.send(.not_configured)
		}
	}

	//--------------------------------------------------------------------------------
	// Function Name: setUnpaired
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func setUnpairedInternal() {
		if let mainCharacteristic = mMainCharacteristic { mainCharacteristic.setUnpaired() }
		else { self.lambdaSetUnpairedComplete?(self.id, false) }
	}
	
	public func setUnpaired() {
		if let mainCharacteristic = mMainCharacteristic { mainCharacteristic.setUnpaired() }
		else {
			self.setUnpairedComplete.send(.not_configured)
		}
	}
	
	//--------------------------------------------------------------------------------
	// Function Name: getPaired
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func getPairedInternal() {
		if let mainCharacteristic = mMainCharacteristic { mainCharacteristic.getPaired() }
		else { self.lambdaGetPairedComplete?(self.id, false, false) }
	}
	
	public func getPaired() {
		if let mainCharacteristic = mMainCharacteristic { mainCharacteristic.getPaired() }
		else {
			self.paired = nil
			self.getPairedComplete.send(.not_configured)
		}
	}
	
	//--------------------------------------------------------------------------------
	// Function Name: setPaired
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func setPageThresholdInternal(_ threshold: Int) {
		if let mainCharacteristic = mMainCharacteristic { mainCharacteristic.setPageThreshold(threshold) }
		else { self.lambdaSetPageThresholdComplete?(self.id, false) }
	}
	
	public func setPageThreshold(_ threshold: Int) {
		if let mainCharacteristic = mMainCharacteristic { mainCharacteristic.setPageThreshold(threshold) }
		else {
			self.setPageThresholdComplete.send(.not_configured)
		}
	}
	
	//--------------------------------------------------------------------------------
	// Function Name: setUnpaired
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func getPageThresholdInternal() {
		if let mainCharacteristic = mMainCharacteristic { mainCharacteristic.getPageThreshold() }
		else { self.lambdaGetPageThresholdComplete?(self.id, false, 1) }
	}
	
	public func getPageThreshold() {
		if let mainCharacteristic = mMainCharacteristic { mainCharacteristic.getPageThreshold() }
		else {
			self.advertisingPageThreshold = nil
			self.getPageThresholdComplete.send(.not_configured)
		}
	}
	
	//--------------------------------------------------------------------------------
	// Function Name: getPaired
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func deletePageThresholdInternal() {
		if let mainCharacteristic = mMainCharacteristic { mainCharacteristic.deletePageThreshold() }
		else { self.lambdaDeletePageThresholdComplete?(self.id, false) }
	}

	public func deletePageThreshold() {
		if let mainCharacteristic = mMainCharacteristic { mainCharacteristic.deletePageThreshold() }
		else {
			self.deletePageThresholdComplete.send(.not_configured)
		}
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func rawLoggingInternal(_ enable: Bool) {
		if let mainCharacteristic = mMainCharacteristic {
			mainCharacteristic.rawLogging(enable)
		}
		else { self.lambdaRawLoggingComplete?(id, false) }
	}

	public func rawLogging(_ enable: Bool) {
		if let mainCharacteristic = mMainCharacteristic {
			mainCharacteristic.rawLogging(enable)
		}
		else {
			DispatchQueue.main.async {
				self.rawLoggingComplete.send(.not_configured)
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
	func wornCheckInternal() {
		if let mainCharacteristic = mMainCharacteristic {
			mainCharacteristic.wornCheck()
		}
		else { self.lambdaWornCheckComplete?(id, false, "Missing Characteristic", 0) }
	}

	public func wornCheck() {
		if let mainCharacteristic = mMainCharacteristic {
			mainCharacteristic.wornCheck()
		}
		else {
			DispatchQueue.main.async {
				self.wornCheckResult = wornCheckResultType(code: "Missing characteristic", value: 0)
				self.wornCheckResultComplete.send(.not_configured)
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
	func getRawLoggingStatusInternal() {
		if let mainCharacteristic = mMainCharacteristic {
			mainCharacteristic.getRawLoggingStatus()
		}
		else { self.lambdaGetRawLoggingStatusComplete?(id, false, false) }
	}
	
	public func getRawLoggingStatus() {
		if let mainCharacteristic = mMainCharacteristic {
			mainCharacteristic.getRawLoggingStatus()
		}
		else {
			DispatchQueue.main.async {
				self.getRawLoggingStatusComplete.send(.not_configured)
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
	func getWornOverrideStatusInternal() {
		if let mainCharacteristic = mMainCharacteristic {
			mainCharacteristic.getWornOverrideStatus()
		}
		else { self.lambdaGetWornOverrideStatusComplete?(id, false, false) }
	}
	
	public func getWornOverrideStatus() {
		if let mainCharacteristic = mMainCharacteristic {
			mainCharacteristic.getWornOverrideStatus()
		}
		else {
			DispatchQueue.main.async {
				self.getWornOverrideStatusComplete.send(.not_configured)
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
	func updateFirmwareInternal(_ file: URL) {
		if let ambiqOTARXCharacteristic = mAmbiqOTARXCharacteristic {
			do {
				let contents = try Data(contentsOf: file)
				ambiqOTARXCharacteristic.start(contents)
			}
			catch {
				log?.e ("Cannot open file")
				self.lambdaUpdateFirmwareFailed?(self.id, 10001, "Cannot parse file for update")
			}
		}
		else { lambdaUpdateFirmwareFailed?(self.id, 10001, "No OTA RX characteristic to update") }
	}

	public func updateFirmware(_ file: URL) {
		if let ambiqOTARXCharacteristic = mAmbiqOTARXCharacteristic {
			do {
				let contents = try Data(contentsOf: file)
				ambiqOTARXCharacteristic.start(contents)
			}
			catch {
				log?.e ("Cannot open file")
				DispatchQueue.main.async {
					self.updateFirmwareFailed.send((10001, "Cannot parse file for update"))
				}
			}
		}
		else {
			DispatchQueue.main.async {
				self.updateFirmwareFailed.send((10001, "No OTA RX characteristic to update"))
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
	func cancelFirmwareUpdateInternal() {
		if let ambiqOTARXCharacteristic = mAmbiqOTARXCharacteristic { ambiqOTARXCharacteristic.cancel() }
		else { lambdaUpdateFirmwareFailed?(self.id, 10001, "No characteristic to cancel") }		
	}

	public func cancelFirmwareUpdate() {
		if let ambiqOTARXCharacteristic = mAmbiqOTARXCharacteristic { ambiqOTARXCharacteristic.cancel() }
		else {
			DispatchQueue.main.async {
				self.updateFirmwareFailed.send((10001, "No characteristic to cancel"))
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
	func setSessionParamInternal(_ parameter: sessionParameterType, value: Int) {
		log?.v("\(self.id): \(parameter)")

		if let mainCharacteristic = mMainCharacteristic {
			mainCharacteristic.setSessionParam(parameter, value: value)
		}
		else { self.lambdaSetSessionParamComplete?(self.id, false, parameter) }
	}

	public func setSessionParam(_ parameter: sessionParameterType, value: Int) {
		log?.v("\(self.id): \(parameter)")

		if let mainCharacteristic = mMainCharacteristic {
			mainCharacteristic.setSessionParam(parameter, value: value)
		}
		else {
			DispatchQueue.main.async {
				switch parameter {
				case .tag: self.tag = nil
				case .ppgCapturePeriod: self.ppgCapturePeriod = nil
				case .ppgCaptureDuration: self.ppgCaptureDuration = nil
				default: break
				}
				self.setSessionParamComplete.send((.not_configured, parameter))
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
	func getSessionParamInternal(_ parameter: sessionParameterType) {
		log?.v("\(self.id): \(parameter)")

		if let mainCharacteristic = mMainCharacteristic {
			mainCharacteristic.getSessionParam(parameter)
		}
		else { self.lambdaGetSessionParamComplete?(self.id, false, parameter, 0) }
	}

	public func getSessionParam(_ parameter: sessionParameterType) {
		log?.v("\(self.id): \(parameter)")

		if let mainCharacteristic = mMainCharacteristic {
			mainCharacteristic.getSessionParam(parameter)
		}
		else {
			DispatchQueue.main.async {
				switch parameter {
				case .tag: self.tag = nil
				case .ppgCapturePeriod: self.ppgCapturePeriod = nil
				case .ppgCaptureDuration: self.ppgCaptureDuration = nil
				default: break
				}
				self.setSessionParamComplete.send((.not_configured, parameter))
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
	func resetSessionParamsInternal() {
		log?.v("\(self.id)")

		if let mainCharacteristic = mMainCharacteristic {
			mainCharacteristic.resetSessionParams()
		}
		else { self.lambdaResetSessionParamsComplete?(self.id, false) }
	}

	public func resetSessionParams() {
		log?.v("\(self.id)")

		if let mainCharacteristic = mMainCharacteristic {
			mainCharacteristic.resetSessionParams()
		}
		else {
			DispatchQueue.main.async {
				self.resetSessionParamsComplete.send(.not_configured)
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
	func acceptSessionParamsInternal() {
		log?.v("\(self.id)")

		if let mainCharacteristic = mMainCharacteristic {
			mainCharacteristic.acceptSessionParams()
		}
		else { self.lambdaAcceptSessionParamsComplete?(self.id, false) }
	}
	
	public func acceptSessionParams() {
		log?.v("\(self.id)")

		if let mainCharacteristic = mMainCharacteristic {
			mainCharacteristic.acceptSessionParams()
		}
		else {
			DispatchQueue.main.async {
				self.acceptSessionParamsComplete.send(.not_configured)
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
	private func attachMainCharacteristicLambdas() {
		mMainCharacteristic?.writeEpochComplete = { successful in
			self.lambdaWriteEpochComplete?(self.id, successful)
			DispatchQueue.main.async { self.writeEpochComplete.send(successful ? .successful : .device_error) }
		}
		
		mMainCharacteristic?.readEpochComplete = { successful, value in
			self.lambdaReadEpochComplete?(self.id, successful,  value)
			DispatchQueue.main.async {
				self.epoch = value
				self.readEpochComplete.send(successful ? .successful : .device_error)
			}
		}
		
		mMainCharacteristic?.deviceWornStatus = { isWorn in
			self.lambdaWornStatus?(self.id, isWorn)
			DispatchQueue.main.async {
				if (isWorn) { self.wornStatus = "Worn" }
				else { self.wornStatus = "Not Worn" }
			}
		}
		
		mMainCharacteristic?.deviceChargingStatus			= { charging, on_charger, error in
			self.lambdaChargingStatus?(self.id, charging, on_charger, error)
			DispatchQueue.main.async {
				if (charging) { self.chargingStatus	= "Charging" }
				else if (on_charger) { self.chargingStatus = "On Charger" }
				else if (error) { self.chargingStatus = "Charging Error" }
				else { self.chargingStatus = "Not Charging" }
			}
		}

		mMainCharacteristic?.startManualComplete = { successful in
			self.lambdaStartManualComplete?(self.id, successful)
			DispatchQueue.main.async { self.startManualComplete.send(successful ? .successful : .device_error) }
		}
		
		mMainCharacteristic?.stopManualComplete = { successful in
			self.lambdaStopManualComplete?(self.id, successful)
			DispatchQueue.main.async { self.stopManualComplete.send(successful ? .successful : .device_error) }
		}
		
		mMainCharacteristic?.ledComplete = { successful in
			self.lambdaLEDComplete?(self.id, successful)
			DispatchQueue.main.async { self.ledComplete.send(successful ? .successful : .device_error) }
		}
		
		mMainCharacteristic?.getRawLoggingStatusComplete = { successful, enabled in
			self.lambdaGetRawLoggingStatusComplete?(self.id, successful, enabled)
			DispatchQueue.main.async {
				if successful {
					self.rawLogging = enabled
				}
				else {
					self.rawLogging = nil
				}
				self.getRawLoggingStatusComplete.send(successful ? .successful : .device_error)
			}
		}
		
		mMainCharacteristic?.getWornOverrideStatusComplete = { successful, overridden in
			self.lambdaGetWornOverrideStatusComplete?(self.id, successful, overridden)
			DispatchQueue.main.async {
				if successful {
					self.wornOverridden = overridden
				}
				else {
					self.wornOverridden = nil
				}
				self.getWornOverrideStatusComplete.send(successful ? .successful : .device_error)
			}
		}
		
		mMainCharacteristic?.writeSerialNumberComplete = { successful in
			self.lamdaWriteSerialNumberComplete?(self.id, successful)
			DispatchQueue.main.async {
				self.writeSerialNumberComplete.send(successful ? .successful : .device_error)
			}
		}

		mMainCharacteristic?.readSerialNumberComplete = { successful, partID in
			self.lambdaReadSerialNumberComplete?(self.id, successful, partID)
			DispatchQueue.main.async {
				if successful { self.serialNumber = partID }
				self.readSerialNumberComplete.send(successful ? .successful : .device_error)
			}
		}
		
		mMainCharacteristic?.deleteSerialNumberComplete = { successful in
			self.lambdaDeleteSerialNumberComplete?(self.id, successful)
			DispatchQueue.main.async {
				self.deleteSerialNumberComplete.send(successful ? .successful : .device_error)
			}
		}
		
		mMainCharacteristic?.writeAdvIntervalComplete = { successful in
			self.lambdaWriteAdvIntervalComplete?(self.id, successful)
			DispatchQueue.main.async {
				self.writeAdvIntervalComplete.send(successful ? .successful : .device_error)
			}
		}
		
		mMainCharacteristic?.readAdvIntervalComplete = { successful, seconds in
			self.lambdaReadAdvIntervalComplete?(self.id, successful, seconds)
			DispatchQueue.main.async {
				self.advertisingInterval = seconds
				self.readAdvIntervalComplete.send(successful ? .successful : .device_error)
			}
		}
		
		mMainCharacteristic?.deleteAdvIntervalComplete = { successful in
			self.lambdaDeleteAdvIntervalComplete?(self.id, successful)
			DispatchQueue.main.async {
				if successful { self.advertisingInterval = nil }
				self.deleteAdvIntervalComplete.send(successful ? .successful : .device_error)
			}
		}
		
		mMainCharacteristic?.clearChargeCyclesComplete = { successful in
			self.lambdaClearChargeCyclesComplete?(self.id, successful)
			DispatchQueue.main.async {
				if successful { self.chargeCycles = nil }
				self.clearChargeCyclesComplete.send(successful ? .successful : .device_error)
			}
		}
		
		mMainCharacteristic?.readChargeCyclesComplete = { successful, cycles in
			self.lambdaReadChargeCyclesComplete?(self.id, successful, cycles)
			DispatchQueue.main.async {
				self.chargeCycles = cycles
				self.readChargeCyclesComplete.send(successful ? .successful : .device_error)
			}
		}

		mMainCharacteristic?.setAdvertiseAsHRMComplete	= { successful, asHRM in
			self.lambdaSetAdvertiseAsHRMComplete?(self.id, successful, asHRM)
			DispatchQueue.main.async {
				if successful {
					self.advertiseAsHRM = asHRM
				}
				else {
					self.advertiseAsHRM = nil
				}
				self.setAdvertiseAsHRMComplete.send(successful ? .successful : .device_error)
			}
		}
		mMainCharacteristic?.getAdvertiseAsHRMComplete	= { successful, asHRM in
			self.lambdaGetAdvertiseAsHRMComplete?(self.id, successful, asHRM)
			DispatchQueue.main.async {
				if successful {
					self.advertiseAsHRM = asHRM
				}
				else {
					self.advertiseAsHRM = nil
				}
				self.getAdvertiseAsHRMComplete.send(successful ? .successful : .device_error)
			}
		}
		mMainCharacteristic?.setButtonCommandComplete	= { successful, tap, command in
			self.lambdaSetButtonCommandComplete?(self.id, successful, tap, command)
			DispatchQueue.main.async {
				switch tap {
				case .single: self.singleButtonPressAction = successful ? command : nil
				case .double: self.doubleButtonPressAction = successful ? command : nil
				case .triple: self.tripleButtonPressAction = successful ? command : nil
				case .long: self.longButtonPressAction = successful ? command : nil
				default: break
				}
				self.setButtonCommandComplete.send((successful ? .successful : .device_error, tap))
			}
		}
		mMainCharacteristic?.getButtonCommandComplete	= { successful, tap, command in
			self.lambdaGetButtonCommandComplete?(self.id, successful, tap, command)
			DispatchQueue.main.async {
				switch tap {
				case .single: self.singleButtonPressAction = successful ? command : nil
				case .double: self.doubleButtonPressAction = successful ? command : nil
				case .triple: self.tripleButtonPressAction = successful ? command : nil
				case .long: self.longButtonPressAction = successful ? command : nil
				default: break
				}
				self.getButtonCommandComplete.send((successful ? .successful : .device_error, tap))
			}
		}
		
		mMainCharacteristic?.setAskForButtonResponseComplete = { successful, enable in
			self.lambdaSetAskForButtonResponseComplete?(self.id, successful, enable)
			DispatchQueue.main.async {
				if successful {
					self.buttonResponseEnabled = enable
				}
				else {
					self.buttonResponseEnabled = false
				}
				self.setAskForButtonResponseComplete.send(successful ? .successful : .device_error)
			}
		}
		
		mMainCharacteristic?.getAskForButtonResponseComplete = { successful, enable in
			self.lambdaGetAskForButtonResponseComplete?(self.id, successful, enable)
			DispatchQueue.main.async {
				if successful {
					self.buttonResponseEnabled = enable
				}
				else {
					self.buttonResponseEnabled = false
				}
				self.getAskForButtonResponseComplete.send(successful ? .successful : .device_error)
			}
		}
		
		mMainCharacteristic?.setHRZoneColorComplete		= { successful, type in
			self.lambdaSetHRZoneColorComplete?(self.id, successful, type)
			DispatchQueue.main.async {
				self.setHRZoneColorComplete.send((successful ? .successful : .device_error, type))
			}
		}
		
		mMainCharacteristic?.getHRZoneColorComplete		= { successful, type, red, green, blue, on_ms, off_ms in
			self.lambdaGetHRZoneColorComplete?(self.id, successful, type, red, green, blue, on_ms, off_ms)
			DispatchQueue.main.async {
				switch (type) {
				case .below: self.hrZoneLEDBelow = hrZoneLEDValueType(red: red, green: green, blue: blue, on_ms: on_ms, off_ms: off_ms)
				case .within: self.hrZoneLEDWithin = hrZoneLEDValueType(red: red, green: green, blue: blue, on_ms: on_ms, off_ms: off_ms)
				case .above: self.hrZoneLEDAbove = hrZoneLEDValueType(red: red, green: green, blue: blue, on_ms: on_ms, off_ms: off_ms)
				default: break
				}
				self.getHRZoneColorComplete.send((successful ? .successful : .device_error, type))
			}
		}
		
		mMainCharacteristic?.setHRZoneRangeComplete		= { successful in
			self.lambdaSetHRZoneRangeComplete?(self.id, successful)
			DispatchQueue.main.async {
				self.setHRZoneRangeComplete.send(successful ? .successful : .device_error)
			}
		}
		
		mMainCharacteristic?.getHRZoneRangeComplete		= { successful, enabled, high_value, low_value in
			self.lambdaGetHRZoneRangeComplete?(self.id, successful, enabled, high_value, low_value)
			DispatchQueue.main.async {
				if successful {
					self.hrZoneRange = hrZoneRangeValueType(enabled: enabled, lower: low_value, upper: high_value)
				}
				self.getHRZoneRangeComplete.send(successful ? .successful : .device_error)
			}
		}
		
		mMainCharacteristic?.getPPGAlgorithmComplete	= { successful, algorithm, state in
			self.lambdaGetPPGAlgorithmComplete?(self.id, successful, algorithm, state)
			DispatchQueue.main.async {
				self.getPPGAlgorithmComplete.send((successful, algorithm, state))
			}
		}
		
		mMainCharacteristic?.endSleepComplete = { successful in
			self.lambdaEndSleepComplete?(self.id, successful)
			DispatchQueue.main.async {
				self.endSleepComplete.send(successful ? .successful : .device_error)
			}
		}
		
		mMainCharacteristic?.endSleepStatus = { enable in
			self.lambdaEndSleepStatus?(self.id, enable)
			DispatchQueue.main.async {
				self.endSleepStatus.send(enable)
			}
		}
		
		mMainCharacteristic?.disableWornDetectComplete = { successful in
			self.lambdaDisableWornDetectComplete?(self.id, successful)
			DispatchQueue.main.async {
				self.disableWornDetectComplete.send(successful ? .successful : .device_error)
			}
		}
		
		mMainCharacteristic?.enableWornDetectComplete = { successful in
			self.lambdaEnableWornDetectComplete?(self.id, successful)
			DispatchQueue.main.async {
				self.enableWornDetectComplete.send(successful ? .successful : .device_error)
			}
		}
		
		mMainCharacteristic?.buttonClicked = { presses in
			self.lambdaButtonClicked?(self.id, presses)
			DispatchQueue.main.async {
				self.buttonPresses = presses
			}
		}
		
		mMainCharacteristic?.wornCheckComplete = { successful, code, value in
			self.lambdaWornCheckComplete?(self.id, successful, code, value )
			DispatchQueue.main.async {
				self.wornCheckResult = wornCheckResultType(code: code, value: value)
				self.wornCheckResultComplete.send(successful ? .successful : .device_error)
			}
		}
		
		mMainCharacteristic?.setSessionParamComplete = { successful, parameter in
			log?.v ("setSessionParamComplete: \(successful), \(parameter)")
			self.lambdaSetSessionParamComplete?(self.id, successful, parameter)
			DispatchQueue.main.async {
				self.setSessionParamComplete.send((successful ? .successful : .device_error, parameter))
			}
		}
		
		mMainCharacteristic?.getSessionParamComplete = { successful, parameter, value in
			log?.v ("getSessionParamComplete: \(successful), \(parameter), \(value)")
			self.lambdaGetSessionParamComplete?(self.id, successful, parameter, value)
			DispatchQueue.main.async {
				switch parameter {
				case .tag:
					var data = Data()
					data.append((UInt8((value >> 0) & 0xff)))
					data.append((UInt8((value >> 8) & 0xff)))
					if let strValue = String(data: data, encoding: .utf8) {
						self.tag = strValue
					}
					else {
						self.tag = "'\(String(format:"0x%04X", value))' - Could not make string"
					}
				case .ppgCapturePeriod: self.ppgCapturePeriod = value
				case .ppgCaptureDuration: self.ppgCaptureDuration = value
				default: break
				}
				self.getSessionParamComplete.send((successful ? .successful : .device_error, parameter))
			}
		}
		
		mMainCharacteristic?.acceptSessionParamsComplete	= { successful in
			self.lambdaAcceptSessionParamsComplete?(self.id, successful)
			DispatchQueue.main.async {
				self.acceptSessionParamsComplete.send(successful ? .successful : .device_error)
			}
		}
		
		mMainCharacteristic?.resetSessionParamsComplete	= { successful in
			self.lambdaResetSessionParamsComplete?(self.id, successful)
			DispatchQueue.main.async {
				self.resetSessionParamsComplete.send(successful ? .successful : .device_error)
			}
		}
		
		mMainCharacteristic?.readCanLogDiagnosticsComplete = { successful, allow in
			self.lambdaReadCanLogDiagnosticsComplete?(self.id, successful, allow)
			DispatchQueue.main.async {
				self.canLogDiagnostics = allow
				self.readCanLogDiagnosticsComplete.send(successful ? .successful : .device_error)
			}
		}
		
		mMainCharacteristic?.updateCanLogDiagnosticsComplete = { successful in
			self.lambdaUpdateCanLogDiagnosticsComplete?(self.id, successful)
			DispatchQueue.main.async {
				self.updateCanLogDiagnosticsComplete.send(successful ? .successful : .device_error)
			}
		}
		
		mMainCharacteristic?.getPacketCountComplete = { successful, count in
			self.lambdaGetPacketCountComplete?(self.id, successful, count)
			DispatchQueue.main.async {
				self.getPacketCountComplete.send((successful ? .successful : .device_error, count))
			}
		}
		
		mMainCharacteristic?.getAllPacketsComplete = { successful in
			self.lambdaGetAllPacketsComplete?(self.id, successful)
			DispatchQueue.main.async {
				self.getAllPacketsComplete.send(successful ? .successful : .device_error)
			}
		}
		
		mMainCharacteristic?.getAllPacketsAcknowledgeComplete = { successful, ack in
			self.lambdaGetAllPacketsAcknowledgeComplete?(self.id, successful, ack)
			DispatchQueue.main.async {
				self.getAllPacketsAcknowledgeComplete.send((successful ? .successful : .device_error, ack))
			}
		}
		
		mMainCharacteristic?.setPairedComplete			= { successful in
			self.lambdaSetPairedComplete?(self.id, successful)
			DispatchQueue.main.async {
				self.setPairedComplete.send(successful ? .successful : .device_error)
			}
		}
		
		mMainCharacteristic?.setUnpairedComplete		= { successful in
			self.lambdaSetUnpairedComplete?(self.id, successful)
			DispatchQueue.main.async {
				self.setUnpairedComplete.send(successful ? .successful : .device_error)
			}
		}
		
		mMainCharacteristic?.getPairedComplete			= { successful, paired in
			self.lambdaGetPairedComplete?(self.id, successful, paired)
			DispatchQueue.main.async {
				if successful {
					self.paired = paired
				}
				else {
					self.paired = nil
				}
				self.getPairedComplete.send(successful ? .successful : .device_error)
			}
		}
		
		mMainCharacteristic?.setPageThresholdComplete	= { successful in
			self.lambdaSetPageThresholdComplete?(self.id, successful)
			DispatchQueue.main.async {
				self.setPageThresholdComplete.send(successful ? .successful : .device_error)
			}
		}
		
		mMainCharacteristic?.getPageThresholdComplete	= { successful, threshold in
			self.lambdaGetPageThresholdComplete?(self.id, successful, threshold)
			DispatchQueue.main.async {
				if successful {
					self.advertisingPageThreshold = threshold
				}
				else {
					self.advertisingPageThreshold = nil
				}
				self.getPageThresholdComplete.send(successful ? .successful : .device_error)
			}
		}
		
		mMainCharacteristic?.deletePageThresholdComplete	= { successful in
			self.lambdaDeletePageThresholdComplete?(self.id, successful)
			DispatchQueue.main.async {
				self.deletePageThresholdComplete.send(successful ? .successful : .device_error)
			}
		}
		
		mMainCharacteristic?.enterShipModeComplete = { successful in
			self.lambdaEnterShipModeComplete?(self.id, successful)
			DispatchQueue.main.async {
				self.enterShipModeComplete.send(successful ? .successful : .device_error)
			}
		}
		
		mMainCharacteristic?.resetComplete = { successful in
			self.lambdaResetComplete?(self.id, successful)
			DispatchQueue.main.async {
				self.resetComplete.send(successful ? .successful : .device_error)
			}
		}
		
		mMainCharacteristic?.airplaneModeComplete		= { successful in
			self.lambdaAirplaneModeComplete?(self.id, successful)
			DispatchQueue.main.async {
				self.airplaneModeComplete.send(successful ? .successful : .device_error)
			}
		}
		
		mMainCharacteristic?.manufacturingTestComplete	= { successful in
			self.lambdaManufacturingTestComplete?(self.id, successful)
			DispatchQueue.main.async {
				self.manufacturingTestComplete.send(successful ? .successful : .device_error)
			}
		}
		
		mMainCharacteristic?.rawLoggingComplete = { successful in
			self.lambdaRawLoggingComplete?(self.id, successful)
			DispatchQueue.main.async {
				self.rawLoggingComplete.send(successful ? .successful : .device_error)
			}
		}
		
		// MARK: Notifications
		mMainCharacteristic?.manufacturingTestResult	= { valid, result in
			self.lambdaManufacturingTestResult?(self.id, valid, result)
			DispatchQueue.main.async {
				self.manufacturingTestResult.send((valid, result))
			}
		}
		
		mMainCharacteristic?.ppgMetrics = { successful, packet in
			self.lambdaPPGMetrics?(self.id, successful, packet)
			DispatchQueue.main.async {
				self.ppgMetrics = ppgMetricsType(packet)
			}
		}
		
		mMainCharacteristic?.ppgFailed = { code in
			self.lambdaPPGFailed?(self.id, code)
			DispatchQueue.main.async {
				self.ppgFailed.send(code)
			}
		}
		
		mMainCharacteristic?.dataPackets = { packets in
			self.lambdaDataPackets?(self.id, -1, packets)
			DispatchQueue.main.async {
				self.dataPackets.send((-1, packets))
			}
		}
		
		mMainCharacteristic?.dataComplete = { bad_fw_read_count, bad_fw_parse_count, overflow_count, bad_sdk_parse_count in
			self.lambdaDataComplete?(self.id, bad_fw_read_count, bad_fw_parse_count, overflow_count, bad_sdk_parse_count, false)
			DispatchQueue.main.async {
				self.dataComplete.send((bad_fw_read_count, bad_fw_parse_count, overflow_count, bad_sdk_parse_count, false))
			}
		}
		
		mMainCharacteristic?.dataFailure = { self.lambdaDataFailure?(self.id) }
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	private func attachDataCharacteristicLambdas() {
		mDataCharacteristic?.dataPackets = { sequence_number, packets in
			self.lambdaDataPackets?(self.id, sequence_number, packets)
			DispatchQueue.main.async {
				self.dataPackets.send((sequence_number, packets))
			}
		}
		
		mDataCharacteristic?.dataComplete = { bad_fw_read_count, bad_fw_parse_count, overflow_count, bad_sdk_parse_count, intermediate in
			self.lambdaDataComplete?(self.id, bad_fw_read_count, bad_fw_parse_count, overflow_count, bad_sdk_parse_count, intermediate)
			DispatchQueue.main.async {
				self.dataComplete.send((bad_fw_read_count, bad_fw_parse_count, overflow_count, bad_sdk_parse_count, intermediate))
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
	private func attachStreamingCharacteristicLambdas() {
		mStreamingCharacteristic?.deviceWornStatus			= { isWorn in
			self.lambdaWornStatus?(self.id, isWorn)
			DispatchQueue.main.async {
				if (isWorn) { self.wornStatus = "Worn" }
				else { self.wornStatus = "Not Worn" }
			}
		}
		mStreamingCharacteristic?.deviceChargingStatus		= { charging, on_charger, error in
			self.lambdaChargingStatus?(self.id, charging, on_charger, error)
			DispatchQueue.main.async {
				if (charging) { self.chargingStatus	= "Charging" }
				else if (on_charger) { self.chargingStatus = "On Charger" }
				else if (error) { self.chargingStatus = "Charging Error" }
				else { self.chargingStatus = "Not Charging" }
			}
		}
		
		mStreamingCharacteristic?.endSleepStatus = { enable in
			self.lambdaEndSleepStatus?(self.id, enable)
			DispatchQueue.main.async {
				self.endSleepStatus.send(enable)
			}
		}
		
		mStreamingCharacteristic?.buttonClicked = { presses in
			self.lambdaButtonClicked?(self.id, presses)
			DispatchQueue.main.async {
				self.buttonPresses = presses
			}
		}
		
		mStreamingCharacteristic?.manufacturingTestResult	= { valid, result in
			self.lambdaManufacturingTestResult?(self.id, valid, result)
			DispatchQueue.main.async {
				self.manufacturingTestResult.send((valid, result))
			}
		}
		
		mStreamingCharacteristic?.ppgMetrics = { successful, packet in
			self.lambdaPPGMetrics?(self.id, successful, packet)
			DispatchQueue.main.async {
				self.ppgMetrics = ppgMetricsType(packet)
			}
		}
		
		mStreamingCharacteristic?.ppgFailed = { code in
			self.lambdaPPGFailed?(self.id, code)
			DispatchQueue.main.async {
				self.ppgFailed.send(code)
			}
		}
		
		mStreamingCharacteristic?.streamingPacket = { packet in
			self.lambdaStreamingPacket?(self.id, packet)
			DispatchQueue.main.async {
				self.streamingPacket.send(packet)
			}
		}
		
		mStreamingCharacteristic?.dataAvailable = { self.lambdaDataAvailable?(self.id) }
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
					mDISCharacteristicsDiscovered	= true
					mDISCharacteristicCount = mDISCharacteristicCount + 1
					mModelNumber = disStringCharacteristic(peripheral, characteristic: characteristic)
					mModelNumber?.read()
				case .hardware_revision_string:
					mDISCharacteristicsDiscovered	= true
					mDISCharacteristicCount = mDISCharacteristicCount + 1
					mHardwareRevision = disStringCharacteristic(peripheral, characteristic: characteristic)
					mHardwareRevision?.read()
				case .firmware_revision_string:
					mDISCharacteristicsDiscovered	= true
					mDISCharacteristicCount = mDISCharacteristicCount + 1
					mFirmwareVersion = disFirmwareVersionCharacteristic(peripheral, characteristic: characteristic)
					mFirmwareVersion?.read()
				case .software_revision_string:
					mDISCharacteristicsDiscovered	= true
					mDISCharacteristicCount = mDISCharacteristicCount + 1
					#if UNIVERSAL
					mSoftwareRevision = disSoftwareRevisionCharacteristic(peripheral, characteristic: characteristic, type: type)
					#else
					mSoftwareRevision = disSoftwareRevisionCharacteristic(peripheral, characteristic: characteristic)
					#endif
					mSoftwareRevision?.read()
				case .manufacturer_name_string:
					mDISCharacteristicsDiscovered	= true
					mDISCharacteristicCount = mDISCharacteristicCount + 1
					mManufacturerName = disStringCharacteristic(peripheral, characteristic: characteristic)
					mManufacturerName?.read()
				case .serial_number_string:
					mDISCharacteristicsDiscovered	= true
					mDISCharacteristicCount = mDISCharacteristicCount + 1
					mSerialNumber = disStringCharacteristic(peripheral, characteristic: characteristic)
					mSerialNumber?.read()
				case .battery_level:
					log?.v ("\(self.id) '\(testCharacteristic.title)' - read it and enable notifications")
					mBatteryLevelCharacteristic	= batteryLevelCharacteristic(peripheral, characteristic: characteristic)
					mBatteryLevelCharacteristic?.updated	= { id, percentage in
						self.lambdaBatteryLevelUpdated?(id, percentage)
						DispatchQueue.main.async {
							self.batteryValid = true
							self.batteryLevel = percentage
						}
					}
					mBatteryLevelCharacteristic?.read()
					mBatteryLevelCharacteristic?.discoverDescriptors()
				case .heart_rate_measurement:
					log?.v ("\(self.id) '\(testCharacteristic.title)' - and enable notifications")
					mHeartRateMeasurementCharacteristic	= heartRateMeasurementCharacteristic(peripheral, characteristic: characteristic)
					mHeartRateMeasurementCharacteristic?.updated	= { id, epoch, hr, rr in
						self.lambdaHeartRateUpdated?(id, epoch, hr, rr)
						DispatchQueue.main.async {
							self.heartRateUpdated.send((epoch, hr, rr))
						}
					}
					mHeartRateMeasurementCharacteristic?.discoverDescriptors()
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
					
				#if UNIVERSAL || ALTER
				case .alterMainCharacteristic:
					mMainCharacteristic	= customMainCharacteristic(peripheral, characteristic: characteristic)
					#if UNIVERSAL
					mMainCharacteristic?.type	= .alter
					#endif
					attachMainCharacteristicLambdas()
					mMainCharacteristic?.discoverDescriptors()
					
				case .alterDataCharacteristic:
					mDataCharacteristic = customDataCharacteristic(peripheral, characteristic: characteristic)
					mDataCharacteristic?.discoverDescriptors()
					
				case .alterStrmCharacteristic:
					mStreamingCharacteristic = customStreamingCharacteristic(peripheral, characteristic: characteristic)
					#if UNIVERSAL
					mStreamingCharacteristic?.type	= .alter
					#endif
					attachStreamingCharacteristicLambdas()
					mStreamingCharacteristic?.discoverDescriptors()

				#endif

				#if UNIVERSAL || KAIROS
				case .kairosMainCharacteristic:
					mMainCharacteristic	= customMainCharacteristic(peripheral, characteristic: characteristic)
					#if UNIVERSAL
					mMainCharacteristic?.type	= .kairos
					#endif
					attachMainCharacteristicLambdas()
					mMainCharacteristic?.discoverDescriptors()

				case .kairosDataCharacteristic:
					mDataCharacteristic = customDataCharacteristic(peripheral, characteristic: characteristic)
					mDataCharacteristic?.discoverDescriptors()
					
				case .kairosStrmCharacteristic:
					mStreamingCharacteristic = customStreamingCharacteristic(peripheral, characteristic: characteristic)
					#if UNIVERSAL
					mStreamingCharacteristic?.type	= .kairos
					#endif
					attachStreamingCharacteristicLambdas()
					mStreamingCharacteristic?.discoverDescriptors()

				#endif

				case .ambiqOTARXCharacteristic:
					if let service = characteristic.service {
						log?.v ("\(self.id) for service: \(service.prettyID) - '\(testCharacteristic.title)'")
					}
					else {
						log?.v ("\(self.id) for nil service - '\(testCharacteristic.title)'")
					}
					
					mAmbiqOTARXCharacteristic = ambiqOTARXCharacteristic(peripheral, characteristic: characteristic)
					mAmbiqOTARXCharacteristic?.started	= {
						self.lambdaUpdateFirmwareStarted?(self.id)
						DispatchQueue.main.async {
							self.updateFirmwareStarted.send()
						}
					}
					
					mAmbiqOTARXCharacteristic?.finished = {
						self.lambdaUpdateFirmwareFinished?(self.id)
						DispatchQueue.main.async {
							self.updateFirmwareFinished.send()
						}
					}
					
					mAmbiqOTARXCharacteristic?.failed	= { code, message in
						self.lambdaUpdateFirmwareFailed?(self.id, code, message)
						DispatchQueue.main.async {
							self.updateFirmwareFailed.send((code, message))
						}
					}
					
					mAmbiqOTARXCharacteristic?.progress	= { percent in
						self.lambdaUpdateFirmwareProgress?(self.id, percent)
						DispatchQueue.main.async {
							self.updateFirmwareProgress.send(percent)
						}
					}
					
				case .ambiqOTATXCharacteristic:
					if let service = characteristic.service {
						log?.v ("\(self.id) for service: \(service.prettyID) - '\(testCharacteristic.title)'")
					}
					else {
						log?.v ("\(self.id) for nil service - '\(testCharacteristic.title)'")
					}
					
					mAmbiqOTATXCharacteristic = ambiqOTATXCharacteristic(peripheral, characteristic: characteristic)
					mAmbiqOTATXCharacteristic?.discoverDescriptors()
				
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
					#if UNIVERSAL || ALTER
					case .alterMainCharacteristic		: mMainCharacteristic?.didDiscoverDescriptor()
					case .alterDataCharacteristic		: mDataCharacteristic?.didDiscoverDescriptor()
					case .alterStrmCharacteristic		: mStreamingCharacteristic?.didDiscoverDescriptor()
					#endif

					#if UNIVERSAL || KAIROS
					case .kairosMainCharacteristic		: mMainCharacteristic?.didDiscoverDescriptor()
					case .kairosDataCharacteristic		: mDataCharacteristic?.didDiscoverDescriptor()
					case .kairosStrmCharacteristic		: mStreamingCharacteristic?.didDiscoverDescriptor()
					#endif

					case .ambiqOTARXCharacteristic		: log?.e ("\(self.id) '\(enumerated.title)' - should not be here")
					case .ambiqOTATXCharacteristic		: mAmbiqOTATXCharacteristic?.didDiscoverDescriptor()
					}
				}
				else if let enumerated = org_bluetooth_characteristic(rawValue: characteristic.prettyID) {
					switch (enumerated) {
					case .battery_level					: mBatteryLevelCharacteristic?.didDiscoverDescriptor()
					case .heart_rate_measurement		: mHeartRateMeasurementCharacteristic?.didDiscoverDescriptor()
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
			case .model_number_string			:
				mModelNumber?.didUpdateValue()
				if let modelNumberCharacteristic = mModelNumber {
					self.modelNumber = modelNumberCharacteristic.value
				}

				mDISCharacteristicCount			= mDISCharacteristicCount - 1

			case .hardware_revision_string		:
				mHardwareRevision?.didUpdateValue()
				if let hardwareRevisionCharacteristic = mHardwareRevision {
					self.hardwareRevision = hardwareRevisionCharacteristic.value
				}
				mDISCharacteristicCount			= mDISCharacteristicCount - 1

			case .firmware_revision_string		:
				mFirmwareVersion?.didUpdateValue()
				if let firmwareVersionCharacteristic = mFirmwareVersion {
					self.firmwareRevision = firmwareVersionCharacteristic.value
				}
				mDISCharacteristicCount			= mDISCharacteristicCount - 1

			case .software_revision_string		:
				mSoftwareRevision?.didUpdateValue()
				if let softwareRevisionCharacteristic = mSoftwareRevision {
					self.bluetoothSoftwareRevision = softwareRevisionCharacteristic.bluetooth
					self.algorithmsSoftwareRevision	= softwareRevisionCharacteristic.algorithms
					self.sleepSoftwareRevision = softwareRevisionCharacteristic.sleep
				}
				mDISCharacteristicCount			= mDISCharacteristicCount - 1

			case .manufacturer_name_string		:
				mManufacturerName?.didUpdateValue()
				if let manufacturerNameCharacteristic = mManufacturerName {
					self.manufacturerName = manufacturerNameCharacteristic.value
				}
				mDISCharacteristicCount			= mDISCharacteristicCount - 1

			case .serial_number_string			:
				mSerialNumber?.didUpdateValue()
				if let serialNumberCharacteristic = mSerialNumber {
					self.serialNumber = serialNumberCharacteristic.value
				}
				mDISCharacteristicCount			= mDISCharacteristicCount - 1

			case .battery_level					: mBatteryLevelCharacteristic?.didUpdateValue()
			case .heart_rate_measurement		: mHeartRateMeasurementCharacteristic?.didUpdateValue()
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
			#if UNIVERSAL || ALTER
			case .alterMainCharacteristic		: mMainCharacteristic?.didUpdateValue()
			case .alterDataCharacteristic		: mDataCharacteristic?.didUpdateValue()
			case .alterStrmCharacteristic		: mStreamingCharacteristic?.didUpdateValue()
			#endif

			#if UNIVERSAL || KAIROS
			case .kairosMainCharacteristic		: mMainCharacteristic?.didUpdateValue()
			case .kairosDataCharacteristic		: mDataCharacteristic?.didUpdateValue()
			case .kairosStrmCharacteristic		: mStreamingCharacteristic?.didUpdateValue()
			#endif
				
			case .ambiqOTARXCharacteristic		: log?.e ("\(self.id) '\(enumerated.title)' - should not be here")
			case .ambiqOTATXCharacteristic		:
				// Commands to RX come in on TX, causes RX to do next step
				if let value = characteristic.value {
					mAmbiqOTARXCharacteristic?.didUpdateTXValue(value)
				}
				else {
					log?.e ("\(self.id) '\(enumerated.title)' - No data received for RX command")
				}
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
					#if UNIVERSAL || ALTER
					case .alterMainCharacteristic			: mMainCharacteristic?.didUpdateNotificationState()
					case .alterDataCharacteristic			: mDataCharacteristic?.didUpdateNotificationState()
					case .alterStrmCharacteristic			: mStreamingCharacteristic?.didUpdateNotificationState()
					#endif

					#if UNIVERSAL || KAIROS
					case .kairosMainCharacteristic			: mMainCharacteristic?.didUpdateNotificationState()
					case .kairosDataCharacteristic			: mDataCharacteristic?.didUpdateNotificationState()
					case .kairosStrmCharacteristic			: mStreamingCharacteristic?.didUpdateNotificationState()
					#endif
						
					#if UNIVERSAL || ALTER || KAIROS
					case .ambiqOTARXCharacteristic			: log?.e ("\(self.id) '\(enumerated.title)' - should not be here")
					case .ambiqOTATXCharacteristic			: mAmbiqOTATXCharacteristic?.didUpdateNotificationState()
					#endif
					}
				}
				else if let enumerated = org_bluetooth_characteristic(rawValue: characteristic.prettyID) {
					log?.v ("\(self.id): '\(enumerated.title)'")
					
					switch (enumerated) {
					case .battery_level					: mBatteryLevelCharacteristic?.didUpdateNotificationState()
					case .heart_rate_measurement		: mHeartRateMeasurementCharacteristic?.didUpdateNotificationState()
					default								: log?.e ("\(self.id): '\(enumerated.title)'.  Do not know what to do - skipping")
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
		mAmbiqOTARXCharacteristic?.isReady()
	}

}
