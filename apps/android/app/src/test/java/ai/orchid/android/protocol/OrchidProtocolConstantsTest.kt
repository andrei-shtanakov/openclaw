package ai.orchid.android.protocol

import org.junit.Assert.assertEquals
import org.junit.Test

class OrchidProtocolConstantsTest {
  @Test
  fun canvasCommandsUseStableStrings() {
    assertEquals("canvas.present", OrchidCanvasCommand.Present.rawValue)
    assertEquals("canvas.hide", OrchidCanvasCommand.Hide.rawValue)
    assertEquals("canvas.navigate", OrchidCanvasCommand.Navigate.rawValue)
    assertEquals("canvas.eval", OrchidCanvasCommand.Eval.rawValue)
    assertEquals("canvas.snapshot", OrchidCanvasCommand.Snapshot.rawValue)
  }

  @Test
  fun a2uiCommandsUseStableStrings() {
    assertEquals("canvas.a2ui.push", OrchidCanvasA2UICommand.Push.rawValue)
    assertEquals("canvas.a2ui.pushJSONL", OrchidCanvasA2UICommand.PushJSONL.rawValue)
    assertEquals("canvas.a2ui.reset", OrchidCanvasA2UICommand.Reset.rawValue)
  }

  @Test
  fun capabilitiesUseStableStrings() {
    assertEquals("canvas", OrchidCapability.Canvas.rawValue)
    assertEquals("camera", OrchidCapability.Camera.rawValue)
    assertEquals("screen", OrchidCapability.Screen.rawValue)
    assertEquals("voiceWake", OrchidCapability.VoiceWake.rawValue)
  }

  @Test
  fun screenCommandsUseStableStrings() {
    assertEquals("screen.record", OrchidScreenCommand.Record.rawValue)
  }
}
