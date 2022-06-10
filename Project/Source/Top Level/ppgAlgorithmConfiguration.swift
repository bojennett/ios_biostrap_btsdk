//
//  livotalAlgorithmConfiguration.swift
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
	#if ETHOS || UNIVERSAL
	public var white_spo2	: Bool
	#endif
	
	override public init() {
		hr			= false
		hrv			= false
		rr			= false
		spo2		= false
		#if ETHOS || UNIVERSAL
		white_spo2	= false
		#endif
	}
	
	var commandByte: UInt8 {
		var result: UInt8	= 0x00
		
		if (hr)			{ result = result | 0x01 }
		if (hrv)		{ result = result | 0x02 }
		if (rr)			{ result = result | 0x04 }
		if (spo2)		{ result = result | 0x08 }
		#if ETHOS || UNIVERSAL
		if (white_spo2)	{ result = result | 0x10 }
		#endif

		return result
	}
	
	@objc public var commandString: String {
		var result: String	= ""
		
		if (hr)			{ if (result != "") { result = "\(result)," }; result = "\(result)HR" }
		if (hrv)		{ if (result != "") { result = "\(result)," }; result = "\(result)HRV" }
		if (rr)			{ if (result != "") { result = "\(result)," }; result = "\(result)RR" }
		if (spo2)		{ if (result != "") { result = "\(result)," }; result = "\(result)SPO2" }
		#if ETHOS || UNIVERSAL
		if (white_spo2)	{ if (result != "") { result = "\(result)," }; result = "\(result)WHITE_SPO2" }
		#endif

		return result

	}
}

