import UIKit

@MainActor
class AutoCompleteManager {
    static let shared = AutoCompleteManager()
    
    private let htmlTags = [
        "!DOCTYPE", "html", "head", "body", "title", "meta", "link", "script", "style",
        "div", "span", "p", "a", "img", "br", "hr", "table", "tr", "td", "th",
        "thead", "tbody", "tfoot", "ul", "ol", "li", "dl", "dt", "dd",
        "h1", "h2", "h3", "h4", "h5", "h6",
        "form", "input", "button", "textarea", "select", "option", "label",
        "header", "footer", "nav", "section", "article", "aside", "main",
        "canvas", "svg", "video", "audio", "source", "iframe", "embed",
        "strong", "em", "b", "i", "u", "s", "del", "ins", "sub", "sup",
        "code", "pre", "blockquote", "q", "cite", "abbr", "address",
        "fieldset", "legend", "datalist", "output", "progress", "meter",
        "details", "summary", "dialog", "template"
    ]
    
    private let htmlAttributes = [
        "class", "id", "style", "src", "href", "alt", "title", "name", "value",
        "type", "placeholder", "required", "disabled", "readonly", "checked",
        "selected", "multiple", "size", "maxlength", "min", "max", "step",
        "pattern", "action", "method", "enctype", "target", "rel", "media",
        "charset", "content", "http-equiv", "lang", "dir", "role", "aria-label",
        "aria-hidden", "aria-expanded", "aria-checked", "aria-selected",
        "data-", "onclick", "ondblclick", "onmousedown", "onmouseup", "onmouseover",
        "onmousemove", "onmouseout", "onkeydown", "onkeypress", "onkeyup",
        "onfocus", "onblur", "onchange", "onsubmit", "onreset", "onselect",
        "onload", "onunload", "onerror", "width", "height", "colspan", "rowspan"
    ]
    
    private let cssProperties = [
        "color", "background", "background-color", "background-image", "background-size",
        "border", "border-radius", "border-color", "border-width", "border-style",
        "margin", "margin-top", "margin-right", "margin-bottom", "margin-left",
        "padding", "padding-top", "padding-right", "padding-bottom", "padding-left",
        "width", "height", "min-width", "min-height", "max-width", "max-height",
        "display", "position", "top", "right", "bottom", "left",
        "float", "clear", "overflow", "overflow-x", "overflow-y",
        "font", "font-size", "font-family", "font-weight", "font-style", "line-height",
        "text-align", "text-decoration", "text-transform", "text-indent",
        "white-space", "word-wrap", "word-break", "letter-spacing", "word-spacing",
        "opacity", "visibility", "z-index", "cursor", "pointer-events",
        "transform", "transition", "animation", "box-shadow", "text-shadow",
        "flex", "flex-direction", "flex-wrap", "justify-content", "align-items",
        "align-content", "align-self", "order", "flex-grow", "flex-shrink", "flex-basis",
        "grid", "grid-template", "grid-template-columns", "grid-template-rows",
        "grid-gap", "grid-column", "grid-row", "gap", "column-gap", "row-gap",
        "list-style", "list-style-type", "list-style-position", "list-style-image",
        "outline", "outline-color", "outline-style", "outline-width", "outline-offset",
        "box-sizing", "content", "quotes", "counter-reset", "counter-increment",
        "vertical-align", "table-layout", "border-collapse", "border-spacing",
        "empty-cells", "caption-side", "resize", "user-select", "clip"
    ]
    
    private let cssValues = [
        "absolute", "relative", "fixed", "static", "sticky",
        "block", "inline", "inline-block", "flex", "grid", "none", "table", "table-cell",
        "left", "right", "center", "justify",
        "solid", "dashed", "dotted", "double", "groove", "ridge", "inset", "outset",
        "hidden", "visible", "scroll", "auto",
        "normal", "bold", "bolder", "lighter",
        "italic", "oblique",
        "nowrap", "pre", "pre-wrap", "pre-line",
        "uppercase", "lowercase", "capitalize",
        "none", "underline", "overline", "line-through",
        "pointer", "default", "not-allowed", "grab", "grabbing",
        "row", "row-reverse", "column", "column-reverse",
        "wrap", "nowrap", "wrap-reverse",
        "flex-start", "flex-end", "space-between", "space-around", "space-evenly",
        "stretch", "baseline", "center", "start", "end",
        "all", "ease", "ease-in", "ease-out", "ease-in-out", "linear",
        "infinite", "alternate", "forwards", "backwards", "both",
        "border-box", "content-box",
        "contain", "cover", "auto", "none", "scale-down"
    ]
    
    private let jsKeywords = [
        "function", "var", "let", "const", "if", "else", "for", "while", "do",
        "switch", "case", "break", "continue", "return", "try", "catch", "finally",
        "throw", "new", "this", "typeof", "instanceof", "in", "of", "void", "delete",
        "class", "extends", "super", "import", "export", "default", "from", "as",
        "async", "await", "yield", "static", "get", "set", "constructor",
        "true", "false", "null", "undefined", "NaN", "Infinity",
        "console", "document", "window", "navigator", "location", "history",
        "localStorage", "sessionStorage", "fetch", "Promise", "Set", "Map",
        "Array", "Object", "String", "Number", "Boolean", "Date", "Math", "JSON",
        "parseInt", "parseFloat", "isNaN", "isFinite", "encodeURI", "decodeURI",
        "setTimeout", "setInterval", "clearTimeout", "clearInterval",
        "addEventListener", "removeEventListener", "querySelector", "querySelectorAll",
        "getElementById", "getElementsByClassName", "getElementsByTagName",
        "createElement", "appendChild", "removeChild", "insertBefore", "cloneNode",
        "alert", "confirm", "prompt", "open", "close", "print"
    ]
    
    func getSuggestions(for text: String, at cursorPosition: Int, fileType: ProjectFile.FileType) -> [String] {
        let beforeCursor = String(text.prefix(cursorPosition))
        let lastWord = extractLastWord(beforeCursor)
        
        guard lastWord.count >= 1 else { return [] }
        
        var candidates: [String] = []
        
        switch fileType {
        case .html:
            if beforeCursor.hasSuffix("<") || lastWord.hasPrefix("<") {
                candidates = htmlTags
            } else if beforeCursor.contains("=") || lastWord.hasPrefix("\"") {
                return []
            } else {
                candidates = htmlTags + htmlAttributes
            }
        case .css:
            if beforeCursor.contains(":") {
                candidates = cssValues
            } else {
                candidates = cssProperties
            }
        case .javascript:
            candidates = jsKeywords
        default:
            return []
        }
        
        let filtered = candidates.filter { $0.lowercased().hasPrefix(lastWord.lowercased()) }
        return Array(filtered.prefix(8))
    }
    
    private func extractLastWord(_ text: String) -> String {
        let separators = CharacterSet.whitespacesAndNewlines.union(.init(charactersIn: "<>\"'=;:{},()[]"))
        let components = text.components(separatedBy: separators)
        return components.last ?? ""
    }
    
    func getSnippet(for tag: String, fileType: ProjectFile.FileType) -> String? {
        guard fileType == .html else { return nil }
        
        let snippets: [String: String] = [
            "html": "<!DOCTYPE html>\n<html lang=\"en\">\n<head>\n    <meta charset=\"UTF-8\">\n    <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">\n    <title>Document</title>\n</head>\n<body>\n    \n</body>\n</html>",
            "div": "<div class=\"\">\n    \n</div>",
            "span": "<span class=\"\"></span>",
            "a": "<a href=\"#\">Link</a>",
            "img": "<img src=\"\" alt=\"\" />",
            "table": "<table>\n    <thead>\n        <tr>\n            <th>Header</th>\n        </tr>\n    </thead>\n    <tbody>\n        <tr>\n            <td>Data</td>\n        </tr>\n    </tbody>\n</table>",
            "ul": "<ul>\n    <li>Item 1</li>\n    <li>Item 2</li>\n</ul>",
            "ol": "<ol>\n    <li>Item 1</li>\n    <li>Item 2</li>\n</ol>",
            "form": "<form action=\"\" method=\"POST\">\n    <label for=\"\">Label:</label>\n    <input type=\"text\" name=\"\" id=\"\" />\n    <button type=\"submit\">Submit</button>\n</form>",
            "input": "<input type=\"text\" name=\"\" id=\"\" placeholder=\"\" />",
            "button": "<button type=\"button\">Click me</button>",
            "textarea": "<textarea name=\"\" id=\"\" rows=\"4\" cols=\"50\"></textarea>",
            "select": "<select name=\"\" id=\"\">\n    <option value=\"\">Option 1</option>\n    <option value=\"\">Option 2</option>\n</select>",
            "script": "<script>\n    \n</script>",
            "style": "<style>\n    \n</style>",
            "link": "<link rel=\"stylesheet\" href=\"\" />",
            "meta": "<meta name=\"\" content=\"\" />",
            "canvas": "<canvas id=\"\" width=\"300\" height=\"150\"></canvas>",
            "svg": "<svg width=\"100\" height=\"100\" viewBox=\"0 0 100 100\">\n    \n</svg>",
            "video": "<video width=\"320\" height=\"240\" controls>\n    <source src=\"\" type=\"video/mp4\" />\n</video>",
            "audio": "<audio controls>\n    <source src=\"\" type=\"audio/mpeg\" />\n</audio>",
            "iframe": "<iframe src=\"\" width=\"\" height=\"\"></iframe>",
            "header": "<header>\n    \n</header>",
            "footer": "<footer>\n    \n</footer>",
            "nav": "<nav>\n    \n</nav>",
            "section": "<section>\n    \n</section>",
            "article": "<article>\n    \n</article>",
            "aside": "<aside>\n    \n</aside>",
            "main": "<main>\n    \n</main>"
        ]
        
        return snippets[tag.lowercased()]
    }
}
