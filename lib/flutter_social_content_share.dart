import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class FlutterSocialContentShare {
  static const MethodChannel _channel = const MethodChannel('social_share');

  static Future<String> get platformVersion async {
    return await _channel.invokeMethod('getPlatformVersion');
  }

  static Future<String> shareOnWhatsapp({
    String number,
    @required String text,
  }) async {
    final Map<String, dynamic> params = <String, dynamic>{
      "number": number,
      "text": text
    };
    return await _channel.invokeMethod('shareOnWhatsapp', params);
  }

  static Future<String> shareOnSMS({
    List recipients,
    @required String text,
  }) async {
    final Map<String, dynamic> params = <String, dynamic>{
      "recipients": recipients,
      "text": text
    };
    return await _channel.invokeMethod('shareOnSMS', params);
  }

  static Future<String> shareOnEmail(
      {List recipients,
      List ccrecipients,
      List bccrecipients,
      String subject,
      @required String body,
      bool isHTML}) async {
    final Map<String, dynamic> params = <String, dynamic>{
      "recipients": recipients,
      "subject": subject,
      "ccrecipients": ccrecipients,
      "bccrecipients": bccrecipients,
      "body": body,
      "isHTML": isHTML,
    };
    return await _channel.invokeMethod('shareOnEmail', params);
  }

  static Future<String> shareOnFacebook({
    @required String url,
    String quote,
  }) async {
    final Map<String, dynamic> params = <String, dynamic>{
      "quote": quote,
      "url": url,
    };
    return await _channel.invokeMethod('shareOnFacebook', params);
  }

  static Future<String> shareOnInstagram({
    @required String filePath,
  }) async {
    final Map<String, dynamic> params = <String, dynamic>{
      "filePath": filePath,
    };
    return await _channel.invokeMethod('shareOnInstagram', params);
  }

  static Future<bool> copyToClipboard({
    @required String content,
  }) async {
    final Map<String, String> args = <String, String>{
      "content": content.toString()
    };
    final bool response = await _channel.invokeMethod('copyToClipboard', args);
    return response;
  }

  static Future<String> shareOnSnapchat({
    @required String filePath,
  }) async {
    final Map<String, dynamic> args = <String, dynamic>{
      "filePath": filePath,
    };
    return await _channel.invokeMethod('shareOnSnapchat', args);
  }

  static Future<String> shareOnTwitter({
    String captionText,
    String url,
  }) async {
    String modifiedUrl;

    if (Platform.isAndroid) {
      if (url != null) {
        modifiedUrl = Uri.parse(url).toString().replaceAll('#', "%23");
      }
    } else {
      modifiedUrl = Uri.parse(url).toString();
    }

    Map<String, dynamic> args = <String, dynamic>{
      "captionText": Uri.parse(captionText + " ").toString(),
      "url": modifiedUrl,
    };
    return await _channel.invokeMethod('shareOnTwitter', args);
  }

  static Future<String> shareOnTelegram({
    @required String content,
  }) async {
    final Map<String, dynamic> args = <String, dynamic>{"content": content};
    final String version = await _channel.invokeMethod('shareOnTelegram', args);
    return version;
  }

  static Future<bool> shareOptions({
    @required String contentText,
    String imagePath,
  }) async {
    Map<String, dynamic> args;
    if (Platform.isIOS) {
      args = <String, dynamic>{
        "imagePath": imagePath,
        "content": contentText,
      };
    } else {
      if (imagePath != null) {
        File file = File(imagePath);
        Uint8List bytes = file.readAsBytesSync();
        var imagedata = bytes.buffer.asUint8List();
        final tempDir = await getTemporaryDirectory();
        String imageName = 'image.png';
        final Uint8List imageAsList = imagedata;
        final imageDataPath = '${tempDir.path}/$imageName';
        file = await File(imageDataPath).create();
        file.writeAsBytesSync(imageAsList);
        args = <String, dynamic>{"image": imageName, "content": contentText};
      } else {
        args = <String, dynamic>{"image": imagePath, "content": contentText};
      }
    }
    return await _channel.invokeMethod('shareOptions', args);
  }

  static Future<Map> checkInstalledAppsForShare() async {
    return await _channel.invokeMethod('checkInstalledApps');
  }
}
