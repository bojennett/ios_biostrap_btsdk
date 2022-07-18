//
//  nordicDFU.swift
//  biostrapDeviceSDK
//
//  Created by Joseph A. Bennett on 5/12/21.
//

#if UNIVERSAL || LIVOTAL
import Foundation
import CoreBluetooth
import iOSDFULibrary

class nordicDFU: NSObject {
		
	var active						: Bool { return (mActive) }

	// MARK: Callbacks
	var started: ((_ id: String)->())?
	var finished: ((_ id: String)->())?
	var failed: ((_ id: String, _ code: Int, _ message: String)->())?
	var progress: ((_ id: String, _ progress: Float)->())?
	
	// MARK: Internal Variables
	internal var mID				: String = "UNKNOWN"
	internal var mFirmwareFile		: DFUFirmware!
	internal var mActive			: Bool	= false
	internal var mServiceInitiator	: DFUServiceInitiator!

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func prepare(_ id: String, file: URL) {
		log?.v ("")
		
		mID				= id
		mActive			= false
		
		mFirmwareFile = DFUFirmware.init(urlToZipFile: file, type: .softdeviceBootloaderApplication)
		if (mFirmwareFile == nil) {
			self.failed?(id, 10003, "Could not create update firmware from input file")
		}
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func update(_ peripheral: CBPeripheral) {
		log?.v ("")
		mServiceInitiator					= DFUServiceInitiator(queue: DispatchQueue(label: "Other"))
		mServiceInitiator.logger			= self
		mServiceInitiator.delegate			= self
		mServiceInitiator.progressDelegate	= self
		mActive								= true
		
		if (mFirmwareFile == nil) {
			self.failed?(mID, 10003, "Could not find input file")
		}
		else {
			let _	= mServiceInitiator.with(firmware: mFirmwareFile).start(target: peripheral)
		}
	}
}

// MARK: DFU Service Delegate

extension nordicDFU: DFUServiceDelegate {
	public func dfuStateDidChange(to state: DFUState) {
		log?.v ("dfuStateDidChange: \(state.description())")
		switch state {
		case .completed:
			mActive			= false
			self.finished?(mID)
		case .aborted:
			mActive			= false
			self.failed?(mID, 10004, "Aborted")
		case .starting	: self.started?(mID)
		default			: break
		}
		
	}
	
	public func dfuError(_ error: DFUError, didOccurWithMessage message: String) {
		log?.e ("dfuError: \(error.rawValue), \(message)")
		mActive			= false

		self.failed?(mID, error.rawValue, message)
	}
}

// MARK: DFU Progress Delegate

extension nordicDFU: DFUProgressDelegate {
	public func dfuProgressDidChange(for part: Int, outOf totalParts: Int, to progress: Int, currentSpeedBytesPerSecond: Double, avgSpeedBytesPerSecond: Double) {
		log?.v ("Part: \(part), totalParts: \(totalParts), progress: \(progress). currentSpeed: \(currentSpeedBytesPerSecond), avgSpeed: \(avgSpeedBytesPerSecond)")
		self.progress?(mID, (Float(progress) / 100.0))
	}
}

// MARK: DFU Logger Delegate

extension nordicDFU: LoggerDelegate {
	public func logWith(_ level: LogLevel, message: String) {
		switch (level) {
		case .application	: log?.v ("\(message)")
		case .verbose		: log?.v ("\(message)")
		case .info			: log?.i ("\(message)")
		case .debug			: log?.d ("\(message)")
		case .warning		: log?.w ("\(message)")
		case .error			: log?.e ("\(message)")
		@unknown default	: log?.e ("UNKNOWN LEVEL: \(message)")
		}
	}
}

#endif
