//
//  livotalBTSDK.swift
//  universalBTSDK
//
//  Created by Joseph A. Bennett on 1/28/22.
//

import Foundation

@objc public class livotalBTSDK: biostrapDeviceSDK {
	
	@objc public override init() {
		super.init()
		
		gblLimitLivotal = true
	}
}
