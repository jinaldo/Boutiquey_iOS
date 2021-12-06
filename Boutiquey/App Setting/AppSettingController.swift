//
//  AppSettingController.swift
//  Boutiquey
//
//  Created by kunal on 24/08/18.
//  Copyright © 2018 yogesh. All rights reserved.
//

import UIKit

class AppSettingController: UIViewController,UITableViewDelegate,UITableViewDataSource {
    
var currencyData  = [Currency]()
var languageData = [Languages]()
var clearCacheData = ["searchdata".localized,"recentviewdata".localized]
var languageCode:String = ""
var whichApiToProcess:String = ""
var currencyCode:String = ""
let defaults = UserDefaults.standard;
let productModel = ProductViewModel()

    @IBOutlet var tableView: UITableView!
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = NetworkManager.sharedInstance.language(key: "setting")
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.reloadData()
    }

    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.isNavigationBarHidden = false
    }

    
    
     func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    
     func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return ["currency".localized, "language".localized,"Clear Cache"][section]
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0{
            return currencyData.count
        }else if section == 1{
            return languageData.count
        }else{
            return clearCacheData.count
        }
    }
    
     func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
       let cell = tableView.dequeueReusableCell(withIdentifier: "settingcell", for: indexPath)
        cell.accessoryType = .none
        cell.textLabel?.alingment()
        if indexPath.section == 0{
            cell.textLabel?.text = currencyData[indexPath.row].title
            if sharedPrefrence.object(forKey: "currency") != nil{
                let currencyCode = sharedPrefrence.object(forKey: "currency") as! String
                if currencyCode == currencyData[indexPath.row].code{
                    cell.accessoryType = .checkmark
                }else{
                    cell.accessoryType = .none
                }
            }
        }else if indexPath.section == 1{
            cell.textLabel?.text = languageData[indexPath.row].title
            if sharedPrefrence.object(forKey: "language") != nil{
                let currencyCode = sharedPrefrence.object(forKey: "language") as! String
                if currencyCode == languageData[indexPath.row].code{
                    cell.accessoryType = .checkmark
                }else{
                    cell.accessoryType = .none
                }
            }
        }else{
            cell.textLabel?.text = clearCacheData[indexPath.row]
            cell.accessoryType = .disclosureIndicator
        }
      return cell
    
    }
    
    
    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if section == 0{
            return "currencyinfo".localized
        }else if section == 1{
            return "languageinfo".localized
        }else{
           return "cleardata".localized
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0{
            self.currencyCode = currencyData[indexPath.row].code
            self.whichApiToProcess = "currencychanges"
            self.callingHttppApi()
        }else if indexPath.section == 1{
            self.languageCode = languageData[indexPath.row].code
            self.whichApiToProcess = "languagechanges"
            self.callingHttppApi()
        }else if indexPath.section == 2{
            if indexPath.row == 0{
                let AC = UIAlertController(title: NetworkManager.sharedInstance.language(key: "message"), message: NetworkManager.sharedInstance.language(key: "clearsearchhistory"), preferredStyle: .alert)
                let okBtn = UIAlertAction(title: NetworkManager.sharedInstance.language(key: "clear"), style: .default, handler: {(_ action: UIAlertAction) -> Void in
                    self.defaults.removeObject(forKey:"recentsearch")
                    NetworkManager.sharedInstance.showSuccessSnackBar(msg: "removesuccess".localized)
                    
                })
                let noBtn = UIAlertAction(title: NetworkManager.sharedInstance.language(key: "cancel"), style: .destructive, handler: {(_ action: UIAlertAction) -> Void in
                })
                AC.addAction(okBtn)
                AC.addAction(noBtn)
                self.present(AC, animated: true, completion:nil)
                
            }else if indexPath.row == 1{
                let AC = UIAlertController(title: NetworkManager.sharedInstance.language(key: "message"), message: NetworkManager.sharedInstance.language(key: "clearrecentview"), preferredStyle: .alert)
                let okBtn = UIAlertAction(title: NetworkManager.sharedInstance.language(key: "clear"), style: .default, handler: {(_ action: UIAlertAction) -> Void in
                    self.productModel.deleteAllRecentViewProductData()
                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: "refreshRecentView"), object: nil)
                    NetworkManager.sharedInstance.showSuccessSnackBar(msg: "removesuccess".localized)
                    
                })
                let noBtn = UIAlertAction(title: NetworkManager.sharedInstance.language(key: "cancel"), style: .destructive, handler: {(_ action: UIAlertAction) -> Void in
                })
                AC.addAction(okBtn)
                AC.addAction(noBtn)
                self.present(AC, animated: true, completion:nil)
                
            }
        }
    
    }
    
    
    
    func loginRequest(){
        var loginRequest = [String:String]();
        loginRequest["apiKey"] = API_USER_NAME;
        loginRequest["apiPassword"] = API_KEY.md5;
        if self.defaults.object(forKey: "language") != nil{
            loginRequest["language"] = self.defaults.object(forKey: "language") as? String;
        }
        if self.defaults.object(forKey: "currency") != nil{
            loginRequest["currency"] = self.defaults.object(forKey: "currency") as? String;
        }
        if self.defaults.object(forKey: "customer_id") != nil{
            loginRequest["customer_id"] = self.defaults.object(forKey: "customer_id") as? String;
        }
        NetworkManager.sharedInstance.callingHttpRequest(params:loginRequest, apiname:"common/apiLogin", cuurentView: self){val,responseObject in
            if val == 1{
                let dict = responseObject as! NSDictionary
                self.defaults.set(dict.object(forKey: "wk_token") as! String, forKey: "wk_token")
                self.defaults.set(dict.object(forKey: "language") as! String, forKey: "language")
                self.defaults.set(dict.object(forKey: "currency") as! String, forKey: "currency")
                self.defaults.synchronize();
                self.callingHttppApi()
            }else if val == 2{
                NetworkManager.sharedInstance.dismissLoader()
                self.callingHttppApi()
                
            }
        }
    }
    
    func callingHttppApi(){
        DispatchQueue.main.async{
            let sessionId = self.defaults.object(forKey:"wk_token");
            var requstParams = [String:Any]();
            requstParams["wk_token"] = sessionId;
            
            if  self.whichApiToProcess == "languagechanges"{
                requstParams["code"] = self.languageCode;
                NetworkManager.sharedInstance.callingHttpRequest(params:requstParams, apiname:"common/language", cuurentView: self){success,responseObject in
                    if success == 1 {
                        NetworkManager.sharedInstance.dismissLoader()
                        let dict = responseObject as! NSDictionary;
                        if dict.object(forKey: "fault") != nil{
                            let fault = dict.object(forKey: "fault") as! Bool;
                            if fault == true{
                                self.loginRequest()
                            }
                        }else{
                            if dict.object(forKey: "error") as! Int == 0{
                                self.doFurtherProcessingWithResult()
                            }
                        }
                        
                    }else if success == 2{
                        NetworkManager.sharedInstance.dismissLoader()
                        self.callingHttppApi();
                    }
                }
                
                
            }else if self.whichApiToProcess == "currencychanges"{
                requstParams["code"] = self.currencyCode;
                NetworkManager.sharedInstance.callingHttpRequest(params:requstParams, apiname:"common/currency", cuurentView: self){success,responseObject in
                    if success == 1 {
                        NetworkManager.sharedInstance.dismissLoader()
                        let dict = responseObject as! NSDictionary;
                        if dict.object(forKey: "fault") != nil{
                            let fault = dict.object(forKey: "fault") as! Bool;
                            if fault == true{
                                self.loginRequest()
                            }
                        }else{
                            if dict.object(forKey: "error") as! Int == 0{
                                self.doFurtherProcessingWithResult()
                            }
                        }
                        
                    }else if success == 2{
                        NetworkManager.sharedInstance.dismissLoader()
                        self.callingHttppApi()
                        
                        
                    }
                }
            }
        }
    }
    
    
    func doFurtherProcessingWithResult(){
        productModel.deleteAllRecentViewProductData()
        DBManager.sharedInstance.deleteAllFromDatabase()
        if whichApiToProcess == "languagechanges"{
            defaults.set(languageCode, forKey: "language")
            defaults.synchronize()
            if languageCode == "ar" {
                L102Language.setAppleLAnguageTo(lang: "ar")
                if #available(iOS 9.0, *) {
                    UIView.appearance().semanticContentAttribute = .forceRightToLeft
                } else {
                    // Fallback on earlier versions
                }
            }else {
                L102Language.setAppleLAnguageTo(lang: "en")
                if #available(iOS 9.0, *) {
                    UIView.appearance().semanticContentAttribute = .forceLeftToRight
                } else {
                    // Fallback on earlier versions
                }
            }
        }else if whichApiToProcess  == "currencychanges"{
            defaults.set(currencyCode, forKey: "currency")
            defaults.synchronize()
        }
        
        let rootviewcontroller: UIWindow = ((UIApplication.shared.delegate?.window)!)!
        rootviewcontroller.rootViewController = self.storyboard?.instantiateViewController(withIdentifier: "rootnav")
        let mainwindow = (UIApplication.shared.delegate?.window!)!
        mainwindow.backgroundColor = UIColor(hue: 0.6477, saturation: 0.6314, brightness: 0.6077, alpha: 0.8)
        UIView.transition(with: mainwindow, duration: 0.55001, options: .transitionFlipFromLeft, animations: { () -> Void in
            
        }) { (finished) -> Void in
        }
    }
    
}
