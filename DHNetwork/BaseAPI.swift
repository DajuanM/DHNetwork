//
//  VBServiceAPI.swift
//  VB
//
//  Created by AlienLi on 2017/12/16.
//  Copyright © 2017年 MarcoLi. All rights reserved.
//
// swiftlint:disable line_length
import UIKit
import Moya

let baseProvider = NetworkProvider<BaseAPI>()

private let info = Bundle.main.infoDictionary
private let appversion = info!["CFBundleShortVersionString"] as! String
private let minor = info!["CFBundleVersion"] as! String

enum BaseAPI {
    //刷新token
    case refreshToken
}

// MARK: - TargetType Protocol Implementation
extension BaseAPI: TargetType {
    var path: String {
        switch self {
        case .refreshToken:
            return "/auth/oauth/token?grant_type=refresh_token&refresh_token=\(UserDefaults.standard.string(forKey: "refresh_token") ?? "")"
        }

    }

    var method: Moya.Method {
        switch self {
        default:
            return .post
        }
    }

    var parameters: [String: Any] {
        var _params = [String: Any]()
        switch self {
        default:
            break
        }
        return _params
    }

    var task: Task {
        switch self {
        default:
            return Task.requestParameters(parameters: parameters, encoding: URLEncoding.default)
        }
    }

    var sampleData: Data {
        return Data()
    }

    var headers: [String: String]? {
        switch self {
        case .refreshToken:
            return [
                "Accept": "application/json;charset=UTF-8",
                "Content-Type": "application/json;charset=utf-8",
                "usertype": "manager",
                "Authorization": "Basic YXBwOmFwcA==",
                "C-Platform": "iOS", "C-Version": "\(appversion + minor)"
            ]
        }
    }

    var baseURL: URL {
        switch self {
        default:
            return URL.init(string: globalAPIEnvironment.rawValue)!
        }
    }
}
// MARK: - Helpers
private extension String {
    var urlEscaped: String {
        return addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
    }

    var utf8Encoded: Data {
        return data(using: .utf8)!
    }
}


struct TokenModel: Codable {
    var access_token: String?
    var token_type: String?
    var refresh_token: String?
    //集团id
    var tenant: String?
    //部门id
    var depart: String?
    //公司id
    var rent: String?
    var expires_in: Int?
    var scope: String?
    var sub: String?
    var expire: String?
    var userName: String?
    var jti: String?
    var userId: String?
}
