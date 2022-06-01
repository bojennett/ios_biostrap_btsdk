//
//  livotalPacket.swift
//  biostrapDeviceSDK
//
//  Created by Joseph A. Bennett on 8/12/21.
//

import Foundation

@objc public class biostrapDataPacket: NSObject, Codable {
	public var type				: packetType	= .unknown
	public var settings_type	: settingsType	= .unknown
	public var epoch			: Int			= 0
	public var end_epoch		: Int			= 0
	public var worn				: Bool			= false
	public var ppg_failed_code	: Int			= 0
	public var elapsed_ms		: Int			= 0
	public var x				: Float			= 0.0
	public var y				: Float			= 0.0
	public var z				: Float			= 0.0
	public var x_adc			: Int			= 0
	public var y_adc			: Int			= 0
	public var z_adc			: Int			= 0
	public var seconds			: Int			= 0
	public var value			: Int			= 0
	public var voltage			: Int			= 0
	public var temperature		: Float			= 0.0
	public var hr_valid			: Bool			= false
	public var hr_result		: Float			= 0.0
	public var hr_uncertainty	: Float			= 0.0
	public var hrv_valid		: Bool			= false
	public var hrv_result		: Float			= 0.0
	public var hrv_uncertainty	: Float			= 0.0
	public var rr_valid			: Bool			= false
	public var rr_result		: Float			= 0.0
	public var rr_uncertainty	: Float			= 0.0
	public var spo2_valid		: Bool			= false
	public var spo2_result		: Float			= 0.0
	public var spo2_uncertainty	: Float			= 0.0
	public var tag				: String		= ""
	public var settings_value	: Float			= 0.0
	public var raw_data			: Data			= Data()
	
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
		case ppg_failed_code
		case voltage
		case elapsed_ms
		case x
		case y
		case z
		case x_adc
		case y_adc
		case z_adc
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
		case .activity				: return ("\(type.title),\(epoch),\(seconds),\(value)")
		case .temp					: return ("\(type.title),\(epoch),\(temperature)")
		case .worn					: return ("\(type.title),\(epoch),\(worn)")
		case .ppg_failed			: return ("\(type.title),\(epoch),\(ppg_failed_code)")
		case .battery				: return ("\(type.title),\(epoch),\(value),\(voltage)")
		case .sleep					: return ("\(type.title),\(epoch),\(end_epoch)")
		case .rawPPGFifoCount,
			 .rawAccelFifoCount		: return ("\(type.title),\(value),\(elapsed_ms)")
		case .rawAccel				: return ("\(type.title),\(x),\(y),\(z)")
		case .rawPPGProximity		: return ("\(type.title),\(value)")
		case .rawPPGRed				: return ("\(type.title),\(value)")
		case .rawPPGIR				: return ("\(type.title),\(value)")
			
		case .rawPPGCompressedGreen,
			 .rawPPGCompressedIR,
			 .rawPPGCompressedRed			: return ("\(type.title),\(value),\(raw_data.hexString)")
		#if ETHOS || UNIVERSAL
		case .rawPPGCompressedWhiteIRRPD	: return ("\(type.title),\(value),\(raw_data.hexString)")
		case .rawPPGCompressedWhiteWhitePD	: return ("\(type.title),\(value),\(raw_data.hexString)")
		#endif

		#if LIVOTAL
		case .rawPPGGreen			: return ("\(type.title),\(value)")
		#endif
			
		#if ETHOS || UNIVERSAL
		case .rawPPGGreenIRRPD		: return ("\(type.title),\(value)")
		case .rawPPGGreenWhitePD	: return ("\(type.title),\(value)")
		case .rawPPGWhiteIRRPD		: return ("\(type.title),\(value)")
		case .rawPPGWhiteWhitePD	: return ("\(type.title),\(value)")
		case .rawGyroADC			: return ("\(type.title),\(x_adc),\(y_adc),\(z_adc)")
		#endif
			
		case .rawAccelADC			: return ("\(type.title),\(x_adc),\(y_adc),\(z_adc)")

		case .ppg					: return ("\(type.title),\(epoch),\(hr_valid),\(hr_result),\(hr_uncertainty),\(hrv_valid),\(hrv_result),\(hrv_uncertainty),\(rr_valid),\(rr_result),\(rr_uncertainty),\(spo2_valid),\(spo2_result),\(spo2_uncertainty)")
		case .unknown				: return ("\(type.title)")
		case .steps					: return ("\(type.title),\(epoch),\(value)")
		case .diagnostic			: return ("\(type.title),\(raw_data.hexString)")
		case .milestone				: return ("\(type.title),\(epoch),\(tag)")
		case .settings				: return ("\(type.title),\(settings_type.title),\(settings_value)")
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
			
			switch (type) {
			case .activity:
				epoch		= data.subdata(in: Range(1...4)).leInt
				seconds		= Int(data[5])
				value		= data.subdata(in: Range(6...9)).leInt

			case .temp:
				epoch		= data.subdata(in: Range(1...4)).leInt
				temperature	= data.subdata(in: Range(5...8)).leFloat

			case .worn:
				epoch		= data.subdata(in: Range(1...4)).leInt
				worn		= (data[5] == 0x01)
				
			case .sleep:
				epoch		= data.subdata(in: Range(1...4)).leInt
				end_epoch	= data.subdata(in: Range(5...8)).leInt
				
			case .diagnostic:
				raw_data	= data	// App has to parse
				
			case .rawAccel:
				x = data.subdata(in: Range(1...4)).leFloat
				y = data.subdata(in: Range(5...8)).leFloat
				z = data.subdata(in: Range(9...12)).leFloat

			case .rawPPGFifoCount,
				 .rawAccelFifoCount:
				value		= Int(data[1])
				elapsed_ms	= data.subdata(in: Range(2...5)).leInt

			case .rawPPGCompressedGreen,
				 .rawPPGCompressedIR,
				 .rawPPGCompressedRed:
				raw_data	= data	// App has to parse

			#if ETHOS || UNIVERSAL
			case .rawPPGCompressedWhiteIRRPD,
				 .rawPPGCompressedWhiteWhitePD	:
				raw_data	= data	// App has to parse
			#endif

			case .rawPPGRed:
				value		= data.subdata(in: Range(1...4)).leInt

			case .rawPPGIR:
				value		= data.subdata(in: Range(1...4)).leInt

			#if LIVOTAL
			case .rawPPGGreen:
				value		= data.subdata(in: Range(1...4)).leInt
			#endif
				
			#if ETHOS || UNIVERSAL
			case .rawPPGGreenIRRPD:
				value		= data.subdata(in: Range(1...4)).leInt

			case .rawPPGGreenWhitePD:
				value		= data.subdata(in: Range(1...4)).leInt

			case .rawPPGWhiteIRRPD:
				value		= data.subdata(in: Range(1...4)).leInt
			
			case .rawPPGWhiteWhitePD:
				value		= data.subdata(in: Range(1...4)).leInt

			case .rawGyroADC:
				x_adc		= data.subdata(in: Range(1...2)).leInt16
				y_adc		= data.subdata(in: Range(3...4)).leInt16
				z_adc		= data.subdata(in: Range(5...6)).leInt16
				log?.v("\(data.hexString) - \(x_adc),\(y_adc),\(z_adc)")
			#endif

			case .rawAccelADC:
				x_adc		= data.subdata(in: Range(1...2)).leInt16
				y_adc		= data.subdata(in: Range(3...4)).leInt16
				z_adc		= data.subdata(in: Range(5...6)).leInt16
				log?.v("\(data.hexString) - \(x_adc),\(y_adc),\(z_adc)")

			case .rawPPGProximity:
				value		= data.subdata(in: Range(1...4)).leInt
				
			case .steps:
				epoch				= data.subdata(in: Range(1...4)).leInt
				value				= data.subdata(in: Range(5...6)).leUInt16

			case .ppg:
				epoch				= data.subdata(in: Range(1...4)).leInt
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
				epoch				= data.subdata(in: Range(1...4)).leInt
				ppg_failed_code		= Int(data[5])

			case .battery:
				epoch				= data.subdata(in: Range(1...4)).leInt
				value				= Int(data[5])
				voltage				= data.subdata(in: Range(6...7)).leUInt16

			case .milestone:
				epoch				= data.subdata(in: Range(1...4)).leInt
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
			
		case .rawPPGCompressedGreen,
			 .rawPPGCompressedIR,
			 .rawPPGCompressedRed:
			value				= try values.decode(Int.self, forKey: .value)
			raw_data			= try values.decode(Data.self, forKey: .raw_data)

		#if ETHOS || UNIVERSAL
		case .rawPPGCompressedWhiteIRRPD,
			 .rawPPGCompressedWhiteWhitePD:
			value				= try values.decode(Int.self, forKey: .value)
			raw_data			= try values.decode(Data.self, forKey: .raw_data)
		#endif

		case .diagnostic:
			raw_data			= try values.decode(Data.self, forKey: .raw_data)
			
		case .rawPPGFifoCount,
			 .rawAccelFifoCount:
			value				= try values.decode(Int.self, forKey: .value)
			elapsed_ms			= try values.decode(Int.self, forKey: .elapsed_ms)
			
		case .steps:
			epoch				= try values.decode(Int.self, forKey: .epoch)
			value				= try values.decode(Int.self, forKey: .value)
			
		case .rawAccel:
			x					= try values.decode(Float.self, forKey: .x)
			y					= try values.decode(Float.self, forKey: .y)
			z					= try values.decode(Float.self, forKey: .z)
			
		case .rawPPGRed:
			value				= try values.decode(Int.self, forKey: .value)

		case .rawPPGIR:
			value				= try values.decode(Int.self, forKey: .value)

		case .rawPPGProximity:
			value				= try values.decode(Int.self, forKey: .value)

		#if LIVOTAL
		case .rawPPGGreen:
			value				= try values.decode(Int.self, forKey: .value)
		#endif
			
		#if ETHOS || UNIVERSAL
		case .rawPPGGreenIRRPD:
			value				= try values.decode(Int.self, forKey: .value)

		case .rawPPGGreenWhitePD:
			value				= try values.decode(Int.self, forKey: .value)

		case .rawPPGWhiteIRRPD:
			value				= try values.decode(Int.self, forKey: .value)

		case .rawPPGWhiteWhitePD:
			value				= try values.decode(Int.self, forKey: .value)
			
		case .rawGyroADC:
			x_adc				= try values.decode(Int.self, forKey: .x_adc)
			y_adc				= try values.decode(Int.self, forKey: .y_adc)
			z_adc				= try values.decode(Int.self, forKey: .z_adc)
		#endif

		case .rawAccelADC:
			x_adc				= try values.decode(Int.self, forKey: .x_adc)
			y_adc				= try values.decode(Int.self, forKey: .y_adc)
			z_adc				= try values.decode(Int.self, forKey: .z_adc)

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
			ppg_failed_code		= try values.decode(Int.self, forKey: .ppg_failed_code)
			
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
			try container.encode(raw_data, forKey: .raw_data)
			
		case .rawPPGCompressedGreen,
			 .rawPPGCompressedIR,
			 .rawPPGCompressedRed:
			try container.encode(value, forKey: .value)
			try container.encode(raw_data, forKey: .raw_data)

		#if ETHOS || UNIVERSAL
		case .rawPPGCompressedWhiteIRRPD,
			 .rawPPGCompressedWhiteWhitePD:
			try container.encode(value, forKey: .value)
			try container.encode(raw_data, forKey: .raw_data)
		#endif

		case .rawPPGFifoCount,
			 .rawAccelFifoCount:
			try container.encode(value, forKey: .value)
			try container.encode(elapsed_ms, forKey: .elapsed_ms)
			
		case .rawAccel:
			try container.encode(x, forKey: .x)
			try container.encode(y, forKey: .y)
			try container.encode(z, forKey: .z)
			
		case .rawPPGRed:
			try container.encode(value, forKey: .value)

		case .rawPPGIR:
			try container.encode(value, forKey: .value)

		case .rawPPGProximity:
			try container.encode(value, forKey: .value)

		#if LIVOTAL
		case .rawPPGGreen:
			try container.encode(value, forKey: .value)
		#endif

		#if ETHOS || UNIVERSAL
		case .rawPPGGreenIRRPD:
			try container.encode(value, forKey: .value)

		case .rawPPGGreenWhitePD:
			try container.encode(value, forKey: .value)

		case .rawPPGWhiteIRRPD:
			try container.encode(value, forKey: .value)

		case .rawPPGWhiteWhitePD:
			try container.encode(value, forKey: .value)

		case .rawGyroADC:
			try container.encode(x_adc, forKey: .x_adc)
			try container.encode(y_adc, forKey: .y_adc)
			try container.encode(z_adc, forKey: .z_adc)
		#endif

		case .rawAccelADC:
			try container.encode(x_adc, forKey: .x_adc)
			try container.encode(y_adc, forKey: .y_adc)
			try container.encode(z_adc, forKey: .z_adc)

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
			try container.encode(ppg_failed_code, forKey: .ppg_failed_code)
			
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
