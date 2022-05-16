//
//  HabitViewModel.swift
//  HabitTracker
//
//  Created by Chirag on 5/12/22.
//

import Foundation
import SwiftUI
import CoreData
import UserNotifications
class HabitViewModel: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    // MARK: New Habit Properties
    @Published var addNewHabit: Bool = false
    
    @Published var title: String = ""
    @Published var habitcolor: String = "Card-1"
    @Published var weekDays: [String] = []
    @Published var isRemainderOn: Bool = false
    @Published var remainderText: String = ""
    @Published var remainderDate: Date = Date()
    
    // MARK: Remainder Time Picker
    
    @Published var showTimePicker: Bool = false
    
    // MARK: Editing Habit....
    @Published var editHabit: Habit?
    
    // MARK: Notification Access Status
    @Published var notificartionAccess: Bool = false
    
    override init(){
        super.init()
        requestNotificationAccess()
    }
    
    
    func requestNotificationAccess(){
        UNUserNotificationCenter.current().requestAuthorization(options: [.sound, .alert, .badge]) { status, _ in
            DispatchQueue.main.async {
                self.notificartionAccess = status
            }
        }
        // MARK: To Show In App Notification
        UNUserNotificationCenter.current().delegate = self
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.sound, .banner])
    }
    
    // MARK: Adding Habit to Database
    func addHabbit(context: NSManagedObjectContext)async -> Bool {
        
        // MARK: Editing Data
        var habit: Habit!
        if let editHabit = editHabit {
            habit = editHabit
            // removing all pending notification
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: editHabit.notificationIDs ?? [])
        }else {
            habit = Habit(context: context)
        }
        habit.title = title
        habit.color = habitcolor
        habit.weekDays = weekDays
        habit.isRemainderOn = isRemainderOn
        habit.remainderText = remainderText
        habit.notificationDate = remainderDate
        habit.notificationIDs = []
        
        if isRemainderOn {
            // MARK: Scheduling Notification...
            if let ids = try? await scheduleNotification() {
                habit.notificationIDs = ids
                if let _ = try? context.save() {
                   return true
                }
            }
        }else {
            // MARK: Adding Data
            if let _ = try? context.save() {
               return true
            }
        }
        return false
    }
    
    // MARK: Adding Notification....
    func scheduleNotification()async throws -> [String]{
        let content = UNMutableNotificationContent()
        content.title = "Habit Remainder"
        content.subtitle = remainderText
        content.sound = UNNotificationSound.default
        
        // Scheduled Ids
        var notificationIds:[String] = []
        let calendar = Calendar.current
        let weekdaySymbols: [String] = calendar.weekdaySymbols
        // MARK: Scheduling Notification
        for weekDay in weekDays {
            // UNIQUE Id for each notification
            let id = UUID().uuidString
            let hour = calendar.component(.hour, from: remainderDate)
            let min = calendar.component(.minute, from: remainderDate)
            let day = weekdaySymbols.firstIndex { currentDay in
                return currentDay == weekDay
            } ?? -1
            
            // MARK: Since Week Day Starts From 1-7
            // Thus Adding +1 to Index
            if day != -1 {
                var components = DateComponents()
                components.hour = hour
                components.minute = min
                components.day = day + 1
                // MARK: Thus this will Trigger Notification on each selected Day
                let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
                
                // MARK: Notification Request
                let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
                
                try await UNUserNotificationCenter.current().add(request)
                
                // Adding IDs
                notificationIds.append(id)
            }
        }
        return notificationIds
    }
    
    // MARK: Erasing Data....
    func resetData(){
        title = ""
        habitcolor = "Card-1"
        weekDays = []
        isRemainderOn = false
        remainderDate = Date()
        remainderText = ""
        editHabit = nil
    }
    
    // MARK: Deleting Habit From Database
    func deleteHabit(context: NSManagedObjectContext) -> Bool{
        if let editHabit = editHabit {
            if editHabit.isRemainderOn {
                // removing all pending notification
                UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: editHabit.notificationIDs ?? [])
            }
            context.delete(editHabit)
            if let _ = try? context.save() {
                return true
            }
        }
        return false
    }
    // MARK: Restoring Edit Data
    func restoreEditData(){
        if let editHabit = editHabit {
            title = editHabit.title ?? ""
            habitcolor = editHabit.color ?? "Card-1"
            weekDays = editHabit.weekDays ?? []
            isRemainderOn = editHabit.isRemainderOn
            remainderDate = editHabit.notificationDate ?? Date()
            remainderText = editHabit.remainderText ?? ""
        }
    }
    
    // MARK: Done Button Status
    func doneStatus() -> Bool{
        let remainderStatus = isRemainderOn ? remainderText == "" : false
        if title == "" || weekDays.isEmpty || remainderStatus { return false}
        return true
    }
}
