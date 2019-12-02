//
//  ViewController.swift
//  ARTranslate
//
//  Created by Benny Platte on 18.11.19.
//  Copyright © 2019 hsmw. All rights reserved.
//

import UIKit
import SceneKit
import ARKit
import Vision


class ViewController: UIViewController, ARSCNViewDelegate, UIPickerViewDelegate, UIPickerViewDataSource {
   
    
    @IBOutlet weak var sceneView: ARSCNView!
    static let bubbleDepth : Float = 0.01 // the 'depth' of 3D text
    
    
    @IBOutlet weak var ButtonLoad: UIButton!
    @IBOutlet weak var ButtonSave: UIButton!
    @IBOutlet weak var ButtonUndo: UIButton!
    @IBOutlet weak var Button3: UIButton!
    @IBOutlet weak var Button4: UIButton!
    @IBOutlet weak var Button5: UIButton!
    
    @IBOutlet weak var Textview2: UITextView!
    
    private var _latestPrediction : String = "…" // a variable containing the latest CoreML prediction
    var latestPrediction: String {
      set {
        _latestPrediction = newValue
      }
      get {
        return _latestPrediction
      }
    }
    
    var latestPredictionOtherLanguage:String = "…"
    var latestPredictionModelCLassIndex:Int = 0
    
    func GetOriginalModelClassName(_ modelClassIndex : Int) -> String {
        //String(format: "%2d", predictionNumber)
        // Standardsprache ist englisch
        let langName = inceptionConstants.inceptionLanguage_en[modelClassIndex]
        let kurzName = langName.components(separatedBy: ",")[0]
        return kurzName
    }
    
    func GetTranslatedModelClassName(_ modelClassIndex : Int) -> String {
        //String(format: "%2d", predictionNumber)
        let langName = self.DestinationLanguageList[modelClassIndex]
        let kurzName = langName.components(separatedBy: ",")[0]
        return kurzName
    }
    
    private var _latestPredictionFullname:String = "…"
    var latestPredictionFullname: String {
      set {
        _latestPredictionFullname = newValue
        let predictionNumber:Int = inceptionConstants.inception_numbers[newValue] ?? 0
        self.latestPredictionModelCLassIndex = predictionNumber
        self.latestPredictionOtherLanguage = GetTranslatedModelClassName(predictionNumber)
        
        DispatchQueue.main.async {
            self.Textview2.text = self.latestPredictionOtherLanguage
        }
        }
      get {
        return _latestPredictionFullname
      }
    }
    
    var DestinationLanguageList:[String] = inceptionConstants.inceptionLanguage_de
    private var _languageDest : String = "de"
    var languageDest: String {
      set {
        _languageDest = newValue
        switch newValue {
            case "DEU": DestinationLanguageList = inceptionConstants.inceptionLanguage_de
            case "ENG": DestinationLanguageList = inceptionConstants.inceptionLanguage_en
            case "FRA": DestinationLanguageList = inceptionConstants.inceptionLanguage_fr
            case "SPA": DestinationLanguageList = inceptionConstants.inceptionLanguage_sp
            case "RUS": DestinationLanguageList = inceptionConstants.inceptionLanguage_ru
            case "GRC": DestinationLanguageList = inceptionConstants.inceptionLanguage_gr
            case "POL": DestinationLanguageList = inceptionConstants.inceptionLanguage_pol
            case "ITA": DestinationLanguageList = inceptionConstants.inceptionLanguage_ita
            case "NLD": DestinationLanguageList = inceptionConstants.inceptionLanguage_nla
            case "PRT": DestinationLanguageList = inceptionConstants.inceptionLanguage_por
            default: DestinationLanguageList = inceptionConstants.inceptionLanguage_de
        }
        NodesLanguageChange()
      }
      get {
        return _languageDest
      }
    }
    
 
    
    @IBOutlet weak var LanguagePicker: UIPickerView!
    
    @IBOutlet weak var debugTextView: UITextView!
    var visionRequests = [VNRequest]()
    let dispatchQueueML = DispatchQueue(label: "bp.dispatchqueueml") // A Serial Queue
    
    
    func SetButtonStyle(b:UIButton) {
        b.layer.cornerRadius = 5
        b.layer.borderWidth = 1
        b.layer.borderColor = UIColor(named: "myPickerColor")!.cgColor //UIColor.blue.cgColor // UIColor(named: "myPickerColor") as! CGColor
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        LanguagePicker.delegate = self
        LanguagePicker.dataSource = self
        
        SetButtonStyle(b: ButtonLoad)
        SetButtonStyle(b: ButtonSave)
        SetButtonStyle(b: ButtonUndo)
        SetButtonStyle(b: Button3)
        SetButtonStyle(b: Button4)
        SetButtonStyle(b: Button5)
                   
        // Input the data into the array
        pickerData = ["ENG", "FRE", "GRC", "ITA", "DEU", "NLD", "SPA", "PRT", "RUS", "POL"]
        LanguagePicker.selectRow(4, inComponent: 0, animated: true)
        //self.PickerLanguage.dataSource = pickerData
    }
    
    override func viewDidAppear(_ animated: Bool) {
           super.viewDidAppear(animated)
           
           guard ARWorldTrackingConfiguration.isSupported else {
               fatalError("""
                   ARKit is not available on this device. For apps that require ARKit
                   for core functionality, use the `arkit` key in the key in the
                   `UIRequiredDeviceCapabilities` section of the Info.plist to prevent
                   the app from installing. (If the app can't be installed, this error
                   can't be triggered in a production scenario.)
                   In apps where AR is an additive feature, use `isSupported` to
                   determine whether to show UI for launching AR experiences.
               """) // For details, see https://developer.apple.com/documentation/arkit
           }
        
        self.debugTextView.text = "Hallo"
          // Set the view's delegate
          sceneView.delegate = self
          sceneView.session.run(defaultConfiguration)
          sceneView.debugOptions = [ .showFeaturePoints ]
          
          // Show statistics such as fps and timing information
          sceneView.showsStatistics = true
          // Create a new scene
          let scene = SCNScene()
          // Set the scene to the view
          sceneView.scene = scene
          
          sceneView.autoenablesDefaultLighting = true    // Default Lighting
        
          StartTapRecognizer()
          
          LoadCoreMlModel()
           
           // Prevent the screen from being dimmed after a while as users will likely
           // have long periods of interaction without touching the screen or buttons.
           //UIApplication.shared.isIdleTimerDisabled = true
           
       }
    
    
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        
        // Run session of the view
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
    }
    
    
    override func didReceiveMemoryWarning() {
        // nur weiterleiten
        super.didReceiveMemoryWarning()
    }
    




    // MARK: Language Picker

     var pickerData: [String] = [String]()

    @IBOutlet weak var LanguageChanged: UIPickerView!
    
    
   func numberOfComponents(in pickerView: UIPickerView) -> Int {
      return 1
   }
   
   func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
       return pickerData.count
   }
    
    func pickerView(_ pickerView: UIPickerView,
                    rowHeightForComponent component: Int) -> CGFloat {
        return 50
    }
    


//   func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
//        pickerView.setValue(UIColor.yellow, forKeyPath: "textColor")
//
//     //print (pickerData[row])
//    self.languageDest = pickerData[row]
//    return pickerData[row]
//   }
    
func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
    var pickerLabel: UILabel? = (view as? UILabel)
    if pickerLabel == nil {
        pickerLabel = UILabel()
        pickerLabel?.font = UIFont(name: "Futura", size: 30)!//.bold()
        pickerLabel?.textAlignment = .center
    }
    pickerLabel?.text = pickerData[row]
    pickerLabel?.textColor = UIColor(named: "myPickerColor")
    
    for view in pickerView.subviews {
         if view.frame.size.height < 1 {
             var frame = view.frame
             frame.size.height = 3
             view.frame = frame
             view.backgroundColor = UIColor(named: "myPickerColor") //UIColor.yellow
         }
     }
    

    self.languageDest = pickerData[row]
    return pickerLabel!
}
    
func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {

    guard let pickerLabel = pickerView.view(forRow: row, forComponent: component) as? UILabel else {
        return
    }
    //label.backgroundColor = .orange
    pickerLabel.font = UIFont(name: "Futura", size: 32)!.bold()
    pickerLabel.textColor = UIColor(named: "myPickerColor")
    //pickerLabel.textColor = UIColor(named: "myTextColorLight")
    pickerLabel.textAlignment = .center
}
    
    
    
    
    
    // MARK: - Renderer
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        DispatchQueue.main.async {
            // Do any desired updates to SceneKit here.
        }
    }
    

    override var prefersStatusBarHidden : Bool {
        return true
    }
    
    
    
    // MARK: - Taps on Screen
    
    
    func StartTapRecognizer(){
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.handleTap(gestureRecognize:)))
        view.addGestureRecognizer(tapGesture)
    }
    
    
    
    let mySpecialAnchorStartString = "languageAnchorWithModelClassIndex_"
    
    @objc func handleTap(gestureRecognize: UITapGestureRecognizer) {
        // HIT TEST

        // use Screen Center or touchPoint?
        //let screenCenter : CGPoint = CGPoint(x: self.sceneView.bounds.midX, y: self.sceneView.bounds.midY)
        let touchPoint:CGPoint = gestureRecognize.location(in: gestureRecognize.view)
        
        let arHitTestResults : [ARHitTestResult] = sceneView.hitTest(touchPoint, types: [.featurePoint]) // Alternatively, we could use '.existingPlaneUsingExtent' for more grounded hit-test-points.
        
        if let closestResult = arHitTestResults.first {
            // Get Coordinates of HitTest
            let transform : matrix_float4x4 = closestResult.worldTransform
            let worldCoord : SCNVector3 = SCNVector3Make(transform.columns.3.x, transform.columns.3.y, transform.columns.3.z)
            
            // Create 3D Text
            //let textOtherLanguage = latestPredictionOtherLanguage
            let anchorName = mySpecialAnchorStartString + String(format: "%d", self.latestPredictionModelCLassIndex)
            let anchor = ARAnchor(name: anchorName, transform: transform)
            sceneView.session.add(anchor: anchor)
                       
        }
    }
    
    
    
    
    

    
    
    // MARK: PrintSCNNodes
    
    @IBAction func PrintSCNNodes(_ sender: Any) {
        //sceneView.scene.rootNode.enumerateChildNodes { (node, stop) in
        //node.removeFromParentNode() }
       PrintSCNNodesToConsole()
    }
    
    
    func PrintSCNNodesToConsole(){
        print ("Nodes: \(sceneView.scene.rootNode.childNodes.count)")
        
        sceneView.scene.rootNode.enumerateChildNodes {   (node, stop) in
            print ("  " + (node.name ?? "unbekannt") )
            
            if node.childNodes.count > 0 {
                node.enumerateChildNodes {  (node, stop) in
                    print ("    ->" + (node.name ?? "unbekannt"))
                }
            }
                   
        }
    }
    
    
   
    func session(_ session: ARSession, didAdd node: SCNNode, for anchor: ARAnchor) {
        //guard anchor.name == "objekt" else { return }
       // print("objekt-Anchor überrannt!")
    }
    
    
    
    // MARK: Translate Online
    
    @IBAction func TranslateOnline(_ sender: UIButton) {
        NodesLanguageChange(online: true)
    }
    
    
    // MARK: - CoreML Handling
    func LoadCoreMlModel(){
         // Set up Vision Model
         // can be other models from https://developer.apple.com/machine-learning/
         // Models must be part of Target
         guard let myModel = try? VNCoreMLModel(for: Inceptionv3().model) else {
             fatalError("Could not load model.")
         }
         
         // Vision-CoreML Request setup
         let classificationRequest = VNCoreMLRequest(model: myModel, completionHandler: classificationCompleteHandler)
         
         // Crop from centre of images and scale to correct size.
         classificationRequest.imageCropAndScaleOption = VNImageCropAndScaleOption.centerCrop
         visionRequests = [classificationRequest]
         
        
        
         StartCoreMLUpdateLoop()
     }
     
    
    func PrintAllModelClasses(myModel:VNCoreMLModel) {
        var largest = 0
        for (kind) in myModel.inputImageFeatureName {
            print("kind: \(kind)")
        }
    }
    
    func StartCoreMLUpdateLoop() {
        // run CoreML forever
        dispatchQueueML.async {
            self.updateCoreML()
            self.StartCoreMLUpdateLoop()
        }
    }
    
    
    // MARK: Classification Complete
    
    func classificationCompleteHandler(request: VNRequest, error: Error?) {
        // Catch Errors
        if error != nil {
            print("Error: " + (error?.localizedDescription)!)
            return
        }
        guard let observations = request.results else {
            print("No results")
            return
        }
        
        //let latestObservation; as? VNClassificationObservation = observations[0]
        //print (latestObservation.confidence)
        // Get Classifications: first 3 results
        let classifications = observations[0...3]
            .compactMap({ $0 as? VNClassificationObservation })
            .map({ "\($0.identifier) \(String(format:"- %.0f %", $0.confidence*100))" })
            .joined(separator: "\n")
        
        //identifier der am höchsten bewerteten Prediction trimmen und als kompletten Namen speichern
        self.latestPredictionFullname = (observations[0] as? VNClassificationObservation)!.identifier.trimmingCharacters(in: .whitespacesAndNewlines)
        
        DispatchQueue.main.async {
            // Print Classifications
            //print(classifications)
            //print("--")
            
            // Display Debug Text on screen
            var debugText:String = ""
            debugText += classifications
            self.debugTextView.text = debugText
            
            
            // Store the latest prediction
            var objectName:String = "…"
            objectName = classifications.components(separatedBy: "-")[0]
            objectName = objectName.components(separatedBy: ",")[0]
            self.latestPrediction = objectName
            
        }
    }
    
    func updateCoreML() {
        ///////////////////////////
        // Get Camera Image as RGB
        let pixbuff : CVPixelBuffer? = (sceneView.session.currentFrame?.capturedImage)
        if pixbuff == nil { return }
        let ciImage = CIImage(cvPixelBuffer: pixbuff!)
        // Note: Not entirely sure if the ciImage is being interpreted as RGB, but for now it works with the Inception model.
        // Note2: Also uncertain if the pixelBuffer should be rotated before handing off to Vision (VNImageRequestHandler) - regardless, for now, it still works well with the Inception model.
        
        ///////////////////////////
        // Prepare CoreML/Vision Request
        let imageRequestHandler = VNImageRequestHandler(ciImage: ciImage, options: [:])
        // let imageRequestHandler = VNImageRequestHandler(cgImage: cgImage!, orientation: myOrientation, options: [:]) // Alternatively; we can convert the above to an RGB CGImage and use that. Also UIInterfaceOrientation can inform orientation values.
        
        ///////////////////////////
        // Run Image Request
        do {
            try imageRequestHandler.perform(self.visionRequests)
        } catch {
            print(error)
        }
        
    }
    
/*
    // Override to create and configure nodes for anchors added to the view's session.
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        let node = SCNNode()
     
        return node
    }
*/
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
    
    
    
    
    
    
    // MARK: World Map Handling
    
    var CsvWriter = FileHandlerClass(filename: "myFile.armap")
    
    var mapSaveURL: URL = {
        do {
            return try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appendingPathComponent("ART", isDirectory: true).appendingPathComponent("worldMapURL")
        } catch {
            fatalError("Error getting world map URL from document directory.")
        }
    }()
    
    /*
    var mapSaveURL:URL = {
          do {
               let applicationSupportFolderURL = try FileManager.default.url(
                   for: .documentDirectory,
                   in: .userDomainMask,
                   appropriateFor: nil,
                   create: true)
               
               var folderUrl = applicationSupportFolderURL
               folderUrl = folderUrl.appendingPathComponent("ART", isDirectory: true)

               print("  Folder location: \(folderUrl.path)")
               
               if !FileManager.default.fileExists(atPath: folderUrl.path) {
                   try FileManager.default.createDirectory(at: folderUrl, withIntermediateDirectories: true, attributes: nil)
               }
            
            let fileUrl:URL! = folderUrl.appendingPathComponent("myExperience.armap")
            
            if !FileManager.default.fileExists(atPath: fileUrl.path) {
                print("File already there: \(fileUrl.path)")
            } else {
                print("File not there")
            }
            
            return fileUrl
          } catch {
              fatalError("Can't get file save URL: \(error.localizedDescription)")
          }
      }()
 */
        /*   URL = {
        do {
            let erg = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                .appendingPathComponent("ARTranslate", isDirectory: true)
                .appendingPathComponent("map.armap")
            print("Pfad:     ", erg.path)
            print("Pfad abs: ", erg.absoluteString)
            return erg
        } catch {
            fatalError("Can't get file save URL: \(error.localizedDescription)")
        }
    }()
    */
  
    
    // MARK: Load
    
    // Called opportunistically to verify that map data can be loaded from filesystem.
    var mapDataFromFile: Data? {
        return try? Data(contentsOf: self.mapSaveURL)
    }
    
    
    @IBAction func LoadButtonPressed(_ sender: UIButton) {
        
      /*  guard let worldMapData = retrieveWorldMapData(from: worldMapURL),
            let worldMap = unarchive(worldMapData: worldMapData) else { return }
        resetTrackingConfiguration(with: worldMap)
 */
        
        let worldMap: ARWorldMap = {
            guard let data = mapDataFromFile
                else { fatalError("Map data should already be verified to exist before Load button is enabled.") }
            do {
                guard let worldMap = try NSKeyedUnarchiver.unarchivedObject(ofClass: ARWorldMap.self, from: data)
                    else { fatalError("No ARWorldMap in archive.") }
                print( "load world map ok: " + self.mapSaveURL.path)
                let alert = UIAlertController(title: "World Map Loaded",
                                              message: "Found saved world map.",
                                              preferredStyle: .alert)
                  alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                  self.present(alert, animated: true)
                return worldMap
            } catch {
                fatalError("Can't unarchive ARWorldMap from file data: \(error)")
            }
        }()
        
        let configuration = self.defaultConfiguration // this app's standard world tracking settings
        configuration.initialWorldMap = worldMap
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])

        //isRelocalizingMap = true
        //virtualObjectAnchor = nil
    }
    
    var defaultConfiguration: ARWorldTrackingConfiguration {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        configuration.environmentTexturing = .automatic
        return configuration
    }
    
    
    
    @IBAction func ButtonUndoTapped(_ sender: UIButton) {
        let alert = UIAlertController(title: "Undo",
                                    message: "not implemented yet.",
                                    preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: true)
    }
    
    
    @IBAction func ButtonResetTrackingPressed(_ sender: Any) {
        sceneView.session.run(
            defaultConfiguration, options: [.resetTracking, .removeExistingAnchors])
         //  isRelocalizingMap = false
         //  virtualObjectAnchor = nil
    }
    
    
   /*
    func resetTrackingConfiguration(with worldMap: ARWorldMap? = nil) {
         let configuration = ARWorldTrackingConfiguration()
         configuration.planeDetection = [.horizontal]
         
         let options: ARSession.RunOptions = [.resetTracking, .removeExistingAnchors]
         if let worldMap = worldMap {
             configuration.initialWorldMap = worldMap
             print( "Found saved world map.")
            let alert = UIAlertController(title: "World Map Loaded",
                                          message: "Found saved world map.",
                                          preferredStyle: .alert)
              alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
              self.present(alert, animated: true)
         } else {
             print ("Move camera around to map your surrounding space.")
            let alert = UIAlertController(title: "no World Map",
                                          message: "Move camera around to map your surrounding space.",
                                          preferredStyle: .alert)
              alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
              self.present(alert, animated: true)
         }
         
         sceneView.debugOptions = [.showFeaturePoints, .showSkeletons]
         sceneView.session.run(configuration, options: options)
     }
    */
    
    // MARK: Save
    
    @IBAction func SaveButtonPressed(_ sender: UIButton) {
        sceneView.session.getCurrentWorldMap { worldMap, error in
            guard let map = worldMap
                else {
                    self.showAlert(title: "Error getting current world map: ", message: error!.localizedDescription)
                    print ("Error getting current world map: \( error!.localizedDescription)")
                    return
                    
            }
            
            do {
                let data = try NSKeyedArchiver.archivedData(withRootObject: map, requiringSecureCoding: true)
                try data.write(to: self.mapSaveURL, options: [.atomic])
                let alert = UIAlertController(title: "World Map Saved.",
                                                message: "Pfad: " + self.mapSaveURL.absoluteString,
                                                preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self.present(alert, animated: true)
                print ("World Map Saved: " + "Pfad: " + self.mapSaveURL.absoluteString)
                DispatchQueue.main.async {
                    //self.loadExperienceButton.isHidden = false
                    //self.loadExperienceButton.isEnabled = true
                }
            } catch {
                self.showAlert(title: "Can't get current world map", message: "\(error.localizedDescription)")
                fatalError("Can't save map: \(error.localizedDescription)")
            }
        }
  /*      sceneView.session.getCurrentWorldMap { (worldMap, error) in
                  guard let worldMap = worldMap else {
                      let alert = UIAlertController(title: "Error", message: "Error getting current world map.", preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                      self.present(alert, animated: true)
                    return
                    //return self.setLabel(text: "Error getting current world map.")
                  }
                  
                  do {
                      try self.writeWorldMap(worldMap: worldMap)
                      DispatchQueue.main.async {
                          let alert = UIAlertController(title: "World Map Saved.",
                                                        message: "Pfad: " + self.worldMapURL.absoluteString,
                                                        preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                        self.present(alert, animated: true)
                        print ("World Map Saved: " + "Pfad: " + self.worldMapURL.absoluteString)
                      }
                  } catch {
                      let alert = UIAlertController(title: "Error saving world map",
                                                    message: error.localizedDescription,
                                                    preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                        self.present(alert, animated: true)
                        print ("Error saving world map: " + error.localizedDescription)
                  }
              }
 */
    }



    func writeWorldMap(worldMap: ARWorldMap) throws {
          let data = try NSKeyedArchiver.archivedData(withRootObject: worldMap, requiringSecureCoding: true)
          try data.write(to: self.mapSaveURL, options: [.atomic])
          print ( "Pfad: " + self.mapSaveURL.absoluteString)
      }
      

      func retrieveWorldMapData(from url: URL) -> Data? {
          do {
            print ("retrievee WorldMapData from " + mapSaveURL.absoluteString)
              return try Data(contentsOf: self.mapSaveURL)
                
          } catch {
            let alert = UIAlertController(title: "Error", message: "Error retrieving world map data.", preferredStyle: .alert)

            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))

              self.present(alert, animated: true)
              return nil
          }
        
      }
      
      func unarchive(worldMapData data: Data) -> ARWorldMap? {
          guard let unarchievedObject = ((try? NSKeyedUnarchiver.unarchivedObject(ofClass: ARWorldMap.self, from: data)) as ARWorldMap??),
              let worldMap = unarchievedObject else { return nil }
          return worldMap
      }



}
