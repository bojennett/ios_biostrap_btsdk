//
//  customDataCharacteristic.swift
//  biostrapDeviceSDK
//
//  Created by Joseph A. Bennett on 1/3/23.
//

import Foundation
import CoreBluetooth
import zlib

class customDataCharacteristic: Characteristic {

	// MARK: Callbacks
	var dataPackets: ((_ packets: String)->())?
	var dataComplete: ((_ bad_fw_read_count: Int, _ bad_fw_parse_count: Int, _ overflow_count: Int, _ bad_sdk_parse_count: Int)->())?

	internal var mFailedDecodeCount			: Int = 0
	
	//--------------------------------------------------------------------------------
	//
	// Constructor
	//
	//--------------------------------------------------------------------------------
	override init(_ peripheral: CBPeripheral, characteristic: CBCharacteristic) {
		super.init(peripheral, characteristic: characteristic)
	}
	
	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//def reconstruct(dataComp8Bit):
	//	reconstructedData = []
	//	reconstructedData.append(dataComp8Bit.dataOffset)
	//
	//	for counter in range(0,dataComp8Bit.compressionCount):
	//		sign = dataComp8Bit.bitwiseSign & (1 << counter)
	//		if sign != 0:
	//			sign = -1
	//		else:
	//			sign = 1
	//
	//		reconstructedData.append(reconstructedData[0] + sign*dataComp8Bit.dataPointer[counter])
	//
	//	return reconstructedData
	//
	//--------------------------------------------------------------------------------
	internal func mDecompressPPGPackets(_ data: Data) -> [biostrapDataPacket] {
		var packets				= [biostrapDataPacket]()
		if let packetType = packetType(rawValue: data[0]) {
			let compressionCount	= Int(data[1])
			let bitwiseSign			= data[2]
			
			let firstSample			= (Int(data[3]) << 0) | (Int(data[4]) << 8) | (Int(data[5]) << 16)
			let packet				= biostrapDataPacket()
			packet.value			= firstSample
			packet.type				= packetType
			packet.raw_data			= data
			packet.raw_data_string	= data.hexString.replacingOccurrences(of: "[ ", with: "").replacingOccurrences(of: " ]", with: "")
			
			packets.append(packet)
			
			var index		= 0
			while (index < compressionCount) {
				let negative			= ((bitwiseSign & (0x01 << index)) != 0)
				let sample				= Int(data[index + 6])
				let packet				= biostrapDataPacket()
				packet.type				= packetType
				packet.raw_data			= data
				packet.raw_data_string	= data.hexString.replacingOccurrences(of: "[ ", with: "").replacingOccurrences(of: " ]", with: "")
				
				if (negative) {
					packet.value	= firstSample - sample
				}
				else {
					packet.value	= firstSample + sample
				}
				
				packets.append(packet)
				index = index + 1
			}
		}
		
		return (packets)
	}
	
	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	// Similar to PPG.  Differences:
	//    * firstSample is 2 bytes and signed
	//    * bitwiseSign is 2 bytes (total of 15 possible samples)
	//
	//--------------------------------------------------------------------------------
	internal func mDecompressIMUPackets(_ data: Data) -> [biostrapDataPacket] {
		var packets				= [biostrapDataPacket]()
		if let packetType = packetType(rawValue: data[0]) {
			let compressionCount	= Int(data[1])
			let bitwiseSign			= data.subdata(in: Range(2...3)).leUInt16
			
			let firstSample			= data.subdata(in: Range(4...5)).leInt16
			let packet				= biostrapDataPacket()
			packet.value			= firstSample
			packet.raw_data			= data
			packet.raw_data_string	= data.hexString.replacingOccurrences(of: "[ ", with: "").replacingOccurrences(of: " ]", with: "")
			packet.type				= packetType
			
			packets.append(packet)
			
			var index		= 0
			while (index < compressionCount) {
				let negative			= ((bitwiseSign & (0x01 << index)) != 0)
				let sample				= Int(data[index + 6])
				let packet				= biostrapDataPacket()
				packet.type				= packetType
				packet.raw_data			= data
				packet.raw_data_string	= data.hexString.replacingOccurrences(of: "[ ", with: "").replacingOccurrences(of: " ]", with: "")
				
				if (negative) {
					packet.value	= firstSample - sample
				}
				else {
					packet.value	= firstSample + sample
				}
				
				packets.append(packet)
				index = index + 1
			}
		}
		
		return (packets)
	}
	
	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	internal func mParseSinglePacket(_ data: Data, index: Int) -> (Bool, packetType, biostrapDataPacket) {
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
						log?.e ("\(type.title): Index: \(index), Full Packet: \(data.hexString)")
						return (false, .unknown, biostrapDataPacket())
					}
				}
				else {
					log?.e ("\(type.title): Index: \(index), Full Packet: \(data.hexString)")
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
						log?.e ("\(type.title): Index: \(index), Full Packet: \(data.hexString)")
						return (false, .unknown, biostrapDataPacket())
					}
				}
				else {
					log?.e ("\(type.title): Index: \(index), Full Packet: \(data.hexString)")
					return (false, .unknown, biostrapDataPacket())
				}
				
#if ETHOS || UNIVERSAL
			case .rawPPGCompressedWhiteIRRPD,
					.rawPPGCompressedWhiteWhitePD:
				if ((index + 1) < data.count) {
					let length = Int(data[index + 1]) + 1 + 1 + 1 + 3
					if ((index + length) <= data.count) {
						let packetData = data.subdata(in: Range(index...(index + length - 1)))
						return (true, type, biostrapDataPacket(packetData))
					}
					else {
						log?.e ("\(type.title): Index: \(index), Full Packet: \(data.hexString)")
						return (false, .unknown, biostrapDataPacket())
					}
				}
				else {
					log?.e ("\(type.title): Index: \(index), Full Packet: \(data.hexString)")
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
						log?.e ("\(type.title): Index: \(index), Full Packet: \(data.hexString)")
						return (false, .unknown, biostrapDataPacket())
					}
				}
				else {
					log?.e ("\(type.title): Index: \(index), Full Packet: \(data.hexString)")
					return (false, .unknown, biostrapDataPacket())
				}
				
#if ETHOS || UNIVERSAL
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
						log?.e ("\(type.title): Index: \(index), Full Packet: \(data.hexString)")
						return (false, .unknown, biostrapDataPacket())
					}
				}
				else {
					log?.e ("\(type.title): Index: \(index), Full Packet: \(data.hexString)")
					return (false, .unknown, biostrapDataPacket())
				}
#endif
			
			case .unknown:
				log?.e ("\(type.title): Index: \(index), Full Packet: \(data.hexString)")
				return (false, type, biostrapDataPacket())
				
			default:
				if ((index + type.length) <= data.count) {
					let packetData = data.subdata(in: Range((index)...(index + type.length - 1)))
					return (true, type, biostrapDataPacket(packetData))
				}
				else {
					log?.e ("\(type.title): '\(type.length)' from '\(index)' exceeds length of data '\(data.count)'")
					return (false, type, biostrapDataPacket())
				}
			}
			
		}
		else {
			log?.v ("Could not parse type: Remaining bytes: \(data.subdata(in: Range(index...(data.count - 1))).hexString)")
			return (false, .unknown, biostrapDataPacket())
		}
	}
	
	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	internal func mParsePackets(_ data: Data) -> ([biostrapDataPacket]) {
		//log?.v ("\(pID): Data: \(data.hexString)")
		
		var index = 0
		var dataPackets = [biostrapDataPacket]()
		
		let incomingDataDiagnostic				= biostrapDataPacket()
		incomingDataDiagnostic.raw_data			= data
		incomingDataDiagnostic.raw_data_string	= data.hexString.replacingOccurrences(of: "[ ", with: "").replacingOccurrences(of: " ]", with: "")
		incomingDataDiagnostic.type				= packetType.diagnostic
		incomingDataDiagnostic.diagnostic_type	= diagnosticType.bluetoothPacket
		
		dataPackets.append(incomingDataDiagnostic)
		
		while (index < data.count) {
			let (found, type, packet) = mParseSinglePacket(data, index: index)
			
			if (found) {
				switch (type) {
				case .diagnostic:
					index = index + packet.raw_data.count
					dataPackets.append(packet)
					
				case .rawPPGCompressedGreen,
						.rawPPGCompressedIR,
						.rawPPGCompressedRed:
					index = index + packet.raw_data.count
					
					let packets = mDecompressPPGPackets(packet.raw_data)
					dataPackets.append(contentsOf: packets)
					
#if ETHOS || UNIVERSAL
				case .rawPPGCompressedWhiteIRRPD,
						.rawPPGCompressedWhiteWhitePD:
					index = index + packet.raw_data.count
					
					let packets = mDecompressPPGPackets(packet.raw_data)
					dataPackets.append(contentsOf: packets)
#endif
					
				case .rawAccelCompressedXADC,
						.rawAccelCompressedYADC,
						.rawAccelCompressedZADC:
					index = index + packet.raw_data.count
					
					let packets = mDecompressIMUPackets(packet.raw_data)
					dataPackets.append(contentsOf: packets)
					
#if ETHOS || UNIVERSAL
				case .rawGyroCompressedXADC,
						.rawGyroCompressedYADC,
						.rawGyroCompressedZADC:
					index = index + packet.raw_data.count
					
					let packets = mDecompressIMUPackets(packet.raw_data)
					dataPackets.append(contentsOf: packets)
#endif
					
				default:
					index = index + type.length
					if (type != .unknown) { dataPackets.append(packet) }
				}
			}
			else {
				index = index + type.length
				mFailedDecodeCount	= mFailedDecodeCount + 1
			}
		}
		
		return (dataPackets)
	}
	
	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	override func didUpdateValue() {
		if let characteristic = pCharacteristic {
			if let data = characteristic.value {
				let packets = self.mParsePackets(data)
				
				if (packets.count > 0) {
					if (packets.count == 1) {
						let packet = packets.first
						if (packet?.type == .caughtUp) {
							let bad_read_count	= Int(data.subdata(in: Range(1...2)).leUInt16)
							let bad_parse_count	= Int(data.subdata(in: Range(3...4)).leUInt16)
							let overflow_count	= Int(data.subdata(in: Range(5...6)).leUInt16)
							self.dataComplete?(bad_read_count, bad_parse_count, overflow_count, self.mFailedDecodeCount)
						}
						else {
							do {
								let jsonData = try JSONEncoder().encode(packets)
								if let jsonString = String(data: jsonData, encoding: .utf8) {
									self.dataPackets?(jsonString)
								}
								else { log?.e ("Cannot make string from json data") }
							}
							catch { log?.e ("Cannot make JSON data") }
						}
					}
					else {
						do {
							let jsonData = try JSONEncoder().encode(packets)
							if let jsonString = String(data: jsonData, encoding: .utf8) {
								self.dataPackets?(jsonString)
							}
							else { log?.e ("Cannot make string from json data") }
						}
						catch { log?.e ("Cannot make JSON data") }
					}
				}
			}
			else {
				log?.e ("\(pID): Missing data")
			}
		}
		else { log?.e ("\(pID): Missing characteristic") }
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
	
}
