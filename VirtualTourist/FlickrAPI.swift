//
//  FlickrAPI.swift
//  VirtualTourist
//
//  Created by Robert Garza on 4/13/16.
//  Copyright © 2016 Robert Garza. All rights reserved.
//

import Foundation

class FlickrAPI {
    static let sharedSession = FlickrAPI()
    private var session = NSURLSession.sharedSession()
    
    func getImageFromFlickr(latitude: Double, longitude: Double, completion: (returnedData: Dictionary<String, String>)-> Void){
        
        var returnedArray = [String]()
        var returnedDictionary = Dictionary<String, String>()
        let randomSortString = FlickrStrings.randomSort(Int(arc4random_uniform(6)))
        
        let urlString = "\(FlickrStrings.BASE_URL)?method=\(FlickrStrings.METHOD_NAME)&api_key=\(FlickrStrings.API_KEY)&lat=\(latitude)&lon=\(longitude)&page=1&format=json&nojsoncallback=1&extras=\(FlickrStrings.EXTRAS)&per_page=15&sort=\(randomSortString)"
        let url = NSURL(string: urlString)!
        let request = NSURLRequest(URL: url)
        
        let task = session.dataTaskWithRequest(request) {(data, response, error) in
            guard (error == nil) else {
                print("There was an error with the request: \(error)")
                completion(returnedData: returnedDictionary)
                return
            }
            
            guard let statusCode = (response as? NSHTTPURLResponse)?.statusCode where statusCode >= 200 && statusCode <= 299 else {
                print(error)
                completion(returnedData: returnedDictionary)
                return
            }
            
            guard let data = data else {
                print("No data was returned!")
                return
            }
            
            let parsedResult: AnyObject!
            
            do {
                parsedResult = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)
            } catch {
                parsedResult = nil
                print("Could not parse the data as JSON: '\(data)")
                return
            }
            
            guard let photosDictionary = parsedResult["photos"] as? NSDictionary else {
                print("Cannot find photos in results")
                return
            }
            
            guard let totalPhotos = (photosDictionary["total"] as? NSString)?.integerValue else {
                print("Cannot find key 'total' in dictionary")
                return
            }
            
            if totalPhotos > 0 {
                
                guard let photosArray = photosDictionary["photo"] as? [[String: AnyObject]] else {
                    print("Cannot find key 'photo' in dictionary")
                    return
                }
                
                for item in photosArray {
                    
                    guard let imageURLString = item["url_m"] as? String else {
                        completion(returnedData: ["":""])
                        print("Cannot find key 'url_m' in dictionary")
                        return
                    }
                    
                    guard let imageId = item["id"] as? String else {
                        print("Cannot find id in dictionary")
                        return
                    }
                    
                    returnedArray.append(imageURLString)
                    returnedDictionary[imageId] = imageURLString
                }
                completion(returnedData: returnedDictionary)
            } else {
                completion(returnedData: returnedDictionary)
            }
        }
        task.resume()
    }
}