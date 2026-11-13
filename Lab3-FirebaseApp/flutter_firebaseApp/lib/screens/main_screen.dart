import 'package:flutter/material.dart';
import '../services/google_sheet_service.dart';
import 'class_selection_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  final GoogleSheetService _sheetService = GoogleSheetService();

  @override
  Widget build(BuildContext context) {
    const fptNavy = Color(0xFF0B1F3A);
    const fptOrange = Color(0xFFF37021);

    return Scaffold(
      body: Row(
        children: [
          Container(
            width: 232,
            color: fptNavy,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 28, 16, 28),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: fptOrange,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.school, color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'FAP Attendance',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildNavItem(
                  icon: Icons.fact_check_outlined,
                  label: 'Điểm danh lớp',
                  selected: _selectedIndex == 0,
                  onTap: () => setState(() => _selectedIndex = 0),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                  child: Row(
                    children: [
                      Icon(Icons.cloud_done_outlined, color: Colors.green.shade300, size: 18),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Google Sheets DB',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: [
                ClassSelectionScreen(sheetService: _sheetService),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Material(
        color: selected ? Colors.white.withValues(alpha: 0.14) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
            child: Row(
              children: [
                Icon(icon, color: selected ? const Color(0xFFF37021) : Colors.white70, size: 21),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    color: selected ? Colors.white : Colors.white70,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
