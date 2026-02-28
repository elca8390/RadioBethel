import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';

const String _stationName = 'Radio Bethel Costa Rica';
const String _stationSubtitle = 'Emisora Cristiana';
const String _streamUrl = 'http://51.222.154.65:8186/stream';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await JustAudioBackground.init(
      androidNotificationChannelId: 'com.example.radiobethel.channel.audio',
      androidNotificationChannelName: 'Radio Bethel',
      androidNotificationOngoing: true,
    );
  } catch (_) {
    // If the current platform does not support media notifications, continue.
  }

  runApp(const RadioBethelApp());
}

class RadioBethelApp extends StatelessWidget {
  const RadioBethelApp({super.key});

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
      home: const RadioHomePage(),
    );
  }
}

class RadioHomePage extends StatefulWidget {
  const RadioHomePage({super.key});

  @override
  State<RadioHomePage> createState() => _RadioHomePageState();
}

class _RadioHomePageState extends State<RadioHomePage> {
  final AudioPlayer _player = AudioPlayer();

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
      await _player.setAudioSource(
        AudioSource.uri(
          Uri.parse(_streamUrl),
          tag: const MediaItem(
            id: _streamUrl,
            title: _stationName,
            artist: _stationSubtitle,
            album: 'Transmision en vivo',
          ),
        ),
      );
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
        await _player.stop();
        return;
      }

      if (_player.processingState == ProcessingState.idle) {
        await _prepareAudio();
      }

      if (_errorMessage == null) {
        await _player.play();
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

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[
              Color(0xFF06318F),
              Color(0xFFF6F8FF),
              Color(0xFFC10D2E),
              Color(0xFFFAFBFF),
              Color(0xFF062874),
            ],
            stops: <double>[0, 0.20, 0.49, 0.72, 1],
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[
                Colors.white.withValues(alpha: 0.14),
                Colors.transparent,
                Colors.black.withValues(alpha: 0.32),
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
                        final bool isPlaying = snapshot.data?.playing ?? false;
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
                              const Spacer(),
                              const Text(
                                'EMISORA CRISTIANA',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 21,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.2,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Radio Bethel',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: titleSize,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -1.8,
                                  fontStyle: FontStyle.italic,
                                  color: Colors.white,
                                  shadows: <Shadow>[
                                    Shadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.25,
                                      ),
                                      blurRadius: 12,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                              ),
                              const Text(
                                'Costa Rica',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.8,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: compact ? 28 : 34),
                              const Spacer(),
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
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        _buildHeaderIcon(Icons.menu_rounded),
        Row(
          children: <Widget>[
            _buildHeaderIcon(Icons.settings_rounded),
          ],
        ),
      ],
    );
  }

  Widget _buildHeaderIcon(IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: IconButton(
        onPressed: () {},
        icon: Icon(icon, color: Colors.white, size: 29),
      ),
    );
  }

  Widget _buildBottomPanel({
    required bool isPlaying,
    required bool isBusy,
  }) {
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
                onTap: () {},
              ),
              _buildMainControl(isPlaying: isPlaying, isBusy: isBusy),
              _buildSmallControl(
                icon: FontAwesomeIcons.facebookF,
                iconColor: const Color(0xFF1877F2),
                onTap: () {},
              ),
              _buildSmallControl(
                icon: FontAwesomeIcons.tiktok,
                iconColor: const Color(0xFFEE1D52),
                onTap: () {},
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
