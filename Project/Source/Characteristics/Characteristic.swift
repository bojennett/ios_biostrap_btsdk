//
//  Characteristic.swift
//  biostrapDeviceSDK
//
//  Created by Joseph A. Bennett on 5/12/21.
//

import Foundation
import CoreBluetooth

class Characteristic {
	
	enum notifications: UInt8 {
		case completion			= 0x00
		case dataPacket			= 0x01
		case worn				= 0x02
		case ppgFailed			= 0x04
		case validateCRC		= 0x05
		case dataCaughtUp		= 0x06
		case manufacturingTest	= 0x07
		case charging			= 0x08
		case ppg_metrics		= 0x09
		#if UNIVERSAL || ALTER || KAIROS || ETHOS
		case endSleepStatus		= 0x0a
		case buttonResponse		= 0x0b
		#endif
		case streamPacket		= 0x0c
	}
	
	// MARK: Internal Variables
	internal var pPeripheral		: CBPeripheral?
	internal var pCharacteristic	: CBCharacteristic?
	internal var pID				: String				= "UNKNOWN"
	internal var pConfigured		: Bool					= false
	internal var pDiscovered		: Bool					= false

	// MARK: Public Variables
	var configured: Bool {
		return (pConfigured)
	}

	// MARK: Public Variables
	var discovered: Bool {
		return (pDiscovered)
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	internal func pParseSinglePacket(_ data: Data, index: Int) -> (Bool, packetType, biostrapDataPacket) {
		//log?.v ("\(index): \(String(format: "0x%02X", data[index]))")
		if let type = packetType(rawValue: data[index]) {
			switch (type) {
			case .diagnostic:
				if ((index + 1) < data.count) {
					let length = Int(data[index + 1]) + 1
					
					if ((index + length) <= data.count) {
						let packetData = data.subdata(in: Range(index...(index + length - 1)))
						return (true, type, biostrapDataPacket(packetData))
					}
					else {
						log?.e ("\(pID): \(type.title): Index: \(index), Full Packet: \(data.hexString)")
						return (false, .unknown, biostrapDataPacket())
					}
				}
				else {
					log?.e ("\(pID): \(type.title): Index: \(index), Full Packet: \(data.hexString)")
					return (false, .unknown, biostrapDataPacket())
				}
				
			case .rawPPGCompressedGreen,
					.rawPPGCompressedIR,
					.rawPPGCompressedRed:
				if ((index + 1) < data.count) {
					let length = Int(data[index + 1]) + 1 + 1 + 1 + 3
					if ((index + length) <= data.count) {
						let packetData = data.subdata(in: Range(index...(index + length - 1)))
						return (true, type, biostrapDataPacket(packetData))
					}
					else {
						log?.e ("\(pID): \(type.title): Index: \(index), Full Packet: \(data.hexString)")
						return (false, .unknown, biostrapDataPacket())
					}
				}
				else {
					log?.e ("\(pID): \(type.title): Index: \(index), Full Packet: \(data.hexString)")
					return (false, .unknown, biostrapDataPacket())
				}
				
			#if UNIVERSAL || ETHOS
			case .rawPPGCompressedWhiteIRRPD,
					.rawPPGCompressedWhiteWhitePD:
				if ((index + 1) < data.count) {
					let length = Int(data[index + 1]) + 1 + 1 + 1 + 3
					if ((index + length) <= data.count) {
						let packetData = data.subdata(in: Range(index...(index + length - 1)))
						return (true, type, biostrapDataPacket(packetData))
					}
					else {
						log?.e ("\(pID): \(type.title): Index: \(index), Full Packet: \(data.hexString)")
						return (false, .unknown, biostrapDataPacket())
					}
				}
				else {
					log?.e ("\(pID): \(type.title): Index: \(index), Full Packet: \(data.hexString)")
					return (false, .unknown, biostrapDataPacket())
				}
			#endif
				
			case .rawAccelCompressedXADC,
					.rawAccelCompressedYADC,
					.rawAccelCompressedZADC:
				if ((index + 1) < data.count) {
					let length = Int(data[index + 1]) + 1 + 1 + 2 + 2
					if ((index + length) <= data.count) {
						let packetData = data.subdata(in: Range(index...(index + length - 1)))
						return (true, type, biostrapDataPacket(packetData))
					}
					else {
						log?.e ("\(pID): \(type.title): Index: \(index), Full Packet: \(data.hexString)")
						return (false, .unknown, biostrapDataPacket())
					}
				}
				else {
					log?.e ("\(pID): \(type.title): Index: \(index), Full Packet: \(data.hexString)")
					return (false, .unknown, biostrapDataPacket())
				}
				
			#if UNIVERSAL || ETHOS
			case .rawGyroCompressedXADC,
					.rawGyroCompressedYADC,
					.rawGyroCompressedZADC:
				if ((index + 1) < data.count) {
					let length = Int(data[index + 1]) + 1 + 1 + 2 + 2
					if ((index + length) <= data.count) {
						let packetData = data.subdata(in: Range(index...(index + length - 1)))
						return (true, type, biostrapDataPacket(packetData))
					}
					else {
						log?.e ("\(pID): \(type.title): Index: \(index), Full Packet: \(data.hexString)")
						return (false, .unknown, biostrapDataPacket())
					}
				}
				else {
					log?.e ("\(pID): \(type.title): Index: \(index), Full Packet: \(data.hexString)")
					return (false, .unknown, biostrapDataPacket())
				}
			#endif
				
			#if UNIVERSAL || ALTER || KAIROS || ETHOS
			case .bbi:
				if ((index + 9) < data.count) {
					let packets = Int(data[index + 9])
					let final_index = index + 9 + (packets * 2)
					if (final_index < data.count) {
						let packetData = data.subdata(in: Range(index...final_index))
						return (true, type, biostrapDataPacket(packetData))
					}
					else {
						log?.e ("\(pID): \(type.title): (Out of range) Index: \(index), packets: \(packets), final index: \(final_index), full packet: \(data.hexString)")
						return (false, .unknown, biostrapDataPacket())
					}
				}
				else {
					log?.e ("\(pID): \(type.title): (Not enough bytes) Index: \(index), full packet: \(data.hexString)")
					return (false, .unknown, biostrapDataPacket())
				}
				
			case .cadence:
				if ((index + 9) < data.count) {
					let packets = Int(data[index + 9])
					let final_index = index + 9 + packets
					if (final_index < data.count) {
						let packetData = data.subdata(in: Range(index...final_index))
						return (true, type, biostrapDataPacket(packetData))
					}
					else {
						log?.e ("\(pID): \(type.title): (Out of range) Index: \(index), packets: \(packets), final index: \(final_index), full packet: \(data.hexString)")
						return (false, .unknown, biostrapDataPacket())
					}
				}
				else {
					log?.e ("\(pID): \(type.title): (Not enough bytes) Index: \(index), full packet: \(data.hexString)")
					return (false, .unknown, biostrapDataPacket())
				}

			#endif
				
			case .unknown:
				log?.e ("\(pID): \(type.title): Index: \(index), Full Packet: \(data.hexString)")
				return (false, .unknown, biostrapDataPacket())
				
			default:
				if ((index + type.length) <= data.count) {
					let packetData = data.subdata(in: Range((index)...(index + type.length - 1)))
					return (true, type, biostrapDataPacket(packetData))
				}
				else {
					log?.e ("\(pID): \(type.title): '\(type.length)' from '\(index)' exceeds length of data '\(data.count)'")
					return (false, .unknown, biostrapDataPacket())
				}
			}
			
		}
		else {
			log?.v ("\(pID): Could not parse type: Remaining bytes: \(data.subdata(in: Range(index...(data.count - 1))).hexString)")
			return (false, .unknown, biostrapDataPacket())
		}
	}

	//--------------------------------------------------------------------------------
	//
	// Constructor
	//
	//--------------------------------------------------------------------------------
	init(_ peripheral: CBPeripheral, characteristic: CBCharacteristic) {
		pID				= peripheral.prettyID
		pPeripheral		= peripheral
		pCharacteristic	= characteristic
		pConfigured		= false
		pDiscovered		= false
	}
	
	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func read() {
		log?.e ("\(pID): Did you mean to override?")
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func didDiscover() {
		log?.e ("\(pID): Did you mean to override?")
	}
	
	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func didWrite() {
		log?.e ("\(pID): Did you mean to override?")
	}
	
	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func didUpdateValue() {
		log?.e ("\(pID): Did you mean to override?")
	}
	
	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func didUpdateNotificationState() {
		log?.e ("\(pID): Did you mean to override?")
	}
	
	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func didDiscoverDescriptor() {
		if let peripheral = pPeripheral, let characteristic = pCharacteristic {
			peripheral.setNotifyValue(true, for: characteristic)
		}
	}
	
	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func discoverDescriptors() {
		if let peripheral = pPeripheral, let characteristic = pCharacteristic {
			peripheral.discoverDescriptors(for: characteristic)
		}
	}
	
	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	// Write without response is done.  Will only happen for OTA, since that uses
	// write without responses
	//
	//--------------------------------------------------------------------------------
	func isReady() {
		log?.e ("\(pID): Did you mean to override?")
	}
}
