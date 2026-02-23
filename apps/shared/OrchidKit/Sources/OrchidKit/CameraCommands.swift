import Foundation

public enum OrchidCameraCommand: String, Codable, Sendable {
    case list = "camera.list"
    case snap = "camera.snap"
    case clip = "camera.clip"
}

public enum OrchidCameraFacing: String, Codable, Sendable {
    case back
    case front
}

public enum OrchidCameraImageFormat: String, Codable, Sendable {
    case jpg
    case jpeg
}

public enum OrchidCameraVideoFormat: String, Codable, Sendable {
    case mp4
}

public struct OrchidCameraSnapParams: Codable, Sendable, Equatable {
    public var facing: OrchidCameraFacing?
    public var maxWidth: Int?
    public var quality: Double?
    public var format: OrchidCameraImageFormat?
    public var deviceId: String?
    public var delayMs: Int?

    public init(
        facing: OrchidCameraFacing? = nil,
        maxWidth: Int? = nil,
        quality: Double? = nil,
        format: OrchidCameraImageFormat? = nil,
        deviceId: String? = nil,
        delayMs: Int? = nil)
    {
        self.facing = facing
        self.maxWidth = maxWidth
        self.quality = quality
        self.format = format
        self.deviceId = deviceId
        self.delayMs = delayMs
    }
}

public struct OrchidCameraClipParams: Codable, Sendable, Equatable {
    public var facing: OrchidCameraFacing?
    public var durationMs: Int?
    public var includeAudio: Bool?
    public var format: OrchidCameraVideoFormat?
    public var deviceId: String?

    public init(
        facing: OrchidCameraFacing? = nil,
        durationMs: Int? = nil,
        includeAudio: Bool? = nil,
        format: OrchidCameraVideoFormat? = nil,
        deviceId: String? = nil)
    {
        self.facing = facing
        self.durationMs = durationMs
        self.includeAudio = includeAudio
        self.format = format
        self.deviceId = deviceId
    }
}
