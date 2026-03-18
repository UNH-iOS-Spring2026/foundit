import SwiftUI

struct MessageScreen: View {
    var body: some View {
        NavigationStack {
            VStack {
                Spacer()
                Text("Message Screen - UI Coming Soon")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationTitle("Messages")
        }
    }
}

#Preview {
    MessageScreen()
}
