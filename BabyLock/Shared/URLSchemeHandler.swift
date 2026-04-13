import Foundation

enum URLSchemeHandler {
    static func parse(_ url: URL) -> URL? {
        guard url.scheme == "babylock",
              url.host == "open",
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let urlString = components.queryItems?.first(where: { $0.name == "url" })?.value,
              !urlString.isEmpty,
              let contentURL = URL(string: urlString),
              contentURL.scheme == "https" || contentURL.scheme == "http"
        else { return nil }
        return contentURL
    }

    static func buildOpenURL(for contentURL: URL) -> URL {
        var components = URLComponents()
        components.scheme = "babylock"
        components.host = "open"
        components.queryItems = [URLQueryItem(name: "url", value: contentURL.absoluteString)]
        return components.url!
    }
}
