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
		     
	public enum ConnectionState {
		case disconnected
		case connecting
		case configuring
		case configured
        
        public var title: String {
            switch self {
            case .disconnected: return "Disconnected"
            case .connecting: return "Connecting"
            case .configuring: return "Configuring"
            case .configured: return "Configured"
            }
        }
	}
    
    private enum services {
        case bas
        case dis
        case hrs
        case ota
        case custom
        case unknown(CBUUID)
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

    @Published public private(set) var bodySensorLocation: BodySensorLocation?

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
        return customService.scan_services
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
            } else if ambiqOTAService.scan_services.contains(service.uuid) {
                globals.log.v ("\(peripheral.prettyID): 'Ambiq OTA'")
                return true
            } else {
				globals.log.e ("\(peripheral.prettyID): \(service.prettyID) - don't know what to do!!!!")
				return false
			}
		} else {
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
		
        self.subscribeConfigured()
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
		
        self.subscribeConfigured()
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
    
    //--------------------------------------------------------------------------------
    // Function Name: hit
    //--------------------------------------------------------------------------------
    //
    // Sees which service a characteristic is for
    //
    //--------------------------------------------------------------------------------
    private func hit(_ characteristic: CBCharacteristic) -> services {
        if basService.hit(characteristic) { return .bas }
        if hrsService.hit(characteristic) { return .hrs }
        if disService.hit(characteristic) { return .dis }
        if ambiqOTAService.hit(characteristic) { return .ota }
        if customService.hit(characteristic) { return .custom }
        return .unknown(characteristic.uuid)
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
			} else {
				globals.log.e ("Either do not have a central manager or a peripheral")
			}
		} else {
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
			} else {
				globals.log.e ("Either do not have a central manager or a peripheral")
			}
		} else {
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

        mCustomService.writeEpoch(newEpoch)
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
        
        mCustomService.readEpoch()
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
        
        mCustomService.endSleep()
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
        } else {
            globals.log.v ("Bluetooth library version: '\(bluetoothSoftwareRevision ?? "unknown")' - Use old style")
        }

        mCustomService.getAllPackets(pages: pages, delay: delay, newStyle: newStyle)
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
        
        mCustomService.getAllPacketsAcknowledge(ack)
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
        
        mCustomService.getPacketCount()
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
        
        mCustomService.disableWornDetect()
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
        
        mCustomService.enableWornDetect()
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
        
        mCustomService.startManual(algorithms)
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
        
        mCustomService.stopManual()
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
        
        mCustomService.userLED(red: red, green: green, blue: blue, blink: blink, seconds: seconds)
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
        
        mCustomService.enterShipMode()
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
        
        mCustomService.reset()
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
        
        mCustomService.airplaneMode()
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
        
        mCustomService.writeSerialNumber(partID)
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
        
        mCustomService.readSerialNumber()
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
        
        mCustomService.deleteSerialNumber()
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
        
        mCustomService.writeAdvInterval(seconds)
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
        
        mCustomService.readAdvInterval()
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
        
        mCustomService.deleteAdvInterval()
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
        
        mCustomService.clearChargeCycles()
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
        
        mCustomService.readChargeCycles()
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
            
        mCustomService.readCanLogDiagnostics()
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

        mCustomService.updateCanLogDiagnostics(allow)
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
        
        mCustomService.alterManufacturingTest(test)
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

        mCustomService.kairosManufacturingTest(test)
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

        globals.log.v("\(enable)")
        mCustomService.setAskForButtonResponse(enable)
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

        mCustomService.getAskForButtonResponse()
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
        
        mCustomService.setHRZoneColor(type, red: red, green: green, blue: blue, on_milliseconds: on_milliseconds, off_milliseconds: off_milliseconds)
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

        mCustomService.getHRZoneColor(type)
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
        
        mCustomService.setHRZoneRange(enabled, high_value: high_value, low_value: low_value)
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

        mCustomService.getHRZoneRange()
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

        mCustomService.getPPGAlgorithm()
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
        
        mCustomService.setAdvertiseAsHRM(asHRM)
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
        
        mCustomService.getAdvertiseAsHRM()
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
        
        mCustomService.setButtonCommand(tap, command: command)
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
        
        mCustomService.getButtonCommand(tap)
	}
	
	//--------------------------------------------------------------------------------
	// Function Name: setPaired
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	public func setPaired() {
        mCustomService.setPaired()
	}

	//--------------------------------------------------------------------------------
	// Function Name: setUnpaired
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	public func setUnpaired() {
        mCustomService.setUnpaired()
	}
	
	//--------------------------------------------------------------------------------
	// Function Name: getPaired
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	public func getPaired() {
        mCustomService.getPaired()
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

        mCustomService.setPageThreshold(threshold)
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

        mCustomService.getPageThreshold()
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

        mCustomService.deletePageThreshold()
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

        mCustomService.rawLogging(enable)
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
        
        mCustomService.wornCheck()
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
        
        mCustomService.getRawLoggingStatus()
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
        
        mCustomService.getWornOverrideStatus()
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

        mCustomService.setSessionParam(parameter, value: value)
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

        mCustomService.getSessionParam(parameter)
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

        mCustomService.resetSessionParams()
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

        mCustomService.acceptSessionParams()
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
    private func subscribeConfigured() {
        // Get Configured - 2 step process as so many characteristics
        let partialConfigured1 = Publishers.CombineLatest3(
            mBAS.$configured,
            mHRS.$configured,
            mDIS.$configured
        ).map { $0 && $1 && $2 }
        
        let partialConfigured2 = Publishers.CombineLatest(
            mAmbiqOTAService.$configured,
            mCustomService.$configured
        ).map { $0 && $1 }

        Publishers.CombineLatest(partialConfigured1, partialConfigured2)
            .sink { [weak self] partial1, partial2 in
                if self?.connectionState == .configured { return } // If i was already configured, i don't need to tell the app this again
                //if self?.preview { return } // If i am mocked, i don't need to tell the app again
                                
                if partial1 && partial2 {
                    self?.connectionState = .configured
                    if let peripheral = self?.peripheral {
                        self?.lambdaConfigured?(peripheral.prettyID)
                    }
                    else {
                        globals.log.e ("Do not have a peripheral, why am I signaling configured?")
                    }
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
    private func subScribeCustomService() {

        // Published properties
        mCustomService.$epoch
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.epoch = $0 }
            .store(in: &subscriptions)
        
        mCustomService.$canLogDiagnostics
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.canLogDiagnostics = $0 }
            .store(in: &subscriptions)

        mCustomService.$wornCheckResult
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.wornCheckResult = $0 }
            .store(in: &subscriptions)

        mCustomService.$advertisingInterval
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.advertisingInterval = $0 }
            .store(in: &subscriptions)

        mCustomService.$chargeCycles
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.chargeCycles = $0 }
            .store(in: &subscriptions)

        mCustomService.$advertiseAsHRM
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.advertiseAsHRM = $0 }
            .store(in: &subscriptions)

        mCustomService.$rawLogging
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.rawLogging = $0 }
            .store(in: &subscriptions)

        mCustomService.$wornOverridden
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.wornOverridden = $0 }
            .store(in: &subscriptions)
            
        mCustomService.$buttonResponseEnabled
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.buttonResponseEnabled = $0 }
            .store(in: &subscriptions)

        mCustomService.$singleButtonPressAction
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.singleButtonPressAction = $0 }
            .store(in: &subscriptions)

        mCustomService.$doubleButtonPressAction
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.doubleButtonPressAction = $0 }
            .store(in: &subscriptions)

        mCustomService.$tripleButtonPressAction
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.tripleButtonPressAction = $0 }
            .store(in: &subscriptions)

        mCustomService.$longButtonPressAction
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.longButtonPressAction = $0 }
            .store(in: &subscriptions)

        mCustomService.$hrZoneLEDBelow
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.hrZoneLEDBelow = $0 }
            .store(in: &subscriptions)

        mCustomService.$hrZoneLEDWithin
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.hrZoneLEDWithin = $0 }
            .store(in: &subscriptions)

        mCustomService.$hrZoneLEDAbove
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.hrZoneLEDAbove = $0 }
            .store(in: &subscriptions)

        mCustomService.$hrZoneRange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.hrZoneRange = $0 }
            .store(in: &subscriptions)

        mCustomService.$paired
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.paired = $0 }
            .store(in: &subscriptions)

        mCustomService.$advertisingPageThreshold
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.advertisingPageThreshold = $0 }
            .store(in: &subscriptions)

        mCustomService.$ppgCapturePeriod
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.ppgCapturePeriod = $0 }
            .store(in: &subscriptions)

        mCustomService.$ppgCaptureDuration
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.ppgCaptureDuration = $0 }
            .store(in: &subscriptions)

        mCustomService.$tag
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.tag = $0 }
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

        mCustomService.$buttonTaps
            .receive(on: DispatchQueue.main)
            .sink { taps in
                if let taps {
                    self.lambdaButtonClicked?(self.id, taps)
                }
                self.buttonTaps = taps
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
                        } else { self.lambdaPPGMetrics?(self.id, false, "") }
                    }
                    catch { self.lambdaPPGMetrics?(self.id, false, "") }
                }
                
                self.ppgMetrics = metrics
            }
            .store(in: &subscriptions)

        // PassthroughSubjects
        mCustomService.writeEpochComplete
            .receive(on: DispatchQueue.main)
            .sink { status in
                self.lambdaWriteEpochComplete?(self.id, status.successful)
				self.writeEpochComplete.send(status)
			}
            .store(in: &subscriptions)
		
        mCustomService.readEpochComplete
            .receive(on: DispatchQueue.main)
            .sink { status, value in
                self.lambdaReadEpochComplete?(self.id, status.successful, value)
			}
            .store(in: &subscriptions)
				
        mCustomService.startManualComplete
            .receive(on: DispatchQueue.main)
            .sink { status in
                self.lambdaStartManualComplete?(self.id, status.successful)
				self.startManualComplete.send(status)
			}
            .store(in: &subscriptions)
		
        mCustomService.stopManualComplete
            .receive(on: DispatchQueue.main)
            .sink { status in
                self.lambdaStopManualComplete?(self.id, status.successful)
                self.stopManualComplete.send(status)
            }
            .store(in: &subscriptions)
		
        mCustomService.ledComplete
            .receive(on: DispatchQueue.main)
            .sink { status in
                self.lambdaLEDComplete?(self.id, status.successful)
				self.ledComplete.send(status)
			}
            .store(in: &subscriptions)
		
        mCustomService.getRawLoggingStatusComplete
            .receive(on: DispatchQueue.main)
            .sink { status, enabled in
                self.lambdaGetRawLoggingStatusComplete?(self.id, status.successful, enabled)
				self.getRawLoggingStatusComplete.send(status)
			}
            .store(in: &subscriptions)
        
        mCustomService.getWornOverrideStatusComplete
            .receive(on: DispatchQueue.main)
            .sink { status, overridden in
                self.lambdaGetWornOverrideStatusComplete?(self.id, status.successful, overridden)
				self.getWornOverrideStatusComplete.send(status)
			}
            .store(in: &subscriptions)

        mCustomService.writeSerialNumberComplete
            .receive(on: DispatchQueue.main)
            .sink { status in
                self.lamdaWriteSerialNumberComplete?(self.id, status.successful)
				self.writeSerialNumberComplete.send(status)
			}
            .store(in: &subscriptions)

        mCustomService.readSerialNumberComplete
            .receive(on: DispatchQueue.main)
            .sink { status, partID in
            	self.lambdaReadSerialNumberComplete?(self.id, status.successful, partID)
                if status.successful { self.serialNumber = partID }
				self.readSerialNumberComplete.send(status)
			}
            .store(in: &subscriptions)

        mCustomService.deleteSerialNumberComplete
            .receive(on: DispatchQueue.main)
            .sink { status in
            	self.lambdaDeleteSerialNumberComplete?(self.id, status.successful)
				self.deleteSerialNumberComplete.send(status)
			}
            .store(in: &subscriptions)

        mCustomService.writeAdvIntervalComplete
            .receive(on: DispatchQueue.main)
            .sink { status in
	            self.lambdaWriteAdvIntervalComplete?(self.id, status.successful)
				self.writeAdvIntervalComplete.send(status)
			}
            .store(in: &subscriptions)

        mCustomService.readAdvIntervalComplete
            .receive(on: DispatchQueue.main)
            .sink { status, seconds in
                self.lambdaReadAdvIntervalComplete?(self.id, status.successful, seconds)
				self.readAdvIntervalComplete.send(status)
			}
            .store(in: &subscriptions)
		
        mCustomService.deleteAdvIntervalComplete
            .receive(on: DispatchQueue.main)
            .sink { status in
                self.lambdaDeleteAdvIntervalComplete?(self.id, status.successful)
				self.deleteAdvIntervalComplete.send(status)
			}
            .store(in: &subscriptions)

        mCustomService.clearChargeCyclesComplete
            .receive(on: DispatchQueue.main)
            .sink { status in
                self.lambdaClearChargeCyclesComplete?(self.id, status.successful)
				self.clearChargeCyclesComplete.send(status)
			}
            .store(in: &subscriptions)

        mCustomService.readChargeCyclesComplete
            .receive(on: DispatchQueue.main)
            .sink { status, cycles in
                self.lambdaReadChargeCyclesComplete?(self.id, status.successful, cycles)
				self.readChargeCyclesComplete.send(status)
			}
            .store(in: &subscriptions)

        mCustomService.setAdvertiseAsHRMComplete
            .receive(on: DispatchQueue.main)
            .sink { status, asHRM in
                self.lambdaSetAdvertiseAsHRMComplete?(self.id, status.successful, asHRM)
				self.setAdvertiseAsHRMComplete.send(status)
			}
            .store(in: &subscriptions)
    
        mCustomService.getAdvertiseAsHRMComplete
            .receive(on: DispatchQueue.main)
            .sink { status, asHRM in
                self.lambdaGetAdvertiseAsHRMComplete?(self.id, status.successful, asHRM)
				self.getAdvertiseAsHRMComplete.send(status)
			}
            .store(in: &subscriptions)

        mCustomService.setButtonCommandComplete
            .receive(on: DispatchQueue.main)
            .sink { status, tap, command in
				self.lambdaSetButtonCommandComplete?(self.id, status.successful, tap, command)
				self.setButtonCommandComplete.send((status, tap))
			}
            .store(in: &subscriptions)
        
        mCustomService.getButtonCommandComplete
            .receive(on: DispatchQueue.main)
            .sink { status, tap, command in
                self.lambdaGetButtonCommandComplete?(self.id, status.successful, tap, command)
				self.getButtonCommandComplete.send((status, tap))
			}
            .store(in: &subscriptions)
		
        mCustomService.setAskForButtonResponseComplete
            .receive(on: DispatchQueue.main)
            .sink { status, enable in
                self.lambdaSetAskForButtonResponseComplete?(self.id, status.successful, enable)
				self.setAskForButtonResponseComplete.send(status)
			}
            .store(in: &subscriptions)
		
        mCustomService.getAskForButtonResponseComplete
            .receive(on: DispatchQueue.main)
            .sink { status, enable in
                self.lambdaGetAskForButtonResponseComplete?(self.id, status.successful, enable)
				self.getAskForButtonResponseComplete.send(status)
			}
            .store(in: &subscriptions)
		
        mCustomService.setHRZoneColorComplete
            .receive(on: DispatchQueue.main)
            .sink { status, type in
                self.lambdaSetHRZoneColorComplete?(self.id, status.successful, type)
				self.setHRZoneColorComplete.send((status, type))
			}
            .store(in: &subscriptions)
		
        mCustomService.getHRZoneColorComplete
            .receive(on: DispatchQueue.main)
            .sink { status, type, red, green, blue, on_ms, off_ms in
                self.lambdaGetHRZoneColorComplete?(self.id, status.successful, type, red, green, blue, on_ms, off_ms)
				self.getHRZoneColorComplete.send((status, type))
			}
            .store(in: &subscriptions)
		
        mCustomService.setHRZoneRangeComplete
            .receive(on: DispatchQueue.main)
            .sink { status in
                self.lambdaSetHRZoneRangeComplete?(self.id, status.successful)
				self.setHRZoneRangeComplete.send(status)
			}
            .store(in: &subscriptions)
		
        mCustomService.getHRZoneRangeComplete
            .receive(on: DispatchQueue.main)
            .sink { status, enabled, high_value, low_value in
                self.lambdaGetHRZoneRangeComplete?(self.id, status.successful, enabled, high_value, low_value)
				self.getHRZoneRangeComplete.send(status)
			}
            .store(in: &subscriptions)
		
        mCustomService.getPPGAlgorithmComplete
            .receive(on: DispatchQueue.main)
            .sink { status, algorithm, state in
                self.lambdaGetPPGAlgorithmComplete?(self.id, status.successful, algorithm, state)
				self.getPPGAlgorithmComplete.send((status, algorithm, state))
			}
            .store(in: &subscriptions)
		
        mCustomService.endSleepComplete
            .receive(on: DispatchQueue.main)
            .sink { status in
                self.lambdaEndSleepComplete?(self.id, status.successful)
				self.endSleepComplete.send(status)
			}
            .store(in: &subscriptions)
		
        mCustomService.endSleepStatus
            .receive(on: DispatchQueue.main)
            .sink { enable in
				self.lambdaEndSleepStatus?(self.id, enable)
				self.endSleepStatus.send(enable)
			}
            .store(in: &subscriptions)

        mCustomService.disableWornDetectComplete
            .receive(on: DispatchQueue.main)
            .sink { status in
                self.lambdaDisableWornDetectComplete?(self.id, status.successful)
				self.disableWornDetectComplete.send(status)
			}
            .store(in: &subscriptions)

        mCustomService.enableWornDetectComplete
            .receive(on: DispatchQueue.main)
            .sink { status in
                self.lambdaEnableWornDetectComplete?(self.id, status.successful)
				self.enableWornDetectComplete.send(status)
			}
            .store(in: &subscriptions)
		
        mCustomService.wornCheckResultComplete
            .receive(on: DispatchQueue.main)
            .sink { status, code, value in
                self.lambdaWornCheckComplete?(self.id, status.successful, code, value )
				self.wornCheckResultComplete.send(status)
			}
            .store(in: &subscriptions)
		
        mCustomService.setSessionParamComplete
            .receive(on: DispatchQueue.main)
            .sink { status, parameter in
                self.lambdaSetSessionParamComplete?(self.id, status.successful, parameter)
				self.setSessionParamComplete.send((status, parameter))
			}
            .store(in: &subscriptions)
		
        mCustomService.getSessionParamComplete
            .receive(on: DispatchQueue.main)
            .sink { status, parameter, value in
                self.lambdaGetSessionParamComplete?(self.id, status.successful, parameter, value)
				self.getSessionParamComplete.send((status, parameter))
			}
            .store(in: &subscriptions)
		
        mCustomService.acceptSessionParamsComplete
            .receive(on: DispatchQueue.main)
            .sink { status in
                self.lambdaAcceptSessionParamsComplete?(self.id, status.successful)
				self.acceptSessionParamsComplete.send(status)
			}
            .store(in: &subscriptions)
		
        mCustomService.resetSessionParamsComplete
            .receive(on: DispatchQueue.main)
            .sink { status in
                self.lambdaResetSessionParamsComplete?(self.id, status.successful)
				self.resetSessionParamsComplete.send(status)
			}
            .store(in: &subscriptions)
		
        mCustomService.readCanLogDiagnosticsComplete
            .receive(on: DispatchQueue.main)
            .sink { status, allow in
                self.lambdaReadCanLogDiagnosticsComplete?(self.id, status.successful, allow)
				self.readCanLogDiagnosticsComplete.send(status)
			}
            .store(in: &subscriptions)
		
        mCustomService.updateCanLogDiagnosticsComplete
            .receive(on: DispatchQueue.main)
            .sink { status in
                self.lambdaUpdateCanLogDiagnosticsComplete?(self.id, status.successful)
				self.updateCanLogDiagnosticsComplete.send(status)
			}
            .store(in: &subscriptions)
		
        mCustomService.getPacketCountComplete
            .receive(on: DispatchQueue.main)
            .sink { status, count in
                self.lambdaGetPacketCountComplete?(self.id, status.successful, count)
				self.getPacketCountComplete.send((status, count))
			}
            .store(in: &subscriptions)
		
        mCustomService.getAllPacketsComplete
            .receive(on: DispatchQueue.main)
            .sink { status in
                self.lambdaGetAllPacketsComplete?(self.id, status.successful)
				self.getAllPacketsComplete.send(status)
			}
            .store(in: &subscriptions)
		
        mCustomService.getAllPacketsAcknowledgeComplete
            .receive(on: DispatchQueue.main)
            .sink { status, ack in
                self.lambdaGetAllPacketsAcknowledgeComplete?(self.id, status.successful, ack)
				self.getAllPacketsAcknowledgeComplete.send((status, ack))
			}
            .store(in: &subscriptions)
		
        mCustomService.setPairedComplete
            .receive(on: DispatchQueue.main)
            .sink { status in
                self.lambdaSetPairedComplete?(self.id, status.successful)
				self.setPairedComplete.send(status)
			}
            .store(in: &subscriptions)
		
        mCustomService.setUnpairedComplete
            .receive(on: DispatchQueue.main)
            .sink { status in
                self.lambdaSetUnpairedComplete?(self.id, status.successful)
				self.setUnpairedComplete.send(status)
			}
            .store(in: &subscriptions)

        mCustomService.getPairedComplete
            .receive(on: DispatchQueue.main)
            .sink { status, paired in
                self.lambdaGetPairedComplete?(self.id, status.successful, paired)
				self.getPairedComplete.send(status)
			}
            .store(in: &subscriptions)
		
        mCustomService.setPageThresholdComplete
            .receive(on: DispatchQueue.main)
            .sink { status in
                self.lambdaSetPageThresholdComplete?(self.id, status.successful)
				self.setPageThresholdComplete.send(status)
			}
            .store(in: &subscriptions)

        mCustomService.getPageThresholdComplete
            .receive(on: DispatchQueue.main)
            .sink { status, threshold in
                self.lambdaGetPageThresholdComplete?(self.id, status.successful, threshold)
                self.getPageThresholdComplete.send(status)
			}
            .store(in: &subscriptions)

        mCustomService.deletePageThresholdComplete
            .receive(on: DispatchQueue.main)
            .sink { status in
                self.lambdaDeletePageThresholdComplete?(self.id, status.successful)
				self.deletePageThresholdComplete.send(status)
			}
            .store(in: &subscriptions)

        mCustomService.enterShipModeComplete
            .receive(on: DispatchQueue.main)
            .sink { status in
                self.lambdaEnterShipModeComplete?(self.id, status.successful)
				self.enterShipModeComplete.send(status)
			}
            .store(in: &subscriptions)
		
        mCustomService.resetComplete
            .receive(on: DispatchQueue.main)
            .sink { status in
                self.lambdaResetComplete?(self.id, status.successful)
				self.resetComplete.send(status)
			}
            .store(in: &subscriptions)
		
        mCustomService.airplaneModeComplete
            .receive(on: DispatchQueue.main)
            .sink { status in
                self.lambdaAirplaneModeComplete?(self.id, status.successful)
				self.airplaneModeComplete.send(status)
			}
            .store(in: &subscriptions)
		
        mCustomService.manufacturingTestComplete
            .receive(on: DispatchQueue.main)
            .sink { status in
                self.lambdaManufacturingTestComplete?(self.id, status.successful)
				self.manufacturingTestComplete.send(status)
			}
            .store(in: &subscriptions)

        mCustomService.rawLoggingComplete
            .receive(on: DispatchQueue.main)
            .sink { status in
                self.lambdaRawLoggingComplete?(self.id, status.successful)
				self.rawLoggingComplete.send(status)
			}
            .store(in: &subscriptions)
		
		// MARK: Notifications
        mCustomService.manufacturingTestResult
            .receive(on: DispatchQueue.main)
            .sink { valid, result in
				self.lambdaManufacturingTestResult?(self.id, valid, result)
				self.manufacturingTestResult.send((valid, result))
			}
            .store(in: &subscriptions)
		
        mCustomService.ppgFailed
            .receive(on: DispatchQueue.main)
            .sink { code in
				self.lambdaPPGFailed?(self.id, code)
				self.ppgFailed.send(code)
			}
            .store(in: &subscriptions)
		
        mCustomService.dataFailure
            .sink { self.lambdaDataFailure?(self.id) }
            .store(in: &subscriptions)
        
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
		
        mCustomService.endSleepStatus
            .receive(on: DispatchQueue.main)
            .sink { enable in
				self.lambdaEndSleepStatus?(self.id, enable)
				self.endSleepStatus.send(enable)
			}
            .store(in: &subscriptions)

        mCustomService.manufacturingTestResult
            .receive(on: DispatchQueue.main)
            .sink { valid, result in
				self.lambdaManufacturingTestResult?(self.id, valid, result)
				self.manufacturingTestResult.send((valid, result))
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
        
        mHRS.$bodySensorLocation
            .receive(on: DispatchQueue.main)
            .sink { [weak self] location in
                self?.bodySensorLocation = location
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
			} else {
				globals.log.e ("\(peripheral.prettyID): Connected to a device that isn't requesting connection.  Weird!  Disconnect")
				return false
			}
		} else {
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
        switch hit(characteristic) {
        case .bas: mBAS.didDiscoverCharacteristic(characteristic, commandQ: commandQ)
        case .dis: mDIS.didDiscoverCharacteristic(characteristic, commandQ: commandQ)
        case .hrs: mHRS.didDiscoverCharacteristic(characteristic, commandQ: commandQ)
        case .ota: mAmbiqOTAService.didDiscoverCharacteristic(characteristic, commandQ: commandQ)
        case .custom: mCustomService.didDiscoverCharacteristic(characteristic, commandQ: commandQ)
        case .unknown(let uuid):
            globals.log.e ("\(self.id) - Unhandled: \(uuid)")
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
        switch hit(characteristic) {
        case .bas: mBAS.didDiscoverDescriptor(characteristic)
        case .dis: globals.log.e("\(self.id) - DIS should not see this")
        case .hrs: mHRS.didDiscoverDescriptor(characteristic)
        case .ota: mAmbiqOTAService.didDiscoverDescriptor(characteristic)
        case .custom: mCustomService.didDiscoverDescriptor(characteristic)
        case .unknown(let uuid):
            globals.log.e ("\(self.id) - Unhandled: \(uuid)")
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
        switch hit(characteristic) {
        case .bas: mBAS.didUpdateValue(characteristic)
        case .dis: mDIS.didUpdateValue(characteristic)
        case .hrs: mHRS.didUpdateValue(characteristic)
        case .ota: mAmbiqOTAService.didUpdateValue(characteristic)
        case .custom: mCustomService.didUpdateValue(characteristic)
        case .unknown(let uuid):
            globals.log.e ("\(self.id) - Unhandled: \(uuid)")
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
            switch hit(characteristic) {
            case .bas: mBAS.didUpdateNotificationState(characteristic)
            case .dis: globals.log.e("\(self.id) - DIS should not see this")
            case .hrs: mHRS.didUpdateNotificationState(characteristic)
            case .ota: mAmbiqOTAService.didUpdateNotificationState(characteristic)
            case .custom: mCustomService.didUpdateNotificationState(characteristic)
            case .unknown(let uuid):
                globals.log.e ("\(self.id) - Unhandled: \(uuid)")
            }
		} else {
            globals.log.e ("\(self.id): Peripheral object is nil - do nothing")
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
	func didWriteWithoutResponseReady() {
		mAmbiqOTAService.didWriteWithoutResponseReady()
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
                               bodySensorLocation: BodySensorLocation? = nil,
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
        self.bodySensorLocation = .wrist
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
