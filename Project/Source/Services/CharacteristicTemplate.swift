//
//  CharacteristicTemplate.swift
//  biostrapDeviceSDK
//
//  Created by Joseph A. Bennett on 5/12/21.
//

import Foundation
import CoreBluetooth

class CharacteristicTemplate {
	
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
		case endSleepStatus		= 0x0a
		case buttonResponse		= 0x0b
		case streamPacket		= 0x0c
		case dataAvailable		= 0x0d
	}
	
	// MARK: Internal Variables
	internal var id: String = "UNKNOWN"
    internal var characteristic: CBCharacteristic?
    internal var commandQ: CommandQ?
    internal var pFailedDecodeCount: Int = 0
    
    // MARK: Published properties
    @Published var configured: Bool = false

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
    internal func pParseSinglePacket(_ data: Data, index: Int, offset: Int) -> (Bool, packetType, biostrapDataPacket) {
		//globals.log.v ("\(index): \(String(format: "0x%02X", data[index]))")
		if let type = packetType(rawValue: data[index]) {
			switch (type) {
			case .diagnostic:
				if ((index + 1) < data.count) {
					let length = Int(data[index + 1]) + 1
					
					if ((index + length) <= data.count) {
						let packetData = data.subdata(in: Range(index...(index + length - 1)))
						return (true, type, biostrapDataPacket(packetData, offset: offset))
					}
					else {
						globals.log.e ("\(id): \(type.title): Index: \(index), Full Packet: \(data.hexString)")
						return (false, .unknown, biostrapDataPacket())
					}
				}
				else {
					globals.log.e ("\(id): \(type.title): Index: \(index), Full Packet: \(data.hexString)")
					return (false, .unknown, biostrapDataPacket())
				}
				
			case .rawPPGCompressedGreen,
					.rawPPGCompressedIR,
					.rawPPGCompressedRed:
				if ((index + 1) < data.count) {
					let length = Int(data[index + 1]) + 1 + 1 + 1 + 3
					if ((index + length) <= data.count) {
						let packetData = data.subdata(in: Range(index...(index + length - 1)))
						return (true, type, biostrapDataPacket(packetData, offset: offset))
					}
					else {
						globals.log.e ("\(id): \(type.title): Index: \(index), Full Packet: \(data.hexString)")
						return (false, .unknown, biostrapDataPacket())
					}
				}
				else {
					globals.log.e ("\(id): \(type.title): Index: \(index), Full Packet: \(data.hexString)")
					return (false, .unknown, biostrapDataPacket())
				}
								
			case .rawAccelCompressedXADC,
					.rawAccelCompressedYADC,
					.rawAccelCompressedZADC:
				if ((index + 1) < data.count) {
					let length = Int(data[index + 1]) + 1 + 1 + 2 + 2
					if ((index + length) <= data.count) {
						let packetData = data.subdata(in: Range(index...(index + length - 1)))
						return (true, type, biostrapDataPacket(packetData, offset: offset))
					}
					else {
						globals.log.e ("\(id): \(type.title): Index: \(index), Full Packet: \(data.hexString)")
						return (false, .unknown, biostrapDataPacket())
					}
				}
				else {
					globals.log.e ("\(id): \(type.title): Index: \(index), Full Packet: \(data.hexString)")
					return (false, .unknown, biostrapDataPacket())
				}
				
			case .bbi:
				if ((index + 9) < data.count) {
					let packets = Int(data[index + 9])
					let final_index = index + 9 + (packets * 2)
					if (final_index < data.count) {
						let packetData = data.subdata(in: Range(index...final_index))
						return (true, type, biostrapDataPacket(packetData, offset: offset))
					}
					else {
						globals.log.e ("\(id): \(type.title): (Out of range) Index: \(index), packets: \(packets), final index: \(final_index), full packet: \(data.hexString)")
						return (false, .unknown, biostrapDataPacket())
					}
				}
				else {
					globals.log.e ("\(id): \(type.title): (Not enough bytes) Index: \(index), full packet: \(data.hexString)")
					return (false, .unknown, biostrapDataPacket())
				}
				
			case .cadence:
				if ((index + 9) < data.count) {
					let packets = Int(data[index + 9])
					let final_index = index + 9 + packets
					if (final_index < data.count) {
						let packetData = data.subdata(in: Range(index...final_index))
						return (true, type, biostrapDataPacket(packetData, offset: offset))
					}
					else {
						globals.log.e ("\(id): \(type.title): (Out of range) Index: \(index), packets: \(packets), final index: \(final_index), full packet: \(data.hexString)")
						return (false, .unknown, biostrapDataPacket())
					}
				}
				else {
					globals.log.e ("\(id): \(type.title): (Not enough bytes) Index: \(index), full packet: \(data.hexString)")
					return (false, .unknown, biostrapDataPacket())
				}
				
			case .algorithmData:
				if ((index + 1) < data.count) {
					let length = Int(data[index + 1]) + 1
					
					if ((index + length) <= data.count) {
						let packetData = data.subdata(in: Range(index...(index + length - 1)))
                        return (true, type, biostrapDataPacket(packetData, offset: offset))
					}
					else {
						globals.log.e ("\(id): \(type.title): Index: \(index), Full Packet: \(data.hexString)")
						return (false, .unknown, biostrapDataPacket())
					}
				}
				else {
					globals.log.e ("\(id): \(type.title): Index: \(index), Full Packet: \(data.hexString)")
					return (false, .unknown, biostrapDataPacket())
				}
				
			case .unknown:
				globals.log.e ("\(id): \(type.title): Index: \(index), Full Packet: \(data.hexString)")
				return (false, .unknown, biostrapDataPacket())
				
			default:
				if ((index + type.length) <= data.count) {
					let packetData = data.subdata(in: Range((index)...(index + type.length - 1)))
					return (true, type, biostrapDataPacket(packetData, offset: offset))
				}
				else {
					globals.log.e ("\(id): \(type.title): '\(type.length)' from '\(index)' exceeds length of data '\(data.count)'")
					return (false, .unknown, biostrapDataPacket())
				}
			}
			
		}
		else {
			globals.log.e ("\(id): Could not parse type: Remaining bytes: \(data.subdata(in: Range(index...(data.count - 1))).hexString)")
			return (false, .unknown, biostrapDataPacket())
		}
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
    internal func pParseDataPackets(_ data: Data, offset: Int) -> ([biostrapDataPacket]) {
		//globals.log.v ("\(pID): Data: \(data.hexString)")
		
		var index = 0
		var dataPackets = [biostrapDataPacket]()
		
		let incomingDataDiagnostic				= biostrapDataPacket()
		incomingDataDiagnostic.raw_data			= data
		incomingDataDiagnostic.raw_data_string	= data.hexString.replacingOccurrences(of: "[ ", with: "").replacingOccurrences(of: " ]", with: "")
		incomingDataDiagnostic.type				= packetType.diagnostic
		incomingDataDiagnostic.diagnostic_type	= diagnosticType.bluetoothPacket
		
		dataPackets.append(incomingDataDiagnostic)
		
		while (index < data.count) {
            let (found, type, packet) = pParseSinglePacket(data, index: index, offset: offset)
			
			if (found) {
				switch (type) {
				case .diagnostic:
					index = index + packet.raw_data.count
					dataPackets.append(packet)
					
				case .rawAccelCompressedXADC,
						.rawAccelCompressedYADC,
						.rawAccelCompressedZADC:
					index = index + packet.raw_data.count
					
					let packets = mDecompressIMUPackets(packet.raw_data)
					dataPackets.append(contentsOf: packets)
					
				case .rawPPGCompressedGreen,
						.rawPPGCompressedIR,
						.rawPPGCompressedRed:
					index = index + packet.raw_data.count
					
					let packets = mDecompressPPGPackets(packet.raw_data)
					dataPackets.append(contentsOf: packets)
					
				case .bbi:
					index = index + packet.raw_data.count
					dataPackets.append(packet)
					
				case .cadence:
					index = index + packet.raw_data.count
					dataPackets.append(packet)
					
				case .algorithmData:
					index = index + packet.raw_data.count
					dataPackets.append(packet)
					
				default:
					index = index + type.length
					if (type != .unknown) { dataPackets.append(packet) }
				}
			} else {
				index = index + packetType.unknown.length
				pFailedDecodeCount	= pFailedDecodeCount + 1
			}
		}
		
		return (dataPackets)
	}
    
    //--------------------------------------------------------------------------------
    //
    // Constructor
    //
    //--------------------------------------------------------------------------------
    open class var uuid: CBUUID {
        globals.log.e ("Don't know what to do here.  Perhaps need to override?")
        return org_bluetooth_characteristic.string.UUID
    }

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func didDiscover(_ characteristic: CBCharacteristic, commandQ: CommandQ?) {
        self.id = characteristic.deviceID
        self.characteristic = characteristic
        self.configured = false
        self.commandQ = commandQ
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func read() {
		commandQ?.read(characteristic)
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func didWrite() {
		globals.log.e ("\(id): Did you mean to override?")
	}
	
	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func didUpdateValue() {
		globals.log.e ("\(id): Did you mean to override?")
	}
	
	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func didUpdateNotificationState() {
		globals.log.e ("\(id): Did you mean to override?")
	}
	
	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func didDiscoverDescriptor() {
		if let peripheral = characteristic?.service?.peripheral, let characteristic {
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
		if let peripheral = characteristic?.service?.peripheral, let characteristic {
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
	func didWriteWithoutResponseReady() {
		globals.log.e ("\(id): Did you mean to override?")
	}
}
