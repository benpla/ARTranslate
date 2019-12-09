//
//  UIFontExtension.swift
//  ARTranslate
//
//  Created by Benny Platte on 18.11.19.
//  Copyright © 2019 hsmw. All rights reserved.
//

import Foundation
import UIKit


extension UIFont {
    func withTraits(traits:UIFontDescriptor.SymbolicTraits...) -> UIFont {
        let descriptor = self.fontDescriptor.withSymbolicTraits(UIFontDescriptor.SymbolicTraits(traits))
        return UIFont(descriptor: descriptor!, size: 0)
    }
}
