import SwiftUI

struct SearchReplaceView: View {
    @Binding var text: String
    @Binding var isPresented: Bool
    @State private var searchText = ""
    @State private var replaceText = ""
    @State private var showReplace = false
    @State private var matchCount = 0
    @State private var currentMatchIndex = 0
    @State private var matches: [SearchMatch] = []
    
    struct SearchMatch: Identifiable {
        let id = UUID()
        let range: Range<String.Index>
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Search", text: $searchText)
                    .textFieldStyle(.plain)
                    .onSubmit {
                        findNext()
                    }
                    .onChange(of: searchText) { _, _ in
                        updateMatches()
                    }
                
                if !searchText.isEmpty {
                    if matchCount > 0 {
                        Text("\(currentMatchIndex + 1)/\(matchCount)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text("No results")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
                
                Button(action: findPrevious) {
                    Image(systemName: "arrow.up")
                }
                .disabled(searchText.isEmpty || matchCount == 0)
                
                Button(action: findNext) {
                    Image(systemName: "arrow.down")
                }
                .disabled(searchText.isEmpty || matchCount == 0)
                
                Button(action: { withAnimation { showReplace.toggle() } }) {
                    Image(systemName: showReplace ? "chevron.up" : "chevron.down")
                }
                
                Button(action: { isPresented = false }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(.systemGray6))
            
            if showReplace {
                HStack {
                    Image(systemName: "arrow.2.squarepath")
                        .foregroundColor(.secondary)
                    
                    TextField("Replace", text: $replaceText)
                        .textFieldStyle(.plain)
                        .onSubmit {
                            replaceOne()
                        }
                    
                    Button("Replace") {
                        replaceOne()
                    }
                    .disabled(searchText.isEmpty || replaceText.isEmpty || matchCount == 0)
                    
                    Button("All") {
                        replaceAll()
                    }
                    .disabled(searchText.isEmpty || replaceText.isEmpty || matchCount == 0)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(.systemGray6))
            }
            
            if !searchText.isEmpty && matchCount > 0 {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(Array(matches.enumerated()), id: \.element.id) { index, match in
                            Button(action: {
                                currentMatchIndex = index
                                jumpToMatch(match)
                            }) {
                                Text(getPreviewText(for: match.range))
                                    .font(.system(.caption, design: .monospaced))
                                    .lineLimit(1)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(index == currentMatchIndex ? Color.blue.opacity(0.2) : Color.gray.opacity(0.1))
                                    .cornerRadius(4)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 4)
                                            .stroke(index == currentMatchIndex ? Color.blue : Color.clear, lineWidth: 1)
                                    )
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                }
                .frame(maxHeight: 40)
                .background(Color(.systemGray6))
            }
        }
    }
    
    private func updateMatches() {
        guard !searchText.isEmpty else {
            matches = []
            matchCount = 0
            currentMatchIndex = 0
            return
        }
        
        matches = []
        var searchStartIndex = text.startIndex
        
        while let range = text.range(of: searchText, range: searchStartIndex..<text.endIndex) {
            matches.append(SearchMatch(range: range))
            searchStartIndex = range.upperBound
        }
        
        matchCount = matches.count
        currentMatchIndex = matchCount > 0 ? 0 : -1
    }
    
    private func findNext() {
        guard !searchText.isEmpty && matchCount > 0 else { return }
        currentMatchIndex = (currentMatchIndex + 1) % matchCount
        jumpToMatch(matches[currentMatchIndex])
    }
    
    private func findPrevious() {
        guard !searchText.isEmpty && matchCount > 0 else { return }
        currentMatchIndex = (currentMatchIndex - 1 + matchCount) % matchCount
        jumpToMatch(matches[currentMatchIndex])
    }
    
    private func jumpToMatch(_ match: SearchMatch) {
        NotificationCenter.default.post(
            name: .searchMatchFound,
            object: nil,
            userInfo: ["range": match.range]
        )
    }
    
    private func replaceOne() {
        guard !searchText.isEmpty, !matches.isEmpty, currentMatchIndex >= 0, currentMatchIndex < matches.count else { return }
        
        let match = matches[currentMatchIndex]
        let replacementCharOffset = replaceText.count - searchText.count
        let originalOffset = text.distance(from: text.startIndex, to: match.range.lowerBound)
        let expectedOffset = originalOffset + replacementCharOffset
        text.replaceSubrange(match.range, with: replaceText)
        
        matches.removeAll()
        var searchStartIndex = text.startIndex
        var newMatchIndex = -1
        var idx = 0
        
        while let range = text.range(of: searchText, range: searchStartIndex..<text.endIndex) {
            let currentOffset = text.distance(from: text.startIndex, to: range.lowerBound)
            if currentOffset <= expectedOffset {
                newMatchIndex = idx
            }
            matches.append(SearchMatch(range: range))
            searchStartIndex = range.upperBound
            idx += 1
        }
        
        matchCount = matches.count
        currentMatchIndex = matchCount > 0 ? min(max(newMatchIndex + 1, 0), matchCount - 1) : 0
        
        if matchCount > 0 {
            jumpToMatch(matches[currentMatchIndex])
        }
    }
    
    private func replaceAll() {
        guard !searchText.isEmpty else { return }
        text = text.replacingOccurrences(of: searchText, with: replaceText)
        updateMatches()
    }
    
    private func getPreviewText(for range: Range<String.Index>) -> String {
        let charsBefore = text.distance(from: text.startIndex, to: range.lowerBound)
        let charsAfter = text.distance(from: range.upperBound, to: text.endIndex)
        let start = text.index(range.lowerBound, offsetBy: -min(10, charsBefore), limitedBy: text.startIndex) ?? text.startIndex
        let end = text.index(range.upperBound, offsetBy: min(10, charsAfter), limitedBy: text.endIndex) ?? text.endIndex
        
        let prefix = start > text.startIndex ? "..." : ""
        let suffix = end < text.endIndex ? "..." : ""
        
        return prefix + String(text[start..<end]) + suffix
    }
}

extension Notification.Name {
    static let searchMatchFound = Notification.Name("searchMatchFound")
    static let selectAllText = Notification.Name("selectAllText")
}
