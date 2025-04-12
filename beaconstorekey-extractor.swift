//
//  beaconstorekey-extractor.swift
//
//  Decrypt all beacons files from ~/Library/com.apple.icloud.searchpartyd - updated when FindMy is running
//  Results in /tmp/com.apple.icloud.searchpartyd - same file hierarchy
//
//  Created by Matus on 28/01/2024. - https://gist.github.com/YeapGuy/f473de53c2a4e8978bc63217359ca1e4
//  Modified by Airy
//
import Foundation

enum ExtractorError: Error {
    case notFound
    case invalid
    case keychainError(status: OSStatus, description: CFString)
}

let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                            kSecAttrService as String: "BeaconStore",
                            kSecMatchLimit as String: kSecMatchLimitOne,
                            kSecReturnData as String: true,
                                                        kSecReturnAttributes as String: true,

                            ]

var item: CFTypeRef?
let status = SecItemCopyMatching(query as CFDictionary, &item)
let errorDescription = SecCopyErrorMessageString(status,nil)

guard status != errSecItemNotFound else { throw ExtractorError.notFound }
guard status == errSecSuccess else { throw ExtractorError.keychainError(status: status, description: errorDescription!) }
guard let existingItem = item as? [String : Any] else  { throw ExtractorError.invalid }

print(existingItem)
// guard let data = item as? Data else  { throw ExtractorError.invalid };

// let hexString = data.map { String(format: "%02hhx", $0) }.joined()

// print("Found key in keychain:")
// print(hexString)
