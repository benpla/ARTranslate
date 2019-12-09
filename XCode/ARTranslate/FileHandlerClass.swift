//
//  FileHandlerClass.swift
//  IOS-CoreMotionGyroskope_01
//
//  Created by Benny Platte on 04.06.19.
//  Copyright © 2019 Benny Platte. All rights reserved.
//

import Foundation


class FileHandlerClass {
    var DatafileUrl:URL?
    var Subfoldername:String? = nil
    
    
    var Filename: String {
        get {
            guard let url = self.DatafileUrl else {
                return "no file URL defined"
            }
            return url.lastPathComponent
        }
//        set {
//        }
    }

    
    init(filename: String = "data.csv") {
        DatafileUrl = self.GetDatafile(subfolderName: nil, filename: filename)
    }
    
    

    
    func writeDataToFile(msg:String) -> Bool {
        if let unwrappedFileUrl = DatafileUrl {
            guard let fileHandle = FileHandle(forWritingAtPath: unwrappedFileUrl.path) else {
                do {
                    try msg.write(to: unwrappedFileUrl, atomically: true, encoding: .utf8)
                }
                catch {
                    return false
                }
                return true
            }
            
            guard let data = msg.data(using: .utf8) else {
                return false
            }
            
            fileHandle.seekToEndOfFile()
            fileHandle.write(data)
            return true
        }
        return false
    }
    
    
    private func GetDatafile(subfolderName:String?, filename:String)->URL? {
        //print ( "func getDatafile(), filename:\(filename)")
        let fileUrl = createDirectory(dirName: subfolderName)  // Name des Directorys. nil für kein extra Unterverzeichnis
        if let path = fileUrl {
            print("create folder ok:   \(path.path)")
        } else {
            print("create folder error")
            return nil
        }
        
        let filePath:URL! = fileUrl!.appendingPathComponent(filename)
        
        if !FileManager.default.fileExists(atPath: fileUrl!.path) {
            print("File already there")
        } else {
            print("File not there")
        }
        
        //        print ( "filepath:\(filePath!)")
        return filePath
    }
    
    
    
    private  func createDirectory(dirName:String?)->URL? {
        print ("func 'createDirectory'")
        do {
            let applicationSupportFolderURL = try FileManager.default.url(
                for: .documentDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true)
            
            var folderUrl = applicationSupportFolderURL
            
            // Argument auf Leerheit prüfen. Wenn es nicht leer ist, dann Foldernamen dranhängen
            if let unwrappedDirName = dirName {
                folderUrl = folderUrl.appendingPathComponent(unwrappedDirName, isDirectory: true)
            }
            print("  Folder location: \(folderUrl.path)")
            
            if !FileManager.default.fileExists(atPath: folderUrl.path) {
                try FileManager.default.createDirectory(at: folderUrl, withIntermediateDirectories: true, attributes: nil)
            }
            return folderUrl
        } catch {
            print(error)
            return nil
        }
    }
    
    
    func GetFileSizeBytes() -> UInt64 {
        guard let url = self.DatafileUrl else {
            return 0
        }
        
        var fileSize: UInt64 = 0

        var fileSizeValue = 0.0
        try? fileSizeValue = (url.resourceValues(forKeys: [URLResourceKey.fileSizeKey]).allValues.first?.value as! Double?)!
        if fileSizeValue > 0.0 {
            fileSize = UInt64(fileSizeValue)
        }
        return fileSize
    }
    
    
    func DeleteFile() -> Bool {
        guard let url = self.DatafileUrl else {
            return false
        }

        do {
            let fileManager = FileManager.default
            
            // Check if file exists
            if fileManager.fileExists(atPath: url.path) {
                // Delete file
                try fileManager.removeItem(at: url)
            } else {
                print("File to delete does not exist")
                return false
            }
            
        }
        catch let error as NSError {
            print("An error took place: \(error)")
            return false
        }
        return true
    }

}
