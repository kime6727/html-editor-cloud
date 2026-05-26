import UIKit
import CoreImage

struct QRCodeGenerator {
    static func generate(from string: String, size: CGSize = CGSize(width: 300, height: 300)) -> UIImage? {
        guard let data = string.data(using: .utf8) else { return nil }
        
        let filter = CIFilter(name: "CIQRCodeGenerator")
        filter?.setValue(data, forKey: "inputMessage")
        filter?.setValue("H", forKey: "inputCorrectionLevel") // High error correction
        
        guard let ciImage = filter?.outputImage else { return nil }
        
        // Scale up the QR code
        let scaleX = size.width / ciImage.extent.width
        let scaleY = size.height / ciImage.extent.height
        let transformedImage = ciImage.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))
        
        // Convert to UIImage
        let context = CIContext()
        guard let cgImage = context.createCGImage(transformedImage, from: transformedImage.extent) else {
            return nil
        }
        
        return UIImage(cgImage: cgImage)
    }
    
    static func generateWithLogo(from string: String, 
                                 logo: UIImage? = nil,
                                 size: CGSize = CGSize(width: 300, height: 300)) -> UIImage? {
        guard let qrImage = generate(from: string, size: size) else { return nil }
        
        // If no logo, return plain QR code
        guard let logo = logo else { return qrImage }
        
        // Create a new image with logo in center
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        defer { UIGraphicsEndImageContext() }
        
        // Draw QR code
        qrImage.draw(in: CGRect(origin: .zero, size: size))
        
        // Draw logo in center (20% of QR code size)
        let logoSize = CGSize(width: size.width * 0.2, height: size.height * 0.2)
        let logoOrigin = CGPoint(x: (size.width - logoSize.width) / 2,
                                y: (size.height - logoSize.height) / 2)
        
        // Draw white background for logo
        let logoBackgroundRect = CGRect(origin: logoOrigin, size: logoSize).insetBy(dx: -8, dy: -8)
        UIColor.white.setFill()
        UIBezierPath(roundedRect: logoBackgroundRect, cornerRadius: 8).fill()
        
        // Draw logo
        logo.draw(in: CGRect(origin: logoOrigin, size: logoSize))
        
        return UIGraphicsGetImageFromCurrentImageContext()
    }
}
