//
//  HamrahPay.swift
//  test36
//
//  Created by MAC on 10/19/16.
//  Copyright © 2016 MAC. All rights reserved.
//

import UIKit

protocol OnEventHamrahPay{
    func OnStart()
    func OnError(err:String)
    func OnFinish(res:AnyObject)
}

class HamrahPay  {
    
    var sku : String = ""
    var device_id : String = "HamrahPay\(UIDevice.current.identifierForVendor!.uuidString)"
    var verification_type : String = "email_verification"
    var email : String = ""
    
    static var ErrorList = (
        EMPTY_RESULT : (errorCode:-1 , messageCode:"مقادیر بازگتی از سایت همراه پی معتبر نیست"),
        ERROR_PARSING : (errorCode:-2,messageCode:"نتایج باگشتی قابل پردازش نیست"),
        ERROR_RESULT : (errorCode:-3 ,messageCode:"خطای بازگشتی از همراه پی  "),
        ERROR_PAY_CODE : (errorCode:-4,messageCode:"مقدار شماره خرید بازگشتی نا معتبر است")
    )
    
    init(sku : String , email : String) {
        self.email = email
        self.sku = sku
    }
    
    public func PayRequest(event : OnEventHamrahPay)
    {
        
        var params : [String:String] = [:]
        
        params["sku"] = sku
        params["device_id"] = device_id
        params["verification_type"] = verification_type
        params["email"] = email
        let url = "https://hamrahpay.com/rest-api/pay-request"
        
        
        class newEvent : OnEventHamrahPay {
            private var e : OnEventHamrahPay
            
            init(event:OnEventHamrahPay) {
                e = event
            }
            
            func OnStart()->Void{
                e.OnStart()
            }
            
            func OnError(err:String)->Void{
                e.OnError(err: err)
            }
            
            func OnFinish(res:AnyObject)->Void{
                
                let data: Data! = res as! Data
                
                let convertedString = NSString(data: data, encoding: String.Encoding.utf8.rawValue)
               
                if(data == nil){
                    e.OnError(err:HamrahPay.ErrorList.EMPTY_RESULT.messageCode)
                    return
                }
                
                let parse : (errorCode:Int , messageCode:String) = HamrahPay.ParseRequest(JSON: data)
                
                if(parse.errorCode == 0 || parse.errorCode == 1){
                    e.OnFinish(res: (error_code:parse.errorCode , pay_code:parse.messageCode) as AnyObject)
                    return
                }
                
                e.OnError(err: parse.messageCode)
            }
            
        }
                
        SendData(url: url, params: params,event: newEvent(event: event))
    }
    
    
    
    public func PayVerify(pay_code:String,event:OnEventHamrahPay){
        var params : [String:String] = [:]
        
        params["sku"] = sku
        params["device_id"] = device_id
        params["verification_type"] = verification_type
        params["email"] = email
        params["pay_code"] = pay_code
        params["device_model"] = "Iphone"
        params["device_manufacturer"] = "Apple"
        params["sdk_version"] = "21"
        params["android_version"] = "1.2.3"
        
        let url = "https://hamrahpay.com/rest-api/verify-payment"
        
        class newEvent : OnEventHamrahPay {
            private var e : OnEventHamrahPay? = nil
            
            init(event:OnEventHamrahPay) {
                e = event
            }
            
            func OnStart()->Void{
                e?.OnStart()
            }
            
            func OnError(err:String)->Void{
                e?.OnError(err: err)
            }
            
            func OnFinish(res:AnyObject)->Void{
                
                let data: Data! = res as! Data
                //data = NSString(data: data, encoding: String.Encoding.utf8.rawValue)
                
                
                if(data == nil){
                    e?.OnError(err:HamrahPay.ErrorList.EMPTY_RESULT.messageCode)
                    return
                }
                
                let parse : (errorCode:Int , messageCode:String) = HamrahPay.ParseVerify(JSON: data)
                
                if(parse.errorCode == 0 ){
                    e?.OnFinish(res: parse.messageCode as AnyObject)
                    return
                }
                
                e?.OnError(err: parse.messageCode)
            }
            
        }
        
        SendData(url: url, params: params, event: newEvent(event: event))
        
    }
    
    static public func ParseVerify(JSON:Data!)->(errorCode:Int , messageCode:String)
    {
        let convertedString = NSString(data: JSON, encoding: String.Encoding.utf8.rawValue)
        
        if(JSON == nil){
            return ErrorList.EMPTY_RESULT
        }
        
        var JsonObject : [String:AnyObject]? = nil
        
        do {
            
            JsonObject = try(JSONSerialization.jsonObject(with: JSON, options: .mutableContainers)) as? [String : AnyObject]
            if(JsonObject==nil)
            {
                return ErrorList.EMPTY_RESULT
            }
            
        } catch let err {
            
            return ErrorList.ERROR_PARSING
        }
        
        let status : String! = JsonObject?["status"] as? String
        let error : Bool! = JsonObject?["error"] as? Bool
        let message : String! = JsonObject?["message"] as? String
      
        if (status=="SUCCESSFUL_PAYMENT") {
            return (0, "پرداخت با موفقیت انجام گردید. هم اکنون میتوانید از امکانات نرم افزار استفاده نمایید.");
        } else {
            return (ErrorList.ERROR_RESULT.errorCode,ErrorList.ERROR_RESULT.messageCode);
        }
    }
    
    static public func ParseRequest(JSON:Data!)-> (errorCode:Int , messageCode:String)
    {
        if(JSON == nil){
            return ErrorList.EMPTY_RESULT
        }
        
        var JsonObject : [String:AnyObject]? = nil
        
        do {
            
            JsonObject = try(JSONSerialization.jsonObject(with: JSON, options: .mutableContainers)) as? [String : AnyObject]
            if(JsonObject==nil)
            {
                return ErrorList.EMPTY_RESULT
            }
            
        } catch let err {
            
            return ErrorList.ERROR_PARSING
        }
        
        let status : String! = JsonObject?["status"] as? String
        let error : Bool! = JsonObject?["error"] as? Bool
        let message : String! = JsonObject?["message"] as? String
        let pay_code : String! = JsonObject?["pay_code"] as? String
        
        if(error == false){
            if(status == "READY_TO_PAY"){
                return (0,pay_code)
            }else if(status == "BEFORE_PAID"){
                return (1,"BEFOR_PAID")
            }else{
                return (errorCode:ErrorList.ERROR_RESULT.errorCode , messageCode:ErrorList.ERROR_RESULT.messageCode)
            }
        }
        
        
        
        return ErrorList.ERROR_PAY_CODE
    }
    
    public func SendData(url : String , params : [String:String],event:OnEventHamrahPay)
    {
        event.OnStart()
       
       
        var postString = ""
        var i = 0
        for (key,val) in params {
            if (postString.characters.count != 0){
                postString = postString + "&"
            }
             postString = postString + key + "=" + val
            i += 1
        }
        let url:NSURL = NSURL(string: url)!
        let session = URLSession.shared
        
        let request = NSMutableURLRequest(url: url as URL)
        request.httpMethod = "POST"
        request.cachePolicy = NSURLRequest.CachePolicy.reloadIgnoringCacheData
        
        request.httpBody = postString.data(using: String.Encoding.utf8)
        
        let task = session.dataTask(with: request as URLRequest) {
            (data, response, error) in
            guard let _:NSData = data as NSData?, let _:URLResponse = response  , error == nil else {
                
                return
            }
            
            DispatchQueue.main.async(execute: {
                event.OnFinish(res: data! as AnyObject);
            })
            
        }
        
        task.resume()
        
    }
    
}
