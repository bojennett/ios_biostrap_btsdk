//
//  diagnosticType.swift
//  biostrapDeviceSDK
//
//  Created by Joseph A. Bennett on 7/21/22.
//

import Foundation

@objc public enum diagnosticType: UInt8, Codable {
	case sleep				= 0x00		// Packets related to sleep
	case ppgBroken			= 0x01		// The PPG subsystem is broken
	case pmicStatus			= 0x02		// Status register of the PMIC
	case algorithm			= 0x03		// Algorithm library generated
	case rotation			= 0x04		// Got a rotation callback
	case pmicWatchdog		= 0x05		// The PMIC watchdog causes a change in charging status
	case bluetoothPacket	= 0xfe		// The packet received over bluetooth minus the CRC
	case unknown			= 0xff		// Unknown
	
	public var title: String {
		switch (self) {
		case .sleep				: return ("Sleep")
		case .ppgBroken			: return ("PPG Broken")
		case .pmicStatus		: return ("PMIC Status")
		case .algorithm			: return ("Algorithm")
		case .rotation			: return ("Rotation")
		case .pmicWatchdog		: return ("PMIC Watchdog")
		case .bluetoothPacket	: return ("Bluetooth Packet")
		case .unknown			: return ("Unknown")
		}
	}
	
	public init(from decoder: Decoder) throws {
		let container = try decoder.singleValueContainer()
		let code = try? container.decode(String.self)
		switch code {
		case "Sleep"			: self = .sleep
		case "PPG Broken"		: self = .ppgBroken
		case "PMIC Status"		: self = .pmicStatus
		case "Algorithm"		: self = .algorithm
		case "Rotation"			: self = .rotation
		case "PMIC Watchdog"	: self = .pmicWatchdog
		case "Bluetooth Packet"	: self = .bluetoothPacket
		default					: self = .unknown
		}
	}
}
