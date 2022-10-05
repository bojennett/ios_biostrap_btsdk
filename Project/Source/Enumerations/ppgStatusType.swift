//
//  ppgStatusType.swift
//  biostrapDeviceSDK
//
//  Created by Joseph A. Bennett on 9/28/22.
//

import Foundation

//--------------------------------------------------------------------------------
//
//
//
//--------------------------------------------------------------------------------
@objc public enum ppgStatusType: UInt8, Codable {
	case userContinuous				= 0x00
	case userComplete				= 0x01
	case backgroundComplete			= 0x02
	case backgroundMedtor			= 0x03
	case backgroundWornStop			= 0x04
	case backgroundUserStop			= 0x05
	case backgroundMotionStop		= 0x06
	case userWornStop				= 0x07
	case userUserStop				= 0x08
	case userMotionStop				= 0x09
	case userMedtorMotion			= 0x0a
	case unknown					= 0xff

	public var title: String {
		switch (self) {
		case .userContinuous			: return ("User Continuous")
		case .userComplete				: return ("User Complete")
		case .backgroundComplete		: return ("Background Complete")
		case .backgroundMedtor			: return ("Background Medtor")
		case .backgroundWornStop		: return ("Background Worn Stopped")
		case .backgroundUserStop		: return ("Background User Stopped")
		case .backgroundMotionStop		: return ("Background Motion Stopped")
		case .userWornStop				: return ("User Worn Stopped")
		case .userUserStop				: return ("User User Stopped")
		case .userMotionStop			: return ("User Motion Stopped")
		case .userMedtorMotion			: return ("User Medtor Too Much Motion")
		case .unknown					: return ("Unknown")
		}
	}
	
	public init(from decoder: Decoder) throws {
		let container = try decoder.singleValueContainer()
		let code = try? container.decode(String.self)
		switch code {
		case "User Continuous"				: self = .userContinuous
		case "User Complete"				: self = .userComplete
		case "Background Complete"			: self = .backgroundComplete
		case "Background Medtor"			: self = .backgroundMedtor
		case "Background Worn Stopped"		: self = .backgroundWornStop
		case "Background User Stopped"		: self = .backgroundUserStop
		case "Background Motion Stopped"	: self = .backgroundMotionStop
		case "User Worn Stopped"			: self = .userWornStop
		case "User User Stopped"			: self = .userUserStop
		case "User Motion Stopped"			: self = .userMotionStop
		case "User Medtor Too Much Motion"	: self = .userMedtorMotion
		default								: self = .unknown
		}
	}
}
