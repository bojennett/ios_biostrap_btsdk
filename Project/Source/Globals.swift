//
//  Globals.swift
//  biostrapDeviceSDK
//
//  Created by Joseph A. Bennett on 3/31/21.
//

import Foundation
import CoreBluetooth

var log				: Logging?

#if UNIVERSAL || LIVOTAL
var gblDFUName		= "DFU"
var dfu				= nordicDFU()
#endif

var gblLimitLivotal	= false
var gblLimitEthos	= false
var gblLimitAlter	= false

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
// Function Name:
//--------------------------------------------------------------------------------
//
//
//
//--------------------------------------------------------------------------------
