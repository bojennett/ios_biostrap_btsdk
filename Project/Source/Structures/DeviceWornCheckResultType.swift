//
//  DeviceWornCheckResultType.swift
//  biostrapDeviceSDK
//
//  Created by Joseph Bennett on 3/5/24.
//

import Foundation
import Combine

public class DeviceWornCheckResultType: ObservableObject {
	@Published public var code: String = ""
	@Published public var value: Int = 0
	
	public init() {
		self.code = ""
		self.value = 0
	}
	
	public init(code: String, value: Int) {
		self.code = code
		self.value = value
	}
}

