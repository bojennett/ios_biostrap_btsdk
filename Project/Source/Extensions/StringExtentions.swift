//
//  StringExtentions.swift
//  biostrapDeviceSDK
//
//  Created by Joseph A. Bennett on 6/19/23.
//

import Foundation

extension String {
	
	private struct pieces {
		var	valid	= false
		var	major	= -1
		var minor	= -1
		var build	= -1
		
		init(_ valid: Bool, _ major: Int, _ minor: Int, _ build: Int) {
			self.valid	= valid
			self.major	= major
			self.minor	= minor
			self.build	= build
		}
	}
	
	private func mGetPieces(_ separator: Character) -> pieces {
		let values		= self.split(separator: separator)
		
		if (values.count == 3) {
			if let major = Int(values[0]), let minor = Int(values[1]), let build = Int(values[2]) {
				return pieces(true, major, minor, build)
			}
		}

		return pieces(false, -1, -1, -1)
	}
	
	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	public func versionGreaterThan(_ compare: String, separator: Character) -> Bool {
		let myValues		= self.mGetPieces(separator)
		let compareValues	= compare.mGetPieces(separator)
		
		if ((myValues.valid) && (compareValues.valid)) {
			if (myValues.major > compareValues.major) { return (true) }
			if (myValues.major < compareValues.major) { return (false) }
			
			if (myValues.minor > compareValues.minor) { return (true) }
			if (myValues.minor < compareValues.minor) { return (false) }
			
			if (myValues.build > compareValues.build) { return (true) }
			if (myValues.build < compareValues.build) { return (false) }
		}
		
		return (false)
	}
	
	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	public func versionLessThan(_ compare: String, separator: Character) -> Bool {
		let myValues		= self.mGetPieces(separator)
		let compareValues	= compare.mGetPieces(separator)
		
		if ((myValues.valid) && (compareValues.valid)) {
			if (myValues.major < compareValues.major) { return (true) }
			if (myValues.major > compareValues.major) { return (false) }
			
			if (myValues.minor < compareValues.minor) { return (true) }
			if (myValues.minor > compareValues.minor) { return (false) }
			
			if (myValues.build < compareValues.build) { return (true) }
			if (myValues.build > compareValues.build) { return (false) }
		}
		
		return (false)
	}
	
	
	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	public func versionEqualTo(_ compare: String, separator: Character) -> Bool {
		let myValues		= self.mGetPieces(separator)
		let compareValues	= compare.mGetPieces(separator)
		
		if ((myValues.valid) && (compareValues.valid)) {
			if (myValues.major != compareValues.major) { return (false) }
			if (myValues.minor != compareValues.minor) { return (false) }
			if (myValues.build != compareValues.build) { return (false) }
			
			return (true)
		}
		
		return (false)
	}

}
