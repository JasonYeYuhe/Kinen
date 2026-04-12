import WidgetKit
import SwiftUI

@main
struct KinenWidgetBundle: WidgetBundle {
    var body: some Widget {
        StreakWidget()
        MoodWidget()
        PromptWidget()
    }
}
