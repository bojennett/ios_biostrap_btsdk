//
//  UInt8Extensions.swift
//  biostrapDeviceSDK
//
//  Created by Joseph A. Bennett on 8/3/23.
//

import Foundation

extension UInt8 {
	
	var Int8: Int {
		let asInt = Int(self)
		var result = Int(self) & 0x7F
		
		if (asInt == 128) { result = -128 }
		if (asInt > 128) { result = -128 + result }
		
		return (result)
	}
}
