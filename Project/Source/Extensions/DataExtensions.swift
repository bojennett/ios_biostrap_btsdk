//
//  DataExtensions.swift
//  biostrapDeviceSDK
//
//  Created by Joseph A. Bennett on 8/12/21.
//

import Foundation

extension Data {
	
	//--------------------------------------------------------------------------------
	//
	// String of the data
	//
	//--------------------------------------------------------------------------------
	var hexString: String {
		let bytes = (self.reduce(into: "") { $0 += String(format: "%.2X ", $1) })
		return ("[ \(bytes)]")
	}
	
	//--------------------------------------------------------------------------------
	//
	// Array of the data as UInt8
	//
	//--------------------------------------------------------------------------------
	var bytes: [UInt8] {
		return [UInt8](self)
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	var leFloat: Float {
		if (self.count != 4) { return Float(0.0) }
		
		return Float(bitPattern: UInt32(littleEndian: self.withUnsafeBytes { $0.load(as: UInt32.self) }))
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	var leInt64: Int {
		if (self.count != 8) { return 0 }
		
		let byte0	= UInt64(self[0]) <<  0
		let byte1	= UInt64(self[1]) <<  8
		let byte2	= UInt64(self[2]) << 16
		let byte3	= UInt64(self[3]) << 24
		let byte4	= UInt64(self[4]) << 32
		let byte5	= UInt64(self[5]) << 40
		let byte6	= UInt64(self[6]) << 48
		let byte7	= UInt64(self[7]) << 56

		return (Int(byte7 | byte6 | byte5 | byte4 | byte3 | byte2 | byte1 | byte0))
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	var leInt32: Int {
		if (self.count != 4) { return 0 }
		
		let byte0	= UInt32(self[0])
		let byte1	= UInt32(self[1])
		let byte2	= UInt32(self[2])
		let byte3	= UInt32(self[3])
		
		return (Int((byte3 << 24) | (byte2 << 16) | (byte1 << 8) | (byte0)))
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	// Little Endian UInt16
	//
	//--------------------------------------------------------------------------------
	var leUInt16: Int {
		if (self.count != 2) { return (0) }

		let byte0	= UInt16(self[0])
		let byte1	= UInt16(self[1])
		
		return (Int((byte1 << 8) | (byte0)))
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	// Little Endian Int16
	//
	//--------------------------------------------------------------------------------
	var leInt16: Int {
		if (self.count != 2) { return (0) }

		let byte0	= Int16(self[0])
		let byte1	= Int16(self[1])
		
		return (Int((byte1 << 8) | (byte0)))
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	// Converts a 16-bit IEEE754 float format to the normal 32-bit IEEE754 float
	// format we all know and love
	//
	//--------------------------------------------------------------------------------
	var leFloat16: Float {
		if (self.count != 2) { return Float(0) }
		return Float(Float16(bitPattern: UInt16(self.leUInt16)))
	}

}
