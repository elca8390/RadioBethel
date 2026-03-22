import 'dart:ui';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_image_slideshow/flutter_image_slideshow.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:just_audio/just_audio.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

const String _stationName = 'Radio Bethel Costa Rica';
const String _stationSubtitle = 'Emisora Cristiana';
const String _streamUrl = 'http://51.222.154.65:8186/stream';
const String _playStoreUrl =
    'https://play.google.com/store/apps/details?id=co.ecoingenieria.radiobethelcr';
const String _notificationArtworkUrl =
    'https://images.unsplash.com/photo-1516280440614-37939bbacd81?auto=format&fit=crop&w=1000&q=80';
const String _flagCr = '\u{1F1E8}\u{1F1F7}';

const List<String> _sliderImages = <String>[
  'https://radio.ecoingenieria.co/bethelCR/Imagen%201.jpeg',
  'https://radio.ecoingenieria.co/bethelCR/Imagen%202.jpeg',
  'https://radio.ecoingenieria.co/bethelCR/Imagen%203.jpeg',
];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final AudioHandler handler = await AudioService.init(
    builder: () => RadioAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId:
          'co.ecoingenieria.radiobethelcr.channel.audio',
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
  static final Uri _whatsAppUri = Uri.parse('https://wa.me/50670891457');
  static final Uri _donateUri = Uri.parse(
    'https://www.paypal.com/donate/?hosted_button_id=WYWX63VWWAZLS',
  );
  static final Uri _facebookUri = Uri.parse(
    'https://www.facebook.com/profile.php?id=61584990081292',
  );
  static final Uri _tiktokUri = Uri.parse(
    'https://www.tiktok.com/@radiobethelcr',
  );

  bool _isInitializing = true;
  String? _errorMessage;
  double _volume = 0.85;
  double _lastVolume = 0.85;

  bool get _isDarkMode => Theme.of(context).brightness == Brightness.dark;
  Color get _primaryTextColor =>
      _isDarkMode ? Colors.white : const Color(0xFF1A3765);
  Color get _headerChipColor => _isDarkMode
      ? Colors.black.withValues(alpha: 0.12)
      : Colors.white.withValues(alpha: 0.90);
  Color get _contentCardColor => _isDarkMode
      ? Colors.black.withValues(alpha: 0.22)
      : Colors.white.withValues(alpha: 0.82);
  Color get _panelBgColor => _isDarkMode
      ? Colors.black.withValues(alpha: 0.24)
      : Colors.white.withValues(alpha: 0.86);
  Color get _panelBorderColor => _isDarkMode
      ? Colors.white.withValues(alpha: 0.2)
      : Colors.black.withValues(alpha: 0.08);

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

  Future<void> _openWhatsApp() async {
    await launchUrl(_whatsAppUri, mode: LaunchMode.externalApplication);
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

  Future<void> _shareApp() async {
    const String shareText =
        'Te recomiendo Radio Bethel CR para escuchar la emisora en vivo. '
        'Descargala aqui:\n$_playStoreUrl';
    try {
      await SharePlus.instance.share(
        ShareParams(text: shareText, subject: 'Descarga Radio Bethel CR'),
      );
    } on MissingPluginException {
      await Clipboard.setData(const ClipboardData(text: shareText));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No se pudieron abrir las opciones de compartir. '
            'Se copio el mensaje al portapapeles.',
          ),
        ),
      );
    }
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
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(
                color: _isDarkMode
                    ? Colors.white.withValues(alpha: 0.02)
                    : Colors.white.withValues(alpha: 0.14),
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[
                  _isDarkMode
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.white.withValues(alpha: 0.16),
                  Colors.transparent,
                  _isDarkMode
                      ? Colors.black.withValues(alpha: 0.12)
                      : Colors.white.withValues(alpha: 0.01),
                ],
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  final bool compact =
                      constraints.maxHeight < 760 || constraints.maxWidth < 380;
                  final double bottomSafeInset = MediaQuery.viewPaddingOf(
                    context,
                  ).bottom;
                  final double scale = (constraints.maxHeight / 860).clamp(
                    0.74,
                    1.0,
                  );
                  final double titleSize = (compact ? 48 : 58) * scale;
                  final double maxSliderWidth =
                      constraints.maxWidth - (40 * scale);

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
                            padding: EdgeInsets.only(
                              left: 20 * scale,
                              right: 20 * scale,
                              top: 10 * scale,
                              bottom: bottomSafeInset + 10,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: <Widget>[
                                _buildTopBar(scale: scale),
                                SizedBox(height: 4 * scale),
                                Flexible(
                                  flex: 16,
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 10 * scale,
                                      vertical: 6 * scale,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _contentCardColor,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: <Widget>[
                                        Text(
                                          'EMISORA CRISTIANA',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 16 * scale,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 1.2,
                                            color: _primaryTextColor,
                                            shadows: <Shadow>[
                                              Shadow(
                                                color: _isDarkMode
                                                    ? Colors.black
                                                    : Colors.white.withValues(
                                                        alpha: 0.85,
                                                      ),
                                                blurRadius: 6,
                                                offset: Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                        ),
                                        SizedBox(height: 2 * scale),
                                        Text(
                                          'Radio Bethel',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: titleSize * 0.78,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: -1.4,
                                            fontStyle: FontStyle.italic,
                                            color: _primaryTextColor,
                                            shadows: <Shadow>[
                                              Shadow(
                                                color: _isDarkMode
                                                    ? Colors.black.withValues(
                                                        alpha: 0.42,
                                                      )
                                                    : Colors.white.withValues(
                                                        alpha: 0.95,
                                                      ),
                                                blurRadius: 14,
                                                offset: const Offset(0, 4),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 0),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: <Widget>[
                                            Text(
                                              _flagCr,
                                              style: TextStyle(
                                                fontSize: 20 * scale,
                                              ),
                                            ),
                                            SizedBox(width: 6 * scale),
                                            Text(
                                              'Costa Rica',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                fontSize: 17 * scale,
                                                fontWeight: FontWeight.w800,
                                                letterSpacing: 0.8,
                                                color: _primaryTextColor,
                                                shadows: <Shadow>[
                                                  Shadow(
                                                    color: _isDarkMode
                                                        ? Colors.black
                                                        : Colors.white
                                                              .withValues(
                                                                alpha: 0.85,
                                                              ),
                                                    blurRadius: 6,
                                                    offset: Offset(0, 2),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            SizedBox(width: 6 * scale),
                                            Text(
                                              _flagCr,
                                              style: TextStyle(
                                                fontSize: 20 * scale,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Expanded(
                                  flex: 42,
                                  child: LayoutBuilder(
                                    builder: (
                                      BuildContext context,
                                      BoxConstraints box,
                                    ) {
                                      final double sliderSize = box.maxHeight
                                          .clamp(170.0, maxSliderWidth);
                                      return Center(
                                        child: SizedBox(
                                          width: sliderSize,
                                          height: sliderSize,
                                          child: _buildImageSlider(),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(height: 10),
                                _buildBottomPanel(
                                  isPlaying: isPlaying,
                                  isBusy: isBusy,
                                  scale: scale,
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

  Widget _buildTopBar({required double scale}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        _buildHeaderIcon(
          icon: Icons.language_rounded,
          label: 'Web',
          onTap: _openWebsite,
          scale: scale,
        ),
        Row(
          children: <Widget>[
            _buildHeaderIcon(
              icon: Icons.share_rounded,
              label: 'Compartir',
              onTap: _shareApp,
              scale: scale,
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
    required double scale,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          decoration: BoxDecoration(
            color: _headerChipColor,
            borderRadius: BorderRadius.circular(14 * scale),
          ),
          child: IconButton(
            onPressed: onTap,
            icon: Icon(icon, color: _primaryTextColor, size: 28 * scale),
          ),
        ),
        SizedBox(height: 4 * scale),
        Text(
          label,
          style: TextStyle(
            color: _primaryTextColor,
            fontSize: 12 * scale,
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
        border: Border.all(
          color: _isDarkMode
              ? Colors.white.withValues(alpha: 0.35)
              : Colors.black.withValues(alpha: 0.06),
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: _isDarkMode ? 0.22 : 0.10),
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
          indicatorBackgroundColor: _isDarkMode
              ? Colors.white.withValues(alpha: 0.6)
              : Colors.black.withValues(alpha: 0.12),
          children: _sliderImages
              .map(
                (String url) => FadeInImage.assetNetwork(
                  placeholder: 'assets/images/fadein_placeholder.jpg',
                  image: url,
                  imageErrorBuilder:
                      (BuildContext context, Object error, StackTrace? _) {
                        return Container(
                          color: _isDarkMode
                              ? Colors.black.withValues(alpha: 0.3)
                              : Colors.white.withValues(alpha: 0.86),
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.image_not_supported_rounded,
                            color: _isDarkMode
                                ? Colors.white70
                                : Colors.black54,
                            size: 38,
                          ),
                        );
                      },
                  fit: BoxFit.contain,
                  fadeInDuration: const Duration(milliseconds: 350),
                  fadeOutDuration: const Duration(milliseconds: 180),
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  Widget _buildBottomPanel({
    required bool isPlaying,
    required bool isBusy,
    required double scale,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        12 * scale,
        8 * scale,
        12 * scale,
        6 * scale,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(34 * scale),
        color: _panelBgColor,
        border: Border.all(color: _panelBorderColor),
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
                onTap: _openWhatsApp,
                scale: scale,
              ),
              _buildSmallControl(
                icon: FontAwesomeIcons.handHoldingHeart,
                iconColor: const Color(0xFFFFC107),
                onTap: _openDonate,
                scale: scale,
              ),
              _buildMainControl(
                isPlaying: isPlaying,
                isBusy: isBusy,
                scale: scale,
              ),
              _buildSmallControl(
                icon: FontAwesomeIcons.facebookF,
                iconColor: const Color(0xFF1877F2),
                onTap: _openFacebook,
                scale: scale,
              ),
              _buildSmallControl(
                icon: FontAwesomeIcons.tiktok,
                iconColor: const Color(0xFFEE1D52),
                onTap: _openTikTok,
                scale: scale,
              ),
            ],
          ),
          SizedBox(height: 4 * scale),
          Row(
            children: <Widget>[
              IconButton(
                onPressed: _toggleMute,
                icon: Icon(
                  _volume == 0
                      ? Icons.volume_off_rounded
                      : Icons.volume_up_rounded,
                  color: _primaryTextColor,
                ),
              ),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: const Color(0xFFE02448),
                    inactiveTrackColor: _isDarkMode
                        ? Colors.white70
                        : Colors.black.withValues(alpha: 0.28),
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

  Widget _buildMainControl({
    required bool isPlaying,
    required bool isBusy,
    required double scale,
  }) {
    return Container(
      width: 94 * scale,
      height: 94 * scale,
      decoration: BoxDecoration(
        color: const Color(0x2BFFFFFF),
        borderRadius: BorderRadius.circular(47 * scale),
      ),
      child: Center(
        child: FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFE02448),
            shape: const CircleBorder(),
            minimumSize: Size(72 * scale, 72 * scale),
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
                  color: _primaryTextColor,
                  size: 38 * scale,
                ),
        ),
      ),
    );
  }

  Widget _buildSmallControl({
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
    required double scale,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 50 * scale,
        height: 50 * scale,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: _isDarkMode
              ? Colors.black.withValues(alpha: 0.38)
              : const Color(0xFFE7EDF8),
          shape: BoxShape.circle,
          border: Border.all(
            color: _isDarkMode
                ? Colors.white.withValues(alpha: 0.45)
                : Colors.black.withValues(alpha: 0.12),
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withValues(alpha: _isDarkMode ? 0.22 : 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: FaIcon(icon, color: iconColor, size: 24 * scale),
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
