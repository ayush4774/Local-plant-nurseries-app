import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/auth_providers.dart';
import '../models/plant.dart';
import '../data/plant_repository.dart';
import '../data/user_plant_repository.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  final PlantRepository _catalogRepo = PlantRepository();
  final UserPlantRepository _userRepo = UserPlantRepository();
  Timer? _debounce;

  String _selectedType = 'all'; // all, indoor, outdoor
  String _selectedMaintenance = 'all'; // all, low, medium, high

  List<Plant> _allPlants = [];
  List<Plant> _searchResults = [];
  Set<String> _userPlantIds = {};
  bool _isLoading = false;
  bool _hasSearched = false;
  bool _isLoadingCatalog = true;

  @override
  void initState() {
    super.initState();
    _loadCatalog();
    _loadUserPlantIds();
  }

  Future<void> _loadCatalog() async {
    final plants = await _catalogRepo.fetchPlants();
    setState(() {
      _allPlants = plants;
      _searchResults = plants;
      _hasSearched = true;
      _isLoadingCatalog = false;
    });
  }

  Future<void> _loadUserPlantIds() async {
    final userPlants = await _userRepo.fetchUserPlants();
    setState(() {
      _userPlantIds = userPlants.map((p) => p.id).toSet();
    });
  }

  Future<void> _addPlantToCollection(Plant plant) async {
    final added = await _userRepo.addPlantToCollection(plant);
    if (added && mounted) {
      setState(() {
        _userPlantIds.add(plant.id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${plant.name} added to your collection!'),
          backgroundColor: const Color(0xFF2E7D32),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${plant.name} is already in your collection'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _performSearch(query);
    });
  }

  void _performSearch(String query) {
    setState(() {
      _isLoading = true;
      _hasSearched = true;
    });

    Future.delayed(const Duration(milliseconds: 100), () {
      List<Plant> results = _allPlants;

      // Filter by search query
      if (query.isNotEmpty) {
        final lowerQuery = query.toLowerCase();
        results = results.where((plant) {
          return plant.name.toLowerCase().contains(lowerQuery) ||
              (plant.description?.toLowerCase().contains(lowerQuery) ??
                  false) ||
              (plant.scientificName?.toLowerCase().contains(lowerQuery) ??
                  false) ||
              (plant.category?.toLowerCase().contains(lowerQuery) ?? false);
        }).toList();
      }

      // Filter by type
      if (_selectedType != 'all') {
        results =
            results.where((plant) => plant.type == _selectedType).toList();
      }

      // Filter by maintenance
      if (_selectedMaintenance != 'all') {
        results = results
            .where((plant) => plant.maintenance == _selectedMaintenance)
            .toList();
      }

      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF121212) : const Color(0xFFF5F8F5),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(isDark),
            _buildFilters(isDark),
            const SizedBox(height: 12),
            Expanded(
              child: _buildResults(isDark),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(isDark ? 40 : 13),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.arrow_back,
                    color: Color(0xFF2E7D32),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Text(
                'Search Plants',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.grey.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(isDark ? 40 : 13),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocus,
              onChanged: _onSearchChanged,
              style: TextStyle(color: isDark ? Colors.white : Colors.black),
              decoration: InputDecoration(
                hintText: 'Search for plants, care tips...',
                hintStyle: TextStyle(
                    color:
                        isDark ? Colors.grey.shade500 : Colors.grey.shade400),
                prefixIcon: const Icon(
                  Icons.search,
                  color: Color(0xFF2E7D32),
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear,
                            color: isDark
                                ? Colors.grey.shade500
                                : Colors.grey.shade400),
                        onPressed: () {
                          _searchController.clear();
                          _performSearch('');
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(bool isDark) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _buildFilterChip(
            label: 'All Types',
            isSelected: _selectedType == 'all',
            onTap: () {
              setState(() => _selectedType = 'all');
              _performSearch(_searchController.text);
            },
            isDark: isDark,
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: '🏠 Indoor',
            isSelected: _selectedType == 'indoor',
            onTap: () {
              setState(() => _selectedType = 'indoor');
              _performSearch(_searchController.text);
            },
            isDark: isDark,
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: '🌳 Outdoor',
            isSelected: _selectedType == 'outdoor',
            onTap: () {
              setState(() => _selectedType = 'outdoor');
              _performSearch(_searchController.text);
            },
            isDark: isDark,
          ),
          const SizedBox(width: 16),
          Container(
            width: 1,
            height: 30,
            color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
          ),
          const SizedBox(width: 16),
          _buildFilterChip(
            label: 'All Care',
            isSelected: _selectedMaintenance == 'all',
            onTap: () {
              setState(() => _selectedMaintenance = 'all');
              _performSearch(_searchController.text);
            },
            isDark: isDark,
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: '🌱 Low',
            isSelected: _selectedMaintenance == 'low',
            onTap: () {
              setState(() => _selectedMaintenance = 'low');
              _performSearch(_searchController.text);
            },
            isDark: isDark,
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: '🌿 Medium',
            isSelected: _selectedMaintenance == 'medium',
            onTap: () {
              setState(() => _selectedMaintenance = 'medium');
              _performSearch(_searchController.text);
            },
            isDark: isDark,
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: '🌲 High',
            isSelected: _selectedMaintenance == 'high',
            onTap: () {
              setState(() => _selectedMaintenance = 'high');
              _performSearch(_searchController.text);
            },
            isDark: isDark,
          ),
          const SizedBox(width: 20),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF2E7D32)
              : (isDark ? const Color(0xFF1E1E1E) : Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF2E7D32)
                : (isDark ? Colors.grey.shade700 : Colors.grey.shade300),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF2E7D32).withAlpha(77),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? Colors.white
                : (isDark ? Colors.grey.shade300 : Colors.grey.shade700),
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildResults(bool isDark) {
    if (_isLoadingCatalog) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              color: Color(0xFF2E7D32),
            ),
            const SizedBox(height: 16),
            Text(
              'Loading plant catalog...',
              style: TextStyle(
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF2E7D32),
        ),
      );
    }

    if (!_hasSearched) {
      return _buildInitialState(isDark);
    }

    if (_searchResults.isEmpty) {
      return _buildEmptyState(isDark);
    }

    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return ListView.builder(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 8,
        bottom: 20 + bottomPadding,
      ),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        return _buildResultCard(_searchResults[index], isDark);
      },
    );
  }

  Widget _buildInitialState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF2E7D32).withAlpha(isDark ? 40 : 26),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.search,
              size: 60,
              color: Color(0xFF2E7D32),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Find Your Perfect Plant',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Search by name or browse categories',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _buildSuggestionChip('Tulsi', isDark),
              _buildSuggestionChip('Money Plant', isDark),
              _buildSuggestionChip('Neem', isDark),
              _buildSuggestionChip('Medicinal', isDark),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            '${_allPlants.length} plants available',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey.shade500 : Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionChip(String text, bool isDark) {
    return GestureDetector(
      onTap: () {
        _searchController.text = text;
        _performSearch(text);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF2E7D32).withAlpha(77)),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Color(0xFF2E7D32),
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.eco_outlined,
            size: 80,
            color: isDark ? Colors.grey.shade600 : Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'No plants found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search or filters',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard(Plant plant, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 40 : 13),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.hardEdge,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top section: image + name/description
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color:
                            const Color(0xFF2E7D32).withAlpha(isDark ? 40 : 26),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: plant.imageUrl != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.network(
                                plant.imageUrl!,
                                fit: BoxFit.cover,
                              ),
                            )
                          : const Icon(
                              Icons.eco,
                              color: Color(0xFF2E7D32),
                              size: 40,
                            ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  plant.name,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF333333),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: plant.type == 'indoor'
                                      ? (isDark
                                          ? Colors.blue.shade900.withAlpha(77)
                                          : Colors.blue.shade50)
                                      : (isDark
                                          ? Colors.green.shade900.withAlpha(77)
                                          : Colors.green.shade50),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  plant.type == 'indoor'
                                      ? '🏠 Indoor'
                                      : '🌳 Outdoor',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: plant.type == 'indoor'
                                        ? (isDark
                                            ? Colors.blue.shade300
                                            : Colors.blue.shade700)
                                        : (isDark
                                            ? Colors.green.shade300
                                            : Colors.green.shade700),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            plant.description ?? '',
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark
                                  ? Colors.grey.shade400
                                  : Colors.grey.shade600,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Bottom section: quick info + add button (full card width)
                Row(
                  children: [
                    _buildQuickInfo(
                      Icons.water_drop_outlined,
                      '${plant.wateringFrequency}d',
                      Colors.blue,
                      isDark,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildQuickInfo(
                        Icons.wb_sunny_outlined,
                        plant.sunlight,
                        Colors.orange,
                        isDark,
                      ),
                    ),
                    const SizedBox(width: 10),
                    _buildQuickInfo(
                      Icons.spa_outlined,
                      plant.maintenance,
                      Colors.green,
                      isDark,
                    ),
                    const SizedBox(width: 10),
                    _buildAddButton(plant, isDark),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickInfo(IconData icon, String text, Color color, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 3),
        Flexible(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildAddButton(Plant plant, bool isDark) {
    final isInCollection = _userPlantIds.contains(plant.id);

    return GestureDetector(
      onTap: isInCollection ? null : () => _addPlantToCollection(plant),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isInCollection
              ? (isDark ? Colors.grey.shade800 : Colors.grey.shade200)
              : const Color(0xFF2E7D32),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isInCollection ? Icons.check : Icons.add,
              size: 16,
              color: isInCollection
                  ? (isDark ? Colors.grey.shade500 : Colors.grey.shade600)
                  : Colors.white,
            ),
            const SizedBox(width: 4),
            Text(
              isInCollection ? 'Added' : 'Add',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isInCollection
                    ? (isDark ? Colors.grey.shade500 : Colors.grey.shade600)
                    : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
