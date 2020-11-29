import Flutter
import UIKit
import FBSDKShareKit
import Photos
import MessageUI

@available(iOS 10.0, *)
public class SwiftFlutterSocialContentSharePlugin: NSObject, FlutterPlugin {
    var result: FlutterResult?
    var shareURL:String?
    
    //MARK: PLUGIN REGISTRATION
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "social_share", binaryMessenger: registrar.messenger())
        let instance = SwiftFlutterSocialContentSharePlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    //MARK: FLUTTER HANDLER CALL
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        self.result = result
        guard let arguments = call.arguments as? [String:Any] else {
            self.result?("Error getting arguments")
            return
        }
        
        if call.method == "getPlatformVersion" {
            result("iOS " + UIDevice.current.systemVersion)
            
        } else if call.method == "shareOnFacebook" {
            
            shareOnFacebook(withQuote: arguments["quote"] as? String ?? "",
                            withUrl: arguments["url"] as? String ?? "")
            
        } else if call.method == "shareOnInstagram" {
            
            let shareImageUrl = arguments["imageUrl"] as? String ?? ""
            
            self.result?(shareImageUrl)
            let url = URL(string: shareImageUrl)
            if let urlData = url {
                let data = try? Data(contentsOf: urlData)
                if let datas = data {
                    shareInstagramWithImageUrl(image: UIImage(data: datas) ?? UIImage()) { (flag) in
                    }
                } else{
                    self.result?("Something went wrong")
                }
            } else {
                self.result?("Could not load the image")
            }
            
        } else if call.method == "shareOnWhatsapp" {
            
            let number = arguments["number"] as? String ?? ""
            let text = arguments["text"] as? String ?? ""
            shareWhatsapp(withNumber: number, withTxtMsg: text)
            
        } else if call.method == "shareOnSMS" {
            
            let recipients = arguments["recipients"] as? [String] ?? []
            let text = arguments["text"] as? String ?? ""
            sendMessage(withRecipient: recipients,withTxtMsg: text)
            
        } else if call.method == "shareOnEmail" {
            
            let recipients = arguments["recipients"] as? [String] ?? []
            let ccrecipients = arguments["ccrecipients"] as? [String] ?? []
            let bccrecipients = arguments["bccrecipients"] as? [String] ?? []
            let subject = arguments["subject"] as? String ?? ""
            let body = arguments["body"] as? String ?? ""
            let isHTML = arguments["isHTML"] as? Bool ?? false
            sendEmail(withRecipient: recipients, withCcRecipient: ccrecipients, withBccRecipient: bccrecipients, withBody: body, withSubject: subject, withisHTML: isHTML)
            result(NSNumber(value: true))
            
        } else if call.method == "copyToClipboard" {
            
            let content = arguments["content"] as? String
            let pasteBoard = UIPasteboard.general
            pasteBoard.string = content
            result(NSNumber(value: true))
            
        } else if call.method == "shareOnSnapchat" {
            
            //TODO
            result("Not implemented")
            
        } else if call.method == "shareOnTwitter" {
            
            let captionText = arguments["captionText"] as? String
            let urlString = arguments["url"] as? String
            
            let urlTextEscaped = urlString?.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)
            
            let url = URL(string: urlTextEscaped ?? "")
            
            if (url?.absoluteString.count ?? 0) == 0 {
                let urlSchemeTwitter = "twitter://post?message=\(captionText)"
                let urlSchemeSend = URL(string: urlSchemeTwitter)
                if let urlSchemeSend = urlSchemeSend {
                    UIApplication.shared.open(urlSchemeSend, options: [:], completionHandler: nil)
                }
                result("sharing")
            } else {
                let urlSchemeSms = "twitter://post?message=\(captionText)"
                let urlWithLink = urlSchemeSms + (url?.absoluteString ?? "")
                let urlSchemeMsg = URL(string: urlWithLink)
                
                if let urlSchemeMsg = urlSchemeMsg {
                    UIApplication.shared.open(urlSchemeMsg, options: [:], completionHandler: nil)
                }
                result("sharing")
            }
        } else if call.method == "shareOnTelegram" {
            
            let content = arguments["content"] as? String
            let urlScheme = "tg://msg?text=\(content ?? "")"
            let telegramURL = URL(string: (urlScheme as NSString).addingPercentEscapes(using: String.Encoding.utf8.rawValue) ?? "")
            if let telegramURL = telegramURL {
                if UIApplication.shared.canOpenURL(telegramURL) {
                    UIApplication.shared.openURL(telegramURL)
                    result(("sharing"))
                } else {
                    result(("cannot open Telegram"))
                }
            }
            result(NSNumber(value: true))
            
        } else if call.method == "shareOptions" {
            let content = arguments["content"] as? String
            let image = arguments["imagePath"] as? String
            if let image = image {
                let fileManager = FileManager.default
                let isFileExist = fileManager.fileExists(atPath: image)
                var imgShare: UIImage?
                if isFileExist {
                    imgShare = UIImage(contentsOfFile: image)
                }
                let objectsToShare = [content, imgShare] as [Any]
                let activityVC = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)
                let controller = UIApplication.shared.keyWindow?.rootViewController
                controller?.present(activityVC, animated: true)
                result(NSNumber(value: true))
            } else {
                let objectsToShare = [content]
                let activityVC = UIActivityViewController(activityItems: objectsToShare.compactMap { $0 }, applicationActivities: nil)
                let controller = UIApplication.shared.keyWindow?.rootViewController
                controller?.present(activityVC, animated: true)
                result(NSNumber(value: true))
            }
        } else if "checkInstalledApps" == call.method {
            var installedApps: [AnyHashable : Any] = [:]
            
            //Enable checks below when instagram and snapchat sharing is implemented
            installedApps["instagram"] = NSNumber(value: false)
            installedApps["snapchat"] = NSNumber(value: false)
            
            //installedApps["instagram"] = isInstalled(url: "instagram://")
            //installedApps["snapchat"] = isInstalled(url: "snapchat://")
            
            installedApps["facebook"] = isInstalled(url: "facebook://")
            installedApps["twitter"] = isInstalled(url: "twitter://")
            installedApps["sms"] = isInstalled(url: "sms://")
            installedApps["whatsapp"] = isInstalled(url: "whatsapp://")
            installedApps["telegram"] = isInstalled(url: "tg://")
            
            result(installedApps);
        } else {
            result(FlutterMethodNotImplemented);
        }
    }
    
    private func isInstalled(url: String) -> NSNumber {
        if let url = URL(string: url) {
            return UIApplication.shared.canOpenURL(url) ? NSNumber(value: true) : NSNumber(value: false)
        }
        return NSNumber(value: false)
    }
    
    private func shareOnFacebook(withQuote quote: String?, withUrl urlString: String?) {
        DispatchQueue.main.async {
            let shareContent = ShareLinkContent()
            let shareDialog = ShareDialog()
            if let url = urlString {
                shareContent.contentURL = URL.init(string: url)!
            }
            if let quoteString = quote {
                shareContent.quote = quoteString.htmlToString
            }
            shareDialog.shareContent = shareContent
            if let flutterAppDelegate = UIApplication.shared.delegate as? FlutterAppDelegate {
                shareDialog.fromViewController = flutterAppDelegate.window.rootViewController
                shareDialog.mode = .automatic
                shareDialog.show()
                self.result?("Success")
            } else{
                self.result?("Failure")
            }
        }
    }
    
    private func shareInstagramWithImageUrl(image: UIImage, result:((Bool)->Void)? = nil) {
        guard let instagramURL = NSURL(string: "instagram://app") else {
            if let result = result {
                self.result?("Instagram app is not installed on your device")
                result(false)
            }
            return
        }
        
        //Save image on device
        do {
            try PHPhotoLibrary.shared().performChangesAndWait({
                let request = PHAssetChangeRequest.creationRequestForAsset(from: image)
                let assetID = request.placeholderForCreatedAsset?.localIdentifier ?? ""
                self.shareURL = "instagram://library?LocalIdentifier=" + assetID
            })
        } catch {
            if let result = result {
                self.result?("Failure")
                result(false)
            }
        }
        
        //Share image
        if UIApplication.shared.canOpenURL(instagramURL as URL) {
            if let sharingUrl = self.shareURL {
                if let urlForRedirect = NSURL(string: sharingUrl) {
                    UIApplication.shared.open(urlForRedirect as URL, options: [:], completionHandler: nil)
                }
                self.result?("Success")
            }
        } else{
            self.result?("Something went wrong")
        }
    }
    
    func shareWhatsapp(withNumber number: String, withTxtMsg txtMsg: String){
        let urlString = txtMsg.htmlToString
        let urlStringEncoded = urlString.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlQueryAllowed)
        let appURL  = NSURL(string: "whatsapp://send?phone=\(String(describing: number))&text=\(urlStringEncoded!)")
        if UIApplication.shared.canOpenURL(appURL! as URL) {
            UIApplication.shared.open(appURL! as URL, options: [:], completionHandler: nil)
            self.result?("Success")
        }
        else {
            self.result?("Whatsapp app is not installed on your device")
        }
    }
    
    func sendMessage(withRecipient recipent: [String],withTxtMsg txtMsg: String) {
        let string = txtMsg
        if (MFMessageComposeViewController.canSendText()) {
            self.result?("Success")
            let controller = MFMessageComposeViewController()
            controller.body = string.htmlToString
            controller.recipients = recipent
            controller.messageComposeDelegate = self
            UIApplication.shared.keyWindow?.rootViewController?.present(controller, animated: true, completion: nil)
        } else {
            self.result?("Message service is not available")
        }
    }
    
    func sendEmail(withRecipient recipent: [String], withCcRecipient ccrecipent: [String],withBccRecipient bccrecipent: [String],withBody body: String, withSubject subject: String, withisHTML isHTML:Bool ) {
        if MFMailComposeViewController.canSendMail() {
            let mail = MFMailComposeViewController()
            mail.mailComposeDelegate = self
            mail.setSubject(subject)
            mail.setMessageBody(body, isHTML: isHTML)
            mail.setToRecipients(recipent)
            mail.setCcRecipients(ccrecipent)
            mail.setBccRecipients(bccrecipent)
            UIApplication.shared.keyWindow?.rootViewController?.present(mail, animated: true, completion: nil)
        } else {
            self.result?("Mail services are not available")
        }
    }
}

extension String {
    var htmlToAttributedString: NSAttributedString? {
        guard let data = data(using: .utf8) else { return NSAttributedString() }
        do {
            return try NSAttributedString(data: data, options: [.documentType: NSAttributedString.DocumentType.html, .characterEncoding:String.Encoding.utf8.rawValue], documentAttributes: nil)
        } catch {
            return NSAttributedString()
        }
    }
    var htmlToString: String {
        return htmlToAttributedString?.string ?? ""
    }
}

//MARK: MFMessageComposeViewControllerDelegate
@available(iOS 10.0, *)
extension SwiftFlutterSocialContentSharePlugin:MFMessageComposeViewControllerDelegate{
    
    public func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
        let map: [MessageComposeResult: String] = [
            MessageComposeResult.sent: "sent",
            MessageComposeResult.cancelled: "cancelled",
            MessageComposeResult.failed: "failed",
        ]
        if let callback = self.result {
            callback(map[result])
        }
        UIApplication.shared.keyWindow?.rootViewController?.dismiss(animated: true, completion: nil)
    }
}


//MARK: MFMailComposeViewControllerDelegate
@available(iOS 10.0, *)
extension SwiftFlutterSocialContentSharePlugin: MFMailComposeViewControllerDelegate{
    public func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        UIApplication.shared.keyWindow?.rootViewController?.dismiss(animated: true, completion: nil)
    }
}
