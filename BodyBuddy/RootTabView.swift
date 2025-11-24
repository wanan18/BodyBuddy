//
//  RootTabView.swift
//  BodyBuddy
//
//  Created by William Anan on 10/22/25.
//

import SwiftUI

// Which tab is currently selected
enum TabDestination {
    case home
    case train
    case add
    case progress
    case profile
}

struct RootTabView: View {
    @State private var currentTab: TabDestination = .home

    var body: some View {
        ZStack {
            // Always fill screen with black first
            Color.black
                .ignoresSafeArea()

            // Main content switches with tab
            Group {
                switch currentTab {
                case .home:
                    HomeView()
                case .train:
                    TrainView()
                case .add:
                    AddPlaceholderView()
                case .progress:
                    ProgressPlaceholderView()
                case .profile:
                    ProfilePlaceholderView()
                }
            }

            // Floating pill tab bar
            VStack {
                Spacer()
                FloatingTabBar(currentTab: $currentTab)
            }
            .padding(.bottom, 16) // lift off bottom edge
        }
    }
}

// MARK: - Floating Tab Bar

struct FloatingTabBar: View {
    @Binding var currentTab: TabDestination

    private let accentGreen = Color(red: 92/255, green: 255/255, blue: 156/255)
    private let cardGray = Color(red: 20/255, green: 20/255, blue: 20/255)

    var body: some View {
        HStack(spacing: 0) {
            tabButton(.home, label: "Home", systemImage: "house.fill")
            tabButton(.train, label: "Train", systemImage: "dumbbell")
            tabButton(.add, label: "Add", systemImage: "plus.circle")
            tabButton(.progress, label: "Progress", systemImage: "chart.line.uptrend.xyaxis")
            tabButton(.profile, label: "Profile", systemImage: "person.crop.circle")
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 18)
        .background(cardGray)
        .clipShape(Capsule())
        .padding(.horizontal, 24)
    }

    private func tabButton(_ tab: TabDestination, label: String, systemImage: String) -> some View {
        let isSelected = (tab == currentTab)
        let color = isSelected ? accentGreen : Color.white

        return Button {
            currentTab = tab
        } label: {
            VStack(spacing: 2) {
                Image(systemName: systemImage)
                    .font(.system(size: 18, weight: .semibold))
                Text(label)
                    .font(.caption2)
            }
            .foregroundColor(color)
            .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - Temporary placeholder views for other tabs

struct TrainPlaceholderView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Train")
                .font(.largeTitle.bold())
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .padding(.top, 24)

            Text("Train screen coming soon")
                .foregroundStyle(.gray)
                .padding(.horizontal, 16)

            Spacer()
        }
    }
}

struct AddPlaceholderView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Add")
                .font(.largeTitle.bold())
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .padding(.top, 24)

            Text("Radial menu coming soon")
                .foregroundStyle(.gray)
                .padding(.horizontal, 16)

            Spacer()
        }
    }
}

struct ProgressPlaceholderView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Progress")
                .font(.largeTitle.bold())
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .padding(.top, 24)

            Text("Charts and muscle map coming soon")
                .foregroundStyle(.gray)
                .padding(.horizontal, 16)

            Spacer()
        }
    }
}

struct ProfilePlaceholderView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Profile")
                .font(.largeTitle.bold())
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .padding(.top, 24)

            Text("Profile and exercise library coming soon")
                .foregroundStyle(.gray)
                .padding(.horizontal, 16)

            Spacer()
        }
    }
}

#Preview {
    RootTabView()
}
