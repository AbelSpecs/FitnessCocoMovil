import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:pyrosfitmovil/core/models/streak_models.dart';
import 'package:pyrosfitmovil/core/services/streak_service.dart';
import 'package:pyrosfitmovil/core/utils/streak_helpers.dart';
import 'package:pyrosfitmovil/features/auth/presentation/controllers/auth_provider.dart';
import 'package:pyrosfitmovil/theme/app_theme.dart';

enum RankingMetric { streak, points, longestStreak }

class RankingScreen extends StatefulWidget {
  const RankingScreen({super.key});

  @override
  State<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends State<RankingScreen> {
  bool _isLoading = true;
  String _scope = 'coach'; // 'coach' | 'global'
  RankingMetric _metric = RankingMetric.streak;
  String _period = 'Mes'; // 'Semana' | 'Mes' | 'Temporada'
  String _searchQuery = '';

  List<StreakLeaderboardItemDto> _globalLeaderboard = [];
  List<StreakLeaderboardItemDto> _coachLeaderboard = [];

  final List<String> _periods = const ['Semana', 'Mes', 'Temporada'];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final auth = context.read<AuthProvider>();
    final coachId = auth.user?.myCoachId ?? auth.user?.coachId ?? 1;

    try {
      final results = await Future.wait([
        StreakService.getGlobalStreakLeaderboard(limit: 50),
        coachId > 0
            ? StreakService.getCoachStreakLeaderboard(coachId, limit: 50)
            : Future.value(<StreakLeaderboardItemDto>[]),
      ]);

      if (mounted) {
        setState(() {
          _globalLeaderboard = results[0];
          _coachLeaderboard = results[1];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  int _getValueForMetric(AthleteRankingInfo athlete, RankingMetric metric) {
    switch (metric) {
      case RankingMetric.streak:
        return athlete.streak;
      case RankingMetric.points:
        return athlete.points;
      case RankingMetric.longestStreak:
        return athlete.longestStreak;
    }
  }

  String _formatMetricValue(int value, RankingMetric metric) {
    if (metric == RankingMetric.points) {
      return NumberFormat.decimalPattern('es_ES').format(value);
    }
    return value.toString();
  }

  String _getMetricUnit(RankingMetric metric) {
    switch (metric) {
      case RankingMetric.streak:
        return 'días';
      case RankingMetric.points:
        return 'pts';
      case RankingMetric.longestStreak:
        return 'días';
    }
  }

  List<AthleteRankingInfo> _getAthletesData(int currentStudentId) {
    final rawList = _scope == 'coach' ? _coachLeaderboard : _globalLeaderboard;
    final coachLabel = _scope == 'coach' ? 'Tu Equipo' : 'Global';

    return mapLeaderboardToAthletes(
      rawList,
      currentStudentId: currentStudentId,
      coachLabel: coachLabel,
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final currentStudentId = auth.user?.studentId ?? 0;

    final athletes = _getAthletesData(currentStudentId);

    // Ordenar por métrica seleccionada
    final ranked = [...athletes]..sort((a, b) {
        final valA = _getValueForMetric(a, _metric);
        final valB = _getValueForMetric(b, _metric);
        return valB.compareTo(valA);
      });

    // Filtrar por texto de búsqueda
    final filtered = ranked.where((a) {
      return a.name.toLowerCase().contains(_searchQuery.trim().toLowerCase());
    }).toList();

    final maxVal = ranked.isNotEmpty ? _getValueForMetric(ranked[0], _metric) : 0;
    final myIndex = ranked.indexWhere((a) => a.me);
    final me = myIndex >= 0 ? ranked[myIndex] : null;
    final aboveMe = myIndex > 0 ? ranked[myIndex - 1] : null;

    final gap = (me != null && aboveMe != null)
        ? _getValueForMetric(aboveMe, _metric) - _getValueForMetric(me, _metric)
        : 0;

    return context.pyrosStyles.buildMeshBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.emoji_events_rounded,
                  color: AppTheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'PODIO & RANKING',
                style: TextStyle(
                  fontFamily: 'BebasNeue',
                  fontSize: 24,
                  letterSpacing: 1.5,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
            : RefreshIndicator(
                color: AppTheme.primary,
                onRefresh: _loadData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Subtítulo
                      const Text(
                        'Compite con tu equipo y escala en la clasificación global de PyrosFit.',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Scope Switch (Tu Coach / Equipo vs Global)
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF18181B).withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.border.withValues(alpha: 0.7)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildScopeTab(
                                key: 'coach',
                                label: 'Tu Coach / Equipo',
                                icon: Icons.groups_rounded,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: _buildScopeTab(
                                key: 'global',
                                label: 'Global PyrosFit',
                                icon: Icons.public_rounded,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Metric & Period Selectors
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  _buildMetricChip(
                                    metric: RankingMetric.streak,
                                    label: 'Racha actual',
                                    icon: Icons.local_fire_department,
                                  ),
                                  const SizedBox(width: 6),
                                  _buildMetricChip(
                                    metric: RankingMetric.points,
                                    label: 'Puntos',
                                    icon: Icons.auto_awesome,
                                  ),
                                  const SizedBox(width: 6),
                                  _buildMetricChip(
                                    metric: RankingMetric.longestStreak,
                                    label: 'Récord histórico',
                                    icon: Icons.military_tech_rounded,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Period Selector
                          Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.35),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppTheme.border.withValues(alpha: 0.6)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: _periods.map((p) {
                                final isSelected = _period == p;
                                return InkWell(
                                  onTap: () => setState(() => _period = p),
                                  borderRadius: BorderRadius.circular(16),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? AppTheme.primary.withValues(alpha: 0.25)
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Text(
                                      p,
                                      style: TextStyle(
                                        color: isSelected ? AppTheme.primaryGlow : Colors.grey,
                                        fontSize: 10,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // Podium (Top 3)
                      if (ranked.length >= 3) ...[
                        _buildPodium(ranked.sublist(0, 3)),
                        const SizedBox(height: 18),
                      ],

                      // My Position Card ("Tu Puesto")
                      if (me != null) ...[
                        _buildMyPositionCard(
                          me: me,
                          myIndex: myIndex,
                          aboveMe: aboveMe,
                          gap: gap,
                        ),
                        const SizedBox(height: 18),
                      ],

                      // Search input
                      TextField(
                        onChanged: (val) => setState(() => _searchQuery = val),
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Buscar alumno…',
                          hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                          prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 20),
                          filled: true,
                          fillColor: const Color(0xFF18181B).withValues(alpha: 0.6),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: AppTheme.border.withValues(alpha: 0.6)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: AppTheme.border.withValues(alpha: 0.6)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Ranking List
                      if (filtered.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: const Color(0xFF18181B).withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.border.withValues(alpha: 0.4)),
                          ),
                          child: const Column(
                            children: [
                              Icon(Icons.person_search, color: Colors.grey, size: 36),
                              SizedBox(height: 12),
                              Text(
                                'No se encontraron alumnos en esta clasificación.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey, fontSize: 13),
                              ),
                            ],
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: filtered.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final athlete = filtered[index];
                            final position = ranked.indexOf(athlete) + 1;
                            return _buildRankRow(
                              athlete: athlete,
                              position: position,
                              maxVal: maxVal,
                            );
                          },
                        ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildScopeTab({
    required String key,
    required String label,
    required IconData icon,
  }) {
    final isSelected = _scope == key;
    return InkWell(
      onTap: () => setState(() => _scope = key),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : Colors.grey,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricChip({
    required RankingMetric metric,
    required String label,
    required IconData icon,
  }) {
    final isSelected = _metric == metric;
    return InkWell(
      onTap: () => setState(() => _metric = metric),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary.withValues(alpha: 0.18) : Colors.black.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.primary : AppTheme.border.withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: isSelected ? AppTheme.primary : Colors.grey,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppTheme.primaryGlow : Colors.grey,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPodium(List<AthleteRankingInfo> topThree) {
    // 2º puesto (índice 1), 1º puesto (índice 0), 3º puesto (índice 2)
    final order = [1, 0, 2];
    final podiumHeights = [75.0, 105.0, 60.0];
    final podiumLabels = ['2', '1', '3'];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF18181B).withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.border.withValues(alpha: 0.7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.military_tech_rounded, color: AppTheme.primary, size: 16),
              const SizedBox(width: 6),
              Text(
                'PODIO · $_period'.toUpperCase(),
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(3, (i) {
              final idx = order[i];
              if (idx >= topThree.length) return const Expanded(child: SizedBox());
              final a = topThree[idx];
              final isFirst = idx == 0;
              final height = podiumHeights[i];
              final label = podiumLabels[i];
              final val = _getValueForMetric(a, _metric);
              final unit = _getMetricUnit(_metric);

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (isFirst)
                        const Icon(
                          Icons.workspace_premium_rounded,
                          color: Color(0xFFFBBF24),
                          size: 24,
                        )
                      else
                        const SizedBox(height: 24),
                      const SizedBox(height: 4),

                      // Avatar
                      Container(
                        width: isFirst ? 54 : 44,
                        height: isFirst ? 54 : 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: isFirst ? AppTheme.fireGradient : null,
                          color: isFirst ? null : const Color(0xFF27272A),
                          border: Border.all(
                            color: isFirst ? AppTheme.primaryGlow : AppTheme.border,
                            width: isFirst ? 2 : 1,
                          ),
                          boxShadow: isFirst
                              ? [
                                  BoxShadow(
                                    color: AppTheme.primary.withValues(alpha: 0.4),
                                    blurRadius: 12,
                                  )
                                ]
                              : null,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          a.initials,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isFirst ? 16 : 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Nombre
                      Text(
                        a.name.split(' ')[0],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      // Valor métrica
                      Text(
                        '${_formatMetricValue(val, _metric)} $unit',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 10,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Podio Base
                      Container(
                        width: double.infinity,
                        height: height,
                        decoration: BoxDecoration(
                          color: isFirst
                              ? AppTheme.primary.withValues(alpha: 0.25)
                              : Colors.black.withValues(alpha: 0.35),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                          border: Border.all(
                            color: isFirst
                                ? AppTheme.primary.withValues(alpha: 0.6)
                                : AppTheme.border.withValues(alpha: 0.6),
                          ),
                        ),
                        alignment: Alignment.topCenter,
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          label,
                          style: TextStyle(
                            fontFamily: 'BebasNeue',
                            fontSize: 28,
                            color: isFirst ? AppTheme.primaryGlow : Colors.white70,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildMyPositionCard({
    required AthleteRankingInfo me,
    required int myIndex,
    required AthleteRankingInfo? aboveMe,
    required int gap,
  }) {
    final valAbove = aboveMe != null ? _getValueForMetric(aboveMe, _metric) : 0;
    final myVal = _getValueForMetric(me, _metric);
    final unit = _getMetricUnit(_metric);

    final double progress = (aboveMe != null && valAbove > 0)
        ? (myVal / valAbove).clamp(0.0, 1.0)
        : 1.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primary.withValues(alpha: 0.15),
            const Color(0xFF18181B).withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.15),
            blurRadius: 15,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          // Puesto
          Column(
            children: [
              Text(
                '#${myIndex + 1}',
                style: const TextStyle(
                  fontFamily: 'BebasNeue',
                  fontSize: 32,
                  color: AppTheme.primaryGlow,
                  height: 1.0,
                ),
              ),
              const Text(
                'TU PUESTO',
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),

          // Información y barra hacia arriba
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        me.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        me.title,
                        style: const TextStyle(
                          color: AppTheme.primaryGlow,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  aboveMe != null
                      ? '${_formatMetricValue(gap, _metric)} $unit para alcanzar a ${aboveMe.name.split(' ')[0]}'
                      : '¡Estás en la cima! Defiende tu puesto.',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 8),

                // Barra de progreso hacia el siguiente
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Container(
                    height: 5,
                    width: double.infinity,
                    color: Colors.black38,
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: progress > 0 ? progress : 0.05,
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: AppTheme.fireGradient,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),

          // Icono Fuego
          const Icon(
            Icons.local_fire_department_rounded,
            color: AppTheme.primary,
            size: 28,
          ),
        ],
      ),
    );
  }

  Widget _buildRankRow({
    required AthleteRankingInfo athlete,
    required int position,
    required int maxVal,
  }) {
    final val = _getValueForMetric(athlete, _metric);
    final unit = _getMetricUnit(_metric);
    final double pct = maxVal > 0 ? (val / maxVal).clamp(0.0, 1.0) : 0.0;

    return Container(
      decoration: BoxDecoration(
        color: athlete.me
            ? AppTheme.primary.withValues(alpha: 0.12)
            : const Color(0xFF18181B).withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: athlete.me
              ? AppTheme.primary.withValues(alpha: 0.6)
              : AppTheme.border.withValues(alpha: 0.5),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Background fill proporcional al máximo
          Positioned.fill(
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: pct,
              child: Container(
                color: AppTheme.primary.withValues(alpha: 0.06),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                // Posición
                SizedBox(
                  width: 24,
                  child: Text(
                    '$position',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'BebasNeue',
                      fontSize: 18,
                      color: position <= 3 ? AppTheme.primaryGlow : Colors.grey,
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Avatar
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: athlete.me ? AppTheme.primary : const Color(0xFF27272A),
                    border: Border.all(
                      color: athlete.me ? AppTheme.primaryGlow : AppTheme.border,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    athlete.initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              athlete.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (athlete.me) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: AppTheme.primary,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'TÚ',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ]
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${athlete.title} • ${athlete.coach}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Valor métrica
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: _formatMetricValue(val, _metric),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          TextSpan(
                            text: ' $unit',
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
