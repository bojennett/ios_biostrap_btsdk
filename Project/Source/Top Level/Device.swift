//
//  Device.swift
//  biostrapDeviceSDK
//
//  Created by Joseph A. Bennett on 3/31/21.
//

import Foundation
import CoreBluetooth

public class Device: NSObject {
	
	
	enum services: String {
		#if UNIVERSAL || ALTER
		case alterService			= "883BBA2C-8E31-40BB-A859-D59A2FB38EC0"
		#endif
		
		#if UNIVERSAL || ETHOS
		case ethosService			= "B30E0F19-A021-45F3-8661-4255CBD49E10"
		#endif
		
		#if UNIVERSAL || KAIROS
		case kairosService			= "140BB753-9845-4C0E-B61A-E6BAE41712F0"
		#endif

		#if UNIVERSAL || ETHOS || ALTER || KAIROS
		case ambiqOTAService		= "00002760-08C2-11E1-9073-0E8AC72E1001"
		#endif
		
		#if UNIVERSAL || LIVOTAL
		case livotalService			= "58950000-A53F-11EB-BCBC-0242AC130002"
		case nordicDFUService		= "FE59"
		#endif

		var UUID: CBUUID {
			return CBUUID(string: self.rawValue)
		}
		
		var title: String {
			switch (self) {
			#if UNIVERSAL || ALTER
			case .alterService		: return "Alter Service"
			#endif

			#if UNIVERSAL || ETHOS
			case .ethosService		: return "Ethos Service"
			#endif

			#if UNIVERSAL || KAIROS
			case .kairosService		: return "Kairos Service"
			#endif
				
			#if UNIVERSAL || ETHOS || ALTER || KAIROS
			case .ambiqOTAService	: return "Ambiq OTA Service"
			#endif

			#if UNIVERSAL || LIVOTAL
			case .livotalService	: return "Livotal Service"
			case .nordicDFUService	: return "Nordic DFU Service"
			#endif
			}
		}
	}

	enum characteristics: String {
		#if UNIVERSAL || ALTER
		case alterMainCharacteristic	= "883BBA2C-8E31-40BB-A859-D59A2FB38EC1"
		case alterDataCharacteristic	= "883BBA2C-8E31-40BB-A859-D59A2FB38EC2"
		#endif

		#if UNIVERSAL || ETHOS
		case ethosMainCharacteristic	= "B30E0F19-A021-45F3-8661-4255CBD49E11"
		case ethosDataCharacteristic	= "B30E0F19-A021-45F3-8661-4255CBD49E12"
		#endif

		#if UNIVERSAL || KAIROS
		case kairosMainCharacteristic	= "140BB753-9845-4C0E-B61A-E6BAE41712F1"
		case kairosDataCharacteristic	= "140BB753-9845-4C0E-B61A-E6BAE41712F2"
		#endif

		#if UNIVERSAL || ETHOS || ALTER || KAIROS
		case ambiqOTARXCharacteristic	= "00002760-08C2-11E1-9073-0E8AC72E0001"
		case ambiqOTATXCharacteristic	= "00002760-08C2-11E1-9073-0E8AC72E0002"
		#endif

		#if UNIVERSAL || LIVOTAL
		case livotalMainCharacteristic	= "58950001-A53F-11EB-BCBC-0242AC130002"
		case livotalDataCharacteristic	= "58950002-A53F-11EB-BCBC-0242AC130002"
		case nordicDFUCharacteristic	= "8EC90003-F315-4F60-9FB8-838830DAEA50"
		#endif

		var UUID: CBUUID {
			return CBUUID(string: self.rawValue)
		}
		
		var title: String {
			switch (self) {
			#if UNIVERSAL || ALTER
			case .alterMainCharacteristic	: return "Alter Main Characteristic"
			case .alterDataCharacteristic	: return "Alter Data Characteristic"
			#endif

			#if UNIVERSAL || ETHOS
			case .ethosMainCharacteristic	: return "Ethos Main Characteristic"
			case .ethosDataCharacteristic	: return "Ethos Data Characteristic"
			#endif

			#if UNIVERSAL || KAIROS
			case .kairosMainCharacteristic	: return "Kairos Main Characteristic"
			case .kairosDataCharacteristic	: return "Kairos Data Characteristic"
			#endif
				
			#if UNIVERSAL || ETHOS || ALTER || KAIROS
			case .ambiqOTARXCharacteristic	: return "Ambiq OTA RX Characteristic"
			case .ambiqOTATXCharacteristic	: return "Ambiq OTA TX Characteristic"
			#endif

			#if UNIVERSAL || LIVOTAL
			case .livotalMainCharacteristic	: return "Livotal Main Characteristic"
			case .livotalDataCharacteristic	: return "Livotal Data Characteristic"
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
	@objc public var name	: String
	@objc public var id		: String
	var epoch				: TimeInterval
	
	// MARK: Callbacks
	var batteryLevelUpdated: ((_ id: String, _ percentage: Int)->())?

	#if UNIVERSAL || ETHOS
	var pulseOxUpdated: ((_ id: String, _ spo2: Float, _ hr: Float)->())?
	#endif

	#if UNIVERSAL || ETHOS || ALTER || KAIROS
	var heartRateUpdated: ((_ id: String, _ epoch: Int, _ hr: Int, _ rr: [Double])->())?
	#endif

	var writeEpochComplete: ((_ id: String, _ successful: Bool)->())?
	var getAllPacketsComplete: ((_ id: String, _ successful: Bool)->())?
	var getNextPacketComplete: ((_ id: String, _ successful: Bool, _ error_code: nextPacketStatusType, _ caughtUp: Bool, _ packet: String)->())?
	var getPacketCountComplete: ((_ id: String, _ successful: Bool, _ count: Int)->())?
	var startManualComplete: ((_ id: String, _ successful: Bool)->())?
	var stopManualComplete: ((_ id: String, _ successful: Bool)->())?
	var ledComplete: ((_ id: String, _ successful: Bool)->())?
	#if UNIVERSAL || ETHOS
	var motorComplete: ((_ id: String, _ successful: Bool)->())?
	#endif
	var enterShipModeComplete: ((_ id: String, _ successful: Bool)->())?

	var writeSerialNumberComplete: ((_ id: String, _ successful: Bool)->())?
	var readSerialNumberComplete: ((_ id: String, _ successful: Bool, _ partID: String)->())?
	var deleteSerialNumberComplete: ((_ id: String, _ successful: Bool)->())?
	var writeAdvIntervalComplete: ((_ id: String, _ successful: Bool)->())?
	var readAdvIntervalComplete: ((_ id: String, _ successful: Bool, _ seconds: Int)->())?
	var deleteAdvIntervalComplete: ((_ id: String, _ successful: Bool)->())?
	var clearChargeCyclesComplete: ((_ id: String, _ successful: Bool)->())?
	var readChargeCyclesComplete: ((_ id: String, _ successful: Bool, _ cycles: Float)->())?
	var readCanLogDiagnosticsComplete: ((_ id: String, _ successful: Bool, _ allow: Bool)->())?
	var updateCanLogDiagnosticsComplete: ((_ id: String, _ successful: Bool)->())?

	var allowPPGComplete: ((_ id: String, _ successful: Bool)->())?
	var wornCheckComplete: ((_ id: String, _ successful: Bool, _ code: String, _ value: Int)->())?
	var rawLoggingComplete: ((_ id: String, _ successful: Bool)->())?
	var resetComplete: ((_ id: String, _ successful: Bool)->())?
	var endSleepComplete: ((_ id: String, _ successful: Bool)->())?
	var readEpochComplete: ((_ id: String, _ successful: Bool, _ value: Int)->())?
	var ppgMetrics: ((_ id: String, _ successful: Bool, _ packet: String)->())?
	var ppgFailed: ((_ id: String, _ code: Int)->())?
	var disableWornDetectComplete: ((_ id: String, _ successful: Bool)->())?
	var enableWornDetectComplete: ((_ id: String, _ successful: Bool)->())?
	#if UNIVERSAL || ETHOS
	var debugComplete: ((_ id: String, _ successful: Bool, _ device: debugDevice, _ data: Data)->())?
	#endif

	#if UNIVERSAL || ALTER || KAIROS
	var setHRZoneColorComplete: ((_ id: String, _ successful: Bool, _ type: hrZoneRangeType)->())?
	var getHRZoneColorComplete: ((_ id: String, _ successful: Bool, _ type: hrZoneRangeType, _ red: Bool, _ green: Bool, _ blue: Bool, _ on_ms: Int, _ off_ms: Int)->())?
	var setHRZoneRangeComplete: ((_ id: String, _ successful: Bool)->())?
	var getHRZoneRangeComplete: ((_ id: String, _ successful: Bool, _ enabled: Bool, _ high_value: Int, _ low_value: Int)->())?
	var getManualModeComplete: ((_ id: String, _ successful: Bool, _ algorithm: ppgAlgorithmConfiguration)->())?
	#endif

	var dataPackets: ((_ id: String, _ packets: String)->())?
	var dataComplete: ((_ id: String, _ bad_fw_read_count: Int, _ bad_fw_parse_count: Int, _ overflow_count: Int, _ bad_sdk_parse_count: Int)->())?
	var dataFailure: ((_ id: String)->())?
	
	var deviceWornStatus: ((_ id: String, _ isWorn: Bool)->())?

	var updateFirmwareStarted: ((_ id: String)->())?
	var updateFirmwareFinished: ((_ id: String)->())?
	var updateFirmwareProgress: ((_ id: String, _ percentage: Float)->())?
	var updateFirmwareFailed: ((_ id: String, _ code: Int, _ message: String)->())?

	var manufacturingTestComplete: ((_ id: String, _ successful: Bool)->())?
	var manufacturingTestResult: ((_ id: String, _ valid: Bool, _ result: String)->())?

	var recalibratePPGComplete: ((_ id: String, _ successful: Bool)->())?

	#if UNIVERSAL || ETHOS
	var startLiveSyncComplete: ((_ id: String, _ successful: Bool)->())?
	var stopLiveSyncComplete: ((_ id: String, _ successful: Bool)->())?
	#endif

	var getRawLoggingStatusComplete: ((_ id: String, _ successful: Bool, _ enabled: Bool)->())?
	var getWornOverrideStatusComplete: ((_ id: String, _ successful: Bool, _ overridden: Bool)->())?

	var deviceChargingStatus: ((_ id: String, _ charging: Bool, _ on_charger: Bool, _ error: Bool)->())?

	var setSessionParamComplete: ((_ id: String, _ successful: Bool, _ parameter: sessionParameterType)->())?
	var getSessionParamComplete: ((_ id: String, _ successful: Bool, _ parameter: sessionParameterType, _ value: Int)->())?
	var resetSessionParamsComplete: ((_ id: String, _ successful: Bool)->())?
	var acceptSessionParamsComplete: ((_ id: String, _ successful: Bool)->())?

	@objc public var batteryValid	: Bool = false
	@objc public var batteryLevel	: Int = 0
	@objc public var wornStatus		: String = "Not worn"
	@objc public var chargingStatus	: String = "Not charging"

	@objc public var modelNumber : String {
		if let modelNumber = mModelNumber { return modelNumber.value }
		else { return ("???") }
	}

	@objc public var firmwareRevision : String {
		if let firmwareRevision = mFirmwareVersion { return firmwareRevision.value }
		else { return ("???") }
	}

	@objc public var softwareRevision : [String] {
		if let softwareRevision = mSoftwareRevision { return softwareRevision.value }
		else { return ([String]()) }
	}

	@objc public var hardwareRevision : String {
		if let hardwareRevision = mHardwareRevision { return hardwareRevision.value }
		else { return ("???") }
	}

	@objc public var manufacturerName : String {
		if let manufacturerName = mManufacturerName { return manufacturerName.value }
		else { return ("???") }
	}

	@objc public var serialNumber : String {
		if let serialNumber = mSerialNumber { return serialNumber.value }
		else { return ("???") }
	}

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
	
	class var scan_services: [CBUUID] {
		#if UNIVERSAL
		return [services.livotalService.UUID, services.nordicDFUService.UUID, services.ethosService.UUID, services.alterService.UUID, services.kairosService.UUID]
		#endif
		
		#if LIVOTAL
		return [services.livotalService.UUID, services.nordicDFUService.UUID]
		#endif
		
		#if ETHOS
		return [services.ethosService.UUID]
		#endif

		#if ALTER
		return [services.alterService.UUID]
		#endif
		
		#if KAIROS
		return [services.kairosService.UUID]
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

	override init() {
		self.mState							= .disconnected
		
		self.name							= "UNKNOWN"
		self.id								= "UNKNOWN"
		self.epoch							= TimeInterval(0)
		self.mDISCharacteristicCount		= 0
		self.mDISCharacteristicsDiscovered	= false
		
		#if UNIVERSAL
		self.type							= .unknown
		#endif
	}

	#if UNIVERSAL
	convenience init(_ name: String, id: String, peripheral: CBPeripheral?, type: biostrapDeviceSDK.biostrapDeviceType) {
		self.init()
		
		self.name		= name
		self.id			= id
		self.peripheral	= peripheral
		self.type		= type
	}
	#endif

	convenience init(_ name: String, id: String, peripheral: CBPeripheral?) {
		self.init()
		
		self.name		= name
		self.id			= id
		self.peripheral	= peripheral
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
						
			if let dataCharacteristic = mDataCharacteristic {
				//log?.v ("MN: \(modelNumber.configured), HV: \(hardwareRevision.configured), FV: \(firmwareVersion.configured), Name: \(manufacturerName.configured), SN: \(serialNumber.configured), LIV MAIN: \(mainCharacteristic.configured), LIV DATA: \(dataCharacteristic.configured), BAT: \(batteryCharacteristic.configured), DFU: \(dfuCharacteristic.configured)")
				
				return (mDISCharacteristicsDiscovered && mDISCharacteristicCount == 0 &&
						batteryCharacteristic.configured &&
						mainCharacteristic.configured &&
						dataCharacteristic.configured &&
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
					
					if let dataCharacteristic = mDataCharacteristic {
						//log?.v ("ETH MAIN: \(mainCharacteristic.configured), ETH DATA: \(dataCharacteristic.configured), BAT: \(batteryCharacteristic.configured), HRM: \(heartRateMeasurementCharacteristic.configured), PULSOX: \(pulseOxContinuousCharacteristic.configured), OTARX: \(ambiqOTARXCharacteristic.configured), OTATX: \(ambiqOTATXCharacteristic.configured)")
						
						return (mDISCharacteristicsDiscovered && mDISCharacteristicCount == 0 &&
								batteryCharacteristic.configured &&
								mainCharacteristic.configured &&
								dataCharacteristic.configured &&
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
			
			if let dataCharacteristic = mDataCharacteristic {
				//log?.v ("ALTER MAIN: \(mainCharacteristic.configured), ALTER DATA: \(dataCharacteristic.configured), BAT: \(batteryCharacteristic.configured), OTARX: \(ambiqOTARXCharacteristic.configured), OTATX: \(ambiqOTATXCharacteristic.configured)")
				
				return (mDISCharacteristicsDiscovered && mDISCharacteristicCount == 0 &&
						batteryCharacteristic.configured &&
						mainCharacteristic.configured &&
						dataCharacteristic.configured &&
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
			
			if let dataCharacteristic = mDataCharacteristic {
				//log?.v ("ALTER MAIN: \(mainCharacteristic.configured), ALTER DATA: \(dataCharacteristic.configured), BAT: \(batteryCharacteristic.configured), OTARX: \(ambiqOTARXCharacteristic.configured), OTATX: \(ambiqOTATXCharacteristic.configured)")
				
				return (mDISCharacteristicsDiscovered && mDISCharacteristicCount == 0 &&
						batteryCharacteristic.configured &&
						mainCharacteristic.configured &&
						dataCharacteristic.configured &&
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
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	internal func mGetStringFromCharacteristic (_ characteristic: CBCharacteristic) -> String {
		if let value = characteristic.value {
			let valueString = String(decoding: value, as: UTF8.self)
			return valueString
		}
		else {
			log?.e ("Cannot get value from string for \(characteristic.prettyID)")
			return ("")
		}
	}
	
	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func writeEpoch(_ id: String, newEpoch: Int) {
		if let mainCharacteristic = mMainCharacteristic {
			mainCharacteristic.writeEpoch(newEpoch)
		}
		else { self.writeEpochComplete?(id, false) }
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func readEpoch(_ id: String) {
		if let mainCharacteristic = mMainCharacteristic {
			mainCharacteristic.readEpoch()
		}
		else { self.readEpochComplete?(id, false, 0) }
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
	func debug(_ id: String, device: debugDevice, data: Data) {
		if let mainCharacteristic = mMainCharacteristic {
			mainCharacteristic.debug(device, data: data)
		}
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
	func getAllPackets(_ id: String) {
		if let mainCharacteristic = mMainCharacteristic {
			mainCharacteristic.getAllPackets()
		}
		else { self.getAllPacketsComplete?(id, false) }
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
		else { self.getNextPacketComplete?(id, false, .missingDevice, true, "") }
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
		else { self.getPacketCountComplete?(id, false, 0) }
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
		else { self.disableWornDetectComplete?(id, false) }
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
		else { self.enableWornDetectComplete?(id, false) }
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func startManual(_ id: String, algorithms: ppgAlgorithmConfiguration) {
		if let mainCharacteristic = mMainCharacteristic {
			mainCharacteristic.startManual(algorithms)
		}
		else { self.startManualComplete?(id, false) }
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func stopManual(_ id: String) {
		if let mainCharacteristic = mMainCharacteristic {
			mainCharacteristic.stopManual()
		}
		else { self.stopManualComplete?(id, false) }
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	#if UNIVERSAL || LIVOTAL
	func livotalLED(_ id: String, red: Bool, green: Bool, blue: Bool, blink: Bool, seconds: Int) {
		if let mainCharacteristic = mMainCharacteristic {
			mainCharacteristic.livotalLED(red: red, green: green, blue: blue, blink: blink, seconds: seconds)
		}
		else { self.ledComplete?(id, false) }
	}
	#endif

	#if UNIVERSAL || ETHOS
	func ethosLED(_ id: String, red: Int, green: Int, blue: Int, mode: biostrapDeviceSDK.ethosLEDMode, seconds: Int, percent: Int) {
		if let mainCharacteristic = mMainCharacteristic {
			mainCharacteristic.ethosLED(red: red, green: green, blue: blue, mode: mode, seconds: seconds, percent: percent)
		}
		else { self.ledComplete?(id, false) }
	}
	#endif

	#if UNIVERSAL || ALTER
	func alterLED(_ id: String, red: Bool, green: Bool, blue: Bool, blink: Bool, seconds: Int) {
		if let mainCharacteristic = mMainCharacteristic {
			mainCharacteristic.alterLED(red: red, green: green, blue: blue, blink: blink, seconds: seconds)
		}
		else { self.ledComplete?(id, false) }
	}
	#endif

	#if UNIVERSAL || KAIROS
	func kairosLED(_ id: String, red: Bool, green: Bool, blue: Bool, blink: Bool, seconds: Int) {
		if let mainCharacteristic = mMainCharacteristic {
			mainCharacteristic.kairosLED(red: red, green: green, blue: blue, blink: blink, seconds: seconds)
		}
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
	func motor(_ id: String, milliseconds: Int, pulses: Int) {
		if let mainCharacteristic = mMainCharacteristic {
			mainCharacteristic.motor(milliseconds: milliseconds, pulses: pulses)
		}
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
	func enterShipMode(_ id: String) {
		if let mainCharacteristic = mMainCharacteristic {
			mainCharacteristic.enterShipMode()
		}
		else { self.enterShipModeComplete?(id, false) }
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func writeSerialNumber(_ id: String, partID: String) {
		if let mainCharacteristic = mMainCharacteristic {
			mainCharacteristic.writeSerialNumber(partID)
		}
		else { self.writeSerialNumberComplete?(id, false) }
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func readSerialNumber(_ id: String) {
		if let mainCharacteristic = mMainCharacteristic {
			mainCharacteristic.readSerialNumber()
		}
		else { self.readSerialNumberComplete?(id, false, "") }
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func deleteSerialNumber(_ id: String) {
		if let mainCharacteristic = mMainCharacteristic {
			mainCharacteristic.deleteSerialNumber()
		}
		else { self.deleteSerialNumberComplete?(id, false) }
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func writeAdvInterval(_ id: String, seconds: Int) {
		if let mainCharacteristic = mMainCharacteristic {
			mainCharacteristic.writeAdvInterval(seconds)
		}
		else { self.writeAdvIntervalComplete?(id, false) }
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func readAdvInterval(_ id: String) {
		if let mainCharacteristic = mMainCharacteristic {
			mainCharacteristic.readAdvInterval()
		}
		else { self.readAdvIntervalComplete?(id, false, 0) }
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func deleteAdvInterval(_ id: String) {
		if let mainCharacteristic = mMainCharacteristic {
			mainCharacteristic.deleteAdvInterval()
		}
		else { self.deleteAdvIntervalComplete?(id, false) }
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func clearChargeCycles(_ id: String) {
		if let mainCharacteristic = mMainCharacteristic {
			mainCharacteristic.clearChargeCycles()
		}
		else { self.clearChargeCyclesComplete?(id, false) }
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func readChargeCycles(_ id: String) {
		if let mainCharacteristic = mMainCharacteristic {
			mainCharacteristic.readChargeCycles()
		}
		else { self.readChargeCyclesComplete?(id, false, 0.0) }
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
		else { self.readCanLogDiagnosticsComplete?(id, false, false) }
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
		else { self.updateCanLogDiagnosticsComplete?(id, false) }
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
		else { self.allowPPGComplete?(id, false) }
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
		else { self.manufacturingTestComplete?(id, false) }
	}
	#endif

	#if UNIVERSAL || ETHOS
	func ethosManufacturingTest(_ id: String, test: ethosManufacturingTestType) {
		if let mainCharacteristic = mMainCharacteristic {
			mainCharacteristic.ethosManufacturingTest(test)
		}
		else { self.manufacturingTestComplete?(id, false) }
	}
	#endif

	#if UNIVERSAL || ALTER
	func alterManufacturingTest(_ id: String, test: alterManufacturingTestType) {
		if let mainCharacteristic = mMainCharacteristic {
			mainCharacteristic.alterManufacturingTest(test)
		}
		else { self.manufacturingTestComplete?(id, false) }
	}
	#endif

	#if UNIVERSAL || KAIROS
	func kairosManufacturingTest(_ id: String, test: kairosManufacturingTestType) {
		if let mainCharacteristic = mMainCharacteristic {
			mainCharacteristic.kairosManufacturingTest(test)
		}
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
	func startLiveSync(_ id: String, configuration: liveSyncConfiguration) {
		if let mainCharacteristic = mMainCharacteristic {
			mainCharacteristic.startLiveSync(configuration)
		}
		else { self.startLiveSyncComplete?(id, false) }
	}
	
	func stopLiveSync(_ id: String) {
		if let mainCharacteristic = mMainCharacteristic {
			mainCharacteristic.stopLiveSync()
		}
		else { self.stopLiveSyncComplete?(id, false) }
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
	func setHRZoneColor(_ type: hrZoneRangeType, red: Bool, green: Bool, blue: Bool, on_milliseconds: Int, off_milliseconds: Int) {
		if let mainCharacteristic = mMainCharacteristic {
			mainCharacteristic.setHRZoneColor(type, red: red, green: green, blue: blue, on_milliseconds: on_milliseconds, off_milliseconds: off_milliseconds)
		}
		else { self.setHRZoneColorComplete?(self.id, false, type) }
	}
	
	//--------------------------------------------------------------------------------
	// Function Name: getHRZoneColor
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func getHRZoneColor(_ type: hrZoneRangeType) {
		if let mainCharacteristic = mMainCharacteristic {
			mainCharacteristic.getHRZoneColor(type)
		}
		else { self.getHRZoneColorComplete?(self.id, false, type, false, false, false, 0, 0) }
	}
	
	//--------------------------------------------------------------------------------
	// Function Name: setHRZoneRange
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func setHRZoneRange(_ enabled: Bool, high_value: Int, low_value: Int) {
		if let mainCharacteristic = mMainCharacteristic {
			mainCharacteristic.setHRZoneRange(enabled, high_value: high_value, low_value: low_value)
		}
		else { self.setHRZoneRangeComplete?(self.id, false) }
	}
	
	//--------------------------------------------------------------------------------
	// Function Name: getHRZoneRange
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func getHRZoneRange() {
		if let mainCharacteristic = mMainCharacteristic {
			mainCharacteristic.getHRZoneRange()
		}
		else { self.getHRZoneRangeComplete?(self.id, false, false, 0, 0) }
	}
	
	//--------------------------------------------------------------------------------
	// Function Name: getManualMode
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func getManualMode() {
		log?.v("")
		
		if let mainCharacteristic = mMainCharacteristic { mainCharacteristic.getManualMode() }
		else { self.getManualModeComplete?(self.id, false, ppgAlgorithmConfiguration()) }
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
		else { self.recalibratePPGComplete?(id, false) }
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
		else { self.wornCheckComplete?(id, false, "Missing Characteristic", 0) }
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
		else { self.rawLoggingComplete?(id, false) }
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func getRawLoggingStatus(_ id: String) {
		if let mainCharacteristic = mMainCharacteristic {
			mainCharacteristic.getRawLoggingStatus()
		}
		else { self.getRawLoggingStatusComplete?(id, false, false) }
	}
	
	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func getWornOverrideStatus(_ id: String) {
		if let mainCharacteristic = mMainCharacteristic {
			mainCharacteristic.getWornOverrideStatus()
		}
		else { self.getWornOverrideStatusComplete?(id, false, false) }
	}
	
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
		else { self.resetComplete?(id, false) }
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
			else { updateFirmwareFailed?(self.id, 10001, "No DFU characteristic to update") }
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
					self.updateFirmwareFailed?(self.id, 10001, "Cannot parse file for update")
				}
			}
			else { updateFirmwareFailed?(self.id, 10001, "No OTA RX characteristic to update") }
		default: updateFirmwareFailed?(self.id, 10001, "Do not understand type to update: \(type.title)")
		}
		#endif
		
		#if LIVOTAL
		if let nordicDFUCharacteristic = mNordicDFUCharacteristic { nordicDFUCharacteristic.start(file) }
		else { updateFirmwareFailed?(self.id, 10001, "No DFU characteristic to update") }
		#endif
		
		#if ETHOS || ALTER || KAIROS
		if let ambiqOTARXCharacteristic = mAmbiqOTARXCharacteristic {
			do {
				let contents = try Data(contentsOf: file)
				ambiqOTARXCharacteristic.start(contents)
			}
			catch {
				log?.e ("Cannot open file")
				self.updateFirmwareFailed?(self.id, 10001, "Cannot parse file for update")
			}
		}
		else { updateFirmwareFailed?(self.id, 10001, "No OTA RX characteristic to update") }
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
		else { updateFirmwareFailed?(self.id, 10001, "No characteristic to cancel") }
		#endif

		#if ETHOS || ALTER || KAIROS
		if let ambiqOTARXCharacteristic = mAmbiqOTARXCharacteristic { ambiqOTARXCharacteristic.cancel() }
		else { updateFirmwareFailed?(self.id, 10001, "No characteristic to cancel") }
		#endif
		
		#if UNIVERSAL
		switch (type) {
		case .livotal:
			if let nordicDFUCharacteristic = mNordicDFUCharacteristic { nordicDFUCharacteristic.cancel() }
			else { updateFirmwareFailed?(self.id, 10001, "No characteristic to cancel") }
		case .alter, .ethos:
			if let ambiqOTARXCharacteristic = mAmbiqOTARXCharacteristic { ambiqOTARXCharacteristic.cancel() }
			else { updateFirmwareFailed?(self.id, 10001, "No characteristic to cancel") }
		default:
			log?.e ("Do now know device type")
			updateFirmwareFailed?(self.id, 10001, "Do not know device type: \(type.title)")
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
		else { self.setSessionParamComplete?(self.id, false, parameter) }

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
		else { self.getSessionParamComplete?(self.id, false, parameter, 0) }
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
		else { self.resetSessionParamsComplete?(self.id, false) }
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
		else { self.acceptSessionParamsComplete?(self.id, false) }
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
					mSoftwareRevision = disSoftwareRevisionCharacteristic(peripheral, characteristic: characteristic)
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
						self.batteryValid = true
						self.batteryLevel = percentage
						self.batteryLevelUpdated?(id, percentage)
					}
					mBatteryLevelCharacteristic?.read()
					mBatteryLevelCharacteristic?.discoverDescriptors()
				#if UNIVERSAL || ETHOS
				case .plx_continuous_measurement:
					log?.v ("\(self.id) '\(testCharacteristic.title)' - and enable notifications")
					mPulseOxContinuousCharacteristic = pulseOxContinuousCharacteristic(peripheral, characteristic: characteristic)
					mPulseOxContinuousCharacteristic?.updated	= { id, spo2, hr in self.pulseOxUpdated?(id, spo2, hr) }
					mPulseOxContinuousCharacteristic?.discoverDescriptors()
				#endif
				#if UNIVERSAL || ETHOS || ALTER || KAIROS
				case .heart_rate_measurement:
					log?.v ("\(self.id) '\(testCharacteristic.title)' - and enable notifications")
					mHeartRateMeasurementCharacteristic	= heartRateMeasurementCharacteristic(peripheral, characteristic: characteristic)
					mHeartRateMeasurementCharacteristic?.updated	= { id, epoch, hr, rr in self.heartRateUpdated?(id, epoch, hr, rr) }
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
					mMainCharacteristic?.startManualComplete = { successful in self.startManualComplete?(self.id, successful) }
					mMainCharacteristic?.stopManualComplete = { successful in self.stopManualComplete?(self.id, successful) }
					mMainCharacteristic?.ledComplete = { successful in self.ledComplete?(self.id, successful) }
					mMainCharacteristic?.motorComplete = { successful in self.motorComplete?(self.id, successful) }
					mMainCharacteristic?.enterShipModeComplete = { successful in self.enterShipModeComplete?(self.id, successful) }
					mMainCharacteristic?.writeSerialNumberComplete = { successful in self.writeSerialNumberComplete?(self.id, successful) }
					mMainCharacteristic?.readSerialNumberComplete = { successful, partID in self.readSerialNumberComplete?(self.id, successful, partID) }
					mMainCharacteristic?.deleteSerialNumberComplete = { successful in self.deleteSerialNumberComplete?(self.id, successful) }
					mMainCharacteristic?.writeAdvIntervalComplete = { successful in self.writeAdvIntervalComplete?(self.id, successful) }
					mMainCharacteristic?.readAdvIntervalComplete = { successful, seconds in self.readAdvIntervalComplete?(self.id, successful, seconds) }
					mMainCharacteristic?.deleteAdvIntervalComplete = { successful in self.deleteAdvIntervalComplete?(self.id, successful) }
					mMainCharacteristic?.clearChargeCyclesComplete = { successful in self.clearChargeCyclesComplete?(self.id, successful) }
					mMainCharacteristic?.readChargeCyclesComplete = { successful, cycles in self.readChargeCyclesComplete?(self.id, successful, cycles) }
					mMainCharacteristic?.readCanLogDiagnosticsComplete = { successful, allow in self.readCanLogDiagnosticsComplete?(self.id, successful, allow) }
					mMainCharacteristic?.updateCanLogDiagnosticsComplete = { successful in self.updateCanLogDiagnosticsComplete?(self.id, successful) }
					mMainCharacteristic?.rawLoggingComplete = { successful in self.rawLoggingComplete?(self.id, successful) }
					mMainCharacteristic?.getRawLoggingStatusComplete = { successful, enabled in self.getRawLoggingStatusComplete?(self.id, successful, enabled) }
					mMainCharacteristic?.getWornOverrideStatusComplete = { successful, overridden in self.getWornOverrideStatusComplete?(self.id, successful, overridden) }
					mMainCharacteristic?.allowPPGComplete = { successful in self.allowPPGComplete?(self.id, successful)}
					mMainCharacteristic?.wornCheckComplete = { successful, code, value in self.wornCheckComplete?(self.id, successful, code, value )}
					mMainCharacteristic?.resetComplete = { successful in self.resetComplete?(self.id, successful) }
					mMainCharacteristic?.ppgMetrics = { successful, packet in self.ppgMetrics?(self.id, successful, packet) }
					mMainCharacteristic?.ppgFailed = { code in self.ppgFailed?(self.id, code) }
					mMainCharacteristic?.writeEpochComplete = { successful in self.writeEpochComplete?(self.id, successful) }
					mMainCharacteristic?.readEpochComplete = { successful, value in self.readEpochComplete?(self.id, successful,  value) }
					mMainCharacteristic?.endSleepComplete = { successful in self.endSleepComplete?(self.id, successful) }
					mMainCharacteristic?.debugComplete = { successful, device, data in self.debugComplete?(self.id, successful, device, data) }
					mMainCharacteristic?.getAllPacketsComplete = { successful in self.getAllPacketsComplete?(self.id, successful) }
					mMainCharacteristic?.getNextPacketComplete = { successful, error_code, caughtUp, packet in self.getNextPacketComplete?(self.id, successful, error_code, caughtUp, packet) }
					mMainCharacteristic?.getPacketCountComplete = { successful, count in self.getPacketCountComplete?(self.id, successful, count) }
					mMainCharacteristic?.disableWornDetectComplete = { successful in self.disableWornDetectComplete?(self.id, successful) }
					mMainCharacteristic?.enableWornDetectComplete = { successful in self.enableWornDetectComplete?(self.id, successful) }
					mMainCharacteristic?.dataPackets = { packets in self.dataPackets?(self.id, packets) }
					mMainCharacteristic?.dataComplete = { bad_fw_read_count, bad_fw_parse_count, overflow_count, bad_sdk_parse_count in self.dataComplete?(self.id, bad_fw_read_count, bad_fw_parse_count, overflow_count, bad_sdk_parse_count) }
					mMainCharacteristic?.dataFailure = { self.dataFailure?(self.id) }
					mMainCharacteristic?.deviceWornStatus = { isWorn in
						if (isWorn) { self.wornStatus = "Worn" }
						else { self.wornStatus = "Not Worn" }
						self.deviceWornStatus?(self.id, isWorn)
					}
					mMainCharacteristic?.setSessionParamComplete = { successful, parameter in self.setSessionParamComplete?(self.id, successful, parameter) }
					mMainCharacteristic?.getSessionParamComplete = { successful, parameter, value in self.getSessionParamComplete?(self.id, successful, parameter, value) }
					mMainCharacteristic?.acceptSessionParamsComplete	= { successful in self.acceptSessionParamsComplete?(self.id, successful) }
					mMainCharacteristic?.resetSessionParamsComplete	= { successful in self.resetSessionParamsComplete?(self.id, successful) }
					mMainCharacteristic?.manufacturingTestComplete	= { successful in self.manufacturingTestComplete?(self.id, successful) }
					mMainCharacteristic?.manufacturingTestResult		= { valid, result in self.manufacturingTestResult?(self.id, valid, result) }
					mMainCharacteristic?.startLiveSyncComplete		= { successful in self.startLiveSyncComplete?(self.id, successful) }
					mMainCharacteristic?.stopLiveSyncComplete			= { successful in self.stopLiveSyncComplete?(self.id, successful) }
					mMainCharacteristic?.recalibratePPGComplete		= { successful in self.recalibratePPGComplete?(self.id, successful) }
					mMainCharacteristic?.deviceChargingStatus			= { charging, on_charger, error in
						if (charging) { self.chargingStatus	= "Charging" }
						else if (on_charger) { self.chargingStatus = "On Charger" }
						else if (error) { self.chargingStatus = "Charging Error" }
						else { self.chargingStatus = "Not Charging" }
						self.deviceChargingStatus?(self.id, charging, on_charger, error) }
					mMainCharacteristic?.discoverDescriptors()
					
				case .ethosDataCharacteristic:
					mDataCharacteristic = customDataCharacteristic(peripheral, characteristic: characteristic)
					mDataCharacteristic?.dataPackets = { packets in self.dataPackets?(self.id, packets) }
					mDataCharacteristic?.dataComplete = { bad_fw_read_count, bad_fw_parse_count, overflow_count, bad_sdk_parse_count in self.dataComplete?(self.id, bad_fw_read_count, bad_fw_parse_count, overflow_count, bad_sdk_parse_count) }
					mDataCharacteristic?.discoverDescriptors()
				#endif

				#if UNIVERSAL || ALTER
				case .alterMainCharacteristic:
					mMainCharacteristic	= customMainCharacteristic(peripheral, characteristic: characteristic)
					#if UNIVERSAL
					mMainCharacteristic?.type	= .alter
					#endif
					mMainCharacteristic?.startManualComplete = { successful in self.startManualComplete?(self.id, successful) }
					mMainCharacteristic?.stopManualComplete = { successful in self.stopManualComplete?(self.id, successful) }
					mMainCharacteristic?.ledComplete = { successful in self.ledComplete?(self.id, successful) }
					mMainCharacteristic?.enterShipModeComplete = { successful in self.enterShipModeComplete?(self.id, successful) }
					mMainCharacteristic?.writeSerialNumberComplete = { successful in self.writeSerialNumberComplete?(self.id, successful) }
					mMainCharacteristic?.readSerialNumberComplete = { successful, partID in self.readSerialNumberComplete?(self.id, successful, partID) }
					mMainCharacteristic?.deleteSerialNumberComplete = { successful in self.deleteSerialNumberComplete?(self.id, successful) }
					mMainCharacteristic?.writeAdvIntervalComplete = { successful in self.writeAdvIntervalComplete?(self.id, successful) }
					mMainCharacteristic?.readAdvIntervalComplete = { successful, seconds in self.readAdvIntervalComplete?(self.id, successful, seconds) }
					mMainCharacteristic?.deleteAdvIntervalComplete = { successful in self.deleteAdvIntervalComplete?(self.id, successful) }
					mMainCharacteristic?.clearChargeCyclesComplete = { successful in self.clearChargeCyclesComplete?(self.id, successful) }
					mMainCharacteristic?.readChargeCyclesComplete = { successful, cycles in self.readChargeCyclesComplete?(self.id, successful, cycles) }
					mMainCharacteristic?.readCanLogDiagnosticsComplete = { successful, allow in self.readCanLogDiagnosticsComplete?(self.id, successful, allow) }
					mMainCharacteristic?.updateCanLogDiagnosticsComplete = { successful in self.updateCanLogDiagnosticsComplete?(self.id, successful) }
					mMainCharacteristic?.rawLoggingComplete = { successful in self.rawLoggingComplete?(self.id, successful) }
					mMainCharacteristic?.getRawLoggingStatusComplete = { successful, enabled in self.getRawLoggingStatusComplete?(self.id, successful, enabled) }
					mMainCharacteristic?.getWornOverrideStatusComplete = { successful, overridden in self.getWornOverrideStatusComplete?(self.id, successful, overridden) }
					mMainCharacteristic?.allowPPGComplete = { successful in self.allowPPGComplete?(self.id, successful)}
					mMainCharacteristic?.wornCheckComplete = { successful, code, value in self.wornCheckComplete?(self.id, successful, code, value )}
					mMainCharacteristic?.resetComplete = { successful in self.resetComplete?(self.id, successful) }
					mMainCharacteristic?.ppgMetrics = { successful, packet in self.ppgMetrics?(self.id, successful, packet) }
					mMainCharacteristic?.ppgFailed = { code in self.ppgFailed?(self.id, code) }
					mMainCharacteristic?.writeEpochComplete = { successful in self.writeEpochComplete?(self.id, successful) }
					mMainCharacteristic?.readEpochComplete = { successful, value in self.readEpochComplete?(self.id, successful,  value) }
					mMainCharacteristic?.endSleepComplete = { successful in self.endSleepComplete?(self.id, successful) }
					mMainCharacteristic?.getAllPacketsComplete = { successful in self.getAllPacketsComplete?(self.id, successful) }
					mMainCharacteristic?.getNextPacketComplete = { successful, error_code, caughtUp, packet in self.getNextPacketComplete?(self.id, successful, error_code, caughtUp, packet) }
					mMainCharacteristic?.getPacketCountComplete = { successful, count in self.getPacketCountComplete?(self.id, successful, count) }
					mMainCharacteristic?.disableWornDetectComplete = { successful in self.disableWornDetectComplete?(self.id, successful) }
					mMainCharacteristic?.enableWornDetectComplete = { successful in self.enableWornDetectComplete?(self.id, successful) }
					mMainCharacteristic?.dataPackets = { packets in self.dataPackets?(self.id, packets) }
					mMainCharacteristic?.dataComplete = { bad_fw_read_count, bad_fw_parse_count, overflow_count, bad_sdk_parse_count in self.dataComplete?(self.id, bad_fw_read_count, bad_fw_parse_count, overflow_count, bad_sdk_parse_count) }
					mMainCharacteristic?.dataFailure = { self.dataFailure?(self.id) }
					mMainCharacteristic?.deviceWornStatus = { isWorn in
						if (isWorn) { self.wornStatus = "Worn" }
						else { self.wornStatus = "Not Worn" }
						self.deviceWornStatus?(self.id, isWorn)
					}
					mMainCharacteristic?.setSessionParamComplete = { successful, parameter in self.setSessionParamComplete?(self.id, successful, parameter) }
					mMainCharacteristic?.getSessionParamComplete = { successful, parameter, value in self.getSessionParamComplete?(self.id, successful, parameter, value) }
					mMainCharacteristic?.acceptSessionParamsComplete	= { successful in self.acceptSessionParamsComplete?(self.id, successful) }
					mMainCharacteristic?.resetSessionParamsComplete	= { successful in self.resetSessionParamsComplete?(self.id, successful) }
					mMainCharacteristic?.manufacturingTestComplete	= { successful in self.manufacturingTestComplete?(self.id, successful) }
					mMainCharacteristic?.manufacturingTestResult	= { valid, result in self.manufacturingTestResult?(self.id, valid, result) }
					mMainCharacteristic?.recalibratePPGComplete		= { successful in self.recalibratePPGComplete?(self.id, successful) }
					mMainCharacteristic?.deviceChargingStatus		= { charging, on_charger, error in
						if (charging) { self.chargingStatus	= "Charging" }
						else if (on_charger) { self.chargingStatus = "On Charger" }
						else if (error) { self.chargingStatus = "Charging Error" }
						else { self.chargingStatus = "Not Charging" }
						self.deviceChargingStatus?(self.id, charging, on_charger, error) }
					mMainCharacteristic?.setHRZoneColorComplete		= { successful, type in self.setHRZoneColorComplete?(self.id, successful, type) }
					mMainCharacteristic?.getHRZoneColorComplete		= { successful, type, red, green, blue, on_ms, off_ms in self.getHRZoneColorComplete?(self.id, successful, type, red, green, blue, on_ms, off_ms) }
					mMainCharacteristic?.setHRZoneRangeComplete		= { successful in self.setHRZoneRangeComplete?(self.id, successful) }
					mMainCharacteristic?.getHRZoneRangeComplete		= { successful, enabled, high_value, low_value in self.getHRZoneRangeComplete?(self.id, successful, enabled, high_value, low_value) }
					mMainCharacteristic?.getManualModeComplete		= { successful, algorithm in self.getManualModeComplete?(self.id, successful, algorithm) }

					mMainCharacteristic?.discoverDescriptors()
					
				case .alterDataCharacteristic:
					mDataCharacteristic = customDataCharacteristic(peripheral, characteristic: characteristic)
					mDataCharacteristic?.dataPackets = { packets in self.dataPackets?(self.id, packets) }
					mDataCharacteristic?.dataComplete = { bad_fw_read_count, bad_fw_parse_count, overflow_count, bad_sdk_parse_count in self.dataComplete?(self.id, bad_fw_read_count, bad_fw_parse_count, overflow_count, bad_sdk_parse_count) }
					mDataCharacteristic?.discoverDescriptors()
				#endif

				#if UNIVERSAL || KAIROS
				case .kairosMainCharacteristic:
					mMainCharacteristic	= customMainCharacteristic(peripheral, characteristic: characteristic)
					#if UNIVERSAL
					mMainCharacteristic?.type	= .kairos
					#endif
					mMainCharacteristic?.startManualComplete = { successful in self.startManualComplete?(self.id, successful) }
					mMainCharacteristic?.stopManualComplete = { successful in self.stopManualComplete?(self.id, successful) }
					mMainCharacteristic?.ledComplete = { successful in self.ledComplete?(self.id, successful) }
					mMainCharacteristic?.enterShipModeComplete = { successful in self.enterShipModeComplete?(self.id, successful) }
					mMainCharacteristic?.writeSerialNumberComplete = { successful in self.writeSerialNumberComplete?(self.id, successful) }
					mMainCharacteristic?.readSerialNumberComplete = { successful, partID in self.readSerialNumberComplete?(self.id, successful, partID) }
					mMainCharacteristic?.deleteSerialNumberComplete = { successful in self.deleteSerialNumberComplete?(self.id, successful) }
					mMainCharacteristic?.writeAdvIntervalComplete = { successful in self.writeAdvIntervalComplete?(self.id, successful) }
					mMainCharacteristic?.readAdvIntervalComplete = { successful, seconds in self.readAdvIntervalComplete?(self.id, successful, seconds) }
					mMainCharacteristic?.deleteAdvIntervalComplete = { successful in self.deleteAdvIntervalComplete?(self.id, successful) }
					mMainCharacteristic?.clearChargeCyclesComplete = { successful in self.clearChargeCyclesComplete?(self.id, successful) }
					mMainCharacteristic?.readChargeCyclesComplete = { successful, cycles in self.readChargeCyclesComplete?(self.id, successful, cycles) }
					mMainCharacteristic?.readCanLogDiagnosticsComplete = { successful, allow in self.readCanLogDiagnosticsComplete?(self.id, successful, allow) }
					mMainCharacteristic?.updateCanLogDiagnosticsComplete = { successful in self.updateCanLogDiagnosticsComplete?(self.id, successful) }
					mMainCharacteristic?.rawLoggingComplete = { successful in self.rawLoggingComplete?(self.id, successful) }
					mMainCharacteristic?.getRawLoggingStatusComplete = { successful, enabled in self.getRawLoggingStatusComplete?(self.id, successful, enabled) }
					mMainCharacteristic?.getWornOverrideStatusComplete = { successful, overridden in self.getWornOverrideStatusComplete?(self.id, successful, overridden) }
					mMainCharacteristic?.allowPPGComplete = { successful in self.allowPPGComplete?(self.id, successful)}
					mMainCharacteristic?.wornCheckComplete = { successful, code, value in self.wornCheckComplete?(self.id, successful, code, value )}
					mMainCharacteristic?.resetComplete = { successful in self.resetComplete?(self.id, successful) }
					mMainCharacteristic?.ppgMetrics = { successful, packet in self.ppgMetrics?(self.id, successful, packet) }
					mMainCharacteristic?.ppgFailed = { code in self.ppgFailed?(self.id, code) }
					mMainCharacteristic?.writeEpochComplete = { successful in self.writeEpochComplete?(self.id, successful) }
					mMainCharacteristic?.readEpochComplete = { successful, value in self.readEpochComplete?(self.id, successful,  value) }
					mMainCharacteristic?.endSleepComplete = { successful in self.endSleepComplete?(self.id, successful) }
					mMainCharacteristic?.getAllPacketsComplete = { successful in self.getAllPacketsComplete?(self.id, successful) }
					mMainCharacteristic?.getNextPacketComplete = { successful, error_code, caughtUp, packet in self.getNextPacketComplete?(self.id, successful, error_code, caughtUp, packet) }
					mMainCharacteristic?.getPacketCountComplete = { successful, count in self.getPacketCountComplete?(self.id, successful, count) }
					mMainCharacteristic?.disableWornDetectComplete = { successful in self.disableWornDetectComplete?(self.id, successful) }
					mMainCharacteristic?.enableWornDetectComplete = { successful in self.enableWornDetectComplete?(self.id, successful) }
					mMainCharacteristic?.dataPackets = { packets in self.dataPackets?(self.id, packets) }
					mMainCharacteristic?.dataComplete = { bad_fw_read_count, bad_fw_parse_count, overflow_count, bad_sdk_parse_count in self.dataComplete?(self.id, bad_fw_read_count, bad_fw_parse_count, overflow_count, bad_sdk_parse_count) }
					mMainCharacteristic?.dataFailure = { self.dataFailure?(self.id) }
					mMainCharacteristic?.deviceWornStatus = { isWorn in
						if (isWorn) { self.wornStatus = "Worn" }
						else { self.wornStatus = "Not Worn" }
						self.deviceWornStatus?(self.id, isWorn)
					}
					mMainCharacteristic?.setSessionParamComplete = { successful, parameter in self.setSessionParamComplete?(self.id, successful, parameter) }
					mMainCharacteristic?.getSessionParamComplete = { successful, parameter, value in self.getSessionParamComplete?(self.id, successful, parameter, value) }
					mMainCharacteristic?.acceptSessionParamsComplete	= { successful in self.acceptSessionParamsComplete?(self.id, successful) }
					mMainCharacteristic?.resetSessionParamsComplete	= { successful in self.resetSessionParamsComplete?(self.id, successful) }
					mMainCharacteristic?.manufacturingTestComplete	= { successful in self.manufacturingTestComplete?(self.id, successful) }
					mMainCharacteristic?.manufacturingTestResult	= { valid, result in self.manufacturingTestResult?(self.id, valid, result) }
					mMainCharacteristic?.recalibratePPGComplete		= { successful in self.recalibratePPGComplete?(self.id, successful) }
					mMainCharacteristic?.deviceChargingStatus		= { charging, on_charger, error in
						if (charging) { self.chargingStatus	= "Charging" }
						else if (on_charger) { self.chargingStatus = "On Charger" }
						else if (error) { self.chargingStatus = "Charging Error" }
						else { self.chargingStatus = "Not Charging" }
						self.deviceChargingStatus?(self.id, charging, on_charger, error) }
					mMainCharacteristic?.discoverDescriptors()
					mMainCharacteristic?.setHRZoneColorComplete		= { successful, type in self.setHRZoneColorComplete?(self.id, successful, type) }
					mMainCharacteristic?.getHRZoneColorComplete		= { successful, type, red, green, blue, on_ms, off_ms in self.getHRZoneColorComplete?(self.id, successful, type, red, green, blue, on_ms, off_ms) }
					mMainCharacteristic?.setHRZoneRangeComplete		= { successful in self.setHRZoneRangeComplete?(self.id, successful) }
					mMainCharacteristic?.getHRZoneRangeComplete		= { successful, enabled, high_value, low_value in self.getHRZoneRangeComplete?(self.id, successful, enabled, high_value, low_value) }
					mMainCharacteristic?.getManualModeComplete		= { successful, algorithm in self.getManualModeComplete?(self.id, successful, algorithm) }

				case .kairosDataCharacteristic:
					mDataCharacteristic = customDataCharacteristic(peripheral, characteristic: characteristic)
					mDataCharacteristic?.dataPackets = { packets in self.dataPackets?(self.id, packets) }
					mDataCharacteristic?.dataComplete = { bad_fw_read_count, bad_fw_parse_count, overflow_count, bad_sdk_parse_count in self.dataComplete?(self.id, bad_fw_read_count, bad_fw_parse_count, overflow_count, bad_sdk_parse_count) }
					mDataCharacteristic?.discoverDescriptors()
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
					mAmbiqOTARXCharacteristic?.started	= { self.updateFirmwareStarted?(self.id) }
					mAmbiqOTARXCharacteristic?.finished = { self.updateFirmwareFinished?(self.id) }
					mAmbiqOTARXCharacteristic?.failed	= { code, message in self.updateFirmwareFailed?(self.id, code, message) }
					mAmbiqOTARXCharacteristic?.progress	= { percent in self.updateFirmwareProgress?(self.id, percent) }
					
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
					mMainCharacteristic?.startManualComplete = { successful in self.startManualComplete?(self.id, successful) }
					mMainCharacteristic?.stopManualComplete = { successful in self.stopManualComplete?(self.id, successful) }
					mMainCharacteristic?.ledComplete = { successful in self.ledComplete?(self.id, successful) }
					mMainCharacteristic?.enterShipModeComplete = { successful in self.enterShipModeComplete?(self.id, successful) }
					mMainCharacteristic?.writeSerialNumberComplete = { successful in self.writeSerialNumberComplete?(self.id, successful) }
					mMainCharacteristic?.readSerialNumberComplete = { successful, partID in self.readSerialNumberComplete?(self.id, successful, partID) }
					mMainCharacteristic?.deleteSerialNumberComplete = { successful in self.deleteSerialNumberComplete?(self.id, successful) }
					mMainCharacteristic?.writeAdvIntervalComplete = { successful in self.writeAdvIntervalComplete?(self.id, successful) }
					mMainCharacteristic?.readAdvIntervalComplete = { successful, seconds in self.readAdvIntervalComplete?(self.id, successful, seconds) }
					mMainCharacteristic?.deleteAdvIntervalComplete = { successful in self.deleteAdvIntervalComplete?(self.id, successful) }
					mMainCharacteristic?.clearChargeCyclesComplete = { successful in self.clearChargeCyclesComplete?(self.id, successful) }
					mMainCharacteristic?.readChargeCyclesComplete = { successful, cycles in self.readChargeCyclesComplete?(self.id, successful, cycles) }
					mMainCharacteristic?.readCanLogDiagnosticsComplete = { successful, allow in self.readCanLogDiagnosticsComplete?(self.id, successful, allow) }
					mMainCharacteristic?.updateCanLogDiagnosticsComplete = { successful in self.updateCanLogDiagnosticsComplete?(self.id, successful) }
					mMainCharacteristic?.rawLoggingComplete = { successful in self.rawLoggingComplete?(self.id, successful) }
					mMainCharacteristic?.getRawLoggingStatusComplete = { successful, enabled in self.getRawLoggingStatusComplete?(self.id, successful, enabled) }
					mMainCharacteristic?.getWornOverrideStatusComplete = { successful, overridden in self.getWornOverrideStatusComplete?(self.id, successful, overridden) }
					mMainCharacteristic?.allowPPGComplete = { successful in self.allowPPGComplete?(self.id, successful)}
					mMainCharacteristic?.wornCheckComplete = { successful, code, value in self.wornCheckComplete?(self.id, successful, code, value )}
					mMainCharacteristic?.resetComplete = { successful in self.resetComplete?(self.id, successful) }
					mMainCharacteristic?.ppgMetrics = { successful, packet in self.ppgMetrics?(self.id, successful, packet) }
					mMainCharacteristic?.ppgFailed = { code in self.ppgFailed?(self.id, code) }
					mMainCharacteristic?.writeEpochComplete = { successful in self.writeEpochComplete?(self.id, successful) }
					mMainCharacteristic?.readEpochComplete = { successful, value in self.readEpochComplete?(self.id, successful,  value) }
					mMainCharacteristic?.endSleepComplete = { successful in self.endSleepComplete?(self.id, successful) }
					mMainCharacteristic?.getAllPacketsComplete = { successful in self.getAllPacketsComplete?(self.id, successful) }
					mMainCharacteristic?.getNextPacketComplete = { successful, error_code, caughtUp, packet in self.getNextPacketComplete?(self.id, successful, error_code, caughtUp, packet) }
					mMainCharacteristic?.getPacketCountComplete = { successful, count in self.getPacketCountComplete?(self.id, successful, count) }
					mMainCharacteristic?.disableWornDetectComplete = { successful in self.disableWornDetectComplete?(self.id, successful) }
					mMainCharacteristic?.enableWornDetectComplete = { successful in self.enableWornDetectComplete?(self.id, successful) }
					mMainCharacteristic?.dataPackets = { packets in self.dataPackets?(self.id, packets) }
					mMainCharacteristic?.dataComplete = { bad_fw_read_count, bad_fw_parse_count, overflow_count, bad_sdk_parse_count in self.dataComplete?(self.id, bad_fw_read_count, bad_fw_parse_count, overflow_count, bad_sdk_parse_count) }
					mMainCharacteristic?.dataFailure = { self.dataFailure?(self.id) }
					mMainCharacteristic?.deviceWornStatus = { isWorn in
						if (isWorn) { self.wornStatus = "Worn" }
						else { self.wornStatus = "Not Worn" }
						self.deviceWornStatus?(self.id, isWorn)
					}
					mMainCharacteristic?.setSessionParamComplete = { successful, parameter in self.setSessionParamComplete?(self.id, successful, parameter) }
					mMainCharacteristic?.getSessionParamComplete = { successful, parameter, value in self.getSessionParamComplete?(self.id, successful, parameter, value) }
					mMainCharacteristic?.acceptSessionParamsComplete	= { successful in self.acceptSessionParamsComplete?(self.id, successful) }
					mMainCharacteristic?.resetSessionParamsComplete	= { successful in self.resetSessionParamsComplete?(self.id, successful) }
					mMainCharacteristic?.manufacturingTestComplete	= { successful in self.manufacturingTestComplete?(self.id, successful) }
					mMainCharacteristic?.manufacturingTestResult		= { valid, result in self.manufacturingTestResult?(self.id, valid, result)}
					mMainCharacteristic?.deviceChargingStatus			= { charging, on_charger, error in
						if (charging) { self.chargingStatus	= "Charging" }
						else if (on_charger) { self.chargingStatus = "On Charger" }
						else if (error) { self.chargingStatus = "Charging Error" }
						else { self.chargingStatus = "Not Charging" }
						self.deviceChargingStatus?(self.id, charging, on_charger, error) }
					mMainCharacteristic?.discoverDescriptors()
					
				case .livotalDataCharacteristic:
					mDataCharacteristic = customDataCharacteristic(peripheral, characteristic: characteristic)
					mDataCharacteristic?.dataPackets = { packets in self.dataPackets?(self.id, packets) }
					mDataCharacteristic?.dataComplete = { bad_fw_read_count, bad_fw_parse_count, overflow_count, bad_sdk_parse_count in self.dataComplete?(self.id, bad_fw_read_count, bad_fw_parse_count, overflow_count, bad_sdk_parse_count) }
					mDataCharacteristic?.discoverDescriptors()

				case .nordicDFUCharacteristic:
					if let name = peripheral.name {
						mNordicDFUCharacteristic	= nordicDFUCharacteristic(peripheral, characteristic: characteristic, name: name)
					}
					else {
						mNordicDFUCharacteristic	= nordicDFUCharacteristic(peripheral, characteristic: characteristic)
					}
					mNordicDFUCharacteristic?.failed = { id, code, message in self.updateFirmwareFailed?(id, code, message) }
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
					#endif

					#if UNIVERSAL || ALTER
					case .alterMainCharacteristic		: mMainCharacteristic?.didDiscoverDescriptor()
					case .alterDataCharacteristic		: mDataCharacteristic?.didDiscoverDescriptor()
					#endif

					#if UNIVERSAL || KAIROS
					case .kairosMainCharacteristic		: mMainCharacteristic?.didDiscoverDescriptor()
					case .kairosDataCharacteristic		: mDataCharacteristic?.didDiscoverDescriptor()
					#endif

					#if UNIVERSAL || ETHOS || ALTER || KAIROS
					case .ambiqOTARXCharacteristic		: log?.e ("\(self.id) '\(enumerated.title)' - should not be here")
					case .ambiqOTATXCharacteristic		: mAmbiqOTATXCharacteristic?.didDiscoverDescriptor()
					#endif
					
					#if UNIVERSAL || LIVOTAL
					case .livotalMainCharacteristic		: mMainCharacteristic?.didDiscoverDescriptor()
					case .livotalDataCharacteristic		: mDataCharacteristic?.didDiscoverDescriptor()
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
				mDISCharacteristicCount			= mDISCharacteristicCount - 1

			case .hardware_revision_string		:
				mHardwareRevision?.didUpdateValue()
				mDISCharacteristicCount			= mDISCharacteristicCount - 1

			case .firmware_revision_string		:
				mFirmwareVersion?.didUpdateValue()
				mDISCharacteristicCount			= mDISCharacteristicCount - 1

			case .software_revision_string		:
				mSoftwareRevision?.didUpdateValue()
				mDISCharacteristicCount			= mDISCharacteristicCount - 1

			case .manufacturer_name_string		:
				mManufacturerName?.didUpdateValue()
				mDISCharacteristicCount			= mDISCharacteristicCount - 1

			case .serial_number_string			:
				mSerialNumber?.didUpdateValue()
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
			#endif

			#if UNIVERSAL || ALTER
			case .alterMainCharacteristic		: mMainCharacteristic?.didUpdateValue()
			case .alterDataCharacteristic		: mDataCharacteristic?.didUpdateValue()
			#endif

			#if UNIVERSAL || KAIROS
			case .kairosMainCharacteristic		: mMainCharacteristic?.didUpdateValue()
			case .kairosDataCharacteristic		: mDataCharacteristic?.didUpdateValue()
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
					#endif

					#if UNIVERSAL || ALTER
					case .alterMainCharacteristic			: mMainCharacteristic?.didUpdateNotificationState()
					case .alterDataCharacteristic			: mDataCharacteristic?.didUpdateNotificationState()
					#endif

					#if UNIVERSAL || KAIROS
					case .kairosMainCharacteristic			: mMainCharacteristic?.didUpdateNotificationState()
					case .kairosDataCharacteristic			: mDataCharacteristic?.didUpdateNotificationState()
					#endif
						
					#if UNIVERSAL || ETHOS || ALTER || KAIROS
					case .ambiqOTARXCharacteristic			: log?.e ("\(self.id) '\(enumerated.title)' - should not be here")
					case .ambiqOTATXCharacteristic			: mAmbiqOTATXCharacteristic?.didUpdateNotificationState()
					#endif

					#if UNIVERSAL || LIVOTAL
					case .livotalMainCharacteristic			: mMainCharacteristic?.didUpdateNotificationState()
					case .livotalDataCharacteristic			: mDataCharacteristic?.didUpdateNotificationState()
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
