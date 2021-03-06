import 'dart:io';

import 'package:binding/binding.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flushbar/flushbar.dart';
import 'package:flutter/material.dart';
import 'package:share/share.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/app_model.dart';
import '../../models/user_model.dart';
import 'list_widget.dart';
import 'timer_widget.dart';
import 'settings_widget.dart';

class UserPage extends StatefulWidget {
  static const routeName = 'user';

  @override
  _UserPageState createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> {
  int _page = 0;
  GlobalKey _bottomNavigationKey = GlobalKey();
  UserModel _passedInModel;
  bool _initialized = false;
  final FirebaseMessaging _fcm = FirebaseMessaging();

  @override
  void initState() {
    _fcm.configure();
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    _passedInModel.cancelSubscription();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialize();
    }
  }

  _initialize() async {
    _passedInModel = ModalRoute.of(context).settings.arguments;
    await _passedInModel.loadUser();
    if (Platform.isIOS) {
      _fcm.requestNotificationPermissions(IosNotificationSettings());
    }
    // Get the token for this device
    String fcmToken = await _fcm.getToken();
    await _passedInModel.addDeviceToken(fcmToken);
    _initialized = true;
  }

  @override
  Widget build(BuildContext context) {
    return BindingSource<UserModel>(
      instance: _passedInModel,
      child: Scaffold(
        appBar: AppBar(
          title: Binding(
            source: _passedInModel,
            path: UserModel.namePropertyName,
            builder: (_, user) => Text(
              user.name,
              style: Theme.of(context).textTheme.headline,
            ),
          ),
          actions: <Widget>[
            IconButton(
              icon: Icon(Icons.share),
              onPressed: () async {
                Share.share(
                    'Patch Me App (https://patchme.app) record key: ${_passedInModel.userId}.');
              },
            ),
            IconButton(
              icon: Icon(Icons.insert_chart),
              onPressed: () async {
                final url =
                    'https://patchme.app/report?id=${_passedInModel.userId}';
                if (await canLaunch(url)) {
                  await launch(url);
                } else {
                  Flushbar(
                    messageText: Text(
                      'Could not launch URL $url',
                      style: TextStyle(fontSize: 18.0, color: Colors.white),
                    ),
                    icon: Icon(
                      Icons.error,
                      size: 28.0,
                      color: Colors.red,
                    ),
                    duration: Duration(seconds: 5),
                    leftBarIndicatorColor: Colors.red,
                  )..show(context);
                }
              },
            ),
            IconButton(
              icon: Icon(Icons.delete),
              onPressed: () async {
                if (await _asyncConfirmDialog(context) == ConfirmAction.YES) {
                  await _passedInModel.removeAllDeviceTokens();
                  BindingSource.of<AppModel>(context)
                      .removeUser(id: _passedInModel.userId);
                  Navigator.of(context).pop();
                }
              },
            )
          ],
        ),
        body: SafeArea(
          child: Binding<UserModel>(
            source: _passedInModel,
            path: UserModel.timerStartTimePropertyName,
            builder: (_, userModel) {
              return AnimatedSwitcher(
                duration: Duration(milliseconds: 500),
                child: _widgetFromIndex(userModel),
              );
            },
          ),
        ),
        bottomNavigationBar: CurvedNavigationBar(
          key: _bottomNavigationKey,
          backgroundColor: Theme.of(context).canvasColor,
          color: Theme.of(context).bottomAppBarColor,
          items: <Widget>[
            Icon(
              Icons.timer,
              size: 30,
              color: Colors.white,
            ),
            Icon(
              Icons.view_list,
              size: 30,
              color: Colors.white,
            ),
            Icon(
              Icons.settings,
              size: 30,
              color: Colors.white,
            ),
          ],
          onTap: (index) {
            setState(() {
              _page = index;
            });
          },
        ),
      ),
    );
  }

  Widget _widgetFromIndex(UserModel userModel) {
    if (userModel.isLoading)
      return Center(
        child: CircularProgressIndicator(),
      );

    switch (_page) {
      case 0:
        return TimerWidget();
      case 1:
        return ListWidget();
      case 2:
        return SettingsWidget();
      default:
        return TimerWidget();
    }
  }

  Future<ConfirmAction> _asyncConfirmDialog(BuildContext context) async {
    final userModel = _passedInModel;

    return showDialog<ConfirmAction>(
      context: context,
      barrierDismissible: false, // user must tap button for close dialog!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Delete Confirmation',
            style: Theme.of(context).textTheme.headline,
          ),
          content: Text(
              'Are you sure you want to delete ${userModel.name}\'s record?'),
          actions: <Widget>[
            FlatButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(ConfirmAction.NO);
              },
            ),
            FlatButton(
              child: const Text('Yes'),
              onPressed: () {
                Navigator.of(context).pop(ConfirmAction.YES);
              },
            )
          ],
        );
      },
    );
  }
}
