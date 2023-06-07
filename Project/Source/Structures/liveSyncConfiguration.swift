//
//  liveSync.swift
//  biostrapDeviceSDK
//
//  Created by Joseph A. Bennett on 6/17/22.
//

import Foundation

#if UNIVERSAL || ETHOS
//--------------------------------------------------------------------------------
//
//
//
//--------------------------------------------------------------------------------
@objc public class liveSyncConfiguration: NSObject {
	public var green		: Bool
	public var red			: Bool
	public var ir			: Bool
	public var white_irr	: Bool
	public var white_white	: Bool
	public var imu			: Bool
	public var all			: Bool
	
	override public init() {
		green		= false
		red			= false
		ir			= false
		white_irr	= false
		white_white	= false
		imu			= false
		all			= false
	}
	
	var commandByte: UInt8 {
		var result: UInt8	= 0x00
		
		if (green)			{ result = result | 0x01 }
		if (red)			{ result = result | 0x02 }
		if (ir)				{ result = result | 0x04 }
		if (white_irr)		{ result = result | 0x08 }
		if (white_white)	{ result = result | 0x10 }
		if (imu)			{ result = result | 0x20 }
		if (all)			{ result = result | 0x80 }

		return result
	}
	
	@objc public var commandString: String {
		var result: String	= ""
		
		if (green)			{ if (result != "") { result = "\(result)," }; result = "\(result)Green" }
		if (red)			{ if (result != "") { result = "\(result)," }; result = "\(result)Red" }
		if (ir)				{ if (result != "") { result = "\(result)," }; result = "\(result)IR" }
		if (white_irr)		{ if (result != "") { result = "\(result)," }; result = "\(result)White (IRR)" }
		if (white_white)	{ if (result != "") { result = "\(result)," }; result = "\(result)White (White)" }
		if (imu)			{ if (result != "") { result = "\(result)," }; result = "\(result)IMU" }
		if (all)			{ if (result != "") { result = "\(result)," }; result = "\(result)All" }

		return result

	}
}
#endif
