import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';

const String _stationName = 'Radio Bethel Costa Rica';
const String _stationSubtitle = 'Emisora Cristiana';
const String _streamUrl = 'http://51.222.154.65:8186/stream';
const String _sloganTop = 'Musica que transforma';
const String _sloganBottom = 'Vive la experiencia Bethel';

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

  Future<void> _togglePlayPause() async {
    try {
      if (_player.playing) {
        await _player.pause();
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

  Future<void> _reconnectAndPlay() async {
    try {
      await _player.stop();
      await _prepareAudio();
      if (_errorMessage == null) {
        await _player.play();
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'No fue posible reconectar. Intenta de nuevo.';
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

  String _statusLabel(ProcessingState processingState, bool isPlaying) {
    if (_errorMessage != null) {
      return _errorMessage!;
    }

    switch (processingState) {
      case ProcessingState.idle:
        return _isInitializing
            ? 'Preparando senal...'
            : 'Listo para reproducir';
      case ProcessingState.loading:
        return 'Conectando con la emisora...';
      case ProcessingState.buffering:
        return 'Cargando audio...';
      case ProcessingState.ready:
        return isPlaying ? 'En vivo' : 'Pausado';
      case ProcessingState.completed:
        return 'Transmision finalizada';
    }
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
                final double titleSize = compact ? 64 : 76;

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
                              Text(
                                'Bethel',
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
                              const SizedBox(height: 2),
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
                              SizedBox(height: compact ? 22 : 28),
                              _buildPrimaryActionButton(
                                isPlaying: isPlaying,
                                isBusy: isBusy,
                              ),
                              const SizedBox(height: 20),
                              const Text(
                                _sloganTop,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  fontStyle: FontStyle.italic,
                                  color: Colors.white,
                                  shadows: <Shadow>[
                                    Shadow(
                                      color: Color(0xAA000000),
                                      blurRadius: 8,
                                      offset: Offset(0, 1),
                                    ),
                                  ],
                                ),
                              ),
                              const Spacer(),
                              _buildBottomPanel(
                                isPlaying: isPlaying,
                                isBusy: isBusy,
                                status: _statusLabel(
                                  processingState,
                                  isPlaying,
                                ),
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
            _buildHeaderIcon(Icons.search_rounded),
            const SizedBox(width: 8),
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

  Widget _buildPrimaryActionButton({
    required bool isPlaying,
    required bool isBusy,
  }) {
    return GestureDetector(
      onTap: isBusy ? null : _togglePlayPause,
      child: Container(
        width: 112,
        height: 112,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
          color: Colors.white.withValues(alpha: 0.16),
        ),
        child: Center(
          child: isBusy
              ? const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: Colors.white,
                  ),
                )
              : Icon(
                  isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 62,
                ),
        ),
      ),
    );
  }

  Widget _buildBottomPanel({
    required bool isPlaying,
    required bool isBusy,
    required String status,
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
              _buildSmallControl(icon: Icons.music_note_rounded, onTap: () {}),
              _buildSmallControl(
                icon: Icons.skip_previous_rounded,
                onTap: _reconnectAndPlay,
              ),
              _buildMainControl(isPlaying: isPlaying, isBusy: isBusy),
              _buildSmallControl(
                icon: Icons.skip_next_rounded,
                onTap: _reconnectAndPlay,
              ),
              _buildSmallControl(
                icon: Icons.refresh_rounded,
                onTap: _reconnectAndPlay,
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
          const SizedBox(height: 6),
          const Text(
            _sloganBottom,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              fontStyle: FontStyle.italic,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            status,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: _errorMessage == null
                  ? Colors.white.withValues(alpha: 0.9)
                  : const Color(0xFFFFD9DE),
              fontWeight: FontWeight.w600,
            ),
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
          onPressed: isBusy ? null : _togglePlayPause,
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
                  isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 44,
                ),
        ),
      ),
    );
  }

  Widget _buildSmallControl({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.17),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }
}
