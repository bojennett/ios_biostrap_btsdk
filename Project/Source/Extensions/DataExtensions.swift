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
	var leInt: Int {
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
	var leUInt16: UInt16 {
		if (self.count != 2) { return UInt16(0) }

		let byte0	= UInt16(self[0])
		let byte1	= UInt16(self[1])
		
		return ((byte1 << 8) | (byte0))
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
		if (self.count != 2) { return Float(0.0) }
		
		let half = self.leUInt16

		let e = (UInt32(half) & 0x7C00) >> 10	// exponent
		let m = (UInt32(half) & 0x03FF) << 13	// mantissa
		let v = m >> 23							// evil log2 bit hack to count leading zeros in denormalized format
		
		let part1 = (UInt32(half) & 0x8000) << 16
		
		var part2: UInt32 = 0
		if (e != 0) { part2 = ((e + 112) << 23 | m) }
		
		var part3: UInt32 = 0
		if ((e == 0) && (m != 0)) {
			part3 = ((v - 37) << 23 | ((m << (150 - v)) & 0x007FE000))
		}
		
        return Float(bitPattern: (part1 | part2 | part3))
		
		/*
		return Float(
			(
				(half & 0x8000) << 16 |
				(e != 0) * ((e + 112) << 23 | m) |
				((e == 0) & (m != 0)) *
				((v - 37) << 23 | ((m << (150 - v)) & 0x007FE000))
			)
		)	// sign : normalized : denormalized
		*/
	}

}
