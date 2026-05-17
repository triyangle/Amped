//
//  PinIcon.swift
//  Amped
//
//  Created by Kevin Choo & Vlad Munteanu on 8/15/23.
//

import Foundation
import SwiftUI

struct PinIcon: View {
    var stationType: StationAnnotation.StationType
    var numEbikesAvailable: Int
    
    private var pinColor: Color {
        switch stationType {
        case .empty:
            return .red
        case .ebikeOnly:
            return .blue
        case .oneClassicRemaining:
            return .orange
        }
    }
    
    private var labelText: String {
        numEbikesAvailable == 0 ? "0" : String(numEbikesAvailable)
    }

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Image(systemName: "circle.fill")
                    .font(.title)
                    .foregroundColor(pinColor)
                Text(labelText)
                    .foregroundColor(.white)
            }
            Image(systemName: "arrowtriangle.down.fill")
                .font(.caption)
                .foregroundColor(pinColor)
                .offset(x: 0, y: -5)
        }
    }
}
