import UIKit
import CoreImage
import CoreImage.CIFilterBuiltins

@globalActor
actor ImageEnhancer {

    private let context: CIContext
    static let shared = ImageEnhancer()

    private init() {
        context = CIContext(options: [.workingColorSpace: NSNull()])
    }

    func enhance(_ image: UIImage) -> UIImage? {
        guard let inputCI = CIImage(image: image) else { return nil }
        let settings = enhancerSettings()

        let noiseReduction = CIFilter.noiseReduction()
        noiseReduction.inputImage = inputCI
        noiseReduction.noiseLevel = settings.noiseLevel
        noiseReduction.sharpness = settings.noiseSharpness

        guard let smoothedImage = noiseReduction.outputImage else { return nil }

        let color = CIFilter.colorControls()
        color.inputImage = smoothedImage
        color.contrast = settings.contrast
        color.saturation = settings.saturation
        color.brightness = settings.brightness

        guard let coloredImage = color.outputImage else { return nil }
        let unsharpMask = CIFilter.unsharpMask()
        unsharpMask.inputImage = coloredImage
        unsharpMask.radius = settings.unsharpRadius
        unsharpMask.intensity = settings.unsharpIntensity

        guard let outputCI = unsharpMask.outputImage,
              let cgImage = context.createCGImage(outputCI, from: inputCI.extent) else {
            return nil
        }

        return UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)
    }

    private func enhancerSettings() -> EnhancerSettings {
        let defaults = UserDefaults.standard
        let enhancer = AppSettings.ImageEnhancerSettings.self

        return EnhancerSettings(
            brightness: clampedFloat(
                defaults,
                key: enhancer.brightnessKey,
                defaultValue: enhancer.brightnessDefault,
                range: enhancer.brightnessRange
            ),
            contrast: clampedFloat(
                defaults,
                key: enhancer.contrastKey,
                defaultValue: enhancer.contrastDefault,
                range: enhancer.contrastRange
            ),
            saturation: clampedFloat(
                defaults,
                key: enhancer.saturationKey,
                defaultValue: enhancer.saturationDefault,
                range: enhancer.saturationRange
            ),
            noiseLevel: clampedFloat(
                defaults,
                key: enhancer.noiseLevelKey,
                defaultValue: enhancer.noiseLevelDefault,
                range: enhancer.noiseLevelRange
            ),
            noiseSharpness: clampedFloat(
                defaults,
                key: enhancer.noiseSharpnessKey,
                defaultValue: enhancer.noiseSharpnessDefault,
                range: enhancer.noiseSharpnessRange
            ),
            unsharpRadius: clampedFloat(
                defaults,
                key: enhancer.unsharpRadiusKey,
                defaultValue: enhancer.unsharpRadiusDefault,
                range: enhancer.unsharpRadiusRange
            ),
            unsharpIntensity: clampedFloat(
                defaults,
                key: enhancer.unsharpIntensityKey,
                defaultValue: enhancer.unsharpIntensityDefault,
                range: enhancer.unsharpIntensityRange
            )
        )
    }

    private func clampedFloat(
        _ defaults: UserDefaults,
        key: String,
        defaultValue: Double,
        range: ClosedRange<Double>
    ) -> Float {
        let value: Double
        if defaults.object(forKey: key) == nil {
            value = defaultValue
        } else {
            value = defaults.double(forKey: key)
        }
        return Float(min(max(value, range.lowerBound), range.upperBound))
    }
}

private struct EnhancerSettings {
    let brightness: Float
    let contrast: Float
    let saturation: Float
    let noiseLevel: Float
    let noiseSharpness: Float
    let unsharpRadius: Float
    let unsharpIntensity: Float
}
