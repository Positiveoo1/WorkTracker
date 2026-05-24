//
//  OfflineBanner.swift
//  WorkTracker
//
//  Created by Abubakrsiddik Abdurakhimov on 24/05/2026.
//

import SwiftUI

struct OfflineBanner: View {
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "wifi.slash")
            Text("Offline — showing cached data")
                .font(.footnote)
                .fontWeight(.medium)
        }
        .foregroundColor(.white)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color.orange)
        .transition(.move(edge: .top).combined(with: .opacity))
    }
}
