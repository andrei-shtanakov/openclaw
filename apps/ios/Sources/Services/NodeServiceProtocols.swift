import CoreLocation
import Foundation
import OrchidKit
import UIKit

protocol CameraServicing: Sendable {
    func listDevices() async -> [CameraController.CameraDeviceInfo]
    func snap(params: OrchidCameraSnapParams) async throws -> (format: String, base64: String, width: Int, height: Int)
    func clip(params: OrchidCameraClipParams) async throws -> (format: String, base64: String, durationMs: Int, hasAudio: Bool)
}

protocol ScreenRecordingServicing: Sendable {
    func record(
        screenIndex: Int?,
        durationMs: Int?,
        fps: Double?,
        includeAudio: Bool?,
        outPath: String?) async throws -> String
}

@MainActor
protocol LocationServicing: Sendable {
    func authorizationStatus() -> CLAuthorizationStatus
    func accuracyAuthorization() -> CLAccuracyAuthorization
    func ensureAuthorization(mode: OrchidLocationMode) async -> CLAuthorizationStatus
    func currentLocation(
        params: OrchidLocationGetParams,
        desiredAccuracy: OrchidLocationAccuracy,
        maxAgeMs: Int?,
        timeoutMs: Int?) async throws -> CLLocation
    func startLocationUpdates(
        desiredAccuracy: OrchidLocationAccuracy,
        significantChangesOnly: Bool) -> AsyncStream<CLLocation>
    func stopLocationUpdates()
    func startMonitoringSignificantLocationChanges(onUpdate: @escaping @Sendable (CLLocation) -> Void)
    func stopMonitoringSignificantLocationChanges()
}

protocol DeviceStatusServicing: Sendable {
    func status() async throws -> OrchidDeviceStatusPayload
    func info() -> OrchidDeviceInfoPayload
}

protocol PhotosServicing: Sendable {
    func latest(params: OrchidPhotosLatestParams) async throws -> OrchidPhotosLatestPayload
}

protocol ContactsServicing: Sendable {
    func search(params: OrchidContactsSearchParams) async throws -> OrchidContactsSearchPayload
    func add(params: OrchidContactsAddParams) async throws -> OrchidContactsAddPayload
}

protocol CalendarServicing: Sendable {
    func events(params: OrchidCalendarEventsParams) async throws -> OrchidCalendarEventsPayload
    func add(params: OrchidCalendarAddParams) async throws -> OrchidCalendarAddPayload
}

protocol RemindersServicing: Sendable {
    func list(params: OrchidRemindersListParams) async throws -> OrchidRemindersListPayload
    func add(params: OrchidRemindersAddParams) async throws -> OrchidRemindersAddPayload
}

protocol MotionServicing: Sendable {
    func activities(params: OrchidMotionActivityParams) async throws -> OrchidMotionActivityPayload
    func pedometer(params: OrchidPedometerParams) async throws -> OrchidPedometerPayload
}

struct WatchMessagingStatus: Sendable, Equatable {
    var supported: Bool
    var paired: Bool
    var appInstalled: Bool
    var reachable: Bool
    var activationState: String
}

struct WatchQuickReplyEvent: Sendable, Equatable {
    var replyId: String
    var promptId: String
    var actionId: String
    var actionLabel: String?
    var sessionKey: String?
    var note: String?
    var sentAtMs: Int?
    var transport: String
}

struct WatchNotificationSendResult: Sendable, Equatable {
    var deliveredImmediately: Bool
    var queuedForDelivery: Bool
    var transport: String
}

protocol WatchMessagingServicing: AnyObject, Sendable {
    func status() async -> WatchMessagingStatus
    func setReplyHandler(_ handler: (@Sendable (WatchQuickReplyEvent) -> Void)?)
    func sendNotification(
        id: String,
        params: OrchidWatchNotifyParams) async throws -> WatchNotificationSendResult
}

extension CameraController: CameraServicing {}
extension ScreenRecordService: ScreenRecordingServicing {}
extension LocationService: LocationServicing {}
