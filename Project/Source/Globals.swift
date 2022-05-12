//
//  Globals.swift
//  biostrapDeviceSDK
//
//  Created by Joseph A. Bennett on 3/31/21.
//

import Foundation
import CoreBluetooth

var log				: Logging?

var gblDFUName		= "DFU"
var dfu				= nordicDFU()

var gblLimitLivotal	= false
var gblLimitEthos	= false

//--------------------------------------------------------------------------------
//
//
//
//--------------------------------------------------------------------------------
@objc public enum firmwareErorCode: UInt8 {
	case invalid				= 0x00
	case success				= 0x01
	case opcodeNotSupported		= 0x02
	case invalidParameters		= 0x03
	case insufficientResources	= 0x04
	case invalidObject			= 0x05
	case unsupportedType		= 0x07
	case operationNotPermitted	= 0x08
	case operationFailed		= 0x0A
	case extendedError			= 0x0B
	
	var description	: String {
		switch (self) {
		case .invalid				: return ("Invalid opcode")
		case .success				: return ("Operation successful")
		case .opcodeNotSupported	: return ("Opcode not supported")
		case .invalidParameters		: return ("Missing or invalid parameter value")
		case .insufficientResources	: return ("Not enough memory for the data object")
		case .invalidObject			: return ("Data object does not match the firmware and hardware requirements, the signature is wrong, or parsing the command failed")
		case .unsupportedType		: return ("Not a valid object type for a Create request")
		case .operationNotPermitted	: return ("The state of the DFU process does not allow this operation")
		case .operationFailed		: return ("Operation failed")
		case .extendedError			: return ("Extended error")
		}
	}
}

//--------------------------------------------------------------------------------
//
//
//
//--------------------------------------------------------------------------------
@objc public enum extendedFirmwareError: UInt8 {
	case NO_ERROR				= 0x00 // No extended error code has been set.
	case INVALID_ERROR_CODE		= 0x01 // Invalid error code.
	case WRONG_COMMAND_FORMAT	= 0x02 // The format of the command was incorrect.
	case UNKNOWN_COMMAND		= 0x03 // The command was successfully parsed but it is not supported or unknown.
	case INIT_COMMAND_INVALID	= 0x04 // The init command is invalid
	case FW_VERSION_FAILURE		= 0x05 // The firmware version is too low
	case HW_VERSION_FAILURE		= 0x06 // The hardware version of the device does not match the required hardware version for the update
	case SD_VERSION_FAILURE		= 0x07 // The array of supported SoftDevices for the update does not contain the FWID of the current SoftDevice
	case SIGNATURE_MISSING		= 0x08 // The init packet does not contain a signature.
	case WRONG_HASH_TYPE		= 0x09 // The hash type that is specified by the init packet is not supported by the DFU bootloader.
	case HASH_FAILED			= 0x0A // The hash of the firmware image cannot be calculated.
	case WRONG_SIGNATURE_TYPE	= 0x0B // The type of the signature is unknown or not supported by the DFU bootloader.
	case VERIFICATION_FAILED	= 0x0C // The hash of the received firmware image does not match the hash in the init packet.
	case INSUFFICIENT_SPACE		= 0x0D // The available space on the device is insufficient to hold the firmware.
}

//--------------------------------------------------------------------------------
//
//
//
//--------------------------------------------------------------------------------
@objc public enum sessionParameterType: UInt8, Codable {
	case ppgCapturePeriod		= 0x00
	case ppgCaptureDuration		= 0x01
	case tag					= 0x10
	case reset					= 0xfd
	case accept					= 0xfe
	case unknown				= 0xff
	
	public var title: String {
		switch (self) {
		case .ppgCapturePeriod		: return "PPG Capture Period"
		case .ppgCaptureDuration	: return "PPG Capture Duration"
		case .tag					: return "Tag"
		case .reset					: return "Reset"
		case .accept				: return "Accept"
		case .unknown				: return "Unknown"
		}
	}
}

//--------------------------------------------------------------------------------
//
//
//
//--------------------------------------------------------------------------------
@objc public enum deviceParameterType: UInt8, Codable {
	case serialNumber			= 0x01
	case chargeCycle			= 0x02
	case advertisingInterval	= 0x03
	
	public var title: String {
		switch (self) {
		case .serialNumber			: return "serialNumber"
		case .chargeCycle			: return "chargeCycle"
		case .advertisingInterval	: return "advertisingInterval"
		}
	}
}

//--------------------------------------------------------------------------------
//
//
//
//--------------------------------------------------------------------------------
@objc public enum packetType: UInt8, Codable {
	case unknown			= 0x00
	case steps				= 0x81
	case ppg				= 0x82
	case activity			= 0x83
	case temp				= 0x84
	case worn				= 0x85
	case sleep				= 0x86
	case diagnostic			= 0x87
	case ppg_failed			= 0x88
	case battery			= 0x89
	
	case rawPPGCompressedGreen	= 0xd3
	case rawPPGCompressedRed	= 0xd4
	case rawPPGCompressedIR		= 0xd5

	case rawAccel			= 0xe0
	case rawAccelFifoCount	= 0xe1
	case rawPPGProximity	= 0xe2
	#if LIVOTAL
	case rawPPGGreen		= 0xe3
	#endif
	
	#if ETHOS || UNIVERSAL
	case rawPPGGreenIRRPD	= 0xe3
	#endif

	case rawPPGRed			= 0xe4
	case rawPPGIR			= 0xe5
	case rawPPGFifoCount	= 0xe6
	
	#if ETHOS || UNIVERSAL
	case rawPPGGreenWhitePD	= 0xe7
	case rawPPGWhiteIRRPD	= 0xe8
	case rawPPGWhiteWhitePD	= 0xe9
	case rawGyroADC			= 0xea
	#endif
	
	case rawAccelADC		= 0xeb
	
	case milestone			= 0xf0
	case settings			= 0xf1
	
	public init(from decoder: Decoder) throws {
		let container = try decoder.singleValueContainer()
		let code = try? container.decode(String.self)
		switch code {
		case "Unknown"				: self	= .unknown
		case "Steps"				: self	= .steps
		case "PPG Results"			: self	= .ppg
		case "PPG Failed"			: self	= .ppg_failed
		case "Activity"				: self	= .activity
		case "Temperature"			: self	= .temp
		case "Worn"					: self	= .worn
		case "Battery"				: self	= .battery
		case "Sleep"				: self	= .sleep
		case "Diagnostic"			: self	= .diagnostic
		case "Raw Accel"			: self	= .rawAccel
		case "Raw Accel FIFO Count"	: self	= .rawAccelFifoCount
		case "Raw PPG Proximity"	: self	= .rawPPGProximity

		case "Raw PPG Compressed Green"	: self	= .rawPPGCompressedGreen
		case "Raw PPG Compressed Red"	: self	= .rawPPGCompressedRed
		case "Raw PPG Compressed IR"	: self	= .rawPPGCompressedIR

		#if LIVOTAL
		case "Raw PPG Green Sample"	: self	= .rawPPGGreen
		#endif

		#if ETHOS || UNIVERSAL
		case "Raw PPG Green Sample IRR PD"	: self	= .rawPPGGreenIRRPD
		#endif
			
		case "Raw PPG Red Sample"	: self	= .rawPPGRed
		case "Raw PPG IR Sample"	: self	= .rawPPGIR
		case "Raw PPG FIFO Count"	: self	= .rawPPGFifoCount
			
		#if ETHOS || UNIVERSAL
		case "Raw PPG Green Sample White PD"	: self	= .rawPPGGreenWhitePD
		case "Raw PPG White Sample IRR PD"		: self	= .rawPPGWhiteIRRPD
		case "Raw PPG White Sample White PD"	: self	= .rawPPGWhiteWhitePD
		case "Raw Gyro ADC"						: self	= .rawGyroADC
		#endif
			
		case "Raw Accel ADC"		: self	= .rawAccelADC

		case "Milestone"			: self	= .milestone
		case "Settings"				: self	= .settings
		default: self	= .unknown
		}
	}
		
	public var title: String {
		switch (self) {
		case .unknown			: return "Unknown"
		case .steps				: return "Steps"
		case .ppg				: return "PPG Results"
		case .ppg_failed		: return "PPG Failed"
		case .activity			: return "Activity"
		case .temp				: return "Temperature"
		case .worn				: return "Worn"
		case .battery			: return "Battery"
		case .sleep				: return "Sleep"
		case .diagnostic		: return "Diagnostic"
		case .rawAccel			: return "Raw Accel"
		case .rawAccelFifoCount	: return "Raw Accel FIFO Count"
		case .rawPPGProximity	: return "Raw PPG Proximity"

		case .rawPPGCompressedGreen		: return "Raw PPG Compressed Green"
		case .rawPPGCompressedRed		: return "Raw PPG Compressed Red"
		case .rawPPGCompressedIR		: return "Raw PPG Compressed IR"

		#if LIVOTAL
		case .rawPPGGreen		: return "Raw PPG Green Sample"
		#endif

		#if ETHOS || UNIVERSAL
		case .rawPPGGreenIRRPD	: return "Raw PPG Green Sample IRR PD"
		#endif

		case .rawPPGRed			: return "Raw PPG Red Sample"
		case .rawPPGIR			: return "Raw PPG IR Sample"
		case .rawPPGFifoCount	: return "Raw PPG FIFO Count"
			
		#if ETHOS || UNIVERSAL
		case .rawPPGGreenWhitePD	: return "Raw PPG Green Sample White PD"
		case .rawPPGWhiteIRRPD		: return "Raw PPG White Sample IRR PD"
		case .rawPPGWhiteWhitePD	: return "Raw PPG White Sample White PD"
		case .rawGyroADC			: return "Raw Gyro ADC"
		#endif
			
		case .rawAccelADC		: return "Raw Accel ADC"
			
		case .milestone			: return "Milestone"
		case .settings			: return "Settings"
		}
	}
	
	var length: Int {
		switch (self) {
		case .unknown			: return 300
		case .steps				: return 7
		case .ppg				: return 17
		case .ppg_failed		: return 6
		case .activity			: return 10
		case .temp				: return 9
		case .worn				: return 6
		case .battery			: return 8
		case .sleep				: return 9
		case .diagnostic		: return 0 		// Done by calculation
		case .rawAccel			: return 13
		case .rawAccelFifoCount	: return 6
		case .rawPPGProximity	: return 5

		case .rawPPGCompressedGreen		: return 0	// Done by calculation
		case .rawPPGCompressedRed		: return 0	// Done by calculation
		case .rawPPGCompressedIR		: return 0	// Done by calculation

		#if LIVOTAL
		case .rawPPGGreen		: return 5
		#endif
			
		#if ETHOS || UNIVERSAL
		case .rawPPGGreenIRRPD	: return 5
		#endif
			
		case .rawPPGRed			: return 5
		case .rawPPGIR			: return 5
		case .rawPPGFifoCount	: return 6
			
		#if ETHOS || UNIVERSAL
		case .rawPPGGreenWhitePD	: return 5
		case .rawPPGWhiteIRRPD		: return 5
		case .rawPPGWhiteWhitePD	: return 5
		case .rawGyroADC			: return 7
		#endif
			
		case .rawAccelADC		: return 7

		case .milestone			: return 7
		case .settings			: return 6
		}
	}
}

//--------------------------------------------------------------------------------
//
//
//
//--------------------------------------------------------------------------------
@objc public enum settingsType: UInt8, Codable {
	case accelHalfRange			= 0x00
	case gyroHalfRange			= 0x01
	case imuSamplingRate		= 0x02
	case ppgCapturePeriod		= 0x03
	case ppgCaptureDuration		= 0x04
	case ppgSamplingRate		= 0x05
	case unknown				= 0xff
	
	public init(from decoder: Decoder) throws {
		let container = try decoder.singleValueContainer()
		let code = try? container.decode(String.self)
		switch code {
		case "accel_halfrange"		: self	= .accelHalfRange
		case "gyro_halfrange"		: self	= .gyroHalfRange
		case "imu_sampling_rate"	: self	= .imuSamplingRate
		case "ppg_capture_period"	: self	= .ppgCapturePeriod
		case "ppg_capture_duration"	: self	= .ppgCaptureDuration
		case "ppg_sampling_rate"	: self	= .ppgSamplingRate
		default						: self	= .unknown
		}
	}
	
	public var title: String {
		switch (self) {
		case .accelHalfRange		: return "accel_halfrange"
		case .gyroHalfRange			: return "gyro_halfrange"
		case .imuSamplingRate		: return "imu_sampling_rate"
		case .ppgCapturePeriod		: return "ppg_capture_period"
		case .ppgCaptureDuration	: return "ppg_capture_duration"
		case .ppgSamplingRate		: return "ppg_sampling_rate"
		case .unknown				: return "unknown"
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
