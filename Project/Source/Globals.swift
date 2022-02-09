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
@objc public enum packetType: UInt8, Codable {
	case unknown			= 0x00
	case steps				= 0x81
	case ppg				= 0x82
	case activity			= 0x83
	case temp				= 0x84
	case worn				= 0x85
	case sleep				= 0x86
	case diagnostic			= 0x87
	case rawAccel			= 0xe0
	case rawAccelFifoCount	= 0xe1
	case rawPPGProximity	= 0xe2
	case rawPPGGreen		= 0xe3
	case rawPPGRed			= 0xe4
	case rawPPGIR			= 0xe5
	case rawPPGFifoCount	= 0xe6
	case caughtUp			= 0xf0
	
	public init(from decoder: Decoder) throws {
		let container = try decoder.singleValueContainer()
		let code = try? container.decode(String.self)
		switch code {
		case "Unknown"				: self	= .unknown
		case "Steps"				: self	= .steps
		case "PPG Results"			: self	= .ppg
		case "Activity"				: self	= .activity
		case "Temperature"			: self	= .temp
		case "Worn"					: self	= .worn
		case "Sleep"				: self	= .sleep
		case "Diagnostic"			: self	= .diagnostic
		case "Raw Accel"			: self	= .rawAccel
		case "Raw Accel FIFO Count"	: self	= .rawAccelFifoCount
		case "Raw PPG Proximity"	: self	= .rawPPGProximity
		case "Raw PPG Green Sample"	: self	= .rawPPGGreen
		case "Raw PPG Red Sample"	: self	= .rawPPGRed
		case "Raw PPG IR Sample"	: self	= .rawPPGIR
		case "Raw PPG FIFO Count"	: self	= .rawPPGFifoCount
		case "Caught Up"			: self	= .caughtUp
		default: self	= .unknown
		}
	}
		
	public var title: String {
		switch (self) {
		case .unknown			: return "Unknown"
		case .steps				: return "Steps"
		case .ppg				: return "PPG Results"
		case .activity			: return "Activity"
		case .temp				: return "Temperature"
		case .worn				: return "Worn"
		case .sleep				: return "Sleep"
		case .diagnostic		: return "Diagnostic"
		case .rawAccel			: return "Raw Accel"
		case .rawAccelFifoCount	: return "Raw Accel FIFO Count"
		case .rawPPGProximity	: return "Raw PPG Proximity"
		case .rawPPGGreen		: return "Raw PPG Green Sample"
		case .rawPPGRed			: return "Raw PPG Red Sample"
		case .rawPPGIR			: return "Raw PPG IR Sample"
		case .rawPPGFifoCount	: return "Raw PPG FIFO Count"
		case .caughtUp			: return "Caught Up"
		}
	}
	
	var length: Int {
		switch (self) {
		case .unknown			: return 300
		case .steps				: return 7
		case .ppg				: return 17
		case .activity			: return 10
		case .temp				: return 9
		case .worn				: return 6
		case .sleep				: return 9
		case .diagnostic		: return 0 		// Done by calculation
		case .rawAccel			: return 13
		case .rawAccelFifoCount	: return 6
		case .rawPPGProximity	: return 5
		case .rawPPGGreen		: return 5
		case .rawPPGRed			: return 5
		case .rawPPGIR			: return 5
		case .rawPPGFifoCount	: return 6
		case .caughtUp			: return 1
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
internal var gblEmulatorID		= ""

func gblReturnID(_ id: String) -> String {
	if (id == gblEmulatorID) { return "EMULATOR" }
	return id
}

func gblReturnID(_ peripheral: CBPeripheral) -> String {
	return (gblReturnID(peripheral.identifier.uuidString))
}

