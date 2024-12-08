//
//  Device.swift
//  biostrapDeviceSDK
//
//  Created by Joseph A. Bennett on 3/31/21.
//

import Foundation
import CoreBluetooth
import Combine

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
			}
		}
	}

	public enum ConnectionState {
		case disconnected
		case connecting
		case configuring
		case configured
        
        var title: String {
            switch self {
            case .disconnected: return "Disconnected"
            case .connecting: return "Connecting"
            case .configuring: return "Configuring"
            case .configured: return "Configured"
            }
        }
	}
		
	#if UNIVERSAL
	@objc public var type	: biostrapDeviceSDK.biostrapDeviceType
	#endif
	
	var peripheral			: CBPeripheral?
	var centralManager		: CBCentralManager?
	
	// MARK: Published properties
	@Published public var connectionState : ConnectionState = .disconnected

	@Published public private(set) var name: String
	@Published public private(set) var id: String
	@Published public private(set) var discovery_type: biostrapDeviceSDK.biostrapDiscoveryType
	@Published public private(set) var epoch: Int?
	
	@Published public private(set) var batteryLevel: Int?
	@Published public private(set) var worn: Bool?
	@Published public private(set) var charging: Bool?
	@Published public private(set) var on_charger: Bool?
	@Published public private(set) var charge_error: Bool?

	@Published public private(set) var modelNumber: String?
	@Published public private(set) var firmwareRevision: String?
	@Published public private(set) var hardwareRevision: String?
	@Published public private(set) var manufacturerName: String?
	@Published public private(set) var serialNumber: String?
	@Published public private(set) var bluetoothSoftwareRevision: String?
	@Published public private(set) var algorithmsSoftwareRevision: String?
	@Published public private(set) var sleepSoftwareRevision: String?
	
	@Published public private(set) var canLogDiagnostics: Bool?
	
	@Published public private(set) var wornCheckResult: DeviceWornCheckResultType?

	@Published public private(set) var advertisingInterval: Int?
	@Published public private(set) var chargeCycles: Float?
	@Published public private(set) var advertiseAsHRM: Bool?
	@Published public private(set) var rawLogging: Bool?
	@Published public private(set) var wornOverridden: Bool?
	@Published public var buttonResponseEnabled: Bool?
	
	@Published public private(set) var singleButtonPressAction: buttonCommandType?
	@Published public private(set) var doubleButtonPressAction: buttonCommandType?
	@Published public private(set) var tripleButtonPressAction: buttonCommandType?
	@Published public private(set) var longButtonPressAction: buttonCommandType?

	@Published public private(set) var hrZoneLEDBelow: hrZoneLEDValueType?
	@Published public private(set) var hrZoneLEDWithin: hrZoneLEDValueType?
	@Published public private(set) var hrZoneLEDAbove: hrZoneLEDValueType?
	@Published public private(set) var hrZoneRange: hrZoneRangeValueType?
	
	@Published public private(set) var buttonTaps: Int?

	@Published public private(set) var paired: Bool?
	@Published public private(set) var advertisingPageThreshold: Int?
	
	@Published public private(set) var ppgCapturePeriod: Int?
	@Published public private(set) var ppgCaptureDuration: Int?
	@Published public private(set) var tag: String?
	
	@Published public private(set) var ppgMetrics: ppgMetricsType?

    @Published public private(set) var signalStrength: Int?

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
	var lambdaConfigured: ((_ id: String)->())?
	
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

	internal var commandQ: CommandQ?
	
    internal var mBAS: basService?
    internal var mHRS: hrsService?
    internal var mDIS: disService?
    internal var mAmbiqOTAService: ambiqOTAService?

	internal var mMainCharacteristic: customMainCharacteristic?
	internal var mDataCharacteristic: customDataCharacteristic?
	internal var mStreamingCharacteristic: customStreamingCharacteristic?
    
    internal var subscriptions = Set<AnyCancellable>()
    
    internal var preview: Bool = false
    internal var previewTag: String?
    internal var previewPPGCapturePeriod: Int?
    internal var previewPPGCaptureDuration: Int?
    internal var previewCommandStatus: DeviceCommandCompletionStatus = .successful
    internal var previewFirmwareTimer: Timer?
    internal var previewFirmwareProgress: Float = 0.0

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
				globals.log.v ("\(peripheral.prettyID): '\(standardService.title)'")
				switch standardService {
				case .device_information,
					 .battery_service,
					 .pulse_oximeter,
					 .heart_rate			: return true
				default:
					globals.log.e ("\(peripheral.prettyID): (unknown): '\(standardService.title)'")
					return false
				}
			} else if let customService = Device.services(rawValue: service.prettyID) {
				globals.log.v ("\(peripheral.prettyID): '\(customService.title)'")
				return true
			} else if service.uuid == ambiqOTAService.scan_service {
                globals.log.v ("\(peripheral.prettyID): 'Ambiq OTA'")
                return true
            } else {
				globals.log.e ("\(peripheral.prettyID): \(service.prettyID) - don't know what to do!!!!")
				return false
			}
		}
		else {
			return (false)
		}
	}
    
	#if UNIVERSAL
    static public func previewed(type: biostrapDeviceSDK.biostrapDeviceType = .alter,
                                 battery: Int? = nil,
                                 charging: Bool? = nil,
                                 on_charger: Bool? = nil,
                                 worn: Bool? = nil,
                                 modelNumber: String? = nil,
                                 firmwareRevision: String? = nil,
                                 hardwareRevision: String? = nil,
                                 manufacturerName: String? = nil,
                                 serialNumber: String? = nil,
                                 bluetoothSoftwareRevision: String? = nil,
                                 algorithmsSoftwareRevision: String? = nil,
                                 sleepSoftwareRevision: String? = nil,
                                 commandCompletionStatus: DeviceCommandCompletionStatus? = nil
    ) -> Device {
        let device = Device()
        device.type = type
        device.name = "\(type.title)-Preview"

        device.updatePreview(battery: battery,
                             charging: charging,
                             on_charger: on_charger,
                             worn: worn,
                             modelNumber: modelNumber,
                             firmwareRevision: firmwareRevision,
                             hardwareRevision: hardwareRevision,
                             manufacturerName: manufacturerName,
                             serialNumber: serialNumber,
                             bluetoothSoftwareRevision: bluetoothSoftwareRevision,
                             algorithmsSoftwareRevision: algorithmsSoftwareRevision,
                             sleepSoftwareRevision: sleepSoftwareRevision,
                             commandCompletionStatus: commandCompletionStatus
        )
        
        return device
    }
	#endif

	#if ALTER || KAIROS
    static public func previewed(battery: Int? = nil,
                                 charging: Bool? = nil,
                                 on_charger: Bool? = nil,
                                 worn: Bool? = nil,
                                 modelNumber: String? = nil,
                                 firmwareRevision: String? = nil,
                                 hardwareRevision: String? = nil,
                                 manufacturerName: String? = nil,
                                 serialNumber: String? = nil,
                                 bluetoothSoftwareRevision: String? = nil,
                                 algorithmsSoftwareRevision: String? = nil,
                                 sleepSoftwareRevision: String? = nil,
                                 commandCompletionStatus: DeviceCommandCompletionStatus? = nil
    ) -> Device {
        let device = Device()
        
		#if ALTER
        device.name = "Alter-Preview"
		#endif

		#if KAIROS
        device.name = "Kairos-Preview"
		#endif

        device.updatePreview(battery: battery,
                             charging: charging,
                             on_charger: on_charger,
                             worn: worn,
                             modelNumber: modelNumber,
                             firmwareRevision: firmwareRevision,
                             hardwareRevision: hardwareRevision,
                             manufacturerName: manufacturerName,
                             serialNumber: serialNumber,
                             bluetoothSoftwareRevision: bluetoothSoftwareRevision,
                             algorithmsSoftwareRevision: algorithmsSoftwareRevision,
                             sleepSoftwareRevision: sleepSoftwareRevision,
                             commandCompletionStatus: commandCompletionStatus
        )
        
        return device
    }
	#endif
    
	override public init() {
		self.connectionState = .disconnected

		self.name							= "UNKNOWN"
		self.id								= "UNKNOWN"
		self.discovery_type					= .unknown
		
		#if UNIVERSAL
		self.type							= .unknown
		#endif
	}
    
	#if UNIVERSAL
	convenience public init(_ name: String, id: String, centralManager: CBCentralManager?, peripheral: CBPeripheral?, type: biostrapDeviceSDK.biostrapDeviceType, discoveryType: biostrapDeviceSDK.biostrapDiscoveryType) {
		self.init()
		
		self.name		= name
		self.id			= id
		self.peripheral	= peripheral
		self.centralManager = centralManager
		self.type = type
		self.discovery_type = discoveryType
		self.commandQ = CommandQ(peripheral)
        
        self.mBAS = basService()
        self.mHRS = hrsService()
        self.mDIS = disService(type)
        self.mAmbiqOTAService = ambiqOTAService()
	}
	#else
	convenience public init(_ name: String, id: String, centralManager: CBCentralManager?, peripheral: CBPeripheral?, discoveryType: biostrapDeviceSDK.biostrapDiscoveryType) {
		self.init()
		
		self.name		= name
		self.id			= id
		self.peripheral	= peripheral
		self.centralManager = centralManager
		self.discovery_type = discoveryType
		self.commandQ = CommandQ(peripheral)
        
        self.mBAS = basService()
        self.mHRS = hrsService()
        self.mDIS = disService()
        self.mAmbiqOTAService = ambiqOTAService()
	}
	#endif
	
	#if UNIVERSAL || ALTER
	internal var mAlterConfigured: Bool {
        if let mAmbiqOTAService, let mMainCharacteristic, let mBAS, let mHRS, let mDIS {
            
			//globals.log.e ("\(mAmbiqOTAService.pConfigured):\(mBAS.pConfigured):\(mHRS.pConfigured):\(mDIS.isConfigured),\(mMainCharacteristic.configured):\(mStreamingCharacteristic?.configured):\(mDataCharacteristic?.configured)")
			
			if let mDataCharacteristic, let mStreamingCharacteristic {
				return (mBAS.pConfigured &&
                        mHRS.pConfigured &&
                        mDIS.pConfigured &&
                        mAmbiqOTAService.pConfigured &&
						mMainCharacteristic.configured &&
						mDataCharacteristic.configured &&
                        mStreamingCharacteristic.configured
				)
			} else {
				return (mBAS.pConfigured &&
                        mHRS.pConfigured &&
                        mDIS.pConfigured &&
                        mAmbiqOTAService.pConfigured &&
						mMainCharacteristic.configured
				)
			}
		}
		else { return (false) }
	}
	#endif

	#if UNIVERSAL || KAIROS
	internal var mKairosConfigured: Bool {
        if let mAmbiqOTAService, let mMainCharacteristic, let mBAS, let mHRS, let mDIS {
			
			if let mDataCharacteristic, let mStreamingCharacteristic {
				return (mBAS.pConfigured &&
                        mHRS.pConfigured &&
                        mDIS.pConfigured &&
                        mAmbiqOTAService.pConfigured &&
						mMainCharacteristic.configured &&
						mDataCharacteristic.configured &&
                        mStreamingCharacteristic.configured
				)
			} else {
				return (mBAS.pConfigured &&
                        mHRS.pConfigured &&
                        mDIS.pConfigured &&
                        mAmbiqOTAService.pConfigured &&
						mMainCharacteristic.configured
				)
			}
		}
		else { return (false) }
	}
	#endif

	//--------------------------------------------------------------------------------
	// Function Name: checkConfigured
	//--------------------------------------------------------------------------------
	//
	// See if everything has been configured
	//
	//--------------------------------------------------------------------------------
	internal func checkConfigured() {
        if let mDIS, let customCharacteristic = mMainCharacteristic {
			customCharacteristic.firmwareVersion = mDIS.mFirmwareRevisionCharacteristic.value
		}
		
		if connectionState == .configured { return } // If i was already configured, i don't need to tell the app this again
        if preview { return } // If i am mocked, i don't need to tell the app again
		
		var configured: Bool = false
		
		#if UNIVERSAL
		switch type {
		case .alter		: configured = mAlterConfigured
		case .kairos	: configured = mKairosConfigured
		case .unknown	: break
		}
		#endif
				
		#if ALTER
		configured = mAlterConfigured
		#endif
		
		#if KAIROS
		configured = mKairosConfigured
		#endif

		if (configured) {
			connectionState = .configured
			if let peripheral {
				lambdaConfigured?(peripheral.prettyID)
			}
			else {
				globals.log.e ("Do not have a peripheral, why am I signaling configured?")
			}
		}
	}
	
	//--------------------------------------------------------------------------------
	// Function Name: connect
	//--------------------------------------------------------------------------------
	//
	// Connect the device
	//
	//--------------------------------------------------------------------------------
	public func connect() {
		if connectionState == .disconnected {
			connectionState = .connecting
			
			if let centralManager, let peripheral {
				centralManager.connect(peripheral, options: nil)
			}
			else {
				globals.log.e ("Either do not have a central manager or a peripheral")
			}
		}
		else {
			globals.log.e ("Device is not in a disconnected state")
		}
	}
	
	//--------------------------------------------------------------------------------
	// Function Name: connect
	//--------------------------------------------------------------------------------
	//
	// Connect the device
	//
	//--------------------------------------------------------------------------------
	public func disconnect() {
		if connectionState != .disconnected {
			if let centralManager, let peripheral {
				centralManager.cancelPeripheralConnection(peripheral)
			}
			else {
				globals.log.e ("Either do not have a central manager or a peripheral")
			}
		}
		else {
			globals.log.e ("Device is not in a connecting or connected state")
		}
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
        if preview {
            self.epoch = newEpoch
            self.writeEpochComplete.send(previewCommandStatus)
            return
        }

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
        if preview {
            self.readEpochComplete.send(previewCommandStatus)
            return
        }
        
		if let mainCharacteristic = mMainCharacteristic {
			mainCharacteristic.readEpoch()
		} else {
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
        if preview {
            self.endSleepComplete.send(previewCommandStatus)
            self.endSleepStatus.send(true)
            return
        }
        
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
            if let mDIS {
				if (mDIS.mSoftwareRevisionCharacteristic.bluetoothGreaterThan("2.0.4")) {
					globals.log.v ("Bluetooth library version: '\(mDIS.mSoftwareRevisionCharacteristic.bluetooth)' - Use new style")
					newStyle	= true
				}
				else {
					globals.log.v ("Bluetooth library version: '\(mDIS.mSoftwareRevisionCharacteristic.bluetooth)' - Use old style")
				}
			}
			else {
				globals.log.e ("Can't find the software version, i guess i will use the old style")
			}

			mainCharacteristic.getAllPackets(pages: pages, delay: delay, newStyle: newStyle)
		}
		else { self.lambdaGetAllPacketsComplete?(id, false) }
	}

	public func getAllPackets(pages: Int, delay: Int) {
        if preview {
            self.getAllPacketsComplete.send(previewCommandStatus)
            return
        }
        
		var newStyle	= false
		
		if let mainCharacteristic = mMainCharacteristic {
            if let mDIS {
				if (mDIS.mSoftwareRevisionCharacteristic.bluetoothGreaterThan("2.0.4")) {
					globals.log.v ("Bluetooth library version: '\(mDIS.mSoftwareRevisionCharacteristic.bluetooth)' - Use new style")
					newStyle	= true
				}
				else {
					globals.log.v ("Bluetooth library version: '\(mDIS.mSoftwareRevisionCharacteristic.bluetooth)' - Use old style")
				}
			}
			else {
				globals.log.e ("Can't find the software version, i guess i will use the old style")
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
        if preview {
            self.getAllPacketsAcknowledgeComplete.send((previewCommandStatus, ack))
            return
        }
        
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
        if preview {
            self.getPacketCountComplete.send((previewCommandStatus, 0))
            return
        }
        
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
        if preview {
            self.disableWornDetectComplete.send(previewCommandStatus)
            return
        }
        
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
        if preview {
            self.enableWornDetectComplete.send(previewCommandStatus)
            return
        }
        
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
        if preview {
            self.startManualComplete.send(previewCommandStatus)
            return
        }
        
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
        if preview {
            self.stopManualComplete.send(previewCommandStatus)
            return
        }
        
		if let mainCharacteristic = mMainCharacteristic {
			mainCharacteristic.stopManual()
		}
		else {
			DispatchQueue.main.async { self.stopManualComplete.send(.not_configured) }
		}
	}

	#if UNIVERSAL || ALTER || KAIROS
	func userLEDInternal(red: Bool, green: Bool, blue: Bool, blink: Bool, seconds: Int) {
		if let mainCharacteristic = mMainCharacteristic {
			mainCharacteristic.userLED(red: red, green: green, blue: blue, blink: blink, seconds: seconds)
		}
		else { self.lambdaLEDComplete?(id, false) }
	}
	
	public func userLED(red: Bool, green: Bool, blue: Bool, blink: Bool, seconds: Int) {
        if preview {
            self.ledComplete.send(previewCommandStatus)
            return
        }
        
		if let mainCharacteristic = mMainCharacteristic {
			mainCharacteristic.userLED(red: red, green: green, blue: blue, blink: blink, seconds: seconds)
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
        if preview {
            self.enterShipModeComplete.send(previewCommandStatus)
            return
        }
        
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
        if preview {
            self.resetComplete.send(previewCommandStatus)
            return
        }
        
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
        if preview {
            self.airplaneModeComplete.send(previewCommandStatus)
            return
        }
        
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
        if preview {
            self.serialNumber = partID
            self.writeSerialNumberComplete.send(previewCommandStatus)
            return
        }
        
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
        if preview {
            self.readSerialNumberComplete.send(previewCommandStatus)
            return
        }
        
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
        if preview {
            self.serialNumber = nil
            self.deleteSerialNumberComplete.send(previewCommandStatus)
            return
        }
        
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
        if preview {
            self.advertisingInterval = seconds
            self.writeAdvIntervalComplete.send(previewCommandStatus)
            return
        }
        
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
        if preview {
            self.readAdvIntervalComplete.send(previewCommandStatus)
            return
        }
        
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
        if preview {
            self.advertisingInterval = nil
            self.deleteAdvIntervalComplete.send(previewCommandStatus)
            return
        }
        
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
        if preview {
            self.chargeCycles = 0.0
            self.clearChargeCyclesComplete.send(previewCommandStatus)
            return
        }
        
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
        if preview {
            self.readChargeCyclesComplete.send(previewCommandStatus)
            return
        }
        
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
        if preview {
            self.readCanLogDiagnosticsComplete.send(previewCommandStatus)
            return
        }
            
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
        if preview {
            self.canLogDiagnostics = allow
            self.updateCanLogDiagnosticsComplete.send(previewCommandStatus)
            return
        }

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
        if preview {
            self.manufacturingTestComplete.send(previewCommandStatus)
            if previewCommandStatus == .successful {
                self.previewSendAlterTestResult(test)
            }
            return
        }
        
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
        if preview {
            self.manufacturingTestComplete.send(previewCommandStatus)
            if previewCommandStatus == .successful {
                self.previewSendKairosTestResult(test)
            }
            return
        }

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
        if preview {
            self.buttonResponseEnabled = enable
            self.setAskForButtonResponseComplete.send(previewCommandStatus)
            return
        }

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
        if preview {
            self.getAskForButtonResponseComplete.send(previewCommandStatus)
            return
        }

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
        if preview {
            switch (type) {
            case .below: self.hrZoneLEDBelow = hrZoneLEDValueType(red: red, green: green, blue: blue, on_ms: on_milliseconds, off_ms: off_milliseconds)
            case .within: self.hrZoneLEDWithin = hrZoneLEDValueType(red: red, green: green, blue: blue, on_ms: on_milliseconds, off_ms: off_milliseconds)
            case .above: self.hrZoneLEDAbove = hrZoneLEDValueType(red: red, green: green, blue: blue, on_ms: on_milliseconds, off_ms: off_milliseconds)
            default: break
            }
            
            self.setHRZoneColorComplete.send((previewCommandStatus, type))
            return
        }
        
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
        if preview {
            self.getHRZoneColorComplete.send((previewCommandStatus, type))
            return
        }

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
        if preview {
            self.hrZoneRange = hrZoneRangeValueType(enabled: enabled, lower: low_value, upper: high_value)
            self.setHRZoneRangeComplete.send(previewCommandStatus)
            return
        }
        
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
        if preview {
            self.getHRZoneRangeComplete.send(previewCommandStatus)
            return
        }

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
        if preview {
            self.getPPGAlgorithmComplete.send((true, ppgAlgorithmConfiguration(), eventType.unknown))
            return
        }

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
        if preview {
            self.advertiseAsHRM = asHRM
            self.setAdvertiseAsHRMComplete.send(previewCommandStatus)
            return
        }
        
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
        if preview {
            self.getAdvertiseAsHRMComplete.send(previewCommandStatus)
            return
        }
        
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
        if preview {
            switch tap {
            case .single: self.singleButtonPressAction = command
            case .double: self.doubleButtonPressAction = command
            case .triple: self.tripleButtonPressAction = command
            case .long: self.longButtonPressAction = command
            case .unknown: break
            }
            self.setButtonCommandComplete.send((previewCommandStatus, tap))
            return
        }
        
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
        if preview {
            self.getButtonCommandComplete.send((previewCommandStatus, tap))
            return
        }
        
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
			DispatchQueue.main.async {
				self.paired = nil
				self.getPairedComplete.send(.not_configured)
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
	func setPageThresholdInternal(_ threshold: Int) {
		if let mainCharacteristic = mMainCharacteristic { mainCharacteristic.setPageThreshold(threshold) }
		else { self.lambdaSetPageThresholdComplete?(self.id, false) }
	}
	
	public func setPageThreshold(_ threshold: Int) {
        if preview {
            self.advertisingPageThreshold = threshold
            self.setPageThresholdComplete.send(previewCommandStatus)
            return
        }

		if let mainCharacteristic = mMainCharacteristic { mainCharacteristic.setPageThreshold(threshold) }
		else {
			DispatchQueue.main.async {
				self.setPageThresholdComplete.send(.not_configured)
			}
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
        if preview {
            self.getPageThresholdComplete.send(previewCommandStatus)
            return
        }

		if let mainCharacteristic = mMainCharacteristic { mainCharacteristic.getPageThreshold() }
		else {
			DispatchQueue.main.async {
				self.advertisingPageThreshold = nil
				self.getPageThresholdComplete.send(.not_configured)
			}
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
        if preview {
            self.advertisingPageThreshold = nil
            self.deletePageThresholdComplete.send(previewCommandStatus)
            return
        }

		if let mainCharacteristic = mMainCharacteristic { mainCharacteristic.deletePageThreshold() }
		else {
			DispatchQueue.main.async {
				self.deletePageThresholdComplete.send(.not_configured)
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
	func rawLoggingInternal(_ enable: Bool) {
		if let mainCharacteristic = mMainCharacteristic {
			mainCharacteristic.rawLogging(enable)
		}
		else { self.lambdaRawLoggingComplete?(id, false) }
	}

	public func rawLogging(_ enable: Bool) {
        if preview {
            self.rawLoggingComplete.send(previewCommandStatus)
            return
        }

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
        if preview {
            self.wornCheckResult = DeviceWornCheckResultType(code: "Preview", value: 0)
            self.wornCheckResultComplete.send(previewCommandStatus)
            return
        }
        
		if let mainCharacteristic = mMainCharacteristic {
			mainCharacteristic.wornCheck()
		}
		else {
			DispatchQueue.main.async {
				self.wornCheckResult = DeviceWornCheckResultType(code: "Not Configured", value: 0)
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
        if preview {
            self.getRawLoggingStatusComplete.send(previewCommandStatus)
            return
        }
        
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
        if preview {
            self.getWornOverrideStatusComplete.send(previewCommandStatus)
        }
        
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
        if let mAmbiqOTAService {
			do {
				let contents = try Data(contentsOf: file)
				mAmbiqOTAService.rxCharacteristic.start(contents)
			}
			catch {
				globals.log.e ("Cannot open file")
				self.lambdaUpdateFirmwareFailed?(self.id, 10001, "Cannot parse file for update")
			}
		}
		else { lambdaUpdateFirmwareFailed?(self.id, 10001, "No OTA RX characteristic to update") }
	}

	public func updateFirmware(_ file: URL) {
        if preview {
            if previewCommandStatus != .successful {
                self.updateFirmwareFailed.send((10001, "Cannot do preview firmware update"))
            } else {
                self.updateFirmwareStarted.send()
                self.previewFirmwareTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
                    let updatePercent = Float.random(in: 0..<0.1)
                    if self.previewFirmwareProgress + updatePercent >= 1.0 {
                        DispatchQueue.main.async {
                            self.previewFirmwareTimer?.invalidate()
                            self.previewFirmwareProgress = 0.0
                            self.updateFirmwareProgress.send(1.0)
                            self.updateFirmwareFinished.send()
                        }
                    } else {
                        self.previewFirmwareProgress += updatePercent
                        self.updateFirmwareProgress.send(self.previewFirmwareProgress)
                    }
                }
            }
            
            return
        }
        
        if let mAmbiqOTAService {
			do {
				let contents = try Data(contentsOf: file)
				mAmbiqOTAService.rxCharacteristic.start(contents)
			}
			catch {
				globals.log.e ("Cannot open file")
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
        if let mAmbiqOTAService { mAmbiqOTAService.rxCharacteristic.cancel() }
		else { lambdaUpdateFirmwareFailed?(self.id, 10001, "No characteristic to cancel") }
	}

	public func cancelFirmwareUpdate() {
        if preview {
            self.previewFirmwareTimer?.invalidate()
            self.previewFirmwareProgress = 0.0
            self.updateFirmwareFailed.send((10001, "User cancelled"))
            return
        }
        
		if let mAmbiqOTAService { mAmbiqOTAService.rxCharacteristic.cancel() }
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
		globals.log.v("\(self.id): \(parameter)")

		if let mainCharacteristic = mMainCharacteristic {
			mainCharacteristic.setSessionParam(parameter, value: value)
		}
		else { self.lambdaSetSessionParamComplete?(self.id, false, parameter) }
	}

	public func setSessionParam(_ parameter: sessionParameterType, value: Int) {
        if preview {
            switch parameter {
            case .tag: self.previewTag = String(value)
            case .ppgCapturePeriod: self.previewPPGCapturePeriod = value
            case .ppgCaptureDuration: self.previewPPGCaptureDuration = value
            default: break
            }
            self.setSessionParamComplete.send((previewCommandStatus, parameter))
        }

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
		globals.log.v("\(self.id): \(parameter)")

		if let mainCharacteristic = mMainCharacteristic {
			mainCharacteristic.getSessionParam(parameter)
		} else { self.lambdaGetSessionParamComplete?(self.id, false, parameter, 0) }
	}

	public func getSessionParam(_ parameter: sessionParameterType) {
        if preview {
            self.getSessionParamComplete.send((previewCommandStatus, parameter))
        }

		if let mainCharacteristic = mMainCharacteristic {
			mainCharacteristic.getSessionParam(parameter)
		} else {
			DispatchQueue.main.async {
				switch parameter {
				case .tag: self.tag = nil
				case .ppgCapturePeriod: self.ppgCapturePeriod = nil
				case .ppgCaptureDuration: self.ppgCaptureDuration = nil
				default: break
				}
				self.getSessionParamComplete.send((.not_configured, parameter))
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
		if let mainCharacteristic = mMainCharacteristic {
			mainCharacteristic.resetSessionParams()
		}
		else { self.lambdaResetSessionParamsComplete?(self.id, false) }
	}

	public func resetSessionParams() {
        if preview {
            self.previewTag = self.tag
            self.previewPPGCapturePeriod = self.ppgCapturePeriod
            self.previewPPGCaptureDuration = self.ppgCaptureDuration
            self.resetSessionParamsComplete.send(previewCommandStatus)
        }

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
		globals.log.v("\(self.id)")

		if let mainCharacteristic = mMainCharacteristic {
			mainCharacteristic.acceptSessionParams()
		}
		else { self.lambdaAcceptSessionParamsComplete?(self.id, false) }
	}
	
	public func acceptSessionParams() {
        if preview {
            self.tag = self.previewTag
            self.ppgCapturePeriod = self.previewPPGCapturePeriod
            self.ppgCaptureDuration = self.previewPPGCaptureDuration
            self.acceptSessionParamsComplete.send(previewCommandStatus)
        }

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
    public func getSignalStrength() {
        if preview {
            self.signalStrength = -1 * Int.random(in: 50..<90)
            return
        }
        
        if let peripheral {
            peripheral.readRSSI()
        } else {
            self.signalStrength = nil
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
				self.worn = isWorn
			}
		}
		
		mMainCharacteristic?.deviceChargingStatus			= { charging, on_charger, error in
			self.lambdaChargingStatus?(self.id, charging, on_charger, error)
			DispatchQueue.main.async {
				self.charging = charging
				self.on_charger = on_charger
				self.charge_error = error
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
				self.buttonTaps = presses
			}
		}
		
		mMainCharacteristic?.wornCheckComplete = { successful, code, value in
			self.lambdaWornCheckComplete?(self.id, successful, code, value )
			DispatchQueue.main.async {
				self.wornCheckResult = DeviceWornCheckResultType(code: code, value: value)
				self.wornCheckResultComplete.send(successful ? .successful : .device_error)
			}
		}
		
		mMainCharacteristic?.setSessionParamComplete = { successful, parameter in
			globals.log.v ("setSessionParamComplete: \(successful), \(parameter)")
			self.lambdaSetSessionParamComplete?(self.id, successful, parameter)
			DispatchQueue.main.async {
				self.setSessionParamComplete.send((successful ? .successful : .device_error, parameter))
			}
		}
		
		mMainCharacteristic?.getSessionParamComplete = { successful, parameter, value in
			globals.log.v ("getSessionParamComplete: \(successful), \(parameter), \(value)")
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
				self.worn = isWorn
			}
		}
		mStreamingCharacteristic?.deviceChargingStatus		= { charging, on_charger, error in
			self.lambdaChargingStatus?(self.id, charging, on_charger, error)
			DispatchQueue.main.async {
				self.charging = charging
				self.on_charger = on_charger
				self.charge_error = error
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
				self.buttonTaps = presses
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
	func didConnect() -> Bool {
		if let peripheral {
			if connectionState == .connecting {
				peripheral.delegate = self
                
                // Battery Service
                mBAS?.didConnect(peripheral)
                mBAS?.$batteryLevel
                    .receive(on: DispatchQueue.main)
                    .sink { [weak self] level in
                        self?.batteryLevel = level
                        if let level {
                            self?.lambdaBatteryLevelUpdated?(self!.id, level)
                        }
                    }
                    .store(in: &subscriptions)
                
                //mBAS?.lambdaUpdated = { [weak self] id, percentage in
                //    self?.lambdaBatteryLevelUpdated?(id, percentage)
                //}
                
                // Heart Rate Service
                mHRS?.didConnect(peripheral)
                mHRS?.updated
                    .compactMap { $0 }
                    .receive(on: DispatchQueue.main)
                    .sink { [weak self] (epoch, hr, rr) in
                        self?.heartRateUpdated.send((epoch, hr, rr))
                        self?.lambdaHeartRateUpdated?(self!.id, epoch, hr, rr)
                    }
                    .store(in: &subscriptions)
                
                //mHRS?.lambdaUpdated = { [weak self] id, epoch, hr, rr in
                //    self?.lambdaHeartRateUpdated?(id, epoch, hr, rr)
                //}
                
                // Device Information Service
                mDIS?.didConnect(peripheral)
                mDIS?.$modelNumber
                    .receive(on: DispatchQueue.main)
                    .sink { [weak self] value in
                        self?.modelNumber = value
                    }
                    .store(in: &subscriptions)
                
                mDIS?.$serialNumber
                    .receive(on: DispatchQueue.main)
                    .sink { [weak self] value in
                        self?.serialNumber = value
                    }
                    .store(in: &subscriptions)
                
                mDIS?.$hardwareRevision
                    .receive(on: DispatchQueue.main)
                    .sink { [weak self] value in
                        self?.hardwareRevision = value
                    }
                    .store(in: &subscriptions)
                
                mDIS?.$manufacturerName
                    .receive(on: DispatchQueue.main)
                    .sink { [weak self] value in
                        self?.manufacturerName = value
                    }
                    .store(in: &subscriptions)

                mDIS?.$firmwareRevision
                    .receive(on: DispatchQueue.main)
                    .sink { [weak self] value in
                        self?.firmwareRevision = value
                    }
                    .store(in: &subscriptions)

                mDIS?.$bluetoothSoftwareRevision
                    .receive(on: DispatchQueue.main)
                    .sink { [weak self] value in
                        self?.bluetoothSoftwareRevision = value
                    }
                    .store(in: &subscriptions)

                mDIS?.$algorithmsSoftwareRevision
                    .receive(on: DispatchQueue.main)
                    .sink { [weak self] value in
                        self?.algorithmsSoftwareRevision = value
                    }
                    .store(in: &subscriptions)

                mDIS?.$sleepSoftwareRevision
                    .receive(on: DispatchQueue.main)
                    .sink { [weak self] value in
                        self?.sleepSoftwareRevision = value
                    }
                    .store(in: &subscriptions)
                
                // AMBIQ OTA
                mAmbiqOTAService?.didConnect(peripheral)

                /*
                mAmbiqOTAService?.lambdaStarted    = {
                    self.lambdaUpdateFirmwareStarted?(self.id)
                }
                
                mAmbiqOTAService?.lambdaFinished = {
                    self.lambdaUpdateFirmwareFinished?(self.id)
                }
                
                mAmbiqOTAService?.lambdaFailed    = { code, message in
                    self.lambdaUpdateFirmwareFailed?(self.id, code, message)
                }
                
                mAmbiqOTAService?.lambdaProgress    = { percent in
                    self.lambdaUpdateFirmwareProgress?(self.id, percent)
                }
                 */
                
                mAmbiqOTAService?.started
                    .receive(on: DispatchQueue.main)
                    .sink {
                        self.updateFirmwareStarted.send()
                        self.lambdaUpdateFirmwareStarted?(self.id)
                    }
                    .store(in: &subscriptions)

                mAmbiqOTAService?.finished
                    .receive(on: DispatchQueue.main)
                    .sink {
                        self.updateFirmwareFinished.send()
                        self.lambdaUpdateFirmwareFinished?(self.id)
                    }
                    .store(in: &subscriptions)
                
                mAmbiqOTAService?.failed
                    .receive(on: DispatchQueue.main)
                    .sink { code, message in
                        self.updateFirmwareFailed.send((code, message))
                        self.lambdaUpdateFirmwareFailed?(self.id, code, message)
                    }
                    .store(in: &subscriptions)

                mAmbiqOTAService?.progress
                    .receive(on: DispatchQueue.main)
                    .sink { percent in
                        self.updateFirmwareProgress.send(percent)
                        self.lambdaUpdateFirmwareProgress?(self.id, percent)
                    }
                    .store(in: &subscriptions)


                // Configure
				connectionState = .configuring
				peripheral.discoverServices(nil)
			}
			else {
				globals.log.e ("\(peripheral.prettyID): Connected to a device that isn't requesting connection.  Weird!  Disconnect")
				return false
			}
		}
		else {
			globals.log.e ("No peripheral")
			return false
		}
		
		return true
	}
	
	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func didDiscoverCharacteristic(_ characteristic: CBCharacteristic) {
        if basService.hit(characteristic) {
			mBAS?.didDiscoverCharacteristic(characteristic, commandQ: commandQ)
            return
        }
        
        if hrsService.hit(characteristic) {
            mHRS?.didDiscoverCharacteristic(characteristic, commandQ: commandQ)
            return
        }
        
        if disService.hit(characteristic) {
            mDIS?.didDiscoverCharacteristic(characteristic, commandQ: commandQ)
            return
        }
        
        if ambiqOTAService.hit(characteristic) {
            mAmbiqOTAService?.didDiscoverCharacteristic(characteristic, commandQ: commandQ)
            return
        }
        
		if let peripheral = peripheral {
			if let testCharacteristic = org_bluetooth_characteristic(rawValue: characteristic.prettyID) {
				switch (testCharacteristic) {
				default:
					if let service = characteristic.service {
						globals.log.e ("\(self.id) for service: \(service.prettyID) - '\(testCharacteristic.title)' - do not know what to do")
					}
					else {
						globals.log.e ("\(self.id) for nil service - '\(testCharacteristic.title)' - do not know what to do")
					}
				}
			}
			else if let testCharacteristic = Device.characteristics(rawValue: characteristic.prettyID) {
				switch (testCharacteristic) {
					
				#if UNIVERSAL || ALTER
				case .alterMainCharacteristic:
					mMainCharacteristic = customMainCharacteristic()
					mMainCharacteristic?.didDiscover(characteristic, commandQ: commandQ)
					#if UNIVERSAL
					mMainCharacteristic?.type	= .alter
					#endif
					attachMainCharacteristicLambdas()
					mMainCharacteristic?.discoverDescriptors()
					
				case .alterDataCharacteristic:
					mDataCharacteristic = customDataCharacteristic()
					mDataCharacteristic?.didDiscover(characteristic, commandQ: commandQ)
					attachDataCharacteristicLambdas()
					mDataCharacteristic?.discoverDescriptors()
					
				case .alterStrmCharacteristic:
					mStreamingCharacteristic = customStreamingCharacteristic()
					mStreamingCharacteristic?.didDiscover(characteristic, commandQ: commandQ)
					#if UNIVERSAL
					mStreamingCharacteristic?.type	= .alter
					#endif
					attachStreamingCharacteristicLambdas()
					mStreamingCharacteristic?.discoverDescriptors()

				#endif

				#if UNIVERSAL || KAIROS
				case .kairosMainCharacteristic:
					mMainCharacteristic = customMainCharacteristic()
					mMainCharacteristic?.didDiscover(characteristic, commandQ: commandQ)
					#if UNIVERSAL
					mMainCharacteristic?.type	= .kairos
					#endif
					attachMainCharacteristicLambdas()
					mMainCharacteristic?.discoverDescriptors()

				case .kairosDataCharacteristic:
					mDataCharacteristic = customDataCharacteristic()
					mDataCharacteristic?.didDiscover(characteristic, commandQ: commandQ)
					attachDataCharacteristicLambdas()
					mDataCharacteristic?.discoverDescriptors()
					
				case .kairosStrmCharacteristic:
					mStreamingCharacteristic = customStreamingCharacteristic()
					mStreamingCharacteristic?.didDiscover(	characteristic, commandQ: commandQ)
					#if UNIVERSAL
					mStreamingCharacteristic?.type	= .kairos
					#endif
					attachStreamingCharacteristicLambdas()
					mStreamingCharacteristic?.discoverDescriptors()
				#endif
				}
			}
			else {
				if let service = characteristic.service {
					globals.log.e ("\(self.id) for service: \(service.prettyID) - \(characteristic.prettyID) - UNKNOWN")
				}
				else {
					globals.log.e ("\(self.id) for nil service - \(characteristic.prettyID) - UNKNOWN")
				}
			}
		}
		else {
			globals.log.e ("Peripheral object is nil - do nothing")
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
        
        if basService.hit(characteristic) {
            mBAS?.didDiscoverDescriptor(characteristic)
            return
        }
        
        if hrsService.hit(characteristic) {
            mHRS?.didDiscoverDescriptor(characteristic)
            return
        }
        
        if ambiqOTAService.hit(characteristic) {
            mAmbiqOTAService?.didDiscoverDescriptor(characteristic)
            return
        }
        
		if let standardDescriptor = org_bluetooth_descriptor(rawValue: descriptor.prettyID) {
			switch (standardDescriptor) {
			case .client_characteristic_configuration:
				if let enumerated = Device.characteristics(rawValue: characteristic.prettyID) {
					globals.log.v ("\(self.id): \(standardDescriptor.title) '\(enumerated.title)'")
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
					}
				}
				else if let enumerated = org_bluetooth_characteristic(rawValue: characteristic.prettyID) {
					switch (enumerated) {
					default:
						globals.log.e ("\(self.id) '\(enumerated.title)' - don't know what to do")
					}
				}
				
			case .characteristic_user_description:
				break

			default:
				globals.log.e ("\(self.id) for characteristic: \(characteristic.prettyID) - '\(standardDescriptor.title)'.  Do not know what to do - skipping")
			}
		}
		else {
			globals.log.e ("\(self.id) for characteristic \(characteristic.prettyID): \(descriptor.prettyID) - do not know what to do")
		}
	}

    //--------------------------------------------------------------------------------
    // Function Name:
    //--------------------------------------------------------------------------------
    //
    // This is for updating from a file
    //
    //--------------------------------------------------------------------------------
    func didUpdateValue(_ data: Data, offset: Int) {
        mDataCharacteristic?.didUpdateValue(true, data: data, offset: offset)
    }

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	// This is for updating from a characteristic
	//
	//--------------------------------------------------------------------------------
	func didUpdateValue(_ characteristic: CBCharacteristic) {
        
        if basService.hit(characteristic) {
            mBAS?.didUpdateValue(characteristic)
            return
        }
        
        if hrsService.hit(characteristic) {
            mHRS?.didUpdateValue(characteristic)
            return
        }

        if disService.hit(characteristic) {
            mDIS?.didUpdateValue(characteristic)
            return
        }
        
        if ambiqOTAService.hit(characteristic) {
            mAmbiqOTAService?.didUpdateValue(characteristic)
            return
        }

		if let enumerated = org_bluetooth_characteristic(rawValue: characteristic.prettyID) {
			switch (enumerated) {
			default:
				globals.log.e ("\(self.id) for characteristic: '\(enumerated.title)' - do not know what to do")
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
			}
		}
		else {
			globals.log.v ("\(self.id) for characteristic: \(characteristic.prettyID)")
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
            
            if basService.hit(characteristic) {
                mBAS?.didUpdateNotificationState(characteristic)
                return
            }
            
            if hrsService.hit(characteristic) {
                mHRS?.didUpdateNotificationState(characteristic)
                return
            }
            
            if ambiqOTAService.hit(characteristic) {
                mAmbiqOTAService?.didUpdateNotificationState(characteristic)
                return
            }
            
			if (characteristic.isNotifying) {
				if let enumerated = Device.characteristics(rawValue: characteristic.prettyID) {
					globals.log.v ("\(self.id): '\(enumerated.title)'")
					
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
					}
				}
				else if let enumerated = org_bluetooth_characteristic(rawValue: characteristic.prettyID) {
					globals.log.v ("\(self.id): '\(enumerated.title)'")
					
					switch (enumerated) {
					default								: globals.log.e ("\(self.id): '\(enumerated.title)'.  Do not know what to do - skipping")
					}
				}
				else {
					globals.log.e ("\(self.id): \(characteristic.prettyID) - do not know what to do")
				}
			}
		}
		else {
			globals.log.e ("Peripheral object is nil - do nothing")
		}
	}

    //--------------------------------------------------------------------------------
    // Function Name:
    //--------------------------------------------------------------------------------
    //
    // Getting the new RSSI value from a read
    //
    //--------------------------------------------------------------------------------
    func didReadRSSI(_ rssi: Int) {
        DispatchQueue.main.async {
            self.signalStrength = rssi
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
        if let mAmbiqOTAService {
			mAmbiqOTAService.rxCharacteristic.isReady()
        }
	}
}

//--------------------------------------------------------------------------------
//--------------------------------------------------------------------------------
extension Device {
	static func ==(lhs: Device, rhs: Device) -> Bool {
		return lhs.id == rhs.id
	}
    
    private func updatePreview(battery: Int? = nil,
                               charging: Bool? = nil,
                               on_charger: Bool? = nil,
                               worn: Bool? = nil,
                               modelNumber: String? = nil,
                               firmwareRevision: String? = nil,
                               hardwareRevision: String? = nil,
                               manufacturerName: String? = nil,
                               serialNumber: String? = nil,
                               bluetoothSoftwareRevision: String? = nil,
                               algorithmsSoftwareRevision: String? = nil,
                               sleepSoftwareRevision: String? = nil,
                               commandCompletionStatus: DeviceCommandCompletionStatus? = nil
    ) {
        self.preview = true

        self.id = UUID().uuidString
        self.connectionState = .configured
        self.epoch = Int.random(in: 0..<3000)
        self.batteryLevel = 50
        self.worn = false
        self.charging = false
        self.on_charger = false
        self.charge_error = false
        self.modelNumber = "modelNumber"
        self.firmwareRevision = "2.2.2"
        self.hardwareRevision = "0.0.3"
        self.manufacturerName = "manufacturerName"
        self.serialNumber = "serialNumber"
        self.bluetoothSoftwareRevision = "bluetoothSoftwareRevision"
        self.algorithmsSoftwareRevision = "algorithmsSoftwareRevision"
        self.sleepSoftwareRevision = "sleepSoftwareRevision"
        self.canLogDiagnostics = false
        self.wornCheckResult = DeviceWornCheckResultType(code: "Not Worn", value: 4)
        self.advertisingInterval = 10
        self.chargeCycles = 1.0
        self.advertiseAsHRM = false
        self.rawLogging = false
        self.wornOverridden = false
        self.buttonResponseEnabled = false
        self.singleButtonPressAction = buttonCommandType.none
        self.doubleButtonPressAction = buttonCommandType.none
        self.tripleButtonPressAction = buttonCommandType.none
        self.longButtonPressAction = buttonCommandType.none
        self.hrZoneLEDBelow = hrZoneLEDValueType(red: false, green: false, blue: false, on_ms: 0, off_ms: 0)
        self.hrZoneLEDWithin = hrZoneLEDValueType(red: false, green: false, blue: false, on_ms: 0, off_ms: 0)
        self.hrZoneLEDAbove = hrZoneLEDValueType(red: false, green: false, blue: false, on_ms: 0, off_ms: 0)
        self.hrZoneRange = hrZoneRangeValueType(enabled: false, lower: 0, upper: 0)
        self.buttonTaps = 0
        self.paired = false
        self.advertisingPageThreshold = 10
        
        self.previewPPGCapturePeriod = 300
        self.previewPPGCaptureDuration = 45
        self.previewTag = "UK"

        self.ppgCapturePeriod = 300
        self.ppgCaptureDuration = 45
        self.tag = "UK"
        
        self.ppgMetrics = ppgMetricsType()
        self.signalStrength = -50

        if let battery { self.batteryLevel = battery }
        if let charging { self.charging = charging }
        if let on_charger { self.on_charger = on_charger }
        if let worn { self.worn = worn }
        if let modelNumber { self.modelNumber = modelNumber }
        if let firmwareRevision { self.firmwareRevision = firmwareRevision }
        if let hardwareRevision { self.hardwareRevision = hardwareRevision }
        if let manufacturerName { self.manufacturerName = manufacturerName }
        if let serialNumber { self.serialNumber = serialNumber }
        if let bluetoothSoftwareRevision { self.bluetoothSoftwareRevision = bluetoothSoftwareRevision }
        if let algorithmsSoftwareRevision { self.algorithmsSoftwareRevision = algorithmsSoftwareRevision }
        if let sleepSoftwareRevision { self.sleepSoftwareRevision = sleepSoftwareRevision }
        if let commandCompletionStatus { self.previewCommandStatus = commandCompletionStatus }
    }
    
    #if UNIVERSAL || ALTER
    private func previewSendAlterTestResult(_ test: alterManufacturingTestType) {
        let testResult = alterManufacturingTestResult()
        testResult.test = test
        testResult.result = Bool.random() ? "Passed" : "Failed"
        do {
            let jsonData = try JSONEncoder().encode(testResult)
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                self.manufacturingTestResult.send((true, jsonString))
            } else {
                globals.log.e ("Result jsonString Failed")
                self.manufacturingTestResult.send((false, ""))
            }
        } catch {
            globals.log.e ("Result creation Failed")
            self.manufacturingTestResult.send((false, ""))
        }
    }
    #endif
    
    #if UNIVERSAL || KAIROS
    private func previewSendKairosTestResult(_ test: kairosManufacturingTestType) {
        let testResult = kairosManufacturingTestResult()
        testResult.test = test
        testResult.result = Bool.random() ? "Passed" : "Failed"
        do {
            let jsonData = try JSONEncoder().encode(testResult)
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                self.manufacturingTestResult.send((true, jsonString))
            } else {
                globals.log.e ("Result jsonString Failed")
                self.manufacturingTestResult.send((false, ""))
            }
        } catch {
            globals.log.e ("Result creation Failed")
            self.manufacturingTestResult.send((false, ""))
        }
    }
	#endif
}
