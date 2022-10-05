//
//  manufacturingTestType.swift
//  biostrapDeviceSDK
//
//  Created by Joseph A. Bennett on 10/3/22.
//

import Foundation

#if ALTER || ETHOS
@objc public enum manufacturingTestType: UInt8, Codable, CaseIterable {
	case temp			= 0x00
	case flashIF		= 0x01
	case flashArray		= 0x02
	case spectralIF		= 0x03
	case spectralFIFO	= 0x04
	case imuIF			= 0x05
	case imuFIFO		= 0x06
	case led			= 0x07
	case motor		 	= 0x08
	case button			= 0x09
	case unknown		= 0xff
		
	public var title: String {
		switch (self) {
		case .temp					: return ("Temperature")
		case .flashIF				: return ("Flash Interface")
		case .flashArray			: return ("Flash Array")
		case .spectralIF			: return ("Spectral Interface")
		case .spectralFIFO			: return ("Spectral FIFO")
		case .imuIF					: return ("IMU Interface")
		case .imuFIFO				: return ("IMU FIFO")
		case .led					: return ("LED")
		case .motor					: return ("Motor")
		case .button				: return ("Button")
		case .unknown				: return ("Unknown")
		}
	}
	
	public init(from decoder: Decoder) throws {
		let container = try decoder.singleValueContainer()
		let code = try? container.decode(String.self)
		switch code {
		case "Temperature"			: self = .temp
		case "Flash Interface"		: self = .flashIF
		case "Flash Array"			: self = .flashArray
		case "Spectral Interface"	: self = .spectralIF
		case "Spectral FIFO"		: self = .spectralFIFO
		case "IMU Interface"		: self = .imuIF
		case "IMU FIFO"				: self = .imuFIFO
		case "LED"					: self = .led
		case "Motor"				: self = .motor
		case "Button"				: self = .button
		default						: self = .unknown
		}
	}
}
#endif

#if UNIVERSAL
@objc public enum ethosManufacturingTestType: UInt8, Codable, CaseIterable {
	case temp			= 0x00
	case flashIF		= 0x01
	case flashArray		= 0x02
	case spectralIF		= 0x03
	case spectralFIFO	= 0x04
	case imuIF			= 0x05
	case imuFIFO		= 0x06
	case led			= 0x07
	case motor		 	= 0x08
	case button			= 0x09
	case unknown		= 0xff
		
	public var title: String {
		switch (self) {
		case .temp					: return ("Temperature")
		case .flashIF				: return ("Flash Interface")
		case .flashArray			: return ("Flash Array")
		case .spectralIF			: return ("Spectral Interface")
		case .spectralFIFO			: return ("Spectral FIFO")
		case .imuIF					: return ("IMU Interface")
		case .imuFIFO				: return ("IMU FIFO")
		case .led					: return ("LED")
		case .motor					: return ("Motor")
		case .button				: return ("Button")
		case .unknown				: return ("Unknown")
		}
	}
	
	public init(from decoder: Decoder) throws {
		let container = try decoder.singleValueContainer()
		let code = try? container.decode(String.self)
		switch code {
		case "Temperature"			: self = .temp
		case "Flash Interface"		: self = .flashIF
		case "Flash Array"			: self = .flashArray
		case "Spectral Interface"	: self = .spectralIF
		case "Spectral FIFO"		: self = .spectralFIFO
		case "IMU Interface"		: self = .imuIF
		case "IMU FIFO"				: self = .imuFIFO
		case "LED"					: self = .led
		case "Motor"				: self = .motor
		case "Button"				: self = .button
		default						: self = .unknown
		}
	}
}
#endif
