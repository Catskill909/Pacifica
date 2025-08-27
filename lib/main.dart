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
import 'presentation/widgets/webview_container.dart';
import 'wordpres.dart'; // Ensure this import is correct for your wordpres.dart file
import 'sheet.dart'; // Import the RadioSheet widget
import 'dart:developer';
import 'dart:async';
import 'ui/responsive.dart';
import 'package:dio/dio.dart';
import 'package:m3u_nullsafe/m3u_nullsafe.dart';

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
      androidNotificationChannelId: 'com.pacifica.app.pacifica2.audio',
      androidNotificationChannelName: 'KPFT Audio',
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
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 3),
    receiveTimeout: const Duration(seconds: 3),
    sendTimeout: const Duration(seconds: 3),
    responseType: ResponseType.plain,
  ));
  final Map<String, String> _resolvedCache =
      {}; // cache key: "id|playlistUrl" -> direct URL

  static const Map<String, String> streamUrls = {
    'HD1': 'https://docs.pacifica.org/kpft/kpft.m3u',
    'HD2': 'https://docs.pacifica.org/kpft/kpft_hd2.m3u',
    'HD3': 'https://docs.pacifica.org/kpft/kpft_hd3.m3u',
  };

  // Fallback direct streams to avoid regression if playlist resolution fails
  static const Map<String, String> _fallbackDirectById = {
    'HD1': 'https://streams.pacifica.org:9000/live_64',
    'HD2': 'https://streams.pacifica.org:9000/HD3_128',
    'HD3': 'https://streams.pacifica.org:9000/classic_country',
  };

  late final StreamSubscription<PlaybackEvent> _eventSubscription;

  AudioPlayerHandler() {
    _eventSubscription = _player.playbackEventStream.listen(_broadcastState);
    _setInitialMediaItem();
  }

  Future<String> _resolvePlaylistUrl(String id, String url) async {
    // Include URL in cache key so updated playlists bypass stale cache
    final cacheKey = '$id|$url';
    final cached = _resolvedCache[cacheKey];
    if (cached != null && cached.isNotEmpty) return cached;

    final lower = url.toLowerCase();
    if (!lower.endsWith('.m3u')) return url; // not a playlist, return as-is

    try {
      final res = await _dio.get<String>(url);
      final text = res.data ?? '';
      if (text.isEmpty) return url;

      final entries = await M3uParser.parse(text);
      if (entries.isEmpty) {
        return _fallbackDirectById[id] ?? url;
      }

      final base = Uri.parse(url);
      for (final e in entries) {
        // Original link string from playlist
        var link = e.link.trim();
        if (link.isEmpty) continue;

        // Sanitize duplicated URL schemes like https://https://...
        final dupScheme =
            RegExp(r'^(https?:\/\/)(https?:\/\/)+', caseSensitive: false);
        if (dupScheme.hasMatch(link)) {
          link = link.replaceAllMapped(dupScheme, (m) => m.group(1)!);
        }

        if (link.isEmpty) continue;
        Uri resolved;
        try {
          resolved = base.resolve(link);
        } catch (_) {
          continue;
        }
        final schemeOk =
            resolved.scheme == 'https' || resolved.scheme == 'http';
        final hostOk = resolved.hasAuthority && (resolved.host.isNotEmpty);
        if (!schemeOk || !hostOk) continue;

        final value = resolved.toString();
        _resolvedCache[cacheKey] = value;
        return value;
      }
      return _fallbackDirectById[id] ?? url;
    } catch (_) {
      // On any failure, fall back to original URL to avoid breaking playback
      return _fallbackDirectById[id] ?? url;
    }
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
      final playlistUrl = streamUrls[_mediaItem.id];
      if (playlistUrl != null) {
        final resolved = await _resolvePlaylistUrl(_mediaItem.id, playlistUrl);
        await _player.setUrl(resolved);
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
    final playlistUrl = streamUrls[_mediaItem.id];
    if (playlistUrl != null) {
      try {
        final resolved = await _resolvePlaylistUrl(_mediaItem.id, playlistUrl);
        await _player.setUrl(resolved);
        _broadcastState(_player.playbackEvent);
      } catch (_) {
        // ignore prepare errors; user can retry
      }
    }
  }

  Future<void> setMediaItem(MediaItem mediaItem) async {
    final playlistUrl = streamUrls[mediaItem.id];
    if (playlistUrl != null) {
      await _player.stop();
      final resolved = await _resolvePlaylistUrl(mediaItem.id, playlistUrl);
      await _player.setUrl(resolved);
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

  // One-time home-route connectivity verification to suppress any brief overlay flash
  static bool _didHomeConnectivityCheck = false;
  // (Removed) Android-specific debounce timestamps; relying on state guards instead.

  // Startup grace window to avoid false offline overlay during initial load
  static DateTime? _homeEnteredAt;
  static const Duration _overlayGrace = Duration(seconds: 3);

  const MyApp({super.key, required this.handler});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) =>
              ConnectivityCubit(service: ConnectivityService())..initialize(),
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
          // Kick a verification check on first frame after app launches to ensure
          // we have a definitive online/offline status before showing any overlay.
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
          // Once we enter home the first time, force a connectivity re-check and
          // rely on `checking` to prevent overlay until the result returns.
          if (!_didHomeConnectivityCheck) {
            _didHomeConnectivityCheck = true;
            _homeEnteredAt = DateTime.now();
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted) context.read<ConnectivityCubit>().checkNow();
            });
          }
          // Suppress overlay during a brief startup grace period after entering home
          final inGrace = _homeEnteredAt != null &&
              DateTime.now().difference(_homeEnteredAt!) < _overlayGrace;
          return Stack(
            fit: StackFit.expand,
            children: [
              child ?? const SizedBox.shrink(),
              if (!connState.isOnline &&
                  !connState.firstRun &&
                  !connState.checking &&
                  !connState.dismissed &&
                  !inGrace)
                const OfflineOverlay(),
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
  String _currentWebViewUrl = 'https://docs.pacifica.org/kpft/hd1/';

  static const Map<String, String> webViewUrls = {
    'HD1': 'https://docs.pacifica.org/kpft/hd1/',
    'HD2': 'https://docs.pacifica.org/kpft/hd2/',
    'HD3': 'https://docs.pacifica.org/kpft/hd3/',
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
      listenWhen: (prev, curr) => 
        prev.isOnline != curr.isOnline && 
        !curr.firstRun && // Only after startup grace period
        !curr.dismissed, // Respect user dismissal
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
                child: WebViewContainer(url: _currentWebViewUrl),
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
            final isLoading = proc == AudioProcessingState.loading ||
                proc == AudioProcessingState.buffering;
            final mq = MediaQuery.of(context);
            final double vpad = ResponsiveScale.isSmallPhone(mq) ? 4.0 : 0.0;

            return AbsorbPointer(
              absorbing: isLoading,
              child: GestureDetector(
                onTap: () async {
                  if (!playing) {
                    final connectivityState = context.read<ConnectivityCubit>().state;
                    // Only show modal if offline AND not in startup grace period
                    if (!connectivityState.isOnline && !connectivityState.firstRun) {
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
                  width:
                      ResponsiveScale.sSmallAware(context, 90.0, factor: 0.85),
                  height:
                      ResponsiveScale.sSmallAware(context, 90.0, factor: 0.85),
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
                      : Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: vpad),
                            child: Icon(
                              playing ? Icons.pause : Icons.play_arrow,
                              color: Colors.white,
                              size: ResponsiveScale.sSmallAware(context, 70.0,
                                  factor: 0.80),
                            ),
                          ),
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
      iconSize: ResponsiveScale.sFromMqSmallAware(mediaQuery, 40, factor: 0.80),
      padding: EdgeInsets.zero,
    );
  }

  Widget _buildLogoImage() {
    return CachedNetworkImage(
      imageUrl: "https://kpft.org/wp-content/uploads/2022/01/kpft.png",
      width: ResponsiveScale.sFromMqSmallAware(mediaQuery, 70, factor: 0.80),
      height: ResponsiveScale.sFromMqSmallAware(mediaQuery, 70, factor: 0.80),
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
      iconSize: ResponsiveScale.sFromMqSmallAware(mediaQuery, 40, factor: 0.80),
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
      Size.fromHeight(ResponsiveScale.sFromMq(mediaQuery, kToolbarHeight) +
          mediaQuery.padding.top);
}
