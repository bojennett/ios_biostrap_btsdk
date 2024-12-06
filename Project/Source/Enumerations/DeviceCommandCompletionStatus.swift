//
//  DeviceCommandCompletionStatus.swift
//  biostrapDeviceSDK
//
//  Created by Joseph Bennett on 3/5/24.
//

import Foundation

public enum DeviceCommandCompletionStatus: CaseIterable {
	case successful
	case not_configured
	case device_error
	
	public var title: String {
		switch self {
		case .successful: return ""
		case .not_configured: return "Not configured"
		case .device_error: return "Device returned error"
		}
	}
	
	public var successful: Bool {
		return self == .successful
	}
}
