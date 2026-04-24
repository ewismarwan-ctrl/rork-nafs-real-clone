import Vision
import CoreMedia
import UIKit

@Observable
class ObjectDetectionService {
    var objectDetected: Bool = false
    var detectedObjectCount: Int = 0
    var confidence: Float = 0
    var detectedLabel: String = ""

    func detectObjects(sampleBuffer: CMSampleBuffer) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        let classifyRequest = VNClassifyImageRequest { [weak self] request, error in
            guard let results = request.results as? [VNClassificationObservation] else { return }

            let validResults = results.filter { $0.confidence > 0.15 }
            let topResult = validResults.first

            let isRealObject = self?.isRecognizableObject(results: validResults) ?? false

            Task { @MainActor in
                self?.detectedObjectCount = validResults.count
                self?.objectDetected = isRealObject
                self?.confidence = topResult?.confidence ?? 0
                self?.detectedLabel = topResult?.identifier ?? ""
            }
        }

        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .right)
        try? handler.perform([classifyRequest])
    }

    private func isRecognizableObject(results: [VNClassificationObservation]) -> Bool {
        let validCategories: Set<String> = [
            "bottle", "cup", "mug", "glass", "water_bottle",
            "toothbrush", "soap_dispenser", "remote_control",
            "cellular_telephone", "cell_phone", "phone", "mobile_phone",
            "book", "notebook", "pen", "pencil",
            "keyboard", "mouse", "laptop", "computer",
            "shoe", "sandal", "slipper",
            "watch", "clock", "alarm_clock",
            "lamp", "light", "candle",
            "pillow", "blanket", "towel",
            "plate", "bowl", "spoon", "fork", "knife",
            "bag", "backpack", "wallet",
            "key", "door", "window", "mirror",
            "chair", "table", "desk", "bed",
            "plant", "flower_pot", "vase",
            "toy", "teddy_bear", "ball",
            "television", "monitor", "screen",
            "hand", "person", "face",
            "food", "fruit", "banana", "apple", "orange",
            "coffee", "tea", "water",
            "charger", "cable", "headphone", "earphone",
            "tissue", "paper", "card"
        ]

        for result in results.prefix(10) {
            guard result.confidence > 0.1 else { continue }
            let label = result.identifier.lowercased().replacingOccurrences(of: " ", with: "_")
            for category in validCategories {
                if label.contains(category) || category.contains(label) {
                    return true
                }
            }
        }

        if let topResult = results.first, topResult.confidence > 0.4 {
            return true
        }

        return false
    }

    func verifyScreenTimeScreenshot(imageData: Data, completion: @escaping (Bool, String) -> Void) {
        guard let cgImage = UIImage(data: imageData)?.cgImage else {
            completion(false, "Could not process image")
            return
        }

        let request = VNRecognizeTextRequest { request, error in
            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                Task { @MainActor in completion(false, "Could not read text from image") }
                return
            }

            var allText = ""
            for observation in observations {
                if let candidate = observation.topCandidates(1).first {
                    allText += candidate.string.lowercased() + " "
                }
            }

            let screenTimeKeywords = [
                "screen time", "app limits", "app limit",
                "downtime", "always allowed",
                "content & privacy", "content and privacy",
                "communication limits",
                "time limit", "block at end of limit",
                "مدة الاستخدام", "حدود التطبيقات", "وقت التوقف"
            ]

            let found = screenTimeKeywords.contains { allText.contains($0) }

            Task { @MainActor in
                if found {
                    completion(true, "Screen Time settings verified")
                } else {
                    completion(false, "This doesn't appear to be a Screen Time screenshot. Please upload a screenshot from Settings → Screen Time → App Limits.")
                }
            }
        }
        request.recognitionLevel = .accurate

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        DispatchQueue.global(qos: .userInitiated).async {
            try? handler.perform([request])
        }
    }
}
