import Foundation

// Stable identifier used for both the macOS LaunchAgent label and Nix-managed defaults suite.
// nix-orchid writes app defaults into this suite to survive app bundle identifier churn.
let launchdLabel = "ai.orchid.mac"
let gatewayLaunchdLabel = "ai.orchid.gateway"
let onboardingVersionKey = "orchid.onboardingVersion"
let onboardingSeenKey = "orchid.onboardingSeen"
let currentOnboardingVersion = 7
let pauseDefaultsKey = "orchid.pauseEnabled"
let iconAnimationsEnabledKey = "orchid.iconAnimationsEnabled"
let swabbleEnabledKey = "orchid.swabbleEnabled"
let swabbleTriggersKey = "orchid.swabbleTriggers"
let voiceWakeTriggerChimeKey = "orchid.voiceWakeTriggerChime"
let voiceWakeSendChimeKey = "orchid.voiceWakeSendChime"
let showDockIconKey = "orchid.showDockIcon"
let defaultVoiceWakeTriggers = ["orchid"]
let voiceWakeMaxWords = 32
let voiceWakeMaxWordLength = 64
let voiceWakeMicKey = "orchid.voiceWakeMicID"
let voiceWakeMicNameKey = "orchid.voiceWakeMicName"
let voiceWakeLocaleKey = "orchid.voiceWakeLocaleID"
let voiceWakeAdditionalLocalesKey = "orchid.voiceWakeAdditionalLocaleIDs"
let voicePushToTalkEnabledKey = "orchid.voicePushToTalkEnabled"
let talkEnabledKey = "orchid.talkEnabled"
let iconOverrideKey = "orchid.iconOverride"
let connectionModeKey = "orchid.connectionMode"
let remoteTargetKey = "orchid.remoteTarget"
let remoteIdentityKey = "orchid.remoteIdentity"
let remoteProjectRootKey = "orchid.remoteProjectRoot"
let remoteCliPathKey = "orchid.remoteCliPath"
let canvasEnabledKey = "orchid.canvasEnabled"
let cameraEnabledKey = "orchid.cameraEnabled"
let systemRunPolicyKey = "orchid.systemRunPolicy"
let systemRunAllowlistKey = "orchid.systemRunAllowlist"
let systemRunEnabledKey = "orchid.systemRunEnabled"
let locationModeKey = "orchid.locationMode"
let locationPreciseKey = "orchid.locationPreciseEnabled"
let peekabooBridgeEnabledKey = "orchid.peekabooBridgeEnabled"
let deepLinkKeyKey = "orchid.deepLinkKey"
let modelCatalogPathKey = "orchid.modelCatalogPath"
let modelCatalogReloadKey = "orchid.modelCatalogReload"
let cliInstallPromptedVersionKey = "orchid.cliInstallPromptedVersion"
let heartbeatsEnabledKey = "orchid.heartbeatsEnabled"
let debugPaneEnabledKey = "orchid.debugPaneEnabled"
let debugFileLogEnabledKey = "orchid.debug.fileLogEnabled"
let appLogLevelKey = "orchid.debug.appLogLevel"
let voiceWakeSupported: Bool = ProcessInfo.processInfo.operatingSystemVersion.majorVersion >= 26
