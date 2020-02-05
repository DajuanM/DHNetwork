//
//  API.swift
//  MoyaDemo
//
//  Created by Mustafa on 11/8/17.
//  Copyright © 2017 Mustafa. All rights reserved.
//

import Foundation
import RxSwift
import Moya


extension PrimitiveSequence where TraitType == SingleTrait, ElementType == Response {

    func retryWithAuthIfNeeded(limit: Int) -> Single<E> {
        return self.retryWhen { errors in
            return errors.enumerated().flatMap { (retryCount, error) -> PrimitiveSequence<SingleTrait, Void> in
                // 重试超过限制返回错误
                if retryCount >= limit {
                    throw VBError.timeOut
                }

                if case MoyaError.statusCode(let response) = error,
                    let json = try JSONSerialization.jsonObject(with: response.data, options: JSONSerialization.ReadingOptions.allowFragments) as? [String: Any],
                    let status = json["status"] as? Int,
                    status == 40101 {
                    var needRefreshToken = true
                    if let errorMsg = json["message"] as? String,
                        errorMsg.hasPrefix("User token is kicked") {
                        needRefreshToken = false
                        let alertVC = UIAlertController(title: "提示", message: "你的账号已在其他地方登录，如非本人操作，请及时修改密码！", preferredStyle: .alert)
                        let action = UIAlertAction(title: "确定", style: .default) { (_) in
                            NotificationCenter.default.post(name: NSNotification.Name.init("jumpToLogin"), object: nil)
                        }
                        alertVC.addAction(action)
                        UIApplication.shared.keyWindow?.rootViewController?.present(alertVC, animated: true, completion: nil)
                    } else if let errorMsg = json["error_description"] as? String,
                        errorMsg.hasPrefix("Invalid refresh token") {
                        needRefreshToken = false
                        NotificationCenter.default.post(name: NSNotification.Name.init("jumpToLogin"), object: nil)
                    }

                    if needRefreshToken {
                        return Provider.rx
                                    .request(BaseAPI.refreshToken)
                                    .filterSuccessfulStatusCodes()
                                    .map(TokenModel.self, atKeyPath: nil, using: JSONDecoder())
                                    .flatMap({ (model) in
                                        UserDefaults.standard.set(model.access_token ?? "", forKey: "access_token")
                                        return Single.just(())
                                    })
                                    .catchError({ (_) in
                                        NotificationCenter.default.post(name: NSNotification.Name.init("jumpToLogin"), object: nil)
                                        throw VBError.refreshTokenError
                                    })
                    }else {
                        throw VBError.tokenInvalid
                    }
                } else {
                    if case MoyaError.statusCode(let response) = error {
                        let json = try JSONSerialization.jsonObject(with: response.data, options: JSONSerialization.ReadingOptions.allowFragments) as? [String: Any]

                        if let errorMsg = json?["error_description"] as? String {
                            if errorMsg == "40402" {
                                throw VBError.server(0, "用户名或密码错误")
                            } else if errorMsg.hasPrefix("Invalid refresh token") {
                                NotificationCenter.default.post(name: NSNotification.Name.init("jumpToLogin"), object: nil)
                                throw VBError.tokenInvalid
                            } else {
                                throw VBError.server(0, errorMsg)
                            }
                        } else if let status = json?["status"] as? Int, status == 500 {
                            throw VBError.server(0, "服务器异常")
                        } else if let errorMsg = json?["error"] as? String {
                            throw VBError.server(0, errorMsg)
                        }else {
                            throw VBError.server(0, "未知错误")
                        }
                    } else {
                        throw VBError.timeOut
                    }
                }
            }
        }
    }
}

func cancelAllRequest() {
    Provider.manager.session.getTasksWithCompletionHandler { dataTasks, uploadTasks, downloadTasks in
        dataTasks.forEach { $0.cancel() }
        uploadTasks.forEach { $0.cancel() }
        downloadTasks.forEach { $0.cancel() }
    }
//    let attendancenProvider = MoyaProvider<AttendanceAPI>(endpointClosure: NetworkProvider.endpointMapping,
//                                                          plugins: [NetworkLoggerPlugin(verbose: true, responseDataFormatter: JSONResponseDataFormatter)])
//    attendancenProvider.manager.session.getTasksWithCompletionHandler { dataTasks, uploadTasks, downloadTasks in
//        dataTasks.forEach { $0.cancel() }
//        uploadTasks.forEach { $0.cancel() }
//        downloadTasks.forEach { $0.cancel() }
//    }
}

private let endpointClosure = { (target: BaseAPI) -> Moya.Endpoint in
    return Endpoint(
        url: "\(URL(target: target).absoluteString)",
        sampleResponseClosure: { .networkResponse(200, target.sampleData) },
        method: target.method,
        task: target.task,
        httpHeaderFields: target.headers)

}

func JSONResponseDataFormatter(_ data: Data) -> Data {
    do {
        let dataAsJSON = try JSONSerialization.jsonObject(with: data)
        let prettyData =  try JSONSerialization.data(withJSONObject: dataAsJSON, options: .prettyPrinted)
        return prettyData
    } catch {
        return data // fallback to original data if it can't be serialized.
    }
}

let Provider = MoyaProvider<BaseAPI>(endpointClosure: NetworkProvider.endpointMapping,
                                          plugins: [NetworkLoggerPlugin(verbose: true, responseDataFormatter: JSONResponseDataFormatter)])
