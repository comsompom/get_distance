import Foundation

protocol MeasurementCalculating {
    func calculateDistanceMeters(focalLengthPixels: Float, realHeightMeters: Float, pixelHeight: Float) -> Float
}

struct MeasurementCalculator: MeasurementCalculating {
    func calculateDistanceMeters(focalLengthPixels: Float, realHeightMeters: Float, pixelHeight: Float) -> Float {
        guard pixelHeight > 0 else { return 0 }
        return (focalLengthPixels * realHeightMeters) / pixelHeight
    }
}
