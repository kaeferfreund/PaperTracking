//
//  ViewController.swift
//  SmartCameraLBTA
//
//  Created by Brian Voong on 7/12/17.
//  Copyright © 2017 Lets Build That App. All rights reserved.
//

import UIKit
import AVKit
import Vision

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    let identifierLabel: UILabel = {
        let label = UILabel()
        label.backgroundColor = .white
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    var boundingView: UIView = {
        let view = UIView()
        return view
    }()
    
    let fullScreenImage: UIImageView = {
        let imageView = UIImageView()
        //imageView.backgroundColor = .green
        return imageView
    }()
    
    var previewLayer:AVCaptureVideoPreviewLayer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // here is where we start up the camera
        // for more details visit: https://www.letsbuildthatapp.com/course_video?id=1252
        let captureSession = AVCaptureSession()
        captureSession.sessionPreset = .photo
        
        guard let captureDevice = AVCaptureDevice.default(for: .video) else { return }
        guard let input = try? AVCaptureDeviceInput(device: captureDevice) else { return }
        captureSession.addInput(input)
        
        captureSession.startRunning()
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        view.layer.addSublayer(previewLayer)
        previewLayer.frame = view.frame
        
        let dataOutput = AVCaptureVideoDataOutput()

        dataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
        captureSession.addOutput(dataOutput)
        
        view.addSubview(boundingView)
        boundingView.frame.size = CGSize(width: 100, height: 100)
        view.addSubview(fullScreenImage)
        fullScreenImage.frame = view.frame
        setupIdentifierConfidenceLabel()
    }
    
    fileprivate func setupIdentifierConfidenceLabel() {
        view.addSubview(identifierLabel)
        identifierLabel.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -32).isActive = true
        identifierLabel.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        identifierLabel.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        identifierLabel.heightAnchor.constraint(equalToConstant: 50).isActive = true
    }
    
    lazy var rectanglesRequest: VNDetectRectanglesRequest = {
        let request = VNDetectRectanglesRequest(completionHandler: self.handleRectangles)
        request.minimumConfidence = 0.7
        return request
    }()
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        guard let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        let detectRequest = rectanglesRequest
        
        do {
            try VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:]).perform([detectRequest])
        } catch {
            print(error)
        }
    }
    
    func handleRectangles(request: VNRequest, error: Error?) {
        guard let observations = request.results as? [VNRectangleObservation]
            else { fatalError("unexpected result type from VNDetectRectanglesRequest") }
        guard let detectedRectangle = observations.first else {
            DispatchQueue.main.async {
                print("No rectangles detected.")
            }
            return
        }
        
        // show bounding rectangle
        if(false){
            var boundingBox = detectedRectangle.boundingBox
            boundingBox.origin.y = 1 - (boundingBox.origin.y + boundingBox.width)
            let convertedRect = self.previewLayer.layerRectConverted(fromMetadataOutputRect: boundingBox)
            
            DispatchQueue.main.async {
                self.boundingView.frame = convertedRect
            }
        }
        
        // draw on image
        if(true){
            DispatchQueue.main.async {
                self.fullScreenImage.image = nil
                
                
                UIGraphicsBeginImageContext(self.view.frame.size)
                // Draw the starting image in the current context as background
                self.fullScreenImage.image?.draw(at: CGPoint.zero)
                //let ciimage = CIImage(image: self.fullScreenImage.image!)
                let imageSize = self.previewLayer.frame.size
                
                // Get the current context
                let context = UIGraphicsGetCurrentContext()!
                // Draw a red line
                context.setLineWidth(2.0)
                context.setStrokeColor(UIColor.blue.cgColor)
//                context.move(to: detectedRectangle.topLeft.scaled(to:imageSize))
//                context.addLine(to: detectedRectangle.topRight.scaled(to:imageSize))
//                context.addLine(to: detectedRectangle.bottomRight.scaled(to:imageSize))
//                context.addLine(to: detectedRectangle.bottomLeft.scaled(to:imageSize))
//                context.addLine(to: detectedRectangle.topLeft.scaled(to:imageSize))
//                context.strokePath()
                
                let convertedTopLeft: CGPoint = self.previewLayer.layerPointConverted(fromCaptureDevicePoint: CGPoint(x: detectedRectangle.topLeft.x, y: 1 - detectedRectangle.topLeft.y))
                let convertedTopRight: CGPoint = self.previewLayer.layerPointConverted(fromCaptureDevicePoint: CGPoint(x: detectedRectangle.topRight.x, y: 1 - detectedRectangle.topRight.y))
                let convertedBottomLeft: CGPoint = self.previewLayer.layerPointConverted(fromCaptureDevicePoint: CGPoint(x: detectedRectangle.bottomLeft.x, y: 1 - detectedRectangle.bottomLeft.y))
                let convertedBottomRight: CGPoint = self.previewLayer.layerPointConverted(fromCaptureDevicePoint: CGPoint(x: detectedRectangle.bottomRight.x, y: 1 - detectedRectangle.bottomRight.y))
                


                context.move(to: convertedTopLeft)
                context.addLine(to: convertedTopRight)
                context.addLine(to: convertedBottomLeft)
                context.addLine(to: convertedBottomRight)
                context.addLine(to: convertedTopLeft)
                context.strokePath()
                
                context.drawPath(using: .stroke) // or .fillStroke if need filling
                
                // Save the context as a new UIImage
                self.fullScreenImage.image = UIGraphicsGetImageFromCurrentImageContext()
                UIGraphicsEndImageContext()
            }
        }
        
    }
    
}

extension CGPoint {
    func scaled(to size: CGSize) -> CGPoint {
        return CGPoint(x: self.x * size.width, y: self.y * size.height)
    }
}
extension CGRect {
    func scaled(to size: CGSize) -> CGRect {
        return CGRect(
            x: self.origin.x * size.width,
            y: self.origin.y * size.height,
            width: self.size.width * size.width,
            height: self.size.height * size.height
        )
    }
}
