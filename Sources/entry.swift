//
//  main.swift
//  CalSync
//
//  Created by Thomas Preece on 18/10/2023.
//

import EventKit
import Foundation
import Dispatch
import ArgumentParser


@main
struct CalSync: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "CalSync",
        abstract: "A utility for syncing calendars in a way that keeps event details private",
        subcommands: [RunCommand.self, ListCommand.self, AddCommand.self, RemoveCommand.self]
    )
    func validate() throws {
        if CommandLine.arguments.count <= 1 {
            print(asciiArtBanner)
        }
    }
}

struct RunCommand: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "run",
        abstract: "Run configured syncs"
    )

    func run() {
        let eventStore = EKEventStore()
        
        eventStore.requestFullAccessToEvents { (granted, error) in
            if granted && error == nil {
                let calendars = eventStore.calendars(for: .event)
                let settings = read_settings()
                
                for sync in settings.syncs {
                    do {
                        guard let pullCalendar = calendars.first(where: { $0.calendarIdentifier == sync.pullCalendarIdentifier}) else {
                            throw CalSyncError.runtimeError("Could not find pull calendar \(sync.pullCalendarIdentifier) in event store")
                        }
                        guard let pushCalendar = calendars.first(where:{ $0.calendarIdentifier == sync.pushCalendarIdentifier}) else {
                            throw CalSyncError.runtimeError("Could not find push calendar \(sync.pushCalendarIdentifier) in event store")
                        }
                        
                        // Clear out current CalSync events over sync horizon
                        let calSyncEvents = getCalSyncEventsNextXDays(calendar: pushCalendar, eventStore: eventStore, numDays: sync.numDays)
                        
                        deleteEvents(eventStore: eventStore, events: calSyncEvents)
                        
                        // Make new events
                        let events = getNonCalSyncEventsNextXDays(calendar: pullCalendar, eventStore: eventStore, numDays: sync.numDays)
                        
                        for event in events {
                            print("Event: \(String(describing: event.title))")
                            let newEvent = EKEvent(eventStore: eventStore)
                            newEvent.title = sync.eventName
                            newEvent.notes = "Made by CalSync"
                            newEvent.startDate = event.startDate
                            newEvent.endDate = event.endDate
                            newEvent.calendar = pushCalendar
                            
                            try eventStore.save(newEvent, span: .thisEvent)
                        }
                        
                    } catch {
                        print("Error: \(error)")
                    }
                }
                
                AddCommand.exit(withError: 0 as? Error)
            } else {
                print("Access to the Calendar data was not granted.")
            }
        }
        // Allow asynchronous events to run
        RunLoop.main.run()
    }
}

struct ListCommand: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "list",
        abstract: "Lists configured syncs"
    )
    
    func run() {
        let settings = read_settings()
        printCalSyncSettings(settings: settings)
    }
}

struct AddCommand: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "add",
        abstract: "Add a sync"
    )
    
    func run() {
        print(asciiArtBanner)
        let eventStore = EKEventStore()

        eventStore.requestFullAccessToEvents { (granted, error) in
            if granted && error == nil {
                let calendars = eventStore.calendars(for: .event)
                
                do {
                    let newSyncSetting = try createSyncSetting(calendars: calendars)
                    var settings = read_settings()
                    settings.syncs.append(newSyncSetting)
                    write_settings(settings: settings)
                } catch {
                    print("Error creating sync setting: \(error)")
                }
                AddCommand.exit(withError: 0 as? Error)
            } else {
                print("Access to the Calendar data was not granted.")
            }
        }
        // Allow asynchronous events to run
        RunLoop.main.run()
    }
}


struct RemoveCommand: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "remove",
        abstract: "Remove a sync"
    )
    
    @Argument(help: "Id of sync to remove")
    var id: String
    
    func run() {
        var settings = read_settings()
        let idToDelete = UUID(uuidString: id)
        settings.syncs.removeAll(where: {$0.id == idToDelete})
        write_settings(settings: settings)
    }
}
