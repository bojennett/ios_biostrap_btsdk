//
//  kairosManufacturingTestResult.swift
//  alterBTSDK
//
//  Created by Joseph A. Bennett on 1/25/23.
//

import Foundation

#if UNIVERSAL || KAIROS
class kairosManufacturingTestResult: Codable {
	
	//--------------------------------------------------------------------------------
	//
	// Used for JSON encode/decode
	//
	//--------------------------------------------------------------------------------
	enum CodingKeys: String, CodingKey {
		case test
		case result
	}
	
	var test		: kairosManufacturingTestType
	
	var result		: String
	
	init() {
		test		= .unknown
		result		= "Failed"
	}
	
	init(_ data: Data) {
		if let test_data = kairosManufacturingTestType(rawValue: data[0]) {
			test	= test_data
		}
		else {
			test	= .unknown
		}
		
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
		
		test		= try values.decode(kairosManufacturingTestType.self, forKey: .test)
		
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
#endif
