import SwiftUI

struct HomePageView: View {
    @Binding var path: NavigationPath

    var body: some View {
        ZStack {
            AppTheme.sky.ignoresSafeArea()
            VStack(spacing: 28) {
                HStack {
                    Spacer()
                    SnapZiCircleButton(systemName: "medal.fill", size: 56) {
                        path.append(SnapZiRoute.photoLibrary)
                    }
                }
                .padding(.horizontal, 32)
                .padding(.top, 16)

                Spacer()

                SnapZiWideButton(title: "学新字", systemName: "plus") {
                    path.append(SnapZiRoute.keywordPick)
                }

                SnapZiWideButton(title: "复习", systemName: "arrow.counterclockwise", color: AppTheme.brown, disabled: true) {}

                Spacer()
            }
        }
        .navigationBarHidden(true)
    }
}
