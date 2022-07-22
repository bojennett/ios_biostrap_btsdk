//
//  settingsType.swift
//  biostrapDeviceSDK
//
//  Created by Joseph A. Bennett on 7/21/22.
//

import Foundation

@objc public enum settingsType: UInt8, Codable {
	case accelHalfRange			= 0x00
	case gyroHalfRange			= 0x01
	case imuSamplingRate		= 0x02
	case ppgCapturePeriod		= 0x03
	case ppgCaptureDuration		= 0x04
	case ppgSamplingRate		= 0x05
	case unknown				= 0xff
	
	public init(from decoder: Decoder) throws {
		let container = try decoder.singleValueContainer()
		let code = try? container.decode(String.self)
		switch code {
		case "accel_halfrange"		: self	= .accelHalfRange
		case "gyro_halfrange"		: self	= .gyroHalfRange
		case "imu_sampling_rate"	: self	= .imuSamplingRate
		case "ppg_capture_period"	: self	= .ppgCapturePeriod
		case "ppg_capture_duration"	: self	= .ppgCaptureDuration
		case "ppg_sampling_rate"	: self	= .ppgSamplingRate
		default						: self	= .unknown
		}
	}
	
	public var title: String {
		switch (self) {
		case .accelHalfRange		: return "accel_halfrange"
		case .gyroHalfRange			: return "gyro_halfrange"
		case .imuSamplingRate		: return "imu_sampling_rate"
		case .ppgCapturePeriod		: return "ppg_capture_period"
		case .ppgCaptureDuration	: return "ppg_capture_duration"
		case .ppgSamplingRate		: return "ppg_sampling_rate"
		case .unknown				: return "unknown"
		}
	}
}
