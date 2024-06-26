library social_media_audio_recorder;

import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:social_media_audio_recorder/widget/Flow.dart';
import 'package:social_media_audio_recorder/widget/lottie.dart';

class SocialMediaFilePath {
  SocialMediaFilePath._();

  static init() async {
    final Directory appDocumentsDir = await getApplicationDocumentsDirectory();
    documentPath = "${appDocumentsDir.path}/";
  }

  static String documentPath = '';
}

class RecordButton extends StatefulWidget {
  final AnimationController controller; //animated controller
  final double? timerWidth; // show timer widget with
  final double? lockerHeight; //lock widget height
  final double? size;
  final double? radius;
  final bool? releaseToSend;
  final bool? onlyReleaseButton;
  final Color? color;
  final Color? allTextColor;
  final Color? arrowColor;
  final Color? recordButtonColor;
  final Color? recordBgColor;
  final double? fontSize;
  final String? sliderText;
  final String? stopText;
  final Function(String value, double durationParSec) onRecordEnd;
  final Function onRecordStart;
  final Function onCancelRecord;
  final TextDirection direction;
  const RecordButton(
      {Key? key,
      required this.controller,
      this.releaseToSend = false,
      this.onlyReleaseButton = false,
      this.timerWidth,
      this.lockerHeight = 200,
      this.size = 55,
      this.color = Colors.white,
      this.sliderText,
      this.stopText,
      this.radius = 10,
      this.fontSize = 12,
      required this.onRecordEnd,
      required this.onRecordStart,
      required this.onCancelRecord,
      this.allTextColor,
      this.arrowColor,
      this.recordButtonColor,
      this.recordBgColor,
      this.direction = TextDirection.ltr})
      : super(key: key);

  @override
  State<RecordButton> createState() => _RecordButtonState();
}

class _RecordButtonState extends State<RecordButton> {
  double timerWidth = 0;

  Animation<double>? buttonScaleAnimation;
  Animation<double>? timerAnimation;
  Animation<double>? lockerAnimation;
  bool isPause = false;
  DateTime? startTime;
  Timer? timer;
  String recordDuration = "00:00";
  AudioRecorder? record;

  bool isLocked = false;
  bool showLottie = false;

  @override
  void initState() {
    super.initState();
    //init();
    buttonScaleAnimation = Tween<double>(begin: 1, end: 2).animate(
      CurvedAnimation(
        parent: widget.controller,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticInOut),
      ),
    );
    widget.controller.addListener(() {
      setState(() {});
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    timerWidth =
        (widget.timerWidth ?? MediaQuery.of(context).size.width - 2 * 8 - 4);
    timerAnimation = Tween<double>(begin: timerWidth + 8, end: 0).animate(
      CurvedAnimation(
        parent: widget.controller,
        curve: const Interval(0.2, 1, curve: Curves.easeIn),
      ),
    );
    lockerAnimation =
        Tween<double>(begin: widget.lockerHeight! + 8, end: 0).animate(
      CurvedAnimation(
        parent: widget.controller,
        curve: const Interval(0.2, 1, curve: Curves.easeIn),
      ),
    );
  }

  @override
  void dispose() {
    if (record != null) {
      record?.dispose();
    }
    timer?.cancel();
    timer = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = isLocked ? widget.size! * 2 : widget.size!;
    return Directionality(
      textDirection: widget.direction,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (!widget.onlyReleaseButton!) ...[
            lockSlider(),
            cancelSlider(),
          ],
          widget.onlyReleaseButton!
              ? SizedBox(
                  width: size,
                  height: size,
                  child: Align(
                      alignment: widget.direction == TextDirection.ltr
                          ? Alignment.bottomRight
                          : Alignment.bottomLeft,
                      child: audioButton()))
              : audioButton(),
          if (isLocked)
            ...!widget.onlyReleaseButton!
                ? [timerLocked()]
                : [
                    PositionedDirectional(
                      start: 0,
                      bottom: 10,
                      child: GestureDetector(
                        onTap: stopRecordF,
                        child: Container(
                            height: widget.size! * 0.85,
                            width: widget.size! * 0.85,
                            clipBehavior: Clip.hardEdge,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: widget.recordBgColor ??
                                  Theme.of(context).primaryColor,
                            ),
                            child: Center(
                                child: FaIcon(
                              FontAwesomeIcons.xmark,
                              size: 18,
                              color: widget.recordButtonColor ?? Colors.black,
                            ))),
                      ),
                    ),
                    PositionedDirectional(
                        top: 0,
                        end: 10,
                        child: GestureDetector(
                          onTap: pauseRecordF,
                          child: Container(
                            height: widget.size! * 0.85,
                            width: widget.size! * 0.85,
                            clipBehavior: Clip.hardEdge,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: widget.recordBgColor ??
                                  Theme.of(context).primaryColor,
                            ),
                            child: Center(
                                child: FaIcon(
                              !isPause
                                  ? FontAwesomeIcons.pause
                                  : FontAwesomeIcons.play,
                              size: 18,
                              color: widget.recordButtonColor ?? Colors.black,
                            )),
                          ),
                        )),
                    PositionedDirectional(
                        top: 0,
                        start: 0,
                        child: GestureDetector(
                          onTap: saveRecordF,
                          child: Container(
                              height: widget.size! * 0.85,
                              width: widget.size! * 0.85,
                              clipBehavior: Clip.hardEdge,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: widget.recordBgColor ??
                                    Theme.of(context).primaryColor,
                              ),
                              child: Center(
                                  child: FaIcon(
                                FontAwesomeIcons.check,
                                size: 18,
                                color: widget.recordButtonColor ?? Colors.black,
                              ))),
                        )),
                  ],
        ],
      ),
    );
  }

  Widget lockSlider() {
    return lockerAnimation!.value == 0.0
        ? Positioned(
            bottom: -lockerAnimation!.value,
            child: Container(
              height: widget.lockerHeight,
              width: widget.size!,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(widget.radius!),
                color: widget.color,
              ),
              padding: const EdgeInsets.symmetric(vertical: 15),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  FaIcon(
                    FontAwesomeIcons.lock,
                    size: 20,
                    color: widget.arrowColor ?? Colors.black,
                  ),
                  const SizedBox(height: 8),
                  FlowShader(
                    direction: Axis.vertical,
                    child: Column(
                      children: [
                        Icon(
                          Icons.keyboard_arrow_up,
                          color: widget.arrowColor ?? Colors.black,
                        ),
                        Icon(
                          Icons.keyboard_arrow_up,
                          color: widget.arrowColor ?? Colors.black,
                        ),
                        Icon(
                          Icons.keyboard_arrow_up,
                          color: widget.arrowColor ?? Colors.black,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          )
        : Container();
  }

  Widget cancelSlider() {
    return timerAnimation!.value == timerWidth + 8
        ? const SizedBox()
        : Positioned(
            right: timerAnimation!.value == timerWidth + 8
                ? MediaQuery.of(context).size.width
                : -timerAnimation!.value,
            child: Container(
              height: widget.size!,
              width: timerWidth,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(widget.radius!),
                color: widget.color,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    showLottie
                        ? const LottieAnimation()
                        : Text(recordDuration,
                            style: TextStyle(
                              color: widget.allTextColor ?? Colors.black,
                              fontSize: widget.fontSize,
                              decoration: TextDecoration.none,
                            )),
                    SizedBox(width: widget.size!),
                    FlowShader(
                      duration: const Duration(seconds: 3),
                      flowColors: const [Colors.white, Colors.grey],
                      child: Row(
                        children: [
                          Icon(Icons.keyboard_arrow_left,
                              color: widget.allTextColor ?? Colors.black),
                          Text(
                            widget.sliderText ?? "Slide to cancel",
                            style: TextStyle(
                              color: widget.allTextColor ?? Colors.black,
                              fontSize: widget.fontSize,
                              decoration: TextDecoration.none,
                            ),
                          )
                        ],
                      ),
                    ),
                    SizedBox(width: widget.size!),
                  ],
                ),
              ),
            ),
          );
  }

  Widget timerLocked() {
    return Container(
      height: widget.size!,
      width: timerWidth,
      decoration: BoxDecoration(
        borderRadius:
            BorderRadius.circular(widget.radius == null ? 10 : widget.radius!),
        color: widget.color,
      ),
      child: Padding(
        padding: const EdgeInsets.only(left: 20, right: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          mainAxisSize: MainAxisSize.max,
          children: [
            stopButton(),
            recordDurationWidget(),
            pausebutton(),
            checkButton(),
          ],
        ),
      ),
    );
  }

  Text recordDurationWidget({Color? color}) {
    return Text(recordDuration,
        style: TextStyle(
          color: color ?? widget.allTextColor ?? Colors.black,
          fontSize: widget.fontSize,
          decoration: TextDecoration.none,
        ));
  }

  GestureDetector stopButton() {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: stopRecordF,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: FaIcon(
          FontAwesomeIcons.xmark,
          size: 18,
          color: widget.onlyReleaseButton! ? Colors.white : Colors.red,
        ),
      ),
    );
  }

  void stopRecordF() async {
    log("Cancelled recording");
    if (!Platform.isWindows) Vibrate.feedback(FeedbackType.heavy);

    timer?.cancel();
    timer = null;
    startTime = null;
    recordDuration = "00:00";
    setState(() {
      isLocked = false;
      showLottie = true;
    });
    widget.onCancelRecord();

    Timer(const Duration(milliseconds: 1440), () async {
      widget.controller.reverse();
      debugPrint("Cancelled recording");
      var filePath = await record!.stop();

      File(filePath!).delete();

      showLottie = false;
    });
  }

  GestureDetector pausebutton() {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: pauseRecordF,
      child: AbsorbPointer(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: FaIcon(
              !isPause ? FontAwesomeIcons.pause : FontAwesomeIcons.play,
              size: 18,
              color: widget.onlyReleaseButton!
                  ? Colors.white
                  : widget.allTextColor ?? Colors.black,
            ),
          ),
        ),
      ),
    );
  }

  void pauseRecordF() async {
    log("pause recording");
    if (!Platform.isWindows) Vibrate.feedback(FeedbackType.success);

    isPause ? await record?.resume() : await record?.pause(); //Record file

    setState(() {
      isPause = !isPause;
    });
  }

  GestureDetector checkButton() {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: saveRecordF,
      child: AbsorbPointer(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: FaIcon(
              FontAwesomeIcons.check,
              size: 18,
              color: widget.onlyReleaseButton! ? Colors.white : Colors.green,
            ),
          ),
        ),
      ),
    );
  }

  void saveRecordF() async {
    if (!Platform.isWindows) Vibrate.feedback(FeedbackType.success);
    final secDur = durationFromString(recordDuration).inSeconds % 60;
    log("check recording $secDur");

    timer?.cancel();
    timer = null;
    startTime = null;
    recordDuration = "00:00";

    var filePath = await record?.stop(); //Record file

    setState(() {
      isLocked = false;

      widget.onRecordEnd(filePath!, secDur.toDouble());
    });
  }

  Duration durationFromString(String durationString) {
    List<String> parts = durationString.split(':');
    int minutes = int.parse(parts[0]);
    int seconds = int.parse(parts[1]);

    return Duration(minutes: minutes, seconds: seconds);
  }

  Widget audioButton() {
    return GestureDetector(
      onLongPressDown: (_) {
        debugPrint("onLongPressDown");
        if (!widget.onlyReleaseButton!) widget.controller.forward();
      },
      onLongPressEnd:
          widget.onlyReleaseButton ?? false ? null : onLongPressEndF,
      onLongPressCancel: () {
        debugPrint("onLongPressCancel");
        if (!widget.onlyReleaseButton!) widget.controller.reverse();
      },
      onTap: widget.onlyReleaseButton ?? false ? startRecordF : null,
      onLongPress: startRecordF,
      child: Transform.scale(
        scale: widget.onlyReleaseButton! ? 1 : buttonScaleAnimation!.value,
        child: Container(
          height: widget.size!,
          width: widget.size!,
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.recordBgColor ?? Theme.of(context).primaryColor,
          ),
          child: widget.onlyReleaseButton! && timer != null
              ? Center(
                  child: recordDurationWidget(
                      color: widget.recordButtonColor ?? Colors.black))
              : Icon(
                  Icons.mic,
                  color: widget.recordButtonColor ?? Colors.black,
                ),
        ),
      ),
    );
  }

  void onLongPressEndF(details) async {
    if (widget?.onlyReleaseButton ?? false) return;
    if (isCancelled(details.localPosition, context) &&
        !widget.onlyReleaseButton!) {
      if (!Platform.isWindows) Vibrate.feedback(FeedbackType.heavy);

      timer?.cancel();
      timer = null;
      startTime = null;
      recordDuration = "00:00";
      setState(() {
        showLottie = true;
      });
      widget.onCancelRecord();

      Timer(const Duration(milliseconds: 1440), () async {
        widget.controller.reverse();
        debugPrint("Cancelled recording");
        var filePath = await record?.stop() ?? "";

        File(filePath!).delete();

        showLottie = false;
      });
    } else if (checkIsLocked(details.localPosition) &&
        !widget.onlyReleaseButton!) {
      widget.controller.reverse();
      if (!Platform.isWindows) Vibrate.feedback(FeedbackType.heavy);
      debugPrint("Locked recording");
      debugPrint(details.localPosition.dy.toString());
      setState(() {
        isLocked = true;
      });
      widget.onRecordStart();
    } else {
      widget.controller.reverse();
      if (!Platform.isWindows) Vibrate.feedback(FeedbackType.success);
      final secDur = durationFromString(recordDuration).inSeconds % 60;

      timer?.cancel();
      timer = null;
      startTime = null;
      recordDuration = "00:00";
      var filePath = await record?.stop() ?? "";

      if (widget.releaseToSend!) {
        widget.onRecordEnd(filePath!, secDur.toDouble());
      } else {
        widget.onCancelRecord();
      }
    }
  }

  void startRecordF() async {
    debugPrint("onTap");
    if (!Platform.isWindows) Vibrate.feedback(FeedbackType.success);
    final hasPermission =
        Platform.isWindows ? true : await AudioRecorder().hasPermission();
    debugPrint("hasPermission $hasPermission");
    if (hasPermission && timer == null) {
      widget.onRecordStart();

      record = AudioRecorder();
      final pathFileAudio =
          "${SocialMediaFilePath.documentPath}audio_${DateTime.now().millisecondsSinceEpoch}.wav";
      debugPrint("pathFileAudio $pathFileAudio");
      setState(() {
        isPause = false;
        if (widget.onlyReleaseButton!) isLocked = true;
      });
      await record?.start(const RecordConfig(encoder: AudioEncoder.wav),
          path: pathFileAudio);
      startTime = DateTime.now();
      var seconds = 0;
      var minutes = 0;
      timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!isPause) {
          setState(() {
            if (seconds < 59) {
              seconds++;
            } else {
              seconds = 0;
              minutes++;
            }
            recordDuration =
                '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
          });
        }
      });
    }
  }

  bool checkIsLocked(Offset offset) {
    return (offset.dy < -35);
  }

  bool isCancelled(Offset offset, BuildContext context) {
    return (offset.dx < -(MediaQuery.of(context).size.width * 0.2));
  }
}
