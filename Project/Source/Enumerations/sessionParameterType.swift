//
//  sessionParameterType.swift
//  biostrapDeviceSDK
//
//  Created by Joseph Bennett on 4/3/24.
//

import Foundation

@objc public enum sessionParameterType: UInt8, Codable {
	case ppgCapturePeriod		= 0x00
	case ppgCaptureDuration		= 0x01
	case tag					= 0x10
	case reset					= 0xfd
	case accept					= 0xfe
	case unknown				= 0xff
	
	public var title: String {
		switch (self) {
		case .ppgCapturePeriod		: return "PPG Capture Period"
		case .ppgCaptureDuration	: return "PPG Capture Duration"
		case .tag					: return "Tag"
		case .reset					: return "Reset"
		case .accept				: return "Accept"
		case .unknown				: return "Unknown"
		}
	}
}
