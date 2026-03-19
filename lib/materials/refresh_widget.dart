import 'dart:async';

import 'package:flutter/cupertino.dart';

class RefreshWidget extends StatefulWidget {
  const RefreshWidget(
      {super.key, required this.builder, required this.refreshDuration, this.onRefresh});

  final Widget Function(BuildContext) builder;
  final void Function()? onRefresh;
  final Duration refreshDuration;

  @override
  State<RefreshWidget> createState() => _RefreshWidgetState();
}

class _RefreshWidgetState extends State<RefreshWidget> with WidgetsBindingObserver {
  late Timer _timer;

  @override
  void initState(){
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startTimer();
  }

  void _startTimer(){
    _timer = Timer.periodic(widget.refreshDuration, (_){
      setState(() => widget.onRefresh?.call());
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state){
    if(state == AppLifecycleState.resumed){
      setState(() => widget.onRefresh?.call());
    }
  }

  @override
  void dispose(){
    _timer.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context);
}
