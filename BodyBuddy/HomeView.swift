//
//  HomeView.swift
//  BodyBuddy
//
//  Created by William Anan on 3/23/26.
//

import SwiftUI

struct HomeView: View {
    @State private var selectedTab: AppTab = .dashboard

    var body: some View {
        ZStack(alignment: .bottom) {
            selectedContent

            FloatingNavigationBar(selectedTab: $selectedTab)
                .padding(.horizontal)
                .padding(.bottom, 12)
        }
        .background(Color(.systemGroupedBackground))
    }

    @ViewBuilder
    private var selectedContent: some View {
        switch selectedTab {
        case .dashboard:
            DashboardView()
        case .exerciseLog:
            ExerciseLogView()
        case .statistics:
            StatisticsView()
        case .account:
            AccountView()
        }
    }
}

private enum AppTab: String, CaseIterable, Identifiable {
    case dashboard
    case exerciseLog
    case statistics
    case account

    var id: String {
        rawValue
    }

    var title: String {
        switch self {
        case .dashboard:
            "Home"
        case .exerciseLog:
            "Log"
        case .statistics:
            "Stats"
        case .account:
            "Account"
        }
    }

    var systemImage: String {
        switch self {
        case .dashboard:
            "house.fill"
        case .exerciseLog:
            "dumbbell.fill"
        case .statistics:
            "chart.xyaxis.line"
        case .account:
            "person.crop.circle.fill"
        }
    }
}

private struct FloatingNavigationBar: View {
    @Binding var selectedTab: AppTab

    var body: some View {
        HStack(spacing: 4) {
            ForEach(AppTab.allCases) { tab in
                Button {
                    withAnimation(.snappy(duration: 0.2)) {
                        selectedTab = tab
                    }
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: tab.systemImage)
                            .font(.system(size: 18, weight: .semibold))
                            .frame(height: 22)

                        Text(tab.title)
                            .font(.caption2)
                            .fontWeight(.semibold)
                    }
                    .foregroundStyle(selectedTab == tab ? Color.primary : Color.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background {
                        if selectedTab == tab {
                            Capsule()
                                .fill(Color(.systemBackground))
                                .shadow(color: .black.opacity(0.12), radius: 4, x: 0, y: 2)
                        }
                    }
                    .contentShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(.regularMaterial)
        .clipShape(Capsule())
        .overlay {
            Capsule()
                .stroke(Color(.separator).opacity(0.28), lineWidth: 0.5)
        }
        .shadow(color: .black.opacity(0.14), radius: 14, x: 0, y: 7)
    }
}


private struct StatisticsView: View {
    private let metrics = [
        ("Workouts", "12"),
        ("Steps Avg", "8.1k"),
        ("Active Time", "5h 22m"),
        ("Calories", "3,420")
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("This Week")
                        .font(.title2)
                        .fontWeight(.semibold)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(metrics, id: \.0) { metric in
                            VStack(alignment: .leading, spacing: 8) {
                                Text(metric.0)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)

                                Text(metric.1)
                                    .font(.title2)
                                    .fontWeight(.bold)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(Color(.secondarySystemGroupedBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Trends")
                            .font(.headline)

                        Text("Step, workout, weight, and consistency charts will live here.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .padding()
                .padding(.bottom, 108)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Statistics")
        }
    }
}

private struct AccountView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Profile")
                            .font(.title2)
                            .fontWeight(.semibold)

                        Text("Manage goals, connected services, and account settings.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    VStack(spacing: 12) {
                        AccountRow(title: "Health Access", systemImage: "heart.fill")
                        AccountRow(title: "Goals", systemImage: "target")
                        AccountRow(title: "Notifications", systemImage: "bell.fill")
                    }

                    Button(role: .destructive) {
                        Task {
                            await appState.signOut()
                        }
                    } label: {
                        Text("Sign Out")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
                .padding(.bottom, 108)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Account")
        }
    }
}

private struct AccountRow: View {
    let title: String
    let systemImage: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: systemImage)
                .frame(width: 34, height: 34)
                .background(Color.accentColor.opacity(0.14))
                .foregroundStyle(Color.accentColor)
                .clipShape(RoundedRectangle(cornerRadius: 8))

            Text(title)
                .fontWeight(.medium)

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
