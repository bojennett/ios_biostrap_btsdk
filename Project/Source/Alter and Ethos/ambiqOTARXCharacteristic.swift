//
//  ambiqOTARXCharacteristic.swift
//  AmbiqOTATest
//
//  Created by Joseph Bennett on 9/20/21.
//

import Foundation
import CoreBluetooth

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
	
	// Lambdas
	var started		: (()->())?
	var finished	: (()->())?
	var failed		: ((_ code: Int, _ message: String)->())?
	var progress	: ((_ percentage: Float)->())?
	
	internal static let DATA_BLOCK_SIZE		= 512
	internal static let BLUETOOTH_MTU_SIZE	= 20
	internal static let CRC_SIZE			= 4
	internal static let HEADER_SIZE			= 3
	internal static let FILE_HEADER_BLOCK	= 48

	internal var mFileSize		= 0

	internal var mDataPackets	: [[Data]]	// Data blocks with sub-frames
	internal var mHeaderPackets	: [Data]	// Header with sub-frames
	internal var mDataIndex		: Int
	internal var mFrameIndex	: Int
	internal var mState			: state

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
		
		while (index < data.count) {
			var frameLength: Int
			if (data.count - index > ambiqOTARXCharacteristic.BLUETOOTH_MTU_SIZE) {
				frameLength	= ambiqOTARXCharacteristic.BLUETOOTH_MTU_SIZE
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
		if let peripheral = pPeripheral, let characteristic = pCharacteristic {
			DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(100), execute: {
				peripheral.writeValue(data, for: characteristic, type: .withoutResponse)
			})
		}
		else {
			log?.e("Data write not successful: \(data.hexString)")
		}
	}

	//--------------------------------------------------------------------------------
	//
	// Constructor
	//
	//--------------------------------------------------------------------------------
	override init(_ peripheral: CBPeripheral, characteristic: CBCharacteristic) {
		mState			= .IDLE
		mDataIndex		= 0
		mFrameIndex		= 0

		mHeaderPackets	= [Data]()
		mDataPackets	= [[Data]]()

		super.init (peripheral, characteristic: characteristic)

		pConfigured		= true
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
			self.started?()
			
			if (data.count < ambiqOTARXCharacteristic.FILE_HEADER_BLOCK) {
				self.failed?(Int(amotaStatus.APP_NOT_ENOUGH_DATA.rawValue), amotaStatus.APP_NOT_ENOUGH_DATA.title)
				return
			}
			
			let header = data.subdata(in: 0..<ambiqOTARXCharacteristic.FILE_HEADER_BLOCK)
						
			mFileSize = (Int(header[11]) << 24) | (Int(header[10]) << 16) | (Int(header[9]) << 8) | Int(header[8])
			mHeaderPackets = mBuildFrames(data: mBuildPacket(command: otaCommand.AMOTA_CMD_FW_HEADER, data: header))
			
			var currentOffset = ambiqOTARXCharacteristic.FILE_HEADER_BLOCK
			while (currentOffset < mFileSize) {				
				var length = 0
				if (currentOffset + ambiqOTARXCharacteristic.FILE_HEADER_BLOCK + ambiqOTARXCharacteristic.DATA_BLOCK_SIZE) > mFileSize {
					length = mFileSize + ambiqOTARXCharacteristic.FILE_HEADER_BLOCK - currentOffset
				}
				else {
					length = ambiqOTARXCharacteristic.DATA_BLOCK_SIZE
				}
				
				let packet = mBuildPacket(command: otaCommand.AMOTA_CMD_FW_DATA, data: data.subdata(in: currentOffset..<(currentOffset + length)))
				mDataPackets.append(mBuildFrames(data: packet))

				currentOffset = currentOffset + length
			}
			
			mState			= .HEADER
			mFrameIndex		= 0
			progress?(0.0)
			mSendFrame(data: mHeaderPackets[mFrameIndex])
		}
		else {
			self.failed?(Int(amotaStatus.APP_MISSING_OBJECTS.rawValue), amotaStatus.APP_MISSING_OBJECTS.title)
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
		log?.v("Cancel")
		mState = .CANCEL

		failed?(Int(amotaStatus.APP_CANCEL.rawValue), amotaStatus.APP_CANCEL.title)
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
				log?.e("Got unknown command: \(value.hexString)")
				failed?(Int(amotaStatus.UNKNOWN_ERROR.rawValue), amotaStatus.UNKNOWN_ERROR.title)
				return
			}
			
			if (status != .SUCCESS) {
				log?.e("Error '\(status)': \(value.hexString)")
				failed?(Int(status.rawValue), status.title)
				return
			}

			switch (mState) {
			case .IDLE: break

			case .HEADER:
				log?.v ("Offset: \(value.subdata(in: Range(4...7)).hexString)")
				let offset	= value.subdata(in: Range(4...7)).leInt32
				if (offset == 0) {
					log?.v("Finished the header -> send data blocks")
					mState		= .DATA
					mDataIndex	= 0
					mFrameIndex	= 0
					mSendFrame(data: mDataPackets[mDataIndex][mFrameIndex])
				}
				else {
					log?.e("Finished the header -> pre-existing OTA exists - do not continue!")
					mState		= .CANCEL
					failed?(Int(amotaStatus.APP_EXISTING_OTA.rawValue), amotaStatus.APP_EXISTING_OTA.title)
				}

			case .DATA:
				mDataIndex = mDataIndex + 1
				progress?(Float(mDataIndex) / Float(mDataPackets.count))

				if (mDataIndex == mDataPackets.count) {
					log?.v("Finished the data -> send verify command")

					mState = .VERIFY
					mSendFrame(data: mBuildPacket(command: otaCommand.AMOTA_CMD_FW_VERIFY, data: nil))
				}
				else {
					mFrameIndex = 0
					mSendFrame(data: mDataPackets[mDataIndex][mFrameIndex])
				}

			case .VERIFY:
				log?.v("Finished the verify -> send reset command")
				
				mState = .RESET
				mSendFrame(data: mBuildPacket(command: otaCommand.AMOTA_CMD_FW_RESET, data: nil))

			case .RESET:
				log?.v("Done")
				mState = .DONE
				
				finished?()

			default:
				log?.e ("Unknown state: \(mState)")
				mState = .CANCEL
				self.failed?(Int(amotaStatus.UNKNOWN_ERROR.rawValue), amotaStatus.UNKNOWN_ERROR.title)
			}

		}
		else {
			log?.e ("Received an unknown command \(String(format: "0x%02X", value[2])) and/or status \(String(format: "0x%02X", value[3]))")
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
			
		default: log?.e ("Unknown state: \(mState)")
		}
	}
}
