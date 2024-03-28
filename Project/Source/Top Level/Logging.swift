//
//  Logging.swift
//  biostrapDeviceSDK
//
//  Created by Joseph A. Bennett on 3/31/21.
//

import Foundation
import Combine

public enum LogLevel {
	case verbose
	case debug
	case info
	case warning
	case error
}

class Logging {
		
	let log = PassthroughSubject<(LogLevel, String, String, String, Int), Never>()

	func v(_ value: String?, _ file: String = #file, _ function: String = #function, _ line: Int = #line) {
		self.log.send((LogLevel.verbose, "\(value ?? "")", file, function, line))
	}
	
	func d(_ value: String?, _ file: String = #file, _ function: String = #function, _ line: Int = #line) {
		self.log.send((LogLevel.debug, "\(value ?? "")", file, function, line))
	}
	
	func i(_ value: String?, _ file: String = #file, _ function: String = #function, _ line: Int = #line) {
		self.log.send((LogLevel.info, "\(value ?? "")", file, function, line))
	}

	func w(_ value: String?, _ file: String = #file, _ function: String = #function, _ line: Int = #line) {
		self.log.send((LogLevel.warning, "\(value ?? "")", file, function, line))
	}

	func e(_ value: String?, _ file: String = #file, _ function: String = #function, _ line: Int = #line) {
		self.log.send((LogLevel.error, "\(value ?? "")", file, function, line))
	}
}
