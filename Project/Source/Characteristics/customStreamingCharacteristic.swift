//
//  customStreamingCharacteristic.swift
//  biostrapDeviceSDK
//
//  Created by Joseph A. Bennett on 4/19/23.
//

import Foundation

class customStreamingCharacteristic: Characteristic {
	
	#if UNIVERSAL
	var type:	biostrapDeviceSDK.biostrapDeviceType	= .unknown
	#endif

	var deviceWornStatus: ((_ isWorn: Bool)->())?
	var deviceChargingStatus: ((_ charging: Bool, _ on_charger: Bool, _ error: Bool)->())?
	var ppgMetrics: ((_ successful: Bool, _ packet: String)->())?
	var ppgFailed: ((_ code: Int)->())?
	var manufacturingTestResult: ((_ valid: Bool, _ result: String)->())?

	#if UNIVERSAL || ALTER || KAIROS || ETHOS
	var endSleepStatus: ((_ hasSleep: Bool)->())?
	var buttonClicked: ((_ presses: Int)->())?
	#endif

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	//
	//
	//--------------------------------------------------------------------------------
	internal func mProcessUpdateValue(_ data: Data) {
		log?.v ("\(pID): \(data.hexString)")
		if let response = notifications(rawValue: data[0]) {
			switch (response) {
			case .completion: log?.e ("\(pID): Should not get '\(response)' on this characteristic!")
			case .dataPacket: log?.e ("\(pID): Should not get '\(response)' on this characteristic!")
			case .dataCaughtUp: log?.e ("\(pID): Should not get '\(response)' on this characteristic!")
			case .validateCRC: log?.e ("\(pID): Should not get '\(response)' on this characteristic!")

			case .worn:
				if      (data[1] == 0x00) { deviceWornStatus?(false) }
				else if (data[1] == 0x01) { deviceWornStatus?(true)  }
				else {
					log?.e ("\(pID): Cannot parse worn status: \(data[1])")
				}
				
			case .ppg_metrics:
				let (_, type, packet) = pParseSinglePacket(data, index: 1)
				if (type == .ppg_metrics) {
					do {
						let jsonData = try JSONEncoder().encode(packet)
						if let jsonString = String(data: jsonData, encoding: .utf8) {
							self.ppgMetrics?(true, jsonString)
						}
						else { self.ppgMetrics?(false, "") }
					}
					catch { self.ppgMetrics?(false, "") }
				}
				
			case .ppgFailed:
				if (data.count > 1) {
					self.ppgFailed?(Int(data[1]))
				}
				else {
					self.ppgFailed?(999)
				}
								
			#if UNIVERSAL || ALTER || KAIROS || ETHOS
			case .endSleepStatus:
				if (data.count == 2) {
					let hasSleep	= data[1] == 0x01 ? true : false
					self.endSleepStatus?(hasSleep)
				}
				else {
					log?.e ("\(pID): Cannot parse 'endSleepStatus': \(data.hexString)")
				}
				
			case .buttonResponse:
				if (data.count == 2) {
					let presses	= Int(data[1])
					self.buttonClicked?(presses)
				}
				else {
					log?.e ("\(pID): Cannot parse 'buttonResponse': \(data.hexString)")
				}
			#endif
								
			case .manufacturingTest:
				#if LIVOTAL
				let testResult = livotalManufacturingTestResult(data.subdata(in: Range(1...4)))
				do {
					let jsonData = try JSONEncoder().encode(testResult)
					if let jsonString = String(data: jsonData, encoding: .utf8) {
						self.manufacturingTestResult?(true, jsonString)
					}
					else {
						log?.e ("\(pID): Result jsonString Failed")
						self.manufacturingTestResult?(false, "")
					}
				}
				catch {
					log?.e ("\(pID): Result jsonData Failed")
					self.manufacturingTestResult?(false, "")
				}
				#endif
				
				#if ETHOS
				if (data.count == 3) {
					let testResult = ethosManufacturingTestResult(data.subdata(in: Range(1...2)))
					do {
						let jsonData = try JSONEncoder().encode(testResult)
						if let jsonString = String(data: jsonData, encoding: .utf8) {
							self.manufacturingTestResult?(true, jsonString)
						}
						else {
							log?.e ("\(pID): Result jsonString Failed")
							self.manufacturingTestResult?(false, "")
						}
					}
					catch {
						log?.e ("\(pID): Result jsonData Failed")
						self.manufacturingTestResult?(false, "")
					}
				}
				else {
					self.manufacturingTestResult?(false, "")
				}
				#endif
				
				#if ALTER
				if (data.count == 3) {
					let testResult = alterManufacturingTestResult(data.subdata(in: Range(1...2)))
					do {
						let jsonData = try JSONEncoder().encode(testResult)
						if let jsonString = String(data: jsonData, encoding: .utf8) {
							self.manufacturingTestResult?(true, jsonString)
						}
						else {
							log?.e ("\(pID): Result jsonString Failed")
							self.manufacturingTestResult?(false, "")
						}
					}
					catch {
						log?.e ("\(pID): Result jsonData Failed")
						self.manufacturingTestResult?(false, "")
					}
				}
				else {
					self.manufacturingTestResult?(false, "")
				}
				#endif
				
				#if KAIROS
				if (data.count == 3) {
					let testResult = kairosManufacturingTestResult(data.subdata(in: Range(1...2)))
					do {
						let jsonData = try JSONEncoder().encode(testResult)
						if let jsonString = String(data: jsonData, encoding: .utf8) {
							self.manufacturingTestResult?(true, jsonString)
						}
						else {
							log?.e ("\(pID): Result jsonString Failed")
							self.manufacturingTestResult?(false, "")
						}
					}
					catch {
						log?.e ("\(pID): Result jsonData Failed")
						self.manufacturingTestResult?(false, "")
					}
				}
				else {
					self.manufacturingTestResult?(false, "")
				}
				#endif
				
				#if UNIVERSAL
				switch (type) {
				case .livotal	:
					let testResult = livotalManufacturingTestResult(data.subdata(in: Range(1...4)))
					do {
						let jsonData = try JSONEncoder().encode(testResult)
						if let jsonString = String(data: jsonData, encoding: .utf8) {
							self.manufacturingTestResult?(true, jsonString)
						}
						else {
							log?.e ("\(pID): Result jsonString Failed")
							self.manufacturingTestResult?(false, "")
						}
					}
					catch {
						log?.e ("\(pID): Result jsonData Failed")
						self.manufacturingTestResult?(false, "")
					}
					
				case .ethos		:
					if (data.count == 3) {
						let testResult = ethosManufacturingTestResult(data.subdata(in: Range(1...2)))
						do {
							let jsonData = try JSONEncoder().encode(testResult)
							if let jsonString = String(data: jsonData, encoding: .utf8) {
								self.manufacturingTestResult?(true, jsonString)
							}
							else {
								log?.e ("\(pID): Result jsonString Failed")
								self.manufacturingTestResult?(false, "")
							}
						}
						catch {
							log?.e ("\(pID): Result jsonData Failed")
							self.manufacturingTestResult?(false, "")
						}
					}
					else {
						self.manufacturingTestResult?(false, "")
					}
					
				case .alter		:
					if (data.count == 3) {
						let testResult = alterManufacturingTestResult(data.subdata(in: Range(1...2)))
						do {
							let jsonData = try JSONEncoder().encode(testResult)
							if let jsonString = String(data: jsonData, encoding: .utf8) {
								self.manufacturingTestResult?(true, jsonString)
							}
							else {
								log?.e ("\(pID): Result jsonString Failed")
								self.manufacturingTestResult?(false, "")
							}
						}
						catch {
							log?.e ("\(pID): Result jsonData Failed")
							self.manufacturingTestResult?(false, "")
						}
					}
					else {
						self.manufacturingTestResult?(false, "")
					}
					
				case .kairos		:
					if (data.count == 3) {
						let testResult = kairosManufacturingTestResult(data.subdata(in: Range(1...2)))
						do {
							let jsonData = try JSONEncoder().encode(testResult)
							if let jsonString = String(data: jsonData, encoding: .utf8) {
								self.manufacturingTestResult?(true, jsonString)
							}
							else {
								log?.e ("\(pID): Result jsonString Failed")
								self.manufacturingTestResult?(false, "")
							}
						}
						catch {
							log?.e ("\(pID): Result jsonData Failed")
							self.manufacturingTestResult?(false, "")
						}
					}
					else {
						self.manufacturingTestResult?(false, "")
					}
					
				case .unknown	: break
				}
			#endif
				
			case .charging:
				let on_charger	= (data[1] == 0x01)
				let charging	= (data[2] == 0x01)
				let error		= (data[3] == 0x01)
				
				self.deviceChargingStatus?(charging, on_charger, error)
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
				mProcessUpdateValue(data.subdata(in: Range(0...(data.count - 5))))
			}
			else {
				log?.e ("\(pID): Missing data")
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

}
