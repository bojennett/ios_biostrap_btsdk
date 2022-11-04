//
//  nextPacketStatusType.swift
//  biostrapDeviceSDK
//
//  Created by Joseph A. Bennett on 11/3/22.
//

import Foundation

@objc public enum nextPacketStatusType: UInt8, Codable {
	case successful			= 0x00
	case busy				= 0x01
	case caughtUp			= 0x02
	case pageEmpty			= 0x03
	case unknownPacket		= 0x04
	case badCommandFormat	= 0x05
	case badJSON			= 0xfc
	case badSDKDecode		= 0xfd
	case missingDevice		= 0xfe
	case unknown			= 0xff
	
	public init(from decoder: Decoder) throws {
		let container = try decoder.singleValueContainer()
		let code = try? container.decode(String.self)
		switch code {
		case "successful"			: self	= .successful
		case "busy"					: self	= .busy
		case "caughtUp"				: self	= .caughtUp
		case "pageEmpty"			: self	= .pageEmpty
		case "unknownPacket"		: self	= .unknownPacket
		case "badCommandFormat"		: self	= .badCommandFormat
		case "badJSON"				: self	= .badJSON
		case "badSDKDecode"			: self	= .badSDKDecode
		case "missingDevice"		: self	= .missingDevice
		default						: self	= .unknown
		}
	}
	
	public var title: String {
		switch (self) {
		case .successful			: return "successful"
		case .busy					: return "busy"
		case .caughtUp				: return "caughtUp"
		case .pageEmpty				: return "pageEmpty"
		case .unknownPacket			: return "unknownPacket"
		case .badCommandFormat		: return "badCommandFormat"
		case .badJSON				: return "badJSON"
		case .badSDKDecode			: return "badSDKDecode"
		case .missingDevice			: return "missingDevice"
		case .unknown				: return "unknown"
		}
	}
}
