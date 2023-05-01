//
//  AES.swift
//  biostrapSDKKeyGeneration
//
//  Created by Joseph A. Bennett on 4/28/23.
//  Copyright © 2023 Joseph A Bennett. All rights reserved.
//

import Foundation
import CommonCrypto

struct AES {
	
	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	// Generate a 128-bit key
	//
	//--------------------------------------------------------------------------------
	static func generateKey() -> Data? {
		var bytes = [UInt8](repeating: 0, count: 16)
		if SecRandomCopyBytes(kSecRandomDefault, 16, &bytes) == errSecSuccess{
			return Data(bytes)
		}
		
		return nil
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	// Encrypt data
	//
	//--------------------------------------------------------------------------------
	static func encrypt(_ data: Data, key: Data, seed: Data) -> Data? {
		if (key.isEmpty)  { print ("AES Encrypt: Key Missing") }
		if (seed.isEmpty) { print ("AES Encrypt: Seed Missing") }
		
		if (key.isEmpty || seed.isEmpty) { return nil }
		
		if let encryptedData = self.mCrypt(kCCEncrypt, data: data, key: key, seed: seed) {
			return (encryptedData)
		}
		
		return nil
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	// Decrypt data
	//
	//--------------------------------------------------------------------------------
	static func decrypt(_ data: Data, key: Data, seed: Data) -> Data? {
		if (key.isEmpty)  { print ("AES Decrypt: Key Missing") }
		if (seed.isEmpty) { print ("AES Decrypt: Seed Missing") }
		
		if (key.isEmpty || seed.isEmpty) {
			return nil
		}
		
		if let decryptedData = self.mCrypt(kCCDecrypt, data: data, key: key, seed: seed) {
			return decryptedData
		}
		
		return nil
	}

	//--------------------------------------------------------------------------------
	// Function Name:
	//--------------------------------------------------------------------------------
	//
	// Encrypt data
	//
	//--------------------------------------------------------------------------------
	internal static func mCrypt(_ operation: Int, data: Data, key: Data, seed: Data) -> Data? {
		
		return key.withUnsafeBytes { (keyPointer) in
			seed.withUnsafeBytes { (ivPointer) in
				data.withUnsafeBytes { (dataInPointer) -> Data? in
					var dataOutMoved: Int = 0
					let dataOutAvailable: Int = dataInPointer.count + kCCBlockSizeAES128 * 2
					let dataOut = UnsafeMutableRawPointer.allocate(byteCount: dataOutAvailable, alignment: 1)
					defer { dataOut.deallocate() }
					let status = CCCrypt(CCOperation(operation), CCAlgorithm(kCCAlgorithmAES), CCOptions(kCCOptionPKCS7Padding), keyPointer.baseAddress, keyPointer.count, ivPointer.baseAddress, dataInPointer.baseAddress, dataInPointer.count, dataOut, dataOutAvailable, &dataOutMoved)
					
					guard status == kCCSuccess else { return nil }
					return Data(bytes: dataOut, count: dataOutMoved)
				}
			}
		}
	}

}
