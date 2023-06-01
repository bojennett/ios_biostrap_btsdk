//
//  biostrapStreamingPacket.swift
//  biostrapDeviceSDK
//
//  Created by Joseph A. Bennett on 5/30/23.
//

import Foundation

@objc public class biostrapStreamingPacket: NSObject, Codable {
	public var type						: streamingType		= .unknown
	public var epoch_sec				: Int				= 0
	public var epoch_ms					: Int				= 0
	public var hr_bpm					: Int				= 0
	public var cadence_spm				: Int				= 0
	public var hr_confidence			: Int				= 0
	public var cadence_confidence		: Int				= 0
	public var rmssd_ms					: Int				= 0
	public var numberOfDatapoints		: Int				= 0
	public var rr_bpm					: Int				= 0
	public var snr_ratio				: Int				= 0
	public var bbi_ms					: Int				= 0
	public var snr_type					: Int				= 0
	public var ppg						: Float				= 0.0
	public var ppgWavelengths			: wavelengthType	= .unknown
	public var motionState				: Bool				= false
	public var raw_data_string			: String			= ""

	//--------------------------------------------------------------------------------
	//
	// Used for JSON encode/decode
	//
	//--------------------------------------------------------------------------------
	enum CodingKeys: String, CodingKey {
		case type
		case epoch_sec
		case epoch_ms
		case hr_bpm
		case cadence_spm
		case hr_confidence
		case cadence_confidence
		case rmssd_ms
		case numberOfDatapoints
		case rr_bpm
		case snr_ratio
		case bbi_ms
		case snr_type
		case ppg
		case ppgWavelengths
		case motionState
		case raw_data_string
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
		case .hr							: return "\(raw_data_string),\(type.title),\(epoch_sec),\(hr_bpm),\(cadence_spm),\(hr_confidence),\(cadence_confidence)"
		case .hrv							: return "\(raw_data_string),\(type.title),\(epoch_sec),\(rmssd_ms),\(numberOfDatapoints)"
		case .rr							: return "\(raw_data_string),\(type.title),\(epoch_sec),\(rr_bpm),\(snr_ratio)"
		case .bbi							: return "\(raw_data_string),\(type.title),\(epoch_ms),\(bbi_ms),\(snr_ratio)"
		case .ppgSNR						: return "\(raw_data_string),\(type.title),\(epoch_sec),\(snr_ratio),\(snr_type)"
		case .ppgWave						: return "\(raw_data_string),\(type.title),\(epoch_ms),\(ppg),\(ppgWavelengths.title)"
		case .motionState					: return "\(raw_data_string),\(type.title),\(motionState)"
		case .unknown						: return "\(raw_data_string),\(type.title)"
		}
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
		if let thisType = streamingType(rawValue: data[0]) {
			type					= thisType
			raw_data_string			= data.hexString.replacingOccurrences(of: "[ ", with: "").replacingOccurrences(of: " ]", with: "")

			switch (type) {
			case .hr:
				epoch_sec			= data.subdata(in: Range(2...5)).leInt32
				hr_bpm				= Int(data[6])
				cadence_spm			= Int(data[7])
				hr_confidence		= Int(data[8])
				cadence_confidence	= Int(data[9])
				
			case .hrv:
				epoch_sec			= data.subdata(in: Range(2...5)).leInt32
				rmssd_ms			= Int(data[6])
				numberOfDatapoints	= Int(data[7])

			case .rr:
				epoch_sec			= data.subdata(in: Range(2...5)).leInt32
				rr_bpm				= Int(data[6])
				snr_ratio			= Int(data[7])

			case .bbi:
				epoch_ms			= data.subdata(in: Range(2...9)).leInt64
				bbi_ms				= data.subdata(in: Range(10...11)).leUInt16
				snr_ratio			= Int(data[12])

			case .ppgSNR:
				epoch_sec			= data.subdata(in: Range(2...5)).leInt32
				snr_ratio			= Int(data[6])
				snr_type			= Int(data[7])

			case .ppgWave:
				epoch_ms			= data.subdata(in: Range(2...9)).leInt64
				ppg					= data.subdata(in: Range(10...13)).leFloat
				ppgWavelengths		= .unknown
				if let test = wavelengthType(rawValue: data[14]) { ppgWavelengths = test }

			case .motionState:
				motionState			= (data[3] != 0x00)
				
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
		type 					= try values.decode(streamingType.self, forKey: .type)
		
		raw_data_string			= try values.decode(String.self, forKey: .raw_data_string)
		
		switch (type) {
		case .hr:
			epoch_sec			= try values.decode(Int.self, forKey: .epoch_sec)
			hr_bpm				= try values.decode(Int.self, forKey: .hr_bpm)
			cadence_spm			= try values.decode(Int.self, forKey: .cadence_spm)
			hr_confidence		= try values.decode(Int.self, forKey: .hr_confidence)
			cadence_confidence	= try values.decode(Int.self, forKey: .cadence_confidence)
			
		case .hrv:
			epoch_sec			= try values.decode(Int.self, forKey: .epoch_sec)
			rmssd_ms			= try values.decode(Int.self, forKey: .rmssd_ms)
			numberOfDatapoints	= try values.decode(Int.self, forKey: .numberOfDatapoints)

		case .rr:
			epoch_sec			= try values.decode(Int.self, forKey: .epoch_sec)
			rr_bpm				= try values.decode(Int.self, forKey: .rr_bpm)
			snr_ratio			= try values.decode(Int.self, forKey: .snr_ratio)

		case .bbi:
			epoch_ms			= try values.decode(Int.self, forKey: .epoch_ms)
			bbi_ms				= try values.decode(Int.self, forKey: .bbi_ms)
			snr_ratio			= try values.decode(Int.self, forKey: .snr_ratio)

		case .ppgSNR:
			epoch_sec			= try values.decode(Int.self, forKey: .epoch_sec)
			snr_ratio			= try values.decode(Int.self, forKey: .snr_ratio)
			snr_type			= try values.decode(Int.self, forKey: .snr_type)

		case .ppgWave:
			epoch_ms			= try values.decode(Int.self, forKey: .epoch_ms)
			ppg					= try values.decode(Float.self, forKey: .ppg)
			ppgWavelengths		= try values.decode(wavelengthType.self, forKey: .ppgWavelengths)

		case .motionState:
			motionState			= try values.decode(Bool.self, forKey: .motionState)
			
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
		
		try container.encode(raw_data_string, forKey: .raw_data_string)
		
		switch (type) {
		case .hr:
			try container.encode(epoch_sec, forKey: .epoch_sec)
			try container.encode(hr_bpm, forKey: .hr_bpm)
			try container.encode(cadence_spm, forKey: .cadence_spm)
			try container.encode(hr_confidence, forKey: .hr_confidence)
			try container.encode(cadence_confidence, forKey: .cadence_confidence)

		case .hrv:
			try container.encode(epoch_sec, forKey: .epoch_sec)
			try container.encode(rmssd_ms, forKey: .rmssd_ms)
			try container.encode(numberOfDatapoints, forKey: .numberOfDatapoints)

		case .rr:
			try container.encode(epoch_sec, forKey: .epoch_sec)
			try container.encode(rr_bpm, forKey: .rr_bpm)
			try container.encode(snr_ratio, forKey: .snr_ratio)

		case .bbi:
			try container.encode(epoch_ms, forKey: .epoch_ms)
			try container.encode(bbi_ms, forKey: .bbi_ms)
			try container.encode(snr_ratio, forKey: .snr_ratio)

		case .ppgSNR:
			try container.encode(epoch_sec, forKey: .epoch_sec)
			try container.encode(snr_ratio, forKey: .snr_ratio)
			try container.encode(snr_type, forKey: .snr_type)
			
		case .ppgWave:
			try container.encode(epoch_ms, forKey: .epoch_ms)
			try container.encode(ppg, forKey: .ppg)
			try container.encode(ppgWavelengths.title, forKey: .ppgWavelengths)

		case .motionState:
			try container.encode(motionState, forKey: .motionState)
			
		case .unknown: break
		}
	}
}
