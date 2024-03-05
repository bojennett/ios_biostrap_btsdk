//
//  hrZoneLEDValueType.swift
//  biostrapDeviceSDK
//
//  Created by Joseph Bennett on 3/5/24.
//

import Foundation
import Combine

public class hrZoneLEDValueType: ObservableObject {
	@Published public var red: Bool
	@Published public var green: Bool
	@Published public var blue: Bool
	@Published public var on_ms: Int
	@Published public var off_ms: Int
	
	public init() {
		self.red = false
		self.green = false
		self.blue = false
		self.on_ms = 0
		self.off_ms = 0
	}
	
	public init(red: Bool, green: Bool, blue: Bool, on_ms: Int, off_ms: Int) {
		self.red = red
		self.green = green
		self.blue = blue
		self.on_ms = on_ms
		self.off_ms = off_ms
	}
	
	public var stringValue: String {
		return ("Red: \(self.red), green: \(self.green), blue: \(self.blue), on_ms: \(self.on_ms), off_ms: \(self.off_ms)")
	}
}
