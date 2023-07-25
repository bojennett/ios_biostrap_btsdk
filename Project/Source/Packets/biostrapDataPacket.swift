//
//  livotalPacket.swift
//  biostrapDeviceSDK
//
//  Created by Joseph A. Bennett on 8/12/21.
//

import Foundation

@objc public class biostrapDataPacket: NSObject, Codable {
	public var type						: packetType	= .unknown
	public var settings_type			: settingsType	= .unknown
	public var epoch					: Int			= 0
	public var end_epoch				: Int			= 0
	public var worn						: Bool			= false
	public var epoch_ms					: Int			= 0
	public var seconds					: Int			= 0
	public var value					: Int			= 0
	public var active_seconds			: Int			= 0
	public var voltage					: Int			= 0
	public var temperature				: Float			= 0.0
	public var hr_valid					: Bool			= false
	public var hr_result				: Float			= 0.0
	public var hrv_valid				: Bool			= false
	public var hrv_result				: Float			= 0.0
	public var rr_valid					: Bool			= false
	public var rr_result				: Float			= 0.0
	public var spo2_valid				: Bool			= false
	public var spo2_result				: Float			= 0.0
	public var tag						: String		= ""
	public var settings_value			: Float			= 0.0
	public var raw_data					: Data			= Data()
	public var raw_data_string			: String		= ""
	public var diagnostic_type			: diagnosticType	= .unknown
	public var ppg_failed_type			: ppgFailedType		= .unknown
	public var ppg_metrics_status		: ppgStatusType		= .unknown
	#if UNIVERSAL || ETHOS || ALTER || KAIROS
	public var continuous_hr			: [Int]			= [Int]()
	public var bbi						: [Int]			= [Int]()
	public var cadence_spm				: [Int]			= [Int]()
	public var event_type				: eventType		= .unknown
	public var bookend_type				: bookendType	= .unknown
	public var bookend_payload			: Int			= 0
	public var duration_ms				: Int			= 0
	#endif
	public var green_led_current		: Int			= 0
	public var red_led_current			: Int			= 0
	public var ir_led_current			: Int			= 0
	public var white_irr_led_current	: Int			= 0
	public var white_white_led_current	: Int			= 0
	public var charging					: Bool			= false
	public var charge_full				: Bool			= false
	
	#if UNIVERSAL || ALTER || KAIROS
	public var algorithmPacketSubType	: algorithmPacketType	= .unknown
	public var algorithmPacketIndex		: Int			= 0
	public var algorithmPacketCount		: Int			= 0
	public var algorithmPacketData		: Data			= Data()
	#endif

	//--------------------------------------------------------------------------------
	//
	// Used for JSON encode/decode
	//
	//--------------------------------------------------------------------------------
	enum CodingKeys: String, CodingKey {
		case type
		case epoch
		case end_epoch
		case worn
		case voltage
		case epoch_ms
		case seconds
		case temperature
		case hr_valid
		case hr_result
		case hrv_valid
		case hrv_result
		case rr_valid
		case rr_result
		case spo2_valid
		case spo2_result
		case value
		case active_seconds
		case tag
		case settings_type
		case settings_value
		case raw_data
		case raw_data_string
		case diagnostic_type
		case ppg_failed_type
		case ppg_metrics_status
		#if UNIVERSAL || ETHOS || ALTER || KAIROS
		case continuous_hr
		case bbi
		case cadence_spm
		case event_type
		case bookend_type
		case bookend_payload
		case duration_ms
		#endif
		#if UNIVERSAL || ALTER || KAIROS
		case algorithmPacketSubType
		case algorithmPacketIndex
		case algorithmPacketCount
		case algorithmPacketData
		#endif
		case green_led_current
		case red_led_current
		case ir_led_current
		case white_irr_led_current
		case white_white_led_current
		case charging
		case charge_full
	}
	
	//--------------------------------------------------------------------------------
	// Variable: csv
	//--------------------------------------------------------------------------------
	//
	// Returns a CSV version of the object
	//
	//--------------------------------------------------------------------------------
	public var csv: String {
		switch (type) {
		case .activity						: return ("\(raw_data.hexString),\(type.title),\(epoch),\(seconds),\(value)")
		case .temp							: return ("\(raw_data.hexString),\(type.title),\(epoch),\(temperature)")
		case .worn							: return ("\(raw_data.hexString),\(type.title),\(epoch),\(worn)")
		case .ppg_failed					: return ("\(raw_data.hexString),\(type.title),\(epoch),\(ppg_failed_type.title)")
		case .battery						: return ("\(raw_data.hexString),\(type.title),\(epoch),\(value),\(voltage)")
		case .charger						: return ("\(raw_data.hexString),\(type.title),\(epoch),\(charging),\(charge_full)")
		case .sleep							: return ("\(raw_data.hexString),\(type.title),\(epoch),\(end_epoch)")
		case .rawPPGFifoCount,
			 .rawAccelFifoCount				: return ("\(raw_data.hexString),\(type.title),\(value),\(epoch_ms)")
		case .rawPPGProximity				: return ("\(raw_data.hexString),\(type.title),\(value)")
		case .rawPPGRed						: return ("\(raw_data.hexString),\(type.title),\(value)")
		case .rawPPGIR						: return ("\(raw_data.hexString),\(type.title),\(value)")
		case .rawPPGGreen					: return ("\(raw_data.hexString),\(type.title),\(value)")

		case .rawAccelXADC					: return ("\(raw_data.hexString),\(type.title),\(value)")
		case .rawAccelYADC					: return ("\(raw_data.hexString),\(type.title),\(value)")
		case .rawAccelZADC					: return ("\(raw_data.hexString),\(type.title),\(value)")
		case .rawAccelCompressedXADC		: return ("\(raw_data.hexString),\(type.title),\(value)")
		case .rawAccelCompressedYADC		: return ("\(raw_data.hexString),\(type.title),\(value)")
		case .rawAccelCompressedZADC		: return ("\(raw_data.hexString),\(type.title),\(value)")

		#if UNIVERSAL || ETHOS || ALTER || KAIROS
		case .rawGyroXADC					: return ("\(raw_data.hexString),\(type.title),\(value)")
		case .rawGyroYADC					: return ("\(raw_data.hexString),\(type.title),\(value)")
		case .rawGyroZADC					: return ("\(raw_data.hexString),\(type.title),\(value)")
		case .rawGyroCompressedXADC			: return ("\(raw_data.hexString),\(type.title),\(value)")
		case .rawGyroCompressedYADC			: return ("\(raw_data.hexString),\(type.title),\(value)")
		case .rawGyroCompressedZADC			: return ("\(raw_data.hexString),\(type.title),\(value)")
		#endif

		case .ppgCalibrationStart			: return ("\(raw_data.hexString),\(type.title),\(epoch_ms)")
		case .ppgCalibrationDone			: return ("\(raw_data.hexString),\(type.title),\(epoch_ms),\(green_led_current),\(red_led_current),\(ir_led_current),\(white_irr_led_current),\(white_white_led_current)")
		case .motionLevel					: return ("\(raw_data.hexString),\(type.title),\(value),\(epoch_ms)")

		case .rawPPGCompressedGreen,
			 .rawPPGCompressedIR,
			 .rawPPGCompressedRed			: return ("\(raw_data.hexString),\(type.title),\(value)")

		#if UNIVERSAL || ETHOS
		case .rawPPGCompressedWhiteIRRPD,
			 .rawPPGCompressedWhiteWhitePD	: return ("\(raw_data.hexString),\(type.title),\(value)")
		#endif
			
		#if UNIVERSAL || ETHOS
		case .rawPPGWhiteIRRPD,
			 .rawPPGWhiteWhitePD			: return ("\(raw_data.hexString),\(type.title),\(value)")
		#endif

		case .ppg_metrics					:
			let root	= "\(raw_data.hexString),\(type.title),\(epoch_ms),\(ppg_metrics_status.title)"
			let hr		= "\(root),HR,\(hr_valid),\(hr_result)"
			let hrv		= "\(root),HRV,\(hrv_valid),\(hrv_result)"
			let rr		= "\(root),RR,\(rr_valid),\(rr_result)"
			let spo2	= "\(root),SPO2,\(spo2_valid),\(spo2_result)"
			return ("\(hr)\n\(hrv)\n\(rr)\n\(spo2)")
			
		#if UNIVERSAL || ETHOS || ALTER || KAIROS
		case .continuous_hr					:
			return ("\(raw_data.hexString),\(type.title),\(epoch_ms),\(mIntegerArrayToString(continuous_hr))")
		case .bbi							:
			return ("\(raw_data.hexString),\(type.title),\(epoch_ms),\(mIntegerArrayToString(bbi))")
		case .cadence						:
			return ("\(raw_data.hexString),\(type.title),\(epoch_ms),\(mIntegerArrayToString(cadence_spm))")
		case .event							:
			return ("\(raw_data.hexString),\(type.title),\(epoch_ms),\(event_type.title)")
		case .bookend						:
			return ("\(raw_data.hexString),\(type.title),\(epoch_ms),\(duration_ms),\(bookend_type.title),\(bookend_payload)")
		#endif
			
		#if UNIVERSAL || ALTER || KAIROS
		case .algorithmData					:
			return ("\(raw_data.hexString),\(type.title),\(algorithmPacketSubType.title),\(algorithmPacketCount),\(algorithmPacketIndex),\(algorithmPacketData.hexString.replacingOccurrences(of: "[ ", with: "").replacingOccurrences(of: " ]", with: ""))")
		#endif

		case .unknown						: return ("\(raw_data.hexString),\(type.title)")
		case .steps							: return ("\(raw_data.hexString),\(type.title),\(epoch),\(value)")
		case .steps_active					: return ("\(raw_data.hexString),\(type.title),\(epoch),\(value),\(active_seconds)")
		case .diagnostic					: return ("\(raw_data.hexString),\(type.title),\(diagnostic_type.title)")
		case .milestone						: return ("\(raw_data.hexString),\(type.title),\(epoch),\(tag)")
		case .settings						: return ("\(raw_data.hexString),\(type.title),\(settings_type.title),\(settings_value)")
		case .caughtUp						: return ("\(raw_data.hexString),\(type.title)")
		}
	}
	
	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	// Makes a comma deliminated string from an integer array
	//
	// Data goes in as ',<value>,<value>,<value>...'
	// And then the first comma is thrown away
	//
	//--------------------------------------------------------------------------------
	internal func mIntegerArrayToString(_ values: [Int]) -> String {
		var arr_string = ""
		for value in values { arr_string = "\(arr_string),\(value)" }
		arr_string = String(arr_string.dropFirst())
		
		return arr_string
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	// Makes a comma deliminated string from an integer array
	//
	//--------------------------------------------------------------------------------
	internal func mStringArrayToIntegerArray(_ value: String) -> [Int] {
		var array = [Int]()
		let strArray = value.components(separatedBy: ",")
		for str in strArray {
			if let test = Int(str) { array.append(test) }
		}
		
		return array
	}
	
	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	// Makes a comma deliminated string from an integer array
	//
	//--------------------------------------------------------------------------------
	internal func mStringArrayToData(_ value: String) -> Data {
		var data = Data()
		let strArray = value.components(separatedBy: " ")
		for str in strArray {
			if let test = UInt32(str, radix: 16) {
				data.append(UInt8(test))
			}
			else {
				log?.e ("Cannot parse '\(str)' into a hex value")
			}
		}
		
		return data
	}


	//--------------------------------------------------------------------------------
	//
	// Constructor
	//
	//--------------------------------------------------------------------------------
	override init() {
		
	}
	
	//--------------------------------------------------------------------------------
	//
	// Constructor from data stream returned from Bluetooth
	//
	//--------------------------------------------------------------------------------
	init(_ data: Data) {
		super.init()
		if let thisType = packetType(rawValue: data[0]) {
			type = thisType

			raw_data		= data
			raw_data_string	= data.hexString.replacingOccurrences(of: "[ ", with: "").replacingOccurrences(of: " ]", with: "")

			switch (type) {
			case .activity:
				epoch		= data.subdata(in: Range(1...4)).leInt32
				seconds		= Int(data[5])
				value		= data.subdata(in: Range(6...9)).leInt32

			case .temp:
				epoch		= data.subdata(in: Range(1...4)).leInt32
				temperature	= data.subdata(in: Range(5...8)).leFloat

			case .worn:
				epoch		= data.subdata(in: Range(1...4)).leInt32
				worn		= (data[5] == 0x01)
				
			case .sleep:
				epoch		= data.subdata(in: Range(1...4)).leInt32
				end_epoch	= data.subdata(in: Range(5...8)).leInt32
				
			case .diagnostic:
				if (raw_data.count > 2) {
					if let test = diagnosticType(rawValue: raw_data[2]) { diagnostic_type = test }
					else { diagnostic_type = .unknown }
				}
				else { diagnostic_type = .unknown }
				
			case .rawPPGFifoCount,
				 .rawAccelFifoCount:
				value		= Int(data[1])
				epoch_ms	= data.subdata(in: Range(2...9)).leInt64

			case .rawPPGCompressedGreen,
				 .rawPPGCompressedIR,
				 .rawPPGCompressedRed:	break	// use raw_data

			#if UNIVERSAL || ETHOS
			case .rawPPGCompressedWhiteIRRPD,
				 .rawPPGCompressedWhiteWhitePD	:	break	// use raw_data
			#endif

			case .rawPPGRed,
				 .rawPPGIR,
				 .rawPPGGreen:
				value				= data.subdata(in: Range(1...4)).leInt32

			case .rawAccelXADC,
				 .rawAccelYADC,
				 .rawAccelZADC:
				value				= data.subdata(in: Range(1...2)).leInt16

			case .rawAccelCompressedXADC,
				 .rawAccelCompressedYADC,
				 .rawAccelCompressedZADC: break // use raw_data

			#if UNIVERSAL || ETHOS || ALTER || KAIROS
			case .rawGyroXADC,
				 .rawGyroYADC,
				 .rawGyroZADC:
				value				= data.subdata(in: Range(1...2)).leInt16

			case .rawGyroCompressedXADC,
				 .rawGyroCompressedYADC,
				 .rawGyroCompressedZADC: break // use raw_data
			#endif

			#if UNIVERSAL || ETHOS
			case .rawPPGWhiteIRRPD,
				 .rawPPGWhiteWhitePD:
				value				= data.subdata(in: Range(1...4)).leInt32
			#endif

				
			case .ppgCalibrationStart:
				epoch_ms				= data.subdata(in: Range(1...8)).leInt64
				
			case .ppgCalibrationDone:
				epoch_ms				= data.subdata(in: Range(1...8)).leInt64
				green_led_current		= Int(data[ 9])
				red_led_current			= Int(data[10])
				ir_led_current			= Int(data[11])
				white_irr_led_current	= Int(data[12])
				white_white_led_current	= Int(data[13])
				
			case .motionLevel:
				value					= Int(data[2])
				epoch_ms				= data.subdata(in: Range(2...9)).leInt64

			case .rawPPGProximity:
				value				= data.subdata(in: Range(1...4)).leInt32
				
			case .steps:
				epoch				= data.subdata(in: Range(1...4)).leInt32
				value				= data.subdata(in: Range(5...6)).leUInt16

			case .steps_active:
				epoch				= data.subdata(in: Range(1...4)).leInt32
				value				= Int(data[5])
				active_seconds		= Int(data[6])

			case .ppg_metrics:
				epoch_ms			= data.subdata(in: Range(1...8)).leInt64
				if let test = ppgStatusType(rawValue: raw_data[9]) { ppg_metrics_status = test }
				else { ppg_metrics_status = .unknown }
				hr_valid			= (((data[10] >> 0) & 0x01) != 0)
				hrv_valid			= (((data[10] >> 1) & 0x01) != 0)
				rr_valid			= (((data[10] >> 2) & 0x01) != 0)
				spo2_valid			= (((data[10] >> 3) & 0x01) != 0)
				spo2_result			= data.subdata(in: Range(11...12)).leFloat16
				rr_result			= data.subdata(in: Range(13...14)).leFloat16
				hrv_result			= data.subdata(in: Range(15...16)).leFloat16
				hr_result			= data.subdata(in: Range(17...18)).leFloat16
				
			#if UNIVERSAL || ETHOS || ALTER || KAIROS
			case .continuous_hr:
				epoch_ms			= data.subdata(in: Range(1...8)).leInt64
				continuous_hr.removeAll()
				for i in (9...18) {
					if (data[i] != 0xff) { continuous_hr.append(Int(data[i])) }
				}
				
			case .bbi:
				epoch_ms			= data.subdata(in: Range(1...8)).leInt64
				bbi.removeAll()
				let count			= Int(data[9])
				var index			= 10
				for _ in (0..<count) {
					let thisBBI		= data.subdata(in: Range((index + 0)...(index + 1))).leUInt16
					bbi.append(thisBBI)
					index			= index + 2
				}
				
			case .cadence:
				epoch_ms			= data.subdata(in: Range(1...8)).leInt64
				cadence_spm.removeAll()
				let count			= Int(data[9])
				var index			= 10
				for _ in (0..<count) {
					cadence_spm.append(Int(data[index]))
					index			= index + 1
				}
				
			case .event:
				if let thisEvent = eventType(rawValue: data[1]) {
					event_type		= thisEvent
				}
				else {
					event_type		= .unknown
				}
				epoch_ms			= data.subdata(in: Range(2...9)).leInt64
				
			case .bookend:
				if let thisBookend = bookendType(rawValue: data[1]) {
					bookend_type	= thisBookend
				}
				else {
					bookend_type	= .unknown
				}
				bookend_payload		= Int(data[2])
				epoch_ms			= data.subdata(in: Range(3...10)).leInt64
				duration_ms			= data.subdata(in: Range(11...14)).leInt64
			#endif
				
			#if UNIVERSAL || ALTER || KAIROS
			case .algorithmData:
				if let thisType = algorithmPacketType(rawValue: data[2]) {
					algorithmPacketSubType	= thisType
				}
				else {
					algorithmPacketSubType	= .unknown
				}
				algorithmPacketCount	= Int(data[3])
				algorithmPacketIndex	= Int(data[4])
				algorithmPacketData		= data.subdata(in: Range(5...(data.count - 1)))
			#endif
				
			case .ppg_failed:
				epoch				= data.subdata(in: Range(1...4)).leInt32
				if let test = ppgFailedType(rawValue: raw_data[5]) { ppg_failed_type = test }
				else { ppg_failed_type = .unknown }

			case .battery:
				epoch				= data.subdata(in: Range(1...4)).leInt32
				value				= Int(data[5])
				voltage				= data.subdata(in: Range(6...7)).leUInt16
				
			case .charger:
				epoch				= data.subdata(in: Range(1...4)).leInt32
				charging			= (data[5] != 0)
				charge_full			= (data[6] != 0)

			case .milestone:
				epoch				= data.subdata(in: Range(1...4)).leInt32
				if let testTag = String(data: data.subdata(in: Range(5...6)), encoding: .utf8) { tag = testTag }
				else { tag			= "UK" }
				
			case .settings:
				if let thisSetting = settingsType(rawValue: data[1]) { settings_type = thisSetting }
				else { settings_type	= .unknown }
				settings_value		= data.subdata(in: Range(2...5)).leFloat
				
			case .caughtUp:
				break

			case .unknown:
				break
			}
		}
	}
	
	//--------------------------------------------------------------------------------
	//
	// Constructor from a JSON decoder.
	//
	//--------------------------------------------------------------------------------
	public required init(from decoder: Decoder) throws {
		super.init()
		
		let values = try decoder.container(keyedBy: CodingKeys.self)
		type = try values.decode(packetType.self, forKey: .type)

		raw_data				= try values.decode(Data.self, forKey: .raw_data)
		raw_data_string			= try values.decode(String.self, forKey: .raw_data_string)

		switch (type) {
		case .activity:
			epoch				= try values.decode(Int.self, forKey: .epoch)
			seconds				= try values.decode(Int.self, forKey: .seconds)
			value				= try values.decode(Int.self, forKey: .value)
			
		case .temp:
			epoch				= try values.decode(Int.self, forKey: .epoch)
			temperature 		= try values.decode(Float.self, forKey: .temperature)
			
		case .worn:
			epoch				= try values.decode(Int.self, forKey: .epoch)
			worn				= try values.decode(Bool.self, forKey: .worn)
			
		case .sleep:
			epoch				= try values.decode(Int.self, forKey: .epoch)
			end_epoch			= try values.decode(Int.self, forKey: .end_epoch)
			
		case .rawAccelXADC,
			 .rawAccelYADC,
			 .rawAccelZADC:
			value				= try values.decode(Int.self, forKey: .value)

		case .rawAccelCompressedXADC,
			 .rawAccelCompressedYADC,
			 .rawAccelCompressedZADC:
			value				= try values.decode(Int.self, forKey: .value)

		#if UNIVERSAL || ETHOS || ALTER || KAIROS
		case .rawGyroXADC,
			 .rawGyroYADC,
			 .rawGyroZADC:
			value				= try values.decode(Int.self, forKey: .value)

		case .rawGyroCompressedXADC,
			 .rawGyroCompressedYADC,
			 .rawGyroCompressedZADC:
			value				= try values.decode(Int.self, forKey: .value)
		#endif

		case .rawPPGCompressedGreen,
			 .rawPPGCompressedIR,
			 .rawPPGCompressedRed:
			value				= try values.decode(Int.self, forKey: .value)

		#if UNIVERSAL || ETHOS
		case .rawPPGCompressedWhiteIRRPD,
			 .rawPPGCompressedWhiteWhitePD:
			value				= try values.decode(Int.self, forKey: .value)
		#endif

		case .diagnostic:
			diagnostic_type		= try values.decode(diagnosticType.self, forKey: .diagnostic_type)
			
		case .rawPPGFifoCount,
			 .rawAccelFifoCount:
			value				= try values.decode(Int.self, forKey: .value)
			epoch_ms			= try values.decode(Int.self, forKey: .epoch_ms)
			
		case .steps:
			epoch				= try values.decode(Int.self, forKey: .epoch)
			value				= try values.decode(Int.self, forKey: .value)
			
		case .steps_active:
			epoch				= try values.decode(Int.self, forKey: .epoch)
			value				= try values.decode(Int.self, forKey: .value)
			active_seconds		= try values.decode(Int.self, forKey: .active_seconds)
			
		case .rawPPGRed,
			 .rawPPGIR,
			 .rawPPGGreen,
			 .rawPPGProximity:
			value				= try values.decode(Int.self, forKey: .value)

		#if UNIVERSAL || ETHOS
		case .rawPPGWhiteIRRPD,
			 .rawPPGWhiteWhitePD:
			value				= try values.decode(Int.self, forKey: .value)
		#endif

		case .ppgCalibrationStart:
			epoch_ms			= try values.decode(Int.self, forKey: .epoch_ms)
			
		case .ppgCalibrationDone:
			epoch_ms				= try values.decode(Int.self, forKey: .epoch_ms)
			green_led_current		= try values.decode(Int.self, forKey: .green_led_current)
			red_led_current			= try values.decode(Int.self, forKey: .red_led_current)
			ir_led_current			= try values.decode(Int.self, forKey: .ir_led_current)
			white_irr_led_current	= try values.decode(Int.self, forKey: .white_irr_led_current)
			white_white_led_current	= try values.decode(Int.self, forKey: .white_white_led_current)
			
		case .motionLevel:
			value				= try values.decode(Int.self, forKey: .value)
			epoch_ms			= try values.decode(Int.self, forKey: .epoch_ms)

		case .ppg_metrics:
			epoch_ms			= try values.decode(Int.self, forKey: .epoch_ms)
			ppg_metrics_status	= try values.decode(ppgStatusType.self, forKey: .ppg_metrics_status)
			hr_valid			= try values.decode(Bool.self, forKey: .hr_valid)
			hr_result			= try values.decode(Float.self, forKey: .hr_result)
			hrv_valid			= try values.decode(Bool.self, forKey: .hrv_valid)
			hrv_result			= try values.decode(Float.self, forKey: .hrv_result)
			rr_valid			= try values.decode(Bool.self, forKey: .rr_valid)
			rr_result			= try values.decode(Float.self, forKey: .rr_result)
			spo2_valid			= try values.decode(Bool.self, forKey: .spo2_valid)
			spo2_result			= try values.decode(Float.self, forKey: .spo2_result)
			
		#if UNIVERSAL || ETHOS || ALTER || KAIROS
		case .continuous_hr:
			epoch_ms			= try values.decode(Int.self, forKey: .epoch_ms)
			let elements		= try values.decode(String.self, forKey: .continuous_hr)
			continuous_hr		= mStringArrayToIntegerArray(elements)
			
		case .bbi:
			epoch_ms			= try values.decode(Int.self, forKey: .epoch_ms)
			let elements		= try values.decode(String.self, forKey: .bbi)
			bbi					= mStringArrayToIntegerArray(elements)
			
		case .cadence:
			epoch_ms			= try values.decode(Int.self, forKey: .epoch_ms)
			let elements		= try values.decode(String.self, forKey: .cadence_spm)
			cadence_spm			= mStringArrayToIntegerArray(elements)
			
		case .event:
			event_type			= try values.decode(eventType.self, forKey: .event_type)
			epoch_ms			= try values.decode(Int.self, forKey: .epoch_ms)
			
		case .bookend:
			bookend_type		= try values.decode(bookendType.self, forKey: .bookend_type)
			bookend_payload		= try values.decode(Int.self, forKey: .bookend_payload)
			epoch_ms			= try values.decode(Int.self, forKey: .epoch_ms)
			duration_ms			= try values.decode(Int.self, forKey: .duration_ms)
		#endif
			
		#if UNIVERSAL || ALTER || KAIROS
		case .algorithmData:
			algorithmPacketSubType	= try values.decode(algorithmPacketType.self, forKey: .algorithmPacketSubType)
			algorithmPacketCount	= try values.decode(Int.self, forKey: .algorithmPacketCount)
			algorithmPacketIndex	= try values.decode(Int.self, forKey: .algorithmPacketIndex)
			let elements			= try values.decode(String.self, forKey: .algorithmPacketData)
			algorithmPacketData		= mStringArrayToData(elements)
		#endif
			
		case .ppg_failed:
			epoch				= try values.decode(Int.self, forKey: .epoch)
			ppg_failed_type		= try values.decode(ppgFailedType.self, forKey: .ppg_failed_type)
			
		case .battery:
			epoch				= try values.decode(Int.self, forKey: .epoch)
			value				= try values.decode(Int.self, forKey: .value)
			voltage				= try values.decode(Int.self, forKey: .voltage)

		case .charger:
			epoch				= try values.decode(Int.self, forKey: .epoch)
			charging			= try values.decode(Bool.self, forKey: .charging)
			charge_full			= try values.decode(Bool.self, forKey: .charge_full)

		case .milestone:
			epoch				= try values.decode(Int.self, forKey: .epoch)
			tag					= try values.decode(String.self, forKey: .tag)
			
		case .settings:
			settings_type		= try values.decode(settingsType.self, forKey: .settings_type)
			settings_value		= try values.decode(Float.self, forKey: .settings_value)
			break
			
		case .caughtUp:
			break
			
		case .unknown:
			break
		}
	}
	
	//--------------------------------------------------------------------------------
	// Method Name: encode
	//--------------------------------------------------------------------------------
	//
	// When the JSON encoder is called, states how to create a JSON dictionary based
	// upon the packet type
	//
	//--------------------------------------------------------------------------------
	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(type.title, forKey: .type)
		
		try container.encode(raw_data, forKey: .raw_data)
		try container.encode(raw_data_string, forKey: .raw_data_string)

		switch (type) {
		case .activity:
			try container.encode(epoch, forKey: .epoch)
			try container.encode(seconds, forKey: .seconds)
			try container.encode(value, forKey: .value)
			
		case .temp:
			try container.encode(epoch, forKey: .epoch)
			try container.encode(temperature, forKey: .temperature)
			
		case .worn:
			try container.encode(epoch, forKey: .epoch)
			try container.encode(worn, forKey: .worn)

		case .steps:
			try container.encode(epoch, forKey: .epoch)
			try container.encode(value, forKey: .value)

		case .steps_active:
			try container.encode(epoch, forKey: .epoch)
			try container.encode(value, forKey: .value)
			try container.encode(active_seconds, forKey: .active_seconds)

		case .sleep:
			try container.encode(epoch, forKey: .epoch)
			try container.encode(end_epoch, forKey: .end_epoch)
			
		case .diagnostic:
			try container.encode(diagnostic_type.title, forKey: .diagnostic_type)

		case .rawAccelXADC,
			 .rawAccelYADC,
			 .rawAccelZADC:
			try container.encode(value, forKey: .value)

		case .rawAccelCompressedXADC,
			 .rawAccelCompressedYADC,
			 .rawAccelCompressedZADC:
			try container.encode(value, forKey: .value)

		#if UNIVERSAL || ETHOS || ALTER || KAIROS
		case .rawGyroXADC,
			 .rawGyroYADC,
			 .rawGyroZADC:
			try container.encode(value, forKey: .value)

		case .rawGyroCompressedXADC,
			 .rawGyroCompressedYADC,
			 .rawGyroCompressedZADC:
			try container.encode(value, forKey: .value)
		#endif

		case .rawPPGCompressedGreen,
			 .rawPPGCompressedIR,
			 .rawPPGCompressedRed:
			try container.encode(value, forKey: .value)

		#if UNIVERSAL || ETHOS
		case .rawPPGCompressedWhiteIRRPD,
			 .rawPPGCompressedWhiteWhitePD:
			try container.encode(value, forKey: .value)
		#endif

		case .rawPPGFifoCount,
			 .rawAccelFifoCount:
			try container.encode(value, forKey: .value)
			try container.encode(epoch_ms, forKey: .epoch_ms)
						
		case .rawPPGRed:
			try container.encode(value, forKey: .value)

		case .rawPPGIR:
			try container.encode(value, forKey: .value)

		case .rawPPGProximity:
			try container.encode(value, forKey: .value)

		case .rawPPGGreen:
			try container.encode(value, forKey: .value)

		#if UNIVERSAL || ETHOS
		case .rawPPGWhiteIRRPD:
			try container.encode(value, forKey: .value)

		case .rawPPGWhiteWhitePD:
			try container.encode(value, forKey: .value)
		#endif

		case .ppgCalibrationStart:
			try container.encode(epoch_ms, forKey: .epoch_ms)

		case .ppgCalibrationDone:
			try container.encode(epoch_ms, forKey: .epoch_ms)
			try container.encode(green_led_current, forKey: .green_led_current)
			try container.encode(red_led_current, forKey: .red_led_current)
			try container.encode(ir_led_current, forKey: .ir_led_current)
			try container.encode(white_irr_led_current, forKey: .white_irr_led_current)
			try container.encode(white_white_led_current, forKey: .white_white_led_current)
			
		case .motionLevel:
			try container.encode(value, forKey: .value)
			try container.encode(epoch_ms, forKey: .epoch_ms)

		case .ppg_metrics:
			try container.encode(epoch_ms, forKey: .epoch_ms)
			try container.encode(ppg_metrics_status.title, forKey: .ppg_metrics_status)
			try container.encode(hr_valid, forKey: .hr_valid)
			try container.encode(hr_result, forKey: .hr_result)
			try container.encode(hrv_valid, forKey: .hrv_valid)
			try container.encode(hrv_result, forKey: .hrv_result)
			try container.encode(rr_valid, forKey: .rr_valid)
			try container.encode(rr_result, forKey: .rr_result)
			try container.encode(spo2_valid, forKey: .spo2_valid)
			try container.encode(spo2_result, forKey: .spo2_result)
			
		#if UNIVERSAL || ETHOS || ALTER || KAIROS
		case .continuous_hr:
			try container.encode(epoch_ms, forKey: .epoch_ms)
			try container.encode(mIntegerArrayToString(continuous_hr), forKey: .continuous_hr)
			
		case .bbi:
			try container.encode(epoch_ms, forKey: .epoch_ms)
			try container.encode(mIntegerArrayToString(bbi), forKey: .bbi)
			
		case .cadence:
			try container.encode(epoch_ms, forKey: .epoch_ms)
			try container.encode(mIntegerArrayToString(cadence_spm), forKey: .cadence_spm)
			
		case .event:
			try container.encode(event_type.title, forKey: .event_type)
			try container.encode(epoch_ms, forKey: .epoch_ms)
			
		case .bookend:
			try container.encode(bookend_type.title, forKey: .bookend_type)
			try container.encode(bookend_payload, forKey: .bookend_payload)
			try container.encode(epoch_ms, forKey: .epoch_ms)
			try container.encode(duration_ms, forKey: .duration_ms)
		#endif
			
		#if UNIVERSAL || ALTER || KAIROS
		case .algorithmData:
			try container.encode(algorithmPacketSubType.title, forKey: .algorithmPacketSubType)
			try container.encode(algorithmPacketCount, forKey: .algorithmPacketCount)
			try container.encode(algorithmPacketIndex, forKey: .algorithmPacketIndex)
			let outputString = algorithmPacketData.hexString.replacingOccurrences(of: "[ ", with: "").replacingOccurrences(of: " ]", with: "")
			try container.encode(outputString, forKey: .algorithmPacketData)
		#endif
			
		case .ppg_failed:
			try container.encode(epoch, forKey: .epoch)
			try container.encode(ppg_failed_type.title, forKey: .ppg_failed_type)

		case .battery:
			try container.encode(epoch, forKey: .epoch)
			try container.encode(value, forKey: .value)
			try container.encode(voltage, forKey: .voltage)

		case .charger:
			try container.encode(epoch, forKey: .epoch)
			try container.encode(charging, forKey: .charging)
			try container.encode(charge_full, forKey: .charge_full)

		case .milestone:
			try container.encode(epoch, forKey: .epoch)
			try container.encode(tag, forKey: .tag)
			
		case .settings:
			try container.encode(settings_type.title, forKey: .settings_type)
			try container.encode(settings_value, forKey: .settings_value)
			
		case .caughtUp:
			break
			
		case .unknown: break
		}
	}
}

//--------------------------------------------------------------------------------
// Method Name:
//--------------------------------------------------------------------------------
//
//
//
//--------------------------------------------------------------------------------
