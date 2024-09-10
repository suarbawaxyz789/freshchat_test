import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:freshchat_sdk/freshchat_sdk.dart';
import 'package:freshchat_sdk/freshchat_user.dart';

import 'Util.dart';
import 'constants.dart';

Future<dynamic> myBackgroundMessageHandler(RemoteMessage message) async {
  print("Inside background handler");

  //NOTE: Freshchat notification - Initialize Firebase for Android only.
  if (Util.isRegisterFcm) {
    await Firebase.initializeApp();
  }
  handleFreshchatNotification(message.data);
}

void handleFreshchatNotification(Map<String, dynamic> message) async {
  if (await Freshchat.isFreshchatNotification(message)) {
    print("is Freshchat notification");
    Freshchat.handlePushNotification(message);
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  //NOTE: Freshchat notification - Initialize Firebase for Android only.
  if (Util.isRegisterFcm) {
    await Firebase.initializeApp();
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  late StreamSubscription restoreStreamSubscription,
      fchatEventStreamSubscription,
      unreadCountSubscription,
      linkOpenerSubscription,
      notificationClickSubscription,
      userInteractionSubscription;

  @override
  void initState() {
    super.initState();
    Freshchat.init(APPID, APPKEY, DOMAIN, themeName: "MyCustomTheme");
    Freshchat.identifyUser(
      externalId: EXTERNAL_ID,
      restoreId: RESTORE_ID,
    );

    Freshchat.linkifyWithPattern("google", "https://google.com");
    Freshchat.setNotificationConfig(
      notificationInterceptionEnabled: false,
      largeIcon: "large_icon",
      smallIcon: "small_icon",
    );

    var restoreStream = Freshchat.onRestoreIdGenerated;
    restoreStreamSubscription = restoreStream.listen((event) async {
      print("Inside Restore stream: Restore Id generated");
      FreshchatUser user = await Freshchat.getUser;
      String? restoreId = user.getRestoreId();
      if (restoreId != null) {
        print("Restore Id: $restoreId");
        Clipboard.setData(new ClipboardData(text: restoreId));
      } else {
        restoreId = " ";
      }

      ScaffoldMessenger.of(context).showSnackBar(
          new SnackBar(content: new Text("Restore ID copied: $restoreId")));
    });

    initSdk();
  }

  Future<void> initNotification() async {
    //NOTE: Freshchat notification - Initialize Firebase for Android only.
    if (Util.isRegisterFcm) {
      registerFcmToken();

      FirebaseMessaging.instance.onTokenRefresh
          .listen(Freshchat.setPushRegistrationToken);

      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        var data = message.data;
        handleFreshchatNotification(data);
        print("Notification Content: $data");
      });

      FirebaseMessaging.onBackgroundMessage(myBackgroundMessageHandler);
    }
  }

  Future<void> initSdk() async {
    await getUser();
    await initNotification();
    print("test");
  }

  Future<void> getUser() async {
    var user = await Freshchat.getUser;

    user.setFirstName("Dwi");
    user.setLastName("Suarbawa");
    user.setEmail("suarbawaxyz@gmail.com");
    user.setPhone("+62", "85942874616");
    Freshchat.setUser(user);
  }

  void registerFcmToken() async {
    if (Util.isRegisterFcm) {
      String? token = await FirebaseMessaging.instance.getToken();
      print("FCM Token is generated $token");
      Freshchat.setPushRegistrationToken(token!);
    }
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
        actions: [
          IconButton(
              onPressed: () {
                Freshchat.showFAQ();
              },
              icon: Icon(Icons.list_alt))
        ],
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Invoke "debug painting" (press "p" in the console, choose the
          // "Toggle Debug Paint" action from the Flutter Inspector in Android
          // Studio, or the "Toggle Debug Paint" command in Visual Studio Code)
          // to see the wireframe for each widget.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Freshchat.showConversations(
            filteredViewTitle: "Filtered view title test",
          );
        },
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
