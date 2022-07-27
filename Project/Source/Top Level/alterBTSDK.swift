//
//  alterBTSDK.swift
//  biostrapDeviceSDK
//
//  Created by Joseph A. Bennett on 7/26/22.
//

import Foundation

@objc public class alterBTSDK: biostrapDeviceSDK {
	
	@objc public override init() {
		super.init()
		
		gblLimitAlter = true
	}
	
}
