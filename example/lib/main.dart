import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_social_content_share/flutter_social_content_share.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _platformVersion = 'Unknown';

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String platformVersion;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      platformVersion = await FlutterSocialContentShare.platformVersion;
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Container(
          color: Colors.white,
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Text(
                'Running on: $_platformVersion\n',
                textAlign: TextAlign.center,
              ),
              RaisedButton(
                onPressed: () async {
                  final file =
                      await ImagePicker().getVideo(source: ImageSource.gallery);
                  FlutterSocialContentShare.shareOnSnapchat(filePath: file.path)
                      .then((data) {
                    print(data);
                  });
                },
                child: Text("Share On Snapchat"),
              ),
              RaisedButton(
                onPressed: () async {
                  final file =
                      await ImagePicker().getVideo(source: ImageSource.gallery);
                  FlutterSocialContentShare.shareOnInstagram(
                          filePath: file.path)
                      .then((data) {
                    print(data);
                  });
                },
                child: Text("Share On Instagram"),
              ),
              RaisedButton(
                onPressed: () async {
                  FlutterSocialContentShare.shareOnFacebook(
                          url: 'https://vid.camera')
                      .then((data) {
                    print(data);
                  });
                },
                child: Text("Share on facebook"),
              ),
              RaisedButton(
                onPressed: () async {
                  FlutterSocialContentShare.copyToClipboard(
                    content: "This is Social Share plugin",
                  ).then((data) {
                    print(data);
                  });
                },
                child: Text("Copy to clipboard"),
              ),
              RaisedButton(
                onPressed: () async {
                  FlutterSocialContentShare.shareOnTwitter(
                    captionText: '',
                    url: "https://vid.camera",
                  ).then((data) {
                    print(data);
                  });
                },
                child: Text("Share on twitter"),
              ),
              RaisedButton(
                onPressed: () async {
                  FlutterSocialContentShare.shareOnSMS(
                          text: "This is Social Share Sms example")
                      .then((data) {
                    print(data);
                  });
                },
                child: Text("Share on Sms"),
              ),
              RaisedButton(
                onPressed: () async {
                  FlutterSocialContentShare.shareOnWhatsapp(
                          text: "Hello World \n https://google.com")
                      .then((data) {
                    print(data);
                  });
                },
                child: Text("Share on Whatsapp"),
              ),
              RaisedButton(
                onPressed: () async {
                  FlutterSocialContentShare.shareOnTelegram(
                          content: "Hello World \n https://google.com")
                      .then((data) {
                    print(data);
                  });
                },
                child: Text("Share on Telegram"),
              ),
              RaisedButton(
                onPressed: () async {
                  FlutterSocialContentShare.checkInstalledAppsForShare()
                      .then((data) {
                    print(data.toString());
                  });
                },
                child: Text("Get all Apps"),
              ),
              RaisedButton(
                onPressed: () async {
                  FlutterSocialContentShare.shareOptions(
                          contentText: "Hello world")
                      .then((data) {
                    print(data);
                  });
                },
                child: Text("Share Options"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
