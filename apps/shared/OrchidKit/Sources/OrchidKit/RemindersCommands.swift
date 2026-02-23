import Foundation

public enum OrchidRemindersCommand: String, Codable, Sendable {
    case list = "reminders.list"
    case add = "reminders.add"
}

public enum OrchidReminderStatusFilter: String, Codable, Sendable {
    case incomplete
    case completed
    case all
}

public struct OrchidRemindersListParams: Codable, Sendable, Equatable {
    public var status: OrchidReminderStatusFilter?
    public var limit: Int?

    public init(status: OrchidReminderStatusFilter? = nil, limit: Int? = nil) {
        self.status = status
        self.limit = limit
    }
}

public struct OrchidRemindersAddParams: Codable, Sendable, Equatable {
    public var title: String
    public var dueISO: String?
    public var notes: String?
    public var listId: String?
    public var listName: String?

    public init(
        title: String,
        dueISO: String? = nil,
        notes: String? = nil,
        listId: String? = nil,
        listName: String? = nil)
    {
        self.title = title
        self.dueISO = dueISO
        self.notes = notes
        self.listId = listId
        self.listName = listName
    }
}

public struct OrchidReminderPayload: Codable, Sendable, Equatable {
    public var identifier: String
    public var title: String
    public var dueISO: String?
    public var completed: Bool
    public var listName: String?

    public init(
        identifier: String,
        title: String,
        dueISO: String? = nil,
        completed: Bool,
        listName: String? = nil)
    {
        self.identifier = identifier
        self.title = title
        self.dueISO = dueISO
        self.completed = completed
        self.listName = listName
    }
}

public struct OrchidRemindersListPayload: Codable, Sendable, Equatable {
    public var reminders: [OrchidReminderPayload]

    public init(reminders: [OrchidReminderPayload]) {
        self.reminders = reminders
    }
}

public struct OrchidRemindersAddPayload: Codable, Sendable, Equatable {
    public var reminder: OrchidReminderPayload

    public init(reminder: OrchidReminderPayload) {
        self.reminder = reminder
    }
}
