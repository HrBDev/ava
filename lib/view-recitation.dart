import 'package:after_layout/after_layout.dart';
import 'package:ava/calbacks/g-ui-callbacks.dart';
import 'package:ava/models/recitation/PublicRecitationViewModel.dart';
import 'package:ava/widgets/audio-player-widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:url_launcher/url_launcher.dart';

class ViewRecitation extends StatefulWidget {
  final PublicRecitationViewModel narration;
  final LoadingStateChanged loadingStateChanged;
  final SnackbarNeeded snackbarNeeded;

  const ViewRecitation(
      {Key key, this.narration, this.loadingStateChanged, this.snackbarNeeded})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => _ViewRecitationState(
      this.narration, this.loadingStateChanged, this.snackbarNeeded);
}

class _ViewRecitationState extends State<ViewRecitation>
    with AfterLayoutMixin<ViewRecitation> {
  final PublicRecitationViewModel narration;
  final LoadingStateChanged loadingStateChanged;
  final SnackbarNeeded snackbarNeeded;

  AudioPlayer _player;

  _ViewRecitationState(
      this.narration, this.loadingStateChanged, this.snackbarNeeded);

  TextEditingController _titleController = TextEditingController();
  TextEditingController _artistNameController = TextEditingController();
  String _fileDownloadTitle = '';

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.black,
    ));
  }

  @override
  void dispose() {
    _player.dispose();
    _titleController.dispose();
    _artistNameController.dispose();

    super.dispose();
  }

  String getVerse(PublicRecitationViewModel narration, Duration position) {
    if (position == null || narration == null || narration.verses == null) {
      return '';
    }
    var verse = narration.verses.lastWhere(
        (element) => element.audioStartMilliseconds <= position.inMilliseconds);
    if (verse == null) {
      return '';
    }
    return verse.verseText;
  }

  @override
  void afterFirstLayout(BuildContext context) {}

  @override
  Widget build(BuildContext context) {
    _titleController.text = narration.poemFullTitle;
    _artistNameController.text = narration.audioArtist;
    _fileDownloadTitle = 'دریافت فایل صوتی با حجم ' +
        (narration.mp3SizeInBytes / (1024 * 1024)).toStringAsFixed(2) +
        ' مگابایت';

    return FocusTraversalGroup(
        child: Form(
            autovalidateMode: AutovalidateMode.always,
            child: Wrap(children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextFormField(
                    controller: _titleController,
                    readOnly: true,
                    decoration: InputDecoration(
                        labelText: 'متن مرتبط',
                        hintText: 'متن مرتبط',
                        prefixIcon: IconButton(
                          icon: Icon(Icons.open_in_browser),
                          onPressed: () async {
                            var url =
                                'https://ganjoor.net' + narration.poemFullUrl;
                            if (await canLaunch(url)) {
                              await launch(url);
                            } else {
                              throw 'خطا در نمایش نشانی $url';
                            }
                          },
                        ))),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextFormField(
                    controller: _artistNameController,
                    readOnly: true,
                    decoration: InputDecoration(
                        labelText: 'به خوانش',
                        hintText: 'به خوانش',
                        prefixIcon: IconButton(
                          icon: Icon(Icons.open_in_browser),
                          onPressed: () async {
                            var url = narration.audioArtistUrl;
                            if (await canLaunch(url)) {
                              await launch(url);
                            } else {
                              throw 'خطا در نمایش نشانی $url';
                            }
                          },
                        ))),
              ),
              SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ControlButtons(_player, narration, this.loadingStateChanged,
                        this.snackbarNeeded),
                    StreamBuilder<Duration>(
                      stream: _player.durationStream,
                      builder: (context, snapshot) {
                        final duration = snapshot.data ?? Duration.zero;
                        return StreamBuilder<Duration>(
                          stream: _player.positionStream,
                          builder: (context, snapshot) {
                            var position = snapshot.data ?? Duration.zero;
                            if (position > duration) {
                              position = duration;
                            }
                            return Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SeekBar(
                                    duration: duration,
                                    position: position,
                                    onChangeEnd: (newPosition) {
                                      _player.seek(newPosition);
                                    },
                                  ),
                                  Text(getVerse(narration, position))
                                ]);
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
              Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ButtonBar(
                    alignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton(
                        child: Text(_fileDownloadTitle),
                        onPressed: () async {
                          var url = narration.mp3Url;
                          if (await canLaunch(url)) {
                            await launch(url);
                          } else {
                            throw 'خطا در نمایش نشانی $url';
                          }
                        },
                      ),
                      TextButton(
                        child: Text('انصراف'),
                        onPressed: () {
                          Navigator.of(context).pop(null);
                        },
                      )
                    ],
                  )),
            ])));
  }
}
