//
//  customCharacteristic.swift
//  biostrapDeviceSDK
//
//  Created by Joseph A. Bennett on 5/12/21.
//

import Foundation
import CoreBluetooth
import zlib

class customCharacteristic: Characteristic {
	
	// MARK: Enumerations
	enum commands: UInt8 {
		case writeEpoch			= 0x00
		case getAllPackets		= 0x01
		case getNextPacket		= 0x02
		case getPacketCount		= 0x03
		case validateCRC		= 0x04
		case led				= 0x10
		case enterShipMode		= 0x11
		case readEpoch			= 0x12
		case endSleep			= 0x13
		case writeID			= 0x40
		case readID				= 0x41
		case deleteID			= 0x42
		case writeAdvInterval	= 0x44
		case readAdvInterval	= 0x45
		case deleteAdvInterval	= 0x46
		case clearChargeCycle	= 0x48
		case readChargeCycle	= 0x49
		case allowPPG			= 0xf8
		case wornCheck			= 0xf9
		case logRaw				= 0xfa
		case disableWornDetect	= 0xfb
		case enableWornDetect	= 0xfc
		case startManual		= 0xfd
		case stopManual			= 0xfe
		case reset				= 0xff
	}
	
	enum notifications: UInt8 {
		case completion			= 0x00
		case dataPacket			= 0x01
		case worn				= 0x02
		case manualResult		= 0x03
		case ppgFailed			= 0x04
		case validateCRC		= 0x05
		case dataCaughtUp		= 0x06
	}
	
	enum wornResult: UInt8 {
		case broken				= 0x00
		case busy				= 0x01
		case ran				= 0x02
		
		var message: String {
			switch (self) {
			case .broken	: return "PPG cannot initialize"
			case .busy		: return "PPG is busy with another operation"
			case .ran		: return "Ran successfully"
			}
		}
	}
	
	// MARK: Callbacks
	var writeEpochComplete: ((_ successful: Bool)->())?
	var getAllPacketsComplete: ((_ successful: Bool)->())?
	var getNextPacketComplete: ((_ successful: Bool, _ packet: String)->())?
	var getPacketCountComplete: ((_ successful: Bool, _ count: Int)->())?
	var startManualComplete: ((_ successful: Bool)->())?
	var stopManualComplete: ((_ successful: Bool)->())?
	var ledComplete: ((_ successful: Bool)->())?
	var enterShipModeComplete: ((_ successful: Bool)->())?
	var writeIDComplete: ((_ successful: Bool)->())?
	var readIDComplete: ((_ successful: Bool, _ partID: String)->())?
	var deleteIDComplete: ((_ successful: Bool)->())?
	var writeAdvIntervalComplete: ((_ successful: Bool)->())?
	var readAdvIntervalComplete: ((_ successful: Bool, _ seconds: Int)->())?
	var deleteAdvIntervalComplete: ((_ successful: Bool)->())?
	var clearChargeCyclesComplete: ((_ successful: Bool)->())?
	var readChargeCyclesComplete: ((_ successful: Bool, _ cycles: Float)->())?
	var rawLoggingComplete: ((_ successful: Bool)->())?
	var allowPPGComplete: ((_ successful: Bool)->())?
	var wornCheckComplete: ((_ successful: Bool, _ type: String, _ value: Int)->())?
	var resetComplete: ((_ successful: Bool)->())?
	var readEpochComplete: ((_ successful: Bool, _ value: Int)->())?
    var manualResult: ((_ successful: Bool, _ packet: String)->())?
	var ppgFailed: ((_ code: Int)->())?
	var disableWornDetectComplete: ((_ successful: Bool)->())?
	var enableWornDetectComplete: ((_ successful: Bool)->())?
	var endSleepComplete: ((_ successful: Bool)->())?

	var dataPackets: ((_ packets: String)->())?
	var dataComplete: (()->())?
	var dataFailure: (()->())?
	
	var deviceWornStatus: ((_ isWorn: Bool)->())?
	
	internal var mDataPackets	: [biostrapDataPacket]!
	internal var mCRCOK			: Bool = true
	internal var mCRCFailCount	: Int = 0
	
	//--------------------------------------------------------------------------------
	//
	// Test Struct.  This lets things happen a certain number of times where it fails
	// until you hit the limit, then it succeeds
	//
	//--------------------------------------------------------------------------------
	struct testStruct {
		var name		: String
		var enable		: Bool
		var count		: Int
		var limit		: Int
		
		init() {
			name		= "Unknown"
			enable		= false
			count		= 0
			limit		= 2
		}
		
		init(name: String, enable: Bool, limit: Int) {
			self.name	= name
			self.enable	= enable
			self.count	= 0
			self.limit	= limit
		}
		
		mutating func check() -> Bool {
			if (enable == false) {
				//log?.v ("\(name): Not testing - allow")
				return true
			}
			
			count = count + 1
			if (count >= limit) {
				log?.v ("\(name): At limit - allow")
				count	= 0
				return true
			}
			else {
				log?.v ("\(name): Not at limit - disallow \(count) != \(limit)")
				return false
			}
		}
	}
	
	internal var mCRCIgnoreTest				: testStruct
	internal var mCRCFailTest				: testStruct
	
	//--------------------------------------------------------------------------------
	//
	// Constructor
	//
	//--------------------------------------------------------------------------------
	override init(_ peripheral: CBPeripheral, characteristic: CBCharacteristic) {
		mCRCIgnoreTest	= testStruct(name: "CRC Ignore", enable: false, limit: 3)
		mCRCFailTest	= testStruct(name: "CRC Fail", enable: false, limit: 3)
		
		mCRCOK			= false
		mCRCFailCount	= 0

		super.init(peripheral, characteristic: characteristic)
		
		mDataPackets = [biostrapDataPacket]()
		
	}
	
	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func writeEpoch(_ newEpoch: Int) {
		log?.v("\(pID): \(newEpoch)")

		if let peripheral = pPeripheral, let characteristic = pCharacteristic {
			var data = Data()
			data.append(commands.writeEpoch.rawValue)
			data.append(UInt8((newEpoch >>  0) & 0xff))
			data.append(UInt8((newEpoch >>  8) & 0xff))
			data.append(UInt8((newEpoch >> 16) & 0xff))
			data.append(UInt8((newEpoch >> 24) & 0xff))

			peripheral.writeValue(data, for: characteristic, type: .withResponse)
		}
		else { self.writeEpochComplete?(false) }
	}
	
	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func readEpoch() {
		log?.v("\(pID)")

		if let peripheral = pPeripheral, let characteristic = pCharacteristic {
			var data = Data()
			data.append(commands.readEpoch.rawValue)

			peripheral.writeValue(data, for: characteristic, type: .withResponse)
		}
		else { self.readEpochComplete?(false, 0) }
	}
	
	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func endSleep() {
		log?.v("\(pID)")

		if let peripheral = pPeripheral, let characteristic = pCharacteristic {
			var data = Data()
			data.append(commands.endSleep.rawValue)

			peripheral.writeValue(data, for: characteristic, type: .withResponse)
		}
		else { self.endSleepComplete?(false) }
	}
	
	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	internal func mSimpleCommand(_ command: commands) -> Bool {
		if let peripheral = pPeripheral, let characteristic = pCharacteristic {
			var data = Data()
			data.append(command.rawValue)
			
			peripheral.writeValue(data, for: characteristic, type: .withResponse)
			return (true)
		}
		else { return false }
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func getNextPacket() {
		log?.v("\(pID)")

		if (!mSimpleCommand(.getNextPacket)) { self.getNextPacketComplete?(false, "") }
	}
	
	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func getAllPackets() {
		log?.v("\(pID)")

		if (!mSimpleCommand(.getAllPackets)) { self.getAllPacketsComplete?(false) }
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func getPacketCount() {
		log?.v("\(pID)")

		if (!mSimpleCommand(.getPacketCount)) { self.getPacketCountComplete?(false, 0) }
	}
	
	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func disableWornDetect() {
		log?.v("\(pID)")

		if (!mSimpleCommand(.disableWornDetect)) { self.disableWornDetectComplete?(false) }
	}
	
	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func enableWornDetect() {
		log?.v("\(pID)")

		if (!mSimpleCommand(.enableWornDetect)) { self.enableWornDetectComplete?(false) }
	}
	
	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	#if UNIVERSAL || LIVOTAL
	func startManual(_ algorithms: livotalAlgorithmConfiguration) {
		log?.v("\(pID)")
		
		if let peripheral = pPeripheral, let characteristic = pCharacteristic {
			var data = Data()
			data.append(commands.startManual.rawValue)
			data.append(algorithms.commandByte)

			peripheral.writeValue(data, for: characteristic, type: .withResponse)
		}
		else { self.startManualComplete?(false) }
	}
	#endif

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func stopManual() {
		log?.v("\(pID)")
		
		if (!mSimpleCommand(.stopManual)) { self.stopManualComplete?(false) }
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	#if UNIVERSAL || LIVOTAL
	func livotalLED(red: Bool, green: Bool, blue: Bool, blink: Bool, seconds: Int) {
		log?.v("\(pID): Red: \(red), Green: \(green), Blue: \(blue), Blink: \(blink), Seconds: \(seconds)")
		
		if let peripheral = pPeripheral, let characteristic = pCharacteristic {
			var data = Data()
			data.append(commands.led.rawValue)
			data.append(red ? 0x01 : 0x00)		// Red
			data.append(green ? 0x01 : 0x00)	// Green
			data.append(blue ? 0x01 : 0x00)		// Blue
			data.append(blink ? 0x01 : 0x00)	// Blink
			data.append(UInt8(seconds & 0xff))	// Seconds

			peripheral.writeValue(data, for: characteristic, type: .withResponse)
		}
		else { self.ledComplete?(false) }
	}
	#endif
	
	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	#if UNIVERSAL || ETHOS
	func ethosLED(red: Int, green: Int, blue: Int, mode: biostrapDeviceSDK.ethosLEDMode, seconds: Int, percent: Int) {
		log?.v("\(pID): Red: \(String(format: "0x%02X", red)), Green: \(String(format: "0x%02X", green)), Blue: \(String(format: "0x%02X", blue)), Mode: \(mode.title), Seconds: \(seconds), Percent: \(percent)")
		
		if let peripheral = pPeripheral, let characteristic = pCharacteristic {
			var data = Data()
			data.append(commands.led.rawValue)
			data.append(UInt8(red & 0xff))		// Red
			data.append(UInt8(green & 0xff))	// Green
			data.append(UInt8(blue & 0xff))		// Blue
			data.append(UInt8(mode.value))		// Mode
			data.append(UInt8(seconds & 0xff))	// Seconds
			data.append(UInt8(percent & 0xff))	// Percent

			peripheral.writeValue(data, for: characteristic, type: .withResponse)
		}
		else { self.ledComplete?(false) }
	}
	#endif
		
	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func enterShipMode() {
		log?.v("\(pID)")
		
		if let peripheral = pPeripheral, let characteristic = pCharacteristic {
			var data = Data()
			data.append(commands.enterShipMode.rawValue)
			peripheral.writeValue(data, for: characteristic, type: .withResponse)
		}
		else { self.enterShipModeComplete?(false) }
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func writeID(_ partID: String) {
		log?.v("\(pID): \(partID)")
		
		if let peripheral = pPeripheral, let characteristic = pCharacteristic {
			var data = Data()
			data.append(commands.writeID.rawValue)
			data.append(contentsOf: [UInt8](partID.utf8))
			
			log?.v ("\(data.hexString)")

			peripheral.writeValue(data, for: characteristic, type: .withResponse)
		}
		else { self.writeIDComplete?(false) }
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func readID() {
		log?.v("\(pID)")
		
		if let peripheral = pPeripheral, let characteristic = pCharacteristic {
			var data = Data()
			data.append(commands.readID.rawValue)
			peripheral.writeValue(data, for: characteristic, type: .withResponse)
		}
		else { self.readIDComplete?(false, "") }
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func deleteID() {
		log?.v("\(pID)")
		
		if let peripheral = pPeripheral, let characteristic = pCharacteristic {
			var data = Data()
			data.append(commands.deleteID.rawValue)
			peripheral.writeValue(data, for: characteristic, type: .withResponse)
		}
		else { self.deleteIDComplete?(false) }
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func writeAdvInterval(_ seconds: Int) {
		log?.v("\(pID): \(seconds)")
		
		if let peripheral = pPeripheral, let characteristic = pCharacteristic {
			var data = Data()
			data.append(commands.writeAdvInterval.rawValue)
			data.append(contentsOf: seconds.leData32)
			
			log?.v ("\(data.hexString)")

			peripheral.writeValue(data, for: characteristic, type: .withResponse)
		}
		else { self.writeAdvIntervalComplete?(false) }
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func readAdvInterval() {
		log?.v("\(pID)")
		
		if let peripheral = pPeripheral, let characteristic = pCharacteristic {
			var data = Data()
			data.append(commands.readAdvInterval.rawValue)
			peripheral.writeValue(data, for: characteristic, type: .withResponse)
		}
		else { self.readAdvIntervalComplete?(false, 0) }
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func deleteAdvInterval() {
		log?.v("\(pID)")
		
		if let peripheral = pPeripheral, let characteristic = pCharacteristic {
			var data = Data()
			data.append(commands.deleteAdvInterval.rawValue)
			peripheral.writeValue(data, for: characteristic, type: .withResponse)
		}
		else { self.deleteAdvIntervalComplete?(false) }
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func clearChargeCycles() {
		log?.v("\(pID)")
		
		if let peripheral = pPeripheral, let characteristic = pCharacteristic {
			var data = Data()
			data.append(commands.clearChargeCycle.rawValue)
			
			peripheral.writeValue(data, for: characteristic, type: .withResponse)
		}
		else { self.clearChargeCyclesComplete?(false) }
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func readChargeCycles() {
		log?.v("\(pID)")
		
		if let peripheral = pPeripheral, let characteristic = pCharacteristic {
			var data = Data()
			data.append(commands.readChargeCycle.rawValue)
			peripheral.writeValue(data, for: characteristic, type: .withResponse)
		}
		else { self.readChargeCyclesComplete?(false, 0.0) }
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func allowPPG(_ allow: Bool) {
		log?.v("\(pID)")
		
		if let peripheral = pPeripheral, let characteristic = pCharacteristic {
			var data = Data()
			data.append(commands.allowPPG.rawValue)
			data.append(allow ? 0x01 : 0x00)
			peripheral.writeValue(data, for: characteristic, type: .withResponse)
		}
		else { self.allowPPGComplete?(false) }
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func wornCheck() {
		log?.v("\(pID)")
		
		if let peripheral = pPeripheral, let characteristic = pCharacteristic {
			var data = Data()
			data.append(commands.wornCheck.rawValue)
			peripheral.writeValue(data, for: characteristic, type: .withResponse)
		}
		else { self.wornCheckComplete?(false, "No device", 0) }
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func rawLogging(_ enable: Bool) {
		log?.v("\(pID): \(enable)")
		
		if let peripheral = pPeripheral, let characteristic = pCharacteristic {
			var data = Data()
			data.append(commands.logRaw.rawValue)
			data.append(enable ? 0x01 : 0x00)
			peripheral.writeValue(data, for: characteristic, type: .withResponse)
		}
		else { self.rawLoggingComplete?(false) }
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	func reset() {
		log?.v("\(pID)")

		if (!mSimpleCommand(.reset)) { self.resetComplete?(false) }
	}
	
	//--------------------------------------------------------------------------------
	// Function Name: Validate CRC
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	internal func mValidateCRC(_ valid: Bool) {
		log?.v("\(pID): \(valid)")
		
		if (valid == false) {
			mCRCFailCount	= mCRCFailCount + 1
			if (mCRCFailCount == 10) { dataFailure?() }
		}
		else { mCRCFailCount	= 0 }
		
		if let peripheral = pPeripheral, let characteristic = pCharacteristic {
			var data = Data()
			data.append(commands.validateCRC.rawValue)
			data.append(valid ? 0x01 : 0x00)
			peripheral.writeValue(data, for: characteristic, type: .withResponse)
		}
		else {
			log?.e ("I can't run the validate CRC command.  I don't know what to do here")
		}
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	internal func mParseSinglePacket(_ data: Data, index: Int) -> (Bool, packetType, biostrapDataPacket) {
		if let type = packetType(rawValue: data[index]) {
			switch (type) {
			case .ppg,
				 .activity,
				 .steps,
				 .temp,
				 .rawAccelFifoCount,
				 .rawAccel,
				 .rawPPGIR,
				 .rawPPGRed,
				 .rawPPGGreen,
				 .rawPPGProximity,
				 .rawPPGFifoCount,
				 .worn,
				 .ppg_failed,
				 .battery,
				 .sleep:
				let packetData = data.subdata(in: Range((index)...(index + type.length - 1)))
				
				switch (type) {
				case .ppg,
					 .activity,
					 .steps,
					 .temp,
					 .worn,
					 .ppg_failed,
					 .sleep,
					 .battery,
					 .rawPPGFifoCount,
					 .rawAccelFifoCount,
					 .rawPPGProximity,
					 .rawPPGRed,
					 .rawPPGGreen,
					 .rawPPGIR,
					 .rawAccel:				return (true, type, biostrapDataPacket(packetData))
				default:
					log?.e ("\(type.title) (shouldn't be here): \(packetData.hexString)")
					return (false, .unknown, biostrapDataPacket())
				}
			case .diagnostic:
				let length = Int(data[index + 1]) + 1
				
				if ((index + length) <= data.count) {
					let packetData = data.subdata(in: Range(index...(index + length - 1)))
					return (true, type, biostrapDataPacket(packetData))
				}
				else {
					log?.v ("\(type.title): Remaining bytes: \(data.subdata(in: Range(index...(data.count - 1))).hexString)")
					return (false, .unknown, biostrapDataPacket())
				}

			case .unknown:
				log?.v ("\(type.title): Remaining bytes: \(data.subdata(in: Range(index...(data.count - 1))).hexString)")
				return (false, type, biostrapDataPacket())
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
		log?.v ("\(pID): Data: \(data.hexString)")
		
		var index = 0
		var dataPackets = [biostrapDataPacket]()
		
		while (index < data.count) {
			let (found, type, packet) = mParseSinglePacket(data, index: index)

			if (found) {
				if (type == .diagnostic) {
					index = index + packet.diagnostic_data.count
				}
				else {
					index = index + type.length
				}
				if (type != .unknown) { dataPackets.append(packet) }
			}
			else {
				index = index + type.length
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
	internal func mProcessUpdateValue(_ data: Data) {
		
		if let response = notifications(rawValue: data[0]) {
			switch (response) {
			case .completion:
				if (data.count >= 3) {
					if let command = commands(rawValue: data[1]) {
						let successful = (data[2] == 0x01)
						log?.v ("\(pID): Got completion for '\(command)' with \(successful) status: Bytes = \(data.hexString)")
						switch (command) {
						case .writeEpoch	: self.writeEpochComplete?(successful)
						case .readEpoch		:
							if (data.count == 7) {
								let epoch = data.subdata(in: Range(3...6)).leInt
								self.readEpochComplete?(successful, epoch)
							}
							else {
								self.readEpochComplete?(false, 0)
							}
						case .endSleep		: self.endSleepComplete?(successful)
						case .getAllPackets	:
							mCRCOK	= true
							self.getAllPacketsComplete?(successful)
						case .getNextPacket :
							if (successful) {
								let (found, _, packet) = mParseSinglePacket(data, index: 3)
								
								if (found) {
									do {
										let jsonData = try JSONEncoder().encode(packet)
										if let jsonString = String(data: jsonData, encoding: .utf8) {
											self.getNextPacketComplete?(true, jsonString)
										}
										else { self.getNextPacketComplete?(false, "") }
									}
									catch { self.getNextPacketComplete?(false, "") }
								}
								else {
									self.getNextPacketComplete?(false, "")
								}
							}
							else {
								self.getNextPacketComplete?(false, "")
							}
						case .getPacketCount:
							if (successful) {
								if (data.count == 7) {
									let count = data.subdata(in: Range(3...6)).leInt
									self.getPacketCountComplete?(true, count)
								}
								else {
									self.getPacketCountComplete?(false, 0)
								}
							}
							else {
								self.getPacketCountComplete?(false, 0)
							}
						case .disableWornDetect	: self.disableWornDetectComplete?(successful)
						case .enableWornDetect	: self.enableWornDetectComplete?(successful)
						case .startManual		: self.startManualComplete?(successful)
						case .stopManual		: self.stopManualComplete?(successful)
						case .led				: self.ledComplete?(successful)
						case .enterShipMode		: self.enterShipModeComplete?(successful)
						case .writeID			: self.writeIDComplete?(successful)
						case .readID			:
							if (data.count == 19) {
								let partID = String(decoding: data.subdata(in: Range(3...18)), as: UTF8.self)
								let nulls = CharacterSet.whitespacesAndNewlines.union(CharacterSet(["\0"]))
								let stringID = partID.trimmingCharacters(in: nulls)
								self.readIDComplete?(successful, stringID)
							}
							else {
								self.readIDComplete?(false, "")
							}
						case .deleteID			: self.deleteIDComplete?(successful)
						case .writeAdvInterval	: self.writeAdvIntervalComplete?(successful)
						case .readAdvInterval	:
							if (data.count == 19) {
								log?.v ("\(response): Data: \(data.hexString)")
								let seconds = data.subdata(in: Range(3...6)).leInt
								self.readAdvIntervalComplete?(successful, seconds)
							}
							else {
								self.readAdvIntervalComplete?(false, 0)
							}
						case .deleteAdvInterval	: self.deleteAdvIntervalComplete?(successful)
						case .clearChargeCycle	: self.clearChargeCyclesComplete?(successful)
						case .readChargeCycle	:
							if (data.count == 19) {
								log?.v ("\(response): Data: \(data.hexString)")
								let cycles = data.subdata(in: Range(3...6)).leFloat
								self.readChargeCyclesComplete?(successful, cycles)
							}
							else {
								self.readChargeCyclesComplete?(false, 0.0)
							}
						case .allowPPG			: self.allowPPGComplete?(successful)
						case .wornCheck			:
							if (data.count == 8) {
								if let code = wornResult(rawValue: data[3]) {
									let value = data.subdata(in: Range(4...7)).leInt
								
									if code == .ran {
										self.wornCheckComplete?(true, code.message, value)
									}
									else {
										self.wornCheckComplete?(false, code.message, 0)
									}
								}
								else {
									self.wornCheckComplete?(false, "Unknown code: \(String(format: "0x%02X", data[3]))", 0)
								}
							}
						case .logRaw			: self.rawLoggingComplete?(successful)
						case .reset				: self.resetComplete?(successful)
						case .validateCRC		:
							log?.v ("Got Validate CRC completion: \(data.hexString)")
						}
					}
					else {
						log?.e ("\(pID): Unknown command: \(data.hexString)")
					}
				}
				else {
					log?.e ("\(pID): Incorrect length for completion: \(data.hexString)")
				}
				
			case .dataPacket:
				if (data.count > 1) {	// Accounts for header byte
					let dataPackets = self.mParsePackets(data.subdata(in: Range(1...(data.count - 1))))
					mDataPackets.append(contentsOf: dataPackets)
				}
				else {
					log?.e ("\(pID): Bad data length for data packet: \(data.hexString)")
					mCRCOK	= false
				}
				
			case .worn:
				log?.v ("Worn State: \(data[1])")
				if      (data[1] == 0x00) { deviceWornStatus?(false) }
				else if (data[1] == 0x01) { deviceWornStatus?(true)  }
				else {
					log?.e ("Cannot parse worn status: \(data[1])")
				}
				
			case .manualResult:
				log?.v ("Manual Result Complete: \(data.hexString)")
				let (_, type, packet) = mParseSinglePacket(data, index: 1)
				if (type == .ppg) {
					do {
						let jsonData = try JSONEncoder().encode(packet)
						if let jsonString = String(data: jsonData, encoding: .utf8) {
							self.manualResult?(true, jsonString)
						}
						else { self.manualResult?(false, "") }
					}
					catch { self.manualResult?(false, "") }
				}
				else { self.manualResult?(false, "") }
				
			case .ppgFailed:
				log?.v ("PPG Failed: \(data.hexString)")
				if (data.count > 1) {
					self.ppgFailed?(Int(data[1]))
					
				}
				else {
					self.ppgFailed?(999)
				}
				
			case .dataCaughtUp:
				log?.v ("\(response)")
				self.dataComplete?()
				
			case .validateCRC:
				log?.v ("\(response)")
				let allowResponse		= mCRCIgnoreTest.check()
				let allowGoodResponse	= mCRCFailTest.check()
										
				if (allowResponse) {
					if (allowGoodResponse) {
						if (mCRCOK == true) {
							log?.v ("Validate CRC Requested and they've passed - let received packets through")
							
							if (mDataPackets.count > 0) {
								do {
									let jsonData = try JSONEncoder().encode(mDataPackets)
									if let jsonString = String(data: jsonData, encoding: .utf8) {
									self.dataPackets?(jsonString)
								}
									else { log?.e ("Cannot make string from json data") }
								}
								catch { log?.e ("Cannot make JSON data") }
						   }
						}
						else {
							log?.v ("Validate CRC Requested and there was at least one failed CRC - do not let packets through")
						}
					}
					else {
						mCRCOK	= false
					}
												
					DispatchQueue.main.async {
						self.mValidateCRC(self.mCRCOK)
						self.mDataPackets.removeAll()
						self.mCRCOK	= true
					}
				}
			}
		}
		else {
			log?.e ("\(pID): Unknown update: \(data.hexString)")
		}
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
				
				// Packets have to be at least a header + CRC.  If not, do not parse
				if (data.count >= 4) {
					// Get the CRC.  Only process the packet if the CRC is good.
					let crc_received	= data.subdata(in: Range((data.count - 4)...(data.count - 1))).leInt
					var input_bytes 	= data.subdata(in: Range(0...(data.count - 5))).bytes
					let crc_calculated	= crc32(uLong(0), &input_bytes, uInt(input_bytes.count))

					if (crc_received == crc_calculated) {
						mProcessUpdateValue(data.subdata(in: Range(0...(data.count - 5))))
					}
					else {
						log?.e ("Packet CRC Error! CRC : \(String(format:"0x%08X", crc_received)): \(String(format:"0x%08X", crc_calculated))")
						return
					}
				}
				else {
					log?.e ("Cannot calculate packet CRC: Not enough data.  Length = \(data.count): \(data.hexString)")
					return
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
