//
//  CrcCalculator.swift
//  AmbiqOTATest
//
//  Created by Joseph Bennett on 9/20/21.
//

import Foundation

class CrcCalculator {
	static var table: [UInt32] = {
			(0...255).map { i -> UInt32 in
				(0..<8).reduce(UInt32(i), { c, _ in
					(c % 2 == 0) ? (c >> 1) : (0xEDB88320 ^ (c >> 1))
				})
			}
		}()

	static func checksum(bytes: [UInt8]) -> UInt32 {
		return ~(bytes.reduce(~UInt32(0), { crc, byte in
				(crc >> 8) ^ table[(Int(crc) ^ Int(byte)) & 0xFF]
		}))
	}

}
