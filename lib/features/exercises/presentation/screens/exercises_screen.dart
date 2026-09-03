import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pyrosfitmovil/core/models/exercise_model.dart';
import 'package:pyrosfitmovil/features/auth/presentation/controllers/auth_provider.dart';
import 'package:pyrosfitmovil/features/exercises/presentation/controllers/exercises_provider.dart';
import 'package:pyrosfitmovil/features/exercises/presentation/widgets/exercise_card.dart';
import 'package:pyrosfitmovil/features/exercises/presentation/widgets/exercise_form_sheet.dart';
import 'package:pyrosfitmovil/features/exercises/presentation/widgets/exercise_video_modal.dart';
import 'package:pyrosfitmovil/theme/app_theme.dart';

class ExercisesScreen extends StatefulWidget {
  const ExercisesScreen({super.key});

  @override
  State<ExercisesScreen> createState() => _ExercisesScreenState();
}

class _ExercisesScreenState extends State<ExercisesScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      final coachId = auth.user?.coachId ?? auth.user?.id ?? 1;
      context.read<ExercisesProvider>().loadData(coachId);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _confirmDelete(BuildContext context, ExerciseModel exercise) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: const Color(0xFF18181B),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: AppTheme.border),
        ),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 22),
            SizedBox(width: 8),
            Text('Eliminar ejercicio', style: TextStyle(color: Colors.white, fontSize: 18)),
          ],
        ),
        content: Text(
          '¿Estás seguro de que deseas eliminar "${exercise.name}"? Esta acción no se puede deshacer.',
          style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogCtx);
              final provider = context.read<ExercisesProvider>();
              final success = await provider.deleteExercise(exercise.id);
              if (context.mounted) {
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Ejercicio eliminado correctamente'),
                      backgroundColor: Color(0xFF10B981),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('No se pudo eliminar el ejercicio (puede estar asignado a una rutina activa)'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExercisesProvider>();
    final items = provider.filteredExercises;
    final muscleGroups = provider.muscleGroups;

    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF09090B),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Row(
          children: [
            Icon(Icons.fitness_center_rounded, color: AppTheme.primaryGlow, size: 20),
            SizedBox(width: 8),
            Text(
              'Ejercicios y Videos',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.2),
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.primary.withValues(alpha: 0.4)),
              ),
              child: const Icon(Icons.add_rounded, color: AppTheme.primaryGlow, size: 18),
            ),
            onPressed: () => ExerciseFormSheet.show(context),
            tooltip: 'Nuevo ejercicio',
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => ExerciseFormSheet.show(context),
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Nuevo ejercicio', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        elevation: 4,
      ),
      body: RefreshIndicator(
        color: AppTheme.primary,
        backgroundColor: const Color(0xFF18181B),
        onRefresh: () async {
          final auth = context.read<AuthProvider>();
          final coachId = auth.user?.coachId ?? auth.user?.id ?? 1;
          await provider.loadData(coachId);
        },
        child: CustomScrollView(
          slivers: [
            // 1. Barra de KPIs Compactos (Total, Con video, Sin video)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF18181B).withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.border.withValues(alpha: 0.6)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildKpiItem(Icons.fitness_center_rounded, 'Total', '${provider.totalCount}', AppTheme.primaryGlow),
                      _buildKpiDivider(),
                      _buildKpiItem(Icons.videocam_rounded, 'Con Video', '${provider.withVideoCount}', const Color(0xFF10B981)),
                      _buildKpiDivider(),
                      _buildKpiItem(Icons.videocam_off_rounded, 'Sin Video', '${provider.withoutVideoCount}', Colors.white54),
                    ],
                  ),
                ),
              ),
            ),

            // 2. Buscador en Tiempo Real
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  onChanged: (val) => provider.setSearchQuery(val),
                  decoration: InputDecoration(
                    hintText: 'Buscar ejercicio, técnica o músculo...',
                    hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                    prefixIcon: const Icon(Icons.search_rounded, color: Colors.white54, size: 18),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 16, color: Colors.white54),
                            onPressed: () {
                              _searchController.clear();
                              provider.setSearchQuery('');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: const Color(0xFF18181B),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppTheme.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppTheme.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppTheme.primary),
                    ),
                  ),
                ),
              ),
            ),

            // 3. Carrusel Horizontal de Chips por Grupo Muscular + Filtro de Video
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.only(top: 10, bottom: 12),
                height: 38,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    // Chip Toggle "Solo con Video"
                    GestureDetector(
                      onTap: () => provider.toggleOnlyVideo(),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: provider.onlyVideo ? AppTheme.primary.withValues(alpha: 0.25) : const Color(0xFF18181B),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: provider.onlyVideo ? AppTheme.primary : AppTheme.border,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.play_circle_outline_rounded,
                              size: 14,
                              color: provider.onlyVideo ? AppTheme.primaryGlow : Colors.white60,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Solo con video',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: provider.onlyVideo ? FontWeight.bold : FontWeight.normal,
                                color: provider.onlyVideo ? Colors.white : Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Chip "Todos"
                    _buildFilterChip('Todos', provider.selectedMuscleGroup == 'Todos', () {
                      provider.setSelectedMuscleGroup('Todos');
                    }),

                    // Chips dinámicos de Grupos Musculares
                    ...muscleGroups.map((mg) {
                      final isSelected = provider.selectedMuscleGroup.toLowerCase() == mg.name.toLowerCase();
                      return _buildFilterChip(mg.name, isSelected, () {
                        provider.setSelectedMuscleGroup(mg.name);
                      });
                    }),
                  ],
                ),
              ),
            ),

            // 4. Lista de Ejercicios o Estados (Cargando / Vacío)
            if (provider.isLoading) ...[
              const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(color: AppTheme.primary),
                ),
              ),
            ] else if (items.isEmpty) ...[
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.fitness_center_outlined, size: 42, color: AppTheme.primaryGlow),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No se encontraron ejercicios',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Prueba cambiando el filtro o registra un nuevo ejercicio técnico.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13, color: Colors.white54, height: 1.3),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: () => ExerciseFormSheet.show(context),
                          icon: const Icon(Icons.add_rounded, size: 18),
                          label: const Text('Crear nuevo ejercicio'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ] else ...[
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final item = items[index];
                      final auth = context.read<AuthProvider>();
                      final currentCoachId = auth.user?.coachId ?? auth.user?.id;
                      final isOwner = currentCoachId != null && item.coachId == currentCoachId;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14.0),
                        child: ExerciseCard(
                          exercise: item,
                          isOwner: isOwner,
                          onPlayVideo: () => ExerciseVideoModal.show(context, item),
                          onEdit: isOwner ? () => ExerciseFormSheet.show(context, exercise: item) : null,
                          onDelete: isOwner ? () => _confirmDelete(context, item) : null,
                        ),
                      );
                    },
                    childCount: items.length,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildKpiItem(IconData icon, String label, String value, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              value,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.white54)),
      ],
    );
  }

  Widget _buildKpiDivider() {
    return Container(
      width: 1,
      height: 20,
      color: Colors.white12,
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : const Color(0xFF18181B),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.primary : AppTheme.border,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : Colors.white70,
          ),
        ),
      ),
    );
  }
}
