//
//  ppgAlgorithmConfiguration.swift
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
@objc public class ppgAlgorithmConfiguration: NSObject {
	public var hr			: Bool
	public var hrv			: Bool
	public var rr			: Bool
	public var spo2			: Bool
	public var continuous	: Bool
	
	override public init() {
		hr			= false
		hrv			= false
		rr			= false
		spo2		= false
		continuous	= false
	}
	
	convenience init(_ data: UInt8) {
		self.init()
		
		hr			= ((data & 0x01) != 0x00)
		hrv			= ((data & 0x02) != 0x00)
		rr			= ((data & 0x04) != 0x00)
		spo2		= ((data & 0x08) != 0x00)
		continuous	= ((data & 0x80) != 0x00)
	}
	
	var commandByte: UInt8 {
		var result: UInt8	= 0x00
		
		if (hr)			{ result = result | 0x01 }
		if (hrv)		{ result = result | 0x02 }
		if (rr)			{ result = result | 0x04 }
		if (spo2)		{ result = result | 0x08 }
		if (continuous)	{ result = result | 0x80 }

		return result
	}
	
	@objc public var commandString: String {
		var result: String	= ""
		
		if (hr)			{ if (result != "") { result = "\(result), " }; result = "\(result)HR" }
		if (hrv)		{ if (result != "") { result = "\(result), " }; result = "\(result)HRV" }
		if (rr)			{ if (result != "") { result = "\(result), " }; result = "\(result)RR" }
		if (spo2)		{ if (result != "") { result = "\(result), " }; result = "\(result)SPO2" }
		if (continuous)	{ if (result != "") { result = "\(result), " }; result = "\(result)Continous" }
		
		if (result == "") { return ("Idle") }

		return result

	}
}

