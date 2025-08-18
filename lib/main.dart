import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show debugPaintBaselinesEnabled;
import 'package:flutter/services.dart';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/services/connectivity_service.dart';
import 'presentation/bloc/connectivity_cubit.dart';
import 'presentation/widgets/offline_overlay.dart';
import 'presentation/widgets/offline_modal.dart';
import 'widgets/bottom_navigation.dart';
import 'webview.dart';
import 'wordpres.dart'; // Ensure this import is correct for your wordpres.dart file
import 'sheet.dart'; // Import the RadioSheet widget
import 'dart:developer';
import 'dart:async';
import 'ui/responsive.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Disable yellow baseline debug overlay in debug builds only
  assert(() {
    debugPaintBaselinesEnabled = false;
    return true;
  }());
  log('App started');
  final handler = await AudioService.init(
    builder: () => AudioPlayerHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.example.myapp.channel.audio',
      androidNotificationChannelName: 'Audio playback',
      androidNotificationOngoing: true,
    ),
  );

  // Handle app lifecycle for cleanup
  final binding = WidgetsBinding.instance;
  binding.addObserver(AppLifecycleListener(
    onDetach: () async {
      log('App detaching - cleaning up resources');
      await handler.dispose();
    },
  ));

  runApp(MyApp(handler: handler));
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    log('Splash screen initialized');
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        log('Navigating to home screen');
        Navigator.pushReplacementNamed(context, '/home');
      }
    });
  }

  @override
  void didUpdateWidget(covariant SplashScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    log('Splash screen did update widget');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    log('Splash screen did change dependencies');
  }

  @override
  void deactivate() {
    super.deactivate();
    log('Splash screen deactivate');
  }

  @override
  void dispose() {
    super.dispose();
    log('Splash screen dispose');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light
            .copyWith(statusBarColor: Colors.transparent),
        child: Center(child: Image.asset('assets/kpft.png', width: 200)),
      ),
    );
  }
}

class AudioPlayerHandler extends BaseAudioHandler {
  final _player = AudioPlayer();
  late MediaItem _mediaItem;

  static const Map<String, String> streamUrls = {
    'HD1': 'https://streams.pacifica.org:9000/live_64',
    'HD2': 'https://streams.pacifica.org:9000/HD3_128',
    'HD3': 'https://streams.pacifica.org:9000/classic_country',
  };

  late final StreamSubscription<PlaybackEvent> _eventSubscription;

  AudioPlayerHandler() {
    _eventSubscription = _player.playbackEventStream.listen(_broadcastState);
    _setInitialMediaItem();
  }

  Future<void> dispose() async {
    // Stop playback first to prevent event broadcasting during disposal
    await _player.stop();
    await _eventSubscription.cancel();
    await _player.dispose();
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
      id: "HD1",
      album: "Live on the air",
      title: "KPFT HD1",
      artist: "Houston's Community Station",
      duration: const Duration(hours: 24),
      artUri: Uri.parse("https://starkey.digital/app/kpft2.png"),
    );
    await setMediaItem(_mediaItem);
  }

  @override
  Future<void> play() async {
    if (_player.processingState == ProcessingState.idle ||
        _player.processingState == ProcessingState.completed) {
      final streamUrl = streamUrls[_mediaItem.id];
      if (streamUrl != null) {
        await _player.setUrl(streamUrl);
      }
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
    playbackState.add(playbackState.value.copyWith(
      controls: [MediaControl.play],
      processingState: AudioProcessingState.idle,
      playing: false,
      updatePosition: Duration.zero,
      bufferedPosition: Duration.zero,
    ));
  }

  // Prepare current stream without starting playback, so a single Play tap works
  Future<void> prepareCurrent() async {
    final streamUrl = streamUrls[_mediaItem.id];
    if (streamUrl != null) {
      try {
        await _player.setUrl(streamUrl);
        _broadcastState(_player.playbackEvent);
      } catch (_) {
        // ignore prepare errors; user can retry
      }
    }
  }

  Future<void> setMediaItem(MediaItem mediaItem) async {
    final streamUrl = streamUrls[mediaItem.id];
    if (streamUrl != null) {
      await _player.stop();
      await _player.setUrl(streamUrl);
      _mediaItem = mediaItem.copyWith(duration: const Duration(hours: 24));
      _broadcastState(_player.playbackEvent);
      if (_player.playing) {
        await _player.play();
      }
    }
  }
}

class MyApp extends StatelessWidget {
  final AudioPlayerHandler handler;

  const MyApp({super.key, required this.handler});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => ConnectivityCubit(service: ConnectivityService())..initialize(),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        initialRoute: '/',
        theme: ThemeData(
          bottomSheetTheme: const BottomSheetThemeData(
            // Allow bottom sheets to use full available width on large screens
            constraints: BoxConstraints(maxWidth: double.infinity),
            backgroundColor: Colors.black,
          ),
        ),
        routes: {
          '/': (context) => const SplashScreen(),
          '/home': (context) => MyHomePage(handler: handler),
        },
        builder: (context, child) {
          final connState = context.watch<ConnectivityCubit>().state;
          if (connState.firstRun) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted) context.read<ConnectivityCubit>().checkNow();
            });
          }
          // Only show overlay on the home screen, not on the splash screen
          final isSplash = child is SplashScreen;
          if (isSplash) {
            return child;
          }
          return Stack(
            fit: StackFit.expand,
            children: [
              child ?? const SizedBox.shrink(),
              if (!connState.isOnline && !connState.dismissed) const OfflineOverlay(),
            ],
          );
        },
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  final AudioPlayerHandler handler;

  const MyHomePage({super.key, required this.handler});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _currentIndex = 0;
  String _currentWebViewUrl = 'https://starkey.digital/app/';

  static const Map<String, String> webViewUrls = {
    'HD1': 'https://starkey.digital/app/',
    'HD2': 'https://starkey.digital/app2/',
    'HD3': 'https://starkey.digital/app3/',
  };


  void _showWordpressSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.black,
      builder: (BuildContext context) {
        final double topPadding =
            MediaQuery.of(context).padding.top; // Get top safe area height
        final double screenHeight = MediaQuery.of(context).size.height;

        // Adjust this value to control the additional offset from the top
        const double additionalTopOffset = 30; // You can adjust this value

        return SizedBox(
          height: screenHeight -
              topPadding -
              additionalTopOffset, // Subtract additional offset
          child:
              const WordPressIntegrationScreen(), // Your widget from wordpres.dart
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    return BlocListener<ConnectivityCubit, ConnectivityState>(
      listenWhen: (prev, curr) => prev.isOnline != curr.isOnline,
      listener: (context, state) async {
        if (!state.isOnline) {
          // Hard reset audio when network is lost so UI shows Play and player is idle
          await widget.handler.stop();
        } else {
          // When back online, pre-prepare the stream so one Play tap is sufficient
          await widget.handler.prepareCurrent();
        }
      },
      child: Scaffold(
        appBar: CustomNavBar(
          mediaQuery: mediaQuery,
          onInfoPressed: () => _showWordpressSheet(context),
        ),
        body: SafeArea(
          child: Column(
            children: [
              Flexible(
                flex: 8,
                child: CustomWebView(url: _currentWebViewUrl),
              ),
              Flexible(
                flex: 2,
                child: AudioControls(handler: widget.handler),
              ),
            ],
          ),
        ),
        backgroundColor: const Color(0xFFB81717),
        bottomNavigationBar: StreamBottomNavigation(
          currentIndex: _currentIndex,
          onTabChanged: (streamId) {
            setState(() {
              _currentIndex = ['HD1', 'HD2', 'HD3'].indexOf(streamId);
              _currentWebViewUrl = webViewUrls[streamId] ?? _currentWebViewUrl;
            });
            // Update audio stream
            widget.handler.setMediaItem(MediaItem(
              id: streamId,
              title: 'KPFT $streamId',
              artist: "Houston's Community Station",
              artUri: Uri.parse("https://starkey.digital/app/kpft2.png"),
            ));
          },
        ),
      ),
    );
  }
}

class AudioControls extends StatelessWidget {
  final AudioPlayerHandler handler;

  const AudioControls({super.key, required this.handler});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Expanded(child: SizedBox()), // Flexible space above
        StreamBuilder<PlaybackState>(
          stream: handler.playbackState,
          builder: (context, snapshot) {
            final state = snapshot.data;
            final playing = state?.playing ?? false;
            final proc = state?.processingState ?? AudioProcessingState.idle;
            final isLoading = proc == AudioProcessingState.loading || proc == AudioProcessingState.buffering;

            return AbsorbPointer(
              absorbing: isLoading,
              child: GestureDetector(
                onTap: () async {
                  if (!playing) {
                    final isOnline = context.read<ConnectivityCubit>().state.isOnline;
                    if (!isOnline) {
                      showGeneralDialog(
                        context: context,
                        barrierColor: Colors.black54,
                        barrierDismissible: true,
                        pageBuilder: (_, __, ___) => const OfflineModal(),
                      );
                      return;
                    }
                  }
                  playing ? handler.pause() : handler.play();
                },
                child: Container(
                  width: ResponsiveScale.s(context, 90.0),
                  height: ResponsiveScale.s(context, 90.0),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black,
                  ),
                  child: isLoading
                      ? const Center(
                          child: SizedBox(
                            width: 28,
                            height: 28,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              color: Colors.white,
                            ),
                          ),
                        )
                      : Icon(
                          playing ? Icons.pause : Icons.play_arrow,
                          color: Colors.white,
                          size: ResponsiveScale.s(context, 70.0),
                        ),
                ),
              ),
            );
          },
        ),
        const Expanded(child: SizedBox()), // Flexible space below
      ],
    );
  }
}

class CustomNavBar extends StatelessWidget implements PreferredSizeWidget {
  final Function() onInfoPressed;
  final MediaQueryData mediaQuery;

  const CustomNavBar(
      {super.key, required this.onInfoPressed, required this.mediaQuery});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(top: mediaQuery.padding.top - 4),
      decoration: const BoxDecoration(
          gradient: LinearGradient(
              colors: [Colors.black, Colors.black87],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter)),
      child: Padding(
        padding: const EdgeInsets.only(top: 0.0, bottom: 0.0),
        child: Row(
          children: [
            _buildInfoIconButton(),
            const Expanded(child: SizedBox()),
            _buildLogoImage(),
            const Expanded(child: SizedBox()),
            _buildBottomSheetIconButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoIconButton() {
    return IconButton(
      icon: const Icon(Icons.feed, color: Colors.white),
      onPressed: onInfoPressed,
      iconSize: ResponsiveScale.sFromMq(mediaQuery, 40),
      padding: EdgeInsets.zero,
    );
  }

  Widget _buildLogoImage() {
    return CachedNetworkImage(
      imageUrl: "https://kpft.org/wp-content/uploads/2022/01/kpft.png",
      width: ResponsiveScale.sFromMq(mediaQuery, 70),
      height: ResponsiveScale.sFromMq(mediaQuery, 70),
      fit: BoxFit.contain,
    );
  }

  Widget _buildBottomSheetIconButton(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.info,
          color: Colors.white), // Replace 'Icons.add' with your desired icon
      onPressed: () {
        _showBottomSheet(context);
      },
      iconSize: ResponsiveScale.sFromMq(mediaQuery, 40),
      padding: EdgeInsets.zero,
    );
  }

  void _showBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.black,
      builder: (BuildContext context) {
        final double topPadding =
            MediaQuery.of(context).padding.top; // Get top safe area height

        // Adjust this value to control the additional offset from the top
        const double additionalTopOffset =
            30; // Set this to 0 to start from the top

        return SizedBox(
          height: MediaQuery.of(context).size.height -
              topPadding -
              additionalTopOffset,
          child:
              const RadioSheet(), // Display the RadioSheet widget in the bottom sheet
        );
      },
    );
  }

  @override
  Size get preferredSize =>
      Size.fromHeight(ResponsiveScale.sFromMq(mediaQuery, kToolbarHeight) + mediaQuery.padding.top);
}
