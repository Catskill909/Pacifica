import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'webview.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final handler = await AudioService.init(
    builder: () => AudioPlayerHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.example.myapp.channel.audio',
      androidNotificationChannelName: 'Audio playback',
      androidNotificationOngoing: true,
    ),
  );
  runApp(MyApp(handler: handler));
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Future.delayed(const Duration(seconds: 3), () {
      Navigator.pushReplacementNamed(context, '/home');
    });
    return Scaffold(
      backgroundColor: Colors.black,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent),
        child: Center(child: Image.asset('assets/kpft.png', width: 200)),
      ),
    );
  }
}

class AudioPlayerHandler extends BaseAudioHandler {
  final _player = AudioPlayer();
  late MediaItem _mediaItem;

  AudioPlayerHandler() {
    _player.playbackEventStream.listen(_broadcastState);
    _setInitialMediaItem();
  }

  void _broadcastState(PlaybackEvent event) {
    final playing = _player.playing;
    playbackState.add(playbackState.value.copyWith(
      controls: [if (playing) MediaControl.pause else MediaControl.play],
      androidCompactActionIndices: [0],
      processingState: {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[_player.processingState]!,
      playing: playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      queueIndex: event.currentIndex,
    ));
    mediaItem.add(_mediaItem);
  }

  Future<void> _setInitialMediaItem() async {
    _mediaItem = MediaItem(
      id: "https://streams.pacifica.org:9000/live_64",
      album: "Live on the air",
      title: "KPFT 90.1 FM",
      artist: "Houston's Community Station",
      duration: const Duration(milliseconds: 5739820),
      artUri: Uri.parse("https://kpft.org/wp-content/uploads/2022/01/kpft.png"),
    );
    await setMediaItem(_mediaItem);
  }

  @override
  Future<void> play() async {
    if (_player.processingState == ProcessingState.idle || _player.processingState == ProcessingState.completed) {
      await _player.setUrl(_mediaItem.id);
    }
    await _player.play();
  }

  @override
  Future<void> pause() async {
    await _player.pause();
  }

  @override
  Future<void> stop() async {
    await _player.stop();
    await playbackState.first;
    playbackState.add(playbackState.value.copyWith(
      controls: [],
      processingState: AudioProcessingState.idle,
      playing: false,
    ));
  }

  Future<void> setMediaItem(MediaItem mediaItem) async {
    await _player.setUrl(mediaItem.id);
    _mediaItem = mediaItem.copyWith(duration: await _player.durationFuture);
    _broadcastState(_player.playbackEvent);
  }
}

class MyApp extends StatelessWidget {
  final AudioPlayerHandler handler;

  const MyApp({Key? key, required this.handler}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/home': (context) => MyHomePage(handler: handler),
      },
    );
  }
}

class MyHomePage extends StatelessWidget {
  final AudioPlayerHandler handler;

  const MyHomePage({Key? key, required this.handler}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    return Scaffold(
      appBar: CustomNavBar(mediaQuery: mediaQuery, onInfoPressed: () {}),
      body: SafeArea(
        child: Column(
          children: [
            const Flexible(
              flex: 8,
              child: CustomWebView(url: 'https://starkey.digital/app/'),
            ),
            Flexible(
              flex: 2,
              child: AudioControls(handler: handler),
            ),
          ],
        ),
      ),
      backgroundColor: const Color(0xFFB81717),
    );
  }
}

class AudioControls extends StatelessWidget {
  final AudioPlayerHandler handler;

  const AudioControls({Key? key, required this.handler}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: handler.playbackState.map((state) => state.playing).distinct(),
      builder: (context, snapshot) {
        final playing = snapshot.data ?? false;
        return GestureDetector(
          onTap: () => playing ? handler.pause() : handler.play(),
          child: Container(
            width: 90.0,
            height: 90.0,
            decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.black),
            child: Icon(playing ? Icons.pause : Icons.play_arrow, color: Colors.white, size: 70.0),
          ),
        );
      },
    );
  }
}

class CustomNavBar extends StatelessWidget implements PreferredSizeWidget {
  final Function() onInfoPressed;
  final MediaQueryData mediaQuery;

  const CustomNavBar({Key? key, required this.onInfoPressed, required this.mediaQuery}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(top: mediaQuery.padding.top),
      decoration: const BoxDecoration(gradient: LinearGradient(colors: [Colors.black, Colors.black87], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
      child: Padding(
        padding: const EdgeInsets.only(top: 0.0, bottom: 0.0),
        child: Row(
          children: [
            IconButton(icon: const Icon(Icons.info, color: Colors.white), onPressed: onInfoPressed, iconSize: 36),
            const Expanded(child: SizedBox()),
            CachedNetworkImage(imageUrl: "https://kpft.org/wp-content/uploads/2022/01/kpft.png", width: 70, height: 70, fit: BoxFit.contain),
            const Expanded(child: SizedBox()),
            const SizedBox(width: 48),
          ],
        ),
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight + mediaQuery.padding.top);
}
