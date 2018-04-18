//
//  ViewController.swift
//  CircleMaskDemo
//
//  Created by Robert Ryan on 4/18/18.
//  Copyright © 2018 Robert Ryan. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var pinch: UIPinchGestureRecognizer!
    @IBOutlet weak var pan: UIPanGestureRecognizer!
    
    private let maskLayer = CAShapeLayer()
    
    private lazy var radius: CGFloat = min(view.bounds.width, view.bounds.height) * 0.3
    private lazy var center: CGPoint = CGPoint(x: view.bounds.midX, y: view.bounds.midY)
    
    private let pathLayer: CAShapeLayer = {
        let _pathLayer = CAShapeLayer()
        _pathLayer.fillColor = UIColor.clear.cgColor
        _pathLayer.strokeColor = UIColor.black.cgColor
        _pathLayer.lineWidth = 3
        return _pathLayer
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imageView.layer.addSublayer(pathLayer)
        imageView.layer.mask = maskLayer
        
        updateCirclePath(at: center, radius: radius)
        
        // imageView.isUserInteractionEnabled = true
        imageView.addGestureRecognizer(pinch)
        imageView.addGestureRecognizer(pan)
    }
    
    private var oldCenter: CGPoint!
    private var oldRadius: CGFloat!
    
    @IBAction func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        let scale = gesture.scale
        
        if gesture.state == .began { oldRadius = radius }
        
        updateCirclePath(at: center, radius: oldRadius * scale)
    }
    
    @IBAction func handlePan(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: gesture.view)
        
        if gesture.state == .began { oldCenter = center }
        
        let newCenter = CGPoint(x: oldCenter.x + translation.x, y: oldCenter.y + translation.y)
        
        updateCirclePath(at: newCenter, radius: radius)
    }
    
    @IBAction func handleTap(_ gesture: UITapGestureRecognizer) {
        let fileURL = try! FileManager.default
            .url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appendingPathComponent("image.png")
        
        let scale  = imageView.window!.screen.scale
        let radius = self.radius * scale
        let center = CGPoint(x: self.center.x * scale, y: self.center.y * scale)
        
        let frame = CGRect(x: center.x - radius,
                           y: center.y - radius,
                           width: radius * 2.0,
                           height: radius * 2.0)
        
        // temporarily remove the circleLayer
        
        let saveLayer = pathLayer
        saveLayer.removeFromSuperlayer()
        
        // render the clipped image
        
        UIGraphicsBeginImageContextWithOptions(imageView.frame.size, false, 0)
        imageView.drawHierarchy(in: imageView.bounds, afterScreenUpdates: true)
        
        // capture the image and close the context
        
        let image = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        // add the circleLayer back
        
        imageView.layer.addSublayer(saveLayer)
        
        // crop the image
        
        let imageRef = image.cgImage!.cropping(to: frame)!
        let cropped = UIImage(cgImage: imageRef)
        
        // save the image
        
        let data = UIImagePNGRepresentation(cropped)!
        try? data.write(to: fileURL)
        
        // tell the user we're done
        
        let alert = UIAlertController(title: nil, message: "Saved", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    private func updateCirclePath(at center: CGPoint, radius: CGFloat) {
        self.center = center
        self.radius = radius
        
        let path = UIBezierPath(arcCenter: center, radius: radius, startAngle: 0, endAngle: 2 * .pi, clockwise: true)
        maskLayer.path = path.cgPath
        pathLayer.path = path.cgPath
    }
}

extension ViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return (gestureRecognizer == pinch && otherGestureRecognizer == pan) ||
            (gestureRecognizer == pan && otherGestureRecognizer == pinch)
    }
}
