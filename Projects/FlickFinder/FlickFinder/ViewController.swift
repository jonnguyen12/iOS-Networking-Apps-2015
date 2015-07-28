//
//  ViewController.swift
//  FlickFinder
//
//  Created by Phuc Nguyen on 7/26/15.
//  Copyright (c) 2015 Phuc Nguyen. All rights reserved.
//

import UIKit

let BASE_URL = "https://api.flickr.com/services/rest/"
let METHOD_NAME = "flickr.photos.search"
let API_KEY = "cf0bf0f96f574a426f8a29d9b6b22640"
let GALLERY_ID = "66911286-72157647263150569"
let EXTRAS = "url_m"
let DATA_FORMAT = "json"
let NO_JSON_CALLBACK = "1"
let SAFE_SEARCH = "1"
let BOUNDING_BOX_HALF_WIDTH = 1.0
let BOUNDING_BOX_HALF_HEIGHT = 1.0
let LAT_MIN = -90.0
let LAT_MAX = 90.0
let LON_MIN = -180.0
let LON_MAX = 180.0

class ViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var phraseTextField: UITextField!
    @IBOutlet weak var latTextField: UITextField!
    @IBOutlet weak var lonTextField: UITextField!
    @IBOutlet weak var imageTitleLabel: UILabel!
    
    var searchTerm: String! = "Vietnam"
    
    @IBAction func searchByPhrase() {
        textFieldsResign()
        
        if !phraseTextField.text.isEmpty {
            searchTerm = phraseTextField.text
            
            let methodArguments = [
                "method": METHOD_NAME,
                "api_key": API_KEY,
                "text": searchTerm,
                "safe_search": SAFE_SEARCH,
                "extras": EXTRAS,
                "format": DATA_FORMAT,
                "nojsoncallback": NO_JSON_CALLBACK
            ]
            
            getImageFromSearch(methodArguments)
        } else {
          imageTitleLabel.text = "PLEASE ENTER A SEARCH PHRASE!"
        }

    }
    // Helper method
    
    func getImageFromSearch (methodArguments: [String: AnyObject]) {
        let stringURL = BASE_URL + escapedParameters(methodArguments)
        
        let session = NSURLSession.sharedSession()
        let url = NSURL(string: stringURL)!
        let request = NSURLRequest(URL: url)
        
        let task = session.dataTaskWithRequest(request, completionHandler: { (data: NSData!, _, error: NSError!) -> Void in
            if let er = error {
                println("Error downloading the request \(er)")
            } else {
                var  parsingError: NSError? = nil
                let parseResult = NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments, error: &parsingError) as! NSDictionary
                let photosDictionary = parseResult["photos"] as! NSDictionary
                
                let total = photosDictionary.valueForKey("total") as! String
                let totalImages = total.toInt()!
                if totalImages == 0 {
                    var text = "NO PHOTO FOUND"
                    self.imageTitleLabel.text = text
                    
                } else {
                    let photos = photosDictionary.valueForKey("photo") as! NSArray
                    
                    var randomIndex = Int(arc4random_uniform(UInt32(photos.count)))
                    println(randomIndex)
                    
                    let randomPhoto = photos.objectAtIndex(randomIndex) as! NSDictionary
                    
                    let photoURL = randomPhoto.valueForKey("url_m") as! String
                    
                    //Prepare UI updates
                    let photoTitle = randomPhoto["title"] as? String
                    if let imageData = NSData(contentsOfURL: NSURL(string: photoURL)!) {
                        let image = UIImage(data: imageData)
                        
                        // Update UI on main thread
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            self.imageView.image = image
                            self.imageTitleLabel.text = photoTitle
                        })
                    } else {
                        self.imageTitleLabel.text = "NO IMAGE FOUND"
                    }
                    
                    
                }
                
            }
        })
        
        task.resume()
    }
    
    @IBAction func searchByCoordinate() {
        
        textFieldsResign()
        
        if !latTextField.text.isEmpty && !lonTextField.text.isEmpty {
            
            let lat = (latTextField.text as NSString).doubleValue
            let lon = (latTextField.text as NSString).doubleValue
            
            
            if lat > LAT_MAX && lat < LAT_MIN  {
                imageTitleLabel.text = "LATITUDE must be in range [-90,90]"
                return
            }
            
            if lon > LON_MAX && lon < LON_MIN {
                imageTitleLabel.text = "LONGITUDE must be in range [-180,180]"
                return
            }
            
            
            let coordinate = createBboxString()
            
            let methodArguments = [
                "method": METHOD_NAME,
                "api_key": API_KEY,
                "safe_search": SAFE_SEARCH,
                "extras": EXTRAS,
                "format": DATA_FORMAT,
                "nojsoncallback": NO_JSON_CALLBACK,
                "bbox": coordinate
            ]
            
            getImageFromSearch(methodArguments)
        } else {
            imageTitleLabel.text = "PLEASE ENTER LONGITUDE AND LATITUDE"
        }
        
        
    }
    
    func createBboxString() -> String {
        let lat = (latTextField.text as NSString).doubleValue
        let lon = (lonTextField.text as NSString).doubleValue
        
        // make sure box is bounded by min and max
        let bottom_left_lon = max(lon - BOUNDING_BOX_HALF_WIDTH, LON_MIN)
        let bottom_left_lat = max(lat - BOUNDING_BOX_HALF_HEIGHT, LAT_MIN)
        let top_right_lon = min(lon + BOUNDING_BOX_HALF_HEIGHT, LON_MAX)
        let top_right_lat = min(lat + BOUNDING_BOX_HALF_HEIGHT, LAT_MAX)
        
        return "\(bottom_left_lon), \(bottom_left_lat), \(top_right_lon), \(top_right_lat) "
    }
    
    @IBAction func tap(sender: UITapGestureRecognizer) {
        handleSingleTap(sender)
    }
    
    func escapedParameters(paramaters: [String: AnyObject]) -> String
    {
        var urlVars = [String]()
        
        for (key, value) in paramaters {
            let stringValue = "\(value)"
            
            let escapedValue = stringValue.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())
            urlVars += [key + "=" + "\(escapedValue!)"]
        }
        
        return (!urlVars.isEmpty ? "?" : "") + join("&", urlVars)
    }
    
    /* ============================================================
    * Functional stubs for handling UI problems
    * ============================================================ */
    
    /* 1 - Dismissing the keyboard */
    
    func textFieldDidBeginEditing(textField: UITextField) {
        if phraseTextField.editing {
            phraseTextField.text = ""
        } else if lonTextField.editing {
            lonTextField.text = ""
        } else if latTextField.editing {
            latTextField.text = ""
        }
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textFieldsResign()
        return true
    }
    
    func textFieldsResign() {
        if phraseTextField.isFirstResponder() || latTextField.isFirstResponder() || lonTextField.isFirstResponder() {
            view.endEditing(true)
        }
    }
    
    func handleSingleTap(recognizer: UITapGestureRecognizer) {
        textFieldsResign()
    }
    
    /* 2 - Shifting the keyboard so it does not hide controls */
    func subscribeToKeyboardNotifications() {
       NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillShow:", name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillHide:", name: UIKeyboardWillHideNotification, object: nil)
    }
    
    func unsubscribeToKeyboardNotifications() {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func keyboardWillShow(notification: NSNotification) {
        view.frame.origin.y -= getKeyboardHeight(notification)
    }
    
    func keyboardWillHide(notification: NSNotification) {
        view.frame.origin.y += getKeyboardHeight(notification)
    }
    
    func getKeyboardHeight(notification: NSNotification) -> CGFloat {
        let userInfo = notification.userInfo
        let keyboardSize = userInfo![UIKeyboardFrameEndUserInfoKey] as! NSValue
        return keyboardSize.CGRectValue().height
    }
    
    
    // MARK: View life cycles
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        subscribeToKeyboardNotifications()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        unsubscribeToKeyboardNotifications()
    }

}

