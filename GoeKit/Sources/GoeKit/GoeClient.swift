//
//  GoeClient.swift
//  GoeKit
//
//  Created by Christoph Pageler on 30.04.24.
//

import Foundation

public class GoeClient {
    public var url: URL

    public init?(address: String) {
        guard let urlFromString = URL(string: "http://\(address)/api/status") else { return nil }
        url = urlFromString
    }

    public func status(filter: String) async -> GoeControllerStatusResponse? {
        guard var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return nil }
        urlComponents.queryItems = [
            .init(name: "filter", value: filter)
        ]
        guard let statusURL = urlComponents.url else { return nil }
        guard let data = try? await URLSession.shared.data(from: statusURL) else { return nil }
        return try? JSONDecoder().decode(GoeControllerStatusResponse.self, from: data.0)
    }
}

public struct GoeControllerStatusResponse: Codable {
    public var ccn: [String]?
    public var ccp: [Double?]?
}
