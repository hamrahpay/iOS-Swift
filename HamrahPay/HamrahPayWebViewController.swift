//
//  HamrahPayWebViewController.swift
//  Project_4
//
//  Created by MAC on 10/21/16.
//  Copyright © 2016 MAC. All rights reserved.
//

import UIKit

class HamrahPayWebViewController: UIViewController {

   @IBOutlet var WebView: UIWebView!
     var PayCode = ""
    @IBOutlet var actInd: UIActivityIndicatorView!
     var vc : PayViewController!
    
    @IBOutlet var UrlTextView: UITextField!
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        let Url: URL
        Url = URL(string : "https://hamrahpay.com/cart/app/pay_v2/\(PayCode)")!
        let Requst = URLRequest(url :Url)
        WebView.loadRequest(Requst)
   
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    @IBAction func Back(_ sender: AnyObject) {
        vc.Verify(pay_code: PayCode)
        self.dismiss(animated: true, completion: nil)
    }
    
    var waiting = false;
    
    func webViewDidStartLoad(_:UIWebView){
        if(!waiting){
            actInd.startAnimating()
            waiting = true
        }
    }
    
    func webViewDidFinishLoad(_:UIWebView){
        
        UrlTextView.text = self.WebView.request?.url?.absoluteString
        actInd.stopAnimating()
        waiting = false
    }
  
 

}
