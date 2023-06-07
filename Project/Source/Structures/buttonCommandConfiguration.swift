//
//  buttonCommandConfiguration.swift
//  biostrapDeviceSDK
//
//  Created by Joseph A. Bennett on 6/7/23.
//

import Foundation

//--------------------------------------------------------------------------------
//
//
//
//--------------------------------------------------------------------------------
@objc public class buttonCommandConfiguration: NSObject {
	public var advertise			: Bool
	public var connection			: Bool
	public var battery				: Bool
	public var toggleHRMAdvertising	: Bool
	public var startActivity		: Bool
	
	override public init() {
		advertise					= false
		connection					= false
		battery						= false
		toggleHRMAdvertising		= false
		startActivity				= false
	}

	convenience init(_ data: Data) {
		self.init()
		
		if (data.count == 4) {
			advertise				= ((data[3] & 0x01) != 0x00)
			connection				= ((data[3] & 0x02) != 0x00)
			battery					= ((data[3] & 0x04) != 0x00)
			toggleHRMAdvertising	= ((data[3] & 0x08) != 0x00)
			startActivity			= ((data[3] & 0x10) != 0x00)
		}
	}

	var data: Data {
		var lowByte		: UInt8 = 0x00
		
		if (advertise)				{ lowByte = lowByte | 0x01 }
		if (connection)				{ lowByte = lowByte | 0x02 }
		if (battery)				{ lowByte = lowByte | 0x04 }
		if (toggleHRMAdvertising)	{ lowByte = lowByte | 0x08 }
		if (startActivity)			{ lowByte = lowByte | 0x10 }
		
		var data		= Data()
		data.append(0x00)
		data.append(0x00)
		data.append(0x00)
		data.append(lowByte)
		
		return (data)
	}

	var settings: String {
		var intermediate	= ""
		
		if (advertise)				{ intermediate = "\(intermediate) Force Advertise," }
		if (connection)				{ intermediate = "\(intermediate) Connect/Disconnect Status," }
		if (battery)				{ intermediate = "\(intermediate) Show Battery Percentage," }
		if (toggleHRMAdvertising)	{ intermediate = "\(intermediate) Toggle HRM Advertising," }
		if (startActivity)			{ intermediate = "\(intermediate) Start Activity," }
		
		if (intermediate == "") {
			return ("None")
		}
		else {
			return (String(intermediate.dropLast(1)))
		}
	}
}
