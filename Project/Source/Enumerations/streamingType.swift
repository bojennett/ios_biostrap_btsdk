//
//  streamingType.swift
//  biostrapDeviceSDK
//
//  Created by Joseph A. Bennett on 5/30/23.
//

import Foundation

@objc public enum streamingType: UInt8, Codable {
	case hr				= 0x00
	case hrv			= 0x01
	case rr				= 0x02
	case bbi			= 0x03
	case ppgSNR			= 0x04
	case ppgWave		= 0x05
	case motionState	= 0x06
	case unknown		= 0xff

	public init(from decoder: Decoder) throws {
		let container = try decoder.singleValueContainer()
		let code = try? container.decode(String.self)
		switch code {
		case "Unknown"						: self	= .unknown
		case "Heart Rate"					: self	= .hr
		case "Heart Rate Variability"		: self	= .hrv
		case "Respiratory Rate"				: self	= .rr
		case "Beat-to-beat Interval"		: self	= .bbi
		case "PPG Signal-to-Noise Ratio"	: self	= .ppgSNR
		case "PPG Wave"						: self	= .ppgWave
		case "Motion State"					: self	= .motionState
		default								: self	= .unknown
		}
	}
	
	public var title: String {
		switch (self) {
		case .hr							: return "Heart Rate"
		case .hrv							: return "Heart Rate Variability"
		case .rr							: return "Respiratory Rate"
		case .bbi							: return "Beat-to-beat Interval"
		case .ppgSNR						: return "PPG Signal-to-Noise Ratio"
		case .ppgWave						: return "PPG Wave"
		case .motionState					: return "Motion State"
		case .unknown						: return "Unknown"
		}
	}
}
