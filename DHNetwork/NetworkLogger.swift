//
//  NetworkLogger.swift
//  Collector
//
//  Created by listen on 2017/12/8.
//  Copyright © 2017年 covermedia. All rights reserved.
//

import UIKit
import Moya

class NetworkLogger: PluginType {

    /// Called immediately before a request is sent over the network (or stubbed).
    func willSend(_ request: RequestType, target: TargetType) {
        if logNetwork {
            print("Request LOGGING :: \(request.request?.url?.absoluteString ?? String())")
        }
    }
    /// Called after a response has been received, but before the MoyaProvider has invoked its completion handler.
    func didReceive(_ result: Result<Moya.Response, MoyaError>, target: TargetType) {
        if logNetwork {
            switch result {
            case .success(let response):
                print(" Response LOGGING ::  \(response.response?.url?.absoluteString ?? String())")
                    if let json = try? response.mapJSON() {
                        print("Response:")
                        print(json)
                    }
            case .failure(let error):
                print("Response ERROR :: \(error.localizedDescription)")
            }
        }
    }

}
