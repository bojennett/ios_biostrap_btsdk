//
//  manufacturingTestType.swift
//  biostrapDeviceSDK
//
//  Created by Joseph A. Bennett on 10/3/22.
//

import Foundation

#if UNIVERSAL || ALTER
@objc public enum alterManufacturingTestType: UInt8, Codable, CaseIterable {
	case flashIF				= 0x01
	case flashArray				= 0x02
	case spectralIF				= 0x03
	case spectralFIFO			= 0x04
	case imuIF					= 0x05
	case imuFIFO				= 0x06
	case led					= 0x07
    case motor = 0x08
	case ppgUserTriggerButton	= 0x09
	case spectralLEDS			= 0x0A
	case imuSelfTest			= 0x0B
	case spectralLEDLeakage		= 0x0C
	case imuNoiseFloor			= 0x0D
    case temp = 0x0E
    case pmic = 0x0F
	case unknown				= 0xff
    
    public var isGen2: Bool {
        switch self {
        case .motor, .temp, .pmic: return true
        default: return false
        }
    }
		
	public var title: String {
		switch (self) {
		case .flashIF				: return ("Flash Interface")
		case .flashArray			: return ("Flash Array")
		case .spectralIF			: return ("Spectral Interface")
		case .spectralFIFO			: return ("Spectral FIFO")
		case .imuIF					: return ("IMU Interface")
		case .imuFIFO				: return ("IMU FIFO")
		case .led					: return ("LED")
        case .motor: return ("Motor")
		case .ppgUserTriggerButton	: return ("Button")
		case .spectralLEDS			: return ("Spectral LEDs")
		case .imuSelfTest			: return ("IMU Self Test")
		case .spectralLEDLeakage	: return ("Spectral LED Leakage")
		case .imuNoiseFloor			: return ("IMU Noise Floor")
        case .temp: return ("Temperature")
        case .pmic: return ("PMIC")
		case .unknown				: return ("Unknown")
		}
	}
	
	public init(from decoder: Decoder) throws {
		let container = try decoder.singleValueContainer()
		let code = try? container.decode(String.self)
		switch code {
		case "Flash Interface"		: self = .flashIF
		case "Flash Array"			: self = .flashArray
		case "Spectral Interface"	: self = .spectralIF
		case "Spectral FIFO"		: self = .spectralFIFO
		case "IMU Interface"		: self = .imuIF
		case "IMU FIFO"				: self = .imuFIFO
		case "LED"					: self = .led
        case "Motor": self = .motor
		case "Button"				: self = .ppgUserTriggerButton
		case "Spectral LEDs"		: self = .spectralLEDS
		case "IMU Self Test"		: self = .imuSelfTest
		case "Spectral LED Leakage"	: self = .spectralLEDLeakage
		case "IMU Noise Floor"		: self = .imuNoiseFloor
        case "Temperature": self = .temp
        case "PMIC": self = .pmic
		default						: self = .unknown
		}
	}
}
#endif

#if UNIVERSAL || KAIROS
@objc public enum kairosManufacturingTestType: UInt8, Codable, CaseIterable {
	case flashIF				= 0x01
	case flashArray				= 0x02
	case spectralIF				= 0x03
	case spectralFIFO			= 0x04
	case imuIF					= 0x05
	case imuFIFO				= 0x06
	case led					= 0x07
	case ppgUserTriggerButton	= 0x09
	case spectralLEDS			= 0x0A
	case imuSelfTest			= 0x0B
	case spectralLEDLeakage		= 0x0C
	case imuNoiseFloor			= 0x0D
	case unknown				= 0xff
	
	public var title: String {
		switch (self) {
		case .flashIF				: return ("Flash Interface")
		case .flashArray			: return ("Flash Array")
		case .spectralIF			: return ("Spectral Interface")
		case .spectralFIFO			: return ("Spectral FIFO")
		case .imuIF					: return ("IMU Interface")
		case .imuFIFO				: return ("IMU FIFO")
		case .led					: return ("LED")
		case .ppgUserTriggerButton	: return ("Button")
		case .spectralLEDS			: return ("Spectral LEDs")
		case .imuSelfTest			: return ("IMU Self Test")
		case .spectralLEDLeakage	: return ("Spectral LED Leakage")
		case .imuNoiseFloor			: return ("IMU Noise Floor")
		case .unknown				: return ("Unknown")
		}
	}
	
	public init(from decoder: Decoder) throws {
		let container = try decoder.singleValueContainer()
		let code = try? container.decode(String.self)
		switch code {
		case "Flash Interface"		: self = .flashIF
		case "Flash Array"			: self = .flashArray
		case "Spectral Interface"	: self = .spectralIF
		case "Spectral FIFO"		: self = .spectralFIFO
		case "IMU Interface"		: self = .imuIF
		case "IMU FIFO"				: self = .imuFIFO
		case "LED"					: self = .led
		case "Button"				: self = .ppgUserTriggerButton
		case "Spectral LEDs"		: self = .spectralLEDS
		case "IMU Self Test"		: self = .imuSelfTest
		case "Spectral LED Leakage"	: self = .spectralLEDLeakage
		case "IMU Noise Floor"		: self = .imuNoiseFloor
		default						: self = .unknown
		}
	}
}
#endif

