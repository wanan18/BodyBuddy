//
//  QuickLogView.swift
//  BodyBuddy
//
//  Created by William Anan on 10/22/25.
//

import SwiftUI

struct QuickLogView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Log")
                .font(.largeTitle.bold())
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .padding(.top, 24)

            Text("Quick logging will be updated after the new session/exercise structure is finished.")
                .font(.subheadline)
                .foregroundStyle(.gray)
                .padding(.horizontal, 16)

            Spacer()
        }
        .background(Color.black.ignoresSafeArea())
    }
}

#Preview {
    QuickLogView()
}
