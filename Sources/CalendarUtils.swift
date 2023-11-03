//
//  CalendarUtils.swift
//  CalSync
//
//  Created by Thomas Preece on 24/10/2023.
//

import Foundation
import EventKit

let today = Calendar.current.startOfDay(for: Date())

enum CalSyncError: Error {
    case runtimeError(String)
}

func createSyncSetting(calendars: [EKCalendar]) throws -> SyncSetting {
    guard !calendars.isEmpty else {
        print("No calendars available.")
        throw CalSyncError.runtimeError("No calendars available.")
    }
    
    printCalendars(calendars: calendars)
            
    print("\nEnter the number of the calendar you want to pull events from:")
    guard let pullCalendar = try? selectCalendar(calendars:calendars) else {
        throw CalSyncError.runtimeError("Invalid pull calendar selection")
    }
    
    print("\nEnter the number of the calendar you want to push to:")
    guard let pushCalendar = try? selectCalendar(calendars:calendars) else {
        throw CalSyncError.runtimeError("Invalid push calendar selection")
    }
    
    print("\nEnter the number of days you want to sync:")
    let numDays = selectNumDays()
    
    print("\nEnter the name of the generic event to use:")
    guard let eventName = readLine() else {
        throw CalSyncError.runtimeError("Event name not provided")
    }
    
   let newSync = SyncSetting(
        pullCalendarIdentifier: pullCalendar.calendarIdentifier,
        pullCalendarTitle: pullCalendar.title,
        pushCalendarIdentifier: pushCalendar.calendarIdentifier,
        pushCalendarTitle: pushCalendar.title,
        eventName: eventName, numDays: numDays
    )
    return newSync
}


func printCalendars(calendars: [EKCalendar]) {
    for (index, calendar) in calendars.enumerated() {
        print("\(index + 1). \(calendar.title) - \(calendar.source.title)")
    }
}

func selectCalendar(calendars: [EKCalendar]) throws -> EKCalendar {
    guard !calendars.isEmpty else {
        print("No calendars available.")
        throw CalSyncError.runtimeError("No calendars available.")
    }
    
    while true {
        if let input = readLine(), let selectedCalendarIndex = Int(input) {
            let selectedIndex = selectedCalendarIndex - 1
            if selectedIndex >= 0 && selectedIndex < calendars.count {
                return calendars[selectedIndex]
            } else {
                print("Invalid calendar number. Please select a valid option.")
            }
        } else {
            print("Invalid input. Please enter the number corresponding to the calendar.")
        }
    }
}

func selectNumDays() -> Int {
    while true {
        if let input = readLine(), let selectedNumDays = Int(input) {
            return selectedNumDays
        } else {
            print("Invalid input. Please enter a number")
        }
    }
}

func getEventsNextXDays(calendar: EKCalendar, eventStore: EKEventStore, numDays: Int) -> [EKEvent] {
    
    let endOfHorizon = Calendar.current.date(byAdding: .day, value: numDays, to: today)!
    let predicate = eventStore.predicateForEvents(withStart: today, end: endOfHorizon, calendars: [calendar])
    let events = eventStore.events(matching: predicate)
    return events
}

func getNonCalSyncEventsNextXDays(calendar: EKCalendar, eventStore: EKEventStore, numDays: Int) -> [EKEvent] {
    let events = getEventsNextXDays(calendar: calendar, eventStore: eventStore, numDays: numDays)
    let nonCalSyncEvents = events.filter { event in
        return !(event.notes?.contains("Made by CalSync") == true)
    }
    return nonCalSyncEvents
}

func getCalSyncEventsNextXDays(calendar: EKCalendar, eventStore: EKEventStore, numDays: Int) -> [EKEvent] {
    let events = getEventsNextXDays(calendar: calendar, eventStore: eventStore, numDays: numDays)
    let calSyncEvents = events.filter { event in
        return event.notes?.contains("Made by CalSync") == true
    }
    return calSyncEvents
}

func deleteEvents(eventStore: EKEventStore, events: [EKEvent]) {
    for event in events {
        do {
            try eventStore.remove(event, span: .thisEvent)
        } catch {
            print("Error deleting event: \(event) \(error.localizedDescription)")
        }
    }
}