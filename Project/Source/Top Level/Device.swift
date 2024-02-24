//
//  Device.swift
//  biostrapDeviceSDK
//
//  Created by Joseph A. Bennett on 3/31/21.
//

import Foundation
import CoreBluetooth
import Combine

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

public class Device: NSObject, ObservableObject {
	
	enum prefixes: String {
		#if UNIVERSAL || ALTER
		case alter = "ALT"
		#endif
		
		#if UNIVERSAL || ETHOS
		case ethos = "ETH"
		#endif
		
		#if UNIVERSAL || KAIROS
		case kairos = "KAI"
		#endif
		
		#if UNIVERSAL || LIVOTAL
		case livotal = "LIV"
		#endif
		
		case unknown = "UNK"
	}
		
	enum services: String {
		#if UNIVERSAL || ALTER
		case alter			= "883BBA2C-8E31-40BB-A859-D59A2FB38EC0"
		#endif
		
		#if UNIVERSAL || ETHOS
		case ethos			= "B30E0F19-A021-45F3-8661-4255CBD49E10"
		#endif
		
		#if UNIVERSAL || KAIROS
		case kairos			= "140BB753-9845-4C0E-B61A-E6BAE41712F0"
		#endif

		#if UNIVERSAL || ETHOS || ALTER || KAIROS
		case ambiqOTA		= "00002760-08C2-11E1-9073-0E8AC72E1001"
		#endif
		
		#if UNIVERSAL || LIVOTAL
		case livotal		= "58950000-A53F-11EB-BCBC-0242AC130002"
		case nordicDFU		= "FE59"
		#endif

		var UUID: CBUUID {
			return CBUUID(string: self.rawValue)
		}
		
		var title: String {
			switch (self) {
			#if UNIVERSAL || ALTER
			case .alter		: return "Alter Service"
			#endif

			#if UNIVERSAL || ETHOS
			case .ethos		: return "Ethos Service"
			#endif

			#if UNIVERSAL || KAIROS
			case .kairos	: return "Kairos Service"
			#endif
				
			#if UNIVERSAL || ETHOS || ALTER || KAIROS
			case .ambiqOTA	: return "Ambiq OTA Service"
			#endif

			#if UNIVERSAL || LIVOTAL
			case .livotal	: return "Livotal Service"
			case .nordicDFU	: return "Nordic DFU Service"
			#endif
			}
		}
	}

	enum characteristics: String {
		#if UNIVERSAL || ALTER
		case alterMainCharacteristic	= "883BBA2C-8E31-40BB-A859-D59A2FB38EC1"
		case alterDataCharacteristic	= "883BBA2C-8E31-40BB-A859-D59A2FB38EC2"
		case alterStrmCharacteristic	= "883BBA2C-8E31-40BB-A859-D59A2FB38EC3"
		#endif

		#if UNIVERSAL || ETHOS
		case ethosMainCharacteristic	= "B30E0F19-A021-45F3-8661-4255CBD49E11"
		case ethosDataCharacteristic	= "B30E0F19-A021-45F3-8661-4255CBD49E12"
		case ethosStrmCharacteristic	= "B30E0F19-A021-45F3-8661-4255CBD49E13"
		#endif

		#if UNIVERSAL || KAIROS
		case kairosMainCharacteristic	= "140BB753-9845-4C0E-B61A-E6BAE41712F1"
		case kairosDataCharacteristic	= "140BB753-9845-4C0E-B61A-E6BAE41712F2"
		case kairosStrmCharacteristic	= "140BB753-9845-4C0E-B61A-E6BAE41712F3"
		#endif

		#if UNIVERSAL || ETHOS || ALTER || KAIROS
		case ambiqOTARXCharacteristic	= "00002760-08C2-11E1-9073-0E8AC72E0001"
		case ambiqOTATXCharacteristic	= "00002760-08C2-11E1-9073-0E8AC72E0002"
		#endif

		#if UNIVERSAL || LIVOTAL
		case livotalMainCharacteristic	= "58950001-A53F-11EB-BCBC-0242AC130002"
		case livotalDataCharacteristic	= "58950002-A53F-11EB-BCBC-0242AC130002"
		case livotalStrmCharacteristic	= "58950003-A53F-11EB-BCBC-0242AC130002"
		case nordicDFUCharacteristic	= "8EC90003-F315-4F60-9FB8-838830DAEA50"
		#endif

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

			#if UNIVERSAL || ETHOS
			case .ethosMainCharacteristic	: return "Ethos Command Characteristic"
			case .ethosDataCharacteristic	: return "Ethos Data Characteristic"
			case .ethosStrmCharacteristic	: return "Ethos Streaming Characteristic"
			#endif

			#if UNIVERSAL || KAIROS
			case .kairosMainCharacteristic	: return "Kairos Command Characteristic"
			case .kairosDataCharacteristic	: return "Kairos Data Characteristic"
			case .kairosStrmCharacteristic	: return "Kairos Streaming Characteristic"
			#endif
				
			#if UNIVERSAL || ETHOS || ALTER || KAIROS
			case .ambiqOTARXCharacteristic	: return "Ambiq OTA RX Characteristic"
			case .ambiqOTATXCharacteristic	: return "Ambiq OTA TX Characteristic"
			#endif

			#if UNIVERSAL || LIVOTAL
			case .livotalMainCharacteristic	: return "Livotal Command Characteristic"
			case .livotalDataCharacteristic	: return "Livotal Data Characteristic"
			case .livotalStrmCharacteristic	: return "Livotal Streaming Characteristic"
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
	@Published public var name: String
	@Published public var id: String
	@Published public var discovery_type: biostrapDeviceSDK.biostrapDiscoveryType
	
	var epoch				: TimeInterval
	
	// MARK: Passthrough Subjects (Completions)
	public let readEpochComplete = PassthroughSubject<(Bool, Int), Never>()
	public let writeEpochComplete = PassthroughSubject<Bool, Never>()

	public let startManualComplete = PassthroughSubject<Bool, Never>()
	public let stopManualComplete = PassthroughSubject<Bool, Never>()
	
	public let ledComplete = PassthroughSubject<Bool, Never>()
	
	public let getRawLoggingStatusComplete = PassthroughSubject<(Bool, Bool), Never>()
	public let getWornOverrideStatusComplete = PassthroughSubject<(Bool, Bool), Never>()
	
	public let writeSerialNumberComplete = PassthroughSubject<Bool, Never>()
	public let readSerialNumberComplete = PassthroughSubject<(Bool, String), Never>()
	public let deleteSerialNumberComplete = PassthroughSubject<Bool, Never>()
	
	public let writeAdvIntervalComplete = PassthroughSubject<Bool, Never>()
	public let readAdvIntervalComplete = PassthroughSubject<(Bool, Int), Never>()
	public let deleteAdvIntervalComplete = PassthroughSubject<Bool, Never>()
	
	public let clearChargeCyclesComplete = PassthroughSubject<Bool, Never>()
	public let readChargeCyclesComplete = PassthroughSubject<(Bool, Float), Never>()

	#if UNIVERSAL || ALTER || ETHOS || KAIROS
	public let setAdvertiseAsHRMComplete = PassthroughSubject<(Bool, Bool), Never>()
	public let getAdvertiseAsHRMComplete = PassthroughSubject<(Bool, Bool), Never>()

	public let setButtonCommandComplete = PassthroughSubject<(Bool, buttonTapType, buttonCommandType), Never>()
	public let getButtonCommandComplete = PassthroughSubject<(Bool, buttonTapType, buttonCommandType), Never>()
	
	public let setAskForButtonResponseComplete = PassthroughSubject<(Bool, Bool), Never>()
	public let getAskForButtonResponseComplete = PassthroughSubject<(Bool, Bool), Never>()
	
	public let setHRZoneColorComplete = PassthroughSubject<(Bool, hrZoneRangeType), Never>()
	public let getHRZoneColorComplete = PassthroughSubject<(Bool, hrZoneRangeType), Never>()
	public let setHRZoneRangeComplete = PassthroughSubject<Bool, Never>()
	public let getHRZoneRangeComplete = PassthroughSubject<Bool, Never>()
	public let getPPGAlgorithmComplete = PassthroughSubject<(Bool, ppgAlgorithmConfiguration, eventType), Never>()
	
	@Published public var hrZoneLEDBelow = hrZoneLEDValueType()
	@Published public var hrZoneLEDWithin = hrZoneLEDValueType()
	@Published public var hrZoneLEDAbove = hrZoneLEDValueType()
	@Published public var hrZoneRange = hrZoneRangeValueType()
	#endif
	
	// MARK: Passthrough subjects (Notifications)
	public let heartRateUpdated = PassthroughSubject<(Int, Int, [Double]), Never>()


	// MARK: Lambda Completions
	var lambdaWriteEpochComplete: ((_ id: String, _ successful: Bool)->())?
	var lambdaReadEpochComplete: ((_ id: String, _ successful: Bool, _ value: Int)->())?

	var lambdaGetAllPacketsComplete: ((_ id: String, _ successful: Bool)->())?
	var lambdaGetAllPacketsAcknowledgeComplete: ((_ id: String, _ successful: Bool, _ ack: Bool)->())?
	var lambdaGetNextPacketComplete: ((_ id: String, _ successful: Bool, _ error_code: nextPacketStatusType, _ caughtUp: Bool, _ packet: String)->())?
	var lambdaGetPacketCountComplete: ((_ id: String, _ successful: Bool, _ count: Int)->())?
	
	var lambdaStartManualComplete: ((_ id: String, _ successful: Bool)->())?
	var lambdaStopManualComplete: ((_ id: String, _ successful: Bool)->())?
	
	var lambdaLEDComplete: ((_ id: String, _ successful: Bool)->())?
	
	#if UNIVERSAL || ETHOS
	var lambdaMotorComplete: ((_ id: String, _ successful: Bool)->())?
	#endif
	
	var lambdaEnterShipModeComplete: ((_ id: String, _ successful: Bool)->())?

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

	var lambdaAllowPPGComplete: ((_ id: String, _ successful: Bool)->())?
	var lambdaWornCheckComplete: ((_ id: String, _ successful: Bool, _ code: String, _ value: Int)->())?
	var lambdaRawLoggingComplete: ((_ id: String, _ successful: Bool)->())?
	var lambdaResetComplete: ((_ id: String, _ successful: Bool)->())?
	var lambdaEndSleepComplete: ((_ id: String, _ successful: Bool)->())?
	
	var lambdaDisableWornDetectComplete: ((_ id: String, _ successful: Bool)->())?
	var lambdaEnableWornDetectComplete: ((_ id: String, _ successful: Bool)->())?
	
	#if UNIVERSAL || ETHOS
	var lambdaDebugComplete: ((_ id: String, _ successful: Bool, _ device: debugDevice, _ data: Data)->())?
	#endif

	#if UNIVERSAL || ALTER || KAIROS || ETHOS
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
	#endif

	var lambdaManufacturingTestComplete: ((_ id: String, _ successful: Bool)->())?
	var lambdaManufacturingTestResult: ((_ id: String, _ valid: Bool, _ result: String)->())?

	var lambdaRecalibratePPGComplete: ((_ id: String, _ successful: Bool)->())?

	#if UNIVERSAL || ETHOS
	var lambdaStartLiveSyncComplete: ((_ id: String, _ successful: Bool)->())?
	var lambdaStopLiveSyncComplete: ((_ id: String, _ successful: Bool)->())?
	#endif

	var lambdaGetRawLoggingStatusComplete: ((_ id: String, _ successful: Bool, _ enabled: Bool)->())?
	var lambdaGetWornOverrideStatusComplete: ((_ id: String, _ successful: Bool, _ overridden: Bool)->())?

	var lambdaSetSessionParamComplete: ((_ id: String, _ successful: Bool, _ parameter: sessionParameterType)->())?
	var lambdaGetSessionParamComplete: ((_ id: String, _ successful: Bool, _ parameter: sessionParameterType, _ value: Int)->())?
	var lambdaResetSessionParamsComplete: ((_ id: String, _ successful: Bool)->())?
	var lambdaAcceptSessionParamsComplete: ((_ id: String, _ successful: Bool)->())?

	// MARK: Lambda Notifications
	var lambdaBatteryLevelUpdated: ((_ id: String, _ percentage: Int)->())?

	#if UNIVERSAL || ETHOS
	var lambdaPulseOxUpdated: ((_ id: String, _ spo2: Float, _ hr: Float)->())?
	#endif

	var lambdaPPGMetrics: ((_ id: String, _ successful: Bool, _ packet: String)->())?
	var lambdaPPGFailed: ((_ id: String, _ code: Int)->())?
	
	#if UNIVERSAL || ALTER || KAIROS || ETHOS
	var lambdaAirplaneModeComplete: ((_ id: String, _ successful: Bool)->())?
	var lambdaHeartRateUpdated: ((_ id: String, _ epoch: Int, _ hr: Int, _ rr: [Double])->())?
	var lambdaEndSleepStatus: ((_ id: String, _ hasSleep: Bool)->())?
	var lambdaButtonClicked: ((_ id: String, _ presses: Int)->())?
	var lambdaDataAvailable: ((_ id: String)->())?
	#endif

	var lambdaDataPackets: ((_ id: String, _ sequence_number: Int, _ packets: String)->())?
	var lambdaDataComplete: ((_ id: String, _ bad_fw_read_count: Int, _ bad_fw_parse_count: Int, _ overflow_count: Int, _ bad_sdk_parse_count: Int, _ intermediate: Bool)->())?
	var lambdaDataFailure: ((_ id: String)->())?
	var lambdaStreamingPacket: ((_ id: String, _ packet: String)->())?
	
	var lambdaWornStatus: ((_ id: String, _ isWorn: Bool)->())?
	var lambdaChargingStatus: ((_ id: String, _ charging: Bool, _ on_charger: Bool, _ error: Bool)->())?

	var lambdaUpdateFirmwareStarted: ((_ id: String)->())?
	var lambdaUpdateFirmwareFinished: ((_ id: String)->())?
	var lambdaUpdateFirmwareProgress: ((_ id: String, _ percentage: Float)->())?
	var lambdaUpdateFirmwareFailed: ((_ id: String, _ code: Int, _ message: String)->())?

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

	#if UNIVERSAL || ETHOS
	@Published public var medtorSoftwareRevision: String = "???"
	#endif

	#if UNIVERSAL || ALTER || KAIROS || ETHOS
	@Published public var sleepSoftwareRevision: String = "???"
	#endif

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

	#if UNIVERSAL || LIVOTAL
	internal var mNordicDFUCharacteristic		: nordicDFUCharacteristic?
	#endif

	#if UNIVERSAL || ETHOS
	internal var mPulseOxContinuousCharacteristic		: pulseOxContinuousCharacteristic?
	#endif
	
	#if UNIVERSAL || ETHOS || ALTER || KAIROS
	internal var mHeartRateMeasurementCharacteristic	: heartRateMeasurementCharacteristic?
	internal var mAmbiqOTARXCharacteristic				: ambiqOTARXCharacteristic?
	internal var mAmbiqOTATXCharacteristic				: ambiqOTATXCharacteristic?
	#endif
	
	class var manufacturer_prefixes: [String] {
		#if UNIVERSAL
		return [prefixes.livotal.rawValue, prefixes.ethos.rawValue, prefixes.alter.rawValue, prefixes.kairos.rawValue]
		#endif
		
		#if LIVOTAL
		return [prefixes.livotal.rawValue]
		#endif
		
		#if ETHOS
		return [prefixes.ethos.rawValue]
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
		return [services.livotal.UUID, services.nordicDFU.UUID, services.ethos.UUID, services.alter.UUID, services.kairos.UUID]
		#endif
		
		#if LIVOTAL
		return [services.livotal.UUID, services.nordicDFU.UUID]
		#endif
		
		#if ETHOS
		return [services.ethos.UUID]
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
		self.mState							= .disconnected
		
		self.name							= "UNKNOWN"
		self.id								= "UNKNOWN"
		self.epoch							= TimeInterval(0)
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

	var disconnected: Bool {
		get { return (mState == .disconnected) }
		set {
			if (newValue) {
				batteryValid	= false
				batteryLevel	= 0
				mState			= .disconnected
			}
		}
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

	#if UNIVERSAL || LIVOTAL
	private var mLivotalConfigured: Bool {
		if let nordicDFUCharacteristic = mNordicDFUCharacteristic, let mainCharacteristic = mMainCharacteristic, let batteryCharacteristic = mBatteryLevelCharacteristic {
						
			if let dataCharacteristic = mDataCharacteristic, let strmCharacteristic = mStreamingCharacteristic {
				//log?.v ("MN: \(modelNumber.configured), HV: \(hardwareRevision.configured), FV: \(firmwareVersion.configured), Name: \(manufacturerName.configured), SN: \(serialNumber.configured), LIV MAIN: \(mainCharacteristic.configured), LIV DATA: \(dataCharacteristic.configured), BAT: \(batteryCharacteristic.configured), DFU: \(dfuCharacteristic.configured)")
				
				return (mDISCharacteristicsDiscovered && mDISCharacteristicCount == 0 &&
						batteryCharacteristic.configured &&
						mainCharacteristic.configured &&
						dataCharacteristic.configured &&
						strmCharacteristic.configured &&
						nordicDFUCharacteristic.configured)
			}
			else {
				//log?.v ("MN: \(modelNumber.configured), HV: \(hardwareRevision.configured), FV: \(firmwareVersion.configured), Name: \(manufacturerName.configured), SN: \(serialNumber.configured), LIV: \(mainCharacteristic.configured), BAT: \(batteryCharacteristic.configured), DFU: \(dfuCharacteristic.configured)")

				return (mDISCharacteristicsDiscovered && mDISCharacteristicCount == 0 &&
						batteryCharacteristic.configured &&
						mainCharacteristic.configured &&
						nordicDFUCharacteristic.configured)
			}

		}
		else { return (false) }
	}
	#endif

	#if UNIVERSAL || ETHOS
	private var mEthosConfigured: Bool {
		if let firmwareVersion = mFirmwareVersion {
			if (firmwareVersion.lessThan("1.0.0")) {
				if let ambiqOTARXCharacteristic = mAmbiqOTARXCharacteristic, let ambiqOTATXCharacteristic = mAmbiqOTATXCharacteristic, let mainCharacteristic = mMainCharacteristic, let batteryCharacteristic = mBatteryLevelCharacteristic {
					
					//log?.v ("ETH: \(mainCharacteristic.configured), BAT: \(batteryCharacteristic.configured), OTARX: \(ambiqOTARXCharacteristic.configured), OTATX: \(ambiqOTATXCharacteristic.configured)")

					// Data characteristic doesn't exist for < 1.0.0
					return (mDISCharacteristicsDiscovered && mDISCharacteristicCount == 0 &&
							batteryCharacteristic.configured &&
							mainCharacteristic.configured &&
							ambiqOTARXCharacteristic.configured &&
							ambiqOTATXCharacteristic.configured
					)
				}
				else { return (false) }
			}
			else {
				if let ambiqOTARXCharacteristic = mAmbiqOTARXCharacteristic, let ambiqOTATXCharacteristic = mAmbiqOTATXCharacteristic, let mainCharacteristic = mMainCharacteristic, let batteryCharacteristic = mBatteryLevelCharacteristic, let heartRateMeasurementCharacteristic = mHeartRateMeasurementCharacteristic, let pulseOxContinuousCharacteristic = mPulseOxContinuousCharacteristic {
					
					if let dataCharacteristic = mDataCharacteristic, let strmCharacteristic = mStreamingCharacteristic {
						//log?.v ("ETH MAIN: \(mainCharacteristic.configured), ETH DATA: \(dataCharacteristic.configured), BAT: \(batteryCharacteristic.configured), HRM: \(heartRateMeasurementCharacteristic.configured), PULSOX: \(pulseOxContinuousCharacteristic.configured), OTARX: \(ambiqOTARXCharacteristic.configured), OTATX: \(ambiqOTATXCharacteristic.configured)")
						
						return (mDISCharacteristicsDiscovered && mDISCharacteristicCount == 0 &&
								batteryCharacteristic.configured &&
								mainCharacteristic.configured &&
								dataCharacteristic.configured &&
								strmCharacteristic.configured &&
								ambiqOTARXCharacteristic.configured &&
								ambiqOTATXCharacteristic.configured &&
								heartRateMeasurementCharacteristic.configured &&
								pulseOxContinuousCharacteristic.configured
						)
					}
					else {
						//log?.v ("ETH: \(mainCharacteristic.configured), BAT: \(batteryCharacteristic.configured), HRM: \(heartRateMeasurementCharacteristic.configured), PULSOX: \(pulseOxContinuousCharacteristic.configured), OTARX: \(ambiqOTARXCharacteristic.configured), OTATX: \(ambiqOTATXCharacteristic.configured)")
						
						return (mDISCharacteristicsDiscovered && mDISCharacteristicCount == 0 &&
								batteryCharacteristic.configured &&
								mainCharacteristic.configured &&
								ambiqOTARXCharacteristic.configured &&
								ambiqOTATXCharacteristic.configured &&
								heartRateMeasurementCharacteristic.configured &&
								pulseOxContinuousCharacteristic.configured
						)
					}
				}
				else { return (false) }
			}
		}
		else { return (false) }
	}
	#endif
	
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
		case .livotal	: return mLivotalConfigured
		case .ethos		: return mEthosConfigured
		case .alter		: return mAlterConfigured
		case .kairos	: return mKairosConfigured
		case .unknown	: return false
		}
		#endif
		
		#if LIVOTAL
		return mLivotalConfigured
		#endif
		
		#if ETHOS
		return mEthosConfigured
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
			DispatchQueue.main.async { self.writeEpochComplete.send(false) }
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
			DispatchQueue.main.async { self.readEpochComplete.send((false, 0)) }
		}
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func endSleep(_ id: String) {
		if let mainCharacteristic = mMainCharacteristic {
			mainCharacteristic.endSleep()
		}
		else { self.lambdaEndSleepComplete?(id, false) }
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	#if UNIVERSAL || ETHOS
	func debug(_ id: String, device: debugDevice, data: Data) {
		if let mainCharacteristic = mMainCharacteristic {
			mainCharacteristic.debug(device, data: data)
		}
		else { self.lambdaDebugComplete?(id, false, device, data) }
	}
	#endif

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func getAllPackets(_ id: String, pages: Int, delay: Int) {
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

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func getAllPacketsAcknowledge(_ id: String, ack: Bool) {
		if let mainCharacteristic = mMainCharacteristic {
			mainCharacteristic.getAllPacketsAcknowledge(ack)
		}
		else { self.lambdaGetAllPacketsAcknowledgeComplete?(id, false, ack) }
	}
	
	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func getNextPacket(_ id: String, single: Bool) {
		if let mainCharacteristic = mMainCharacteristic {
			mainCharacteristic.getNextPacket(single)
		}
		else { self.lambdaGetNextPacketComplete?(id, false, .missingDevice, true, "") }
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func getPacketCount(_ id: String) {
		if let mainCharacteristic = mMainCharacteristic {
			mainCharacteristic.getPacketCount()
		}
		else { self.lambdaGetPacketCountComplete?(id, false, 0) }
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func disableWornDetect(_ id: String) {
		if let mainCharacteristic = mMainCharacteristic {
			mainCharacteristic.disableWornDetect()
		}
		else { self.lambdaDisableWornDetectComplete?(id, false) }
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func enableWornDetect(_ id: String) {
		if let mainCharacteristic = mMainCharacteristic {
			mainCharacteristic.enableWornDetect()
		}
		else { self.lambdaEnableWornDetectComplete?(id, false) }
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
			DispatchQueue.main.async { self.startManualComplete.send(false) }
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
			DispatchQueue.main.async { self.stopManualComplete.send(false) }
		}
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	#if UNIVERSAL || LIVOTAL
	func livotalLEDInternal(red: Bool, green: Bool, blue: Bool, blink: Bool, seconds: Int) {
		if let mainCharacteristic = mMainCharacteristic {
			mainCharacteristic.livotalLED(red: red, green: green, blue: blue, blink: blink, seconds: seconds)
		}
		else { self.lambdaLEDComplete?(id, false) }
	}
	
	public func livotalLED(red: Bool, green: Bool, blue: Bool, blink: Bool, seconds: Int) {
		if let mainCharacteristic = mMainCharacteristic {
			mainCharacteristic.livotalLED(red: red, green: green, blue: blue, blink: blink, seconds: seconds)
		}
		else {
			DispatchQueue.main.async { self.ledComplete.send(false) }
		}
	}

	#endif

	#if UNIVERSAL || ETHOS
	func ethosLEDInternal(red: Int, green: Int, blue: Int, mode: biostrapDeviceSDK.ethosLEDMode, seconds: Int, percent: Int) {
		if let mainCharacteristic = mMainCharacteristic {
			mainCharacteristic.ethosLED(red: red, green: green, blue: blue, mode: mode, seconds: seconds, percent: percent)
		}
		else { self.lambdaLEDComplete?(id, false) }
	}
	
	public func ethosLED(red: Int, green: Int, blue: Int, mode: biostrapDeviceSDK.ethosLEDMode, seconds: Int, percent: Int) {
		if let mainCharacteristic = mMainCharacteristic {
			mainCharacteristic.ethosLED(red: red, green: green, blue: blue, mode: mode, seconds: seconds, percent: percent)
		}
		else {
			DispatchQueue.main.async { self.ledComplete.send(false) }
		}
	}

	#endif

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
			DispatchQueue.main.async { self.ledComplete.send(false) }
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
			DispatchQueue.main.async { self.ledComplete.send(false) }
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
	#if UNIVERSAL || ETHOS
	func motor(_ id: String, milliseconds: Int, pulses: Int) {
		if let mainCharacteristic = mMainCharacteristic {
			mainCharacteristic.motor(milliseconds: milliseconds, pulses: pulses)
		}
		else { self.lambdaMotorComplete?(id, false) }
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
		if let mainCharacteristic = mMainCharacteristic {
			mainCharacteristic.enterShipMode()
		}
		else { self.lambdaEnterShipModeComplete?(id, false) }
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
				self.writeSerialNumberComplete.send(false)
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
				self.readSerialNumberComplete.send((false, ""))
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
				self.deleteSerialNumberComplete.send(false)
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
				self.writeAdvIntervalComplete.send(false)
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
				self.readAdvIntervalComplete.send((false, 0))
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
				self.deleteAdvIntervalComplete.send(false)
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
				self.clearChargeCyclesComplete.send(false)
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
				self.readChargeCyclesComplete.send((false, 0.0))
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
	func readCanLogDiagnostics(_ id: String) {
		if let mainCharacteristic = mMainCharacteristic {
			mainCharacteristic.readCanLogDiagnostics()
		}
		else { self.lambdaReadCanLogDiagnosticsComplete?(id, false, false) }
	}
	
	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func updateCanLogDiagnostics(_ id: String, allow: Bool) {
		if let mainCharacteristic = mMainCharacteristic {
			mainCharacteristic.updateCanLogDiagnostics(allow)
		}
		else { self.lambdaUpdateCanLogDiagnosticsComplete?(id, false) }
	}
		
	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func allowPPG(_ id: String, allow: Bool) {
		if let mainCharacteristic = mMainCharacteristic {
			mainCharacteristic.allowPPG(allow)
		}
		else { self.lambdaAllowPPGComplete?(id, false) }
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	#if LIVOTAL || UNIVERSAL
	func livotalManufacturingTest(_ id: String) {
		if let mainCharacteristic = mMainCharacteristic {
			mainCharacteristic.livotalManufacturingTest()
		}
		else { self.lambdaManufacturingTestComplete?(id, false) }
	}
	#endif

	#if UNIVERSAL || ETHOS
	func ethosManufacturingTest(_ id: String, test: ethosManufacturingTestType) {
		if let mainCharacteristic = mMainCharacteristic {
			mainCharacteristic.ethosManufacturingTest(test)
		}
		else { self.lambdaManufacturingTestComplete?(id, false) }
	}
	#endif

	#if UNIVERSAL || ALTER
	func alterManufacturingTest(_ id: String, test: alterManufacturingTestType) {
		if let mainCharacteristic = mMainCharacteristic {
			mainCharacteristic.alterManufacturingTest(test)
		}
		else { self.lambdaManufacturingTestComplete?(id, false) }
	}
	#endif

	#if UNIVERSAL || KAIROS
	func kairosManufacturingTest(_ id: String, test: kairosManufacturingTestType) {
		if let mainCharacteristic = mMainCharacteristic {
			mainCharacteristic.kairosManufacturingTest(test)
		}
		else { self.lambdaManufacturingTestComplete?(id, false) }
	}
	#endif

	#if UNIVERSAL || ETHOS
	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func startLiveSync(_ id: String, configuration: liveSyncConfiguration) {
		if let mainCharacteristic = mMainCharacteristic {
			mainCharacteristic.startLiveSync(configuration)
		}
		else { self.lambdaStartLiveSyncComplete?(id, false) }
	}
	
	func stopLiveSync(_ id: String) {
		if let mainCharacteristic = mMainCharacteristic {
			mainCharacteristic.stopLiveSync()
		}
		else { self.lambdaStopLiveSyncComplete?(id, false) }
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
	func setAskForButtonResponseInternal(_ enable: Bool) {
		if let mainCharacteristic = mMainCharacteristic { mainCharacteristic.setAskForButtonResponse(enable) }
		else { self.lambdaSetAskForButtonResponseComplete?(self.id, false, enable) }
	}
	
	public func setAskForButtonResponse(_ enable: Bool) {
		if let mainCharacteristic = mMainCharacteristic { mainCharacteristic.setAskForButtonResponse(enable) }
		else {
			DispatchQueue.main.async {
				self.setAskForButtonResponseComplete.send((false, enable))
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
				self.getAskForButtonResponseComplete.send((false, false))
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
				self.setHRZoneColorComplete.send((false, type))
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
				self.getHRZoneColorComplete.send((false, type))
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
				self.setHRZoneRangeComplete.send(false)
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
				self.getHRZoneRangeComplete.send(false)
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
	#endif

	#if UNIVERSAL || ALTER || KAIROS || ETHOS
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
				self.setAdvertiseAsHRMComplete.send((false, false))
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
				self.getAdvertiseAsHRMComplete.send((false, false))
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
				self.setButtonCommandComplete.send((false, tap, command))
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
				self.getButtonCommandComplete.send((false, tap, .unknown))
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
	func setPaired() {
		if let mainCharacteristic = mMainCharacteristic { mainCharacteristic.setPaired() }
		else { self.lambdaSetPairedComplete?(self.id, false) }
	}

	//--------------------------------------------------------------------------------
	// Function Name: setUnpaired
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func setUnpaired() {
		if let mainCharacteristic = mMainCharacteristic { mainCharacteristic.setUnpaired() }
		else { self.lambdaSetUnpairedComplete?(self.id, false) }
	}
	
	//--------------------------------------------------------------------------------
	// Function Name: getPaired
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func getPaired() {
		if let mainCharacteristic = mMainCharacteristic { mainCharacteristic.getPaired() }
		else { self.lambdaGetPairedComplete?(self.id, false, false) }
	}
	
	//--------------------------------------------------------------------------------
	// Function Name: setPaired
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func setPageThreshold(_ threshold: Int) {
		if let mainCharacteristic = mMainCharacteristic { mainCharacteristic.setPageThreshold(threshold) }
		else { self.lambdaSetPageThresholdComplete?(self.id, false) }
	}
	
	//--------------------------------------------------------------------------------
	// Function Name: setUnpaired
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func getPageThreshold() {
		if let mainCharacteristic = mMainCharacteristic { mainCharacteristic.getPageThreshold() }
		else { self.lambdaGetPageThresholdComplete?(self.id, false, 1) }
	}
	
	//--------------------------------------------------------------------------------
	// Function Name: getPaired
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func deletePageThreshold() {
		if let mainCharacteristic = mMainCharacteristic { mainCharacteristic.deletePageThreshold() }
		else { self.lambdaDeletePageThresholdComplete?(self.id, false) }
	}
	#endif

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func recalibratePPG(_ id: String) {
		if let mainCharacteristic = mMainCharacteristic {
			mainCharacteristic.recalibratePPG()
		}
		else { self.lambdaRecalibratePPGComplete?(id, false) }
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func wornCheck(_ id: String) {
		if let mainCharacteristic = mMainCharacteristic {
			mainCharacteristic.wornCheck()
		}
		else { self.lambdaWornCheckComplete?(id, false, "Missing Characteristic", 0) }
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func rawLogging(_ id: String, enable: Bool) {
		if let mainCharacteristic = mMainCharacteristic {
			mainCharacteristic.rawLogging(enable)
		}
		else { self.lambdaRawLoggingComplete?(id, false) }
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
				self.getRawLoggingStatusComplete.send((false, false))
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
				self.getWornOverrideStatusComplete.send((false, false))
			}
		}
	}
	
	#if UNIVERSAL || ALTER || KAIROS || ETHOS
	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func airplaneMode(_ id: String) {
		if let mainCharacteristic = mMainCharacteristic {
			mainCharacteristic.airplaneMode()
		}
		else { self.lambdaAirplaneModeComplete?(id, false) }
	}
	#endif

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func reset(_ id: String) {
		if let mainCharacteristic = mMainCharacteristic {
			mainCharacteristic.reset()
		}
		else { self.lambdaResetComplete?(id, false) }
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
			else { lambdaUpdateFirmwareFailed?(self.id, 10001, "No DFU characteristic to update") }
		case .ethos,
			 .alter,
			 .kairos:
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
		default: lambdaUpdateFirmwareFailed?(self.id, 10001, "Do not understand type to update: \(type.title)")
		}
		#endif
		
		#if LIVOTAL
		if let nordicDFUCharacteristic = mNordicDFUCharacteristic { nordicDFUCharacteristic.start(file) }
		else { lambdaUpdateFirmwareFailed?(self.id, 10001, "No DFU characteristic to update") }
		#endif
		
		#if ETHOS || ALTER || KAIROS
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
		#if LIVOTAL
		if let nordicDFUCharacteristic = mNordicDFUCharacteristic { nordicDFUCharacteristic.cancel() }
		else { lambdaUpdateFirmwareFailed?(self.id, 10001, "No characteristic to cancel") }
		#endif

		#if ETHOS || ALTER || KAIROS
		if let ambiqOTARXCharacteristic = mAmbiqOTARXCharacteristic { ambiqOTARXCharacteristic.cancel() }
		else { lambdaUpdateFirmwareFailed?(self.id, 10001, "No characteristic to cancel") }
		#endif
		
		#if UNIVERSAL
		switch (type) {
		case .livotal:
			if let nordicDFUCharacteristic = mNordicDFUCharacteristic { nordicDFUCharacteristic.cancel() }
			else { lambdaUpdateFirmwareFailed?(self.id, 10001, "No characteristic to cancel") }
		case .alter, .ethos:
			if let ambiqOTARXCharacteristic = mAmbiqOTARXCharacteristic { ambiqOTARXCharacteristic.cancel() }
			else { lambdaUpdateFirmwareFailed?(self.id, 10001, "No characteristic to cancel") }
		default:
			log?.e ("Do now know device type")
			lambdaUpdateFirmwareFailed?(self.id, 10001, "Do not know device type: \(type.title)")
		}
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

		if let mainCharacteristic = mMainCharacteristic {
			mainCharacteristic.setSessionParam(parameter, value: value)
		}
		else { self.lambdaSetSessionParamComplete?(self.id, false, parameter) }

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

		if let mainCharacteristic = mMainCharacteristic {
			mainCharacteristic.getSessionParam(parameter)
		}
		else { self.lambdaGetSessionParamComplete?(self.id, false, parameter, 0) }
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

		if let mainCharacteristic = mMainCharacteristic {
			mainCharacteristic.resetSessionParams()
		}
		else { self.lambdaResetSessionParamsComplete?(self.id, false) }
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

		if let mainCharacteristic = mMainCharacteristic {
			mainCharacteristic.acceptSessionParams()
		}
		else { self.lambdaAcceptSessionParamsComplete?(self.id, false) }
	}
	
	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	private func attachMainCharacteristicCallbacks() {
		mMainCharacteristic?.writeEpochComplete = { successful in
			self.lambdaWriteEpochComplete?(self.id, successful)
			DispatchQueue.main.async { self.writeEpochComplete.send(successful) }
		}
		
		mMainCharacteristic?.readEpochComplete = { successful, value in
			self.lambdaReadEpochComplete?(self.id, successful,  value)
			DispatchQueue.main.async { self.readEpochComplete.send((successful, value)) }
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
			DispatchQueue.main.async { self.startManualComplete.send(successful) }
		}
		
		mMainCharacteristic?.stopManualComplete = { successful in
			self.lambdaStopManualComplete?(self.id, successful)
			DispatchQueue.main.async { self.stopManualComplete.send(successful) }
		}
		
		mMainCharacteristic?.ledComplete = { successful in
			self.lambdaLEDComplete?(self.id, successful)
			DispatchQueue.main.async { self.ledComplete.send(successful) }
		}
		
		mMainCharacteristic?.getRawLoggingStatusComplete = { successful, enabled in
			self.lambdaGetRawLoggingStatusComplete?(self.id, successful, enabled)
			DispatchQueue.main.async {
				self.getRawLoggingStatusComplete.send((successful, enabled))
			}
		}
		
		mMainCharacteristic?.getWornOverrideStatusComplete = { successful, overridden in
			self.lambdaGetWornOverrideStatusComplete?(self.id, successful, overridden)
			DispatchQueue.main.async {
				self.getWornOverrideStatusComplete.send((successful, overridden))
			}
		}
		
		mMainCharacteristic?.writeSerialNumberComplete = { successful in
			self.lamdaWriteSerialNumberComplete?(self.id, successful)
			DispatchQueue.main.async {
				self.writeSerialNumberComplete.send(successful)
			}
		}

		mMainCharacteristic?.readSerialNumberComplete = { successful, partID in
			self.lambdaReadSerialNumberComplete?(self.id, successful, partID)
			DispatchQueue.main.async {
				self.readSerialNumberComplete.send((successful, partID))
			}
		}
		
		mMainCharacteristic?.deleteSerialNumberComplete = { successful in
			self.lambdaDeleteSerialNumberComplete?(self.id, successful)
			DispatchQueue.main.async {
				self.deleteSerialNumberComplete.send(successful)
			}
		}
		
		mMainCharacteristic?.writeAdvIntervalComplete = { successful in
			self.lambdaWriteAdvIntervalComplete?(self.id, successful)
			DispatchQueue.main.async {
				self.writeAdvIntervalComplete.send(successful)
			}
		}
		
		mMainCharacteristic?.readAdvIntervalComplete = { successful, seconds in
			self.lambdaReadAdvIntervalComplete?(self.id, successful, seconds)
			DispatchQueue.main.async {
				self.readAdvIntervalComplete.send((successful, seconds))
			}
		}
		
		mMainCharacteristic?.deleteAdvIntervalComplete = { successful in
			self.lambdaDeleteAdvIntervalComplete?(self.id, successful)
			DispatchQueue.main.async {
				self.deleteAdvIntervalComplete.send(successful)
			}
		}
		
		mMainCharacteristic?.clearChargeCyclesComplete = { successful in
			self.lambdaClearChargeCyclesComplete?(self.id, successful)
			DispatchQueue.main.async {
				self.clearChargeCyclesComplete.send(successful)
			}
		}
		
		mMainCharacteristic?.readChargeCyclesComplete = { successful, cycles in
			self.lambdaReadChargeCyclesComplete?(self.id, successful, cycles)
			DispatchQueue.main.async {
				self.readChargeCyclesComplete.send((successful, cycles))
			}
		}

		#if UNIVERSAL || ALTER || KAIROS || ETHOS
		mMainCharacteristic?.setAdvertiseAsHRMComplete	= { successful, asHRM in
			self.lambdaSetAdvertiseAsHRMComplete?(self.id, successful, asHRM)
			DispatchQueue.main.async {
				self.setAdvertiseAsHRMComplete.send((successful, asHRM))
			}
		}
		mMainCharacteristic?.getAdvertiseAsHRMComplete	= { successful, asHRM in
			self.lambdaGetAdvertiseAsHRMComplete?(self.id, successful, asHRM)
			DispatchQueue.main.async {
				self.getAdvertiseAsHRMComplete.send((successful, asHRM))
			}
		}
		mMainCharacteristic?.setButtonCommandComplete	= { successful, tap, command in
			self.lambdaSetButtonCommandComplete?(self.id, successful, tap, command)
			DispatchQueue.main.async {
				self.setButtonCommandComplete.send((successful, tap, command))
			}
		}
		mMainCharacteristic?.getButtonCommandComplete	= { successful, tap, command in
			self.lambdaGetButtonCommandComplete?(self.id, successful, tap, command)
			DispatchQueue.main.async {
				self.getButtonCommandComplete.send((successful, tap, command))
			}
		}
		
		mMainCharacteristic?.setAskForButtonResponseComplete = { successful, enable in
			self.lambdaSetAskForButtonResponseComplete?(self.id, successful, enable)
			DispatchQueue.main.async {
				self.setAskForButtonResponseComplete.send((successful, enable))
			}
		}
		
		mMainCharacteristic?.getAskForButtonResponseComplete = { successful, enable in
			self.lambdaGetAskForButtonResponseComplete?(self.id, successful, enable)
			DispatchQueue.main.async {
				self.getAskForButtonResponseComplete.send((successful, enable))
			}
		}
		
		mMainCharacteristic?.recalibratePPGComplete		= { successful in
			self.lambdaRecalibratePPGComplete?(self.id, successful)
			DispatchQueue.main.async {
				
			}
		}
		
		mMainCharacteristic?.setHRZoneColorComplete		= { successful, type in
			self.lambdaSetHRZoneColorComplete?(self.id, successful, type)
			DispatchQueue.main.async {
				self.setHRZoneColorComplete.send((successful, type))
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
				self.getHRZoneColorComplete.send((successful, type))
			}
		}
		
		mMainCharacteristic?.setHRZoneRangeComplete		= { successful in
			self.lambdaSetHRZoneRangeComplete?(self.id, successful)
			DispatchQueue.main.async {
				self.setHRZoneRangeComplete.send(successful)
			}
		}
		
		mMainCharacteristic?.getHRZoneRangeComplete		= { successful, enabled, high_value, low_value in
			self.lambdaGetHRZoneRangeComplete?(self.id, successful, enabled, high_value, low_value)
			DispatchQueue.main.async {
				if successful {
					log?.v ("\(self.id): getHRZoneRangeComplete - Successful: \(enabled) \(high_value), \(low_value)")
					self.hrZoneRange = hrZoneRangeValueType(enabled: enabled, lower: low_value, upper: high_value)
				}
				self.getHRZoneRangeComplete.send(successful)
			}
		}
		
		mMainCharacteristic?.getPPGAlgorithmComplete	= { successful, algorithm, state in
			self.lambdaGetPPGAlgorithmComplete?(self.id, successful, algorithm, state)
			DispatchQueue.main.async {
				self.getPPGAlgorithmComplete.send((successful, algorithm, state))
			}
		}
		#endif
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	private func attachStreamingCharacteristicCallbacks() {
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
				#if UNIVERSAL || ETHOS
				case .plx_continuous_measurement:
					log?.v ("\(self.id) '\(testCharacteristic.title)' - and enable notifications")
					mPulseOxContinuousCharacteristic = pulseOxContinuousCharacteristic(peripheral, characteristic: characteristic)
					mPulseOxContinuousCharacteristic?.updated	= { id, spo2, hr in self.lambdaPulseOxUpdated?(id, spo2, hr) }
					mPulseOxContinuousCharacteristic?.discoverDescriptors()
				#endif
				#if UNIVERSAL || ETHOS || ALTER || KAIROS
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
				#endif
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
				case .ethosMainCharacteristic:
					mMainCharacteristic	= customMainCharacteristic(peripheral, characteristic: characteristic)
					#if UNIVERSAL
					mMainCharacteristic?.type	= .ethos
					#endif
					attachMainCharacteristicCallbacks()
					mMainCharacteristic?.motorComplete = { successful in self.lambdaMotorComplete?(self.id, successful) }
					mMainCharacteristic?.enterShipModeComplete = { successful in self.lambdaEnterShipModeComplete?(self.id, successful) }
					mMainCharacteristic?.readCanLogDiagnosticsComplete = { successful, allow in self.lambdaReadCanLogDiagnosticsComplete?(self.id, successful, allow) }
					mMainCharacteristic?.updateCanLogDiagnosticsComplete = { successful in self.lambdaUpdateCanLogDiagnosticsComplete?(self.id, successful) }
					mMainCharacteristic?.rawLoggingComplete = { successful in self.lambdaRawLoggingComplete?(self.id, successful) }
					mMainCharacteristic?.allowPPGComplete = { successful in self.lambdaAllowPPGComplete?(self.id, successful)}
					mMainCharacteristic?.wornCheckComplete = { successful, code, value in self.lambdaWornCheckComplete?(self.id, successful, code, value )}
					mMainCharacteristic?.resetComplete = { successful in self.lambdaResetComplete?(self.id, successful) }
					mMainCharacteristic?.ppgMetrics = { successful, packet in self.lambdaPPGMetrics?(self.id, successful, packet) }
					mMainCharacteristic?.ppgFailed = { code in self.lambdaPPGFailed?(self.id, code) }
					mMainCharacteristic?.endSleepComplete = { successful in self.lambdaEndSleepComplete?(self.id, successful) }
					mMainCharacteristic?.debugComplete = { successful, device, data in self.lambdaDebugComplete?(self.id, successful, device, data) }
					mMainCharacteristic?.getAllPacketsComplete = { successful in self.lambdaGetAllPacketsComplete?(self.id, successful) }
					mMainCharacteristic?.getAllPacketsAcknowledgeComplete = { successful, ack in self.lambdaGetAllPacketsAcknowledgeComplete?(self.id, successful, ack) }
					mMainCharacteristic?.getNextPacketComplete = { successful, error_code, caughtUp, packet in self.lambdaGetNextPacketComplete?(self.id, successful, error_code, caughtUp, packet) }
					mMainCharacteristic?.getPacketCountComplete = { successful, count in self.lambdaGetPacketCountComplete?(self.id, successful, count) }
					mMainCharacteristic?.disableWornDetectComplete = { successful in self.lambdaDisableWornDetectComplete?(self.id, successful) }
					mMainCharacteristic?.enableWornDetectComplete = { successful in self.lambdaEnableWornDetectComplete?(self.id, successful) }
					mMainCharacteristic?.dataPackets = { packets in self.lambdaDataPackets?(self.id, -1, packets) }
					mMainCharacteristic?.dataComplete = { bad_fw_read_count, bad_fw_parse_count, overflow_count, bad_sdk_parse_count in self.lambdaDataComplete?(self.id, bad_fw_read_count, bad_fw_parse_count, overflow_count, bad_sdk_parse_count, false) }
					mMainCharacteristic?.dataFailure = { self.lambdaDataFailure?(self.id) }
					mMainCharacteristic?.endSleepStatus = { enable in self.lambdaEndSleepStatus?(self.id, enable) }
					mMainCharacteristic?.buttonClicked = { presses in self.lambdaButtonClicked?(self.id, presses) }
					mMainCharacteristic?.setSessionParamComplete = { successful, parameter in self.lambdaSetSessionParamComplete?(self.id, successful, parameter) }
					mMainCharacteristic?.getSessionParamComplete = { successful, parameter, value in self.lambdaGetSessionParamComplete?(self.id, successful, parameter, value) }
					mMainCharacteristic?.acceptSessionParamsComplete	= { successful in self.lambdaAcceptSessionParamsComplete?(self.id, successful) }
					mMainCharacteristic?.resetSessionParamsComplete	= { successful in self.lambdaResetSessionParamsComplete?(self.id, successful) }
					mMainCharacteristic?.manufacturingTestComplete	= { successful in self.lambdaManufacturingTestComplete?(self.id, successful) }
					mMainCharacteristic?.manufacturingTestResult		= { valid, result in self.lambdaManufacturingTestResult?(self.id, valid, result) }
					mMainCharacteristic?.startLiveSyncComplete		= { successful in self.lambdaStartLiveSyncComplete?(self.id, successful) }
					mMainCharacteristic?.stopLiveSyncComplete			= { successful in self.lambdaStopLiveSyncComplete?(self.id, successful) }
					mMainCharacteristic?.recalibratePPGComplete		= { successful in self.lambdaRecalibratePPGComplete?(self.id, successful) }
					mMainCharacteristic?.setPairedComplete			= { successful in self.lambdaSetPairedComplete?(self.id, successful) }
					mMainCharacteristic?.setUnpairedComplete		= { successful in self.lambdaSetUnpairedComplete?(self.id, successful) }
					mMainCharacteristic?.getPairedComplete			= { successful, paired in self.lambdaGetPairedComplete?(self.id, successful, paired) }
					mMainCharacteristic?.setPageThresholdComplete	= { successful in self.lambdaSetPageThresholdComplete?(self.id, successful) }
					mMainCharacteristic?.getPageThresholdComplete	= { successful, threshold in self.lambdaGetPageThresholdComplete?(self.id, successful, threshold) }
					mMainCharacteristic?.deletePageThresholdComplete	= { successful in self.lambdaDeletePageThresholdComplete?(self.id, successful) }
					mMainCharacteristic?.airplaneModeComplete		= { successful in self.lambdaAirplaneModeComplete?(self.id, successful) }

					mMainCharacteristic?.discoverDescriptors()
					
				case .ethosDataCharacteristic:
					mDataCharacteristic = customDataCharacteristic(peripheral, characteristic: characteristic)
					mDataCharacteristic?.dataPackets = { sequence_number, packets in self.lambdaDataPackets?(self.id, sequence_number, packets) }
					mDataCharacteristic?.dataComplete = { bad_fw_read_count, bad_fw_parse_count, overflow_count, bad_sdk_parse_count, intermediate in self.lambdaDataComplete?(self.id, bad_fw_read_count, bad_fw_parse_count, overflow_count, bad_sdk_parse_count, intermediate) }
					mDataCharacteristic?.discoverDescriptors()
					
				case .ethosStrmCharacteristic:
					mStreamingCharacteristic = customStreamingCharacteristic(peripheral, characteristic: characteristic)
					#if UNIVERSAL
					mStreamingCharacteristic?.type	= .ethos
					#endif
					attachStreamingCharacteristicCallbacks()
					mStreamingCharacteristic?.ppgMetrics = { successful, packet in self.lambdaPPGMetrics?(self.id, successful, packet) }
					mStreamingCharacteristic?.ppgFailed = { code in self.lambdaPPGFailed?(self.id, code) }
					mStreamingCharacteristic?.manufacturingTestResult	= { valid, result in self.lambdaManufacturingTestResult?(self.id, valid, result)}
					mStreamingCharacteristic?.endSleepStatus = { enable in self.lambdaEndSleepStatus?(self.id, enable) }
					mStreamingCharacteristic?.buttonClicked = { presses in self.lambdaButtonClicked?(self.id, presses) }
					mStreamingCharacteristic?.streamingPacket = { packet in self.lambdaStreamingPacket?(self.id, packet) }
					mStreamingCharacteristic?.dataAvailable = { self.lambdaDataAvailable?(self.id) }

					mStreamingCharacteristic?.discoverDescriptors()
					
				#endif

				#if UNIVERSAL || ALTER
				case .alterMainCharacteristic:
					mMainCharacteristic	= customMainCharacteristic(peripheral, characteristic: characteristic)
					#if UNIVERSAL
					mMainCharacteristic?.type	= .alter
					#endif
					attachMainCharacteristicCallbacks()
					mMainCharacteristic?.enterShipModeComplete = { successful in self.lambdaEnterShipModeComplete?(self.id, successful) }
					mMainCharacteristic?.readCanLogDiagnosticsComplete = { successful, allow in self.lambdaReadCanLogDiagnosticsComplete?(self.id, successful, allow) }
					mMainCharacteristic?.updateCanLogDiagnosticsComplete = { successful in self.lambdaUpdateCanLogDiagnosticsComplete?(self.id, successful) }
					mMainCharacteristic?.rawLoggingComplete = { successful in self.lambdaRawLoggingComplete?(self.id, successful) }
					mMainCharacteristic?.allowPPGComplete = { successful in self.lambdaAllowPPGComplete?(self.id, successful)}
					mMainCharacteristic?.wornCheckComplete = { successful, code, value in self.lambdaWornCheckComplete?(self.id, successful, code, value )}
					mMainCharacteristic?.resetComplete = { successful in self.lambdaResetComplete?(self.id, successful) }
					mMainCharacteristic?.ppgMetrics = { successful, packet in self.lambdaPPGMetrics?(self.id, successful, packet) }
					mMainCharacteristic?.ppgFailed = { code in self.lambdaPPGFailed?(self.id, code) }
					mMainCharacteristic?.endSleepComplete = { successful in self.lambdaEndSleepComplete?(self.id, successful) }
					mMainCharacteristic?.getAllPacketsComplete = { successful in self.lambdaGetAllPacketsComplete?(self.id, successful) }
					mMainCharacteristic?.getAllPacketsAcknowledgeComplete = { successful, ack in self.lambdaGetAllPacketsAcknowledgeComplete?(self.id, successful, ack) }
					mMainCharacteristic?.getNextPacketComplete = { successful, error_code, caughtUp, packet in self.lambdaGetNextPacketComplete?(self.id, successful, error_code, caughtUp, packet) }
					mMainCharacteristic?.getPacketCountComplete = { successful, count in self.lambdaGetPacketCountComplete?(self.id, successful, count) }
					mMainCharacteristic?.disableWornDetectComplete = { successful in self.lambdaDisableWornDetectComplete?(self.id, successful) }
					mMainCharacteristic?.enableWornDetectComplete = { successful in self.lambdaEnableWornDetectComplete?(self.id, successful) }
					mMainCharacteristic?.dataPackets = { packets in self.lambdaDataPackets?(self.id, -1, packets) }
					mMainCharacteristic?.dataComplete = { bad_fw_read_count, bad_fw_parse_count, overflow_count, bad_sdk_parse_count in self.lambdaDataComplete?(self.id, bad_fw_read_count, bad_fw_parse_count, overflow_count, bad_sdk_parse_count, false) }
					mMainCharacteristic?.dataFailure = { self.lambdaDataFailure?(self.id) }
					mMainCharacteristic?.endSleepStatus = { enable in self.lambdaEndSleepStatus?(self.id, enable) }
					mMainCharacteristic?.buttonClicked = { presses in self.lambdaButtonClicked?(self.id, presses) }
					mMainCharacteristic?.setSessionParamComplete = { successful, parameter in self.lambdaSetSessionParamComplete?(self.id, successful, parameter) }
					mMainCharacteristic?.getSessionParamComplete = { successful, parameter, value in self.lambdaGetSessionParamComplete?(self.id, successful, parameter, value) }
					mMainCharacteristic?.acceptSessionParamsComplete	= { successful in self.lambdaAcceptSessionParamsComplete?(self.id, successful) }
					mMainCharacteristic?.resetSessionParamsComplete	= { successful in self.lambdaResetSessionParamsComplete?(self.id, successful) }
					mMainCharacteristic?.manufacturingTestComplete	= { successful in self.lambdaManufacturingTestComplete?(self.id, successful) }
					mMainCharacteristic?.manufacturingTestResult	= { valid, result in self.lambdaManufacturingTestResult?(self.id, valid, result) }
					mMainCharacteristic?.recalibratePPGComplete		= { successful in self.lambdaRecalibratePPGComplete?(self.id, successful) }
					mMainCharacteristic?.setPairedComplete			= { successful in self.lambdaSetPairedComplete?(self.id, successful) }
					mMainCharacteristic?.setUnpairedComplete		= { successful in self.lambdaSetUnpairedComplete?(self.id, successful) }
					mMainCharacteristic?.getPairedComplete			= { successful, paired in self.lambdaGetPairedComplete?(self.id, successful, paired) }
					mMainCharacteristic?.setPageThresholdComplete	= { successful in self.lambdaSetPageThresholdComplete?(self.id, successful) }
					mMainCharacteristic?.getPageThresholdComplete	= { successful, threshold in self.lambdaGetPageThresholdComplete?(self.id, successful, threshold) }
					mMainCharacteristic?.deletePageThresholdComplete	= { successful in self.lambdaDeletePageThresholdComplete?(self.id, successful) }
					mMainCharacteristic?.airplaneModeComplete		= { successful in self.lambdaAirplaneModeComplete?(self.id, successful) }

					mMainCharacteristic?.discoverDescriptors()
					
				case .alterDataCharacteristic:
					mDataCharacteristic = customDataCharacteristic(peripheral, characteristic: characteristic)
					mDataCharacteristic?.dataPackets = { sequence_number, packets in self.lambdaDataPackets?(self.id, sequence_number, packets) }
					mDataCharacteristic?.dataComplete = { bad_fw_read_count, bad_fw_parse_count, overflow_count, bad_sdk_parse_count, intermediate in self.lambdaDataComplete?(self.id, bad_fw_read_count, bad_fw_parse_count, overflow_count, bad_sdk_parse_count, intermediate) }
					mDataCharacteristic?.discoverDescriptors()
					
				case .alterStrmCharacteristic:
					mStreamingCharacteristic = customStreamingCharacteristic(peripheral, characteristic: characteristic)
					#if UNIVERSAL
					mStreamingCharacteristic?.type	= .alter
					#endif
					attachStreamingCharacteristicCallbacks()
					mStreamingCharacteristic?.ppgMetrics = { successful, packet in self.lambdaPPGMetrics?(self.id, successful, packet) }
					mStreamingCharacteristic?.ppgFailed = { code in self.lambdaPPGFailed?(self.id, code) }
					mStreamingCharacteristic?.manufacturingTestResult	= { valid, result in self.lambdaManufacturingTestResult?(self.id, valid, result)}
					mStreamingCharacteristic?.endSleepStatus = { enable in self.lambdaEndSleepStatus?(self.id, enable) }
					mStreamingCharacteristic?.buttonClicked = { presses in self.lambdaButtonClicked?(self.id, presses) }
					mStreamingCharacteristic?.streamingPacket = { packet in self.lambdaStreamingPacket?(self.id, packet) }
					mStreamingCharacteristic?.dataAvailable = { self.lambdaDataAvailable?(self.id) }

					mStreamingCharacteristic?.discoverDescriptors()

				#endif

				#if UNIVERSAL || KAIROS
				case .kairosMainCharacteristic:
					mMainCharacteristic	= customMainCharacteristic(peripheral, characteristic: characteristic)
					#if UNIVERSAL
					mMainCharacteristic?.type	= .kairos
					#endif
					attachMainCharacteristicCallbacks()
					mMainCharacteristic?.enterShipModeComplete = { successful in self.lambdaEnterShipModeComplete?(self.id, successful) }
					mMainCharacteristic?.readCanLogDiagnosticsComplete = { successful, allow in self.lambdaReadCanLogDiagnosticsComplete?(self.id, successful, allow) }
					mMainCharacteristic?.updateCanLogDiagnosticsComplete = { successful in self.lambdaUpdateCanLogDiagnosticsComplete?(self.id, successful) }
					mMainCharacteristic?.rawLoggingComplete = { successful in self.lambdaRawLoggingComplete?(self.id, successful) }
					mMainCharacteristic?.allowPPGComplete = { successful in self.lambdaAllowPPGComplete?(self.id, successful)}
					mMainCharacteristic?.wornCheckComplete = { successful, code, value in self.lambdaWornCheckComplete?(self.id, successful, code, value )}
					mMainCharacteristic?.resetComplete = { successful in self.lambdaResetComplete?(self.id, successful) }
					mMainCharacteristic?.ppgMetrics = { successful, packet in self.lambdaPPGMetrics?(self.id, successful, packet) }
					mMainCharacteristic?.ppgFailed = { code in self.lambdaPPGFailed?(self.id, code) }
					mMainCharacteristic?.endSleepComplete = { successful in self.lambdaEndSleepComplete?(self.id, successful) }
					mMainCharacteristic?.getAllPacketsComplete = { successful in self.lambdaGetAllPacketsComplete?(self.id, successful) }
					mMainCharacteristic?.getAllPacketsAcknowledgeComplete = { successful, ack in self.lambdaGetAllPacketsAcknowledgeComplete?(self.id, successful, ack) }
					mMainCharacteristic?.getNextPacketComplete = { successful, error_code, caughtUp, packet in self.lambdaGetNextPacketComplete?(self.id, successful, error_code, caughtUp, packet) }
					mMainCharacteristic?.getPacketCountComplete = { successful, count in self.lambdaGetPacketCountComplete?(self.id, successful, count) }
					mMainCharacteristic?.disableWornDetectComplete = { successful in self.lambdaDisableWornDetectComplete?(self.id, successful) }
					mMainCharacteristic?.enableWornDetectComplete = { successful in self.lambdaEnableWornDetectComplete?(self.id, successful) }
					mMainCharacteristic?.dataPackets = { packets in self.lambdaDataPackets?(self.id, -1, packets) }
					mMainCharacteristic?.dataComplete = { bad_fw_read_count, bad_fw_parse_count, overflow_count, bad_sdk_parse_count in self.lambdaDataComplete?(self.id, bad_fw_read_count, bad_fw_parse_count, overflow_count, bad_sdk_parse_count, false) }
					mMainCharacteristic?.dataFailure = { self.lambdaDataFailure?(self.id) }
					mMainCharacteristic?.endSleepStatus = { enable in self.lambdaEndSleepStatus?(self.id, enable) }
					mMainCharacteristic?.buttonClicked = { presses in self.lambdaButtonClicked?(self.id, presses) }
					mMainCharacteristic?.setSessionParamComplete = { successful, parameter in self.lambdaSetSessionParamComplete?(self.id, successful, parameter) }
					mMainCharacteristic?.getSessionParamComplete = { successful, parameter, value in self.lambdaGetSessionParamComplete?(self.id, successful, parameter, value) }
					mMainCharacteristic?.acceptSessionParamsComplete	= { successful in self.lambdaAcceptSessionParamsComplete?(self.id, successful) }
					mMainCharacteristic?.resetSessionParamsComplete	= { successful in self.lambdaResetSessionParamsComplete?(self.id, successful) }
					mMainCharacteristic?.manufacturingTestComplete	= { successful in self.lambdaManufacturingTestComplete?(self.id, successful) }
					mMainCharacteristic?.manufacturingTestResult	= { valid, result in self.lambdaManufacturingTestResult?(self.id, valid, result) }
					mMainCharacteristic?.setPairedComplete			= { successful in self.lambdaSetPairedComplete?(self.id, successful) }
					mMainCharacteristic?.setUnpairedComplete		= { successful in self.lambdaSetUnpairedComplete?(self.id, successful) }
					mMainCharacteristic?.getPairedComplete			= { successful, paired in self.lambdaGetPairedComplete?(self.id, successful, paired) }
					mMainCharacteristic?.setPageThresholdComplete	= { successful in self.lambdaSetPageThresholdComplete?(self.id, successful) }
					mMainCharacteristic?.getPageThresholdComplete	= { successful, threshold in self.lambdaGetPageThresholdComplete?(self.id, successful, threshold) }
					mMainCharacteristic?.deletePageThresholdComplete	= { successful in self.lambdaDeletePageThresholdComplete?(self.id, successful) }
					mMainCharacteristic?.airplaneModeComplete		= { successful in self.lambdaAirplaneModeComplete?(self.id, successful) }

					mMainCharacteristic?.discoverDescriptors()

				case .kairosDataCharacteristic:
					mDataCharacteristic = customDataCharacteristic(peripheral, characteristic: characteristic)
					mDataCharacteristic?.dataPackets = { sequence_number, packets in self.lambdaDataPackets?(self.id, sequence_number, packets) }
					mDataCharacteristic?.dataComplete = { bad_fw_read_count, bad_fw_parse_count, overflow_count, bad_sdk_parse_count, intermediate in self.lambdaDataComplete?(self.id, bad_fw_read_count, bad_fw_parse_count, overflow_count, bad_sdk_parse_count, intermediate) }
					mDataCharacteristic?.discoverDescriptors()
					
				case .kairosStrmCharacteristic:
					mStreamingCharacteristic = customStreamingCharacteristic(peripheral, characteristic: characteristic)
					#if UNIVERSAL
					mStreamingCharacteristic?.type	= .kairos
					#endif
					attachStreamingCharacteristicCallbacks()
					mStreamingCharacteristic?.ppgMetrics = { successful, packet in self.lambdaPPGMetrics?(self.id, successful, packet) }
					mStreamingCharacteristic?.ppgFailed = { code in self.lambdaPPGFailed?(self.id, code) }
					mStreamingCharacteristic?.manufacturingTestResult	= { valid, result in self.lambdaManufacturingTestResult?(self.id, valid, result)}
					mStreamingCharacteristic?.endSleepStatus = { enable in self.lambdaEndSleepStatus?(self.id, enable) }
					mStreamingCharacteristic?.buttonClicked = { presses in self.lambdaButtonClicked?(self.id, presses) }
					mStreamingCharacteristic?.streamingPacket = { packet in self.lambdaStreamingPacket?(self.id, packet) }
					mStreamingCharacteristic?.dataAvailable = { self.lambdaDataAvailable?(self.id) }

					mStreamingCharacteristic?.discoverDescriptors()

				#endif

				#if UNIVERSAL || ETHOS || ALTER || KAIROS
				case .ambiqOTARXCharacteristic:
					if let service = characteristic.service {
						log?.v ("\(self.id) for service: \(service.prettyID) - '\(testCharacteristic.title)'")
					}
					else {
						log?.v ("\(self.id) for nil service - '\(testCharacteristic.title)'")
					}
					
					mAmbiqOTARXCharacteristic = ambiqOTARXCharacteristic(peripheral, characteristic: characteristic)
					mAmbiqOTARXCharacteristic?.started	= { self.lambdaUpdateFirmwareStarted?(self.id) }
					mAmbiqOTARXCharacteristic?.finished = { self.lambdaUpdateFirmwareFinished?(self.id) }
					mAmbiqOTARXCharacteristic?.failed	= { code, message in self.lambdaUpdateFirmwareFailed?(self.id, code, message) }
					mAmbiqOTARXCharacteristic?.progress	= { percent in self.lambdaUpdateFirmwareProgress?(self.id, percent) }
					
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
				case .livotalMainCharacteristic:
					mMainCharacteristic	= customMainCharacteristic(peripheral, characteristic: characteristic)
					#if UNIVERSAL
					mMainCharacteristic?.type	= .livotal
					#endif
					attachMainCharacteristicCallbacks()
					mMainCharacteristic?.enterShipModeComplete = { successful in self.lambdaEnterShipModeComplete?(self.id, successful) }
					mMainCharacteristic?.readCanLogDiagnosticsComplete = { successful, allow in self.lambdaReadCanLogDiagnosticsComplete?(self.id, successful, allow) }
					mMainCharacteristic?.updateCanLogDiagnosticsComplete = { successful in self.lambdaUpdateCanLogDiagnosticsComplete?(self.id, successful) }
					mMainCharacteristic?.rawLoggingComplete = { successful in self.lambdaRawLoggingComplete?(self.id, successful) }
					mMainCharacteristic?.allowPPGComplete = { successful in self.lambdaAllowPPGComplete?(self.id, successful)}
					mMainCharacteristic?.wornCheckComplete = { successful, code, value in self.lambdaWornCheckComplete?(self.id, successful, code, value )}
					mMainCharacteristic?.resetComplete = { successful in self.lambdaResetComplete?(self.id, successful) }
					mMainCharacteristic?.endSleepComplete = { successful in self.lambdaEndSleepComplete?(self.id, successful) }
					mMainCharacteristic?.getAllPacketsComplete = { successful in self.lambdaGetAllPacketsComplete?(self.id, successful) }
					mMainCharacteristic?.getAllPacketsAcknowledgeComplete = { successful, ack in self.lambdaGetAllPacketsAcknowledgeComplete?(self.id, successful, ack) }
					mMainCharacteristic?.getNextPacketComplete = { successful, error_code, caughtUp, packet in self.lambdaGetNextPacketComplete?(self.id, successful, error_code, caughtUp, packet) }
					mMainCharacteristic?.getPacketCountComplete = { successful, count in self.lambdaGetPacketCountComplete?(self.id, successful, count) }
					mMainCharacteristic?.disableWornDetectComplete = { successful in self.lambdaDisableWornDetectComplete?(self.id, successful) }
					mMainCharacteristic?.enableWornDetectComplete = { successful in self.lambdaEnableWornDetectComplete?(self.id, successful) }
					mMainCharacteristic?.setSessionParamComplete = { successful, parameter in self.lambdaSetSessionParamComplete?(self.id, successful, parameter) }
					mMainCharacteristic?.getSessionParamComplete = { successful, parameter, value in self.lambdaGetSessionParamComplete?(self.id, successful, parameter, value) }
					mMainCharacteristic?.acceptSessionParamsComplete	= { successful in self.lambdaAcceptSessionParamsComplete?(self.id, successful) }
					mMainCharacteristic?.resetSessionParamsComplete	= { successful in self.lambdaResetSessionParamsComplete?(self.id, successful) }
					mMainCharacteristic?.manufacturingTestComplete	= { successful in self.lambdaManufacturingTestComplete?(self.id, successful) }

					mMainCharacteristic?.dataPackets = { packets in self.lambdaDataPackets?(self.id, -1, packets) }
					mMainCharacteristic?.dataComplete = { bad_fw_read_count, bad_fw_parse_count, overflow_count, bad_sdk_parse_count in self.lambdaDataComplete?(self.id, bad_fw_read_count, bad_fw_parse_count, overflow_count, bad_sdk_parse_count, false) }
					mMainCharacteristic?.dataFailure = { self.lambdaDataFailure?(self.id) }
					mMainCharacteristic?.ppgMetrics = { successful, packet in self.lambdaPPGMetrics?(self.id, successful, packet) }
					mMainCharacteristic?.ppgFailed = { code in self.lambdaPPGFailed?(self.id, code) }
					mMainCharacteristic?.manufacturingTestResult		= { valid, result in self.lambdaManufacturingTestResult?(self.id, valid, result)}

					mMainCharacteristic?.discoverDescriptors()
					
				case .livotalDataCharacteristic:
					mDataCharacteristic = customDataCharacteristic(peripheral, characteristic: characteristic)
					mDataCharacteristic?.dataPackets = { sequence_number, packets in self.lambdaDataPackets?(self.id, sequence_number, packets) }
					mDataCharacteristic?.dataComplete = { bad_fw_read_count, bad_fw_parse_count, overflow_count, bad_sdk_parse_count, intermediate in self.lambdaDataComplete?(self.id, bad_fw_read_count, bad_fw_parse_count, overflow_count, bad_sdk_parse_count, intermediate) }
					mDataCharacteristic?.discoverDescriptors()
					
				case .livotalStrmCharacteristic:
					mStreamingCharacteristic = customStreamingCharacteristic(peripheral, characteristic: characteristic)
					#if UNIVERSAL
					mStreamingCharacteristic?.type	= .livotal
					#endif
					attachStreamingCharacteristicCallbacks()
					mStreamingCharacteristic?.ppgMetrics = { successful, packet in self.lambdaPPGMetrics?(self.id, successful, packet) }
					mStreamingCharacteristic?.ppgFailed = { code in self.lambdaPPGFailed?(self.id, code) }
					mStreamingCharacteristic?.manufacturingTestResult	= { valid, result in self.lambdaManufacturingTestResult?(self.id, valid, result)}
					mStreamingCharacteristic?.streamingPacket = { packet in self.lambdaStreamingPacket?(self.id, packet) }

					mStreamingCharacteristic?.discoverDescriptors()

				case .nordicDFUCharacteristic:
					if let name = peripheral.name {
						mNordicDFUCharacteristic	= nordicDFUCharacteristic(peripheral, characteristic: characteristic, name: name)
					}
					else {
						mNordicDFUCharacteristic	= nordicDFUCharacteristic(peripheral, characteristic: characteristic)
					}
					mNordicDFUCharacteristic?.failed = { id, code, message in self.lambdaUpdateFirmwareFailed?(id, code, message) }
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
					case .ethosMainCharacteristic		: mMainCharacteristic?.didDiscoverDescriptor()
					case .ethosDataCharacteristic		: mDataCharacteristic?.didDiscoverDescriptor()
					case .ethosStrmCharacteristic		: mStreamingCharacteristic?.didDiscoverDescriptor()
					#endif

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

					#if UNIVERSAL || ETHOS || ALTER || KAIROS
					case .ambiqOTARXCharacteristic		: log?.e ("\(self.id) '\(enumerated.title)' - should not be here")
					case .ambiqOTATXCharacteristic		: mAmbiqOTATXCharacteristic?.didDiscoverDescriptor()
					#endif
					
					#if UNIVERSAL || LIVOTAL
					case .livotalMainCharacteristic		: mMainCharacteristic?.didDiscoverDescriptor()
					case .livotalDataCharacteristic		: mDataCharacteristic?.didDiscoverDescriptor()
					case .livotalStrmCharacteristic		: mStreamingCharacteristic?.didDiscoverDescriptor()
					case .nordicDFUCharacteristic		: mNordicDFUCharacteristic?.didDiscoverDescriptor()
					#endif
					}
				}
				else if let enumerated = org_bluetooth_characteristic(rawValue: characteristic.prettyID) {
					switch (enumerated) {
					case .battery_level					: mBatteryLevelCharacteristic?.didDiscoverDescriptor()
					#if UNIVERSAL || ETHOS
					case .plx_continuous_measurement	: mPulseOxContinuousCharacteristic?.didDiscoverDescriptor()
					#endif
					#if UNIVERSAL || ETHOS || ALTER || KAIROS
					case .heart_rate_measurement		: mHeartRateMeasurementCharacteristic?.didDiscoverDescriptor()
					#endif
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

					#if UNIVERSAL || ETHOS
					self.medtorSoftwareRevision = softwareRevisionCharacteristic.medtor
					#endif

					#if UNIVERSAL || ALTER || KAIROS || ETHOS
					self.sleepSoftwareRevision = softwareRevisionCharacteristic.sleep
					#endif

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
			#if UNIVERSAL || ETHOS
			case .plx_continuous_measurement	: mPulseOxContinuousCharacteristic?.didUpdateValue()
			#endif
			#if UNIVERSAL || ETHOS || ALTER || KAIROS
			case .heart_rate_measurement		: mHeartRateMeasurementCharacteristic?.didUpdateValue()
			#endif
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
			case .ethosMainCharacteristic		: mMainCharacteristic?.didUpdateValue()
			case .ethosDataCharacteristic		: mDataCharacteristic?.didUpdateValue()
			case .ethosStrmCharacteristic		: mStreamingCharacteristic?.didUpdateValue()
			#endif

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
				
			#if UNIVERSAL || ETHOS || ALTER || KAIROS
			case .ambiqOTARXCharacteristic		: log?.e ("\(self.id) '\(enumerated.title)' - should not be here")
			case .ambiqOTATXCharacteristic		:
				// Commands to RX come in on TX, causes RX to do next step
				if let value = characteristic.value {
					mAmbiqOTARXCharacteristic?.didUpdateTXValue(value)
				}
				else {
					log?.e ("\(self.id) '\(enumerated.title)' - No data received for RX command")
				}
			#endif
			
			#if UNIVERSAL || LIVOTAL
			case .livotalMainCharacteristic		: mMainCharacteristic?.didUpdateValue()
			case .livotalDataCharacteristic		: mDataCharacteristic?.didUpdateValue()
			case .livotalStrmCharacteristic		: mStreamingCharacteristic?.didUpdateValue()
			case .nordicDFUCharacteristic		: mNordicDFUCharacteristic?.didUpdateValue()
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
					case .ethosMainCharacteristic			: mMainCharacteristic?.didUpdateNotificationState()
					case .ethosDataCharacteristic			: mDataCharacteristic?.didUpdateNotificationState()
					case .ethosStrmCharacteristic			: mStreamingCharacteristic?.didUpdateNotificationState()
					#endif

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
						
					#if UNIVERSAL || ETHOS || ALTER || KAIROS
					case .ambiqOTARXCharacteristic			: log?.e ("\(self.id) '\(enumerated.title)' - should not be here")
					case .ambiqOTATXCharacteristic			: mAmbiqOTATXCharacteristic?.didUpdateNotificationState()
					#endif

					#if UNIVERSAL || LIVOTAL
					case .livotalMainCharacteristic			: mMainCharacteristic?.didUpdateNotificationState()
					case .livotalDataCharacteristic			: mDataCharacteristic?.didUpdateNotificationState()
					case .livotalStrmCharacteristic			: mStreamingCharacteristic?.didUpdateNotificationState()
					case .nordicDFUCharacteristic			: mNordicDFUCharacteristic?.didUpdateNotificationState()
					#endif
					}
				}
				else if let enumerated = org_bluetooth_characteristic(rawValue: characteristic.prettyID) {
					log?.v ("\(self.id): '\(enumerated.title)'")
					
					switch (enumerated) {
					case .battery_level					: mBatteryLevelCharacteristic?.didUpdateNotificationState()
					#if UNIVERSAL || ETHOS
					case .plx_continuous_measurement	: mPulseOxContinuousCharacteristic?.didUpdateNotificationState()
					#endif
					#if UNIVERSAL || ETHOS || ALTER || KAIROS
					case .heart_rate_measurement		: mHeartRateMeasurementCharacteristic?.didUpdateNotificationState()
					#endif
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
		#if UNIVERSAL || ETHOS || ALTER || KAIROS
		mAmbiqOTARXCharacteristic?.isReady()
		#endif
	}

}
