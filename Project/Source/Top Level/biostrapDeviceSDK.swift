//
//  biostrapDeviceSDK.swift
//  biostrapDeviceSDK
//
//  Created by Joseph A. Bennett on 3/31/21.
//

import Foundation
import CoreBluetooth
#if UNIVERSAL || LIVOTAL
import iOSDFULibrary
#endif

@objc public class biostrapDeviceSDK: NSObject {
	
	var dataPacketsOnBackgroundThread	= false
	
	#if UNIVERSAL
	@objc public enum biostrapDeviceType: Int {
		case livotal	= 1
		case ethos		= 2
		case alter		= 3
		case kairos		= 4
		case unknown	= 99
		
		public var title: String {
			switch (self) {
			case .livotal	: return "Livotal"
			case .ethos		: return "Ethos"
			case .alter		: return "Alter"
			case .kairos	: return "Kairos"
			case .unknown	: return "Unknown"
			}
		}
	}
	#endif
	
	#if UNIVERSAL || ETHOS
	@objc public enum ethosLEDMode: Int {
		case blink		= 0
		case fade		= 1
		case sweep		= 2
		case pulse		= 3
		case sparkle	= 4
		case percent	= 5
		
		public var title: String {
			switch (self) {
			case .blink		: return "Blink"
			case .fade		: return "Fade"
			case .sweep		: return "Sweep"
			case .pulse		: return "Pulse"
			case .sparkle	: return "Sparkle"
			case .percent	: return "Percent"
			}
		}
		
		public var value: UInt8 {
			return UInt8(self.rawValue)
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
	#if UNIVERSAL
	@objc public var discovered: ((_ id: String, _ type: biostrapDeviceType)->())?
	#else
	@objc public var discovered: ((_ id: String)->())?
	#endif
	
	@objc public var connected: ((_ id: String)->())?
	@objc public var disconnected: ((_ id: String)->())?
	
	@objc public var writeEpochComplete: ((_ id: String, _ successful: Bool)->())?
	@objc public var readEpochComplete: ((_ id: String, _ successful: Bool, _ value: Int)->())?
	@objc public var endSleepComplete: ((_ id: String, _ successful: Bool)->())?
	#if UNIVERSAL || ETHOS
	@objc public var debugComplete: ((_ id: String, _ successful: Bool, _ device: debugDevice, _ data: Data)->())?
	#endif
	@objc public var getAllPacketsComplete: ((_ id: String, _ successful: Bool)->())?
	@objc public var getNextPacketComplete: ((_ id: String, _ successful: Bool, _ error_code: nextPacketStatusType, _ caughtUp: Bool, _ packet: String)->())?
	@objc public var getPacketCountComplete: ((_ id: String, _ successful: Bool, _ count: Int)->())?
	@objc public var startManualComplete: ((_ id: String, _ successful: Bool)->())?
	@objc public var stopManualComplete: ((_ id: String, _ successful: Bool)->())?
	@objc public var ledComplete: ((_ id: String, _ successful: Bool)->())?
	#if UNIVERSAL || ETHOS
	@objc public var motorComplete: ((_ id: String, _ successful: Bool)->())?
	#endif
	@objc public var enterShipModeComplete: ((_ id: String, _ successful: Bool)->())?
	
	@objc public var writeSerialNumberComplete: ((_ id: String, _ successful: Bool)->())?
	@objc public var readSerialNumberComplete: ((_ id: String, _ successful: Bool, _ partID: String)->())?
	@objc public var deleteSerialNumberComplete: ((_ id: String, _ successful: Bool)->())?
	@objc public var writeAdvIntervalComplete: ((_ id: String, _ successful: Bool)->())?
	@objc public var readAdvIntervalComplete: ((_ id: String, _ successful: Bool, _ seconds: Int)->())?
	@objc public var deleteAdvIntervalComplete: ((_ id: String, _ successful: Bool)->())?
	@objc public var clearChargeCyclesComplete: ((_ id: String, _ successful: Bool)->())?
	@objc public var readChargeCyclesComplete: ((_ id: String, _ successful: Bool, _ cycles: Float)->())?
	@objc public var readCanLogDiagnosticsComplete: ((_ id: String, _ successful: Bool, _ allow: Bool)->())?
	@objc public var updateCanLogDiagnosticsComplete: ((_ id: String, _ successful: Bool)->())?

	@objc public var allowPPGComplete: ((_ id: String, _ successful: Bool)->())?
	@objc public var wornCheckComplete: ((_ id: String, _ successful: Bool, _ code: String, _ value: Int)->())?
	@objc public var rawLoggingComplete: ((_ id: String, _ successful: Bool)->())?
	@objc public var resetComplete: ((_ id: String, _ successful: Bool)->())?
	@objc public var ppgMetrics: ((_ id: String, _ successful: Bool, _ packet: String)->())?
	@objc public var ppgFailed: ((_ id: String, _ code: Int)->())?
	@objc public var disableWornDetectComplete: ((_ id: String, _ successful: Bool)->())?
	@objc public var enableWornDetectComplete: ((_ id: String, _ successful: Bool)->())?

	@objc public var dataPackets: ((_ id: String, _ packets: String)->())?
	@objc public var dataComplete: ((_ id: String, _ bad_fw_read_count: Int, _ bad_fw_parse_count: Int, _ overflow_count: Int, _ bad_sdk_parse_count: Int)->())?
	@objc public var dataFailure: ((_ id: String)->())?
	
	@objc public var deviceWornStatus: ((_ id: String, _ isWorn: Bool)->())?

	@objc public var updateFirmwareStarted: ((_ id: String)->())?
	@objc public var updateFirmwareFinished: ((_ id: String)->())?
	@objc public var updateFirmwareFailed: ((_ id: String, _ code: Int, _ message: String)->())?
	@objc public var updateFirmwareProgress: ((_ id: String, _ percentage: Float)->())?
	
	@objc public var manufacturingTestComplete: ((_ id: String, _ successful: Bool)->())?
	@objc public var manufacturingTestResult: ((_ id: String, _ valid: Bool, _ result: String)->())?

	#if UNIVERSAL || ETHOS
	@objc public var startLiveSyncComplete: ((_ id: String, _ successful: Bool)->())?
	@objc public var stopLiveSyncComplete: ((_ id: String, _ successful: Bool)->())?
	#endif
	
	#if UNIVERSAL || ALTER || KAIROS || ETHOS
	@objc public var setAskForButtonResponseComplete: ((_ id: String, _ successful: Bool, _ enable: Bool)->())?
	@objc public var getAskForButtonResponseComplete: ((_ id: String, _ successful: Bool, _ enable: Bool)->())?
	#endif
	
	#if UNIVERSAL || ALTER || KAIROS || ETHOS
	@objc public var endSleepStatus: ((_ id: String, _ hasSleep: Bool)->())?
	@objc public var buttonClicked: ((_ id: String, _ presses: Int)->())?
	#endif
	
	#if UNIVERSAL || ALTER || KAIROS
	@objc public var setHRZoneColorComplete: ((_ id: String, _ successful: Bool, _ type: hrZoneRangeType)->())?
	@objc public var getHRZoneColorComplete: ((_ id: String, _ successful: Bool, _ type: hrZoneRangeType, _ red: Bool, _ green: Bool, _ blue: Bool, _ on_ms: Int, _ off_ms: Int)->())?
	@objc public var setHRZoneRangeComplete: ((_ id: String, _ successful: Bool)->())?
	@objc public var getHRZoneRangeComplete: ((_ id: String, _ successful: Bool, _ enabled: Bool, _ high_value: Int, _ low_value: Int)->())?
	@objc public var getPPGAlgorithmComplete: ((_ id: String, _ successful: Bool, _ algorithm: ppgAlgorithmConfiguration)->())?
	#endif
	
	#if UNIVERSAL || ALTER || KAIROS || ETHOS
	@objc public var setAdvertiseAsHRMComplete: ((_ id: String, _ successful: Bool, _ asHRM: Bool)->())?
	@objc public var getAdvertiseAsHRMComplete: ((_ id: String, _ successful: Bool, _ asHRM: Bool)->())?
	#endif

	@objc public var recalibratePPGComplete: ((_ id: String, _ successful: Bool)->())?

	@objc public var getRawLoggingStatusComplete: ((_ id: String, _ successful: Bool, _ enabled: Bool)->())?
	@objc public var getWornOverrideStatusComplete: ((_ id: String, _ successful: Bool, _ overridden: Bool)->())?

	@objc public var deviceChargingStatus: ((_ id: String, _ charging: Bool, _ on_charger: Bool, _ error: Bool)->())?

	@objc public var setSessionParamComplete: ((_ id: String, _ successful: Bool, _ parameter: sessionParameterType)->())?
	@objc public var getSessionParamComplete: ((_ id: String, _ successful: Bool, _ parameter: sessionParameterType, _ value: Int)->())?
	@objc public var resetSessionParamsComplete: ((_ id: String, _ successful: Bool)->())?
	@objc public var acceptSessionParamsComplete: ((_ id: String, _ successful: Bool)->())?

	@objc public var batteryLevel: ((_ id: String, _ percentage: Int)->())?

	#if UNIVERSAL || ETHOS
	@objc public var pulseOx: ((_ id: String, _ spo2: Float, _ hr: Float)->())?
	#endif

	#if UNIVERSAL || ETHOS || ALTER || KAIROS
	@objc public var heartRate: ((_ id: String, _ epoch: Int, _ hr: Int, _ rr: [Double])->())?
	#endif

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
				devDictionary[device.epoch]	= device
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
		if let devices = mConnectedDevices {
			return (mGetDevicesSortedByTime(devices))
		}
		
		return ([])
	}
	
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	@objc public var discoveredDevices: [ Device ] {
		if let devices = mDiscoveredDevices {
			return (mGetDevicesSortedByTime(devices))
		}
		
		return ([])
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
	internal var mDiscoveredDevices	: [ String : Device ]?
	internal var mConnectedDevices	: [ String : Device ]?
	internal lazy var mPairedDeviceNames	= [ String: String ]()
	
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
		
		#if UNIVERSAL || LIVOTAL
		dfu.finished		= { id in DispatchQueue.main.async { self.updateFirmwareFinished?(id) } }
		dfu.failed			= { id, code, message in DispatchQueue.main.async { self.updateFirmwareFailed?(id, code, message) } }
		dfu.started			= { id in DispatchQueue.main.async { self.updateFirmwareStarted?(id) } }
		dfu.progress		= { id, percentage in DispatchQueue.main.async { self.updateFirmwareProgress?(id, percentage) } }
		#endif
		
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
	@objc public func startScan() -> Bool {
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
		
		mDiscoveredDevices?.removeAll()
		
		if (mCentralManager?.state == .poweredOn) {
			let services	= Device.scan_services
			var options		= [String : Any]()

			//services.append(Device.scan_services)
			options[CBCentralManagerScanOptionAllowDuplicatesKey]		= true

			mCentralManager?.scanForPeripherals(withServices: services, options: options)
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
		mDiscoveredDevices?.removeAll()
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
		
		if let device = mDiscoveredDevices?[id] {
			if let peripheral = device.peripheral {
				device.connecting = true
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
		
		if let device = mConnectedDevices?[id] {
			if let peripheral = device.peripheral {
				mCentralManager?.cancelPeripheralConnection(peripheral)
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
	@objc public func writeEpoch(_ id: String, newEpoch: Int) {
		log?.v("\(id): \(newEpoch)")
		
		if let device = mConnectedDevices?[id] { device.writeEpoch(id, newEpoch: newEpoch) }
		else { self.writeEpochComplete?(id, false) }
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	@objc public func readEpoch(_ id: String) {
		log?.v("\(id)")
		
		if let device = mConnectedDevices?[id] { device.readEpoch(id) }
		else { self.readEpochComplete?(id, false, 0) }
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	@objc public func endSleep(_ id: String) {
		log?.v("\(id)")
		
		if let device = mConnectedDevices?[id] { device.endSleep(id) }
		else { self.endSleepComplete?(id, false) }
	}
	
	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	#if UNIVERSAL || ETHOS
	@objc public func debug(_ id: String, device: debugDevice, data: Data) {
		log?.v("\(id): \(device.name) -> \(data.hexString)")
		
		if let connectedDevice = mConnectedDevices?[id] { connectedDevice.debug(id, device: device, data: data) }
		else { self.debugComplete?(id, false, device, data) }
	}
	#endif

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	@objc public func getAllPackets(_ id: String) {
		log?.v ("\(id)")
		
		if let device = mConnectedDevices?[id] { device.getAllPackets(id) }
		else { self.getAllPacketsComplete?(id, false) }
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	@objc public func getNextPacket(_ id: String, single: Bool) {
		log?.v ("\(id)")
		
		if let device = mConnectedDevices?[id] { device.getNextPacket(id, single: single) }
		else { self.getNextPacketComplete?(id, false, .missingDevice, true, "") }
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	@objc public func getPacketCount(_ id: String) {
		log?.v ("\(id)")
		
		if let device = mConnectedDevices?[id] { device.getPacketCount(id) }
		else { self.getPacketCountComplete?(id, false, 0) }
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	@objc public func disableWornDetect(_ id: String) {
		log?.v ("\(id)")
		
		if let device = mConnectedDevices?[id] { device.disableWornDetect(id) }
		else { self.disableWornDetectComplete?(id, false) }
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	@objc public func enableWornDetect(_ id: String) {
		log?.v ("\(id)")
		
		if let device = mConnectedDevices?[id] { device.enableWornDetect(id) }
		else { self.enableWornDetectComplete?(id, false) }
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	@objc public func startManual(_ id: String, algorithms: ppgAlgorithmConfiguration) {
		log?.v ("\(id): Algorithms: \(String(format: "0x%02X", algorithms.commandByte))")
		
		if let device = mConnectedDevices?[id] { device.startManual(id, algorithms: algorithms) }
		else { self.startManualComplete?(id, false) }
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	@objc public func stopManual(_ id: String) {
		log?.v ("\(id)")
		
		if let device = mConnectedDevices?[id] { device.stopManual(id) }
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
	@objc public func livotalLED(_ id: String, red: Bool, green: Bool, blue: Bool, blink: Bool, seconds: Int) {
		if let device = mConnectedDevices?[id] { device.livotalLED(id, red: red, green: green, blue: blue, blink: blink, seconds: seconds) }
		else { self.ledComplete?(id, false) }
	}
	
	@objc public func ethosLED(_ id: String, red: Int, green: Int, blue: Int, mode: ethosLEDMode, seconds: Int, percent: Int) {
		if let device = mConnectedDevices?[id] { device.ethosLED(id, red: red, green: green, blue: blue, mode: mode, seconds: seconds, percent: percent) }
		else { self.ledComplete?(id, false) }
	}

	@objc public func alterLED(_ id: String, red: Bool, green: Bool, blue: Bool, blink: Bool, seconds: Int) {
		if let device = mConnectedDevices?[id] { device.alterLED(id, red: red, green: green, blue: blue, blink: blink, seconds: seconds) }
		else { self.ledComplete?(id, false) }
	}
	
	@objc public func kairosLED(_ id: String, red: Bool, green: Bool, blue: Bool, blink: Bool, seconds: Int) {
		if let device = mConnectedDevices?[id] { device.kairosLED(id, red: red, green: green, blue: blue, blink: blink, seconds: seconds) }
		else { self.ledComplete?(id, false) }
	}
	#endif

	#if LIVOTAL
	@objc public func led(_ id: String, red: Bool, green: Bool, blue: Bool, blink: Bool, seconds: Int) {
		if let device = mConnectedDevices?[id] { device.livotalLED(id, red: red, green: green, blue: blue, blink: blink, seconds: seconds) }
		else { self.ledComplete?(id, false) }
	}
	#endif

	#if ETHOS
	@objc public func led(_ id: String, red: Int, green: Int, blue: Int, mode: ethosLEDMode, seconds: Int, percent: Int) {
		if let device = mConnectedDevices?[id] { device.ethosLED(id, red: red, green: green, blue: blue, mode: mode, seconds: seconds, percent: percent) }
		else { self.ledComplete?(id, false) }
	}
	#endif

	#if ALTER
	@objc public func led(_ id: String, red: Bool, green: Bool, blue: Bool, blink: Bool, seconds: Int) {
		if let device = mConnectedDevices?[id] { device.alterLED(id, red: red, green: green, blue: blue, blink: blink, seconds: seconds) }
		else { self.ledComplete?(id, false) }
	}
	#endif

	#if KAIROS
	@objc public func led(_ id: String, red: Bool, green: Bool, blue: Bool, blink: Bool, seconds: Int) {
		if let device = mConnectedDevices?[id] { device.kairosLED(id, red: red, green: green, blue: blue, blink: blink, seconds: seconds) }
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
	#if UNIVERSAL || ETHOS
	@objc public func motor(_ id: String, milliseconds: Int, pulses: Int) {
		if let device = mConnectedDevices?[id] { device.motor(id, milliseconds: milliseconds, pulses: pulses) }
		else { self.motorComplete?(id, false) }
	}
	#endif

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	@objc public func enterShipMode(_ id: String) {
		if let device = mConnectedDevices?[id] { device.enterShipMode(id) }
		else { self.enterShipModeComplete?(id, false) }
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	@objc public func writeSerialNumber(_ id: String, partID: String) {
		if let device = mConnectedDevices?[id] { device.writeSerialNumber(id, partID: partID) }
		else { self.writeSerialNumberComplete?(id, false) }
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	@objc public func readSerialNumber(_ id: String) {
		if let device = mConnectedDevices?[id] { device.readSerialNumber(id) }
		else { self.readSerialNumberComplete?(id, false, "") }
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	@objc public func deleteSerialNumber(_ id: String) {
		if let device = mConnectedDevices?[id] { device.deleteSerialNumber(id) }
		else { self.deleteSerialNumberComplete?(id, false) }
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	@objc public func writeAdvInterval(_ id: String, seconds: Int) {
		if let device = mConnectedDevices?[id] { device.writeAdvInterval(id, seconds: seconds) }
		else { self.writeAdvIntervalComplete?(id, false) }
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	@objc public func readAdvInterval(_ id: String) {
		if let device = mConnectedDevices?[id] { device.readAdvInterval(id) }
		else { self.readAdvIntervalComplete?(id, false, 0) }
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	@objc public func deleteAdvInterval(_ id: String) {
		if let device = mConnectedDevices?[id] { device.deleteAdvInterval(id) }
		else { self.deleteAdvIntervalComplete?(id, false) }
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	@objc public func clearChargeCycles(_ id: String) {
		if let device = mConnectedDevices?[id] { device.clearChargeCycles(id) }
		else { self.clearChargeCyclesComplete?(id, false) }
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	@objc public func readChargeCycles(_ id: String) {
		if let device = mConnectedDevices?[id] { device.readChargeCycles(id) }
		else { self.readChargeCyclesComplete?(id, false, 0) }
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	@objc public func readCanLogDiagnostics(_ id: String) {
		if let device = mConnectedDevices?[id] { device.readCanLogDiagnostics(id) }
		else { self.readCanLogDiagnosticsComplete?(id, false, false) }
	}
	
	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	@objc public func updateCanLogDiagnostics(_ id: String, allow: Bool) {
		if let device = mConnectedDevices?[id] { device.updateCanLogDiagnostics(id, allow: allow) }
		else { self.updateCanLogDiagnosticsComplete?(id, false) }
	}
		
	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	#if LIVOTAL
	@objc public func manufacturingTest(_ id: String) {
		if let device = mConnectedDevices?[id] { device.livotalManufacturingTest(id) }
		else { self.manufacturingTestComplete?(id, false) }
	}
	#endif
	
	#if ALTER
	@objc public func manufacturingTest(_ id: String, test: alterManufacturingTestType) {
		if let device = mConnectedDevices?[id] { device.alterManufacturingTest(id, test: test) }
		else { self.manufacturingTestComplete?(id, false) }
	}
	#endif

	#if KAIROS
	@objc public func manufacturingTest(_ id: String, test: kairosManufacturingTestType) {
		if let device = mConnectedDevices?[id] { device.kairosManufacturingTest(id, test: test) }
		else { self.manufacturingTestComplete?(id, false) }
	}
	#endif

	#if ETHOS
	@objc public func manufacturingTest(_ id: String, test: ethosManufacturingTestType) {
		if let device = mConnectedDevices?[id] { device.ethosManufacturingTest(id, test: test) }
		else { self.manufacturingTestComplete?(id, false) }
	}
	#endif

	#if UNIVERSAL
	@objc public func livotalManufacturingTest(_ id: String) {
		if let device = mConnectedDevices?[id] { device.livotalManufacturingTest(id) }
		else { self.manufacturingTestComplete?(id, false) }
	}

	@objc public func ethosManufacturingTest(_ id: String, test: ethosManufacturingTestType) {
		if let device = mConnectedDevices?[id] { device.ethosManufacturingTest(id, test: test) }
		else { self.manufacturingTestComplete?(id, false) }
	}
	
	@objc public func alterManufacturingTest(_ id: String, test: alterManufacturingTestType) {
		if let device = mConnectedDevices?[id] { device.alterManufacturingTest(id, test: test) }
		else { self.manufacturingTestComplete?(id, false) }
	}
	
	@objc public func kairosManufacturingTest(_ id: String, test: kairosManufacturingTestType) {
		if let device = mConnectedDevices?[id] { device.kairosManufacturingTest(id, test: test) }
		else { self.manufacturingTestComplete?(id, false) }
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
	@objc public func startLiveSync(_ id: String, configuration: liveSyncConfiguration) {
		if let device = mConnectedDevices?[id] { device.startLiveSync(id, configuration: configuration) }
		else { self.startLiveSyncComplete?(id, false) }
	}
	
	@objc public func stopLiveSync(_ id: String) {
		if let device = mConnectedDevices?[id] { device.stopLiveSync(id) }
		else { self.stopLiveSyncComplete?(id, false) }
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
	@objc public func setAskForButtonResponse(_ id: String, enable: Bool) {
		if let device = mConnectedDevices?[id] { device.setAskForButtonResponse(enable) }
		else { self.setAskForButtonResponseComplete?(id, false, enable) }
	}
	
	//--------------------------------------------------------------------------------
	// Function Name: getAskForButtonResponse
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	@objc public func getAskForButtonResponse(_ id: String) {
		if let device = mConnectedDevices?[id] { device.getAskForButtonResponse() }
		else { self.getAskForButtonResponseComplete?(id, false, false) }
	}
	#endif

	#if UNIVERSAL || ALTER || KAIROS
	//--------------------------------------------------------------------------------
	// Function Name: setHRZoneColor
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	@objc public func setHRZoneColor(_ id: String, type: hrZoneRangeType, red: Bool, green: Bool, blue: Bool, on_milliseconds: Int, off_milliseconds: Int) {
		if let device = mConnectedDevices?[id] {
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
	@objc public func getHRZoneColor(_ id: String, type: hrZoneRangeType) {
		if let device = mConnectedDevices?[id] { device.getHRZoneColor(type) }
		else { self.getHRZoneColorComplete?(id, false, type, false, false, false, 0, 0) }
	}
	
	//--------------------------------------------------------------------------------
	// Function Name: setHRZoneRange
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	@objc public func setHRZoneRange(_ id: String, enabled: Bool, high_value: Int, low_value: Int) {
		if let device = mConnectedDevices?[id] {
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
	@objc public func getHRZoneRange(_ id: String) {
		if let device = mConnectedDevices?[id] { device.getHRZoneRange() }
		else { self.getHRZoneRangeComplete?(id, false, false, 0, 0) }
	}
	
	//--------------------------------------------------------------------------------
	// Function Name: getPPGAlgorithm
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	@objc public func getPPGAlgorithm(_ id: String) {
		if let device = mConnectedDevices?[id] { device.getPPGAlgorithm() }
		else { self.getPPGAlgorithmComplete?(id, false, ppgAlgorithmConfiguration()) }
	}
	
	//--------------------------------------------------------------------------------
	// Function Name: setAdvertiseAsHRM
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	@objc public func setAdvertiseAsHRM(_ id: String, asHRM: Bool) {
		if let device = mConnectedDevices?[id] { device.setAdvertiseAsHRM(asHRM) }
		else { self.setAdvertiseAsHRMComplete?(id, false, false) }
	}
	
	//--------------------------------------------------------------------------------
	// Function Name: getAdvertiseAsHRM
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	@objc public func getAdvertiseAsHRM(_ id: String) {
		if let device = mConnectedDevices?[id] { device.getAdvertiseAsHRM() }
		else { self.getAdvertiseAsHRMComplete?(id, false, false) }
	}
	#endif

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	@objc public func recalibratePPG(_ id: String) {
		if let device = mConnectedDevices?[id] { device.recalibratePPG(id) }
		else { self.recalibratePPGComplete?(id, false) }
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	@objc public func allowPPG(_ id: String, allow: Bool) {
		if let device = mConnectedDevices?[id] { device.allowPPG(id, allow: allow) }
		else { self.allowPPGComplete?(id, false) }
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	@objc public func wornCheck(_ id: String) {
		if let device = mConnectedDevices?[id] { device.wornCheck(id) }
		else { self.wornCheckComplete?(id, false, "No device", 0) }
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	@objc public func rawLogging(_ id: String, enable: Bool) {
		if let device = mConnectedDevices?[id] { device.rawLogging(id, enable: enable) }
		else { self.rawLoggingComplete?(id, false) }
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	@objc public func getRawLoggingStatus(_ id: String) {
		if let device = mConnectedDevices?[id] { device.getRawLoggingStatus(id) }
		else { self.getRawLoggingStatusComplete?(id, false, false) }
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	@objc public func getWornOverrideStatus(_ id: String) {
		if let device = mConnectedDevices?[id] { device.getWornOverrideStatus(id) }
		else { self.getWornOverrideStatusComplete?(id, false, false) }
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	@objc public func reset(_ id: String) {
		if let device = mConnectedDevices?[id] { device.reset(id) }
		else { self.resetComplete?(id, false) }
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	@objc public func updateFirmware(_ id: String, file: URL) {
		if let device = mConnectedDevices?[id] { device.updateFirmware(file) }
		else { self.updateFirmwareFailed?(id, 10000, "No connected device to update") }

	}
	
	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	@objc public func cancelFirmwareUpdate(_ id: String) {
		if let device = mConnectedDevices?[id] { device.cancelFirmwareUpdate() }
		else { self.updateFirmwareFailed?(id, 10000, "No connected device to update") }
	}
	
	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	@objc public func setSessionParam(_ id: String, parameter: sessionParameterType, value: Int) {
		if let device = mConnectedDevices?[id] { device.setSessionParam(parameter, value: value) }
		else { self.setSessionParamComplete?(id, false, parameter) }

	}
	
	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	@objc public func getSessionParam(_ id: String, parameter: sessionParameterType) {
		if let device = mConnectedDevices?[id] { device.getSessionParam(parameter) }
		else { self.getSessionParamComplete?(id, false, parameter, 0) }
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	@objc public func resetSessionParams(_ id: String) {
		if let device = mConnectedDevices?[id] { device.resetSessionParams() }
		else { self.resetSessionParamsComplete?(id, false) }
	}

	
	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	@objc public func acceptSessionParams(_ id: String) {
		if let device = mConnectedDevices?[id] { device.acceptSessionParams() }
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

