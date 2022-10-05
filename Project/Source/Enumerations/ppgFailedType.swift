//
//  ppgFailedType.swift
//  biostrapDeviceSDK
//
//  Created by Joseph A. Bennett on 7/21/22.
//

import Foundation

//--------------------------------------------------------------------------------
//
//
//
//--------------------------------------------------------------------------------
@objc public enum ppgFailedType: UInt8, Codable {
	case worn				= 0x00
	case start				= 0x01
	case interrupt			= 0x02
	case overflow			= 0x03
	case fifoRead			= 0x04
	case alreadyRunning		= 0x05
	case lowBattery			= 0x06
	case userDisallowed		= 0x07
	case timedNotWorn		= 0x08
	case unknown			= 0xff
	
	public var title: String {
		switch (self) {
		case .worn				: return ("Worn")
		case .start				: return ("Start")
		case .interrupt			: return ("Interrupt")
		case .overflow			: return ("Overflow")
		case .fifoRead			: return ("FIFO Read")
		case .alreadyRunning	: return ("Already Running")
		case .lowBattery		: return ("Low Battery")
		case .userDisallowed	: return ("User Disallowed")
		case .timedNotWorn		: return ("Timed Not Worn")
		case .unknown			: return ("Unknown")
		}
	}
	
	public init(from decoder: Decoder) throws {
		let container = try decoder.singleValueContainer()
		let code = try? container.decode(String.self)
		switch code {
		case "Worn"				: self = .worn
		case "Start"			: self = .start
		case "Interrupt"		: self = .interrupt
		case "Overflow"			: self = .overflow
		case "FIFO Read"		: self = .fifoRead
		case "Already Running"	: self = .alreadyRunning
		case "Low Battery"		: self = .lowBattery
		case "User Disallowed"	: self = .userDisallowed
		case "Timed Not Worn"	: self = .timedNotWorn
		default					: self = .unknown
		}
	}
}
