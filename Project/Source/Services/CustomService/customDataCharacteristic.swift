//
//  customDataCharacteristic.swift
//  biostrapDeviceSDK
//
//  Created by Joseph A. Bennett on 1/3/23.
//

import Foundation
import CoreBluetooth
import Combine
import zlib

class customDataCharacteristic: CharacteristicTemplate {
	
    let dataPackets = PassthroughSubject<(Int, String), Never>()
    let dataComplete = PassthroughSubject<(Int, Int, Int, Int, Bool), Never>()

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
    internal func mProcessUpdateValue(_ data: Data, offset: Int) {
		globals.log.v ("\(id): \(data.count) bytes - \(data.hexString)")
		if let response = notifications(rawValue: data[0]) {
			switch (response) {
			case .dataPacket:
				if (data.count > 3) {	// Accounts for header byte and sequence number
					let sequence_number = data.subdata(in: Range(1...2)).leUInt16
                    let dataPackets = self.pParseDataPackets(data.subdata(in: Range(3...(data.count - 1))), offset: offset)
					
					do {
						let jsonData = try JSONEncoder().encode(dataPackets)
						if let jsonString = String(data: jsonData, encoding: .utf8) {
                            self.dataPackets.send((sequence_number, jsonString))
						}
						else { globals.log.e ("\(id): Cannot make string from json data") }
					}
					catch { globals.log.e ("\(id): Cannot make JSON data") }

				}
				else {
					globals.log.e ("\(id): Bad data length for data packet: \(data.hexString)")
					//mCRCOK	= false
				}
				
			case .dataCaughtUp:
				if (data.count == 8) {
					let bad_read_count	= Int(data.subdata(in: Range(1...2)).leUInt16)
					let bad_parse_count	= Int(data.subdata(in: Range(3...4)).leUInt16)
					let overflow_count	= Int(data.subdata(in: Range(5...6)).leUInt16)
					let intermediate	= (data[7] == 0x01)
                    self.dataComplete.send((bad_read_count, bad_parse_count, overflow_count, self.pFailedDecodeCount, intermediate))
					
					self.pFailedDecodeCount			= 0
				}
				else {
                    self.dataComplete.send((-1, -1, -1, self.pFailedDecodeCount, false))
				}
				
			default:
				globals.log.e ("\(id): Should not get a packet here of type: \(response)")
			}
		}
		else {
			globals.log.e ("\(id): Unknown update: \(data.hexString)")
		}
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	// This update is from Bluetooth
	//
	//--------------------------------------------------------------------------------
	override func didUpdateValue() {
        guard let characteristic = characteristic else {
            globals.log.e ("\(id): Missing characteristic")
            return
        }
        
        guard let data = characteristic.value else {
            globals.log.e ("\(id): Missing data")
            return
        }

        didUpdateValue(false, data: data, offset: 0)
	}
	
	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	override func didUpdateNotificationState() {
		configured	= true
	}
	    
    //--------------------------------------------------------------------------------
    // Function Name:
    //--------------------------------------------------------------------------------
    //
    // This is an update either from Bluetooth, or from a file.  When from a file,
    // there is no CRC
    //
    //--------------------------------------------------------------------------------
    func didUpdateValue(_ fromFile: Bool, data: Data, offset: Int) {
        if fromFile {
            mProcessUpdateValue(data, offset: offset)
        } else {
            // Packets have to be at least a header + CRC.  If not, do not parse
            if (data.count >= 4) {
                // Get the CRC.  Only process the packet if the CRC is good.
                let crc_received    = data.subdata(in: Range((data.count - 4)...(data.count - 1))).leInt32
                var input_bytes     = data.subdata(in: Range(0...(data.count - 5))).bytes
                let crc_calculated  = crc32(uLong(0), &input_bytes, uInt(input_bytes.count))
                
                if (crc_received != crc_calculated) {
                    globals.log.e ("\(id): Hmmm..... Packet CRC Error! CRC : \(String(format:"0x%08X", crc_received)): \(String(format:"0x%08X", crc_calculated))")
                    self.pFailedDecodeCount = self.pFailedDecodeCount + 1
                }
                
                mProcessUpdateValue(data.subdata(in: Range(0...(data.count - 5))), offset: offset)
            } else {
                globals.log.e ("\(id): Not enough data.  Length = \(data.count): \(data.hexString)")
            }
        }
    }
}
