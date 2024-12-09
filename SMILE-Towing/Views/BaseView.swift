import SwiftUI

struct BaseView<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: geometry.size.height * 0.02) {
                    content
                }
                .padding()
                .frame(minHeight: geometry.size.height)
            }
            .background(Color(.systemBackground))
            .edgesIgnoringSafeArea(.all)
            .onAppear {
                if #available(iOS 16.0, *) {
                    // Apply scrollDismissesKeyboard if supported
                    UIScrollView.appearance().keyboardDismissMode = .interactive
                } else {
                    // Fallback for older versions (keyboard will dismiss by tapping outside)
                    hideKeyboardOnTap()
                }
            }
        }
    }
    
    // MARK: - Helper for iOS <16.0
    func hideKeyboardOnTap() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
        guard let window = windowScene.windows.first else { return }
        
        let tapGesture = UITapGestureRecognizer(target: UIApplication.shared, action: #selector(UIApplication.resignFirstResponder))
        window.addGestureRecognizer(tapGesture)
    }
}
