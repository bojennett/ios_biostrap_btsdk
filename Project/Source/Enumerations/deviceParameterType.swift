//
//  deviceParameterType.swift
//  biostrapDeviceSDK
//
//  Created by Joseph Bennett on 4/3/24.
//

import Foundation

@objc public enum deviceParameterType: UInt8, Codable {
	case serialNumber			= 0x01
	case chargeCycle			= 0x02
	case advertisingInterval	= 0x03
	case canLogDiagnostics		= 0x04
	case paired					= 0x07
	case pageThreshold			= 0x08
	
	public var title: String {
		switch (self) {
		case .serialNumber			: return "serialNumber"
		case .chargeCycle			: return "chargeCycle"
		case .advertisingInterval	: return "advertisingInterval"
		case .canLogDiagnostics		: return "canLogDiagnostics"
		case .paired				: return "paired"
		case .pageThreshold			: return "pageThreshold"
		}
	}
}
