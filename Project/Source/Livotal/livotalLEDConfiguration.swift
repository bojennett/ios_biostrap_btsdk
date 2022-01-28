//
//  livotalLEDConfiguration.swift
//  biostrapDeviceSDK
//
//  Created by Joseph A. Bennett on 8/26/21.
//

import Foundation

//--------------------------------------------------------------------------------
//
//
//
//--------------------------------------------------------------------------------
@objc public class livotalLEDConfiguration: NSObject {
	public var green	: Bool
	public var red		: Bool
	public var ir		: Bool
	//public var raw		: Bool
	
	override public init() {
		green	= false
		red		= false
		ir		= false
		//raw		= false
	}
	
	var commandByte: UInt8 {
		var result: UInt8	= 0x00
		
		if (green)	{ result = result | 0x01 }
		if (red)	{ result = result | 0x02 }
		if (ir)		{ result = result | 0x04 }
		//if (raw)	{ result = result | 0x80 }
		
		return result
	}
	
	@objc public var commandString: String {
		var result: String	= ""
		
		if (green)	{ if (result != "") { result = "\(result)," }; result = "\(result)Green" }
		if (red)	{ if (result != "") { result = "\(result)," }; result = "\(result)Red" }
		if (ir)		{ if (result != "") { result = "\(result)," }; result = "\(result)IR" }
		//if (raw)	{ if (result != "") { result = "\(result)," }; result = "\(result)Raw" }
		
		return result

	}
}

