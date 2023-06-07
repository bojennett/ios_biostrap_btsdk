//
//  eventType.swift
//  biostrapDeviceSDK
//
//  Created by Joseph A. Bennett on 6/1/23.
//

import Foundation

@objc public enum eventType: UInt8, Codable {
	case ppgUserTriggerButton						= 0x00
	case ppgUserTriggerAutoActivity					= 0x01
	case ppgUserTriggerBLE							= 0x02
	case ppgUserTriggerUART							= 0x03
	case ppgUserTriggerButtonStop					= 0x04
	case ppgUserTriggerAutoActivityStop				= 0x05
	case ppgUserTriggerBLEStop						= 0x06
	case ppgUserTriggerUARTStop						= 0x07
	case ppgUserTriggerManufacturingTestStop		= 0x08
	case singlePress								= 0x09
	case doublePress								= 0x0a
	case triplePress								= 0x0b
	case longPress									= 0x0c
	case none										= 0x0d
	case ppgWornStop								= 0x0e
	case ppgTimerStop								= 0x0f
	case ppgFWStop									= 0x10
	case ppgFWStart									= 0x11
	case unknown									= 0xff
	
	public init(from decoder: Decoder) throws {
		let container = try decoder.singleValueContainer()
		let code = try? container.decode(String.self)
		switch code {
		case "Unknown"								: self	= .unknown
		case "PPG User Trigger Button"				: self	= .ppgUserTriggerButton
		case "PPG User Trigger Auto Activity"		: self	= .ppgUserTriggerAutoActivity
		case "PPG User Trigger BLE"					: self	= .ppgUserTriggerBLE
		case "PPG User Trigger UART"				: self	= .ppgUserTriggerUART
		case "PPG User Trigger Button Stop"			: self	= .ppgUserTriggerButtonStop
		case "PPG User Trigger Auto Activity Stop"	: self	= .ppgUserTriggerAutoActivityStop
		case "PPG User Trigger BLE Stop"			: self	= .ppgUserTriggerBLEStop
		case "PPG User Trigger UART Stop"			: self	= .ppgUserTriggerUARTStop
		case "Single Press"							: self	= .singlePress
		case "Double Press"							: self	= .doublePress
		case "Triple Press"							: self	= .triplePress
		case "Long Press"							: self	= .longPress
		case "None"									: self	= .none
		case "PPG Worn Stop"						: self	= .ppgWornStop
		case "PPG Timer Stop"						: self	= .ppgTimerStop
		case "PPG Firmware Stop"					: self	= .ppgFWStop
		case "PPG Firmware Start"					: self	= .ppgFWStart
		default										: self	= .unknown
		}
	}
	
	public var title: String {
		switch (self) {
		case .ppgUserTriggerButton					: return "PPG User Trigger Button"
		case .ppgUserTriggerAutoActivity			: return "PPG User Trigger Auto Activity"
		case .ppgUserTriggerBLE						: return "PPG User Trigger BLE"
		case .ppgUserTriggerUART					: return "PPG User Trigger UART"
		case .ppgUserTriggerButtonStop				: return "PPG User Trigger Button Stop"
		case .ppgUserTriggerAutoActivityStop		: return "PPG User Trigger Auto Activity Stop"
		case .ppgUserTriggerBLEStop					: return "PPG User Trigger BLE Stop"
		case .ppgUserTriggerUARTStop				: return "PPG User Trigger UART Stop"
		case .ppgUserTriggerManufacturingTestStop	: return "PPG User Trigger Manufacturing Test Stop"
		case .singlePress							: return "Single Press"
		case .doublePress							: return "Double Press"
		case .triplePress							: return "Triple Press"
		case .longPress								: return "Long Press"
		case .none									: return "None"
		case .ppgWornStop							: return "PPG Worn Stop"
		case .ppgTimerStop							: return "PPG Timer Stop"
		case .ppgFWStop								: return "PPG Firmware Stop"
		case .ppgFWStart							: return "PPG Firmware Start"
		case .unknown								: return "Unknown"
		}
	}
}
