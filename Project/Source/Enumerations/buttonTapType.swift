//
//  buttonTapType.swift
//  biostrapDeviceSDK
//
//  Created by Joseph A. Bennett on 6/6/23.
//

import Foundation

@objc public enum buttonTapType: UInt8, Codable {
	case single				= 0x00
	case double				= 0x01
	case triple				= 0x02
	case unknown			= 0xff
	
	public var title: String {
		switch (self) {
		case .single		: return ("Single Tap")
		case .double		: return ("Double Tap")
		case .triple		: return ("Triple Tap")
		case .unknown		: return ("Unknown")
		}
	}
	
	public init(from decoder: Decoder) throws {
		let container = try decoder.singleValueContainer()
		let code = try? container.decode(String.self)
		
		switch code {
		case "Single Tap"	: self = .single
		case "Double Tap"	: self = .double
		case "Triple Tap"	: self = .triple
		default				: self = .unknown
		}
	}
}
