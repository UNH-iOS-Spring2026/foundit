//
//  OnboardingView.swift
//  foundit
//
//  Source of inspiration for UI: ChatGPT (OpenAI)
//  Updated by Ashish Khadka on 16/03/2026.
//

import SwiftUI

struct OnboardingPage: Identifiable {
	let id = UUID()
	let imageName: String
	let title: String
	let description: String
}

struct OnboardingView: View {
	@State private var currentPage = 0
	@State private var goToLogin = false

	private let pages: [OnboardingPage] = [
		OnboardingPage(
			imageName: "onboarding1",
			title: "Lost or Found Something?",
			description: "Post missing or discovered items to reunite and help return them to their right owner."
		),
		OnboardingPage(
			imageName: "onboarding2",
			title: "Smart Matches, Real-Time Alerts",
			description: "Scan item details, discover similar listings, and get notified instantly when there is a possible match."
		),
		OnboardingPage(
			imageName: "onboarding3",
			title: "Securely Connect & Reclaim",
			description: "Chat, verify ownership, and coordinate safe returns with real-time messaging and identity checks."
		)
	]

	var body: some View {
		ZStack {
			Color(FounditColors.primary)
				.ignoresSafeArea()

			VStack {
				Spacer()

				ZStack {
					RoundedRectangle(cornerRadius: 24)
						.fill(Color(FounditColors.primary))
						.frame(width: 320, height: 620)

					VStack(alignment: .leading, spacing: 0) {
						topSection

						Spacer().frame(height: 20)

						imageSection

						Spacer().frame(height: 28)

						textSection

						Spacer()

						nextButton
					}
					.padding(.horizontal, 24)
					.padding(.top, 18)
					.padding(.bottom, 24)
					.frame(width: 320, height: 620)
				}

				Spacer()
			}

			NavigationLink(
				destination: LoginView(),
				isActive: $goToLogin
			) {
				EmptyView()
			}
			.hidden()
		}
		.navigationBarBackButtonHidden(true)
	}

	private var topSection: some View {
		HStack {
			Button {
				if currentPage > 0 {
					currentPage -= 1
				}
			} label: {
				Image(systemName: "chevron.left")
					.font(.system(size: 14, weight: .medium))
					.foregroundColor(.black.opacity(currentPage == 0 ? 0.3 : 0.8))
			}
			.disabled(currentPage == 0)

			Spacer()

			HStack(spacing: 6) {
				ForEach(0..<pages.count, id: \.self) { index in
					Capsule()
						.fill(index == currentPage ? Color.black : Color.white.opacity(0.7))
						.frame(width: 20, height: 4)
				}
			}

			Spacer()

			Image(systemName: "chevron.left")
				.font(.system(size: 14, weight: .medium))
				.opacity(0)
		}
	}

	private var imageSection: some View {
		HStack {
			Spacer()

			Image(pages[currentPage].imageName)
				.resizable()
				.scaledToFit()
				.frame(width: 180, height: 180)

			Spacer()
		}
	}

	private var textSection: some View {
		VStack(alignment: .leading, spacing: 10) {
			Text(pages[currentPage].title)
				.font(.system(size: 20, weight: .bold))
				.foregroundColor(.black)

			Text(pages[currentPage].description)
				.font(.system(size: 13))
				.foregroundColor(.black.opacity(0.75))
				.fixedSize(horizontal: false, vertical: true)
		}
	}

	private var nextButton: some View {
		Button {
			if currentPage < pages.count - 1 {
				currentPage += 1
			} else {
				goToLogin = true
			}
		} label: {
			Text(currentPage == pages.count - 1 ? "GET STARTED" : "NEXT")
				.font(.system(size: 14, weight: .bold))
				.foregroundColor(.black)
				.frame(maxWidth: .infinity)
				.frame(height: 46)
				.background(Color.white)
				.clipShape(RoundedRectangle(cornerRadius: 10))
		}
	}
}

#Preview {
	NavigationStack {
		OnboardingView()
	}
}
