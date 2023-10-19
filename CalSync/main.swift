//
//  main.swift
//  CalSync
//
//  Created by Thomas Preece on 18/10/2023.
//

import EventKit
import Foundation
import Dispatch

enum CalSyncError: Error {
    case runtimeError(String)
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

func main() {
    let asciiArtBanner = """
       ____     _       _           ____      __   __  _   _      ____
    U /"___|U  /\"\\  u  |\"|         / __\"| u   \\ \\ / / | \\ |\"|  U /\"___|
    \\| | u   \\/ _ \\/ U | | u      <\\___ \\/     \\ V / <|  \\| |> \\| | u
     | |/__  / ___ \\  \\| |/__      u___) |    U_|\"|_uU| |\\  |u  | |/__
      \\____|/_/   \\_\\  |_____|     |____/>>     |_|   |_| \\_|    \\____|
     _// \\\\  \\\\    >>  //  \\\\       )(  (__).-,//|(_  ||   \\\\,-._// \\\\
    (__)(__)(__)  (__)(\"_\")("_)     (__)      \\_) (__) (\"_)  (_/(__)(__)
    \n
    """
    print(asciiArtBanner)
    
    
    let eventStore = EKEventStore()
    
    // Request access to the user's Calendar data
    eventStore.requestAccess(to: .event) { (granted, error) in
        if granted && error == nil {
            let calendars = eventStore.calendars(for: .event)
            
            printCalendars(calendars: calendars)
            
            print("\nEnter the number of the calendar you want to pull events from:")
            let pullCalendar = try? selectCalendar(calendars:calendars)
            
            print("\nEnter the number of the calendar you want to push to:")
            let pushCalendar = try? selectCalendar(calendars:calendars)
            
            if let pullCalendar = pullCalendar, let pushCalendar = pushCalendar {
                print("\nEnter the number of days you want to sync:")
                let numDays = selectNumDays()
                
                print("\nEnter the name of the generic event to use:")
                if let eventName = readLine() {
                    // Clear out current CalSync events over sync horizon
                    let calSyncEvents = getCalSyncEventsNextXDays(calendar: pushCalendar, eventStore: eventStore, numDays: numDays)
                    
                    deleteEvents(eventStore: eventStore, events: calSyncEvents)
                    
                    // Make new events
                    print("\nSyncing Events")
                    let events = getNonCalSyncEventsNextXDays(calendar: pullCalendar, eventStore: eventStore, numDays: numDays)
                    for event in events {
                        print("Event: \(String(describing: event.title))")
                        let newEvent = EKEvent(eventStore: eventStore)
                        newEvent.title = eventName
                        newEvent.notes = "Made by CalSync"
                        newEvent.startDate = event.startDate
                        newEvent.endDate = event.endDate
                        newEvent.calendar = pushCalendar
                        
                        do {
                            try eventStore.save(newEvent, span: .thisEvent)
                        } catch {
                            print("Error saving event: \(error.localizedDescription)")
                        }
                    }
                }
            }
            // After processing all events, exit the app gracefully
            DispatchQueue.main.async {
                exit(0)
            }
        } else {
            print("Access to the Calendar data was not granted.")
        }
    }
}

let today = Calendar.current.startOfDay(for: Date())

// Call the main function
main()

RunLoop.main.run()
