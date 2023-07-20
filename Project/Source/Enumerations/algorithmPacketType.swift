//
//  algorithmPacketType.swift
//  biostrapDeviceSDK
//
//  Created by Joseph A. Bennett on 7/6/23.
//

import Foundation

@objc public enum algorithmPacketType: UInt8, Codable {
	case philipsSleep			= 0x2f
	case unknown				= 0xff
	
	public var title: String {
		switch (self) {
		case .philipsSleep		: return ("Philips Sleep")
		default					: return ("Unknown")
		}
	}
	
	public init(from decoder: Decoder) throws {
		let container = try decoder.singleValueContainer()
		let code = try? container.decode(String.self)
		switch code {
		case "Philips Sleep"	: self = .philipsSleep
		default					: self = .unknown
		}
	}
}
