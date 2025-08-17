import Cocoa
import FlutterMacOS

public class FastJpegEncoderPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "fast_jpeg_encoder", binaryMessenger: registrar.messenger)
    let instance = FastJpegEncoderPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getPlatformVersion":
      result("macOS " + ProcessInfo.processInfo.operatingSystemVersionString)
      case "encodeJpeg":
      guard let args = call.arguments as? [String: Any],
            let width = args["width"] as? Int,
            let height = args["height"] as? Int,
            let rgba = args["rgba"] as? FlutterStandardTypedData else {
        result(FlutterError(code: "INVALID_ARGUMENTS", message: "Missing or invalid arguments", details: nil))
        return
      }

      let data = rgba.data
      let colorSpace = CGColorSpaceCreateDeviceRGB()
      guard let provider = CGDataProvider(data: data as CFData),
            let cgImage = CGImage(width: width,
                                  height: height,
                                  bitsPerComponent: 8,
                                  bitsPerPixel: 32,
                                  bytesPerRow: width * 4,
                                  space: colorSpace,
                                  bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
                                  provider: provider,
                                  decode: nil,
                                  shouldInterpolate: true,
                                  intent: .defaultIntent)
      else {
        result(FlutterError(code: "ENCODING_ERROR", message: "Failed to create CGImage", details: nil))
        return
      }

      let quality = (args["quality"] as? Double) ?? 0.7
      let rep = NSBitmapImageRep(cgImage: cgImage)
      guard let jpegData = rep.representation(using: .jpeg, properties: [.compressionFactor: quality]) else {
        result(FlutterError(code: "JPEG_ERROR", message: "Failed to encode JPEG", details: nil))
        return
      }

      result(FlutterStandardTypedData(bytes: jpegData))
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
