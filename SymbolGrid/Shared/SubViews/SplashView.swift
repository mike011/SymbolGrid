//
//  SplashView.swift
//  SymbolGrid
//
//  Created by Dalton on 6/17/24.
//

import SwiftUI
import SFSymbolKit

struct SplashView: View {
    @State private var system = System()
    @State private var vmo = ViewModel()

    @Binding var fontSize: Double
    @Binding var selectedWeight: Weight
    @Binding var isAnimating: Bool
    
    var body: some View {
        let limitedIcons: [String] = Array(system.searchResults.prefix(200)).map { symbolName in
            symbolName
        }
        GeometryReader { geo in
            let minColumnWidth = 1.5 * fontSize
            let numberOfColumns = max(1, Int(geo.size.width / minColumnWidth))
            let columns = Array(
                repeating: GridItem(
                    .adaptive(minimum: minColumnWidth)
                ),
                count: numberOfColumns
            )
            ZStack {
                ProgressView()
                NavigationView {
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVGrid(columns: columns, spacing: vmo.spacing) {
                                ForEach(limitedIcons, id: \.self) { icon in
                                    Image(systemName: icon)
                                        .padding(8)
                                        .font(.system(size: fontSize, weight: selectedWeight.weight))
                                        .symbolEffect(.breathe.byLayer.pulse)
                                        .foregroundStyle(Color.random())
                                        .onAppear {
                                            isAnimating = true
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 3.4) {
                                                withAnimation(.easeInOut(duration: 2)) {
                                                    isAnimating = false
                                                }
                                            }
                                        }
                                        .animation(.default, value: isAnimating)
                                }
                            }
                        }
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                if limitedIcons.count > numberOfColumns {
                                    proxy.scrollTo(limitedIcons[numberOfColumns + 1], anchor: .top)
                                }
                            }
                        }
                    }
                }
            }

#if os(macOS)
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    if let selectedIcon = selected {
                        Text("\(selectedIcon.id)")
                            .padding()
                            .onTapGesture(count: 1) {
                                NSPasteboard.general.setString(selectedIcon.id, forType: .string)
                                print(selectedIcon.id)
                            }
                    }
                }
            }
#endif
        }
    }
}

#Preview {
    SplashView(
        fontSize: .constant(50.0),
        selectedWeight: .constant(.regular),
        isAnimating: .constant(true)
    )
}
