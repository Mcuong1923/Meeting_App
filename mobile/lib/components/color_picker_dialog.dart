import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:metting_app/providers/theme_provider.dart';

class ColorPickerDialog extends StatefulWidget {
  final Color currentColor;
  final Function(Color) onColorSelected;

  const ColorPickerDialog({
    Key? key,
    required this.currentColor,
    required this.onColorSelected,
  }) : super(key: key);

  @override
  State<ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<ColorPickerDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Color _selectedColor;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _selectedColor = widget.currentColor;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    return Dialog(
      backgroundColor:
          themeProvider.isDarkMode ? const Color(0xFF1C1C1E) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        width: 320,
        height: 580,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: _selectedColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Chọn Màu Chủ Đề - ',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: themeProvider.isDarkMode
                        ? Colors.white
                        : Colors.black87,
                  ),
                ),
                const Text(
                  'Đặt Lại',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Tab Bar
            Container(
              decoration: BoxDecoration(
                color: themeProvider.isDarkMode
                    ? const Color(0xFF2C2C2E)
                    : const Color(0xFFF2F2F7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: themeProvider.isDarkMode
                      ? const Color(0xFF1C1C1E)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                indicatorPadding: const EdgeInsets.all(2),
                labelColor:
                    themeProvider.isDarkMode ? Colors.white : Colors.black87,
                unselectedLabelColor: themeProvider.isDarkMode
                    ? Colors.white60
                    : Colors.grey[600],
                labelStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                tabs: const [
                  Tab(text: 'Primary'),
                  Tab(text: 'Accent'),
                  Tab(text: 'Black & White'),
                  Tab(text: 'Wheel'),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Tab Views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildPrimaryColorsTab(),
                  _buildAccentColorsTab(),
                  _buildBlackWhiteTab(),
                  _buildWheelTab(),
                ],
              ),
            ),

            // Bottom Buttons
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Hủy',
                    style: TextStyle(
                      fontSize: 16,
                      color: themeProvider.isDarkMode
                          ? Colors.white70
                          : Colors.grey,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    widget.onColorSelected(_selectedColor);
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selectedColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'OK',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrimaryColorsTab() {
    final primaryColors = [
      // Row 1 - Reds
      const Color(0xFFFF3B30), const Color(0xFFFF2D92), const Color(0xFFE91E63),
      const Color(0xFFFF006B), const Color(0xFF9C27B0), const Color(0xFFBB86FC),

      // Row 2 - Purples & Blues
      const Color(0xFF673AB7), const Color(0xFF5856D6), const Color(0xFF3F51B5),
      const Color(0xFF2196F3), const Color(0xFF00BCD4), const Color(0xFF0099CC),

      // Row 3 - Cyans & Teals
      const Color(0xFF00DDFF), const Color(0xFF00C7BE), const Color(0xFF009688),
      const Color(0xFF00E676), const Color(0xFF4CAF50), const Color(0xFF8BC34A),

      // Row 4 - Greens & Yellows
      const Color(0xFF4CAF50), const Color(0xFF64DD17), const Color(0xFF76FF03),
      const Color(0xFFCDDC39), const Color(0xFFFFEB3B), const Color(0xFFFFC107),

      // Row 5 - Yellows & Oranges
      const Color(0xFFFFEB3B), const Color(0xFFFFD600), const Color(0xFFFF9800),
      const Color(0xFFFF8F00), const Color(0xFFFF5722), const Color(0xFFFF6D00),

      // Row 6 - Neutrals
      const Color(0xFFE91E63), const Color(0xFFD32F2F), const Color(0xFF8D6E63),
      const Color(0xFF607D8B), const Color(0xFF9E9E9E),
    ];

    return _buildColorGrid(primaryColors);
  }

  Widget _buildAccentColorsTab() {
    final accentColors = [
      // Light Blues
      const Color(0xFFE3F2FD), const Color(0xFFBBDEFB), const Color(0xFF90CAF9),
      const Color(0xFF64B5F6), const Color(0xFF42A5F5), const Color(0xFF2196F3),

      // Medium Blues
      const Color(0xFF1E88E5), const Color(0xFF1976D2), const Color(0xFF1565C0),
      const Color(0xFF0D47A1), const Color(0xFF0A3D91), const Color(0xFF003C8F),
    ];

    return _buildColorGrid(accentColors);
  }

  Widget _buildBlackWhiteTab() {
    final blackWhiteColors = [
      Colors.white,
      const Color(0xFFF5F5F5),
      const Color(0xFFEEEEEE),
      const Color(0xFFE0E0E0),
      const Color(0xFFBDBDBD),
      const Color(0xFF9E9E9E),
      const Color(0xFF757575),
      const Color(0xFF616161),
      const Color(0xFF424242),
      const Color(0xFF212121),
      Colors.black,
    ];

    return _buildColorGrid(blackWhiteColors);
  }

  Widget _buildWheelTab() {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    return Center(
      child: Text(
        'Color Wheel\n(Đang phát triển)',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 16,
          color: themeProvider.isDarkMode ? Colors.white70 : Colors.grey,
        ),
      ),
    );
  }

  Widget _buildColorGrid(List<Color> colors) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 6,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemCount: colors.length,
      itemBuilder: (context, index) {
        final color = colors[index];
        final isSelected = color.value == _selectedColor.value;

        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedColor = color;
            });
          },
          child: Container(
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
              border: color == Colors.white
                  ? Border.all(color: Colors.grey[300]!, width: 1)
                  : null,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: isSelected
                ? Icon(
                    Icons.check,
                    color: _getContrastColor(color),
                    size: 20,
                  )
                : null,
          ),
        );
      },
    );
  }

  Color _getContrastColor(Color color) {
    // Calculate luminance to determine if text should be black or white
    final luminance =
        (0.299 * color.red + 0.587 * color.green + 0.114 * color.blue) / 255;
    return luminance > 0.5 ? Colors.black : Colors.white;
  }
}
