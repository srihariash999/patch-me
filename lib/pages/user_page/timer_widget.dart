import 'package:auto_size_text/auto_size_text.dart';
import 'package:binding/binding.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:progress_indicators/progress_indicators.dart';
import '../../models/user_model.dart';

class TimerWidget extends StatelessWidget {
  const TimerWidget({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    final smallestSize = width < height ? width : height;

    final circleRadius = smallestSize > 500.0 ? 400.0 : smallestSize * 0.6;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Center(
          child: Text(
            DateFormat.yMMMMEEEEd().format(DateTime.now()),
            style: Theme.of(context).textTheme.title,
          ),
        ),
        Binding<UserModel>(
          source: BindingSource.of<UserModel>(context),
          path: UserModel.todayTotalTimePropertyName,
          builder: (_, userModel) => CircularPercentIndicator(
            progressColor: Colors.green[400],
            radius: circleRadius,
            lineWidth: 30.0,
            percent: userModel.todayPercentage,
            animation: true,
            animateFromLastPercent: true,
            center: AnimatedSwitcher(
              duration: Duration(milliseconds: 500),
              transitionBuilder: (child, animation) => ScaleTransition(
                child: child,
                scale: animation,
              ),
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 35.0),
                child: (userModel.todayMinutesRemaining >= 0)
                    ? Column(
                        key: ValueKey('underText'),
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                            Center(
                              child: AutoSizeText(
                                '${userModel.todayMinutesRemaining} minutes',
                                style: Theme.of(context).textTheme.headline,
                                maxLines: 1,
                              ),
                            ),
                            Center(
                              child: AutoSizeText(
                                'Remaining',
                                style: Theme.of(context).textTheme.subhead,
                              ),
                            ),
                          ])
                    : Column(
                        key: ValueKey('overText'),
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Center(
                            child: AutoSizeText(
                              'Over by',
                              style: Theme.of(context).textTheme.subhead,
                            ),
                          ),
                          Center(
                            child: AutoSizeText(
                              '${userModel.todayMinutesRemaining.abs()} minutes',
                              style: Theme.of(context).textTheme.headline,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
        Center(
          child: Binding<UserModel>(
            source: BindingSource.of<UserModel>(context),
            path: UserModel.timerStartTimePropertyName,
            builder: (_, userModel) => Container(
              width: circleRadius,
              child: AnimatedSwitcher(
                duration: Duration(milliseconds: 500),
                transitionBuilder: (child, animation) => ScaleTransition(
                  child: child,
                  scale: animation,
                ),
                child: userModel.timerStartTime == null
                    ? RaisedButton(
                        key: ValueKey('startButton'),
                        textColor: Colors.white,
                        onPressed: () async {
                          if (userModel.maxTimeExceededForToday) {
                            await _timerExceededAlert(context);
                            return;
                          }
                          userModel.startTimer();
                        },
                        color: Colors.green[600],
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Icon(Icons.timer),
                            SizedBox(
                              width: 5,
                            ),
                            Text('START'),
                          ],
                        ),
                      )
                    : RaisedButton(
                        key: ValueKey('stopButton'),
                        textColor: Colors.white,
                        onPressed: userModel.stopTimer,
                        color: Colors.red[600],
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            GlowingProgressIndicator(
                              child: Icon(Icons.timer),
                            ),
                            SizedBox(
                              width: 5,
                            ),
                            Text('STOP'),
                          ],
                        ),
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _timerExceededAlert(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Maximum Time'),
          content: const Text(
              'You have patched for the maximum allowed time for today.'),
          actions: <Widget>[
            FlatButton(
              child: Text('Ok'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
