//
//  wavelengthType.swift
//  biostrapDeviceSDK
//
//  Created by Joseph A. Bennett on 5/30/23.
//

import Foundation

@objc public enum wavelengthType: UInt8, Codable {
	case green			= 0x00
	case red			= 0x01
	case IR				= 0x02
	case whiteIR		= 0x03
	case whiteWhite		= 0x04
	case unknown		= 0xff
	
	public init(from decoder: Decoder) throws {
		let container = try decoder.singleValueContainer()
		let code = try? container.decode(String.self)
		switch code {
		case "Unknown"				: self	= .unknown
		case "Green"				: self	= .green
		case "Red"					: self	= .red
		case "IR"					: self	= .IR
		case "White IR"				: self	= .whiteIR
		case "White White"			: self	= .whiteWhite
		default						: self	= .unknown
		}
	}

	public var title: String {
		switch (self) {
		case .green					: return "Green"
		case .red					: return "Red"
		case .IR					: return "IR"
		case .whiteIR				: return "White IR"
		case .whiteWhite			: return "White White"
		case .unknown				: return "Unknown"
		}
	}
}
