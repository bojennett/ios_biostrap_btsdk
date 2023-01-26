//
//  manufacturingTestType.swift
//  biostrapDeviceSDK
//
//  Created by Joseph A. Bennett on 10/3/22.
//

import Foundation

#if LIVOTAL || UNIVERSAL
@objc public enum livotalManufacturingTestType: Int, RawRepresentable, Codable, CaseIterable {
	case pmic
	case temp
	case flash_if
	case flash_array
	case ppg_if
	case ppg_fifo
	case imu_if
	case imu_fifo
	case led
	
	public typealias RawValue = String

	public var rawValue: RawValue {
		switch (self) {
		case .pmic			: return "pmic"
		case .temp			: return "temp"
		case .flash_if		: return "flash_if"
		case .flash_array	: return "flash_array"
		case .ppg_if		: return "ppg_if"
		case .ppg_fifo		: return "ppg_fifo"
		case .imu_if		: return "imu_if"
		case .imu_fifo		: return "imu_fifo"
		case .led			: return "led"
		}
	}

	public init?(rawValue: RawValue) {
		switch (rawValue) {
		case "pmic"			: self = .pmic
		case "temp"			: self = .temp
		case "flash_if"		: self = .flash_if
		case "flash_array"	: self = .flash_array
		case "ppg_if"		: self = .ppg_if
		case "ppg_fifo"		: self = .ppg_fifo
		case "imu_if"		: self = .imu_if
		case "imu_fifo"		: self = .imu_fifo
		case "led"			: self = .led
		default				: return nil
		}
	}

	public var title: String {
		switch (self) {
		case .pmic			: return "PMIC"
		case .temp			: return "Temp Sensor Interface"
		case .flash_if		: return "Flash Interface"
		case .flash_array	: return "Flash Array"
		case .ppg_if		: return "PPG Interface"
		case .ppg_fifo		: return "PPG FIFO"
		case .imu_if		: return "IMU Interface"
		case .imu_fifo		: return "IMU FIFO"
		case .led			: return "User LEDs"
		}
	}
}
#endif

#if UNIVERSAL || ALTER
@objc public enum alterManufacturingTestType: UInt8, Codable, CaseIterable {
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

#if UNIVERSAL || KAIROS
@objc public enum kairosManufacturingTestType: UInt8, Codable, CaseIterable {
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

#if UNIVERSAL || ETHOS
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
