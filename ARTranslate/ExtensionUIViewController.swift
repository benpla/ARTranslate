//
//  ExtensionUIViewController.swift
//  ARTranslate
//
//  Created by Benny Platte on 18.11.19.
//  Copyright © 2019 hsmw. All rights reserved.
//

import Foundation
import UIKit
import ARKit

extension UIViewController {
    func showAlert(title: String,
                   message: String,
                   buttonTitle: String = "OK",
                   showCancel: Bool = false,
                   buttonHandler: ((UIAlertAction) -> Void)? = nil) {
        print(title + "\n" + message)
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: buttonTitle, style: .default, handler: buttonHandler))
        if showCancel {
            alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        }
        DispatchQueue.main.async {
            self.present(alertController, animated: true, completion: nil)
        }
    }

}




extension ViewController {
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard !(anchor is ARPlaneAnchor) else { return }
        guard let anchorname = anchor.name else {return}
        
        // nur meine Anker herausfischen
        guard anchorname.starts(with: self.mySpecialAnchorStartString) else { return }
        print("languageAnchor-Anchor gefunden: \(anchorname)")
        
        // Startstring entfernen, was danach bleibt, ist die Classnumber des Models
        let languageStrings = anchorname.replacingOccurrences(of: self.mySpecialAnchorStartString, with: "")
        
        let ausgeleseneModelClassnumber = Int(languageStrings) ?? 0 //        let splits = languageStrings.components(separatedBy: "---")
//
//        for split in splits {
//            print ("   Language Split: \(split)")
//        }
        
        
        DispatchQueue.main.async {
            // für Debug: Kugel generieren
            //let sphereNode = generateSphereNode()
            //node.addChildNode(sphereNode)
            
            let myNode : SCNNode = self.createNewBubbleParentNode(
                ausgeleseneModelClassnumber,
                language1Text: self.GetOriginalModelClassName(ausgeleseneModelClassnumber),
                language2Text: self.GetTranslatedModelClassName(ausgeleseneModelClassnumber))
            
            self.sceneView.scene.rootNode.addChildNode(myNode)
            myNode.position = node.position
            //node.position = worldCoord
        }
    }
    
    func generateSphereNode() -> SCNNode {
        let sphere = SCNSphere(radius: 0.02)
        let sphereNode = SCNNode()
        sphereNode.position.y += Float(sphere.radius)
        sphereNode.geometry = sphere
        return sphereNode
    }
    
    
    func createNewBubbleParentNode(_ modelClassNumber:Int,  language1Text : String, language2Text:String) -> SCNNode {
        // Warning: Creating 3D Text is susceptible to crashing. To reduce chances of crashing; reduce number of polygons, letters, smoothness, etc.
        
        // TEXT BILLBOARD CONSTRAINT
        let billboardConstraint = SCNBillboardConstraint()
        billboardConstraint.freeAxes = SCNBillboardAxis.Y
        
        // BUBBLE-TEXT
        let bubble = SCNText(string: language1Text, extrusionDepth: CGFloat(ViewController.self.bubbleDepth))
        var font = UIFont(name: "Futura", size: 0.15)
        font = font?.withTraits(traits: .traitBold)
        bubble.font = font
        bubble.alignmentMode = CATextLayerAlignmentMode.center.rawValue
        //bubble.alignmentMode = kCAAlignmentCenter
        bubble.firstMaterial?.diffuse.contents = UIColor.orange
        bubble.firstMaterial?.specular.contents = UIColor.white
        bubble.firstMaterial?.isDoubleSided = true
        // bubble.flatness // setting this too low can cause crashes.
        bubble.chamferRadius = CGFloat(ViewController.bubbleDepth)
        
        // BUBBLE NODE
        let (minBound, maxBound) = bubble.boundingBox
        let bubbleNode = SCNNode(geometry: bubble)
        // Centre Node - to Centre-Bottom point
        bubbleNode.pivot = SCNMatrix4MakeTranslation( (maxBound.x - minBound.x)/2, minBound.y, ViewController.bubbleDepth/2)
        // Reduce default text size
        bubbleNode.scale = SCNVector3Make(0.15, 0.15, 0.15)
        bubbleNode.name = "german"
        
        
        let bubble2 = SCNText(string: language2Text, extrusionDepth: CGFloat(ViewController.bubbleDepth))
        bubble2.font = font
        bubble2.alignmentMode = CATextLayerAlignmentMode.center.rawValue
        //bubble.alignmentMode = kCAAlignmentCenter
        bubble2.firstMaterial?.diffuse.contents = UIColor.red
        bubble2.firstMaterial?.specular.contents = UIColor.white
        bubble2.firstMaterial?.isDoubleSided = true
        // bubble.flatness // setting this too low can cause crashes.
        bubble2.chamferRadius = CGFloat(ViewController.bubbleDepth)
      
        let (minBound2, maxBound2) = bubble2.boundingBox
        let bubbleNode2 = SCNNode(geometry: bubble2)
        // Centre Node - to Centre-Bottom point
        bubbleNode2.pivot = SCNMatrix4MakeTranslation( (maxBound2.x - minBound2.x)/2, minBound2.y + 0.15, ViewController.bubbleDepth/2)
        // Reduce default text size
        bubbleNode2.scale = SCNVector3Make(0.20, 0.20, 0.20)
        bubbleNode2.name = "SchriftTranslatedWithClassnumber_" + String(format: "%d", modelClassNumber)
        
        //bubbleNode.simdPosition += bubbleNode.simdWorldFront * 2
        
        // CENTRE POINT NODE
        let sphere = SCNSphere(radius: 0.005)
        sphere.firstMaterial?.diffuse.contents = UIColor.cyan
        let sphereNode = SCNNode(geometry: sphere)
        
        // BUBBLE PARENT NODE
        let bubbleNodeParent = SCNNode()
        bubbleNodeParent.name = "parentNodeName"
        bubbleNodeParent.addChildNode(bubbleNode)
        bubbleNodeParent.addChildNode(sphereNode)
        bubbleNodeParent.addChildNode(bubbleNode2)
        bubbleNodeParent.constraints = [billboardConstraint]
        
        return bubbleNodeParent
    }
    
    
    func NodesLanguageChange(online:Bool = false) {

        sceneView.scene.rootNode.enumerateChildNodes { (node, stop) in
            // leere Nodes nicht beachten
            guard let nodename = node.name else { return }
            
            // nur meine Nodes herausfischen
            guard nodename.starts(with: "SchriftTranslatedWithClassnumber_") else { return }
            print("Node gefunden: \(nodename)")
            
            // Startstring entfernen, was danach bleibt, ist die Classnumber des Models
            let nodeClassnumberAsString = nodename.replacingOccurrences(of: "SchriftTranslatedWithClassnumber_", with: "")
            
            let ausgeleseneModelClassnumber = Int(nodeClassnumberAsString) ?? 0
            print("  Nummer als Int extrahiert: " + String(format: "%d", ausgeleseneModelClassnumber))
            
            let origText = self.GetOriginalModelClassName(ausgeleseneModelClassnumber)
        
            var newText:String = ""
            if online {
                print ("online translate")
                let translator = ROGoogleTranslate(with: myApiKeys.GoogleTranslateApiKey)
                  
                  var params = ROGoogleTranslateParams()
                  params.source = "en"
                  params.target = "hi"
                  params.text = origText
                  
                  translator.translate(params: params) { (result) in
                        print ("  Result: \(result)")
                        newText = result
                        var theCountDownText: SCNText!
                        theCountDownText = node.geometry as! SCNText
                        theCountDownText.string = newText
                  }
            }
            else {
                newText = self.GetTranslatedModelClassName(ausgeleseneModelClassnumber)
                var theCountDownText: SCNText!
               theCountDownText = node.geometry as! SCNText
               theCountDownText.string = newText
            }
            
        
           
//            if node.childNodes.count > 0 {
//                 node.enumerateChildNodes {  (node, stop) in
//                     print ("    ->" + (node.name ?? "unbekannt"))
//                 }
//             }
                    
         }
    }
}



extension UIFont {
    func bold() -> UIFont {
        let descriptor = self.fontDescriptor.withSymbolicTraits(UIFontDescriptor.SymbolicTraits.traitBold)!
        return UIFont(descriptor: descriptor, size: 0)
    }
}
