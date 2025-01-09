//
//  main.swift
//  CalSync
//
//  Created by Thomas Preece on 18/10/2023.
//  Modified by Gordon Mickel on 09/01/2024.
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
                        
                        print("Starting sync from '\(pullCalendar.title)' to '\(pushCalendar.title)'")
                        
                        // Clear out current CalSync events over sync horizon
                        let calSyncEvents = getCalSyncEventsNextXDays(calendar: pushCalendar, eventStore: eventStore, numDays: sync.numDays)
                        print("Found \(calSyncEvents.count) existing CalSync events to clean up")
                        
                        deleteEvents(eventStore: eventStore, events: calSyncEvents)
                        
                        // Make new events
                        let events = getNonCalSyncEventsNextXDays(calendar: pullCalendar, eventStore: eventStore, numDays: sync.numDays)
                        print("Found \(events.count) events to sync")
                        
                        for event in events {
                            print("Syncing event: '\(event.title ?? "Untitled")' from \(String(describing: event.startDate)) to \(String(describing: event.endDate))")
                            print("Is recurring: \(event.recurrenceRules != nil)")
                            
                            let newEvent = EKEvent(eventStore: eventStore)
                            
                            // Copy basic details
                            newEvent.title = event.title
                            newEvent.notes = "Made by CalSync\n\n" + (event.notes ?? "")
                            newEvent.startDate = event.startDate
                            newEvent.endDate = event.endDate
                            newEvent.calendar = pushCalendar
                            newEvent.location = event.location
                            newEvent.url = event.url
                            newEvent.isAllDay = event.isAllDay
                            newEvent.availability = event.availability
                            
                            // Handle recurrence rules carefully
                            if let recurrenceRules = event.recurrenceRules {
                                print("Copying recurrence rules: \(recurrenceRules)")
                                // Create new instances of recurrence rules to avoid reference issues
                                newEvent.recurrenceRules = recurrenceRules.map { rule in
                                    let newRule = EKRecurrenceRule(
                                        recurrenceWith: rule.frequency,
                                        interval: rule.interval,
                                        daysOfTheWeek: rule.daysOfTheWeek,
                                        daysOfTheMonth: rule.daysOfTheMonth,
                                        monthsOfTheYear: rule.monthsOfTheYear,
                                        weeksOfTheYear: rule.weeksOfTheYear,
                                        daysOfTheYear: rule.daysOfTheYear,
                                        setPositions: rule.setPositions,
                                        end: rule.recurrenceEnd
                                    )
                                    return newRule
                                }
                            }
                            
                            // Copy alarms if any
                            if let alarms = event.alarms {
                                newEvent.alarms = alarms.map { alarm in
                                    // Create new alarm instance to avoid reference issues
                                    let newAlarm = EKAlarm(relativeOffset: alarm.relativeOffset)
                                    return newAlarm
                                }
                            }
                            
                            do {
                                let span: EKSpan = event.recurrenceRules != nil ? .futureEvents : .thisEvent
                                try eventStore.save(newEvent, span: span)
                                print("Successfully created event: \(newEvent.title ?? "Untitled")")
                            } catch {
                                print("Error saving event: \(error.localizedDescription)")
                            }
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
