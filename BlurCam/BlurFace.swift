
import UIKit

public class BlurFace {
    
    private let ciDetector = CIDetector(ofType: CIDetectorTypeFace, context: nil ,options: [CIDetectorAccuracy : CIDetectorAccuracyHigh])
    
    public var ciImage: CIImage!
    private var orientation: UIImage.Orientation = .up
    
    private var features : [AnyObject]!
    
    private lazy var context = { CIContext(options: nil) }()
    
    // MARK: Initializers
    
    public init(image: UIImage!) {
        setImage(image: image)
    }
    
    public func setImage(image: UIImage!) {
        ciImage = CIImage(image: image)
        orientation = image.imageOrientation
        self.features = self.ciDetector!.features(in: self.ciImage)
    }
    
    // MARK: Public
    
    public func hasFaces() -> Bool {
        self.features = self.ciDetector!.features(in: self.ciImage)
        return !features.isEmpty
    }
    
    public func blurFaces() -> UIImage {
        let pixelateFiler = CIFilter(name: "CIPixellate")
        pixelateFiler!.setValue(ciImage, forKey: kCIInputImageKey)
        pixelateFiler!.setValue(max(ciImage!.extent.width, ciImage.extent.height) / 60.0, forKey: kCIInputScaleKey)
        
        var maskImage: CIImage?
        for feature in featureFaces() {
            let centerX = feature.bounds.origin.x + feature.bounds.size.width / 2.0
            let centerY = feature.bounds.origin.y + feature.bounds.size.height / 2.0
            let radius = min(feature.bounds.size.width, feature.bounds.size.height) / 1.5
            
            let radialGradient = CIFilter(name: "CIRadialGradient")
            radialGradient!.setValue(radius, forKey: "inputRadius0")
            radialGradient!.setValue(radius + 1, forKey: "inputRadius1")
            radialGradient!.setValue(CIColor(red: 0, green: 1, blue: 0, alpha: 1), forKey: "inputColor0")
            radialGradient!.setValue(CIColor(red: 0, green: 0, blue: 0, alpha: 0), forKey: "inputColor1")
            radialGradient!.setValue(CIVector(x: centerX, y: centerY), forKey: kCIInputCenterKey)
            
            let circleImage = radialGradient?.outputImage!.cropped(to: ciImage.extent)
            
            if (maskImage == nil) {
                maskImage = circleImage
            }
            else {
                let filter =  CIFilter(name: "CISourceOverCompositing")
                filter!.setValue(circleImage, forKey: kCIInputImageKey)
                filter!.setValue(maskImage, forKey: kCIInputBackgroundImageKey)
                
                maskImage = filter?.outputImage
            }
        }
        
        let composite = CIFilter(name: "CIBlendWithMask")
        composite!.setValue(pixelateFiler?.outputImage, forKey: kCIInputImageKey)
        composite!.setValue(ciImage, forKey: kCIInputBackgroundImageKey)
        composite!.setValue(maskImage, forKey: kCIInputMaskImageKey)
        
        let cgImage = context.createCGImage((composite?.outputImage!)!, from: (composite?.outputImage!.extent)!)
        return UIImage(cgImage: cgImage!, scale: 1, orientation: orientation)
    }
    
    // MARK: Private
    
    private func featureFaces() -> [CIFeature] {
        print("1")
        return features as! [CIFeature]
    }
}
