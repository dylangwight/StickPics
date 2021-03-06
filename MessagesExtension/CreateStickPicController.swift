//
//  CreateStickPicController.swift
//  StickPics
//
//  Created by Dylan Wight on 8/20/16.
//  Copyright © 2016 Dylan Wight. All rights reserved.
//

import Foundation
import UIKit
import Messages

let savedStickerKey = "savedStickerKey"

protocol CreateStickPicDelegate: class {
    func save () -> ()
}

class CreateStickPicController: UIViewController {
    
    weak var delegate: CreateStickPicDelegate?
    
    static let storyboardIdentifier = "CreateStickPicController"
    
    fileprivate var undoStack = [UIImage]()
    
    fileprivate var currentStroke: UIImage?
    
    @IBOutlet weak var backgroundView: UIView! {
        didSet {
            backgroundView.backgroundColor = UIColor(patternImage: #imageLiteral(resourceName: "backgroundTile"))
        }
    }
    
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var leftUnderFingerView: UIImageView! {
        didSet {
            leftUnderFingerView.clipsToBounds = true
            leftUnderFingerView.layer.borderWidth = 2.0
            leftUnderFingerView.layer.borderColor = UIColor.black.cgColor
            leftUnderFingerView.alpha = 0.0
            leftUnderFingerView.backgroundColor = UIColor(patternImage: #imageLiteral(resourceName: "backgroundTile"))
        }
    }
    
    @IBOutlet weak var rightUnderFingerView: UIImageView! {
        didSet {
            rightUnderFingerView.clipsToBounds = true
            rightUnderFingerView.layer.borderWidth = 2.0
            rightUnderFingerView.layer.borderColor = UIColor.black.cgColor
            rightUnderFingerView.alpha = 0.0
            rightUnderFingerView.backgroundColor = UIColor(patternImage: #imageLiteral(resourceName: "backgroundTile"))
        }
    }
    
    var brushSize: CGFloat {
        return (CGFloat(sizeSlider.value) * CGFloat(sizeSlider.value))
    }
    
    var lastPoint: CGPoint?
    
    var actualSize: CGSize {
        return CGSize(width: imageView.frame.width * 2.0, height: imageView.frame.height * 2.0)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let drag = UILongPressGestureRecognizer(target: self, action: #selector(CreateStickPicController.handleDrag(_:)))
        drag.minimumPressDuration = 0.0
        drag.delegate = self
        imageView.addGestureRecognizer(drag)
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if let savedSticker = UserDefaults.standard.string(forKey: savedStickerKey) {
            imageView.image = UIImage.fromBase64(savedSticker)
        }
        
        if !UserDefaults.standard.bool(forKey: "intro") {
            UserDefaults.standard.set(true, forKey: "intro")
            let introAlert = UIAlertController(title: "Welcome", message: "Tap 'Choose Photo' to select a picture. Then erase the background of the photo and save to your sticker collection.", preferredStyle: UIAlertControllerStyle.alert)
            
            introAlert.addAction(UIAlertAction(title: "Got it", style: .default, handler: nil ))
            self.present(introAlert, animated: true, completion: nil)
        }
    }
    
    @IBAction func save(_ sender: UIButton) {
        let saveAlert = UIAlertController(title: "Finished?", message: "Add this sticker to your collection", preferredStyle: .alert)
        
        saveAlert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { _ in
            if let image = self.imageView.image {
                if let data = UIImagePNGRepresentation(image) {
                    
                    let id = NSUUID().uuidString
                    
                    let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier:
                        "group.stickpics")!.appendingPathComponent("\(id).png")
                    
                    StickPicHistory.load().add(url: url)
                    
                    do {
                        try data.write(to: url)
                        UserDefaults.standard.setValue(nil, forKey: savedStickerKey)
                        self.delegate?.save()
                    } catch {
                        print(error)
                    }
                }
            }
        }))
        saveAlert.addAction(UIAlertAction(title: "No", style: .cancel, handler: nil))
        self.present(saveAlert, animated: true, completion: nil)
    }
    
    @IBAction func addPhoto(_ sender: UIButton) {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.allowsEditing = false
        imagePicker.sourceType = .photoLibrary
        
        addChildViewController(imagePicker)
        
        imagePicker.view.frame = view.bounds
        imagePicker.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(imagePicker.view)
        
        imagePicker.view.leftAnchor.constraint(equalTo: stackView.leftAnchor).isActive = true
        imagePicker.view.rightAnchor.constraint(equalTo: stackView.rightAnchor).isActive = true
        imagePicker.view.topAnchor.constraint(equalTo: stackView.topAnchor).isActive = true
        imagePicker.view.bottomAnchor.constraint(equalTo: stackView.bottomAnchor).isActive = true
        imagePicker.didMove(toParentViewController: self)
    }
    
    @IBAction func undo(_ sender: UIButton) {
        _ = undoStack.popLast()
        imageView.image = undoStack.last
        UserDefaults.standard.setValue(imageView.image?.toBase64(), forKey: savedStickerKey)
    }
    
    @IBOutlet weak var sizeSlider: UISlider! {
        didSet {
            sizeSlider.minimumValue = 2.0
            sizeSlider.maximumValue = 10.0
            sizeSlider.value = 5.5
        }
    }


    func handleDrag(_ sender: UILongPressGestureRecognizer) {
        
        let point = sender.location(in: imageView)
        
        setUnderFingerView(point)
        
        switch sender.state {
        case .began:
            lastPoint = point
        case .changed:
            let currentPoint = sender.location(in: imageView)
            
            UIGraphicsBeginImageContext(imageView.frame.size)
            imageView.image?.draw(at: CGPoint.zero)
            
            let context = UIGraphicsGetCurrentContext()!
            
            context.setLineCap(.round)
            context.setLineWidth(brushSize)
            context.setBlendMode(.clear)
            
            context.setStrokeColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
            context.beginPath()
            
            if let lastPoint = lastPoint {
                context.move(to: CGPoint(x: lastPoint.x, y: lastPoint.y))
            }
            context.addLine(to: CGPoint(x: currentPoint.x, y: currentPoint.y))

            context.strokePath()
            imageView.image = UIGraphicsGetImageFromCurrentImageContext()
            
            UIGraphicsEndImageContext()
            
            lastPoint = currentPoint
            
        case .ended:
            hide(view: rightUnderFingerView)
            hide(view: leftUnderFingerView)
            addToUndoStack(imageView.image)
        default:
            break
        }
    }
    
    fileprivate func addToUndoStack(_ image: UIImage?) {
        guard let image = image else { return }
        UserDefaults.standard.setValue(image.toBase64(), forKey: savedStickerKey)
        if undoStack.count <= 20 {
            undoStack.append(image)
        } else {
            undoStack.remove(at: 0)
            undoStack.append(image)
        }
    }
}

extension CreateStickPicController {
    
    public func hide(view: UIView) {
        UIView.animate(withDuration: 0.5,delay: 0.0, options: UIViewAnimationOptions.beginFromCurrentState, animations: {
            view.alpha = 0.0
        }, completion: nil)
    }
    
    public func show(view: UIView) {
        UIView.animate(withDuration: 0.5,delay: 0.0, options: UIViewAnimationOptions.beginFromCurrentState, animations: {
            view.alpha = 1.0
        }, completion: nil)
    }
    
    public func setUnderFingerView(_ position: CGPoint) {
        
        let underFingerSize: CGSize
        
        let maxUnderFinger: CGFloat = 400.0
        let minUnderFinger: CGFloat = 200.0
        
        let ceilingSize: CGFloat = 80.0
        let baseSize: CGFloat = 10.0
        
        if (brushSize > ceilingSize) {
            underFingerSize = CGSize(width: maxUnderFinger, height: maxUnderFinger)
        } else if (brushSize < baseSize){
            underFingerSize = CGSize(width: minUnderFinger, height: minUnderFinger)
        } else {
            let underFinger = ((brushSize - baseSize) / ceilingSize) * (maxUnderFinger - minUnderFinger) + minUnderFinger
            underFingerSize = CGSize(width: underFinger, height: underFinger)
        }
        
        let underFingerImage = imageView.image?.cropToSquare(position, cropSize: underFingerSize)
        leftUnderFingerView.image = underFingerImage
        rightUnderFingerView.image = underFingerImage
        
        if position.x < 150.0 && position.y < 150.0 {
            show(view: rightUnderFingerView)
            hide(view: leftUnderFingerView)
        } else {
            show(view: leftUnderFingerView)
            hide(view: rightUnderFingerView)
        }
    }
}

extension CreateStickPicController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            UIGraphicsBeginImageContext(imageView.frame.size)
            pickedImage.draw(in: imageView.frame)
            imageView.image = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            addToUndoStack(imageView.image)
        }
        
        for child in childViewControllers {
            child.willMove(toParentViewController: nil)
            child.view.removeFromSuperview()
            child.removeFromParentViewController()
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        for child in childViewControllers {
            child.willMove(toParentViewController: nil)
            child.view.removeFromSuperview()
            child.removeFromParentViewController()
        }
    }
}

extension CreateStickPicController: UIGestureRecognizerDelegate {}

