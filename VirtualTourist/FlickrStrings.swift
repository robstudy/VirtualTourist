//
//  FlickrStrings.swift
//  VirtualTourist
//
//  Created by Robert Garza on 4/13/16.
//  Copyright © 2016 Robert Garza. All rights reserved.
//

import Foundation

extension FlickrAPI {
    
    struct FlickrStrings {
        static let API_KEY = "2a2c8e47d731e1f7d1c57322fc734e4b"
        static let BASE_URL = "https://api.flickr.com/services/rest/"
        static let METHOD_NAME = "flickr.photos.search"
        static let EXTRAS = "url_m"
        static let SAFE_SEARCH = "1"
        static let DATA_FORMAT = "json"
        static let NO_JSON_CALLBACK = "1"
        static func randomSort(randomResult: Int) -> String {
            switch randomResult {
            case 0:
                return "date-posted-asc"
            case 1:
                return "date-posted-desc"
            case 2:
                return "date-taken-asc"
            case 3:
                return "date-taken-desc"
            case 4:
                return "interestingness-desc"
            case 5:
                return "interestingness-asc"
            default:
                return "relevance"
            }
        }
    }
}