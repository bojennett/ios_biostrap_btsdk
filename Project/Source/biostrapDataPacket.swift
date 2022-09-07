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
	public var voltage					: Int			= 0
	public var temperature				: Float			= 0.0
	public var hr_valid					: Bool			= false
	public var hr_result				: Float			= 0.0
	public var hr_uncertainty			: Float			= 0.0
	public var hrv_valid				: Bool			= false
	public var hrv_result				: Float			= 0.0
	public var hrv_uncertainty			: Float			= 0.0
	public var rr_valid					: Bool			= false
	public var rr_result				: Float			= 0.0
	public var rr_uncertainty			: Float			= 0.0
	public var spo2_valid				: Bool			= false
	public var spo2_result				: Float			= 0.0
	public var spo2_uncertainty			: Float			= 0.0
	public var tag						: String		= ""
	public var settings_value			: Float			= 0.0
	public var raw_data					: Data			= Data()
	public var raw_data_string			: String		= ""
	public var diagnostic_type			: diagnosticType	= .unknown
	public var ppg_failed_type			: ppgFailedType		= .unknown
	public var green_led_current		: Int			= 0
	public var red_led_current			: Int			= 0
	public var ir_led_current			: Int			= 0
	public var white_irr_led_current	: Int			= 0
	public var white_white_led_current	: Int			= 0

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
		case hr_uncertainty
		case hrv_valid
		case hrv_result
		case hrv_uncertainty
		case rr_valid
		case rr_result
		case rr_uncertainty
		case spo2_valid
		case spo2_result
		case spo2_uncertainty
		case value
		case tag
		case settings_type
		case settings_value
		case raw_data
		case raw_data_string
		case diagnostic_type
		case ppg_failed_type
		case green_led_current
		case red_led_current
		case ir_led_current
		case white_irr_led_current
		case white_white_led_current
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

		#if UNIVERSAL || ETHOS || ALTER
		case .rawGyroXADC					: return ("\(raw_data.hexString),\(type.title),\(value)")
		case .rawGyroYADC					: return ("\(raw_data.hexString),\(type.title),\(value)")
		case .rawGyroZADC					: return ("\(raw_data.hexString),\(type.title),\(value)")
		case .rawGyroCompressedXADC			: return ("\(raw_data.hexString),\(type.title),\(value)")
		case .rawGyroCompressedYADC			: return ("\(raw_data.hexString),\(type.title),\(value)")
		case .rawGyroCompressedZADC			: return ("\(raw_data.hexString),\(type.title),\(value)")
		#endif

		#if UNIVERSAL || ETHOS
		case .ppgCalibrationDone			: return ("\(raw_data.hexString),\(type.title),\(epoch_ms),\(green_led_current),\(red_led_current),\(ir_led_current),\(white_irr_led_current),\(white_white_led_current)")
		case .motionLevel					: return ("\(raw_data.hexString),\(type.title),\(value),\(epoch_ms)")
		#endif

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

		#if UNIVERSAL || ETHOS
		case .ppgCalibrationStart			: return ("\(raw_data.hexString),\(type.title),\(epoch_ms)")
		#endif

		case .ppg							:
			let root	= "\(raw_data.hexString),\(type.title),\(epoch)"
			let hr		= "\(root),HR,\(hr_valid),\(hr_result),\(hr_uncertainty)"
			let hrv		= "\(root),HRV,\(hrv_valid),\(hrv_result),\(hrv_uncertainty)"
			let rr		= "\(root),RR,\(rr_valid),\(rr_result),\(rr_uncertainty)"
			let spo2	= "\(root),SPO2,\(spo2_valid),\(spo2_result),\(spo2_uncertainty)"
			return ("\(hr)\n\(hrv)\n\(rr)\n\(spo2)")
			
		case .unknown						: return ("\(raw_data.hexString),\(type.title)")
		case .steps							: return ("\(raw_data.hexString),\(type.title),\(epoch),\(value)")
		case .diagnostic					: return ("\(raw_data.hexString),\(type.title),\(diagnostic_type.title)")
		case .milestone						: return ("\(raw_data.hexString),\(type.title),\(epoch),\(tag)")
		case .settings						: return ("\(raw_data.hexString),\(type.title),\(settings_type.title),\(settings_value)")
		}
	}
	
	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	// Custom float for the "uncertainty" value that was packed into an 8-bit UInt8
	//
	//--------------------------------------------------------------------------------
	internal func mDecodeUncertainty(_ encoded: UInt8) -> Float {
		if (encoded == 0xff) { return Float(0.0) }
		
		let UNCERTAINTY_ENCODE_A	= Float(1.986749)
		let UNCERTAINTY_ENCODE_B 	= Float(0.0128)
		let UNCERTAINTY_ENCODE_C	= (UNCERTAINTY_ENCODE_A * (UNCERTAINTY_ENCODE_B - 1))
		
		return UNCERTAINTY_ENCODE_A * exp(UNCERTAINTY_ENCODE_B * Float(encoded)) + UNCERTAINTY_ENCODE_C
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
				if raw_data.count > 2 {
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

			#if UNIVERSAL || ETHOS || ALTER
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

				
			#if UNIVERSAL || ETHOS
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
			#endif

			case .rawPPGProximity:
				value				= data.subdata(in: Range(1...4)).leInt32
				
			case .steps:
				epoch				= data.subdata(in: Range(1...4)).leInt32
				value				= data.subdata(in: Range(5...6)).leUInt16

			case .ppg:
				epoch				= data.subdata(in: Range(1...4)).leInt32
				hr_result			= data.subdata(in: Range(5...6)).leFloat16
				hr_uncertainty		= mDecodeUncertainty(data[7])
				hr_valid			= (data[7] != 0xff)
				hrv_result			= data.subdata(in: Range(8...9)).leFloat16
				hrv_uncertainty		= mDecodeUncertainty(data[10])
				hrv_valid			= (data[10] != 0xff)
				rr_result			= data.subdata(in: Range(11...12)).leFloat16
				rr_uncertainty		= mDecodeUncertainty(data[13])
				rr_valid			= (data[13] != 0xff)
				spo2_result			= data.subdata(in: Range(14...15)).leFloat16
				spo2_uncertainty	= mDecodeUncertainty(data[16])
				spo2_valid			= (data[16] != 0xff)

			case .ppg_failed:
				epoch				= data.subdata(in: Range(1...4)).leInt32
				if let test = ppgFailedType(rawValue: raw_data[5]) { ppg_failed_type = test }
				else { ppg_failed_type = .unknown }

			case .battery:
				epoch				= data.subdata(in: Range(1...4)).leInt32
				value				= Int(data[5])
				voltage				= data.subdata(in: Range(6...7)).leUInt16

			case .milestone:
				epoch				= data.subdata(in: Range(1...4)).leInt32
				if let testTag = String(data: data.subdata(in: Range(5...6)), encoding: .utf8) { tag = testTag }
				else { tag			= "UK" }
				
			case .settings:
				if let thisSetting = settingsType(rawValue: data[1]) { settings_type = thisSetting }
				else { settings_type	= .unknown }
				settings_value		= data.subdata(in: Range(2...5)).leFloat

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

		#if UNIVERSAL || ETHOS || ALTER
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

		#if UNIVERSAL || ETHOS
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
		#endif

		case .ppg:
			epoch				= try values.decode(Int.self, forKey: .epoch)
			hr_valid			= try values.decode(Bool.self, forKey: .hr_valid)
			hr_result			= try values.decode(Float.self, forKey: .hr_result)
			hr_uncertainty		= try values.decode(Float.self, forKey: .hr_uncertainty)
			hrv_valid			= try values.decode(Bool.self, forKey: .hrv_valid)
			hrv_result			= try values.decode(Float.self, forKey: .hrv_result)
			hrv_uncertainty		= try values.decode(Float.self, forKey: .hrv_uncertainty)
			rr_valid			= try values.decode(Bool.self, forKey: .rr_valid)
			rr_result			= try values.decode(Float.self, forKey: .rr_result)
			rr_uncertainty		= try values.decode(Float.self, forKey: .rr_uncertainty)
			spo2_valid			= try values.decode(Bool.self, forKey: .spo2_valid)
			spo2_result			= try values.decode(Float.self, forKey: .spo2_result)
			spo2_uncertainty	= try values.decode(Float.self, forKey: .spo2_uncertainty)
			
		case .ppg_failed:
			epoch				= try values.decode(Int.self, forKey: .epoch)
			ppg_failed_type		= try values.decode(ppgFailedType.self, forKey: .ppg_failed_type)
			
		case .battery:
			epoch				= try values.decode(Int.self, forKey: .epoch)
			value				= try values.decode(Int.self, forKey: .value)
			voltage				= try values.decode(Int.self, forKey: .voltage)

		case .milestone:
			epoch				= try values.decode(Int.self, forKey: .epoch)
			tag					= try values.decode(String.self, forKey: .tag)
			
		case .settings:
			settings_type		= try values.decode(settingsType.self, forKey: .settings_type)
			settings_value		= try values.decode(Float.self, forKey: .settings_value)
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

		#if UNIVERSAL || ETHOS || ALTER
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

		#if UNIVERSAL || ETHOS
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
		#endif

		case .ppg:
			try container.encode(epoch, forKey: .epoch)
			try container.encode(hr_valid, forKey: .hr_valid)
			try container.encode(hr_result, forKey: .hr_result)
			try container.encode(hr_uncertainty, forKey: .hr_uncertainty)
			try container.encode(hrv_valid, forKey: .hrv_valid)
			try container.encode(hrv_result, forKey: .hrv_result)
			try container.encode(hrv_uncertainty, forKey: .hrv_uncertainty)
			try container.encode(rr_valid, forKey: .rr_valid)
			try container.encode(rr_result, forKey: .rr_result)
			try container.encode(rr_uncertainty, forKey: .rr_uncertainty)
			try container.encode(spo2_valid, forKey: .spo2_valid)
			try container.encode(spo2_result, forKey: .spo2_result)
			try container.encode(spo2_uncertainty, forKey: .spo2_uncertainty)
			
		case .ppg_failed:
			try container.encode(epoch, forKey: .epoch)
			try container.encode(ppg_failed_type.title, forKey: .ppg_failed_type)

		case .battery:
			try container.encode(epoch, forKey: .epoch)
			try container.encode(value, forKey: .value)
			try container.encode(voltage, forKey: .voltage)

		case .milestone:
			try container.encode(epoch, forKey: .epoch)
			try container.encode(tag, forKey: .tag)
			break
			
		case .settings:
			try container.encode(settings_type.title, forKey: .settings_type)
			try container.encode(settings_value, forKey: .settings_value)
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
