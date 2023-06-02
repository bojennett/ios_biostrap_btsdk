//
//  bookendType.swift
//  biostrapDeviceSDK
//
//  Created by Joseph A. Bennett on 6/2/23.
//

import Foundation

@objc public enum bookendType: UInt8, Codable {
	case activity				= 0x00
	case unknown				= 0xff
	
	public var title: String {
		switch (self) {
		case .activity			: return ("Activity")
		default					: return ("Unknown")
		}
	}
	
	public init(from decoder: Decoder) throws {
		let container = try decoder.singleValueContainer()
		let code = try? container.decode(String.self)
		switch code {
		case "Activity"			: self = .activity
		default					: self = .unknown
		}
	}
}
