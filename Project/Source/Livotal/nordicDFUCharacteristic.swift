//
//  dfuCharacteristic.swift
//  biostrapDeviceSDK
//
//  Created by Joseph A. Bennett on 5/12/21.
//

#if UNIVERSAL || LIVOTAL
import Foundation
import CoreBluetooth

class nordicDFUCharacteristic: Characteristic {
	
	// MARK: Enumerations
	// Firmware packet command types
	enum commandType: UInt8 {
		case enterDFU		= 0x01
		case setAdvName		= 0x02
		case responseCode	= 0x20
	}

	enum responseType: UInt8 {
		case invalidCode	= 0x00	// The provided opcode was missing or malformed.
		case success		= 0x01	// The operation completed successfully.
		case notSupported	= 0x02	// The provided opcode was invalid.
		case failed			= 0x04	// The operation failed.
		case invalidAdvName	= 0x05	// The requested advertisement name was invalid (empty or too long). Only available without bond support.
		case busy			= 0x06	// The request was rejected due to a ongoing asynchronous operation.
		case notBonded		= 0x07	// The request was rejected because no bond was created.
	}
	
	// MARK: Callbacks
	var failed: ((_ id: String, _ code: Int, _ message: String)->())?

	//--------------------------------------------------------------------------------
	//
	// Constructor
	//
	//--------------------------------------------------------------------------------
	override init(_ peripheral: CBPeripheral, characteristic: CBCharacteristic) {
		super.init(peripheral, characteristic: characteristic)
	}
	
	convenience init(_ peripheral: CBPeripheral, characteristic: CBCharacteristic, name: String) {
		self.init(peripheral, characteristic: characteristic)
		
		let components = name.components(separatedBy: "-")
		
		if (components.count == 2) {
			gblDFUName	= "DFU-\(components[1])"
		}
		else {
			gblDFUName	= "LivotalDFU"
		}
	}
		
	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	override func didWrite() {
		if let characteristic = pCharacteristic {
			if let data = characteristic.value {
				log?.v ("\(pID): \(data.hexString)")
			}
			else {
				log?.v ("\(pID): (no data)")
			}
		}
	}
	
	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	override func didUpdateNotificationState() {
		pConfigured	= true
	}
	
	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	override func didUpdateValue() {
		if let peripheral = pPeripheral, let characteristic = pCharacteristic {
			if let data = characteristic.value {
				
				log?.v("\(pID): \(data.hexString)")
				
				let command		= commandType(rawValue: data[1])
				let response	= responseType(rawValue: data[2])

				if (response == .success) {
					switch (command!) {
					case .enterDFU:
						log?.v ("enterDFU")
					case .setAdvName:
						log?.v ("setAdvName")
						let data	= Data([commandType.enterDFU.rawValue])
						peripheral.writeValue(data, for: characteristic, type: .withResponse)
					default:
						log?.e ("Don't know what the command was: '\(data[1])'")
					}
				}
				else {
					log?.e ("Result '\(data[2])' wasn't successful")
				}
			}
			else {
				log?.e ("No data")
			}
		}
		else { log?.e ("Missing characteristic") }
	}
	
	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func start(_ file: URL) {
		log?.v ("\(pID)")
		
		if let peripheral = pPeripheral, let characteristic = pCharacteristic {
			if let advName = gblDFUName.data(using: .utf8) {
				
				dfu.prepare(pID, file: file)
				
				var data = Data([commandType.setAdvName.rawValue])
				data.append(UInt8(advName.count))
				data.append(advName)
				peripheral.writeValue(data, for: characteristic, type: .withResponse)
			}
		}
		else {
			self.failed?(pID, 10002, "No peripheral or characteristic to enable starting")
		}
	}
	
	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func cancel() {
	}

}

#endif
