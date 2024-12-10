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
		#endif

		#if UNIVERSAL || KAIROS
		case kairosMainCharacteristic	= "140BB753-9845-4C0E-B61A-E6BAE41712F1"
		#endif

		var UUID: CBUUID {
			return CBUUID(string: self.rawValue)
		}
		
		var title: String {
			switch (self) {
			#if UNIVERSAL || ALTER
			case .alterMainCharacteristic	: return "Alter Command Characteristic"
			#endif

			#if UNIVERSAL || KAIROS
			case .kairosMainCharacteristic	: return "Kairos Command Characteristic"
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
	public let getPPGAlgorithmComplete = PassthroughSubject<(DeviceCommandCompletionStatus, ppgAlgorithmConfiguration, eventType), Never>()
	
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
	
    internal var mBAS: basService
    internal var mHRS: hrsService
    internal var mDIS: disService
    internal var mAmbiqOTAService: ambiqOTAService
    internal var mCustomService: customService

	internal var mMainCharacteristic: customMainCharacteristic
    
    internal var mDataCharacteristicDiscovered: Bool = false
    internal var mStreamingCharacteristicDiscovered: Bool = false
    
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
            } else if customService.scan_services.contains(service.uuid) {
                return true
			} else if let customService = Device.services(rawValue: service.prettyID) {
				globals.log.v ("\(peripheral.prettyID): '\(customService.title)'")
				return true
            } else if ambiqOTAService.scan_services.contains(service.uuid) {
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
        
        mMainCharacteristic = customMainCharacteristic()
        
        mBAS = basService()
        mHRS = hrsService()
        mDIS = disService()
        mAmbiqOTAService = ambiqOTAService()
        mCustomService = customService()

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
		
        self.subscribeMainCharacteristic()
        self.subScribeCustomService()
        self.subscribeBAS()
        self.subscribeHRS()
        self.subscribeDIS()
        self.subscribeOTA()

		self.name		= name
		self.id			= id
		self.peripheral	= peripheral
		self.centralManager = centralManager
		self.type = type
		self.discovery_type = discoveryType
		self.commandQ = CommandQ(peripheral)
	}
	#else
	convenience public init(_ name: String, id: String, centralManager: CBCentralManager?, peripheral: CBPeripheral?, discoveryType: biostrapDeviceSDK.biostrapDiscoveryType) {
		self.init()
		
        self.subscribeMainCharacteristic()
        self.subScribeCustomService()
        self.subscribeBAS()
        self.subscribeHRS()
        self.subscribeDIS()
        self.subscribeOTA()

		self.name		= name
		self.id			= id
		self.peripheral	= peripheral
		self.centralManager = centralManager
		self.discovery_type = discoveryType
		self.commandQ = CommandQ(peripheral)        
	}
	#endif
	
	#if UNIVERSAL || ALTER
	internal var mAlterConfigured: Bool {
        //globals.log.e ("\(mAmbiqOTAService.pConfigured):\(mBAS.pConfigured):\(mHRS.pConfigured):\(mDIS.isConfigured),\(mMainCharacteristic.configured):\(mStreamingCharacteristic.configured):\(mDataCharacteristic.configured)")
			
        return (mBAS.pConfigured &&
                mHRS.pConfigured &&
                mDIS.pConfigured &&
                mAmbiqOTAService.pConfigured &&
                mCustomService.pConfigured &&
                mMainCharacteristic.configured
        )
	}
	#endif

	#if UNIVERSAL || KAIROS
	internal var mKairosConfigured: Bool {
        return (mBAS.pConfigured &&
                mHRS.pConfigured &&
                mDIS.pConfigured &&
                mAmbiqOTAService.pConfigured &&
                mCustomService.pConfigured &&
                mMainCharacteristic.configured
        )
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
	public func writeEpoch(_ newEpoch: Int) {
        if preview {
            self.epoch = newEpoch
            self.writeEpochComplete.send(previewCommandStatus)
            return
        }

        mMainCharacteristic.writeEpoch(newEpoch)
	}

	//--------------------------------------------------------------------------------
	// Function Name: readEpoch
	//--------------------------------------------------------------------------------
	//
	// Two ways to get here - one is from the SDK wrapper (internal), and one is
	// directly (public).
	//
	//--------------------------------------------------------------------------------
	public func readEpoch() {
        if preview {
            self.readEpochComplete.send(previewCommandStatus)
            return
        }
        
        mMainCharacteristic.readEpoch()
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	public func endSleep() {
        if preview {
            self.endSleepComplete.send(previewCommandStatus)
            self.endSleepStatus.send(true)
            return
        }
        
        mMainCharacteristic.endSleep()
	}


	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	public func getAllPackets(pages: Int, delay: Int) {
        if preview {
            self.getAllPacketsComplete.send(previewCommandStatus)
            return
        }
        
		var newStyle	= false
		
        if (mDIS.bluetoothRevisionGreaterThan("2.0.4")) {
            globals.log.v ("Bluetooth library version: '\(bluetoothSoftwareRevision ?? "unknown")' - Use new style")
            newStyle    = true
        }
        else {
            globals.log.v ("Bluetooth library version: '\(bluetoothSoftwareRevision ?? "unknown")' - Use old style")
        }

        mMainCharacteristic.getAllPackets(pages: pages, delay: delay, newStyle: newStyle)
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	public func getAllPacketsAcknowledge(_ ack: Bool) {
        if preview {
            self.getAllPacketsAcknowledgeComplete.send((previewCommandStatus, ack))
            return
        }
        
        mMainCharacteristic.getAllPacketsAcknowledge(ack)
	}
	
	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	public func getPacketCount() {
        if preview {
            self.getPacketCountComplete.send((previewCommandStatus, 0))
            return
        }
        
        mMainCharacteristic.getPacketCount()
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	public func disableWornDetect() {
        if preview {
            self.disableWornDetectComplete.send(previewCommandStatus)
            return
        }
        
        mMainCharacteristic.disableWornDetect()
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	public func enableWornDetect() {
        if preview {
            self.enableWornDetectComplete.send(previewCommandStatus)
            return
        }
        
        mMainCharacteristic.enableWornDetect()
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	public func startManual(_ algorithms: ppgAlgorithmConfiguration) {
        if preview {
            self.startManualComplete.send(previewCommandStatus)
            return
        }
        
        mMainCharacteristic.startManual(algorithms)
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	public func stopManual() {
        if preview {
            self.stopManualComplete.send(previewCommandStatus)
            return
        }
        
        mMainCharacteristic.stopManual()
	}

    //--------------------------------------------------------------------------------
    // Function Name:
    //--------------------------------------------------------------------------------
    //
    //
    //
    //--------------------------------------------------------------------------------
	public func userLED(red: Bool, green: Bool, blue: Bool, blink: Bool, seconds: Int) {
        if preview {
            self.ledComplete.send(previewCommandStatus)
            return
        }
        
        mMainCharacteristic.userLED(red: red, green: green, blue: blue, blink: blink, seconds: seconds)
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	public func enterShipMode() {
        if preview {
            self.enterShipModeComplete.send(previewCommandStatus)
            return
        }
        
        mMainCharacteristic.enterShipMode()
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	public func reset() {
        if preview {
            self.resetComplete.send(previewCommandStatus)
            return
        }
        
        mMainCharacteristic.reset()
	}
	
	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	public func airplaneMode() {
        if preview {
            self.airplaneModeComplete.send(previewCommandStatus)
            return
        }
        
        mMainCharacteristic.airplaneMode()
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	public func writeSerialNumber(_ partID: String) {
        if preview {
            self.serialNumber = partID
            self.writeSerialNumberComplete.send(previewCommandStatus)
            return
        }
        
        mMainCharacteristic.writeSerialNumber(partID)
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	public func readSerialNumber() {
        if preview {
            self.readSerialNumberComplete.send(previewCommandStatus)
            return
        }
        
        mMainCharacteristic.readSerialNumber()
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	public func deleteSerialNumber() {
        if preview {
            self.serialNumber = nil
            self.deleteSerialNumberComplete.send(previewCommandStatus)
            return
        }
        
        mMainCharacteristic.deleteSerialNumber()
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	public func writeAdvInterval(_ seconds: Int) {
        if preview {
            self.advertisingInterval = seconds
            self.writeAdvIntervalComplete.send(previewCommandStatus)
            return
        }
        
        mMainCharacteristic.writeAdvInterval(seconds)
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	public func readAdvInterval() {
        if preview {
            self.readAdvIntervalComplete.send(previewCommandStatus)
            return
        }
        
        mMainCharacteristic.readAdvInterval()
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	public func deleteAdvInterval() {
        if preview {
            self.advertisingInterval = nil
            self.deleteAdvIntervalComplete.send(previewCommandStatus)
            return
        }
        
        mMainCharacteristic.deleteAdvInterval()
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	public func clearChargeCycles() {
        if preview {
            self.chargeCycles = 0.0
            self.clearChargeCyclesComplete.send(previewCommandStatus)
            return
        }
        
        mMainCharacteristic.clearChargeCycles()
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	public func readChargeCycles() {
        if preview {
            self.readChargeCyclesComplete.send(previewCommandStatus)
            return
        }
        
        mMainCharacteristic.readChargeCycles()
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	public func readCanLogDiagnostics() {
        if preview {
            self.readCanLogDiagnosticsComplete.send(previewCommandStatus)
            return
        }
            
        mMainCharacteristic.readCanLogDiagnostics()
	}
	
	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	public func updateCanLogDiagnostics(_ allow: Bool) {
        if preview {
            self.canLogDiagnostics = allow
            self.updateCanLogDiagnosticsComplete.send(previewCommandStatus)
            return
        }

        mMainCharacteristic.updateCanLogDiagnostics(allow)
	}
		
	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	#if UNIVERSAL || ALTER
	public func alterManufacturingTest(_ test: alterManufacturingTestType) {
        if preview {
            self.manufacturingTestComplete.send(previewCommandStatus)
            if previewCommandStatus == .successful {
                self.previewSendAlterTestResult(test)
            }
            return
        }
        
        mMainCharacteristic.alterManufacturingTest(test)
	}
	#endif

	#if UNIVERSAL || KAIROS
	public func kairosManufacturingTest(_ test: kairosManufacturingTestType) {
        if preview {
            self.manufacturingTestComplete.send(previewCommandStatus)
            if previewCommandStatus == .successful {
                self.previewSendKairosTestResult(test)
            }
            return
        }

        mMainCharacteristic.kairosManufacturingTest(test)
	}
	#endif

	//--------------------------------------------------------------------------------
	// Function Name: setAskForButtonResponse
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	public func setAskForButtonResponse(_ enable: Bool) {
        if preview {
            self.buttonResponseEnabled = enable
            self.setAskForButtonResponseComplete.send(previewCommandStatus)
            return
        }

        mMainCharacteristic.setAskForButtonResponse(enable)
	}
	
	//--------------------------------------------------------------------------------
	// Function Name: getAskForButtonResponse
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	public func getAskForButtonResponse() {
        if preview {
            self.getAskForButtonResponseComplete.send(previewCommandStatus)
            return
        }

        mMainCharacteristic.getAskForButtonResponse()
	}
	
	//--------------------------------------------------------------------------------
	// Function Name: setHRZoneColor
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
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
        
        mMainCharacteristic.setHRZoneColor(type, red: red, green: green, blue: blue, on_milliseconds: on_milliseconds, off_milliseconds: off_milliseconds)
	}

	//--------------------------------------------------------------------------------
	// Function Name: getHRZoneColor
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	public func getHRZoneColor(_ type: hrZoneRangeType) {
        if preview {
            self.getHRZoneColorComplete.send((previewCommandStatus, type))
            return
        }

        mMainCharacteristic.getHRZoneColor(type)
	}
	
	//--------------------------------------------------------------------------------
	// Function Name: setHRZoneRange
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	public func setHRZoneRange(_ enabled: Bool, high_value: Int, low_value: Int) {
        if preview {
            self.hrZoneRange = hrZoneRangeValueType(enabled: enabled, lower: low_value, upper: high_value)
            self.setHRZoneRangeComplete.send(previewCommandStatus)
            return
        }
        
        mMainCharacteristic.setHRZoneRange(enabled, high_value: high_value, low_value: low_value)
	}
	
	//--------------------------------------------------------------------------------
	// Function Name: getHRZoneRange
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	public func getHRZoneRange() {
        if preview {
            self.getHRZoneRangeComplete.send(previewCommandStatus)
            return
        }

        mMainCharacteristic.getHRZoneRange()
	}
	
	//--------------------------------------------------------------------------------
	// Function Name: getPPGAlgorithm
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	public func getPPGAlgorithm() {
        if preview {
            self.getPPGAlgorithmComplete.send((previewCommandStatus, ppgAlgorithmConfiguration(), eventType.unknown))
            return
        }

        mMainCharacteristic.getPPGAlgorithm()
	}

	//--------------------------------------------------------------------------------
	// Function Name: setAdvertiseAsHRM
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	public func setAdvertiseAsHRM(_ asHRM: Bool) {
        if preview {
            self.advertiseAsHRM = asHRM
            self.setAdvertiseAsHRMComplete.send(previewCommandStatus)
            return
        }
        
        mMainCharacteristic.setAdvertiseAsHRM(asHRM)
	}

	//--------------------------------------------------------------------------------
	// Function Name: getAdvertiseAsHRM
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	public func getAdvertiseAsHRM() {
        if preview {
            self.getAdvertiseAsHRMComplete.send(previewCommandStatus)
            return
        }
        
        mMainCharacteristic.getAdvertiseAsHRM()
	}

	//--------------------------------------------------------------------------------
	// Function Name: setButtonCommand
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
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
        
        mMainCharacteristic.setButtonCommand(tap, command: command)
	}

	//--------------------------------------------------------------------------------
	// Function Name: getButtonCommand
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	public func getButtonCommand(_ tap: buttonTapType) {
        if preview {
            self.getButtonCommandComplete.send((previewCommandStatus, tap))
            return
        }
        
        mMainCharacteristic.getButtonCommand(tap)
	}
	
	//--------------------------------------------------------------------------------
	// Function Name: setPaired
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	public func setPaired() {
        mMainCharacteristic.setPaired()
	}

	//--------------------------------------------------------------------------------
	// Function Name: setUnpaired
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	public func setUnpaired() {
        mMainCharacteristic.setUnpaired()
	}
	
	//--------------------------------------------------------------------------------
	// Function Name: getPaired
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	public func getPaired() {
        mMainCharacteristic.getPaired()
	}
	
	//--------------------------------------------------------------------------------
	// Function Name: setPaired
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	public func setPageThreshold(_ threshold: Int) {
        if preview {
            self.advertisingPageThreshold = threshold
            self.setPageThresholdComplete.send(previewCommandStatus)
            return
        }

        mMainCharacteristic.setPageThreshold(threshold)
	}
	
	//--------------------------------------------------------------------------------
	// Function Name: setUnpaired
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	public func getPageThreshold() {
        if preview {
            self.getPageThresholdComplete.send(previewCommandStatus)
            return
        }

        mMainCharacteristic.getPageThreshold()
	}
	
	//--------------------------------------------------------------------------------
	// Function Name: getPaired
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	public func deletePageThreshold() {
        if preview {
            self.advertisingPageThreshold = nil
            self.deletePageThresholdComplete.send(previewCommandStatus)
            return
        }

        mMainCharacteristic.deletePageThreshold()
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	public func rawLogging(_ enable: Bool) {
        if preview {
            self.rawLoggingComplete.send(previewCommandStatus)
            return
        }

        mMainCharacteristic.rawLogging(enable)
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	public func wornCheck() {
        if preview {
            self.wornCheckResult = DeviceWornCheckResultType(code: "Preview", value: 0)
            self.wornCheckResultComplete.send(previewCommandStatus)
            return
        }
        
        mMainCharacteristic.wornCheck()
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	public func getRawLoggingStatus() {
        if preview {
            self.getRawLoggingStatusComplete.send(previewCommandStatus)
            return
        }
        
        mMainCharacteristic.getRawLoggingStatus()
	}
	
	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	public func getWornOverrideStatus() {
        if preview {
            self.getWornOverrideStatusComplete.send(previewCommandStatus)
        }
        
        mMainCharacteristic.getWornOverrideStatus()
	}
	
	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
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
        
        do {
            let contents = try Data(contentsOf: file)
            mAmbiqOTAService.start(contents)
        }
        catch {
            globals.log.e ("Cannot open file")
            DispatchQueue.main.async {
                self.updateFirmwareFailed.send((10001, "Cannot parse file for update"))
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
	public func cancelFirmwareUpdate() {
        if preview {
            self.previewFirmwareTimer?.invalidate()
            self.previewFirmwareProgress = 0.0
            self.updateFirmwareFailed.send((10001, "User cancelled"))
            return
        }
        
		mAmbiqOTAService.cancel()
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
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

        mMainCharacteristic.setSessionParam(parameter, value: value)
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	public func getSessionParam(_ parameter: sessionParameterType) {
        if preview {
            self.getSessionParamComplete.send((previewCommandStatus, parameter))
        }

        mMainCharacteristic.getSessionParam(parameter)
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	public func resetSessionParams() {
        if preview {
            self.previewTag = self.tag
            self.previewPPGCapturePeriod = self.ppgCapturePeriod
            self.previewPPGCaptureDuration = self.ppgCaptureDuration
            self.resetSessionParamsComplete.send(previewCommandStatus)
        }

        mMainCharacteristic.resetSessionParams()
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	public func acceptSessionParams() {
        if preview {
            self.tag = self.previewTag
            self.ppgCapturePeriod = self.previewPPGCapturePeriod
            self.ppgCaptureDuration = self.previewPPGCaptureDuration
            self.acceptSessionParamsComplete.send(previewCommandStatus)
        }

        mMainCharacteristic.acceptSessionParams()
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
	private func subscribeMainCharacteristic() {
		mMainCharacteristic.writeEpochComplete
            .receive(on: DispatchQueue.main)
            .sink { status in
                self.lambdaWriteEpochComplete?(self.id, status.successful)
				self.writeEpochComplete.send(status)
			}
            .store(in: &subscriptions)
		
		mMainCharacteristic.readEpochComplete
            .receive(on: DispatchQueue.main)
            .sink { status, value in
                self.lambdaReadEpochComplete?(self.id, status.successful,  value)
				self.epoch = value
				self.readEpochComplete.send(status)
			}
            .store(in: &subscriptions)
		
		mMainCharacteristic.deviceWornStatus
            .receive(on: DispatchQueue.main)
            .sink { isWorn in
				self.lambdaWornStatus?(self.id, isWorn)
				self.worn = isWorn
			}
            .store(in: &subscriptions)
		
		mMainCharacteristic.deviceChargingStatus
            .receive(on: DispatchQueue.main)
            .sink { charging, on_charger, error in
				self.lambdaChargingStatus?(self.id, charging, on_charger, error)
				self.charging = charging
				self.on_charger = on_charger
				self.charge_error = error
			}
            .store(in: &subscriptions)

		mMainCharacteristic.startManualComplete
            .receive(on: DispatchQueue.main)
            .sink { status in
                self.lambdaStartManualComplete?(self.id, status.successful)
				self.startManualComplete.send(status)
			}
            .store(in: &subscriptions)
		
		mMainCharacteristic.stopManualComplete
            .receive(on: DispatchQueue.main)
            .sink { status in
                self.lambdaStopManualComplete?(self.id, status.successful)
                self.stopManualComplete.send(status)
            }
            .store(in: &subscriptions)
		
		mMainCharacteristic.ledComplete
            .receive(on: DispatchQueue.main)
            .sink { status in
                self.lambdaLEDComplete?(self.id, status.successful)
				self.ledComplete.send(status)
			}
            .store(in: &subscriptions)
		
		mMainCharacteristic.getRawLoggingStatusComplete
            .receive(on: DispatchQueue.main)
            .sink { status, enabled in
                self.lambdaGetRawLoggingStatusComplete?(self.id, status.successful, enabled)
                if status.successful {
					self.rawLogging = enabled
				} else {
					self.rawLogging = nil
				}
				self.getRawLoggingStatusComplete.send(status)
			}
            .store(in: &subscriptions)
        
		mMainCharacteristic.getWornOverrideStatusComplete
            .receive(on: DispatchQueue.main)
            .sink { status, overridden in
                self.lambdaGetWornOverrideStatusComplete?(self.id, status.successful, overridden)
                if status.successful {
					self.wornOverridden = overridden
				} else {
					self.wornOverridden = nil
				}
				self.getWornOverrideStatusComplete.send(status)
			}
            .store(in: &subscriptions)

		mMainCharacteristic.writeSerialNumberComplete
            .receive(on: DispatchQueue.main)
            .sink { status in
                self.lamdaWriteSerialNumberComplete?(self.id, status.successful)
				self.writeSerialNumberComplete.send(status)
			}
            .store(in: &subscriptions)

		mMainCharacteristic.readSerialNumberComplete
            .receive(on: DispatchQueue.main)
            .sink { status, partID in
            	self.lambdaReadSerialNumberComplete?(self.id, status.successful, partID)
                if status.successful { self.serialNumber = partID }
				self.readSerialNumberComplete.send(status)
			}
            .store(in: &subscriptions)

		mMainCharacteristic.deleteSerialNumberComplete
            .receive(on: DispatchQueue.main)
            .sink { status in
            	self.lambdaDeleteSerialNumberComplete?(self.id, status.successful)
				self.deleteSerialNumberComplete.send(status)
			}
            .store(in: &subscriptions)

		mMainCharacteristic.writeAdvIntervalComplete
            .receive(on: DispatchQueue.main)
            .sink { status in
	            self.lambdaWriteAdvIntervalComplete?(self.id, status.successful)
				self.writeAdvIntervalComplete.send(status)
			}
            .store(in: &subscriptions)

		mMainCharacteristic.readAdvIntervalComplete
            .receive(on: DispatchQueue.main)
            .sink { status, seconds in
                self.lambdaReadAdvIntervalComplete?(self.id, status.successful, seconds)
				self.advertisingInterval = seconds
				self.readAdvIntervalComplete.send(status)
			}
            .store(in: &subscriptions)
		
		mMainCharacteristic.deleteAdvIntervalComplete
            .receive(on: DispatchQueue.main)
            .sink { status in
                self.lambdaDeleteAdvIntervalComplete?(self.id, status.successful)
                if status.successful { self.advertisingInterval = nil }
				self.deleteAdvIntervalComplete.send(status)
			}
            .store(in: &subscriptions)

		mMainCharacteristic.clearChargeCyclesComplete
            .receive(on: DispatchQueue.main)
            .sink { status in
                self.lambdaClearChargeCyclesComplete?(self.id, status.successful)
                if status.successful { self.chargeCycles = nil }
				self.clearChargeCyclesComplete.send(status)
			}
            .store(in: &subscriptions)

		mMainCharacteristic.readChargeCyclesComplete
            .receive(on: DispatchQueue.main)
            .sink { status, cycles in
                self.lambdaReadChargeCyclesComplete?(self.id, status.successful, cycles)
				self.chargeCycles = cycles
				self.readChargeCyclesComplete.send(status)
			}
            .store(in: &subscriptions)

		mMainCharacteristic.setAdvertiseAsHRMComplete
            .receive(on: DispatchQueue.main)
            .sink { status, asHRM in
                self.lambdaSetAdvertiseAsHRMComplete?(self.id, status.successful, asHRM)
                if status.successful {
					self.advertiseAsHRM = asHRM
				} else {
					self.advertiseAsHRM = nil
				}
				self.setAdvertiseAsHRMComplete.send(status)
			}
            .store(in: &subscriptions)
    
		mMainCharacteristic.getAdvertiseAsHRMComplete
            .receive(on: DispatchQueue.main)
            .sink { status, asHRM in
                self.lambdaGetAdvertiseAsHRMComplete?(self.id, status.successful, asHRM)
                if status.successful {
					self.advertiseAsHRM = asHRM
				} else {
					self.advertiseAsHRM = nil
				}
				self.getAdvertiseAsHRMComplete.send(status)
			}
            .store(in: &subscriptions)

		mMainCharacteristic.setButtonCommandComplete
            .receive(on: DispatchQueue.main)
            .sink { status, tap, command in
				self.lambdaSetButtonCommandComplete?(self.id, status.successful, tap, command)
				switch tap {
				case .single: self.singleButtonPressAction = status.successful ? command : nil
				case .double: self.doubleButtonPressAction = status.successful ? command : nil
				case .triple: self.tripleButtonPressAction = status.successful ? command : nil
				case .long: self.longButtonPressAction = status.successful ? command : nil
				default: break
				}
				self.setButtonCommandComplete.send((status, tap))
			}
            .store(in: &subscriptions)
        
		mMainCharacteristic.getButtonCommandComplete
            .receive(on: DispatchQueue.main)
            .sink { status, tap, command in
                self.lambdaGetButtonCommandComplete?(self.id, status.successful, tap, command)
				switch tap {
                case .single: self.singleButtonPressAction = status.successful ? command : nil
                case .double: self.doubleButtonPressAction = status.successful ? command : nil
                case .triple: self.tripleButtonPressAction = status.successful ? command : nil
                case .long: self.longButtonPressAction = status.successful ? command : nil
				default: break
				}
				self.getButtonCommandComplete.send((status, tap))
			}
            .store(in: &subscriptions)
		
		mMainCharacteristic.setAskForButtonResponseComplete
            .receive(on: DispatchQueue.main)
            .sink { status, enable in
                self.lambdaSetAskForButtonResponseComplete?(self.id, status.successful, enable)
                if status.successful {
					self.buttonResponseEnabled = enable
				} else {
					self.buttonResponseEnabled = false
				}
				self.setAskForButtonResponseComplete.send(status)
			}
            .store(in: &subscriptions)
		
		mMainCharacteristic.getAskForButtonResponseComplete
            .receive(on: DispatchQueue.main)
            .sink { status, enable in
                self.lambdaGetAskForButtonResponseComplete?(self.id, status.successful, enable)
                if status.successful {
					self.buttonResponseEnabled = enable
				} else {
					self.buttonResponseEnabled = false
				}
				self.getAskForButtonResponseComplete.send(status)
			}
            .store(in: &subscriptions)
		
		mMainCharacteristic.setHRZoneColorComplete
            .receive(on: DispatchQueue.main)
            .sink { status, type in
                self.lambdaSetHRZoneColorComplete?(self.id, status.successful, type)
				self.setHRZoneColorComplete.send((status, type))
			}
            .store(in: &subscriptions)
		
		mMainCharacteristic.getHRZoneColorComplete
            .receive(on: DispatchQueue.main)
            .sink { status, type, red, green, blue, on_ms, off_ms in
                self.lambdaGetHRZoneColorComplete?(self.id, status.successful, type, red, green, blue, on_ms, off_ms)
				switch (type) {
				case .below: self.hrZoneLEDBelow = hrZoneLEDValueType(red: red, green: green, blue: blue, on_ms: on_ms, off_ms: off_ms)
				case .within: self.hrZoneLEDWithin = hrZoneLEDValueType(red: red, green: green, blue: blue, on_ms: on_ms, off_ms: off_ms)
				case .above: self.hrZoneLEDAbove = hrZoneLEDValueType(red: red, green: green, blue: blue, on_ms: on_ms, off_ms: off_ms)
				default: break
				}
				self.getHRZoneColorComplete.send((status, type))
			}
            .store(in: &subscriptions)
		
		mMainCharacteristic.setHRZoneRangeComplete
            .receive(on: DispatchQueue.main)
            .sink { status in
                self.lambdaSetHRZoneRangeComplete?(self.id, status.successful)
				self.setHRZoneRangeComplete.send(status)
			}
            .store(in: &subscriptions)
		
		mMainCharacteristic.getHRZoneRangeComplete
            .receive(on: DispatchQueue.main)
            .sink { status, enabled, high_value, low_value in
                self.lambdaGetHRZoneRangeComplete?(self.id, status.successful, enabled, high_value, low_value)
                if status.successful {
					self.hrZoneRange = hrZoneRangeValueType(enabled: enabled, lower: low_value, upper: high_value)
				}
				self.getHRZoneRangeComplete.send(status)
			}
            .store(in: &subscriptions)
		
		mMainCharacteristic.getPPGAlgorithmComplete
            .receive(on: DispatchQueue.main)
            .sink { status, algorithm, state in
                self.lambdaGetPPGAlgorithmComplete?(self.id, status.successful, algorithm, state)
				self.getPPGAlgorithmComplete.send((status, algorithm, state))
			}
            .store(in: &subscriptions)
		
		mMainCharacteristic.endSleepComplete
            .receive(on: DispatchQueue.main)
            .sink { status in
                self.lambdaEndSleepComplete?(self.id, status.successful)
				self.endSleepComplete.send(status)
			}
            .store(in: &subscriptions)
		
		mMainCharacteristic.endSleepStatus
            .receive(on: DispatchQueue.main)
            .sink { enable in
				self.lambdaEndSleepStatus?(self.id, enable)
				self.endSleepStatus.send(enable)
			}
            .store(in: &subscriptions)

		mMainCharacteristic.disableWornDetectComplete
            .receive(on: DispatchQueue.main)
            .sink { status in
                self.lambdaDisableWornDetectComplete?(self.id, status.successful)
				self.disableWornDetectComplete.send(status)
			}
            .store(in: &subscriptions)

		mMainCharacteristic.enableWornDetectComplete
            .receive(on: DispatchQueue.main)
            .sink { status in
                self.lambdaEnableWornDetectComplete?(self.id, status.successful)
				self.enableWornDetectComplete.send(status)
			}
            .store(in: &subscriptions)
		
		mMainCharacteristic.buttonClicked
            .receive(on: DispatchQueue.main)
            .sink { presses in
				self.lambdaButtonClicked?(self.id, presses)
				self.buttonTaps = presses
			}
            .store(in: &subscriptions)

		mMainCharacteristic.wornCheckComplete
            .receive(on: DispatchQueue.main)
            .sink { status, code, value in
                self.lambdaWornCheckComplete?(self.id, status.successful, code, value )
				self.wornCheckResult = DeviceWornCheckResultType(code: code, value: value)
				self.wornCheckResultComplete.send(status)
			}
            .store(in: &subscriptions)
		
		mMainCharacteristic.setSessionParamComplete
            .receive(on: DispatchQueue.main)
            .sink { status, parameter in
                self.lambdaSetSessionParamComplete?(self.id, status.successful, parameter)
				self.setSessionParamComplete.send((status, parameter))
			}
            .store(in: &subscriptions)
		
		mMainCharacteristic.getSessionParamComplete
            .receive(on: DispatchQueue.main)
            .sink { status, parameter, value in
                self.lambdaGetSessionParamComplete?(self.id, status.successful, parameter, value)
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
				self.getSessionParamComplete.send((status, parameter))
			}
            .store(in: &subscriptions)
		
		mMainCharacteristic.acceptSessionParamsComplete
            .receive(on: DispatchQueue.main)
            .sink { status in
                self.lambdaAcceptSessionParamsComplete?(self.id, status.successful)
				self.acceptSessionParamsComplete.send(status)
			}
            .store(in: &subscriptions)
		
		mMainCharacteristic.resetSessionParamsComplete
            .receive(on: DispatchQueue.main)
            .sink { status in
                self.lambdaResetSessionParamsComplete?(self.id, status.successful)
				self.resetSessionParamsComplete.send(status)
			}
            .store(in: &subscriptions)
		
		mMainCharacteristic.readCanLogDiagnosticsComplete
            .receive(on: DispatchQueue.main)
            .sink { status, allow in
                self.lambdaReadCanLogDiagnosticsComplete?(self.id, status.successful, allow)
				self.canLogDiagnostics = allow
				self.readCanLogDiagnosticsComplete.send(status)
			}
            .store(in: &subscriptions)
		
		mMainCharacteristic.updateCanLogDiagnosticsComplete
            .receive(on: DispatchQueue.main)
            .sink { status in
                self.lambdaUpdateCanLogDiagnosticsComplete?(self.id, status.successful)
				self.updateCanLogDiagnosticsComplete.send(status)
			}
            .store(in: &subscriptions)
		
		mMainCharacteristic.getPacketCountComplete
            .receive(on: DispatchQueue.main)
            .sink { status, count in
                self.lambdaGetPacketCountComplete?(self.id, status.successful, count)
				self.getPacketCountComplete.send((status, count))
			}
            .store(in: &subscriptions)
		
		mMainCharacteristic.getAllPacketsComplete
            .receive(on: DispatchQueue.main)
            .sink { status in
                self.lambdaGetAllPacketsComplete?(self.id, status.successful)
				self.getAllPacketsComplete.send(status)
			}
            .store(in: &subscriptions)
		
		mMainCharacteristic.getAllPacketsAcknowledgeComplete
            .receive(on: DispatchQueue.main)
            .sink { status, ack in
                self.lambdaGetAllPacketsAcknowledgeComplete?(self.id, status.successful, ack)
				self.getAllPacketsAcknowledgeComplete.send((status, ack))
			}
            .store(in: &subscriptions)
		
		mMainCharacteristic.setPairedComplete
            .receive(on: DispatchQueue.main)
            .sink { status in
                self.lambdaSetPairedComplete?(self.id, status.successful)
				self.setPairedComplete.send(status)
			}
            .store(in: &subscriptions)
		
		mMainCharacteristic.setUnpairedComplete
            .receive(on: DispatchQueue.main)
            .sink { status in
                self.lambdaSetUnpairedComplete?(self.id, status.successful)
				self.setUnpairedComplete.send(status)
			}
            .store(in: &subscriptions)

		mMainCharacteristic.getPairedComplete
            .receive(on: DispatchQueue.main)
            .sink { status, paired in
                self.lambdaGetPairedComplete?(self.id, status.successful, paired)
                if status.successful {
					self.paired = paired
				} else {
					self.paired = nil
				}
				self.getPairedComplete.send(status)
			}
            .store(in: &subscriptions)
		
		mMainCharacteristic.setPageThresholdComplete
            .receive(on: DispatchQueue.main)
            .sink { status in
                self.lambdaSetPageThresholdComplete?(self.id, status.successful)
				self.setPageThresholdComplete.send(status)
			}
            .store(in: &subscriptions)

		mMainCharacteristic.getPageThresholdComplete
            .receive(on: DispatchQueue.main)
            .sink { status, threshold in
                self.lambdaGetPageThresholdComplete?(self.id, status.successful, threshold)
                if status.successful {
					self.advertisingPageThreshold = threshold
				} else {
					self.advertisingPageThreshold = nil
				}
                self.getPageThresholdComplete.send(status)
			}
            .store(in: &subscriptions)

		mMainCharacteristic.deletePageThresholdComplete
            .receive(on: DispatchQueue.main)
            .sink { status in
                self.lambdaDeletePageThresholdComplete?(self.id, status.successful)
				self.deletePageThresholdComplete.send(status)
			}
            .store(in: &subscriptions)

		mMainCharacteristic.enterShipModeComplete
            .receive(on: DispatchQueue.main)
            .sink { status in
                self.lambdaEnterShipModeComplete?(self.id, status.successful)
				self.enterShipModeComplete.send(status)
			}
            .store(in: &subscriptions)
		
		mMainCharacteristic.resetComplete
            .receive(on: DispatchQueue.main)
            .sink { status in
                self.lambdaResetComplete?(self.id, status.successful)
				self.resetComplete.send(status)
			}
            .store(in: &subscriptions)
		
		mMainCharacteristic.airplaneModeComplete
            .receive(on: DispatchQueue.main)
            .sink { status in
                self.lambdaAirplaneModeComplete?(self.id, status.successful)
				self.airplaneModeComplete.send(status)
			}
            .store(in: &subscriptions)
		
		mMainCharacteristic.manufacturingTestComplete
            .receive(on: DispatchQueue.main)
            .sink { status in
                self.lambdaManufacturingTestComplete?(self.id, status.successful)
				self.manufacturingTestComplete.send(status)
			}
            .store(in: &subscriptions)

		mMainCharacteristic.rawLoggingComplete
            .receive(on: DispatchQueue.main)
            .sink { status in
                self.lambdaRawLoggingComplete?(self.id, status.successful)
				self.rawLoggingComplete.send(status)
			}
            .store(in: &subscriptions)
		
		// MARK: Notifications
		mMainCharacteristic.manufacturingTestResult
            .receive(on: DispatchQueue.main)
            .sink { valid, result in
				self.lambdaManufacturingTestResult?(self.id, valid, result)
				self.manufacturingTestResult.send((valid, result))
			}
            .store(in: &subscriptions)

		mMainCharacteristic.ppgMetrics
            .receive(on: DispatchQueue.main)
            .sink { successful, packet in
				self.lambdaPPGMetrics?(self.id, successful, packet)
				self.ppgMetrics = ppgMetricsType(packet)
			}
            .store(in: &subscriptions)
		
		mMainCharacteristic.ppgFailed
            .receive(on: DispatchQueue.main)
            .sink { code in
				self.lambdaPPGFailed?(self.id, code)
				self.ppgFailed.send(code)
			}
            .store(in: &subscriptions)
		
        // Do not push to main dispatch queue
		mMainCharacteristic.dataPackets
            .sink { sequence_number, packets in
                self.lambdaDataPackets?(self.id, sequence_number, packets)
                self.dataPackets.send((sequence_number, packets))
			}
            .store(in: &subscriptions)

		mMainCharacteristic.dataComplete
            .receive(on: DispatchQueue.main)
            .sink { bad_fw_read_count, bad_fw_parse_count, overflow_count, bad_sdk_parse_count, intermediate in
				self.lambdaDataComplete?(self.id, bad_fw_read_count, bad_fw_parse_count, overflow_count, bad_sdk_parse_count, intermediate)
				self.dataComplete.send((bad_fw_read_count, bad_fw_parse_count, overflow_count, bad_sdk_parse_count, intermediate))
			}
            .store(in: &subscriptions)

		mMainCharacteristic.dataFailure
            .sink { self.lambdaDataFailure?(self.id) }
            .store(in: &subscriptions)
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	private func subScribeCustomService() {
        
        // Do not push to main dispatch queue
        mCustomService.dataPackets
            .sink { sequence_number, packets in
				self.lambdaDataPackets?(self.id, sequence_number, packets)
				self.dataPackets.send((sequence_number, packets))
			}
            .store(in: &subscriptions)
		
        mCustomService.dataComplete
            .receive(on: DispatchQueue.main)
            .sink {bad_fw_read_count, bad_fw_parse_count, overflow_count, bad_sdk_parse_count, intermediate in
				self.lambdaDataComplete?(self.id, bad_fw_read_count, bad_fw_parse_count, overflow_count, bad_sdk_parse_count, intermediate)
				self.dataComplete.send((bad_fw_read_count, bad_fw_parse_count, overflow_count, bad_sdk_parse_count, intermediate))
			}
            .store(in: &subscriptions)

        mCustomService.$worn
            .receive(on: DispatchQueue.main)
            .sink { worn in
                if let worn {
                    self.lambdaWornStatus?(self.id, worn)
                }
                self.worn = worn
            }
            .store(in: &subscriptions)
    
        Publishers.CombineLatest3(mCustomService.$charging, mCustomService.$on_charger, mCustomService.$charge_error)
	        .receive(on: DispatchQueue.main)
	        .sink { charging, on_charger, charge_error in
                if let charging, let on_charger, let charge_error {
                    self.lambdaChargingStatus?(self.id, charging, on_charger, charge_error)
                }
                self.charging = charging
                self.on_charger = on_charger
                self.charge_error = charge_error
	        }
	        .store(in: &subscriptions)
		
        mCustomService.endSleepStatus
            .receive(on: DispatchQueue.main)
            .sink { enable in
				self.lambdaEndSleepStatus?(self.id, enable)
				self.endSleepStatus.send(enable)
			}
            .store(in: &subscriptions)

        mCustomService.$buttonTaps
            .receive(on: DispatchQueue.main)
            .sink { taps in
                if let taps {
                    self.lambdaButtonClicked?(self.id, taps)
                }
				self.buttonTaps = taps
			}
            .store(in: &subscriptions)

        mCustomService.manufacturingTestResult
            .receive(on: DispatchQueue.main)
            .sink { valid, result in
				self.lambdaManufacturingTestResult?(self.id, valid, result)
				self.manufacturingTestResult.send((valid, result))
			}
            .store(in: &subscriptions)
		
        mCustomService.$ppgMetrics
            .receive(on: DispatchQueue.main)
            .sink { metrics in
                if let metrics {
                    let packet = biostrapDataPacket()
                    if let hr = metrics.hr {
                        packet.hr_valid = true
                        packet.hr_result = hr
                    }
                    
                    if let hrv = metrics.hrv {
                        packet.hrv_valid = true
                        packet.hrv_result = hrv
                    }
                    
                    if let rr = metrics.rr {
                        packet.rr_valid = true
                        packet.rr_result = rr
                    }
                    
                    do {
                        let jsonData = try JSONEncoder().encode(packet)
                        if let jsonString = String(data: jsonData, encoding: .utf8) {
                            self.lambdaPPGMetrics?(self.id, true, jsonString)
                        }
                        else { self.lambdaPPGMetrics?(self.id, false, "") }
                    }
                    catch { self.lambdaPPGMetrics?(self.id, false, "") }
                }
				self.ppgMetrics = metrics
			}
            .store(in: &subscriptions)
		
        mCustomService.ppgFailed
            .receive(on: DispatchQueue.main)
            .sink { code in
				self.lambdaPPGFailed?(self.id, code)
				self.ppgFailed.send(code)
			}
            .store(in: &subscriptions)

        mCustomService.streamingPacket
            .receive(on: DispatchQueue.main)
            .sink { packet in
				self.lambdaStreamingPacket?(self.id, packet)
				self.streamingPacket.send(packet)
			}
            .store(in: &subscriptions)

        mCustomService.dataAvailable
            .receive(on: DispatchQueue.main)
            .sink {
                self.lambdaDataAvailable?(self.id)
            }
            .store(in: &subscriptions)
	}
    
    //--------------------------------------------------------------------------------
    // Function Name:
    //--------------------------------------------------------------------------------
    //
    //
    //
    //--------------------------------------------------------------------------------
    func subscribeHRS() {
        mHRS.updated
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] (epoch, hr, rr) in
                self?.heartRateUpdated.send((epoch, hr, rr))
                self?.lambdaHeartRateUpdated?(self!.id, epoch, hr, rr)
            }
            .store(in: &subscriptions)
    }
    
    //--------------------------------------------------------------------------------
    // Function Name:
    //--------------------------------------------------------------------------------
    //
    //
    //
    //--------------------------------------------------------------------------------
    func subscribeBAS() {
        mBAS.$batteryLevel
            .receive(on: DispatchQueue.main)
            .sink { [weak self] level in
                self?.batteryLevel = level
                if let level {
                    self?.lambdaBatteryLevelUpdated?(self!.id, level)
                }
            }
            .store(in: &subscriptions)
    }
    
    //--------------------------------------------------------------------------------
    // Function Name:
    //--------------------------------------------------------------------------------
    //
    //
    //
    //--------------------------------------------------------------------------------
    func subscribeDIS() {
        mDIS.$modelNumber
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.modelNumber = $0 }
            .store(in: &subscriptions)
        
        mDIS.$serialNumber
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.serialNumber = $0 }
            .store(in: &subscriptions)
        
        mDIS.$hardwareRevision
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.hardwareRevision = $0 }
            .store(in: &subscriptions)
        
        mDIS.$manufacturerName
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.manufacturerName = $0 }
            .store(in: &subscriptions)

        mDIS.$firmwareRevision
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.firmwareRevision = $0 }
            .store(in: &subscriptions)

        mDIS.$bluetoothSoftwareRevision
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.bluetoothSoftwareRevision = $0 }
            .store(in: &subscriptions)

        mDIS.$algorithmsSoftwareRevision
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.algorithmsSoftwareRevision = $0 }
            .store(in: &subscriptions)

        mDIS.$sleepSoftwareRevision
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.sleepSoftwareRevision = $0 }
            .store(in: &subscriptions)
    }
    
    //--------------------------------------------------------------------------------
    // Function Name:
    //--------------------------------------------------------------------------------
    //
    //
    //
    //--------------------------------------------------------------------------------
    func subscribeOTA() {
        mAmbiqOTAService.started
            .receive(on: DispatchQueue.main)
            .sink {
                self.updateFirmwareStarted.send()
                self.lambdaUpdateFirmwareStarted?(self.id)
            }
            .store(in: &subscriptions)

        mAmbiqOTAService.finished
            .receive(on: DispatchQueue.main)
            .sink {
                self.updateFirmwareFinished.send()
                self.lambdaUpdateFirmwareFinished?(self.id)
            }
            .store(in: &subscriptions)
        
        mAmbiqOTAService.failed
            .receive(on: DispatchQueue.main)
            .sink { code, message in
                self.updateFirmwareFailed.send((code, message))
                self.lambdaUpdateFirmwareFailed?(self.id, code, message)
            }
            .store(in: &subscriptions)

        mAmbiqOTAService.progress
            .receive(on: DispatchQueue.main)
            .sink { percent in
                self.updateFirmwareProgress.send(percent)
                self.lambdaUpdateFirmwareProgress?(self.id, percent)
            }
            .store(in: &subscriptions)
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
                
                mBAS.didConnect(peripheral)
                mHRS.didConnect(peripheral)
                mDIS.didConnect(peripheral)
                mAmbiqOTAService.didConnect(peripheral)
                mCustomService.didConnect(peripheral)
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
			mBAS.didDiscoverCharacteristic(characteristic, commandQ: commandQ)
            return
        }
        
        if hrsService.hit(characteristic) {
            mHRS.didDiscoverCharacteristic(characteristic, commandQ: commandQ)
            return
        }
        
        if disService.hit(characteristic) {
            mDIS.didDiscoverCharacteristic(characteristic, commandQ: commandQ)
            return
        }
        
        if ambiqOTAService.hit(characteristic) {
            mAmbiqOTAService.didDiscoverCharacteristic(characteristic, commandQ: commandQ)
            return
        }
        
        if customService.hit(characteristic) {
            mCustomService.didDiscoverCharacteristic(characteristic, commandQ: commandQ)
            return
        }
        
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
                mMainCharacteristic.didDiscover(characteristic, commandQ: commandQ)
				#if UNIVERSAL
                mMainCharacteristic.type	= .alter
				#endif
                mMainCharacteristic.discoverDescriptors()
            #endif
                
			#if UNIVERSAL || KAIROS
            case .kairosMainCharacteristic:
                mMainCharacteristic.didDiscover(characteristic, commandQ: commandQ)
				#if UNIVERSAL
                mMainCharacteristic.type	= .kairos
				#endif
                mMainCharacteristic.discoverDescriptors()
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
	
	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func didDiscoverDescriptor (_ descriptor: CBDescriptor, forCharacteristic characteristic: CBCharacteristic) {
        
        if basService.hit(characteristic) {
            mBAS.didDiscoverDescriptor(characteristic)
            return
        }
        
        if hrsService.hit(characteristic) {
            mHRS.didDiscoverDescriptor(characteristic)
            return
        }
        
        if ambiqOTAService.hit(characteristic) {
            mAmbiqOTAService.didDiscoverDescriptor(characteristic)
            return
        }
        
        if customService.hit(characteristic) {
            mCustomService.didDiscoverDescriptor(characteristic)
            return
        }
        
		if let standardDescriptor = org_bluetooth_descriptor(rawValue: descriptor.prettyID) {
			switch (standardDescriptor) {
			case .client_characteristic_configuration:
				if let enumerated = Device.characteristics(rawValue: characteristic.prettyID) {
					globals.log.v ("\(self.id): \(standardDescriptor.title) '\(enumerated.title)'")
					switch (enumerated) {
					#if UNIVERSAL || ALTER
					case .alterMainCharacteristic		: mMainCharacteristic.didDiscoverDescriptor()
					#endif

					#if UNIVERSAL || KAIROS
					case .kairosMainCharacteristic		: mMainCharacteristic.didDiscoverDescriptor()
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
        mCustomService.didUpdateValue(data, offset: offset)
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
            mBAS.didUpdateValue(characteristic)
            return
        }
        
        if hrsService.hit(characteristic) {
            mHRS.didUpdateValue(characteristic)
            return
        }

        if disService.hit(characteristic) {
            mDIS.didUpdateValue(characteristic)
            return
        }
        
        if ambiqOTAService.hit(characteristic) {
            mAmbiqOTAService.didUpdateValue(characteristic)
            return
        }
        
        if customService.hit(characteristic) {
            mCustomService.didUpdateValue(characteristic)
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
			case .alterMainCharacteristic		: mMainCharacteristic.didUpdateValue()
			#endif

			#if UNIVERSAL || KAIROS
			case .kairosMainCharacteristic		: mMainCharacteristic.didUpdateValue()
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
                mBAS.didUpdateNotificationState(characteristic)
                return
            }
            
            if hrsService.hit(characteristic) {
                mHRS.didUpdateNotificationState(characteristic)
                return
            }
            
            if ambiqOTAService.hit(characteristic) {
                mAmbiqOTAService.didUpdateNotificationState(characteristic)
                return
            }
            
            if customService.hit(characteristic) {
                mCustomService.didUpdateNotificationState(characteristic)
                return
            }

            if (characteristic.isNotifying) {
				if let enumerated = Device.characteristics(rawValue: characteristic.prettyID) {
					globals.log.v ("\(self.id): '\(enumerated.title)'")
					
					switch (enumerated) {
					#if UNIVERSAL || ALTER
					case .alterMainCharacteristic			: mMainCharacteristic.didUpdateNotificationState()
					#endif

					#if UNIVERSAL || KAIROS
					case .kairosMainCharacteristic			: mMainCharacteristic.didUpdateNotificationState()
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
		mAmbiqOTAService.isReady()
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
