//
//  Validator.swift
//  W3DartFramework
//
//  Created by w3nuts on 27/01/22.
//

import Foundation
import UIKit

public struct Validator {
   static func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"

        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }
    public static func sayHallo(window:UIWindow,vc:UIViewController){
        print("Hallo baby. How are you ??")
        W3DartVC.shared.vc = vc
        mainWindow = window
        W3DartVC.shared.mainWindow = window
        W3DartVC.shared.enable = true
    }
}
