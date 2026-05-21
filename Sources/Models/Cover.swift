import Foundation

/// URLTemplate is a template of cover image URL.
public typealias URLTemplate = String

public enum CoverSize: String {
    case extraSmall = "50x50"
    case small = "100x100"
    case medium = "200x200"
    case large = "400x400"
}

extension URLTemplate {
    public func render(with size: CoverSize) -> URL? {
        let replaced = replacingOccurrences(of: "%%", with: size.rawValue)
        let urlString = replaced.hasPrefix("http") ? replaced : "https://\(replaced)"
        return URL(string: urlString)
    }
}
