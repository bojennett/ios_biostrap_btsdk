//
//  buttonCommandType.swift
//  biostrapDeviceSDK
//
//  Created by Joseph A. Bennett on 6/8/23.
//

import Foundation

@objc public enum buttonCommandType: UInt8, Codable, CaseIterable {
	case none								= 0x00
	case showBattery						= 0x01
	case advertiseShowConnection			= 0x02
	case hrmAdvertiseToggleActivity			= 0x03
	case shutDown							= 0x04
	case unknown							= 0xff
	
	public var title: String {
		switch (self) {
		case .none							: return ("None")
		case .showBattery					: return ("Show Battery Percentage")
		case .advertiseShowConnection		: return ("Force Advertise and Show Connection Status")
		case .hrmAdvertiseToggleActivity	: return ("Toggle Activity and HRM Advertise Mode")
		case .shutDown						: return ("Shutdown")
		case .unknown						: return ("Unknown")
		}
	}
	
	public init(from decoder: Decoder) throws {
		let container = try decoder.singleValueContainer()
		let code = try? container.decode(String.self)
		
		switch code {
		case "None"											: self = .none
		case "Show Battery Percentage"						: self = .showBattery
		case "Force Advertise and Show Connection Status"	: self = .advertiseShowConnection
		case "Toggle Activity and HRM Advertise Mode"		: self = .hrmAdvertiseToggleActivity
		case "Shutdown"										: self = .shutDown
		default												: self = .unknown
		}
	}
}
