import 'dart:ui';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_slideshow/flutter_image_slideshow.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:just_audio/just_audio.dart';
import 'package:url_launcher/url_launcher.dart';

const String _stationName = 'Radio Bethel Costa Rica';
const String _stationSubtitle = 'Emisora Cristiana';
const String _streamUrl = 'http://51.222.154.65:8186/stream';
const String _notificationArtworkUrl =
    'https://images.unsplash.com/photo-1516280440614-37939bbacd81?auto=format&fit=crop&w=1000&q=80';
const String _flagCr = '\u{1F1E8}\u{1F1F7}';

const List<String> _sliderImages = <String>[
  'https://images.unsplash.com/photo-1504052434569-70ad5836ab65?auto=format&fit=crop&w=1200&q=80',
  'https://images.unsplash.com/photo-1516280440614-37939bbacd81?auto=format&fit=crop&w=1200&q=80',
  'https://images.unsplash.com/photo-1470225620780-dba8ba36b745?auto=format&fit=crop&w=1200&q=80',
];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final AudioHandler handler = await AudioService.init(
    builder: () => RadioAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.example.radiobethel.channel.audio',
      androidNotificationChannelName: 'Radio Bethel',
      androidNotificationOngoing: true,
      androidNotificationIcon: 'mipmap/ic_launcher',
    ),
  );

  runApp(RadioBethelApp(audioHandler: handler as RadioAudioHandler));
}

class RadioBethelApp extends StatelessWidget {
  const RadioBethelApp({required this.audioHandler, super.key});

  final RadioAudioHandler audioHandler;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: _stationName,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0A2A87),
          brightness: Brightness.dark,
        ),
      ),
      home: RadioHomePage(audioHandler: audioHandler),
    );
  }
}

class RadioHomePage extends StatefulWidget {
  const RadioHomePage({required this.audioHandler, super.key});

  final RadioAudioHandler audioHandler;

  @override
  State<RadioHomePage> createState() => _RadioHomePageState();
}

class _RadioHomePageState extends State<RadioHomePage> {
  AudioPlayer get _player => widget.audioHandler.player;
  static final Uri _websiteUri = Uri.parse('https://www.radiobethelcr.com');
  static final Uri _donateUri = Uri.parse(
    'https://www.paypal.com/donate/?hosted_button_id=WYWX63VWWAZLS',
  );
  static final Uri _facebookUri = Uri.parse(
    'https://www.facebook.com/profile.php?id=61584990081292',
  );
  static final Uri _tiktokUri = Uri.parse('https://www.tiktok.com/@radiobethelcr');

  bool _isInitializing = true;
  String? _errorMessage;
  double _volume = 0.85;
  double _lastVolume = 0.85;

  @override
  void initState() {
    super.initState();
    _prepareAudio();
  }

  Future<void> _prepareAudio() async {
    setState(() {
      _isInitializing = true;
      _errorMessage = null;
    });

    try {
      await _player.setVolume(_volume);
      await widget.audioHandler.prepare();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'No se pudo conectar con la emisora.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
    }
  }

  Future<void> _togglePlayStop() async {
    try {
      if (_player.playing) {
        await widget.audioHandler.stop();
        return;
      }

      if (_player.processingState == ProcessingState.idle) {
        await _prepareAudio();
      }

      if (_errorMessage == null) {
        await widget.audioHandler.play();
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Error al iniciar la transmision.';
      });
    }
  }

  void _changeVolume(double value) {
    setState(() {
      _volume = value;
      if (value > 0) {
        _lastVolume = value;
      }
    });
    _player.setVolume(value);
  }

  void _toggleMute() {
    if (_volume == 0) {
      _changeVolume(_lastVolume == 0 ? 0.85 : _lastVolume);
      return;
    }
    _changeVolume(0);
  }

  Future<void> _openWebsite() async {
    await launchUrl(_websiteUri, mode: LaunchMode.externalApplication);
  }

  Future<void> _openDonate() async {
    await launchUrl(_donateUri, mode: LaunchMode.externalApplication);
  }

  Future<void> _openFacebook() async {
    await launchUrl(_facebookUri, mode: LaunchMode.externalApplication);
  }

  Future<void> _openTikTok() async {
    await launchUrl(_tiktokUri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: <Widget>[
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[
                  Color(0xFF0038A8),
                  Color(0xFF0038A8),
                  Color(0xFFFFFFFF),
                  Color(0xFFFFFFFF),
                  Color(0xFFCE1126),
                  Color(0xFFCE1126),
                  Color(0xFFFFFFFF),
                  Color(0xFFFFFFFF),
                  Color(0xFF0038A8),
                  Color(0xFF0038A8),
                ],
                stops: <double>[
                  0.00,
                  0.16,
                  0.16,
                  0.34,
                  0.34,
                  0.66,
                  0.66,
                  0.84,
                  0.84,
                  1.00,
                ],
              ),
            ),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 50.2, sigmaY: 50.2),
              child: Container(color: Colors.white.withValues(alpha: 0.02)),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[
                  Colors.white.withValues(alpha: 0.06),
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.12),
                ],
              ),
            ),
            child: SafeArea(
              child: LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  final bool compact =
                      constraints.maxHeight < 760 || constraints.maxWidth < 380;
                  final double titleSize = compact ? 48 : 58;

                  return StreamBuilder<PlayerState>(
                    stream: _player.playerStateStream,
                    builder:
                        (
                          BuildContext context,
                          AsyncSnapshot<PlayerState> snapshot,
                        ) {
                          final bool isPlaying =
                              snapshot.data?.playing ?? false;
                          final ProcessingState processingState =
                              snapshot.data?.processingState ??
                              ProcessingState.idle;
                          final bool isBusy =
                              _isInitializing ||
                              processingState == ProcessingState.loading ||
                              processingState == ProcessingState.buffering;

                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 14,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: <Widget>[
                                _buildTopBar(),
                                const SizedBox(height: 14),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.22),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Column(
                                    children: <Widget>[
                                      const Text(
                                        'EMISORA CRISTIANA',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 21,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 1.2,
                                          color: Colors.white,
                                          shadows: <Shadow>[
                                            Shadow(
                                              color: Colors.black,
                                              blurRadius: 6,
                                              offset: Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'Radio Bethel',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: titleSize,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: -1.4,
                                          fontStyle: FontStyle.italic,
                                          color: Colors.white,
                                          shadows: <Shadow>[
                                            Shadow(
                                              color: Colors.black.withValues(
                                                alpha: 0.42,
                                              ),
                                              blurRadius: 14,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      const Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: <Widget>[
                                          Text(
                                            _flagCr,
                                            style: TextStyle(fontSize: 24),
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            'Costa Rica',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: 24,
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: 0.8,
                                              color: Colors.white,
                                              shadows: <Shadow>[
                                                Shadow(
                                                  color: Colors.black,
                                                  blurRadius: 6,
                                                  offset: Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            _flagCr,
                                            style: TextStyle(fontSize: 24),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: compact ? 14 : 18),
                                Expanded(child: _buildImageSlider()),
                                const SizedBox(height: 14),
                                _buildBottomPanel(
                                  isPlaying: isPlaying,
                                  isBusy: isBusy,
                                ),
                              ],
                            ),
                          );
                        },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        _buildHeaderIcon(
          icon: Icons.language_rounded,
          label: 'Web',
          onTap: _openWebsite,
        ),
        Row(
          children: <Widget>[
            _buildHeaderIcon(
              icon: Icons.share_rounded,
              label: 'Compartir',
              onTap: () {},
            ),
            const SizedBox(width: 8),
            _buildHeaderIcon(
              icon: Icons.settings_rounded,
              label: 'Config',
              onTap: () {},
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHeaderIcon({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: IconButton(
            onPressed: onTap,
            icon: Icon(icon, color: Colors.white, size: 29),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  Widget _buildImageSlider() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: ImageSlideshow(
          width: double.infinity,
          height: double.infinity,
          autoPlayInterval: 4000,
          isLoop: true,
          indicatorColor: const Color(0xFFE02448),
          indicatorBackgroundColor: Colors.white.withValues(alpha: 0.6),
          children: _sliderImages
              .map(
                (String url) => Image.network(
                  url,
                  fit: BoxFit.cover,
                  loadingBuilder:
                      (
                        BuildContext context,
                        Widget child,
                        ImageChunkEvent? loadingProgress,
                      ) {
                        if (loadingProgress == null) {
                          return child;
                        }
                        return Container(
                          color: Colors.black.withValues(alpha: 0.25),
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.4,
                            ),
                          ),
                        );
                      },
                  errorBuilder:
                      (BuildContext context, Object error, StackTrace? _) {
                        return Container(
                          color: Colors.black.withValues(alpha: 0.3),
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.image_not_supported_rounded,
                            color: Colors.white70,
                            size: 38,
                          ),
                        );
                      },
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  Widget _buildBottomPanel({required bool isPlaying, required bool isBusy}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(34),
        color: Colors.black.withValues(alpha: 0.24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              _buildSmallControl(
                icon: FontAwesomeIcons.whatsapp,
                iconColor: const Color(0xFF25D366),
                onTap: () {},
              ),
              _buildSmallControl(
                icon: FontAwesomeIcons.handHoldingHeart,
                iconColor: const Color(0xFFFFC107),
                onTap: _openDonate,
              ),
              _buildMainControl(isPlaying: isPlaying, isBusy: isBusy),
              _buildSmallControl(
                icon: FontAwesomeIcons.facebookF,
                iconColor: const Color(0xFF1877F2),
                onTap: _openFacebook,
              ),
              _buildSmallControl(
                icon: FontAwesomeIcons.tiktok,
                iconColor: const Color(0xFFEE1D52),
                onTap: _openTikTok,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: <Widget>[
              IconButton(
                onPressed: _toggleMute,
                icon: Icon(
                  _volume == 0
                      ? Icons.volume_off_rounded
                      : Icons.volume_up_rounded,
                  color: Colors.white,
                ),
              ),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: const Color(0xFFE02448),
                    inactiveTrackColor: Colors.white70,
                    thumbColor: const Color(0xFFE02448),
                    overlayColor: const Color(0x33E02448),
                  ),
                  child: Slider(value: _volume, onChanged: _changeVolume),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMainControl({required bool isPlaying, required bool isBusy}) {
    return Container(
      width: 108,
      height: 108,
      decoration: BoxDecoration(
        color: const Color(0x2BFFFFFF),
        borderRadius: BorderRadius.circular(54),
      ),
      child: Center(
        child: FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFE02448),
            shape: const CircleBorder(),
            minimumSize: const Size(82, 82),
            padding: EdgeInsets.zero,
            elevation: 4,
          ),
          onPressed: isBusy ? null : _togglePlayStop,
          child: isBusy
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                )
              : Icon(
                  isPlaying ? Icons.stop_rounded : Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 44,
                ),
        ),
      ),
    );
  }

  Widget _buildSmallControl({
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.38),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.45)),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.22),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: FaIcon(icon, color: iconColor, size: 28),
      ),
    );
  }
}

class RadioAudioHandler extends BaseAudioHandler with SeekHandler {
  RadioAudioHandler() {
    _player.playerStateStream.listen((_) => _broadcastState());
    _player.playbackEventStream.listen((_) => _broadcastState());
    mediaItem.add(
      MediaItem(
        id: _streamUrl,
        title: _stationName,
        artist: _stationSubtitle,
        album: 'Transmision en vivo',
        artUri: Uri.parse(_notificationArtworkUrl),
      ),
    );
  }

  final AudioPlayer _player = AudioPlayer();
  bool _isPrepared = false;

  AudioPlayer get player => _player;

  @override
  Future<void> prepare() => _ensurePrepared();

  Future<void> _ensurePrepared() async {
    if (_isPrepared) return;
    await _player.setAudioSource(AudioSource.uri(Uri.parse(_streamUrl)));
    _isPrepared = true;
    _broadcastState();
  }

  AudioProcessingState _mapState(ProcessingState state) {
    switch (state) {
      case ProcessingState.idle:
        return AudioProcessingState.idle;
      case ProcessingState.loading:
        return AudioProcessingState.loading;
      case ProcessingState.buffering:
        return AudioProcessingState.buffering;
      case ProcessingState.ready:
        return AudioProcessingState.ready;
      case ProcessingState.completed:
        return AudioProcessingState.completed;
    }
  }

  void _broadcastState() {
    playbackState.add(
      PlaybackState(
        controls: const <MediaControl>[MediaControl.play, MediaControl.stop],
        androidCompactActionIndices: const <int>[0, 1],
        processingState: _mapState(_player.processingState),
        playing: _player.playing,
        updatePosition: _player.position,
        bufferedPosition: _player.bufferedPosition,
        speed: _player.speed,
        queueIndex: 0,
      ),
    );
  }

  @override
  Future<void> play() async {
    await _ensurePrepared();
    await _player.play();
    _broadcastState();
  }

  @override
  Future<void> pause() => stop();

  @override
  Future<void> stop() async {
    await _player.stop();
    _broadcastState();
    await super.stop();
  }
}
