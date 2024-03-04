//
//  biostrapDeviceSDK.swift
//  biostrapDeviceSDK
//
//  Created by Joseph A. Bennett on 3/31/21.
//

import Foundation
import CoreBluetooth

@objc public class biostrapDeviceSDK: NSObject {
	
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
	
	// Lambdas
	@objc public var logV: ((_ message: String?, _ file: String, _ function: String, _ line: Int)->())?
	@objc public var logD: ((_ message: String?, _ file: String, _ function: String, _ line: Int)->())?
	@objc public var logI: ((_ message: String?, _ file: String, _ function: String, _ line: Int)->())?
	@objc public var logW: ((_ message: String?, _ file: String, _ function: String, _ line: Int)->())?
	@objc public var logE: ((_ message: String?, _ file: String, _ function: String, _ line: Int)->())?
	
	@objc public var bluetoothReady: ((_ isOn: Bool)->())?
	@objc public var discovered: ((_ id: String, _ device: Device)->())?
	@objc public var discoveredUnnamed: ((_ id: String, _ device: Device)->())?
	
	@objc public var connected: ((_ id: String)->())?
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
	@objc public var allowPPGComplete: ((_ id: String, _ successful: Bool)->())?
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
	internal func mGetDevicesSortedByTime(_ devices: [ String : Device]) -> [ Device ] {
		var list			= [ Device ]()
		var devDictionary	= [ TimeInterval : Device ]()

		let keys			= Array(devices.keys)
		
		for key in keys {
			if let device = devices[key] {
				devDictionary[device.creation_epoch]	= device
			}
		}

		let timeKeys	= Array(devDictionary.keys).sorted()
		for timeKey in timeKeys {
			if let device = devDictionary[timeKey] {
				list.append(device)
			}
		}
		
		return (list)
	}
	
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	@objc public var connectedDevices: [ Device ] {
		return (mGetDevicesSortedByTime(mConnectedDevices))
	}
	
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	@objc public var discoveredDevices: [ Device ] {
		return (mGetDevicesSortedByTime(mDiscoveredDevices))
	}
	
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
	internal var mCentralManager	: CBCentralManager?
	internal var mDiscoveredDevices	= [ String : Device ]()
	internal var mConnectedDevices	= [ String : Device ]()
	internal lazy var mPairedDeviceNames	= [ String: String ]()
	internal var mLicensed			: Bool = false

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
		
		log						= Logging()
		log?.log	= { level, message, file, function, line in
			switch (level) {
			case .verbose:	self.logV?(message, file, function, line)
			case .debug:	self.logD?(message, file, function, line)
			case .info:		self.logI?(message, file, function, line)
			case .warning:	self.logW?(message, file, function, line)
			case .error:	self.logE?(message, file, function, line)
			}
		}
				
		let backgroundQueue	= DispatchQueue.global(qos: DispatchQoS.QoSClass.background)
		mCentralManager		= CBCentralManager(delegate: self, queue: backgroundQueue, options: [CBCentralManagerOptionRestoreIdentifierKey: Bundle.main.bundleIdentifier ?? ""])
		
		mDiscoveredDevices	= [ String : Device ]()
		mConnectedDevices	= [ String : Device ]()
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
				log?.v ("\(license)")
				
				if let strDate = license["date"] {
					if let date = Int(strDate) {
						let expiration_ts	= TimeInterval(date) / 1000		// Data is stored in ms
						let current_ts		= Date().timeIntervalSince1970

						if (current_ts < expiration_ts) {
							days = Int(expiration_ts - current_ts) / 60 / 60 / 24
							message = "License is valid for '\(days)' more days"
							
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
	@objc public func startScan(inBackground: Bool = false, forPaired: Bool = true, forUnpaired: Bool = true, forLegacy: Bool = true) -> Bool {
		scanInBackground = inBackground
		scanForPaired = forPaired
		scanForUnpaired = forUnpaired
		scanForLegacy = forLegacy
		
		#if KAIROS || UNIVERSAL
		if (!mLicensed) {
			log?.e ("Not licensed - cannot start scanning")
			return (false)
		}
		#endif
		
		log?.v("")
		
		// See if there were any connected peripherals (which could happen due to a previous instance crash), and disconnect them
		let peripherals = mCentralManager?.retrieveConnectedPeripherals(withServices: Device.scan_services)
		if let peripherals = peripherals {
			if (peripherals.count > 0) {
				log?.v ("Found '\(peripherals.count)' previously connected devices (probably due to a crash).  Disconnect them to clean up")
				for peripheral in peripherals {
					log?.v ("    Disconnect \(peripheral.identifier)")
					mCentralManager?.cancelPeripheralConnection(peripheral)
				}
			}
		}
		else {
			log?.v ("Checking for previously connected peripherals (due to crash).  Didn't find any")
		}
		
		mDiscoveredDevices.removeAll()
		
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
		log?.v("")
		
		mCentralManager?.stopScan()
		mDiscoveredDevices.removeAll()
	}
	
	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	@objc public func connect(_ id: String) {
		log?.v("\(id)")
		
		if let device = mDiscoveredDevices[id] {
			if let peripheral = device.peripheral {
				device.connectionState = .connecting
				mCentralManager?.connect(peripheral, options: nil)
			}
			else {
				log?.e("Peripheral for \(id) does not exist")
			}
		}
		else {
			log?.e("Device for \(id) does not exist")
		}
	}
	
	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	@objc public func disconnect(_ id: String) {
		log?.v("\(id)")
		
		if let device = mDiscoveredDevices[id] {
			if let peripheral = device.peripheral {
				log?.v("Found \(id) in discovered list -> trying to disconnect")
				mDiscoveredDevices.removeValue(forKey: id)
				mCentralManager?.cancelPeripheralConnection(peripheral)
				return
			}
		}
		
		if let device = mConnectedDevices[id] {
			if let peripheral = device.peripheral {
				log?.v("Found \(id) in connected list -> trying to disconnect")
				mCentralManager?.cancelPeripheralConnection(peripheral)
				return
			}
		}
		
		log?.e("Cannot find '\(id)' in connected or discovered list.  Nothing to disconnect")
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
				log?.e ("Cannot get data from json String")
			}
		}
		catch {
			log?.e ("\(error.localizedDescription)")
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
		log?.v("\(id): \(newEpoch)")
		
		if let device = mConnectedDevices[id] { device.writeEpochInternal(newEpoch) }
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
		log?.v("\(id)")
		
		if let device = mConnectedDevices[id] { device.readEpochInternal() }
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
		log?.v("\(id)")
		
		if let device = mConnectedDevices[id] { device.endSleepInternal() }
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
		if let device = mConnectedDevices[id] { device.getAllPackets(pages: pages, delay: delay) }
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
		if let device = mConnectedDevices[id] { device.getAllPacketsAcknowledgeInternal(ack) }
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
		log?.v ("\(id)")
		
		if let device = mConnectedDevices[id] { device.getPacketCountInternal() }
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
		log?.v ("\(id)")
		
		if let device = mConnectedDevices[id] { device.disableWornDetectInternal() }
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
		log?.v ("\(id)")
		
		if let device = mConnectedDevices[id] { device.enableWornDetectInternal() }
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
		log?.v ("\(id): Algorithms: \(String(format: "0x%02X", algorithms.commandByte))")
		
		if let device = mConnectedDevices[id] { device.startManual(algorithms) }
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
		log?.v ("\(id)")
		
		if let device = mConnectedDevices[id] { device.stopManual() }
		else { self.stopManualComplete?(id, false) }
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	#if UNIVERSAL
	@available(*, deprecated, message: "Send commands to the Device object directly.  This will be removed in a future version of the SDK")
	@available(*, deprecated, message: "Send commands to the Device object directly.  This will be removed in a future version of the SDK")
	@objc public func alterLED(_ id: String, red: Bool, green: Bool, blue: Bool, blink: Bool, seconds: Int) {
		if let device = mConnectedDevices[id] { device.alterLEDInternal(red: red, green: green, blue: blue, blink: blink, seconds: seconds) }
		else { self.ledComplete?(id, false) }
	}
	
	@available(*, deprecated, message: "Send commands to the Device object directly.  This will be removed in a future version of the SDK")
	@objc public func kairosLED(_ id: String, red: Bool, green: Bool, blue: Bool, blink: Bool, seconds: Int) {
		if let device = mConnectedDevices[id] { device.kairosLEDInternal(red: red, green: green, blue: blue, blink: blink, seconds: seconds) }
		else { self.ledComplete?(id, false) }
	}
	#endif

	#if ALTER
	@available(*, deprecated, message: "Send commands to the Device object directly.  This will be removed in a future version of the SDK")
	@objc public func led(_ id: String, red: Bool, green: Bool, blue: Bool, blink: Bool, seconds: Int) {
		if let device = mConnectedDevices[id] { device.alterLEDInternal(red: red, green: green, blue: blue, blink: blink, seconds: seconds) }
		else { self.ledComplete?(id, false) }
	}
	#endif

	#if KAIROS
	@available(*, deprecated, message: "Send commands to the Device object directly.  This will be removed in a future version of the SDK")
	@objc public func led(_ id: String, red: Bool, green: Bool, blue: Bool, blink: Bool, seconds: Int) {
		if let device = mConnectedDevices[id] { device.kairosLEDInternal(red: red, green: green, blue: blue, blink: blink, seconds: seconds) }
		else { self.ledComplete?(id, false) }
	}
	#endif

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	@available(*, deprecated, message: "Send commands to the Device object directly.  This will be removed in a future version of the SDK")
	@objc public func enterShipMode(_ id: String) {
		if let device = mConnectedDevices[id] { device.enterShipModeInternal() }
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
		if let device = mConnectedDevices[id] { device.writeSerialNumberInternal(partID) }
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
		if let device = mConnectedDevices[id] { device.readSerialNumberInternal() }
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
		if let device = mConnectedDevices[id] { device.deleteSerialNumberInternal() }
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
		if let device = mConnectedDevices[id] { device.writeAdvIntervalInternal(seconds) }
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
		if let device = mConnectedDevices[id] { device.readAdvIntervalInternal() }
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
		if let device = mConnectedDevices[id] { device.deleteAdvIntervalInternal() }
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
		if let device = mConnectedDevices[id] { device.clearChargeCyclesInternal() }
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
		if let device = mConnectedDevices[id] { device.readChargeCyclesInternal() }
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
		if let device = mConnectedDevices[id] { device.readCanLogDiagnosticsInternal() }
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
		if let device = mConnectedDevices[id] { device.updateCanLogDiagnosticsInternal(allow) }
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
		if let device = mConnectedDevices[id] { device.alterManufacturingTestInternal(id, test: test) }
		else { self.lambdaManufacturingTestComplete?(id, false) }
	}
	#endif

	#if KAIROS
	@available(*, deprecated, message: "Send commands to the Device object directly.  This will be removed in a future version of the SDK")
	@objc public func manufacturingTest(_ id: String, test: kairosManufacturingTestType) {
		if let device = mConnectedDevices[id] { device.kairosManufacturingTestInternal(id, test: test) }
		else { self.lambdaManufacturingTestComplete?(id, false) }
	}
	#endif

	#if UNIVERSAL
	@available(*, deprecated, message: "Send commands to the Device object directly.  This will be removed in a future version of the SDK")
	@objc public func alterManufacturingTest(_ id: String, test: alterManufacturingTestType) {
		if let device = mConnectedDevices[id] { device.alterManufacturingTestInternal(test) }
		else { self.manufacturingTestComplete?(id, false) }
	}
	
	@available(*, deprecated, message: "Send commands to the Device object directly.  This will be removed in a future version of the SDK")
	@objc public func kairosManufacturingTest(_ id: String, test: kairosManufacturingTestType) {
		if let device = mConnectedDevices[id] { device.kairosManufacturingTestInternal(test) }
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
		if let device = mConnectedDevices[id] { device.setAskForButtonResponseInternal(enable) }
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
		if let device = mConnectedDevices[id] { device.getAskForButtonResponseInternal() }
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
		if let device = mConnectedDevices[id] {
			device.setHRZoneColorInternal(type, red: red, green: green, blue: blue, on_milliseconds: on_milliseconds, off_milliseconds: off_milliseconds)
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
		if let device = mConnectedDevices[id] { device.getHRZoneColorInternal(type) }
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
		if let device = mConnectedDevices[id] {
			device.setHRZoneRangeInternal(enabled, high_value: high_value, low_value: low_value)
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
		if let device = mConnectedDevices[id] { device.getHRZoneRangeInternal() }
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
		if let device = mConnectedDevices[id] { device.getPPGAlgorithmInternal() }
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
		if let device = mConnectedDevices[id] { device.setAdvertiseAsHRMInternal(asHRM) }
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
		if let device = mConnectedDevices[id] { device.getAdvertiseAsHRMInternal() }
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
		if let device = mConnectedDevices[id] { device.setButtonCommandInternal(tap, command: command) }
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
		if let device = mConnectedDevices[id] { device.getButtonCommandInternal(tap) }
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
		if let device = mConnectedDevices[id] { device.setPairedInternal() }
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
		if let device = mConnectedDevices[id] { device.setUnpairedInternal() }
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
		if let device = mConnectedDevices[id] { device.getPairedInternal() }
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
		if let device = mConnectedDevices[id] { device.setPageThresholdInternal(threshold) }
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
		if let device = mConnectedDevices[id] { device.getPageThresholdInternal() }
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
		if let device = mConnectedDevices[id] { device.deletePageThresholdInternal() }
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
		if let device = mConnectedDevices[id] { device.wornCheckInternal() }
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
		if let device = mConnectedDevices[id] { device.rawLoggingInternal(enable) }
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
		if let device = mConnectedDevices[id] { device.getRawLoggingStatusInternal() }
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
		if let device = mConnectedDevices[id] { device.getWornOverrideStatusInternal() }
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
		if let device = mConnectedDevices[id] { device.airplaneModeInternal() }
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
		if let device = mConnectedDevices[id] { device.resetInternal() }
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
		if let device = mConnectedDevices[id] { device.updateFirmwareInternal(file) }
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
		if let device = mConnectedDevices[id] { device.cancelFirmwareUpdateInternal() }
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
		if let device = mConnectedDevices[id] { device.setSessionParamInternal(parameter, value: value) }
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
		if let device = mConnectedDevices[id] { device.getSessionParamInternal(parameter) }
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
		if let device = mConnectedDevices[id] { device.resetSessionParamsInternal() }
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
		if let device = mConnectedDevices[id] { device.acceptSessionParamsInternal() }
		else { self.acceptSessionParamsComplete?(id, false) }
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

