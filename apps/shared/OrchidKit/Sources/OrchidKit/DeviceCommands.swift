import Foundation

public enum OrchidDeviceCommand: String, Codable, Sendable {
    case status = "device.status"
    case info = "device.info"
}

public enum OrchidBatteryState: String, Codable, Sendable {
    case unknown
    case unplugged
    case charging
    case full
}

public enum OrchidThermalState: String, Codable, Sendable {
    case nominal
    case fair
    case serious
    case critical
}

public enum OrchidNetworkPathStatus: String, Codable, Sendable {
    case satisfied
    case unsatisfied
    case requiresConnection
}

public enum OrchidNetworkInterfaceType: String, Codable, Sendable {
    case wifi
    case cellular
    case wired
    case other
}

public struct OrchidBatteryStatusPayload: Codable, Sendable, Equatable {
    public var level: Double?
    public var state: OrchidBatteryState
    public var lowPowerModeEnabled: Bool

    public init(level: Double?, state: OrchidBatteryState, lowPowerModeEnabled: Bool) {
        self.level = level
        self.state = state
        self.lowPowerModeEnabled = lowPowerModeEnabled
    }
}

public struct OrchidThermalStatusPayload: Codable, Sendable, Equatable {
    public var state: OrchidThermalState

    public init(state: OrchidThermalState) {
        self.state = state
    }
}

public struct OrchidStorageStatusPayload: Codable, Sendable, Equatable {
    public var totalBytes: Int64
    public var freeBytes: Int64
    public var usedBytes: Int64

    public init(totalBytes: Int64, freeBytes: Int64, usedBytes: Int64) {
        self.totalBytes = totalBytes
        self.freeBytes = freeBytes
        self.usedBytes = usedBytes
    }
}

public struct OrchidNetworkStatusPayload: Codable, Sendable, Equatable {
    public var status: OrchidNetworkPathStatus
    public var isExpensive: Bool
    public var isConstrained: Bool
    public var interfaces: [OrchidNetworkInterfaceType]

    public init(
        status: OrchidNetworkPathStatus,
        isExpensive: Bool,
        isConstrained: Bool,
        interfaces: [OrchidNetworkInterfaceType])
    {
        self.status = status
        self.isExpensive = isExpensive
        self.isConstrained = isConstrained
        self.interfaces = interfaces
    }
}

public struct OrchidDeviceStatusPayload: Codable, Sendable, Equatable {
    public var battery: OrchidBatteryStatusPayload
    public var thermal: OrchidThermalStatusPayload
    public var storage: OrchidStorageStatusPayload
    public var network: OrchidNetworkStatusPayload
    public var uptimeSeconds: Double

    public init(
        battery: OrchidBatteryStatusPayload,
        thermal: OrchidThermalStatusPayload,
        storage: OrchidStorageStatusPayload,
        network: OrchidNetworkStatusPayload,
        uptimeSeconds: Double)
    {
        self.battery = battery
        self.thermal = thermal
        self.storage = storage
        self.network = network
        self.uptimeSeconds = uptimeSeconds
    }
}

public struct OrchidDeviceInfoPayload: Codable, Sendable, Equatable {
    public var deviceName: String
    public var modelIdentifier: String
    public var systemName: String
    public var systemVersion: String
    public var appVersion: String
    public var appBuild: String
    public var locale: String

    public init(
        deviceName: String,
        modelIdentifier: String,
        systemName: String,
        systemVersion: String,
        appVersion: String,
        appBuild: String,
        locale: String)
    {
        self.deviceName = deviceName
        self.modelIdentifier = modelIdentifier
        self.systemName = systemName
        self.systemVersion = systemVersion
        self.appVersion = appVersion
        self.appBuild = appBuild
        self.locale = locale
    }
}
