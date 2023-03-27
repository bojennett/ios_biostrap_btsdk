//
//  hrZoneRangeType.swift
//  biostrapDeviceSDK
//
//  Created by Joseph A. Bennett on 3/23/23.
//

import Foundation

#if UNIVERSAL || ALTER || KAIROS
@objc public enum hrZoneRangeType: UInt8, Codable {
	case below				= 0x00		// Below the minimum range
	case within				= 0x01		// Wthin the range
	case above				= 0x02		// Above the maximum range
	case unknown			= 0xff		// Unknown
	
	public var title: String {
		switch (self) {
		case .below			: return ("Below")
		case .within		: return ("Within")
		case .above			: return ("Above")
		case .unknown		: return ("Unknown")
		}
	}
	
	public init(from decoder: Decoder) throws {
		let container = try decoder.singleValueContainer()
		let code = try? container.decode(String.self)
		
		switch code {
		case "Below"		: self = .below
		case "Within"		: self = .within
		case "Above"		: self = .above
		default				: self = .unknown
		}
	}
}
#endif
