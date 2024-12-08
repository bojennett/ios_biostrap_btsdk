//
//  customStreamingCharacteristic.swift
//  biostrapDeviceSDK
//
//  Created by Joseph A. Bennett on 4/19/23.
//

import Foundation
import Combine

class customStreamingCharacteristic: Characteristic {
	
	#if UNIVERSAL
	var type:	biostrapDeviceSDK.biostrapDeviceType	= .unknown
	#endif

    let deviceWornStatus = PassthroughSubject<Bool, Never>()
    let deviceChargingStatus = PassthroughSubject<(Bool, Bool, Bool), Never>()
    let ppgMetrics = PassthroughSubject<(Bool, String), Never>()
    let ppgFailed = PassthroughSubject<Int, Never>()
    let manufacturingTestResult = PassthroughSubject<(Bool, String), Never>()
    let streamingPacket = PassthroughSubject<String, Never>()
    let dataAvailable = PassthroughSubject<Void, Never>()

    let endSleepStatus = PassthroughSubject<Bool, Never>()
    let buttonClicked = PassthroughSubject<Int, Never>()

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
			case .completion: globals.log.e ("\(pID): Should not get '\(response)' on this characteristic!")
			case .dataPacket: globals.log.e ("\(pID): Should not get '\(response)' on this characteristic!")
			case .dataCaughtUp: globals.log.e ("\(pID): Should not get '\(response)' on this characteristic!")
			case .validateCRC: globals.log.e ("\(pID): Should not get '\(response)' on this characteristic!")

			case .worn:
                if      (data[1] == 0x00) { deviceWornStatus.send(false) }
                else if (data[1] == 0x01) { deviceWornStatus.send(true)  }
				else {
					globals.log.e ("\(pID): Cannot parse worn status: \(data[1])")
				}
				
			case .ppg_metrics:
                let (_, type, packet) = pParseSinglePacket(data, index: 1, offset: 0)
				if (type == .ppg_metrics) {
					do {
						let jsonData = try JSONEncoder().encode(packet)
						if let jsonString = String(data: jsonData, encoding: .utf8) {
                            self.ppgMetrics.send((true, jsonString))
						}
                        else { self.ppgMetrics.send((false, "")) }
					}
                    catch { self.ppgMetrics.send((false, "")) }
				}
				
			case .ppgFailed:
				if (data.count > 1) {
                    self.ppgFailed.send(Int(data[1]))
				}
				else {
                    self.ppgFailed.send(999)
				}
								
			case .endSleepStatus:
				if (data.count == 2) {
					let hasSleep	= data[1] == 0x01 ? true : false
                    self.endSleepStatus.send(hasSleep)
				}
				else {
					globals.log.e ("\(pID): Cannot parse 'endSleepStatus': \(data.hexString)")
				}
				
			case .buttonResponse:
				if (data.count == 2) {
					let presses	= Int(data[1])
                    self.buttonClicked.send(presses)
				}
				else {
					globals.log.e ("\(pID): Cannot parse 'buttonResponse': \(data.hexString)")
				}
								
			case .manufacturingTest:
				#if ALTER
				if (data.count == 3) {
					let testResult = alterManufacturingTestResult(data.subdata(in: Range(1...2)))
					do {
						let jsonData = try JSONEncoder().encode(testResult)
						if let jsonString = String(data: jsonData, encoding: .utf8) {
                            self.manufacturingTestResult.send((true, jsonString))
						}
						else {
							globals.log.e ("\(pID): Result jsonString Failed")
                            self.manufacturingTestResult.send((false, ""))
						}
					}
					catch {
						globals.log.e ("\(pID): Result jsonData Failed")
                        self.manufacturingTestResult.send((false, ""))
					}
				}
				else {
                    self.manufacturingTestResult.send((false, ""))
				}
				#endif
				
				#if KAIROS
				if (data.count == 3) {
					let testResult = kairosManufacturingTestResult(data.subdata(in: Range(1...2)))
					do {
						let jsonData = try JSONEncoder().encode(testResult)
						if let jsonString = String(data: jsonData, encoding: .utf8) {
                            self.manufacturingTestResult.send((true, jsonString))
						}
						else {
							globals.log.e ("\(pID): Result jsonString Failed")
                            self.manufacturingTestResult.send((false, ""))
						}
					}
					catch {
						globals.log.e ("\(pID): Result jsonData Failed")
                        self.manufacturingTestResult.send((false, ""))
					}
				}
				else {
                    self.manufacturingTestResult.send((false, ""))
				}
				#endif
				
				#if UNIVERSAL
				switch (type) {
				case .alter		:
					if (data.count == 3) {
						let testResult = alterManufacturingTestResult(data.subdata(in: Range(1...2)))
						do {
							let jsonData = try JSONEncoder().encode(testResult)
							if let jsonString = String(data: jsonData, encoding: .utf8) {
                                self.manufacturingTestResult.send((true, jsonString))
							}
							else {
								globals.log.e ("\(pID): Result jsonString Failed")
                                self.manufacturingTestResult.send((false, ""))
							}
						}
						catch {
							globals.log.e ("\(pID): Result jsonData Failed")
                            self.manufacturingTestResult.send((false, ""))
						}
					}
					else {
                        self.manufacturingTestResult.send((false, ""))
					}
					
				case .kairos		:
					if (data.count == 3) {
						let testResult = kairosManufacturingTestResult(data.subdata(in: Range(1...2)))
						do {
							let jsonData = try JSONEncoder().encode(testResult)
							if let jsonString = String(data: jsonData, encoding: .utf8) {
                                self.manufacturingTestResult.send((true, jsonString))
							}
							else {
								globals.log.e ("\(pID): Result jsonString Failed")
                                self.manufacturingTestResult.send((false, ""))
							}
						}
						catch {
							globals.log.e ("\(pID): Result jsonData Failed")
                            self.manufacturingTestResult.send((false, ""))
						}
					}
					else {
                        self.manufacturingTestResult.send((false, ""))
					}
					
				case .unknown	: break
				}
			#endif
				
			case .charging:
				let on_charger	= (data[1] == 0x01)
				let charging	= (data[2] == 0x01)
				let error		= (data[3] == 0x01)
				
                self.deviceChargingStatus.send((charging, on_charger, error))
				
			case .streamPacket:
				let length = Int(data[2])
				var packet = biostrapStreamingPacket()
				
				if ((length + 1) <= data.count) {
					packet = biostrapStreamingPacket(data.subdata(in: Range(1...length)))
				}
				else {
					packet.type				= .unknown
					packet.raw_data_string	= data.hexString.replacingOccurrences(of: "[ ", with: "").replacingOccurrences(of: " ]", with: "")

					globals.log.e ("\(pID): Bad streaming packet: \(data.hexString)")
				}
				
				do {
					let jsonData = try JSONEncoder().encode(packet)
					if let jsonString = String(data: jsonData, encoding: .utf8) {
                        self.streamingPacket.send(jsonString)
					}
					else { globals.log.e ("\(pID): Cannot make string from json data") }
				}
				catch { globals.log.e ("\(pID): Cannot make JSON data") }
				
            case .dataAvailable: dataAvailable.send()
			}
		}
		else {
			globals.log.e ("\(pID): Unknown update: \(data.hexString)")
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
				mProcessUpdateValue(data.subdata(in: Range(0...(data.count - 5))))
			}
			else {
				globals.log.e ("\(pID): Missing data")
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
		configured	= true
	}

}
