//
//  IntExtentions.swift
//  biostrapDeviceSDK
//
//  Created by Joseph A. Bennett on 1/6/22.
//

import Foundation

extension Int {
		
	var leData16: Data {
		var data = Data()
		data.append(UInt8((self >> 0) & 0xff))
		data.append(UInt8((self >> 8) & 0xff))
		
		return (data)
	}
	
	var leData32: Data {
		var data = Data()
		data.append(UInt8((self >>  0) & 0xff))
		data.append(UInt8((self >>  8) & 0xff))
		data.append(UInt8((self >> 16) & 0xff))
		data.append(UInt8((self >> 24) & 0xff))
		
		return (data)
	}
	
	var leData64: Data {
		var data = Data()
		data.append(UInt8((self >>  0) & 0xff))
		data.append(UInt8((self >>  8) & 0xff))
		data.append(UInt8((self >> 16) & 0xff))
		data.append(UInt8((self >> 24) & 0xff))
		data.append(UInt8((self >> 32) & 0xff))
		data.append(UInt8((self >> 40) & 0xff))
		data.append(UInt8((self >> 48) & 0xff))
		data.append(UInt8((self >> 56) & 0xff))
		
		return (data)
	}

	var beData16: Data {
		let byte0 = (self & 0x000000ff)
		let byte1 = (self & 0x0000ff00) >> 8
		
		var output	= Data()
		output.append(UInt8(byte1))
		output.append(UInt8(byte0))
		
		return (output)
	}

	var beData32: Data {
		let byte0 = (self & 0x000000ff)
		let byte1 = (self & 0x0000ff00) >> 8
		let byte2 = (self & 0x00ff0000) >> 16
		let byte3 = (Int64(self) & 0xff000000) >> 24
		
		var output	= Data()
		output.append(UInt8(byte3))
		output.append(UInt8(byte2))
		output.append(UInt8(byte1))
		output.append(UInt8(byte0))
		
		return (output)
	}

}
