import Foundation

public enum OrchidChatTransportEvent: Sendable {
    case health(ok: Bool)
    case tick
    case chat(OrchidChatEventPayload)
    case agent(OrchidAgentEventPayload)
    case seqGap
}

public protocol OrchidChatTransport: Sendable {
    func requestHistory(sessionKey: String) async throws -> OrchidChatHistoryPayload
    func sendMessage(
        sessionKey: String,
        message: String,
        thinking: String,
        idempotencyKey: String,
        attachments: [OrchidChatAttachmentPayload]) async throws -> OrchidChatSendResponse

    func abortRun(sessionKey: String, runId: String) async throws
    func listSessions(limit: Int?) async throws -> OrchidChatSessionsListResponse

    func requestHealth(timeoutMs: Int) async throws -> Bool
    func events() -> AsyncStream<OrchidChatTransportEvent>

    func setActiveSessionKey(_ sessionKey: String) async throws
}

extension OrchidChatTransport {
    public func setActiveSessionKey(_: String) async throws {}

    public func abortRun(sessionKey _: String, runId _: String) async throws {
        throw NSError(
            domain: "OrchidChatTransport",
            code: 0,
            userInfo: [NSLocalizedDescriptionKey: "chat.abort not supported by this transport"])
    }

    public func listSessions(limit _: Int?) async throws -> OrchidChatSessionsListResponse {
        throw NSError(
            domain: "OrchidChatTransport",
            code: 0,
            userInfo: [NSLocalizedDescriptionKey: "sessions.list not supported by this transport"])
    }
}
