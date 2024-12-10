//
//  biostrapDeviceSDK.swift
//  biostrapDeviceSDK
//
//  Created by Joseph A. Bennett on 3/31/21.
//

import Foundation
import CoreBluetooth
import Combine

@objc public class biostrapDeviceSDK: NSObject, ObservableObject {
	
	var dataPacketsOnBackgroundThread	= false
	
	internal var scanInBackground		= false
	internal var scanForPaired			= false
	internal var scanForUnpaired		= false
	internal var scanForLegacy			= false
	
	@objc public enum biostrapDiscoveryType: Int {
		case legacy				= 1
		case unpaired			= 2
		case unpaired_w_uuid	= 3		// This should never occur.. it means a firmware bug
		case paired				= 4
		case paired_w_uuid		= 5
		case unknown			= 99
		
		public var title: String {
			switch (self) {
			case .legacy			: return "Legacy"
			case .unpaired			: return "Unpaired"
			case .unpaired_w_uuid	: return "Unpaired with UUID"
			case .paired			: return "Paired"
			case .paired_w_uuid		: return "Paired with UUID"
			case .unknown			: return "Unknown"
			}
		}
		
		public var isPaired: Bool {
			return (self == .paired) || (self == .paired_w_uuid)
		}
		
		public var isNotPaired: Bool {
			return (self == .unpaired) || (self == .unpaired_w_uuid)
		}
	}
	
	#if UNIVERSAL
	@objc public enum biostrapDeviceType: Int {
		case alter		= 3
		case kairos		= 4
		case unknown	= 99
		
		public var title: String {
			switch (self) {
			case .alter		: return "Alter"
			case .kairos	: return "Kairos"
			case .unknown	: return "Unknown"
			}
		}
	}
	#endif
	
	private var subscriptions = Set<AnyCancellable>()
	
	// Observable Objects / Passthroughs
	@objc @Published public internal(set) var bluetoothAvailable: Bool = false
	@objc @Published public internal(set) var discoveredDevices = [ Device ]()
	@objc @Published public internal(set) var unnamedDevices = [ Device ]()
	@objc @Published public internal(set) var connectedDevices = [ Device ]()
	
	public let log = PassthroughSubject<(LogLevel, String, String, String, Int), Never>()
	public let deviceDisconnected = PassthroughSubject<Device, Never>()

	// Lambdas
	@available(*, deprecated, message: "Use the 'log' PassthroughSubject.  This will be removed in a future version of the SDK")
	@objc public var logV: ((_ message: String?, _ file: String, _ function: String, _ line: Int)->())?
	@available(*, deprecated, message: "Use the 'log' PassthroughSubject.  This will be removed in a future version of the SDK")
	@objc public var logD: ((_ message: String?, _ file: String, _ function: String, _ line: Int)->())?
	@available(*, deprecated, message: "Use the 'log' PassthroughSubject.  This will be removed in a future version of the SDK")
	@objc public var logI: ((_ message: String?, _ file: String, _ function: String, _ line: Int)->())?
	@available(*, deprecated, message: "Use the 'log' PassthroughSubject.  This will be removed in a future version of the SDK")
	@objc public var logW: ((_ message: String?, _ file: String, _ function: String, _ line: Int)->())?
	@available(*, deprecated, message: "Use the 'log' PassthroughSubject.  This will be removed in a future version of the SDK")
	@objc public var logE: ((_ message: String?, _ file: String, _ function: String, _ line: Int)->())?
	
	@available(*, deprecated, message: "Use the published bluetoothAvailable property.  This will be removed in a future version of the SDK")
	@objc public var bluetoothReady: ((_ isOn: Bool)->())?
	@available(*, deprecated, message: "Use the published discoverdDevices property.  This will be removed in a future version of the SDK")
	@objc public var discovered: ((_ id: String, _ device: Device)->())?
	@available(*, deprecated, message: "Use the published unnamedDevices property.  This will be removed in a future version of the SDK")
	@objc public var discoveredUnnamed: ((_ id: String, _ device: Device)->())?
	@available(*, deprecated, message: "Use the published connectedDevices property.  This will be removed in a future version of the SDK")
	@objc public var connected: ((_ id: String)->())?
	
	@available(*, deprecated, message: "Use the 'deviceDisconnected' PassthroughSubject.  This will be removed in a future version of the SDK")
	@objc public var disconnected: ((_ id: String)->())?
	
	@available(*, deprecated, message: "Use the device object's publisher directly.  This will be removed in a future version of the SDK")
	@objc public var writeEpochComplete: ((_ id: String, _ successful: Bool)->())?
	@available(*, deprecated, message: "Use the device object's publisher directly.  This will be removed in a future version of the SDK")
	@objc public var readEpochComplete: ((_ id: String, _ successful: Bool, _ value: Int)->())?
	@available(*, deprecated, message: "Use the device object's publisher directly.  This will be removed in a future version of the SDK")
	@objc public var endSleepComplete: ((_ id: String, _ successful: Bool)->())?
	@available(*, deprecated, message: "Use the device object's publisher directly.  This will be removed in a future version of the SDK")
	@objc public var getAllPacketsComplete: ((_ id: String, _ successful: Bool)->())?
	@available(*, deprecated, message: "Use the device object's publisher directly.  This will be removed in a future version of the SDK")
	@objc public var getAllPacketsAcknowledgeComplete: ((_ id: String, _ successful: Bool, _ ack: Bool)->())?
	@available(*, deprecated, message: "Use the device object's publisher directly.  This will be removed in a future version of the SDK")
	@objc public var getNextPacketComplete: ((_ id: String, _ successful: Bool, _ error_code: nextPacketStatusType, _ caughtUp: Bool, _ packet: String)->())?
	@available(*, deprecated, message: "Use the device object's publisher directly.  This will be removed in a future version of the SDK")
	@objc public var getPacketCountComplete: ((_ id: String, _ successful: Bool, _ count: Int)->())?
	@available(*, deprecated, message: "Use the device object's publisher directly.  This will be removed in a future version of the SDK")
	@objc public var startManualComplete: ((_ id: String, _ successful: Bool)->())?
	@available(*, deprecated, message: "Use the device object's publisher directly.  This will be removed in a future version of the SDK")
	@objc public var stopManualComplete: ((_ id: String, _ successful: Bool)->())?
	@available(*, deprecated, message: "Use the device object's publisher directly.  This will be removed in a future version of the SDK")
	@objc public var ledComplete: ((_ id: String, _ successful: Bool)->())?
	@available(*, deprecated, message: "Use the device object's publisher directly.  This will be removed in a future version of the SDK")
	@objc public var enterShipModeComplete: ((_ id: String, _ successful: Bool)->())?
	
	@available(*, deprecated, message: "Use the device object's publisher directly.  This will be removed in a future version of the SDK")
	@objc public var writeSerialNumberComplete: ((_ id: String, _ successful: Bool)->())?
	@available(*, deprecated, message: "Use the device object's publisher directly.  This will be removed in a future version of the SDK")
	@objc public var readSerialNumberComplete: ((_ id: String, _ successful: Bool, _ partID: String)->())?
	@available(*, deprecated, message: "Use the device object's publisher directly.  This will be removed in a future version of the SDK")
	@objc public var deleteSerialNumberComplete: ((_ id: String, _ successful: Bool)->())?
	@available(*, deprecated, message: "Use the device object's publisher directly.  This will be removed in a future version of the SDK")
	@objc public var writeAdvIntervalComplete: ((_ id: String, _ successful: Bool)->())?
	@available(*, deprecated, message: "Use the device object's publisher directly.  This will be removed in a future version of the SDK")
	@objc public var readAdvIntervalComplete: ((_ id: String, _ successful: Bool, _ seconds: Int)->())?
	@available(*, deprecated, message: "Use the device object's publisher directly.  This will be removed in a future version of the SDK")
	@objc public var deleteAdvIntervalComplete: ((_ id: String, _ successful: Bool)->())?
	@available(*, deprecated, message: "Use the device object's publisher directly.  This will be removed in a future version of the SDK")
	@objc public var clearChargeCyclesComplete: ((_ id: String, _ successful: Bool)->())?
	@available(*, deprecated, message: "Use the device object's publisher directly.  This will be removed in a future version of the SDK")
	@objc public var readChargeCyclesComplete: ((_ id: String, _ successful: Bool, _ cycles: Float)->())?
	@available(*, deprecated, message: "Use the device object's publisher directly.  This will be removed in a future version of the SDK")
	@objc public var readCanLogDiagnosticsComplete: ((_ id: String, _ successful: Bool, _ allow: Bool)->())?
	@available(*, deprecated, message: "Use the device object's publisher directly.  This will be removed in a future version of the SDK")
	@objc public var updateCanLogDiagnosticsComplete: ((_ id: String, _ successful: Bool)->())?

	@available(*, deprecated, message: "Use the device object's publisher directly.  This will be removed in a future version of the SDK")
	@objc public var wornCheckComplete: ((_ id: String, _ successful: Bool, _ code: String, _ value: Int)->())?
	@available(*, deprecated, message: "Use the device object's publisher directly.  This will be removed in a future version of the SDK")
	@objc public var rawLoggingComplete: ((_ id: String, _ successful: Bool)->())?
	@available(*, deprecated, message: "Use the device object's publisher directly.  This will be removed in a future version of the SDK")
	@objc public var resetComplete: ((_ id: String, _ successful: Bool)->())?
	@available(*, deprecated, message: "Use the device object's publisher directly.  This will be removed in a future version of the SDK")
	@objc public var ppgMetrics: ((_ id: String, _ successful: Bool, _ packet: String)->())?
	@available(*, deprecated, message: "Use the device object's publisher directly.  This will be removed in a future version of the SDK")
	@objc public var ppgFailed: ((_ id: String, _ code: Int)->())?
	@available(*, deprecated, message: "Use the device object's publisher directly.  This will be removed in a future version of the SDK")
	@objc public var disableWornDetectComplete: ((_ id: String, _ successful: Bool)->())?
	@available(*, deprecated, message: "Use the device object's publisher directly.  This will be removed in a future version of the SDK")
	@objc public var enableWornDetectComplete: ((_ id: String, _ successful: Bool)->())?

	@available(*, deprecated, message: "Use the device object's publisher directly.  This will be removed in a future version of the SDK")
	@objc public var dataPackets: ((_ id: String, _ sequence_number: Int, _ packets: String)->())?
	@available(*, deprecated, message: "Use the device object's publisher directly.  This will be removed in a future version of the SDK")
	@objc public var dataComplete: ((_ id: String, _ bad_fw_read_count: Int, _ bad_fw_parse_count: Int, _ overflow_count: Int, _ bad_sdk_parse_count: Int, _ intermediate: Bool)->())?
	@available(*, deprecated, message: "Use the device object's publisher directly.  This will be removed in a future version of the SDK")
	@objc public var dataFailure: ((_ id: String)->())?
	@available(*, deprecated, message: "Use the device object's publisher directly.  This will be removed in a future version of the SDK")
	@objc public var streamingPacket: ((_ id: String, _ packet: String)->())?
	@available(*, deprecated, message: "Use the device object's publisher directly.  This will be removed in a future version of the SDK")
	@objc public var dataAvailable: ((_ id: String)->())?

	@available(*, deprecated, message: "Use the device object's publisher directly.  This will be removed in a future version of the SDK")
	@objc public var deviceWornStatus: ((_ id: String, _ isWorn: Bool)->())?

	@available(*, deprecated, message: "Use the device object's publisher directly.  This will be removed in a future version of the SDK")
	@objc public var updateFirmwareStarted: ((_ id: String)->())?
	@available(*, deprecated, message: "Use the device object's publisher directly.  This will be removed in a future version of the SDK")
	@objc public var updateFirmwareFinished: ((_ id: String)->())?
	@available(*, deprecated, message: "Use the device object's publisher directly.  This will be removed in a future version of the SDK")
	@objc public var updateFirmwareFailed: ((_ id: String, _ code: Int, _ message: String)->())?
	@available(*, deprecated, message: "Use the device object's publisher directly.  This will be removed in a future version of the SDK")
	@objc public var updateFirmwareProgress: ((_ id: String, _ percentage: Float)->())?
	
	@available(*, deprecated, message: "Use the device object's publisher directly.  This will be removed in a future version of the SDK")
	@objc public var manufacturingTestComplete: ((_ id: String, _ successful: Bool)->())?
	@available(*, deprecated, message: "Use the device object's publisher directly.  This will be removed in a future version of the SDK")
	@objc public var manufacturingTestResult: ((_ id: String, _ valid: Bool, _ result: String)->())?

	@available(*, deprecated, message: "Use the device object's publisher directly.  This will be removed in a future version of the SDK")
	@objc public var endSleepStatus: ((_ id: String, _ hasSleep: Bool)->())?
	@available(*, deprecated, message: "Use the device object's publisher directly.  This will be removed in a future version of the SDK")
	@objc public var buttonClicked: ((_ id: String, _ presses: Int)->())?
	@available(*, deprecated, message: "Use the device object's publisher directly.  This will be removed in a future version of the SDK")
	@objc public var setAskForButtonResponseComplete: ((_ id: String, _ successful: Bool, _ enable: Bool)->())?
	@available(*, deprecated, message: "Use the device object's publisher directly.  This will be removed in a future version of the SDK")
	@objc public var getAskForButtonResponseComplete: ((_ id: String, _ successful: Bool, _ enable: Bool)->())?
	@available(*, deprecated, message: "Use the device object's publisher directly.  This will be removed in a future version of the SDK")
	@objc public var setHRZoneColorComplete: ((_ id: String, _ successful: Bool, _ type: hrZoneRangeType)->())?
	@available(*, deprecated, message: "Use the device object's publisher directly.  This will be removed in a future version of the SDK")
	@objc public var getHRZoneColorComplete: ((_ id: String, _ successful: Bool, _ type: hrZoneRangeType, _ red: Bool, _ green: Bool, _ blue: Bool, _ on_ms: Int, _ off_ms: Int)->())?
	@available(*, deprecated, message: "Use the device object's publisher directly.  This will be removed in a future version of the SDK")
	@objc public var setHRZoneRangeComplete: ((_ id: String, _ successful: Bool)->())?
	@available(*, deprecated, message: "Use the device object's publisher directly.  This will be removed in a future version of the SDK")
	@objc public var getHRZoneRangeComplete: ((_ id: String, _ successful: Bool, _ enabled: Bool, _ high_value: Int, _ low_value: Int)->())?
	@available(*, deprecated, message: "Use the device object's publisher directly.  This will be removed in a future version of the SDK")
	@objc public var getPPGAlgorithmComplete: ((_ id: String, _ successful: Bool, _ algorithm: ppgAlgorithmConfiguration, _ state: eventType)->())?
	@available(*, deprecated, message: "Use the device object's publisher directly.  This will be removed in a future version of the SDK")
	@objc public var setAdvertiseAsHRMComplete: ((_ id: String, _ successful: Bool, _ asHRM: Bool)->())?
	@available(*, deprecated, message: "Use the device object's publisher directly.  This will be removed in a future version of the SDK")
	@objc public var getAdvertiseAsHRMComplete: ((_ id: String, _ successful: Bool, _ asHRM: Bool)->())?
	@available(*, deprecated, message: "Use the device object's publisher directly.  This will be removed in a future version of the SDK")
	@objc public var setButtonCommandComplete: ((_ id: String, _ successful: Bool, _ tap: buttonTapType, _ command: buttonCommandType)->())?
	@available(*, deprecated, message: "Use the device object's publisher directly.  This will be removed in a future version of the SDK")
	@objc public var getButtonCommandComplete: ((_ id: String, _ successful: Bool, _ tap: buttonTapType, _ command: buttonCommandType)->())?
	@available(*, deprecated, message: "Use the device object's publisher directly.  This will be removed in a future version of the SDK")
	@objc public var getPairedComplete: ((_ id: String, _ successful: Bool, _ paired: Bool)->())?
	@available(*, deprecated, message: "Use the device object's publisher directly.  This will be removed in a future version of the SDK")
	@objc public var setPairedComplete: ((_ id: String, _ successful: Bool)->())?
	@available(*, deprecated, message: "Use the device object's publisher directly.  This will be removed in a future version of the SDK")
	@objc public var setUnpairedComplete: ((_ id: String, _ successful: Bool)->())?
	@available(*, deprecated, message: "Use the device object's publisher directly.  This will be removed in a future version of the SDK")
	@objc public var getPageThresholdComplete: ((_ id: String, _ successful: Bool, _ threshold: Int)->())?
	@available(*, deprecated, message: "Use the device object's publisher directly.  This will be removed in a future version of the SDK")
	@objc public var setPageThresholdComplete: ((_ id: String, _ successful: Bool)->())?
	@available(*, deprecated, message: "Use the device object's publisher directly.  This will be removed in a future version of the SDK")
	@objc public var deletePageThresholdComplete: ((_ id: String, _ successful: Bool)->())?

	@available(*, deprecated, message: "Use the device object's publisher directly.  This will be removed in a future version of the SDK")
	@objc public var getRawLoggingStatusComplete: ((_ id: String, _ successful: Bool, _ enabled: Bool)->())?
	@available(*, deprecated, message: "Use the device object's publisher directly.  This will be removed in a future version of the SDK")
	@objc public var getWornOverrideStatusComplete: ((_ id: String, _ successful: Bool, _ overridden: Bool)->())?

	@available(*, deprecated, message: "Use the device object's publisher directly.  This will be removed in a future version of the SDK")
	@objc public var deviceChargingStatus: ((_ id: String, _ charging: Bool, _ on_charger: Bool, _ error: Bool)->())?

	@available(*, deprecated, message: "Use the device object's publisher directly.  This will be removed in a future version of the SDK")
	@objc public var setSessionParamComplete: ((_ id: String, _ successful: Bool, _ parameter: sessionParameterType)->())?
	@available(*, deprecated, message: "Use the device object's publisher directly.  This will be removed in a future version of the SDK")
	@objc public var getSessionParamComplete: ((_ id: String, _ successful: Bool, _ parameter: sessionParameterType, _ value: Int)->())?
	@available(*, deprecated, message: "Use the device object's publisher directly.  This will be removed in a future version of the SDK")
	@objc public var resetSessionParamsComplete: ((_ id: String, _ successful: Bool)->())?
	@available(*, deprecated, message: "Use the device object's publisher directly.  This will be removed in a future version of the SDK")
	@objc public var acceptSessionParamsComplete: ((_ id: String, _ successful: Bool)->())?

	@available(*, deprecated, message: "Use the device object's publisher directly.  This will be removed in a future version of the SDK")
	@objc public var batteryLevel: ((_ id: String, _ percentage: Int)->())?

	@available(*, deprecated, message: "Use the device object's publisher directly.  This will be removed in a future version of the SDK")
	@objc public var heartRate: ((_ id: String, _ epoch: Int, _ hr: Int, _ rr: [Double])->())?
	@available(*, deprecated, message: "Use the device object's publisher directly.  This will be removed in a future version of the SDK")
	@objc public var airplaneModeComplete: ((_ id: String, _ successful: Bool)->())?
	
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	@objc public var version: String {
		let version = mSDKVersion()
		let build	= mSDKBuild()
		
		return version == build ? "\(version)" : "\(version) (\(build))"
	}
		
	// Internal vars
	internal var mCentralManager : CBCentralManager?
	internal lazy var mPairedDeviceNames	= [ String: String ]()
	internal var mLicensed : Bool = false

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	// Manage device ids & name pair in paired devices.  In the background, iOS
	// doesn't always look for both the advertisement packet and the scan response
	// packet.  As such, in the background the name may be nil, and then we can't
	// connect as a valid name is required
	//
	//--------------------------------------------------------------------------------
	@objc public func addPairedDeviceWithId(_ id: String, name: String) { mPairedDeviceNames[id] = name }
	@objc public func removePairedDeviceWithId(_ id: String) { mPairedDeviceNames.removeValue(forKey: id) }
	@objc public func clearPairedDevices() { mPairedDeviceNames.removeAll() }
	
	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	@objc public override init() {
		super.init()
		
		globals.log.log
			.sink { level, message, file, function, line in
				switch (level) {
				case .verbose:	self.logV?(message, file, function, line)
				case .debug:	self.logD?(message, file, function, line)
				case .info:		self.logI?(message, file, function, line)
				case .warning:	self.logW?(message, file, function, line)
				case .error:	self.logE?(message, file, function, line)
				}
				
				self.log.send((level, message, file, function, line))
			}
			.store(in: &subscriptions)
				
		let backgroundQueue	= DispatchQueue.global(qos: DispatchQoS.QoSClass.background)
		mCentralManager		= CBCentralManager(delegate: self, queue: backgroundQueue, options: [CBCentralManagerOptionRestoreIdentifierKey: Bundle.main.bundleIdentifier ?? ""])
		
		discoveredDevices	= [ Device ]()
		connectedDevices	= [ Device ]()
	}
	
	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	#if KAIROS || UNIVERSAL
	public func acquireLicense(_ licenseKey: String) -> (Bool, Int, String) {
		mLicensed		= false
		
		var message		= ""
		var days		= 0
		let key			= Data(hex: "9A144A39DFF1E9B818EECFB9D59D7E3A")
		let seed		= Data(hex: "672014793B911351260FE2136D2EA553")

		let licenseKeyData	= Data.init(base64: licenseKey)
		if let decrypt = AES.decrypt(licenseKeyData, key: key, seed: seed) {
			do {
				let license = try JSONDecoder().decode([String : String].self, from: decrypt)
				globals.log.v ("\(license)")
				
				if let strDate = license["date"] {
					if let date = Int(strDate) {
						let expiration_ts	= TimeInterval(date) / 1000		// Data is stored in ms
						let current_ts		= Date().timeIntervalSince1970

						if (current_ts < expiration_ts) {
							days = Int(expiration_ts - current_ts) / 60 / 60 / 24
							
							let formatter = DateComponentsFormatter()
							formatter.allowedUnits = [.year, .month, .day]
							formatter.unitsStyle = .full
							
							let formattedDuration = formatter.string(from: (expiration_ts - current_ts))
							//print(formattedDuration)
							
							message = "License is valid for '\(formattedDuration ?? "Unknown")'"
							
							if let bundle = license["bundle"] {
								if (bundle == "*") {
									message = "Universal bundle: \(message)"
									mLicensed	= true
								}
								else {
									if let bundleID = Bundle.main.bundleIdentifier {
										if (bundleID == bundle) {
											message = "Bundle ID matches: \(message)"
											mLicensed = true
										}
										else {
											message = "Application's Bundle ID does not match licensed bundle ID"
										}
									}
									else {
										message = "Could not retrieve application's bundle ID"
									}
								}
							}
							else {
								message = "No bundle ID given in the license"
							}
						}
						else {
							message = "License is invalid - it has expired"
						}

					}
					else {
						message = "No date in the license"
					}
				}
				else {
					message = "Cannot parse date of license"
				}
			}
			catch {
				message = "Could not decode the license"
			}
		}
		else {
			message = "Could not decrypt the license"
		}
		
		return (mLicensed, days, message)
	}
	#endif

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	@objc public func startScan() -> Bool {
		return startScanWithParameters(inBackground: true, forPaired: true, forUnpaired: true, forLegacy: true)
	}

	@objc public func startScanWithParameters(inBackground: Bool, forPaired: Bool, forUnpaired: Bool, forLegacy: Bool) -> Bool {
		scanInBackground = inBackground
		scanForPaired = forPaired
		scanForUnpaired = forUnpaired
		scanForLegacy = forLegacy
		
		#if KAIROS || UNIVERSAL
		if (!mLicensed) {
			globals.log.e ("Not licensed - cannot start scanning")
			return (false)
		}
		#endif
		
		globals.log.v("InBackground: \(inBackground), forPaired: \(forPaired), forUnpaired: \(forUnpaired), forLegacy: \(forLegacy)")
		
		// See if there were any connected peripherals (which could happen due to a previous instance crash), and disconnect them
		let peripherals = mCentralManager?.retrieveConnectedPeripherals(withServices: Device.scan_services)
		if let peripherals = peripherals {
			if (peripherals.count > 0) {
				globals.log.v ("Found '\(peripherals.count)' previously connected devices (probably due to a crash).  Disconnect them to clean up")
				for peripheral in peripherals {
					globals.log.v ("    Disconnect \(peripheral.identifier)")
					mCentralManager?.cancelPeripheralConnection(peripheral)
				}
			}
		}
		else {
			globals.log.v ("Checking for previously connected peripherals (due to crash).  Didn't find any")
		}
		
		discoveredDevices.removeAll()
		unnamedDevices.removeAll()
		
		if (mCentralManager?.state == .poweredOn) {
			let services	= Device.scan_services
			var options		= [String : Any]()

			options[CBCentralManagerScanOptionAllowDuplicatesKey]		= true

			if (inBackground) {
				mCentralManager?.scanForPeripherals(withServices: services, options: options)
			}
			else {
				mCentralManager?.scanForPeripherals(withServices: nil, options: options)
			}
			return (true)
		}
		
		globals.log.e ("Bluetooth not available")
		return (false)
	}
	
	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	@objc public func stopScan() {
		globals.log.v("")
		
		mCentralManager?.stopScan()
		discoveredDevices.removeAll()
	}
	
	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	@available(*, deprecated, message: "Use the device object's connect function directly.  This will be removed in a future version of the SDK")
	@objc public func connect(_ id: String) {
		globals.log.v("\(id)")
		
		if let device = discoveredDevices.first(where: { $0.id == id }) {
			if let peripheral = device.peripheral {
				device.connectionState = .connecting
				mCentralManager?.connect(peripheral, options: nil)
			}
			else {
				globals.log.e("Peripheral for \(id) does not exist")
			}
		}
		else {
			globals.log.e("Device for \(id) does not exist")
		}
	}
	
	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	@available(*, deprecated, message: "Use the device object's connect function directly.  This will be removed in a future version of the SDK")
	@objc public func disconnect(_ id: String) {
		globals.log.v("\(id)")
		
		if let device = discoveredDevices.first(where: { $0.id == id }), let peripheral = device.peripheral {
			globals.log.v("Found \(id) in discovered list -> trying to disconnect")
			discoveredDevices.removeAll { $0.id == id }
			mCentralManager?.cancelPeripheralConnection(peripheral)
			return
		}
		
		if let device = unnamedDevices.first(where: { $0.id == id }), let peripheral = device.peripheral {
			globals.log.v("Found \(id) in unnamed list -> trying to disconnect")
			unnamedDevices.removeAll { $0.id == id }
			mCentralManager?.cancelPeripheralConnection(peripheral)
			return
		}
		
		if let device = connectedDevices.first(where: { $0.id == id }) {
			if let peripheral = device.peripheral {
				globals.log.v("Found \(id) in connected list -> trying to disconnect")
				mCentralManager?.cancelPeripheralConnection(peripheral)
				return
			}
		}
		
		globals.log.e("Cannot find '\(id)' in connected or discovered list.  Nothing to disconnect")
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	@objc public func getCSVFromDataPackets(_ json: String) -> String {
		do {
			if let jsonData = json.data(using: .utf8) {
				let packets	= try JSONDecoder().decode([biostrapDataPacket].self, from: jsonData)
				
				let csvString	= NSMutableString()
				for packet in packets { csvString.append ("\(packet.csv)\n") }
				let csvResult	= String(csvString)
				return (csvResult)
			}
			else {
				globals.log.e ("Cannot get data from json String")
			}
		}
		catch {
			globals.log.e ("\(error.localizedDescription)")
		}

		return ("")
	}
	
	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	@available(*, deprecated, message: "Send commands to the Device object directly.  This will be removed in a future version of the SDK")
	@objc public func writeEpoch(_ id: String, newEpoch: Int) {
		globals.log.v("\(id): \(newEpoch)")
		
		if let device = connectedDevices.first(where: { $0.id == id }) { device.writeEpoch(newEpoch) }
		else { self.writeEpochComplete?(id, false) }
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	@available(*, deprecated, message: "Send commands to the Device object directly.  This will be removed in a future version of the SDK")
	@objc public func readEpoch(_ id: String) {
		globals.log.v("\(id)")
		
		if let device = connectedDevices.first(where: { $0.id == id }) { device.readEpoch() }
		else { self.readEpochComplete?(id, false, 0) }
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	@available(*, deprecated, message: "Send commands to the Device object directly.  This will be removed in a future version of the SDK")
	@objc public func endSleep(_ id: String) {
		globals.log.v("\(id)")
		
		if let device = connectedDevices.first(where: { $0.id == id }) { device.endSleep() }
		else { self.endSleepComplete?(id, false) }
	}
	
	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	@available(*, deprecated, message: "Send commands to the Device object directly.  This will be removed in a future version of the SDK")
	@objc public func getAllPackets(_ id: String, pages: Int, delay: Int) {
		if let device = connectedDevices.first(where: { $0.id == id }) { device.getAllPackets(pages: pages, delay: delay) }
		else { self.getAllPacketsComplete?(id, false) }
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	@available(*, deprecated, message: "Send commands to the Device object directly.  This will be removed in a future version of the SDK")
	@objc public func getAllPacketsAcknowledge(_ id: String, ack: Bool) {
		if let device = connectedDevices.first(where: { $0.id == id }) { device.getAllPacketsAcknowledge(ack) }
		else { self.getAllPacketsAcknowledgeComplete?(id, false, ack) }
	}
	
	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	@available(*, deprecated, message: "Send commands to the Device object directly.  This will be removed in a future version of the SDK")
	@objc public func getPacketCount(_ id: String) {
		globals.log.v ("\(id)")
		
		if let device = connectedDevices.first(where: { $0.id == id }) { device.getPacketCount() }
		else { self.getPacketCountComplete?(id, false, 0) }
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	@available(*, deprecated, message: "Send commands to the Device object directly.  This will be removed in a future version of the SDK")
	@objc public func disableWornDetect(_ id: String) {
		globals.log.v ("\(id)")
		
		if let device = connectedDevices.first(where: { $0.id == id }) { device.disableWornDetect() }
		else { self.disableWornDetectComplete?(id, false) }
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	@available(*, deprecated, message: "Send commands to the Device object directly.  This will be removed in a future version of the SDK")
	@objc public func enableWornDetect(_ id: String) {
		globals.log.v ("\(id)")
		
		if let device = connectedDevices.first(where: { $0.id == id }) { device.enableWornDetect() }
		else { self.enableWornDetectComplete?(id, false) }
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	@available(*, deprecated, message: "Send commands to the Device object directly.  This will be removed in a future version of the SDK")
	@objc public func startManual(_ id: String, algorithms: ppgAlgorithmConfiguration) {
		globals.log.v ("\(id): Algorithms: \(String(format: "0x%02X", algorithms.commandByte))")
		
		if let device = connectedDevices.first(where: { $0.id == id }) { device.startManual(algorithms) }
		else { self.startManualComplete?(id, false) }
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	@available(*, deprecated, message: "Send commands to the Device object directly.  This will be removed in a future version of the SDK")
	@objc public func stopManual(_ id: String) {
		globals.log.v ("\(id)")
		
		if let device = connectedDevices.first(where: { $0.id == id }) { device.stopManual() }
		else { self.stopManualComplete?(id, false) }
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	@available(*, deprecated, message: "Send commands to the Device object directly.  This will be removed in a future version of the SDK")
	@objc public func userLED(_ id: String, red: Bool, green: Bool, blue: Bool, blink: Bool, seconds: Int) {
		if let device = connectedDevices.first(where: { $0.id == id }) { device.userLED(red: red, green: green, blue: blue, blink: blink, seconds: seconds) }
		else { self.ledComplete?(id, false) }
	}
	
	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	@available(*, deprecated, message: "Send commands to the Device object directly.  This will be removed in a future version of the SDK")
	@objc public func enterShipMode(_ id: String) {
		if let device = connectedDevices.first(where: { $0.id == id }) { device.enterShipMode() }
		else { self.enterShipModeComplete?(id, false) }
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	@available(*, deprecated, message: "Send commands to the Device object directly.  This will be removed in a future version of the SDK")
	@objc public func writeSerialNumber(_ id: String, partID: String) {
		if let device = connectedDevices.first(where: { $0.id == id }) { device.writeSerialNumber(partID) }
		else { self.writeSerialNumberComplete?(id, false) }
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	@available(*, deprecated, message: "Send commands to the Device object directly.  This will be removed in a future version of the SDK")
	@objc public func readSerialNumber(_ id: String) {
		if let device = connectedDevices.first(where: { $0.id == id }) { device.readSerialNumber() }
		else { self.readSerialNumberComplete?(id, false, "") }
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	@available(*, deprecated, message: "Send commands to the Device object directly.  This will be removed in a future version of the SDK")
	@objc public func deleteSerialNumber(_ id: String) {
		if let device = connectedDevices.first(where: { $0.id == id }) { device.deleteSerialNumber() }
		else { self.deleteSerialNumberComplete?(id, false) }
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	@available(*, deprecated, message: "Send commands to the Device object directly.  This will be removed in a future version of the SDK")
	@objc public func writeAdvInterval(_ id: String, seconds: Int) {
		if let device = connectedDevices.first(where: { $0.id == id }) { device.writeAdvInterval(seconds) }
		else { self.writeAdvIntervalComplete?(id, false) }
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	@available(*, deprecated, message: "Send commands to the Device object directly.  This will be removed in a future version of the SDK")
	@objc public func readAdvInterval(_ id: String) {
		if let device = connectedDevices.first(where: { $0.id == id }) { device.readAdvInterval() }
		else { self.readAdvIntervalComplete?(id, false, 0) }
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	@available(*, deprecated, message: "Send commands to the Device object directly.  This will be removed in a future version of the SDK")
	@objc public func deleteAdvInterval(_ id: String) {
		if let device = connectedDevices.first(where: { $0.id == id }) { device.deleteAdvInterval() }
		else { self.deleteAdvIntervalComplete?(id, false) }
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	@available(*, deprecated, message: "Send commands to the Device object directly.  This will be removed in a future version of the SDK")
	@objc public func clearChargeCycles(_ id: String) {
		if let device = connectedDevices.first(where: { $0.id == id }) { device.clearChargeCycles() }
		else { self.clearChargeCyclesComplete?(id, false) }
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	@available(*, deprecated, message: "Send commands to the Device object directly.  This will be removed in a future version of the SDK")
	@objc public func readChargeCycles(_ id: String) {
		if let device = connectedDevices.first(where: { $0.id == id }) { device.readChargeCycles() }
		else { self.readChargeCyclesComplete?(id, false, 0) }
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	@available(*, deprecated, message: "Send commands to the Device object directly.  This will be removed in a future version of the SDK")
	@objc public func readCanLogDiagnostics(_ id: String) {
		if let device = connectedDevices.first(where: { $0.id == id }) { device.readCanLogDiagnostics() }
		else { self.readCanLogDiagnosticsComplete?(id, false, false) }
	}
	
	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	@available(*, deprecated, message: "Send commands to the Device object directly.  This will be removed in a future version of the SDK")
	@objc public func updateCanLogDiagnostics(_ id: String, allow: Bool) {
		if let device = connectedDevices.first(where: { $0.id == id }) { device.updateCanLogDiagnostics(allow) }
		else { self.updateCanLogDiagnosticsComplete?(id, false) }
	}
		
	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------	
	#if ALTER
	@available(*, deprecated, message: "Send commands to the Device object directly.  This will be removed in a future version of the SDK")
	@objc public func manufacturingTest(_ id: String, test: alterManufacturingTestType) {
		if let device = connectedDevices.first(where: { $0.id == id }) { device.alterManufacturingTest(test) }
		else { self.manufacturingTestComplete?(id, false) }
	}
	#endif

	#if KAIROS
	@available(*, deprecated, message: "Send commands to the Device object directly.  This will be removed in a future version of the SDK")
	@objc public func manufacturingTest(_ id: String, test: kairosManufacturingTestType) {
		if let device = connectedDevices.first(where: { $0.id == id }) { device.kairosManufacturingTest(test) }
		else { self.manufacturingTestComplete?(id, false) }
	}
	#endif

	#if UNIVERSAL
	@available(*, deprecated, message: "Send commands to the Device object directly.  This will be removed in a future version of the SDK")
	@objc public func alterManufacturingTest(_ id: String, test: alterManufacturingTestType) {
		if let device = connectedDevices.first(where: { $0.id == id }) { device.alterManufacturingTest(test) }
		else { self.manufacturingTestComplete?(id, false) }
	}
	
	@available(*, deprecated, message: "Send commands to the Device object directly.  This will be removed in a future version of the SDK")
	@objc public func kairosManufacturingTest(_ id: String, test: kairosManufacturingTestType) {
		if let device = connectedDevices.first(where: { $0.id == id }) { device.kairosManufacturingTest(test) }
		else { self.manufacturingTestComplete?(id, false) }
	}
	#endif

	//--------------------------------------------------------------------------------
	// Function Name: setAskForButtonResponse
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	@available(*, deprecated, message: "Send commands to the Device object directly.  This will be removed in a future version of the SDK")
	@objc public func setAskForButtonResponse(_ id: String, enable: Bool) {
		if let device = connectedDevices.first(where: { $0.id == id }) { device.setAskForButtonResponse(enable) }
		else { self.setAskForButtonResponseComplete?(id, false, enable) }
	}
	
	//--------------------------------------------------------------------------------
	// Function Name: getAskForButtonResponse
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	@available(*, deprecated, message: "Send commands to the Device object directly.  This will be removed in a future version of the SDK")
	@objc public func getAskForButtonResponse(_ id: String) {
		if let device = connectedDevices.first(where: { $0.id == id }) { device.getAskForButtonResponse() }
		else { self.getAskForButtonResponseComplete?(id, false, false) }
	}

	//--------------------------------------------------------------------------------
	// Function Name: setHRZoneColor
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	@available(*, deprecated, message: "Send commands to the Device object directly.  This will be removed in a future version of the SDK")
	@objc public func setHRZoneColor(_ id: String, type: hrZoneRangeType, red: Bool, green: Bool, blue: Bool, on_milliseconds: Int, off_milliseconds: Int) {
		if let device = connectedDevices.first(where: { $0.id == id }) {
			device.setHRZoneColor(type, red: red, green: green, blue: blue, on_milliseconds: on_milliseconds, off_milliseconds: off_milliseconds)
		}
		else { self.setHRZoneColorComplete?(id, false, type) }
	}
	
	//--------------------------------------------------------------------------------
	// Function Name: getHRZoneColor
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	@available(*, deprecated, message: "Send commands to the Device object directly.  This will be removed in a future version of the SDK")
	@objc public func getHRZoneColor(_ id: String, type: hrZoneRangeType) {
		if let device = connectedDevices.first(where: { $0.id == id }) { device.getHRZoneColor(type) }
		else { self.getHRZoneColorComplete?(id, false, type, false, false, false, 0, 0) }
	}
	
	//--------------------------------------------------------------------------------
	// Function Name: setHRZoneRange
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	@available(*, deprecated, message: "Send commands to the Device object directly.  This will be removed in a future version of the SDK")
	@objc public func setHRZoneRange(_ id: String, enabled: Bool, high_value: Int, low_value: Int) {
		if let device = connectedDevices.first(where: { $0.id == id }) {
			device.setHRZoneRange(enabled, high_value: high_value, low_value: low_value)
		}
		else { self.setHRZoneRangeComplete?(id, false) }
	}
	
	//--------------------------------------------------------------------------------
	// Function Name: getHRZoneRange
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	@available(*, deprecated, message: "Send commands to the Device object directly.  This will be removed in a future version of the SDK")
	@objc public func getHRZoneRange(_ id: String) {
		if let device = connectedDevices.first(where: { $0.id == id }) { device.getHRZoneRange() }
		else { self.getHRZoneRangeComplete?(id, false, false, 0, 0) }
	}
	
	//--------------------------------------------------------------------------------
	// Function Name: getPPGAlgorithm
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	@available(*, deprecated, message: "Send commands to the Device object directly.  This will be removed in a future version of the SDK")
	@objc public func getPPGAlgorithm(_ id: String) {
		if let device = connectedDevices.first(where: { $0.id == id }) { device.getPPGAlgorithm() }
		else { self.getPPGAlgorithmComplete?(id, false, ppgAlgorithmConfiguration(), eventType.unknown) }
	}
	
	//--------------------------------------------------------------------------------
	// Function Name: setAdvertiseAsHRM
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	@available(*, deprecated, message: "Send commands to the Device object directly.  This will be removed in a future version of the SDK")
	@objc public func setAdvertiseAsHRM(_ id: String, asHRM: Bool) {
		if let device = connectedDevices.first(where: { $0.id == id }) { device.setAdvertiseAsHRM(asHRM) }
		else { self.setAdvertiseAsHRMComplete?(id, false, false) }
	}
	
	//--------------------------------------------------------------------------------
	// Function Name: getAdvertiseAsHRM
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	@available(*, deprecated, message: "Send commands to the Device object directly.  This will be removed in a future version of the SDK")
	@objc public func getAdvertiseAsHRM(_ id: String) {
		if let device = connectedDevices.first(where: { $0.id == id }) { device.getAdvertiseAsHRM() }
		else { self.getAdvertiseAsHRMComplete?(id, false, false) }
	}

	//--------------------------------------------------------------------------------
	// Function Name: setButtonCommand
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	@available(*, deprecated, message: "Send commands to the Device object directly.  This will be removed in a future version of the SDK")
	@objc public func setButtonCommand(_ id: String, tap: buttonTapType, command: buttonCommandType) {
		if let device = connectedDevices.first(where: { $0.id == id }) { device.setButtonCommand(tap, command: command) }
		else { self.setButtonCommandComplete?(id, false, tap, command) }
	}
	
	//--------------------------------------------------------------------------------
	// Function Name: getButtonCommand
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	@available(*, deprecated, message: "Send commands to the Device object directly.  This will be removed in a future version of the SDK")
	@objc public func getButtonCommand(_ id: String, tap: buttonTapType) {
		if let device = connectedDevices.first(where: { $0.id == id }) { device.getButtonCommand(tap) }
		else { self.getButtonCommandComplete?(id, false, tap, .unknown) }
	}
	
	//--------------------------------------------------------------------------------
	// Function Name: setPaired
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	@available(*, deprecated, message: "Send commands to the Device object directly.  This will be removed in a future version of the SDK")
	@objc public func setPaired(_ id: String) {
		if let device = connectedDevices.first(where: { $0.id == id }) { device.setPaired() }
		else { self.setPairedComplete?(id, false) }
	}
	
	//--------------------------------------------------------------------------------
	// Function Name: setUnpaired
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	@available(*, deprecated, message: "Send commands to the Device object directly.  This will be removed in a future version of the SDK")
	@objc public func setUnpaired(_ id: String) {
		if let device = connectedDevices.first(where: { $0.id == id }) { device.setUnpaired() }
		else { self.setUnpairedComplete?(id, false) }
	}
	
	//--------------------------------------------------------------------------------
	// Function Name: getPaired
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	@available(*, deprecated, message: "Send commands to the Device object directly.  This will be removed in a future version of the SDK")
	@objc public func getPaired(_ id: String) {
		if let device = connectedDevices.first(where: { $0.id == id }) { device.getPaired() }
		else { self.getPairedComplete?(id, false, false) }
	}
	
	//--------------------------------------------------------------------------------
	// Function Name: setPaired
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	@available(*, deprecated, message: "Send commands to the Device object directly.  This will be removed in a future version of the SDK")
	@objc public func setPageThreshold(_ id: String, threshold: Int) {
		if let device = connectedDevices.first(where: { $0.id == id }) { device.setPageThreshold(threshold) }
		else { self.setPageThresholdComplete?(id, false) }
	}
	
	//--------------------------------------------------------------------------------
	// Function Name: setUnpaired
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	@available(*, deprecated, message: "Send commands to the Device object directly.  This will be removed in a future version of the SDK")
	@objc public func getPageThreshold(_ id: String) {
		if let device = connectedDevices.first(where: { $0.id == id }) { device.getPageThreshold() }
		else { self.getPageThresholdComplete?(id, false, 1) }
	}
	
	//--------------------------------------------------------------------------------
	// Function Name: getPaired
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	@available(*, deprecated, message: "Send commands to the Device object directly.  This will be removed in a future version of the SDK")
	@objc public func deletePageThreshold(_ id: String) {
		if let device = connectedDevices.first(where: { $0.id == id }) { device.deletePageThreshold() }
		else { self.deletePageThresholdComplete?(id, false) }
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	@available(*, deprecated, message: "Send commands to the Device object directly.  This will be removed in a future version of the SDK")
	@objc public func wornCheck(_ id: String) {
		if let device = connectedDevices.first(where: { $0.id == id }) { device.wornCheck() }
		else { self.wornCheckComplete?(id, false, "No device", 0) }
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	@available(*, deprecated, message: "Send commands to the Device object directly.  This will be removed in a future version of the SDK")
	@objc public func rawLogging(_ id: String, enable: Bool) {
		if let device = connectedDevices.first(where: { $0.id == id }) { device.rawLogging(enable) }
		else { self.rawLoggingComplete?(id, false) }
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	@available(*, deprecated, message: "Send commands to the Device object directly.  This will be removed in a future version of the SDK")
	@objc public func getRawLoggingStatus(_ id: String) {
		if let device = connectedDevices.first(where: { $0.id == id }) { device.getRawLoggingStatus() }
		else { self.getRawLoggingStatusComplete?(id, false, false) }
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	@available(*, deprecated, message: "Send commands to the Device object directly.  This will be removed in a future version of the SDK")
	@objc public func getWornOverrideStatus(_ id: String) {
		if let device = connectedDevices.first(where: { $0.id == id }) { device.getWornOverrideStatus() }
		else { self.getWornOverrideStatusComplete?(id, false, false) }
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	@available(*, deprecated, message: "Send commands to the Device object directly.  This will be removed in a future version of the SDK")
	@objc public func airplaneMode(_ id: String) {
		if let device = connectedDevices.first(where: { $0.id == id }) { device.airplaneMode() }
		else { self.airplaneModeComplete?(id, false) }
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	@available(*, deprecated, message: "Send commands to the Device object directly.  This will be removed in a future version of the SDK")
	@objc public func reset(_ id: String) {
		if let device = connectedDevices.first(where: { $0.id == id }) { device.reset() }
		else { self.resetComplete?(id, false) }
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	@available(*, deprecated, message: "Send commands to the Device object directly.  This will be removed in a future version of the SDK")
	@objc public func updateFirmware(_ id: String, file: URL) {
		if let device = connectedDevices.first(where: { $0.id == id }) { device.updateFirmware(file) }
		else { self.updateFirmwareFailed?(id, 10000, "No connected device to update") }

	}
	
	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	@available(*, deprecated, message: "Send commands to the Device object directly.  This will be removed in a future version of the SDK")
	@objc public func cancelFirmwareUpdate(_ id: String) {
		if let device = connectedDevices.first(where: { $0.id == id }) { device.cancelFirmwareUpdate() }
		else { self.updateFirmwareFailed?(id, 10000, "No connected device to update") }
	}
	
	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	@available(*, deprecated, message: "Send commands to the Device object directly.  This will be removed in a future version of the SDK")
	@objc public func setSessionParam(_ id: String, parameter: sessionParameterType, value: Int) {
		if let device = connectedDevices.first(where: { $0.id == id }) { device.setSessionParam(parameter, value: value) }
		else { self.setSessionParamComplete?(id, false, parameter) }

	}
	
	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	@available(*, deprecated, message: "Send commands to the Device object directly.  This will be removed in a future version of the SDK")
	@objc public func getSessionParam(_ id: String, parameter: sessionParameterType) {
		if let device = connectedDevices.first(where: { $0.id == id }) { device.getSessionParam(parameter) }
		else { self.getSessionParamComplete?(id, false, parameter, 0) }
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	@available(*, deprecated, message: "Send commands to the Device object directly.  This will be removed in a future version of the SDK")
	@objc public func resetSessionParams(_ id: String) {
		if let device = connectedDevices.first(where: { $0.id == id }) { device.resetSessionParams() }
		else { self.resetSessionParamsComplete?(id, false) }
	}
	
	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	@available(*, deprecated, message: "Send commands to the Device object directly.  This will be removed in a future version of the SDK")
	@objc public func acceptSessionParams(_ id: String) {
        guard let device = connectedDevices.first(where: { $0.id == id }) else {
            self.acceptSessionParamsComplete?(id, false)
            return
        }
        device.acceptSessionParams()
	}

    //--------------------------------------------------------------------------------
    // Function Name:
    //--------------------------------------------------------------------------------
    //
    //
    //
    //--------------------------------------------------------------------------------
    @objc public func runSessionFile(_ id: String, file: URL, offset: Int) {
        globals.log.v ("\(id): \(file) \(offset) seconds")
        
        guard let device = connectedDevices.first(where: { $0.id == id }) else {
            globals.log.e ("Cannot find device to run session to")
            return
        }

        var packet = Data()
        var packets = [Data]()
        
        do {
            let fileContents = try String(contentsOf: file)
            let lines = fileContents.components(separatedBy: "\n")
            
            // Build data packets - maximum size of each packet will be 200 bytes
            for line in lines {
                let pieces = line.split(separator: ",")
                if pieces.count > 0 {
                    let rawString = String(pieces[0])
                    let raw = rawString.replacingOccurrences(of: " ", with: "").replacingOccurrences(of: "[", with: "").replacingOccurrences(of: "]", with: "")
                    let bytes = Data(hex: raw)
                    
                    if packet.count + bytes.count > 200 {
                        let sequence = packets.count.leData16
                        packet.insert(contentsOf: sequence, at: 0)
                        packet.insert(CharacteristicTemplate.notifications.dataPacket.rawValue, at: 0)
                        packets.append(packet)
                        packet.removeAll()
                    }
                    
                    packet.append(bytes)
                }
            }

            // Build data caught up packet
            packet.removeAll()
            packet.append(CharacteristicTemplate.notifications.dataCaughtUp.rawValue)
            packet.append(0x00) // Lower byte of bad_read_count
            packet.append(0x00) // Upper byte of bad_read_count
            packet.append(0x00) // Lower byte of bad_parse_count
            packet.append(0x00) // Upper byte of bad_parse_count
            packet.append(0x00) // Lower byte of overflow_count
            packet.append(0x00) // Upper byte of overflow_count
            packet.append(0x00) // Intermediate
            packets.append(packet)

            // Send data packets and the data caught up packet
            for packet in packets {
                device.didUpdateValue(packet, offset: offset)
            }

        } catch {
            globals.log.e ("Cannot convert file data into array")
        }
    }
}


// MARK: Version
extension biostrapDeviceSDK {
	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	internal func mSDKVersion() -> String {
		return Bundle(for: type(of: self)).object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
	}
	
	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	internal func mSDKBuild() -> String {
		return Bundle(for: type(of: self)).object(forInfoDictionaryKey: kCFBundleVersionKey as String) as! String
	}
	
}

