//
//  ethosManufacturingTestResult.swift
//  biostrapDeviceSDK
//
//  Created by Joseph A. Bennett on 7/19/22.
//

import Foundation

class ethosManufacturingTestResult: Codable {
	
	//--------------------------------------------------------------------------------
	//
	// Used for JSON encode/decode
	//
	//--------------------------------------------------------------------------------
	enum CodingKeys: String, CodingKey {
		case test
		case result
	}

	#if ALTER || ETHOS
	var test		: manufacturingTestType
	#endif
	
	#if UNIVERSAL
	var test		: ethosManufacturingTestType
	#endif
	
	var result		: String
	
	init() {
		test		= .unknown
		result		= "Failed"
	}
	
	init(_ data: Data) {
		#if ALTER || ETHOS
		if let test_data = manufacturingTestType(rawValue: data[0]) {
			test	= test_data
		}
		else {
			test	= .unknown
		}
		#endif

		#if UNIVERSAL
		if let test_data = ethosManufacturingTestType(rawValue: data[0]) {
			test	= test_data
		}
		else {
			test	= .unknown
		}
		#endif

		if (data[1] == 0x01) {
			result	= "Passed"
		}
		else {
			result	= "Failed"
		}
	}
	
	//--------------------------------------------------------------------------------
	//
	// Constructor from a JSON decoder.
	//
	//--------------------------------------------------------------------------------
	public required init(from decoder: Decoder) throws {
		let values = try decoder.container(keyedBy: CodingKeys.self)
		
		#if ALTER || ETHOS
		test		= try values.decode(manufacturingTestType.self, forKey: .test)
		#endif

		#if UNIVERSAL
		test		= try values.decode(ethosManufacturingTestType.self, forKey: .test)
		#endif

		result		= try values.decode(String.self, forKey: .result)
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
		
		try container.encode(test.title, forKey: .test)
		try container.encode(result, forKey: .result)
	}
}

