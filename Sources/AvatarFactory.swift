
import UIKit

final class AvatarFactory {
    static func avatar(name: String, seed: Int, size: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            let rect = CGRect(origin: .zero, size: size)
            let path = UIBezierPath(ovalIn: rect)
            path.addClip()

            let h1 = CGFloat(seed % 360) / 360
            let h2 = CGFloat((seed * 37) % 360) / 360
            let c1 = UIColor(hue: h1, saturation: 0.72, brightness: 0.95, alpha: 1).cgColor
            let c2 = UIColor(hue: h2, saturation: 0.78, brightness: 0.55, alpha: 1).cgColor
            let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                      colors: [c1, c2] as CFArray,
                                      locations: [0, 1])!
            ctx.cgContext.drawLinearGradient(gradient, start: .zero,
                                             end: CGPoint(x: size.width, y: size.height),
                                             options: [])

            ctx.cgContext.setAlpha(0.18)
            ctx.cgContext.setFillColor(UIColor.black.cgColor)
            let blob = CGRect(x: -size.width * 0.2, y: size.height * 0.5,
                              width: size.width * 0.9, height: size.height * 0.9)
            ctx.cgContext.fillEllipse(in: blob)
            ctx.cgContext.setAlpha(1)

            let text = name.initials as NSString
            let font = UIFont.systemFont(ofSize: max(12, size.width * 0.36), weight: .bold)
            let attrs: [NSAttributedString.Key: Any] = [.foregroundColor: UIColor.white, .font: font]
            let textSize = text.size(withAttributes: attrs)
            let origin = CGPoint(x: (size.width - textSize.width) / 2,
                                 y: (size.height - textSize.height) / 2)
            text.draw(at: origin, withAttributes: attrs)
        }
    }

    static func gradientImage(seed: Int, size: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            let rect = CGRect(origin: .zero, size: size)
            let h1 = CGFloat(seed % 360) / 360
            let h2 = CGFloat((seed * 53 + 40) % 360) / 360
            let c1 = UIColor(hue: h1, saturation: 0.85, brightness: 0.85, alpha: 1).cgColor
            let c2 = UIColor(hue: h2, saturation: 0.9, brightness: 0.32, alpha: 1).cgColor
            let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                      colors: [c1, c2] as CFArray,
                                      locations: [0, 1])!
            ctx.cgContext.drawLinearGradient(gradient, start: CGPoint(x: 0, y: size.height),
                                             end: CGPoint(x: size.width, y: 0), options: [])

            var rng = SeededRandom(UInt64(seed + 1))
            for _ in 0..<10 {
                let radius = CGFloat(rng.int(18...90))
                let x = CGFloat(rng.int(0...Int(size.width)))
                let y = CGFloat(rng.int(0...Int(size.height)))
                ctx.cgContext.setFillColor(UIColor.white.withAlphaComponent(0.06).cgColor)
                ctx.cgContext.fillEllipse(in: CGRect(x: x - radius, y: y - radius,
                                                     width: radius * 2, height: radius * 2))
            }
        }
    }

    static func waveform(seed: Int, width: CGFloat) -> UIImage {
        let height: CGFloat = 28
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: width, height: height))
        return renderer.image { ctx in
            var rng = SeededRandom(UInt64(seed + 77))
            let bars = 34
            let step = width / CGFloat(bars)
            for i in 0..<bars {
                let h = CGFloat(rng.int(4...22))
                let rect = CGRect(x: CGFloat(i) * step + 1, y: (height - h) / 2,
                                  width: max(1, step - 2), height: h)
                let color = i % 3 == 0 ? UIColor.white : UIColor.white.withAlphaComponent(0.55)
                color.setFill()
                UIBezierPath(roundedRect: rect, cornerRadius: 1.5).fill()
            }
        }
    }

    static func mapImage(seed: Int, size: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            UIColor(red: 0.10, green: 0.14, blue: 0.20, alpha: 1).setFill()
            ctx.fill(CGRect(origin: .zero, size: size))

            UIColor.white.withAlphaComponent(0.08).setStroke()
            let path = UIBezierPath()
            let step: CGFloat = 22
            var x: CGFloat = 0
            while x <= size.width {
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: size.height))
                x += step
            }
            var y: CGFloat = 0
            while y <= size.height {
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size.width, y: y))
                y += step
            }
            path.lineWidth = 1
            path.stroke()

            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            UIColor.systemPink.setFill()
            UIBezierPath(ovalIn: CGRect(x: center.x - 8, y: center.y - 8, width: 16, height: 16)).fill()
            UIColor.white.setFill()
            UIBezierPath(ovalIn: CGRect(x: center.x - 3, y: center.y - 3, width: 6, height: 6)).fill()
        }
    }
}
