//
//  GoeClient.swift
//  GoeKit
//
//  Created by Christoph Pageler on 30.04.24.
//

import Foundation

public class GoeClient {
    public var baseURL: URL

    public init?(address: String) {
        guard let urlFromString = URL(string: "http://\(address)") else { return nil }
        baseURL = urlFromString
    }

    public func status(filter: String) async -> GoeControllerStatusResponse? {
        guard var urlComponents = URLComponents(url: baseURL, resolvingAgainstBaseURL: false) else { return nil }
        urlComponents.path = "/api/status"
        urlComponents.queryItems = [
            .init(name: "filter", value: filter)
        ]
        guard let statusURL = urlComponents.url else { return nil }
        guard let data = try? await URLSession.shared.data(from: statusURL) else { return nil }
        return try? JSONDecoder().decode(GoeControllerStatusResponse.self, from: data.0)
    }

    private func set(apiKeys: [String: String]) async -> [String: Bool]? {
        guard var urlComponents = URLComponents(url: baseURL, resolvingAgainstBaseURL: false) else { return nil }
        urlComponents.path = "/api/set"
        urlComponents.queryItems = apiKeys.map { .init(name: $0.key, value: $0.value) }
        guard let statusURL = urlComponents.url else { return nil }
        guard let data = try? await URLSession.shared.data(from: statusURL) else { return nil }
        return try? JSONDecoder().decode([String: Bool].self, from: data.0)
    }

    public func logicMode() async throws -> GoeLogicMode {
        guard let statusResponse = await status(filter: "lmo") else { throw GoeError.emptyStatusResponse }
        guard let lmo = statusResponse.lmo else { throw GoeError.apiKeyMissing(key: "lmo") }
        guard let logicMode = GoeLogicMode(rawValue: lmo) else { throw GoeError.apiKeyMappingError }
        return logicMode
    }

    public func setLogicMode(logicMode: GoeLogicMode) async throws -> Bool {
        guard let response = await set(apiKeys: ["lmo": "\(logicMode.rawValue)"]) else { throw GoeError.noSetResponse }
        guard let lmoSuccess = response["lmo"] else { throw GoeError.noSetResponseSuccess }
        return lmoSuccess
    }
}

public struct GoeControllerStatusResponse: Codable {
    public var ccn: [String]?
    public var ccp: [Double?]?
    public var lmo: Int?
}

public enum GoeLogicMode: Int, Codable {
    case basic = 3
    case eco = 4
    case dailyTrip = 5
}

public enum GoeError: Error {
    case emptyStatusResponse
    case apiKeyMissing(key: String)
    case apiKeyMappingError

    case noSetResponse
    case noSetResponseSuccess
}
