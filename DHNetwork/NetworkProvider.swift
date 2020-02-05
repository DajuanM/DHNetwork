//
//  NetworProvider.swift
//  Collector
//
//  Created by listen on 2017/12/8.
//  Copyright © 2017年 covermedia. All rights reserved.
//

import UIKit
import Moya
import RxSwift

class NetworkProvider<Target: TargetType> {
    private let provider: MoyaProvider<Target>

    init(endpointClosure: @escaping MoyaProvider<Target>.EndpointClosure = NetworkProvider.endpointMapping,
//         requestClosure: @escaping MoyaProvider<Target>.RequestClosure = MoyaProvider.defaultRequestMapping,
         stubClosure: @escaping MoyaProvider<Target>.StubClosure = MoyaProvider.neverStub,
         manager: Manager = NetworkProvider.sessionManager(),
         plugins: [PluginType] = [NetworkLogger()],
         trackInflights: Bool = false) {
        self.provider = MoyaProvider(endpointClosure: endpointClosure,
//                                     requestClosure: requestClosure,
                                     stubClosure: stubClosure,
                                     manager: manager,
                                     plugins: plugins,
                                     trackInflights: trackInflights)
    }

    func request(_ target: Target) -> Observable<Moya.Response> {
        return provider.rx
            .request(target)
            .filterSuccessfulStatusAndRedirectCodes()
            .retryWithAuthIfNeeded(limit: 5)
            .asObservable()
    }

}

struct NetModel: Decodable {
    let message: String?
    let status: Int
    var isSucceed: Bool {
        return 200 == status
    }
}
struct InvalidToken: Codable {
    let error_description: String
    let error: String?
}

extension ObservableType where E == Response {

    //data字段为空（或者值没有意义）时，使用 MapVoid()
    func mapVoid() -> Observable<Void> {
        return mapToModel(NetModel.self, keyPath: "").map { _ in Void() }
    }
    func mapToModel<T: Decodable>(_: T.Type, decoder: JSONDecoder = JSONDecoder.init(), keyPath: String = "data") -> Observable<T> {
        return map({ (response) -> T in
            let object = try Network.decodableObject(data: response.data, type: T.self, decoder: decoder, keyPath: keyPath)
            return object
        }).catchError { (err) -> Observable<T> in
            // 捕获错误，转换为VBError
            return Observable<T>.create({ (observe) -> Disposable in
//                var finalError = VBError.dataMapError(err.localizedDescription)
                var finalError = VBError.server(0, "")
                if let error = err as? MoyaError, let reponse = error.response {
                    if reponse.statusCode == NSURLErrorTimedOut {
                        finalError = VBError.timeOut
                    }
                } else if let error = err as? VBError {
                    finalError = error
                }
                observe.onError(finalError)
                return Disposables.create()
            })}
    }

    func mapToArrayModel<T: Decodable>(_: T.Type, decoder: JSONDecoder = JSONDecoder.init(), keyPath: String? = "data") -> Observable<[T]> {

        return map({ (response) -> [T] in
            let object = try Network.decodableArrayObject(data: response.data,
                                                          type: T.self,
                                                          decoder: decoder,
                                                          keyPath: keyPath)
            return object
        }).catchError { (err) -> Observable<[T]> in
            // 捕获错误，转换为VBError
            return Observable<[T]>.create({ (observe) -> Disposable in
//                var finalError = VBError.dataMapError(err.localizedDescription)
                var finalError = VBError.server(0, "")
                if let error = err as? MoyaError, let reponse = error.response {
                    if reponse.statusCode == NSURLErrorTimedOut {
                        finalError = VBError.timeOut
                    }
                } else if let error = err as? VBError {
                    finalError = error
                }
                observe.onError(finalError)
                return Disposables.create()
            })}
    }

    func mapToDict() -> Observable<[String: Any]> {
        return map({ (response) -> [String: Any] in
            let json = try JSONSerialization.jsonObject(with: response.data, options: .allowFragments)
            if let dict = json as? [String: Any] {
                let status = dict["status"] as? Int
                if status != nil, status == 200 {
                    return dict
                }
                let message = dict["message"] as? String
                throw VBError.server(status ?? 0, message ?? "未知错误")
            }
            throw VBError.serverDataError
        }).catchError { (err) -> Observable<[String: Any]> in
            // 捕获错误，转换为VBError
            return Observable<[String: Any]>.create({ (observe) -> Disposable in
//                var finalError = VBError.dataMapError(err.localizedDescription)
                var finalError = VBError.server(0, "")
                if let error = err as? MoyaError, let reponse = error.response {
                    if reponse.statusCode == NSURLErrorTimedOut {
                        finalError = VBError.timeOut
                    }
                } else if let error = err as? VBError {
                    finalError = error
                }
                observe.onError(finalError)
                return Disposables.create()
            })}
    }
}
