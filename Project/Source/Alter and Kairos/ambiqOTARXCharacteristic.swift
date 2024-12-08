//
//  ambiqOTARXCharacteristic.swift
//  AmbiqOTATest
//
//  Created by Joseph Bennett on 9/20/21.
//

import Foundation
import CoreBluetooth
import Combine

//--------------------------------------------------------------------------------
//
// OTA Status
//
//--------------------------------------------------------------------------------
internal enum amotaStatus: UInt8 {
	case SUCCESS				= 0x00
	case CRC_ERROR				= 0x01
	case INVALID_HEADER_INFO	= 0x02
	case INVALID_PACKET_LENGTH	= 0x03
	case INSUFFICIENT_BUFFER	= 0x04
	case UNKNOWN_ERROR			= 0x05
	case STATUS_MAX				= 0x06
	case APP_CANCEL				= 0x80
	case APP_NOT_ENOUGH_DATA	= 0x81
	case APP_MISSING_OBJECTS	= 0x82
	case APP_MISSING_FILE		= 0x83
	case APP_MISSING_DEVICE		= 0x84
	case APP_EXISTING_OTA		= 0x85
	
	var title: String {
		switch (self) {
		case .SUCCESS				: return "Success"
		case .CRC_ERROR				: return "Failed: CRC Error"
		case .INVALID_HEADER_INFO	: return "Failed: Invalid Header Info"
		case .INVALID_PACKET_LENGTH	: return "Failed: Invalid Packet Length"
		case .INSUFFICIENT_BUFFER	: return "Failed: Insufficient Buffer"
		case .UNKNOWN_ERROR			: return "Failed: Unknown Error"
		case .STATUS_MAX			: return "Failed: 'Max'"
		case .APP_CANCEL			: return "Failed: App Cancelled"
		case .APP_NOT_ENOUGH_DATA	: return "Failed: Not Enough Data in File"
		case .APP_MISSING_OBJECTS	: return "Failed: Missing OS Bluetooth Objects"
		case .APP_MISSING_FILE		: return "Failed: Missing FW Data File"
		case .APP_MISSING_DEVICE	: return "Failed: Missing Device"
		case .APP_EXISTING_OTA		: return "Failed: Previous incomplete OTA exists - please reset device"
		}
	}
}

class ambiqOTARXCharacteristic: Characteristic {
	internal var mData							: Data?

	//--------------------------------------------------------------------------------
	//
	// OTA commands
	//
	//--------------------------------------------------------------------------------
	internal enum otaCommand: UInt8 {
		case AMOTA_CMD_UNKNOWN					= 0x00
		case AMOTA_CMD_FW_HEADER				= 0x01
		case AMOTA_CMD_FW_DATA					= 0x02
		case AMOTA_CMD_FW_VERIFY				= 0x03
		case AMOTA_CMD_FW_RESET					= 0x04
		case AMOTA_CMD_MAX						= 0x05
	}

	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	internal enum state {
		case IDLE
		case HEADER
		case DATA
		case VERIFY
		case RESET
		case DONE
		case CANCEL
	}
	
    let started = PassthroughSubject<Void, Never>()
    let finished = PassthroughSubject<Void, Never>()
    let progress = PassthroughSubject<Float, Never>()
    let failed = PassthroughSubject<(Int, String), Never>()

	internal static let DATA_BLOCK_SIZE		= 512
	internal static let CRC_SIZE			= 4
	internal static let HEADER_SIZE			= 3
	internal static let FILE_HEADER_BLOCK	= 48

	internal var mFileSize		= 0

	internal var mDataPackets	: [[Data]]	// Data blocks with sub-frames
	internal var mHeaderPackets	: [Data]	// Header with sub-frames
	internal var mDataIndex		: Int
	internal var mFrameIndex	: Int
	internal var mState			: state
    
    override class var uuid: CBUUID {
        return CBUUID(string: "00002760-08C2-11E1-9073-0E8AC72E0001")
    }

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	// Adds the header (command + 2-byte length) and CRC (4-bytes) to data block
	//
	//--------------------------------------------------------------------------------
	internal func mBuildPacket(command: otaCommand, data: Data?) -> Data {
		var checksum	= UInt32(0)
		var length		= 0
		
		if let data = data { length = data.count }
		
		var packet = Data()
		
		// fill data + checksum length
		packet.append(UInt8(((length + ambiqOTARXCharacteristic.CRC_SIZE) >> 0) & 0xff))
		packet.append(UInt8(((length + ambiqOTARXCharacteristic.CRC_SIZE) >> 8) & 0xff))
		packet.append(command.rawValue)
		
		if let data = data {
			checksum = CrcCalculator.checksum(bytes: data.bytes) // calculate CRC
			packet.append(data)
		}

		// append crc into packet. crc is always 0 if there is no data only command
		packet.append(UInt8((checksum >>  0) & 0xff))
		packet.append(UInt8((checksum >>  8) & 0xff))
		packet.append(UInt8((checksum >> 16) & 0xff))
		packet.append(UInt8((checksum >> 24) & 0xff))
		
		//globals.log.v (packet.hexString)
		
		return packet
	}
	
	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	// Splits a block into individual frames for transmission
	//
	//--------------------------------------------------------------------------------
	internal func mBuildFrames(data: Data) -> [Data] {
		var index = 0
		
		var packets = [Data]()
		
		var deviceMTU = 20
		
		if let peripheral = pPeripheral {
			deviceMTU = peripheral.maximumWriteValueLength(for: .withoutResponse)
		}

		let mtu = deviceMTU > 200 ? 200 : deviceMTU
		
		while (index < data.count) {
			var frameLength: Int
			if (data.count - index > mtu) {
				frameLength	= mtu
			}
			else {
				frameLength	= data.count - index
			}
			
			let frame = data.subdata(in: (index..<(index + frameLength)))
			packets.append(frame)
			index	= index + frameLength
		}
		return packets
	}
	
	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	// Sends a frame onto bluetooth
	//
	//--------------------------------------------------------------------------------
	internal func mSendFrame(data: Data) {
		pCommandQ?.write(pCharacteristic, data: data, type: .withoutResponse)
	}

	//--------------------------------------------------------------------------------
	//
	// Constructor
	//
	//--------------------------------------------------------------------------------
	override init() {
		mState			= .IDLE
		mDataIndex		= 0
		mFrameIndex		= 0

		mHeaderPackets	= [Data]()
		mDataPackets	= [[Data]]()

		super.init ()

		configured		= true
	}
	
	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	override func didDiscover(_ peripheral: CBPeripheral, characteristic: CBCharacteristic, commandQ: CommandQ?) {
		super.didDiscover(peripheral, characteristic: characteristic, commandQ: commandQ)
		configured = true
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func start(_ data: Data) {
		mData = data
		
		if let _ = pPeripheral, let _ = pCharacteristic, let data = mData {
            self.started.send()
			
			if (data.count < ambiqOTARXCharacteristic.FILE_HEADER_BLOCK) {
                self.failed.send((Int(amotaStatus.APP_NOT_ENOUGH_DATA.rawValue), amotaStatus.APP_NOT_ENOUGH_DATA.title))
				return
			}
			
			let header = data.subdata(in: 0..<ambiqOTARXCharacteristic.FILE_HEADER_BLOCK)
			mHeaderPackets = mBuildFrames(data: mBuildPacket(command: otaCommand.AMOTA_CMD_FW_HEADER, data: header))

			// The file size doesn't account for the header of length FILE_HEADER_BLOCK
			mFileSize = (Int(header[11]) << 24) | (Int(header[10]) << 16) | (Int(header[9]) << 8) | Int(header[8])
						
			var currentOffset = ambiqOTARXCharacteristic.FILE_HEADER_BLOCK

			// "At the end" needs to account for the fact that the file size doesn't account for the header
			while (currentOffset < (mFileSize + ambiqOTARXCharacteristic.FILE_HEADER_BLOCK)) {
				var length = 0
				if (currentOffset + ambiqOTARXCharacteristic.DATA_BLOCK_SIZE) > (mFileSize + ambiqOTARXCharacteristic.FILE_HEADER_BLOCK) {
					length = mFileSize + ambiqOTARXCharacteristic.FILE_HEADER_BLOCK - currentOffset
				}
				else {
					length = ambiqOTARXCharacteristic.DATA_BLOCK_SIZE
				}
				
				//globals.log.v ("Current offset: \(currentOffset), length: \(length), File Size: \(mFileSize), count: \(data.count), total file size: \(mFileSize + ambiqOTARXCharacteristic.FILE_HEADER_BLOCK)")
				
				let packet = mBuildPacket(command: otaCommand.AMOTA_CMD_FW_DATA, data: data.subdata(in: currentOffset..<(currentOffset + length)))
				mDataPackets.append(mBuildFrames(data: packet))

				currentOffset = currentOffset + length
			}
			
			mState			= .HEADER
			mFrameIndex		= 0
            progress.send(0.0)
			mSendFrame(data: mHeaderPackets[mFrameIndex])
		} else {
            self.failed.send((Int(amotaStatus.APP_MISSING_OBJECTS.rawValue), amotaStatus.APP_MISSING_OBJECTS.title))
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
		globals.log.v("Cancel")
		mState = .CANCEL

        failed.send((Int(amotaStatus.APP_CANCEL.rawValue), amotaStatus.APP_CANCEL.title))
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	// This does not override any function.  Commands on RX come back as notifications
	// on TX, so I can't get the value from the RX characteristic
	//
	//--------------------------------------------------------------------------------
	func didUpdateTXValue(_ value: Data) {
		
		if (mState == .CANCEL) { return }

		if let cmd = otaCommand(rawValue: value[2]), let status = amotaStatus(rawValue: value[3]) {
			if (cmd == .AMOTA_CMD_UNKNOWN) {
				globals.log.e("Got unknown command: \(value.hexString)")
                failed.send((Int(amotaStatus.UNKNOWN_ERROR.rawValue), amotaStatus.UNKNOWN_ERROR.title))
				return
			}
			
			if (status != .SUCCESS) {
				globals.log.e("Error '\(status)': \(value.hexString)")
                failed.send((Int(status.rawValue), status.title))
				return
			}

			switch (mState) {
			case .IDLE: break

			case .HEADER:
				globals.log.v ("Offset: \(value.subdata(in: Range(4...7)).hexString)")
				let offset	= value.subdata(in: Range(4...7)).leInt32
				if (offset == 0) {
					globals.log.v("Finished the header -> send data blocks")
					mState		= .DATA
					mDataIndex	= 0
					mFrameIndex	= 0
					mSendFrame(data: mDataPackets[mDataIndex][mFrameIndex])
				}
				else {
					globals.log.e("Finished the header -> pre-existing OTA exists - do not continue!")
					mState		= .CANCEL
                    failed.send((Int(amotaStatus.APP_EXISTING_OTA.rawValue), amotaStatus.APP_EXISTING_OTA.title))
				}

			case .DATA:
				mDataIndex = mDataIndex + 1
                progress.send(Float(mDataIndex) / Float(mDataPackets.count))

				if (mDataIndex == mDataPackets.count) {
					globals.log.v("Finished the data -> send verify command")

					mState = .VERIFY
					mSendFrame(data: mBuildPacket(command: otaCommand.AMOTA_CMD_FW_VERIFY, data: nil))
				}
				else {
					mFrameIndex = 0
					mSendFrame(data: mDataPackets[mDataIndex][mFrameIndex])
				}

			case .VERIFY:
				globals.log.v("Finished the verify -> send reset command")
				
				mState = .RESET
				mSendFrame(data: mBuildPacket(command: otaCommand.AMOTA_CMD_FW_RESET, data: nil))

			case .RESET:
				globals.log.v("Done")
				mState = .DONE
				
                finished.send()

			default:
				globals.log.e ("Unknown state: \(mState)")
				mState = .CANCEL
                failed.send((Int(amotaStatus.UNKNOWN_ERROR.rawValue), amotaStatus.UNKNOWN_ERROR.title))
			}

		}
		else {
			globals.log.e ("Received an unknown command \(String(format: "0x%02X", value[2])) and/or status \(String(format: "0x%02X", value[3]))")
		}
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	override func isReady() {
		switch (mState) {
		case .IDLE: break

		case .HEADER:
			mFrameIndex = mFrameIndex + 1
			if (mFrameIndex != mHeaderPackets.count) {
				mSendFrame(data: mHeaderPackets[mFrameIndex])
			}

		case .DATA:
			mFrameIndex = mFrameIndex + 1
			if (mFrameIndex != mDataPackets[mDataIndex].count) {
				mSendFrame(data: mDataPackets[mDataIndex][mFrameIndex])
			}
			
		case .VERIFY: break
		case .RESET: break
			
		default: globals.log.e ("Unknown state: \(mState)")
		}
	}
}
