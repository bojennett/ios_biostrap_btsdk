//
//  Logging.swift
//  biostrapDeviceSDK
//
//  Created by Joseph A. Bennett on 3/31/21.
//

import Foundation

class Logging {
	
	public enum LEVEL {
		case verbose
		case debug
		case info
		case warning
		case error
	}
	
	// Logging
	public var log: ((_ level: LEVEL, _ message: String?, _ file: String, _ function: String, _ line: Int)->())?
	
	var prefix			: String	= ""
	
	public func v(_ value: String?, _ file: String = #file, _ function: String = #function, _ line: Int = #line) {
		self.log?(.verbose, "\(prefix) \(value!)", file, function, line)
	}
	
	public func d(_ value: String?, _ file: String = #file, _ function: String = #function, _ line: Int = #line) {
		self.log?(.debug, "\(prefix) \(value!)", file, function, line)
	}
	
	public func i(_ value: String?, _ file: String = #file, _ function: String = #function, _ line: Int = #line) {
		self.log?(.info, "\(prefix) \(value!)", file, function, line)
	}

	public func w(_ value: String?, _ file: String = #file, _ function: String = #function, _ line: Int = #line) {
		self.log?(.warning, "\(prefix) \(value!)", file, function, line)
	}

	public func e(_ value: String?, _ file: String = #file, _ function: String = #function, _ line: Int = #line) {
		self.log?(.error, "\(prefix) \(value!)", file, function, line)
	}	
}
