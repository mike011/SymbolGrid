//
//  SheetView.swift
//  SymbolGrid
//
//  Created by Dalton on 6/15/24.
//

import SwiftUI
import Design
import SFSymbolKit
import SwiftData

struct SymbolView: View {
#if os(macOS)
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
#endif
    @Environment(\.verticalSizeClass) var verticalSizeClass
    @Query var favorites: [Favorite]
    var icons: [Symbol]
    @Binding var fontSize: Double
    @Binding var selectedWeight: Weight
    @Binding var selectedMode: SymbolRenderingModes
    @Binding var showingSymbolMenu: Bool
    @Binding var showingDetail: Bool
    let handleSearch: () -> Void
    @Binding var showingSearch: Bool
    @Binding var searchText: String
    @Binding var searchScope: SearchScope
    @Binding var searchTokens: [SearchToken]
    @Binding var showingFavorites: Bool
    var favoriteSuggestions: [Symbol]

    @State var isHovered = false
    @State private var vmo = ViewModel()

    var body: some View {
//        let iconArray: [Symbol] = icons
//        @State var isKeyboardVisible = false
//        let suggestions: [Symbol] = favoriteSuggestions
            GeometryReader { geo in
                let minColumnWidth = 1.5 * fontSize
                let numberOfColumns = max(1, Int(geo.size.width / minColumnWidth))
                let columns = Array(
                    repeating: GridItem(
                        .adaptive(minimum: minColumnWidth)
                    ),
                    count: numberOfColumns
                )
                NavigationView {
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVGrid(columns: columns, spacing: fontSize * 0.1) {
                                ForEach(icons, id: \.self) { icon in
                                    Button {
                                        if !showingSearch {
                                            if vmo.selected == icon {
                                                vmo.showSheet()
                                            } else {
                                                vmo.selected = icon
#if os(iOS)
                                                vmo.showingSheet = true
#else
                                                appDelegate.showMenuPanel(
                                                    icon: icon,
                                                    detailIcon: $detailIcon,
                                                    selectedWeight: $fontWeight,
                                                    selectedMode: $renderMode,
                                                    showInspector: $showInspector
                                                )
#endif
                                            }
                                        } else if vmo.selected != icon {
                                            vmo.selected = icon
                                        }
                                    } label: {
                                        Image(systemName: icon.name)
                                            .symbolRenderingMode(selectedMode.mode)
                                            .font(.system(size: fontSize, weight: selectedWeight.weight))
                                            .animation(.linear, value: 0.5)
                                            .opacity(isHovered ? 0.5 : 1.0)
#if os(iOS)
                                            .hoverEffect(.highlight)
#endif
                                            .onHover { hovering in
                                                isHovered = hovering
                                            }
                                            .previewLayout(.sizeThatFits)
                                            .padding(8)
                                            .contentShape(.dragPreview, RoundedRectangle(cornerRadius: 7))
                                            .foregroundStyle(
                                                (vmo.selected == icon) ? Color.random() : .primary
                                            )
                                            .draggable(Image(systemName: icon.name)) {
                                                Text("\(icon)")
                                            }
                                            .scrollTransition(.interactive) { content, phase in
                                                content
                                                    .scaleEffect(phase.isIdentity ? 1 : 0.25, anchor: .center)
                                                    .opacity(phase.isIdentity ? 1 : 0.05)
                                            }
                                            .edgesIgnoringSafeArea(.all)
                                    }
                                    .buttonStyle(BorderlessButtonStyle())
                                }
                            }
                            .searchable(
                                text: $searchText,
                                tokens: $searchTokens,
                                isPresented: $showingSearch,
                                prompt: Text("Search \(icons.count) Symbols"),
                                token: { token in
                                    Text(token.text)
                                })
                            .onSubmit(of: .search, {
                                handleSearch()
                                searchScope = .all
                            })
                            .searchScopes($searchScope, activation: .onSearchPresentation) {
                                if !favorites.isEmpty {
                                    Text("Symbols").tag(SearchScope.all)
                                    Text("Favorites").tag(SearchScope.favorites)
                                }
                            }
                            .onChange(of: showingSearch) { isPresented, _ in
                                if !isPresented {
                                    searchScope = .all
                                }
                            }
                        }
                        .scrollTargetLayout()
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now()) {
                                if icons.count > numberOfColumns {
                                    withAnimation(.easeIn(duration: 1.0)) {
                                        proxy.scrollTo(icons[numberOfColumns + 1], anchor: .zero)
                                    }
                                }
                            }
                        }
                    }
                    .toolbar {
                        ToolbarItem(placement: .keyboard) {
                            if let selectedIconName = vmo.selected?.name {
                                Text(selectedIconName)
                            } else {
                                Text("No Icon Selected")
                            }
                            Text("No Icon Selected")
                        }
                    }
                }
                .refreshable {
                    showingSymbolMenu.toggle()
                }
#if os(iOS)
                .sheet(isPresented: $vmo.showingSheet) {
                    if let selectedIcon = vmo.selected, !showingSearch {
                        SymbolSheet(
                            icon: selectedIcon,
                            detailIcon: $vmo.detailIcon,
                            fontSize: $fontSize,
                            searchText: $searchText,
                            selectedWeight: $selectedWeight,
                            selectedMode: $selectedMode,
                            showingDetail: $showingDetail,
                            showingSearch: $showingSearch
                        )
                        .presentationBackgroundInteraction(.enabled)
                        .presentationDetents(
                            /*isKeyboardVisible ? [.medium] :*/ [.height(geo.size.height / 4), .medium]
                        )
                        .sheet(isPresented: $vmo.showingDetail) {
                            DetailView(
                                icon: selectedIcon,
                                fontSize: $fontSize,
                                showingDetail: $vmo.showingDetail
                            )
                            .presentationDetents([.large])
                        }
                    }
                }
#endif
                .inspector(isPresented: $showingFavorites) {
                    FavoritesView(
                        fontSize: $fontSize,
                        showingDetail: $showingDetail,
                        showingSearch: $showingSearch,
                        searchText: $searchText
                    )
                    //                    .dropDestination(for: String.self) { items, _ in
                    //                        if let item = items.first {
                    //                            draggedText = item
                    //                            print("\(draggedText) added to favorites")
                    //                            addFavorite(glyph: <#T##Icon#>: draggedText)
                    //                            return true
                    //                        }
                    //                        return false
                    //                    }
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

#Preview {
    SymbolView(
        icons: [],
        fontSize: .constant(50.0),
        selectedWeight: .constant(.regular),
        selectedMode: .constant(.monochrome),
        showingSymbolMenu: .constant(false),
        showingDetail: .constant(false),
        handleSearch: {},
        showingSearch: .constant(false),
        searchText: .constant(""),
        searchScope: .constant(.all),
        searchTokens: .constant([]),
        showingFavorites: .constant(false),
        favoriteSuggestions: []
    )
}
