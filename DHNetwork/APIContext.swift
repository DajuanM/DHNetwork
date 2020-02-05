//
//  APIContext.swift
//  Collector
//
//  Created by listen on 2017/12/8.
//  Copyright © 2017年 covermedia. All rights reserved.
//

import UIKit

var globalAPIEnvironment: APIEnvironment = {
    if let api = UserDefaults.standard.object(forKey: "globalAPIEnvironment") as? String {
        return APIEnvironment.init(rawValue: api)!
    } else {
        return APIEnvironment.release
    }
}()

var WebHost: String {
    get {
        if let api = UserDefaults.standard.object(forKey: "globalAPIEnvironment") as? String, api == APIEnvironment.debug.rawValue {
            return "http://rd.ccwcar.com:8088"
        }else {
            return "https://biz.ccwcar.com"
        }
    }
}

let logNetwork = true

enum APIEnvironment: String {
//    case debug = "http://192.168.1.90:8765/api"
    case debug = "http://rd.ccwcar.com:8765/api"
    case release = "https://biz.ccwcar.com/api"
    case carBrand = "http://125.65.82.194:8080/carCommon"

    case debug_mall = "http://ccwcar.iask.in:808/mall/"
    case release_mall = "http://www.ccwcar.com/mall/"

    case debugSocket = "ws://rd.ccwcar.com:8850/websocket"
    case releaseSocket = "wss://biz.ccwcar.com/api/ccwgps/websocket"

}
