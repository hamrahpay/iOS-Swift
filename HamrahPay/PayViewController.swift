//
//  PayViewController.swift
//  Project_4
//
//  Created by MAC on 10/20/16.
//  Copyright © 2016 MAC. All rights reserved.
//

import UIKit

class PayViewController: UIViewController {

    @IBOutlet var TextView: UITextView!
    @IBOutlet var btnPay: UIButton!
    @IBOutlet var TxtUserName: UITextField!
    @IBOutlet var TxtPass: UITextField!
    @IBOutlet var lblUserName: UILabel!
    @IBOutlet var lblMessage: UILabel!
    
    @IBOutlet var lblPass: UILabel!
     var PayName : String = "hp_56f2d475bbbdc079328397"
    
     var hp :HamrahPay!
    
    @IBOutlet var IconImage: UIImageView!
    @IBOutlet var actInd: UIActivityIndicatorView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        TxtPass.isSecureTextEntry = true
        // Do any additional setup after loading the view.
        let savedFlag = ReadObject("smf")
        
        if(savedFlag != nil && savedFlag == UIDevice.current.identifierForVendor!.uuidString as String )
        {
            btnPay.isHidden = true
            TxtUserName.isHidden = true
            TxtPass.isHidden = true
            lblPass.isHidden = true
            lblUserName.isHidden = true
            lblMessage.text = "خرید انجام شده است"
        }
    }
    
   
    @IBAction func StartPay(_ sender: AnyObject) {
        
        if((TxtPass.text?.characters.count)! < 8 || (TxtUserName.text?.characters.count)! < 8)
        {
            lblMessage.text = "نام کاربری و گذرواژه باید بیش از ۸ حرف باشد"
            return
        }
       
        var email : String = TxtUserName.text! + TxtPass.text!
        email = getHash(str: email)
        
        
        
        let emailPart_1 : String = SubString(email, start: 0, end: email.characters.count / 2)!
        let emailPart_2 : String = SubString(email, start: email.characters.count / 2 , end: email.characters.count)!
        email = "\(emailPart_1)@\(emailPart_2).com"
        hp = HamrahPay(sku: PayName, email: email)
        
        class event : OnEventHamrahPay {
            var vc : PayViewController
            
            init(v:PayViewController) {
                vc = v
            }
            
           func OnStart()->Void{
            vc.actInd.startAnimating()
            print("Start")
            }
            
            func OnError(err:String)->Void{
                vc.actInd.stopAnimating()
                print("error = \(err)")
            }
            
            func OnFinish(res:AnyObject)->Void{
                vc.actInd.stopAnimating()
                let pay : (error_code:Int,pay_code:String) = res as! (error_code:Int,pay_code:String)
                
                let pay_code = pay.pay_code
                print("payError = \(pay.error_code)")
                if(pay.error_code==0){
                    
                    vc.showWeb(pay_code);
                }else{
                    if(pay.error_code==1 && pay.pay_code == "BEFOR_PAID"){
                        vc.btnPay.isHidden = true
                        vc.actInd.stopAnimating()
                       vc.lblMessage.text = "خرید با موفقیت بازیابی شد"
                       PayViewController.SaveObject("smf", value: UIDevice.current.identifierForVendor!.uuidString as AnyObject)
                    }else{
                       vc.Verify(pay_code: pay_code)
                    }
                }
            }
            
        }
        
        hp.PayRequest(event: event(v: self))
    }
    
    func showWeb(_ pay_code:String){
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let controller = storyboard.instantiateViewController(withIdentifier: "HamrahPayWebViewController") as! HamrahPayWebViewController
        controller.PayCode = pay_code
        controller.vc = self
        self.present(controller,animated: true,completion: nil)
    }
    
    func Verify(pay_code:String){
        
        class event : OnEventHamrahPay{
            init(vc : PayViewController) {
                self.vc = vc
            }
            var vc : PayViewController
            func OnStart() {
                vc.actInd.startAnimating()
            }
            
            func OnError(err: String) {
                vc.actInd.stopAnimating()
               vc.lblMessage.text = err
            }
            
            func OnFinish(res: AnyObject) {
                vc.btnPay.isHidden = true
                vc.actInd.stopAnimating()
                vc.lblMessage.text = "خرید با موفقیت انجام شد"
                PayViewController.SaveObject("smf", value: UIDevice.current.identifierForVendor!.uuidString as AnyObject)
            }
        }
        
        hp.PayVerify(pay_code: pay_code, event: event(vc: self))
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func back(_ sender: AnyObject) {
        
        self.dismiss(animated: true, completion: nil)
    }
     func getHash(str:String)->String{
        let data = (str).data(using: String.Encoding.utf8)
        var Mycode = data!.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0))
        
        Mycode = Mycode.replacingOccurrences(of: "=", with: "a", options: .literal, range: nil)
        
        var intArray1 : [Int] = []
        var intArray2 : String = ""
        
        
        for character in Mycode.utf8 {
            var asciiCode: Int = Int(character)
            if(asciiCode >= 48 && asciiCode <= 57 )
            {
                asciiCode += 17
                
            }
            intArray1.append(asciiCode)
        }
        print("\(intArray1)")
        
        while (intArray1.count > 0)
        {
            if(intArray1.count == 1)
            {
                intArray2 += "\(Character(UnicodeScalar(intArray1[0])!))"
                break
            }
            var c = (intArray1[0] + intArray1[1])/2
            if(c >= 91 && c <= 96)
            {
                c = c + 7
            }
            
            intArray2 += "\(Character(UnicodeScalar(c)!))"
            intArray1.removeFirst()
            intArray1.removeFirst()
        }
        
        if(intArray2.characters.count > 40){
            intArray2 = getHash(str: intArray2)
        }
        
        return intArray2
    }
     func SubString(_ string: String , start : Int,end:Int) -> String?
    {
        let ss:Int = start
        let ee:Int = end
        let path  = string.substring(with: (string.characters.index(string.startIndex, offsetBy: ss) ..< string.characters.index(string.startIndex, offsetBy: ee)))
        
        return path
    }
    
    static func SaveObject(_ key:String , value:AnyObject){
        let preferences = UserDefaults.standard
        
        
        preferences.set(value, forKey: key)
        
        let didSave = preferences.synchronize()
      
    }
     func ReadObject(_ key:String)-> String!{
        let preferences = UserDefaults.standard
        
        
        if preferences.string(forKey: key) == nil {
            return nil
        } else {
            return preferences.string(forKey: key)! as String!
        }
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
