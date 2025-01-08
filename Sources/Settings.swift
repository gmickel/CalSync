//
//  Settings.swift
//  CalSync
//
//  Created by Thomas Preece on 25/10/2023.
//  Modified by Gordon Mickel on 09/01/2024.
//

import Foundation

struct SyncSetting: Codable {
    var id = UUID()
    let pullCalendarIdentifier: String
    let pullCalendarTitle: String
    let pushCalendarIdentifier: String
    let pushCalendarTitle: String
    let numDays: Int
}

struct CalSyncSettings: Codable {
    var syncs: [SyncSetting]
}

func printCalSyncSettings(settings: CalSyncSettings) {
    let encoder = JSONEncoder()
    encoder.outputFormatting = .prettyPrinted
    let encodedSettings = try! encoder.encode(settings.syncs)
    print(String(data: encodedSettings, encoding: .utf8)!)
}

func read_settings() -> CalSyncSettings {
    let fileURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!.appendingPathComponent("CalSync/settings.json")
    let decoder = JSONDecoder()
    
    if let data = try? Data(contentsOf: fileURL),
       let settings = try? decoder.decode(CalSyncSettings.self, from: data) {
        return settings
    } else {
        // No file found use default settings
        let settings = CalSyncSettings(syncs: [])
        return settings
    }
}

func write_settings(settings: CalSyncSettings) {
    let fileManager = FileManager.default
    let directoryURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!.appendingPathComponent("CalSync")
    
    // Create the directory if it doesn't exist
    if !fileManager.fileExists(atPath: directoryURL.path) {
        do {
            try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true, attributes: nil)
        } catch {
            print("Error creating directory: \(error)")
        }
    }
    
    let fileURL = directoryURL.appendingPathComponent("settings.json")
    
    let encoder = JSONEncoder()
    do {
        let data = try encoder.encode(settings)
        try data.write(to: fileURL)
    } catch {
        print("Error writing the file: \(error)")
    }
}
