//
//  livotalManufacturingTestResult.swift
//  biostrapDeviceSDK
//
//  Created by Joseph A. Bennett on 4/21/22.
//

import Foundation


class livotalManufacturingTestResult: Codable {
	
	//--------------------------------------------------------------------------------
	//
	// Used for JSON encode/decode
	//
	//--------------------------------------------------------------------------------
	enum CodingKeys: String, CodingKey {
		case pmic
		case flash_if
		case flash_array
		case ppg_if
		case ppg_fifo
		case imu_if
		case imu_fifo
		case temp
	}

	//--------------------------------------------------------------------------------
	//
	// Value of test result
	//
	//--------------------------------------------------------------------------------
	enum testType: UInt8, Codable {
		case TEST_NOT_RUN	= 0
		case TEST_FAIL		= 1
		case TEST_UNKNOWN	= 2
		case TEST_PASS		= 3
		
		var title: String {
			switch (self) {
			case .TEST_NOT_RUN	: return "Not Run"
			case .TEST_FAIL		: return "Failed"
			case .TEST_UNKNOWN	: return "Unknown (2)"
			case .TEST_PASS		: return "Passed"
			}
		}
	}

	var pmic		: testType
	var flash_if	: testType
	var flash_array	: testType
	var ppg_if		: testType
	var ppg_fifo	: testType
	var imu_if		: testType
	var imu_fifo	: testType
	var temp		: testType
	
	init() {
		pmic		= .TEST_NOT_RUN
		flash_if	= .TEST_NOT_RUN
		flash_array	= .TEST_NOT_RUN
		ppg_if		= .TEST_NOT_RUN
		ppg_fifo	= .TEST_NOT_RUN
		imu_if		= .TEST_NOT_RUN
		imu_fifo	= .TEST_NOT_RUN
		temp		= .TEST_NOT_RUN
	}
	
	init(_ data: Data) {
		let pmic_data			= (data[0] >> 0) & 0x03
		let flash_if_data		= (data[0] >> 2) & 0x03
		let flash_array_data	= (data[0] >> 4) & 0x03
		let ppg_if_data			= (data[0] >> 6) & 0x03
		let ppg_fifo_data		= (data[1] >> 0) & 0x03
		let imu_if_data			= (data[1] >> 2) & 0x03
		let imu_fifo_data		= (data[1] >> 4) & 0x03
		let temp_data			= (data[1] >> 6) & 0x03
		
		pmic		= testType(rawValue: pmic_data)!
		flash_if	= testType(rawValue: flash_if_data)!
		flash_array	= testType(rawValue: flash_array_data)!
		ppg_if		= testType(rawValue: ppg_if_data)!
		ppg_fifo	= testType(rawValue: ppg_fifo_data)!
		imu_if		= testType(rawValue: imu_if_data)!
		imu_fifo	= testType(rawValue: imu_fifo_data)!
		temp		= testType(rawValue: temp_data)!
	}
	
	//--------------------------------------------------------------------------------
	//
	// Constructor from a JSON decoder.
	//
	//--------------------------------------------------------------------------------
	public required init(from decoder: Decoder) throws {
		let values = try decoder.container(keyedBy: CodingKeys.self)
		
		pmic		= try values.decode(testType.self, forKey: .pmic)
		flash_if	= try values.decode(testType.self, forKey: .flash_if)
		flash_array	= try values.decode(testType.self, forKey: .flash_array)
		ppg_if		= try values.decode(testType.self, forKey: .ppg_if)
		ppg_fifo	= try values.decode(testType.self, forKey: .ppg_fifo)
		imu_if		= try values.decode(testType.self, forKey: .imu_if)
		imu_fifo	= try values.decode(testType.self, forKey: .imu_fifo)
		temp		= try values.decode(testType.self, forKey: .temp)
	}

	//--------------------------------------------------------------------------------
	// Method Name: encode
	//--------------------------------------------------------------------------------
	//
	// When the JSON encoder is called, states how to create a JSON dictionary based
	// upon the packet type
	//
	//--------------------------------------------------------------------------------
	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		
		try container.encode(pmic.title, forKey: .pmic)
		try container.encode(flash_if.title, forKey: .flash_if)
		try container.encode(flash_array.title, forKey: .flash_array)
		try container.encode(ppg_if.title, forKey: .ppg_if)
		try container.encode(ppg_fifo.title, forKey: .ppg_fifo)
		try container.encode(imu_if.title, forKey: .imu_if)
		try container.encode(imu_fifo.title, forKey: .imu_fifo)
		try container.encode(temp.title, forKey: .temp)
	}
}

