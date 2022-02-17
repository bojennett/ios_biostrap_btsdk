//
//  ethosBTSDK.swift
//  biostrapDeviceSDK
//
//  Created by Joseph A. Bennett on 2/16/22.
//

import Foundation

@objc public class ethosBTSDK: biostrapDeviceSDK {
	
	#if UNIVERSAL || ETHOS
	@objc public override init() {
		super.init()
		
		gblLimitEthos = true
	}
	#endif
}
