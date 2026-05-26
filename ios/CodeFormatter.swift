import Foundation

struct CodeFormatter {
    static func format(_ code: String, for type: ProjectFile.FileType) -> String {
        switch type {
        case .html:
            return formatHTML(code)
        case .css:
            return formatCSS(code)
        case .javascript:
            return formatJS(code)
        default:
            return code
        }
    }
    
    static func formatHTML(_ html: String) -> String {
        var indentLevel = 0
        let indentString = "  "
        
        let lines = html.components(separatedBy: .newlines)
        
        var formattedLines: [String] = []
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty else { continue }
            
            if trimmed.hasPrefix("</") || trimmed.hasPrefix("-->") {
                indentLevel = max(0, indentLevel - 1)
            }
            
            let indentedLine = String(repeating: indentString, count: indentLevel) + trimmed
            formattedLines.append(indentedLine)
            
            if trimmed.hasPrefix("<") && !trimmed.hasPrefix("</") && !trimmed.hasPrefix("<!") && !trimmed.hasPrefix("</") {
                let isSelfClosing = trimmed.hasSuffix("/>") || 
                                   trimmed.contains("<img") || 
                                   trimmed.contains("<br") || 
                                   trimmed.contains("<hr") || 
                                   trimmed.contains("<input") ||
                                   trimmed.contains("<meta") ||
                                   trimmed.contains("<link")
                
                if !isSelfClosing && !trimmed.contains("</") {
                    indentLevel += 1
                }
            }
        }
        
        return formattedLines.joined(separator: "\n")
    }
    
    static func formatCSS(_ css: String) -> String {
        var result = ""
        var indentLevel = 0
        let indentString = "  "
        
        let lines = css.components(separatedBy: .newlines)
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty else { continue }
            
            if trimmed.contains("}") {
                indentLevel = max(0, indentLevel - 1)
            }
            
            let indentedLine = String(repeating: indentString, count: indentLevel) + trimmed
            result += indentedLine + "\n"
            
            if trimmed.contains("{") {
                indentLevel += 1
            }
        }
        
        return result.trimmingCharacters(in: .newlines)
    }
    
    static func formatJS(_ js: String) -> String {
        var result = ""
        var indentLevel = 0
        let indentString = "  "
        
        let lines = js.components(separatedBy: .newlines)
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty else { continue }
            
            if trimmed.hasPrefix("}") || trimmed.hasPrefix("]") || trimmed.hasPrefix(")") {
                indentLevel = max(0, indentLevel - 1)
            }
            
            let indentedLine = String(repeating: indentString, count: indentLevel) + trimmed
            result += indentedLine + "\n"
            
            if trimmed.hasSuffix("{") || trimmed.hasSuffix("[") || trimmed.hasSuffix("(") {
                indentLevel += 1
            }
        }
        
        return result.trimmingCharacters(in: .newlines)
    }
}
