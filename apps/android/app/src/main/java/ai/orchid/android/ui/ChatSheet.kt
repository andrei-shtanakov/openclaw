package ai.orchid.android.ui

import androidx.compose.runtime.Composable
import ai.orchid.android.MainViewModel
import ai.orchid.android.ui.chat.ChatSheetContent

@Composable
fun ChatSheet(viewModel: MainViewModel) {
  ChatSheetContent(viewModel = viewModel)
}
