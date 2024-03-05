//
//  hrZoneRangeValueType.swift
//  biostrapDeviceSDK
//
//  Created by Joseph Bennett on 3/5/24.
//

import Foundation
import Combine

public class hrZoneRangeValueType: ObservableObject {
	@Published public var enabled: Bool = false
	@Published public var lower: Int = 0
	@Published public var upper: Int = 0
	
	public init() {
		self.enabled = false
		self.lower = 0
		self.upper = 0
	}
	
	public init(enabled: Bool, lower: Int, upper: Int) {
		self.enabled = enabled
		self.lower = lower
		self.upper = upper
	}
	
	public var stringValue: String {
		return ("Enabled: \(self.enabled), lower: \(self.lower), upper: \(self.upper)")
	}
}
