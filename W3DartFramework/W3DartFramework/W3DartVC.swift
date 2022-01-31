//
//  W3DartVC.swift
//  W3DartFramework
//
//  Created by w3nuts on 22/12/21.
//


import UIKit
import SystemConfiguration
import CoreTelephony
import Foundation
import LocalAuthentication
import CoreLocation

class Captured{
    var paramKey:String
    var paramValue:String
        
    init(paramKey:String, paramValue:String){
        self.paramKey = paramKey
        self.paramValue = paramValue
    }
}
var currentVC = UIViewController()
class W3DartVC: UIViewController {
    var batteryLevel: Float { UIDevice.current.batteryLevel }
    var batteryState: UIDevice.BatteryState { UIDevice.current.batteryState }
    // Screen width.
    public var screenWidth: CGFloat {
        return UIScreen.main.bounds.width
    }

    // Screen height.
    public var screenHeight: CGFloat {
        return UIScreen.main.bounds.height
    }
    let currentBrightness = Int(UIScreen.main.brightness * 100)
    let langStr = Locale.current.languageCode
    let countryCode = NSLocale.current.regionCode
    let screenSize = UIScreen.main.bounds.size
    private let locationManager = CLLocationManager()
    
    // Native Bounds - Detect Screen size in Pixels.
    let nWidth = UIScreen.main.nativeBounds.width
    let nHeight = UIScreen.main.nativeBounds.height
    var mainWindow:UIWindow?
    
    static let shared = W3DartVC()
    @objc public var enable = false {
        didSet {
            //If not enable, enable it.
            if enable == true{
                DispatchQueue.main.async {
                    self.sharedData()
                }
                print("Enabled")
            } else if enable == false{
                print("Disabled")
            }
        }
    }
    
    var bubble: BubbleControl!
    var tblCaptured = UITableView()
    var tblHeight = NSLayoutConstraint()
    var capturedAry = [Captured]()
    var timer: Timer?
    var totalTime = 0
    var vc = UIViewController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        self.sharedData()
    }
    
    func sharedData(){
        let appInfo = self.getAppInfo()
        self.capturedAry = [Captured(paramKey: "Device Name", paramValue: UIDevice.modelName), Captured(paramKey: "CPU Name", paramValue: UIDevice.current.getCPUName()), Captured(paramKey: "CPU Speed", paramValue: UIDevice.current.getCPUSpeed()), Captured(paramKey: "System Version", paramValue: UIDevice.current.systemVersion), Captured(paramKey: "App version", paramValue: appInfo), Captured(paramKey: "Device Type", paramValue: UIDevice.current.model), Captured(paramKey: "Battery Percentaeg", paramValue: self.getBatteryPercentage()), Captured(paramKey: "Time", paramValue: self.printTimestamp()), Captured(paramKey: "Screen Width", paramValue: "\(screenWidth)"), Captured(paramKey: "Screen Height", paramValue: "\(screenHeight)"), Captured(paramKey: "Brightness", paramValue: "\(currentBrightness)"), Captured(paramKey: "Mobile Network", paramValue: self.getConnectionType()), Captured(paramKey: "Language", paramValue: langStr ?? ""), Captured(paramKey: "Country", paramValue: countryCode ?? ""), Captured(paramKey: "Orientation", paramValue: self.rotated())]
        
        self.tblCaptured.delegate = self
        self.tblCaptured.dataSource = self
        tblCaptured.register(CapturedCell.self, forCellReuseIdentifier: "CapturedCell")
        let vc = self.top
        print("Current View Controller = \(vc ?? self)")
        let topvc = self.mainWindow?.visibleViewController
        currentVC = topvc!
        print("Current View Controller 2 = \(topvc ?? self)")
        self.startTimer()
        self.setupBubble()
        print("Run")
    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.tblHeight.constant = tblCaptured.contentSize.height
    }
    private func startTimer() {
        self.totalTime = 0
        self.timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updateTimer), userInfo: nil, repeats: true)
    }
    @objc func updateTimer() {
        print(self.totalTime)
        let time = self.timeFormatted(self.totalTime) // will show timer
        print("Duration = \(time)")
        if totalTime != nil {
            totalTime += 1  // decrease counter timer
        } else {
            if let timer = self.timer {
                timer.invalidate()
                self.timer = nil
            }
        }
    }
    func timeFormatted(_ totalSeconds: Int) -> String {
        let seconds: Int = totalSeconds % 60
        let minutes: Int = (totalSeconds / 60) % 60
        let hours: Int = totalSeconds / 3600
        return String(format: "%02d:%02d:%02d", hours,minutes, seconds)
    }
    
    func getManufactureName(name:String) -> String{
        return name
    }
   
    func getAppInfo()->String {
        let dictionary = Bundle.main.infoDictionary!
        let version = dictionary["CFBundleShortVersionString"] as! String
        let build = dictionary["CFBundleVersion"] as! String
        return version + "(" + build + ")"
    }
    
    func getBatteryPercentage()->String{
        UIDevice.current.isBatteryMonitoringEnabled = true
        print("BatteryLevel = \(batteryLevel * 100)")
        return "\(batteryLevel * 100)"
        switch batteryState {
        case .unplugged:
            print("The battery state for the device cannot be determined.")
            return "cannot be determined."
        case .unknown:
            print("The device is not plugged into power; the battery is discharging")
            return "the battery is discharging"
        case .charging:
            print("The device is plugged into power and the battery is less than 100% charged.")
            return "less than 100% charged."
        case .full:
            print("The device is plugged into power and the battery is 100% charged.")
            return "100% charged."
        }
    }
    func printTimestamp()->String {
        let dateFormatter : DateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM-dd-yyyy HH:mm:ss"
        let date = Date()
        let dateString = dateFormatter.string(from: date)
        let interval = date.timeIntervalSince1970
//        self.time = dateString
        print("Current Time Date = \(interval)")
        print("Current Time Date = \(dateString)")
        return dateString
    }
    func getConnectionType() -> String {
            guard let reachability = SCNetworkReachabilityCreateWithName(kCFAllocatorDefault, "www.google.com") else {
                return "NO INTERNET"
            }

            var flags = SCNetworkReachabilityFlags()
            SCNetworkReachabilityGetFlags(reachability, &flags)

            let isReachable = flags.contains(.reachable)
            let isWWAN = flags.contains(.isWWAN)

            if isReachable {
                if isWWAN {
                    let networkInfo = CTTelephonyNetworkInfo()
                    let carrierType = networkInfo.serviceCurrentRadioAccessTechnology

                    guard let carrierTypeName = carrierType?.first?.value else {
                        return "UNKNOWN"
                    }

                    switch carrierTypeName {
                    case CTRadioAccessTechnologyGPRS, CTRadioAccessTechnologyEdge, CTRadioAccessTechnologyCDMA1x:
                        return "2G Mobile Net"
                    case CTRadioAccessTechnologyLTE:
                        return "4G Mobile Net"
                    default:
                        return "3G Mobile Net"
                    }
                } else {
                    return "WIFI"
                }
            } else {
                return "NO INTERNET"
            }
        }
    func rotated()->String {
        if UIDevice.current.orientation.isLandscape {
            print("Orientation = Landscape")
            return "Landscape"
        } else {
            print("Orientation = Portrait")
            return "Portrait"
        }
    }
    func biometricType() -> BiometricType {
        let authContext = LAContext()
        if #available(iOS 11, *) {
            let _ = authContext.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
            switch(authContext.biometryType) {
            case .none:
                return .none
            case .touchID:
                return .touch
            case .faceID:
                return .face
             default:
                return .none
            }
        } else {
            return authContext.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil) ? .touch : .none
        }
    }

    enum BiometricType {
        case none
        case touch
        case face
    }
    
    @available(iOS 14.0, *)
    func getLocationAccess(){
        if CLLocationManager.locationServicesEnabled() {
            switch locationManager.authorizationStatus {
                case .notDetermined, .restricted, .denied:
                    print("No access")
                case .authorizedAlways, .authorizedWhenInUse:
                    print("Access")
                @unknown default:
                    break
            }
        } else {
            print("Location services are not enabled")
        }
    }
    
    func setupBubble () {
        let win = self.mainWindow!
        bubble = BubbleControl (size: CGSize(width: 80, height: 80))
//        bubble.mainWindow = win
//        bubble.vc = self.vc
        bubble.image = UIImage(named: "logo.png")
        
        bubble.didNavigationBarButtonPressed = {
            print("pressed in nav bar")
            self.bubble!.popFromNavBar()
        }
        
        bubble.setOpenAnimation = { content, background in
            self.bubble.contentView!.bottom = win.bottom
            if (self.bubble.center.x > win.center.x) {
                self.bubble.contentView!.left = win.right
                self.bubble.contentView!.spring(animations: { () -> Void in
                    self.bubble.contentView!.right = win.right
                }, completion: nil)
            } else {
                self.bubble.contentView!.right = win.left
                self.bubble.contentView!.spring(animations: { () -> Void in
                    self.bubble.contentView!.left = win.left
                }, completion: nil)
            }
        }
        self.bugViewConstrait()
    }
    
    func bugViewConstrait(){
        let win = self.mainWindow!
        //let min: CGFloat = 50
//        let max: CGFloat = win.h - 250
        //let randH = min + CGFloat(random()%Int(max-min))
        
        let v = UIView (frame: CGRect (x: 0, y: 0, width: win.w, height: win.h))
        v.backgroundColor = UIColor.white
        
        let btnClose = UIButton()
        btnClose.setImage(UIImage(named: "x") , for: .normal)
        btnClose.isUserInteractionEnabled = true
        btnClose.isEnabled = true
        btnClose.addTarget(self, action: #selector(onClickClose), for: .touchUpInside)
        
        let imgLogo = UIImageView()
        imgLogo.image = UIImage(named: "Logos")
        
        let scrollView = UIScrollView()
        scrollView.isScrollEnabled = true
        let scrollSubView = UIView()
//        scrollSubView.backgroundColor = .red
        
        let lblMainTitle = UILabel()
        lblMainTitle.textColor = .black
        lblMainTitle.font = UIFont(name: "Roboto-Bold", size: 24)
        lblMainTitle.text = "Report your Bug"
        
        let btnSubmit = UIButton()
        btnSubmit.backgroundColor = hexStringToUIColor(hex: "#F72360")
        btnSubmit.setTitle("Submit", for: .normal)
        btnSubmit.titleLabel?.font = UIFont(name: "Roboto-Regular", size: 14)
        btnSubmit.layer.cornerRadius = 4
        btnClose.isUserInteractionEnabled = true
        btnClose.isEnabled = true
        
        let lblTitle = UILabel()
        lblTitle.textColor = hexStringToUIColor(hex: "#989898")
        lblTitle.font = UIFont(name: "Roboto-Regular", size: 14)
        lblTitle.text = "Title"
        
        let txtTitle = UITextField()
        txtTitle.backgroundColor = hexStringToUIColor(hex: "#F6F6F6")
        txtTitle.borderStyle = .none
        txtTitle.layer.cornerRadius = 6
        
        let lblDes = UILabel()
        lblDes.textColor = hexStringToUIColor(hex: "#989898")
        lblDes.font = UIFont(name: "Roboto-Regular", size: 14)
        lblDes.text = "Description"
        
        let txtDes = UITextView()
        txtDes.backgroundColor = hexStringToUIColor(hex: "#F6F6F6")
        txtDes.layer.cornerRadius = 6
        
        let lblCaptured = UILabel()
        lblCaptured.textColor = .black
        lblCaptured.font = UIFont(name: "Roboto-Bold", size: 24)
        lblCaptured.text = "Captured Parameters"
        
        let imgSS = UIImageView()
        self.setData(imgSS: imgSS, createdSS: currentVC.view.layer.makeSnapshot()!)
        bubble.imgSS = imgSS
        
//        let lblLocDeviceName = UILabel()
//        lblLocDeviceName.textColor = hexStringToUIColor(hex: "#989898")
//        lblLocDeviceName.font = UIFont(name: "Roboto-Regular", size: 10)
//        lblLocDeviceName.text = "Device Name"
//
//        let lblDeviceName = UILabel()
//        lblDeviceName.textColor = .black
//        lblDeviceName.font = UIFont(name: "Roboto-Regular", size: 14)
//        lblDeviceName.text = "iPhone 13 Max Pro"
//
//        let lblLocModelNo = UILabel()
//        lblLocModelNo.textColor = hexStringToUIColor(hex: "#989898")
//        lblLocModelNo.font = UIFont(name: "Roboto-Regular", size: 10)
//        lblLocModelNo.text = "Model No."
//
//        let lblModelNo = UILabel()
//        lblModelNo.textColor = .black
//        lblModelNo.font = UIFont(name: "Roboto-Regular", size: 14)
//        lblModelNo.text = "iPhone 13-SME5264"
//
//        let lblIosVersion = UILabel()
//        lblIosVersion.textColor = .black
//        lblIosVersion.font = UIFont(name: "Roboto-Regular", size: 14)
//        lblIosVersion.text = "iOS 15.10"
//
//        let lblLocIosVersion = UILabel()
//        lblLocIosVersion.textColor = hexStringToUIColor(hex: "#989898")
//        lblLocIosVersion.font = UIFont(name: "Roboto-Regular", size: 10)
//        lblLocIosVersion.text = "iOS Version"
//
//        let lblLocMobileData = UILabel()
//        lblLocMobileData.textColor = hexStringToUIColor(hex: "#989898")
//        lblLocMobileData.font = UIFont(name: "Roboto-Regular", size: 10)
//        lblLocMobileData.text = "Network Connectivity"
//
//        let lblMobileData = UILabel()
//        lblMobileData.textColor = .black
//        lblMobileData.font = UIFont(name: "Roboto-Regular", size: 14)
//        lblMobileData.text = "Mobile Data Connected"
//
//        let lblLocLang = UILabel()
//        lblLocLang.textColor = hexStringToUIColor(hex: "#989898")
//        lblLocLang.font = UIFont(name: "Roboto-Regular", size: 10)
//        lblLocLang.text = "Device Language"
//
//        let lblLang = UILabel()
//        lblLang.textColor = .black
//        lblLang.font = UIFont(name: "Roboto-Regular", size: 14)
//        lblLang.text = "English - en"
//
//        let lblLocOrientation = UILabel()
//        lblLocOrientation.textColor = hexStringToUIColor(hex: "#989898")
//        lblLocOrientation.font = UIFont(name: "Roboto-Regular", size: 10)
//        lblLocOrientation.text = "Orientation"
//
//        let lblOrientation = UILabel()
//        lblOrientation.textColor = .black
//        lblOrientation.font = UIFont(name: "Roboto-Regular", size: 14)
//        lblOrientation.text = "Portrait"
//
//        let lblLocResolution = UILabel()
//        lblLocResolution.textColor = hexStringToUIColor(hex: "#989898")
//        lblLocResolution.font = UIFont(name: "Roboto-Regular", size: 10)
//        lblLocResolution.text = "Device Resolution"
//
//        let lblResolution = UILabel()
//        lblResolution.textColor = .black
//        lblResolution.font = UIFont(name: "Roboto-Regular", size: 14)
//        lblResolution.text = "1280 x 720"
//
//        let lblLocBrightness = UILabel()
//        lblLocBrightness.textColor = hexStringToUIColor(hex: "#989898")
//        lblLocBrightness.font = UIFont(name: "Roboto-Regular", size: 10)
//        lblLocBrightness.text = "Brightness"
//
//        let lblBrightness = UILabel()
//        lblBrightness.textColor = .black
//        lblBrightness.font = UIFont(name: "Roboto-Regular", size: 14)
//        lblBrightness.text = "32"

        self.tblCaptured.separatorStyle = .none
        self.tblCaptured.isScrollEnabled = false
        let guide = v.safeAreaLayoutGuide
        v.addSubview(btnClose)
//        v.addSubview(imgLogo)
        v.addSubview(scrollView)
        scrollView.addSubview(scrollSubView)
        scrollSubView.addSubview(imgLogo)
        scrollSubView.addSubview(lblMainTitle)
        scrollSubView.addSubview(btnSubmit)
        scrollSubView.addSubview(lblTitle)
        scrollSubView.addSubview(txtTitle)
        scrollSubView.addSubview(lblDes)
        scrollSubView.addSubview(txtDes)
        scrollSubView.addSubview(lblCaptured)
        scrollSubView.addSubview(imgSS)
//        scrollSubView.addSubview(lblLocDeviceName)
//        scrollSubView.addSubview(lblDeviceName)
//        scrollSubView.addSubview(lblLocModelNo)
//        scrollSubView.addSubview(lblModelNo)
//        scrollSubView.addSubview(lblLocIosVersion)
//        scrollSubView.addSubview(lblIosVersion)
//        scrollSubView.addSubview(lblLocMobileData)
//        scrollSubView.addSubview(lblMobileData)
//        scrollSubView.addSubview(lblLocLang)
//        scrollSubView.addSubview(lblLang)
//        scrollSubView.addSubview(lblLocOrientation)
//        scrollSubView.addSubview(lblOrientation)
//        scrollSubView.addSubview(lblLocResolution)
//        scrollSubView.addSubview(lblResolution)
//        scrollSubView.addSubview(lblLocBrightness)
//        scrollSubView.addSubview(lblBrightness)
        scrollSubView.addSubview(tblCaptured)
        
        
        btnClose.translatesAutoresizingMaskIntoConstraints = false
        imgLogo.translatesAutoresizingMaskIntoConstraints = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollSubView.translatesAutoresizingMaskIntoConstraints = false
        lblMainTitle.translatesAutoresizingMaskIntoConstraints = false
        btnSubmit.translatesAutoresizingMaskIntoConstraints = false
        lblTitle.translatesAutoresizingMaskIntoConstraints = false
        txtTitle.translatesAutoresizingMaskIntoConstraints = false
        lblDes.translatesAutoresizingMaskIntoConstraints = false
        txtDes.translatesAutoresizingMaskIntoConstraints = false
        lblCaptured.translatesAutoresizingMaskIntoConstraints = false
        tblCaptured.translatesAutoresizingMaskIntoConstraints = false
        imgSS.translatesAutoresizingMaskIntoConstraints = false
//        lblLocDeviceName.translatesAutoresizingMaskIntoConstraints = false
//        lblDeviceName.translatesAutoresizingMaskIntoConstraints = false
//        lblLocModelNo.translatesAutoresizingMaskIntoConstraints = false
//        lblModelNo.translatesAutoresizingMaskIntoConstraints = false
//        lblLocIosVersion.translatesAutoresizingMaskIntoConstraints = false
//        lblIosVersion.translatesAutoresizingMaskIntoConstraints = false
//        lblLocMobileData.translatesAutoresizingMaskIntoConstraints = false
//        lblMobileData.translatesAutoresizingMaskIntoConstraints = false
//        lblLocLang.translatesAutoresizingMaskIntoConstraints = false
//        lblLang.translatesAutoresizingMaskIntoConstraints = false
//        lblLocOrientation.translatesAutoresizingMaskIntoConstraints = false
//        lblOrientation.translatesAutoresizingMaskIntoConstraints = false
//        lblLocResolution.translatesAutoresizingMaskIntoConstraints = false
//        lblResolution.translatesAutoresizingMaskIntoConstraints = false
//        lblLocBrightness.translatesAutoresizingMaskIntoConstraints = false
//        lblBrightness.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            btnClose.topAnchor.constraint(equalTo: guide.topAnchor, constant: 8),
            btnClose.leadingAnchor.constraint(equalTo: v.leadingAnchor, constant: 16),
            btnClose.widthAnchor.constraint(equalToConstant: 40),
            btnClose.heightAnchor.constraint(equalToConstant: 40),
            
            scrollView.topAnchor.constraint(equalTo: btnClose.bottomAnchor, constant: 8),
            scrollView.leadingAnchor.constraint(equalTo: v.leadingAnchor, constant: 0),
            scrollView.trailingAnchor.constraint(equalTo: v.trailingAnchor, constant: 0),
            scrollView.bottomAnchor.constraint(equalTo: v.bottomAnchor, constant: 0),
            
            scrollSubView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 0),
            scrollSubView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 0),
            scrollSubView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: 0),
            scrollSubView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: 0),
            scrollSubView.widthAnchor.constraint(equalTo: scrollView.widthAnchor, multiplier: 1),
//            scrollSubView.heightAnchor.constraint(equalTo: scrollView.heightAnchor, multiplier: 1),
            imgLogo.topAnchor.constraint(equalTo: scrollSubView.topAnchor, constant: 8),
            imgLogo.leadingAnchor.constraint(equalTo: scrollSubView.leadingAnchor, constant: 16),
            imgLogo.widthAnchor.constraint(equalToConstant: 102),
            imgLogo.heightAnchor.constraint(equalToConstant: 70),
            
            lblMainTitle.topAnchor.constraint(equalTo: imgLogo.bottomAnchor, constant: 20),
            lblMainTitle.leadingAnchor.constraint(equalTo: scrollSubView.leadingAnchor, constant: 20),
            lblMainTitle.trailingAnchor.constraint(equalTo: btnSubmit.leadingAnchor, constant: 8),
            
            btnSubmit.topAnchor.constraint(equalTo: imgLogo.bottomAnchor, constant: 20),
            btnSubmit.trailingAnchor.constraint(equalTo: scrollSubView.trailingAnchor, constant: -16),
            btnSubmit.widthAnchor.constraint(equalToConstant: 85),
            btnSubmit.heightAnchor.constraint(equalToConstant: 40),
            
            imgSS.topAnchor.constraint(equalTo: btnSubmit.bottomAnchor, constant: 20),
            imgSS.leadingAnchor.constraint(equalTo: scrollSubView.leadingAnchor, constant: 70),
            imgSS.trailingAnchor.constraint(equalTo: scrollSubView.trailingAnchor, constant: -70),
            imgSS.heightAnchor.constraint(equalToConstant: 300),
            
            
            lblTitle.topAnchor.constraint(equalTo: imgSS.bottomAnchor, constant: 20),
            lblTitle.leadingAnchor.constraint(equalTo: scrollSubView.leadingAnchor, constant: 20),
            
            txtTitle.topAnchor.constraint(equalTo: lblTitle.bottomAnchor, constant: 2),
            txtTitle.leadingAnchor.constraint(equalTo: scrollSubView.leadingAnchor, constant: 16),
            txtTitle.trailingAnchor.constraint(equalTo: scrollSubView.trailingAnchor, constant: -16),
            txtTitle.heightAnchor.constraint(equalToConstant: 56),
            
            lblDes.topAnchor.constraint(equalTo: txtTitle.bottomAnchor, constant: 16),
            lblDes.leadingAnchor.constraint(equalTo: scrollSubView.leadingAnchor, constant: 20),
            
            txtDes.topAnchor.constraint(equalTo: lblDes.bottomAnchor, constant: 2),
            txtDes.leadingAnchor.constraint(equalTo: scrollSubView.leadingAnchor, constant: 16),
            txtDes.trailingAnchor.constraint(equalTo: scrollSubView.trailingAnchor, constant: -16),
            txtDes.heightAnchor.constraint(equalToConstant: 140),
            
            lblCaptured.topAnchor.constraint(equalTo: txtDes.bottomAnchor, constant: 30),
            lblCaptured.leadingAnchor.constraint(equalTo: scrollSubView.leadingAnchor, constant: 20),
//            lblCaptured.heightAnchor.constraint(equalToConstant: 24),
            
            tblCaptured.topAnchor.constraint(equalTo: lblCaptured.bottomAnchor, constant: 26),
            tblCaptured.leadingAnchor.constraint(equalTo: scrollSubView.leadingAnchor, constant: 30),
            tblCaptured.trailingAnchor.constraint(equalTo: scrollSubView.trailingAnchor, constant: 30),
            tblCaptured.bottomAnchor.constraint(equalTo: scrollSubView.bottomAnchor, constant: 16),
            tblCaptured.heightAnchor.constraint(equalToConstant: CGFloat(self.capturedAry.count * 50)),
            
//            lblDeviceName.topAnchor.constraint(equalTo: lblCaptured.bottomAnchor, constant: 26),
//            lblDeviceName.leadingAnchor.constraint(equalTo: scrollSubView.leadingAnchor, constant: 30),
//
//            lblLocDeviceName.topAnchor.constraint(equalTo: lblDeviceName.bottomAnchor, constant: 0),
//            lblLocDeviceName.leadingAnchor.constraint(equalTo: scrollSubView.leadingAnchor, constant: 30),
//
//            lblModelNo.topAnchor.constraint(equalTo: lblLocDeviceName.bottomAnchor, constant: 16),
//            lblModelNo.leadingAnchor.constraint(equalTo: scrollSubView.leadingAnchor, constant: 30),
//
//            lblLocModelNo.topAnchor.constraint(equalTo: lblModelNo.bottomAnchor, constant: 0),
//            lblLocModelNo.leadingAnchor.constraint(equalTo: scrollSubView.leadingAnchor, constant: 30),
//
//            lblIosVersion.topAnchor.constraint(equalTo: lblLocModelNo.bottomAnchor, constant: 16),
//            lblIosVersion.leadingAnchor.constraint(equalTo: scrollSubView.leadingAnchor, constant: 30),
//
//            lblLocIosVersion.topAnchor.constraint(equalTo: lblIosVersion.bottomAnchor, constant: 0),
//            lblLocIosVersion.leadingAnchor.constraint(equalTo: scrollSubView.leadingAnchor, constant: 30),
//
//            lblMobileData.topAnchor.constraint(equalTo: lblLocIosVersion.bottomAnchor, constant: 16),
//            lblMobileData.leadingAnchor.constraint(equalTo: scrollSubView.leadingAnchor, constant: 30),
//
//            lblLocMobileData.topAnchor.constraint(equalTo: lblMobileData.bottomAnchor, constant: 0),
//            lblLocMobileData.leadingAnchor.constraint(equalTo: scrollSubView.leadingAnchor, constant: 30),
//
//            lblLang.topAnchor.constraint(equalTo: lblLocMobileData.bottomAnchor, constant: 16),
//            lblLang.leadingAnchor.constraint(equalTo: scrollSubView.leadingAnchor, constant: 30),
//
//            lblLocLang.topAnchor.constraint(equalTo: lblLang.bottomAnchor, constant: 0),
//            lblLocLang.leadingAnchor.constraint(equalTo: scrollSubView.leadingAnchor, constant: 30),
//
//            lblOrientation.topAnchor.constraint(equalTo: lblLocLang.bottomAnchor, constant: 16),
//            lblOrientation.leadingAnchor.constraint(equalTo: scrollSubView.leadingAnchor, constant: 30),
//
//            lblLocOrientation.topAnchor.constraint(equalTo: lblOrientation.bottomAnchor, constant: 0),
//            lblLocOrientation.leadingAnchor.constraint(equalTo: scrollSubView.leadingAnchor, constant: 30),
//
//            lblResolution.topAnchor.constraint(equalTo: lblLocOrientation.bottomAnchor, constant: 16),
//            lblResolution.leadingAnchor.constraint(equalTo: scrollSubView.leadingAnchor, constant: 30),
//
//            lblLocResolution.topAnchor.constraint(equalTo: lblResolution.bottomAnchor, constant: 0),
//            lblLocResolution.leadingAnchor.constraint(equalTo: scrollSubView.leadingAnchor, constant: 30),
//
//            lblBrightness.topAnchor.constraint(equalTo: lblLocResolution.bottomAnchor, constant: 16),
//            lblBrightness.leadingAnchor.constraint(equalTo: scrollSubView.leadingAnchor, constant: 30),
//
//            lblLocBrightness.topAnchor.constraint(equalTo: lblBrightness.bottomAnchor, constant: 0),
//            lblLocBrightness.leadingAnchor.constraint(equalTo: scrollSubView.leadingAnchor, constant: 30),
//            lblLocBrightness.bottomAnchor.constraint(equalTo: scrollSubView.bottomAnchor, constant: -16),
            
        ])
        bubble.contentView = v
        win.addSubview(bubble)
    }

    func setData(imgSS:UIImageView, createdSS:UIImage){
        imgSS.image = createdSS
        imgSS.contentMode = .scaleAspectFill
        imgSS.clipsToBounds = true
    }
    
    @objc func onClickClose(_ sender:UIButton){
        print("close")
        self.bubble.closeContentView()
    }
    // MARK: Animation
    
    func animateBubbleIcon (_ on: Bool) {
        let shapeLayer = self.bubble.imageView!.layer.sublayers![0] as! CAShapeLayer
        let from = on ? self.basketBezier().cgPath: self.arrowBezier().cgPath
        let to = on ? self.arrowBezier().cgPath: self.basketBezier().cgPath
        
        let anim = CABasicAnimation (keyPath: "path")
        anim.fromValue = from
        anim.toValue = to
        anim.duration = 0.5
        anim.fillMode = CAMediaTimingFillMode.forwards
        anim.isRemovedOnCompletion = false
        
        shapeLayer.add (anim, forKey:"bezier")
    }
    func arrowBezier () -> UIBezierPath {
        //// PaintCode Trial Version
        //// www.paintcodeapp.com
        
        let color0 = UIColor(red: 0.000, green: 0.000, blue: 0.000, alpha: 1.000)
        
        let bezier2Path = UIBezierPath()
        bezier2Path.move(to: CGPoint(x: 21.22, y: 2.89))
        bezier2Path.addCurve(to: CGPoint(x: 19.87, y: 6.72), controlPoint1: CGPoint(x: 21.22, y: 6.12), controlPoint2: CGPoint(x: 20.99, y: 6.72))
        bezier2Path.addCurve(to: CGPoint(x: 14.54, y: 7.92), controlPoint1: CGPoint(x: 19.12, y: 6.72), controlPoint2: CGPoint(x: 16.72, y: 7.24))
        bezier2Path.addCurve(to: CGPoint(x: 0.44, y: 25.84), controlPoint1: CGPoint(x: 7.27, y: 10.09), controlPoint2: CGPoint(x: 1.64, y: 17.14))
        bezier2Path.addCurve(to: CGPoint(x: 2.39, y: 26.97), controlPoint1: CGPoint(x: -0.08, y: 29.74), controlPoint2: CGPoint(x: 1.12, y: 30.49))
        bezier2Path.addCurve(to: CGPoint(x: 17.62, y: 16.09), controlPoint1: CGPoint(x: 4.34, y: 21.19), controlPoint2: CGPoint(x: 10.12, y: 17.14))
        bezier2Path.addLine(to: CGPoint(x: 21.14, y: 15.64))
        bezier2Path.addLine(to: CGPoint(x: 21.37, y: 19.47))
        bezier2Path.addLine(to: CGPoint(x: 21.59, y: 23.29))
        bezier2Path.addLine(to: CGPoint(x: 29.09, y: 17.52))
        bezier2Path.addCurve(to: CGPoint(x: 36.59, y: 11.22), controlPoint1: CGPoint(x: 33.22, y: 14.37), controlPoint2: CGPoint(x: 36.59, y: 11.52))
        bezier2Path.addCurve(to: CGPoint(x: 22.12, y: -0.33), controlPoint1: CGPoint(x: 36.59, y: 10.69), controlPoint2: CGPoint(x: 24.89, y: 1.39))
        bezier2Path.addCurve(to: CGPoint(x: 21.22, y: 2.89), controlPoint1: CGPoint(x: 21.44, y: -0.71), controlPoint2: CGPoint(x: 21.22, y: 0.19))
        bezier2Path.close()
        bezier2Path.move(to: CGPoint(x: 31.87, y: 8.82))
        bezier2Path.addCurve(to: CGPoint(x: 34.64, y: 11.22), controlPoint1: CGPoint(x: 33.44, y: 9.94), controlPoint2: CGPoint(x: 34.72, y: 10.99))
        bezier2Path.addCurve(to: CGPoint(x: 28.87, y: 15.87), controlPoint1: CGPoint(x: 34.64, y: 11.44), controlPoint2: CGPoint(x: 32.09, y: 13.54))
        bezier2Path.addLine(to: CGPoint(x: 23.09, y: 20.14))
        bezier2Path.addLine(to: CGPoint(x: 22.87, y: 17.07))
        bezier2Path.addLine(to: CGPoint(x: 22.64, y: 13.99))
        bezier2Path.addLine(to: CGPoint(x: 18.97, y: 14.44))
        bezier2Path.addCurve(to: CGPoint(x: 6.22, y: 19.24), controlPoint1: CGPoint(x: 13.04, y: 15.12), controlPoint2: CGPoint(x: 9.44, y: 16.54))
        bezier2Path.addCurve(to: CGPoint(x: 5.09, y: 16.84), controlPoint1: CGPoint(x: 2.77, y: 22.24), controlPoint2: CGPoint(x: 2.39, y: 21.49))
        bezier2Path.addCurve(to: CGPoint(x: 20.69, y: 8.22), controlPoint1: CGPoint(x: 8.09, y: 11.82), controlPoint2: CGPoint(x: 14.54, y: 8.22))
        bezier2Path.addCurve(to: CGPoint(x: 22.72, y: 5.14), controlPoint1: CGPoint(x: 22.57, y: 8.22), controlPoint2: CGPoint(x: 22.72, y: 7.99))
        bezier2Path.addLine(to: CGPoint(x: 22.72, y: 2.07))
        bezier2Path.addLine(to: CGPoint(x: 25.94, y: 4.47))
        bezier2Path.addCurve(to: CGPoint(x: 31.87, y: 8.82), controlPoint1: CGPoint(x: 27.67, y: 5.74), controlPoint2: CGPoint(x: 30.37, y: 7.77))
        bezier2Path.close()
        bezier2Path.miterLimit = 4;
        
        color0.setFill()
        bezier2Path.fill()
        return bezier2Path
    }
    func basketBezier () -> UIBezierPath {
        //// PaintCode Trial Version
        //// www.paintcodeapp.com
        
        let color0 = UIColor(red: 0.000, green: 0.000, blue: 0.000, alpha: 1.000)
        
        let bezier2Path = UIBezierPath()
        bezier2Path.move(to: CGPoint(x: 0.86, y: 0.36))
        bezier2Path.addCurve(to: CGPoint(x: 3.41, y: 6.21), controlPoint1: CGPoint(x: -0.27, y: 1.41), controlPoint2: CGPoint(x: 0.48, y: 2.98))
        bezier2Path.addLine(to: CGPoint(x: 6.41, y: 9.51))
        bezier2Path.addLine(to: CGPoint(x: 3.18, y: 9.73))
        bezier2Path.addCurve(to: CGPoint(x: -0.27, y: 12.96), controlPoint1: CGPoint(x: 0.03, y: 9.96), controlPoint2: CGPoint(x: -0.04, y: 10.03))
        bezier2Path.addCurve(to: CGPoint(x: 0.48, y: 16.71), controlPoint1: CGPoint(x: -0.42, y: 14.83), controlPoint2: CGPoint(x: -0.12, y: 16.18))
        bezier2Path.addCurve(to: CGPoint(x: 3.26, y: 23.46), controlPoint1: CGPoint(x: 1.08, y: 17.08), controlPoint2: CGPoint(x: 2.28, y: 20.16))
        bezier2Path.addCurve(to: CGPoint(x: 18.33, y: 32.08), controlPoint1: CGPoint(x: 6.03, y: 32.91), controlPoint2: CGPoint(x: 4.61, y: 32.08))
        bezier2Path.addCurve(to: CGPoint(x: 33.41, y: 23.46), controlPoint1: CGPoint(x: 32.06, y: 32.08), controlPoint2: CGPoint(x: 30.63, y: 32.91))
        bezier2Path.addCurve(to: CGPoint(x: 36.18, y: 16.71), controlPoint1: CGPoint(x: 34.38, y: 20.16), controlPoint2: CGPoint(x: 35.58, y: 17.08))
        bezier2Path.addCurve(to: CGPoint(x: 36.93, y: 12.96), controlPoint1: CGPoint(x: 36.78, y: 16.18), controlPoint2: CGPoint(x: 37.08, y: 14.83))
        bezier2Path.addCurve(to: CGPoint(x: 33.48, y: 9.73), controlPoint1: CGPoint(x: 36.71, y: 10.03), controlPoint2: CGPoint(x: 36.63, y: 9.96))
        bezier2Path.addLine(to: CGPoint(x: 30.26, y: 9.51))
        bezier2Path.addLine(to: CGPoint(x: 33.33, y: 6.13))
        bezier2Path.addCurve(to: CGPoint(x: 36.18, y: 1.48), controlPoint1: CGPoint(x: 35.06, y: 4.26), controlPoint2: CGPoint(x: 36.33, y: 2.16))
        bezier2Path.addCurve(to: CGPoint(x: 28.23, y: 4.63), controlPoint1: CGPoint(x: 35.66, y: -1.22), controlPoint2: CGPoint(x: 33.26, y: -0.24))
        bezier2Path.addLine(to: CGPoint(x: 23.06, y: 9.58))
        bezier2Path.addLine(to: CGPoint(x: 18.33, y: 9.58))
        bezier2Path.addLine(to: CGPoint(x: 13.61, y: 9.58))
        bezier2Path.addLine(to: CGPoint(x: 8.51, y: 4.71))
        bezier2Path.addCurve(to: CGPoint(x: 0.86, y: 0.36), controlPoint1: CGPoint(x: 3.78, y: 0.13), controlPoint2: CGPoint(x: 2.06, y: -0.84))
        bezier2Path.close()
        bezier2Path.move(to: CGPoint(x: 10.08, y: 12.66))
        bezier2Path.addCurve(to: CGPoint(x: 14.58, y: 12.21), controlPoint1: CGPoint(x: 12.33, y: 14.38), controlPoint2: CGPoint(x: 14.58, y: 14.16))
        bezier2Path.addCurve(to: CGPoint(x: 18.33, y: 11.08), controlPoint1: CGPoint(x: 14.58, y: 11.38), controlPoint2: CGPoint(x: 15.48, y: 11.08))
        bezier2Path.addCurve(to: CGPoint(x: 22.08, y: 12.21), controlPoint1: CGPoint(x: 21.18, y: 11.08), controlPoint2: CGPoint(x: 22.08, y: 11.38))
        bezier2Path.addCurve(to: CGPoint(x: 26.58, y: 12.66), controlPoint1: CGPoint(x: 22.08, y: 14.16), controlPoint2: CGPoint(x: 24.33, y: 14.38))
        bezier2Path.addCurve(to: CGPoint(x: 32.21, y: 11.08), controlPoint1: CGPoint(x: 28.08, y: 11.61), controlPoint2: CGPoint(x: 29.88, y: 11.08))
        bezier2Path.addCurve(to: CGPoint(x: 35.58, y: 13.33), controlPoint1: CGPoint(x: 35.43, y: 11.08), controlPoint2: CGPoint(x: 35.58, y: 11.16))
        bezier2Path.addLine(to: CGPoint(x: 35.58, y: 15.58))
        bezier2Path.addLine(to: CGPoint(x: 18.33, y: 15.58))
        bezier2Path.addLine(to: CGPoint(x: 1.08, y: 15.58))
        bezier2Path.addLine(to: CGPoint(x: 1.08, y: 13.33))
        bezier2Path.addCurve(to: CGPoint(x: 4.46, y: 11.08), controlPoint1: CGPoint(x: 1.08, y: 11.16), controlPoint2: CGPoint(x: 1.23, y: 11.08))
        bezier2Path.addCurve(to: CGPoint(x: 10.08, y: 12.66), controlPoint1: CGPoint(x: 6.78, y: 11.08), controlPoint2: CGPoint(x: 8.58, y: 11.61))
        bezier2Path.close()
        bezier2Path.move(to: CGPoint(x: 11.21, y: 22.86))
        bezier2Path.addCurve(to: CGPoint(x: 12.71, y: 28.71), controlPoint1: CGPoint(x: 11.21, y: 28.18), controlPoint2: CGPoint(x: 11.36, y: 28.71))
        bezier2Path.addCurve(to: CGPoint(x: 14.43, y: 22.86), controlPoint1: CGPoint(x: 14.06, y: 28.71), controlPoint2: CGPoint(x: 14.21, y: 28.11))
        bezier2Path.addCurve(to: CGPoint(x: 15.56, y: 17.08), controlPoint1: CGPoint(x: 14.58, y: 18.96), controlPoint2: CGPoint(x: 14.96, y: 17.08))
        bezier2Path.addCurve(to: CGPoint(x: 16.23, y: 21.21), controlPoint1: CGPoint(x: 16.16, y: 17.08), controlPoint2: CGPoint(x: 16.38, y: 18.36))
        bezier2Path.addCurve(to: CGPoint(x: 18.56, y: 28.93), controlPoint1: CGPoint(x: 15.86, y: 27.13), controlPoint2: CGPoint(x: 16.46, y: 29.23))
        bezier2Path.addCurve(to: CGPoint(x: 20.21, y: 22.86), controlPoint1: CGPoint(x: 20.13, y: 28.71), controlPoint2: CGPoint(x: 20.21, y: 28.33))
        bezier2Path.addCurve(to: CGPoint(x: 21.11, y: 17.08), controlPoint1: CGPoint(x: 20.21, y: 18.88), controlPoint2: CGPoint(x: 20.51, y: 17.08))
        bezier2Path.addCurve(to: CGPoint(x: 22.23, y: 22.86), controlPoint1: CGPoint(x: 21.71, y: 17.08), controlPoint2: CGPoint(x: 22.08, y: 18.96))
        bezier2Path.addCurve(to: CGPoint(x: 23.96, y: 28.71), controlPoint1: CGPoint(x: 22.46, y: 28.11), controlPoint2: CGPoint(x: 22.61, y: 28.71))
        bezier2Path.addCurve(to: CGPoint(x: 25.46, y: 22.86), controlPoint1: CGPoint(x: 25.31, y: 28.71), controlPoint2: CGPoint(x: 25.46, y: 28.18))
        bezier2Path.addLine(to: CGPoint(x: 25.46, y: 17.08))
        bezier2Path.addLine(to: CGPoint(x: 29.43, y: 17.08))
        bezier2Path.addCurve(to: CGPoint(x: 31.53, y: 24.58), controlPoint1: CGPoint(x: 33.93, y: 17.08), controlPoint2: CGPoint(x: 33.86, y: 16.78))
        bezier2Path.addLine(to: CGPoint(x: 29.88, y: 30.21))
        bezier2Path.addLine(to: CGPoint(x: 18.33, y: 30.21))
        bezier2Path.addLine(to: CGPoint(x: 6.78, y: 30.21))
        bezier2Path.addLine(to: CGPoint(x: 5.13, y: 24.58))
        bezier2Path.addCurve(to: CGPoint(x: 7.31, y: 17.08), controlPoint1: CGPoint(x: 2.81, y: 16.78), controlPoint2: CGPoint(x: 2.73, y: 17.08))
        bezier2Path.addLine(to: CGPoint(x: 11.21, y: 17.08))
        bezier2Path.addLine(to: CGPoint(x: 11.21, y: 22.86))
        bezier2Path.close()
        bezier2Path.miterLimit = 4;
        
        color0.setFill()
        bezier2Path.fill()
        return bezier2Path
    }
}

extension W3DartVC:UITableViewDelegate,UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.capturedAry.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "CapturedCell", for: indexPath) as? CapturedCell else {
            fatalError()
        }
        cell.lblKey.text = self.capturedAry[indexPath.row].paramKey
        cell.lblValue.text = self.capturedAry[indexPath.row].paramValue
        return cell
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        self.viewDidLayoutSubviews()
    }
}

class CapturedCell: UITableViewCell {
    let lblKey = UILabel()
    let lblValue = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
        
        lblKey.textColor = hexStringToUIColor(hex: "#989898")
        lblKey.font = UIFont(name: "Roboto-Regular", size: 10)
        lblKey.text = "Device Name"
        
        lblValue.textColor = .black
        lblValue.font = UIFont(name: "Roboto-Regular", size: 14)
        lblValue.text = "iPhone 13 Max Pro"
        
        self.contentView.addSubview(lblKey)
        self.contentView.addSubview(lblValue)
        
        lblKey.translatesAutoresizingMaskIntoConstraints = false
        lblValue.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            
            lblValue.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: 8),
            lblValue.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor, constant: 0),
            lblValue.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor, constant: 0),
            lblValue.heightAnchor.constraint(equalToConstant: 20),
            
            lblKey.topAnchor.constraint(equalTo: lblValue.bottomAnchor, constant: 0),
            lblKey.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor, constant: 0),
            lblKey.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor, constant: 0),
//            lblKey.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor, constant: 8)
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    //    override func awakeFromNib() {
//        super.awakeFromNib()
//
//    }
}
