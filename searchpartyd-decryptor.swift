//
//  airtag-decryptor.swift
//
//  Decrypt all beacons files from ~/Library/com.apple.icloud.searchpartyd - updated when FindMy is running
//  Results in /tmp/com.apple.icloud.searchpartyd - same file hierarchy
//
//  Created by Matus on 28/01/2024. - https://gist.github.com/YeapGuy/f473de53c2a4e8978bc63217359ca1e4
//  Modified by Airy https://gist.github.com/airy10/5205dc851fbd0715fcd7a5cdde25e7c8
//  Modified by pajowu https://github.com/pajowu/beaconstorekey-extractor
//
import Cocoa
import Foundation
import CryptoKit

extension URL {
    var isDirectory: Bool {
        (try? resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true
    }
}

// Function to decrypt using AES-GCM
func decryptRecordFile(fileURL: URL, key: SymmetricKey) throws -> [String: Any] {
    // Read data from the file
    let data = try Data(contentsOf: fileURL)

    // Convert data to a property list (plist)
    guard let plist = try PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [Any] else {
        throw MyError.invalidFileFormat
    }

    // Extract nonce, tag, and ciphertext
    guard plist.count >= 3,
          let nonceData = plist[0] as? Data,
          let tagData = plist[1] as? Data,
          let ciphertextData = plist[2] as? Data else {
        throw MyError.invalidPlistFormat
    }

    let sealedBox = try AES.GCM.SealedBox(nonce: AES.GCM.Nonce(data: nonceData), ciphertext: ciphertextData, tag: tagData)

    // Decrypt using AES-GCM
    let decryptedData = try AES.GCM.open(sealedBox, using: key)

    // Convert decrypted data to a property list
    guard let decryptedPlist = try PropertyListSerialization.propertyList(from: decryptedData, options: [], format: nil) as? [String: Any] else {
        throw MyError.invalidDecryptedData
    }

    return decryptedPlist
}

func decryptDirectory(filePath: String, outputPath: String, key: SymmetricKey) throws {
    let baseURL = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first
    if let contentURL = baseURL?.appending(path: filePath) {
        if contentURL.isDirectory {
            if let urls = try? FileManager.default.contentsOfDirectory(at: contentURL, includingPropertiesForKeys: nil) {
                for url in urls {
                    let path = (filePath as NSString).appendingPathComponent(url.lastPathComponent)
                    try decryptDirectory(filePath: path, outputPath: outputPath, key: key)
                }
            }
        } else {
            do {
                let decryptedPlist = try decryptRecordFile(fileURL: contentURL, key: key)
                // Save decrypted plist as a file in the current directory
                let name = contentURL.lastPathComponent as NSString
                if let outputName = (name.deletingPathExtension as NSString).appendingPathExtension("plist") {

                    let dir = (filePath as NSString).deletingLastPathComponent
                    let outputDirPath = (outputPath as NSString).appendingPathComponent(dir)
                    try FileManager.default.createDirectory(atPath: outputDirPath, withIntermediateDirectories: true)

                    let outputURL = URL(fileURLWithPath: outputDirPath).appending(path: outputName)
                    try PropertyListSerialization.data(fromPropertyList: decryptedPlist, format: .xml, options: 0).write(to: outputURL)
                }
            } catch {
                print("Error:", error)
            }

            print(filePath)
        }
    }
}

// Function to convert hex string to Data
func data(fromHex hex: String) -> Data {
    var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
    hexSanitized = hexSanitized.replacingOccurrences(of: "0x", with: "")

    var data = Data(capacity: hexSanitized.count / 2)
    var index = hexSanitized.startIndex

    while index < hexSanitized.endIndex {
        let byteString = hexSanitized[index ..< hexSanitized.index(index, offsetBy: 2)]
        let byte = UInt8(byteString, radix: 16)!
        data.append(byte)
        index = hexSanitized.index(index, offsetBy: 2)
    }

    return data
}

func decryptAndOpen(keyData: Data) throws {

    let key = SymmetricKey(data: keyData)

    let basePath = "com.apple.icloud.searchpartyd"
    let outputPath = NSTemporaryDirectory()

    try decryptDirectory(filePath: basePath, outputPath: outputPath, key: key)

    let resultURL = URL(filePath: basePath, relativeTo: URL(filePath: outputPath))
    NSWorkspace.shared.open(resultURL)

}

enum MyError: Error {
    case invalidFileFormat
    case invalidPlistFormat
    case invalidDecryptedData
    case noPassword
    case invalidItem
    case keychainError(status: OSStatus)
}


print("Enter the BeaconStoreKey:")
let response = readLine()!
let keyData = data(fromHex: response)
try decryptAndOpen(keyData: keyData)
