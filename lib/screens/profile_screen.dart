import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../models/app_user.dart';
import '../models/leaderboard_entry.dart';
import '../models/match_prediction.dart';
import '../services/leaderboard_service.dart';
import '../services/prediction_service.dart';
import '../services/session_controller.dart';
import '../design_system/design_system.dart';
import '../widgets/logout_circle_button.dart';

/// Profile screen with avatar, editable identity, stats, and history.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    required this.sessionController,
    this.leaderboardService,
    this.predictionService,
  });

  final SessionController sessionController;
  final LeaderboardService? leaderboardService;
  final PredictionService? predictionService;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final TextEditingController _nickController;
  LeaderboardEntry? _userStats;
  List<_PredictionHistoryItem> _history = [];
  bool _isStatsLoading = true;
  bool _isPhotoUploading = false;
  String? _statsError;

  @override
  void initState() {
    super.initState();
    final user = widget.sessionController.currentUser!;
    _nickController = TextEditingController(text: user.nick);
    _loadProfileStats(user);
  }

  @override
  void dispose() {
    _nickController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.sessionController.currentUser!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.md),
            child: LogoutCircleButton(
              sessionController: widget.sessionController,
            ),
          ),
        ],
      ),
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screen,
            AppSpacing.md,
            AppSpacing.screen,
            AppSpacing.bottomNavClearance,
          ),
          children: [
            _UserSummary(user: user),
            const SizedBox(height: AppSpacing.md),
            AppButton.outline(
              label: _isPhotoUploading ? 'Enviando foto...' : 'Alterar foto',
              icon: PhosphorIcon(PhosphorIcons.camera()),
              isLoading: _isPhotoUploading,
              onPressed: widget.sessionController.isLoading
                  ? null
                  : _pickAndUploadPhoto,
            ),
            const SizedBox(height: AppSpacing.lg),
            _StatsGrid(entry: _userStats, isLoading: _isStatsLoading),
            if (_statsError != null) ...[
              const SizedBox(height: AppSpacing.md),
              AppErrorState(message: _statsError!),
            ],
            const SizedBox(height: AppSpacing.xxl),
            const AppSectionHeader(title: 'Nick no ranking'),
            const SizedBox(height: AppSpacing.sm),
            AppTextField(
              controller: _nickController,
              maxLength: 24,
              hintText: 'Como voce quer aparecer?',
            ),
            const SizedBox(height: AppSpacing.xxl),
            AppButton(
              label: widget.sessionController.isLoading
                  ? 'Salvando...'
                  : 'Salvar perfil',
              icon: PhosphorIcon(PhosphorIcons.floppyDisk()),
              isLoading: widget.sessionController.isLoading,
              onPressed: _save,
            ),
            const SizedBox(height: AppSpacing.md),
            AppButton.outline(
              label: 'Sair',
              icon: PhosphorIcon(PhosphorIcons.signOut()),
              onPressed: widget.sessionController.isLoading
                  ? null
                  : widget.sessionController.signOut,
            ),
            const SizedBox(height: AppSpacing.xxl),
            const AppSectionHeader(title: 'Historico'),
            const SizedBox(height: AppSpacing.md),
            if (_isStatsLoading)
              const AppLoading(padding: EdgeInsets.all(AppSpacing.xxl))
            else if (_history.isEmpty)
              const AppEmptyState(
                message: 'Nenhum palpite registrado no backend ainda.',
              )
            else
              for (final item in _history) ...[
                _HistoryTile(item: item),
                const SizedBox(height: AppSpacing.md),
              ],
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final nick = _nickController.text.trim();
    if (nick.length < 3) {
      AppSnackBar.error(context, 'Use um nick com pelo menos 3 letras.');
      return;
    }

    await widget.sessionController.updateProfile(
      nick: nick,
      avatarId: widget.sessionController.currentUser!.avatarId,
    );

    if (!mounted) return;
    if (widget.sessionController.errorMessage != null) {
      AppSnackBar.error(context, widget.sessionController.errorMessage!);
      return;
    }

    AppSnackBar.info(context, 'Perfil atualizado.');
    setState(() {});
    await _loadProfileStats(widget.sessionController.currentUser!);
  }

  Future<void> _pickAndUploadPhoto() async {
    final user = widget.sessionController.currentUser;
    if (user == null) return;

    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 82,
      );
      if (image == null) return;

      setState(() => _isPhotoUploading = true);
      final bytes = await image.readAsBytes();
      final extension = _imageExtension(image.name);
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.$extension';
      final reference = FirebaseStorage.instance
          .ref()
          .child('profile_photos')
          .child(user.id)
          .child(fileName);

      await reference.putData(
        bytes,
        SettableMetadata(contentType: _contentType(extension)),
      );
      final photoUrl = await reference.getDownloadURL();

      await widget.sessionController.updateProfile(
        nick: _nickController.text.trim(),
        avatarId: user.avatarId,
        photoUrl: photoUrl,
      );

      if (!mounted) return;
      if (widget.sessionController.errorMessage != null) {
        AppSnackBar.error(context, widget.sessionController.errorMessage!);
        return;
      }

      AppSnackBar.info(context, 'Foto atualizada.');
      setState(() {});
    } catch (error) {
      debugPrint('Falha ao enviar foto de perfil: $error');
      if (!mounted) return;
      AppSnackBar.error(context, 'Nao foi possivel enviar a foto.');
    } finally {
      if (mounted) setState(() => _isPhotoUploading = false);
    }
  }

  String _imageExtension(String fileName) {
    final lowerName = fileName.toLowerCase();
    if (lowerName.endsWith('.png')) return 'png';
    if (lowerName.endsWith('.webp')) return 'webp';
    return 'jpg';
  }

  String _contentType(String extension) {
    return switch (extension) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      _ => 'image/jpeg',
    };
  }

  Future<void> _loadProfileStats(AppUser user) async {
    setState(() {
      _isStatsLoading = true;
      _statsError = null;
    });

    try {
      final leaderboardService =
          widget.leaderboardService ?? LeaderboardService();
      final predictionService = widget.predictionService ?? PredictionService();
      final results = await Future.wait<Object>([
        leaderboardService.loadLeaderboard(user),
        predictionService.loadMatches(),
        predictionService.loadUserPredictions(user),
      ]);

      if (!mounted) return;
      final leaderboard = results[0] as List<LeaderboardEntry>;
      final matches = results[1] as List<MatchPrediction>;
      final predictions = results[2] as Map<int, UserMatchPrediction>;
      LeaderboardEntry? userEntry;
      for (final entry in leaderboard) {
        if (entry.userId == user.id) {
          userEntry = entry;
          break;
        }
      }
      final matchesById = {for (final match in matches) match.fixtureId: match};

      setState(() {
        _userStats = userEntry;
        _history = predictions.entries
            .map((entry) {
              final match = matchesById[entry.key];
              if (match == null) return null;
              return _PredictionHistoryItem(
                match: match,
                prediction: entry.value,
              );
            })
            .nonNulls
            .toList()
            .reversed
            .toList();
        _isStatsLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isStatsLoading = false;
        _statsError =
            'Nao foi possivel carregar estatisticas reais do backend.';
        _history = [];
      });
    }
  }
}

class _UserSummary extends StatelessWidget {
  const _UserSummary({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Row(
        children: [
          _ProfilePhoto(photoUrl: user.photoUrl, radius: 36),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.nick, style: theme.textTheme.titleLarge),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  user.email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfilePhoto extends StatelessWidget {
  const _ProfilePhoto({required this.photoUrl, required this.radius});

  final String? photoUrl;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final imageUrl = photoUrl?.trim();

    return CircleAvatar(
      radius: radius,
      backgroundColor: context.tokens.surfaceElevated,
      foregroundImage: imageUrl == null || imageUrl.isEmpty
          ? null
          : NetworkImage(imageUrl),
      child: imageUrl == null || imageUrl.isEmpty
          ? PhosphorIcon(
              PhosphorIcons.userCircle(),
              color: context.tokens.textSecondary,
              size: radius,
            )
          : null,
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.entry, required this.isLoading});

  final LeaderboardEntry? entry;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final points = isLoading ? '--' : '${entry?.points ?? 0}';
    final exactScores = isLoading ? '--' : '${entry?.exactScores ?? 0}';
    final predictions = isLoading ? '--' : '${entry?.predictionsCount ?? 0}';
    final position = isLoading ? '--' : '#${entry?.position ?? 0}';

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 520;
        return GridView.count(
          crossAxisCount: isWide ? 4 : 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: isWide ? 1.7 : 1.45,
          children: [
            _StatCard(label: 'Pontos', value: points),
            _StatCard(label: 'Exatos', value: exactScores),
            _StatCard(label: 'Palpites', value: predictions),
            _StatCard(label: 'Posicao', value: position),
          ],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return AppCard.elevated(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.numeric.copyWith(
              color: context.tokens.brandOnSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.item});

  final _PredictionHistoryItem item;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          PhosphorIcon(
            PhosphorIcons.clockCounterClockwise(),
            color: context.tokens.pending,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  item.subtitle,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String get title => '${item.match.homeTeam} x ${item.match.awayTeam}';
}

class _PredictionHistoryItem {
  const _PredictionHistoryItem({required this.match, required this.prediction});

  final MatchPrediction match;
  final UserMatchPrediction prediction;

  String get subtitle {
    final home = prediction.homeScore ?? '-';
    final away = prediction.awayScore ?? '-';
    return 'Palpite: $home x $away - ${_pickLabel(prediction.pick)}';
  }

  String _pickLabel(MatchPick pick) {
    return switch (pick) {
      MatchPick.home => match.homeTeam,
      MatchPick.draw => 'Empate',
      MatchPick.away => match.awayTeam,
    };
  }
}
