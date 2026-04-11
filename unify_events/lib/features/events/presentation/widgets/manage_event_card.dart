import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/widgets/r2_image_widget.dart';
import 'manage_event_modals.dart';
import 'manage_event_sub_modals.dart';

class ManageEventCard extends ConsumerStatefulWidget {
  final Map<String, dynamic> event;
  final bool isAdmin;

  const ManageEventCard({super.key, required this.event, required this.isAdmin});

  @override
  ConsumerState<ManageEventCard> createState() => _ManageEventCardState();
}

class _ManageEventCardState extends ConsumerState<ManageEventCard> with SingleTickerProviderStateMixin {
  bool _isHovered = false;

  void _onHover(bool isHovered) => setState(() => _isHovered = isHovered);

  @override
  Widget build(BuildContext context) {
    final eventName = widget.event['name'] ?? 'Unnamed Event';
    final committee = widget.event['parent_committee']?.toString() ?? 'Main Committee';
    final price = widget.event['price']?.toString() ?? 'FREE';
    final isExclusive = widget.event['exclusivity'] == 'EXCLUSIVE';
    final imageKey = widget.event['banner_image'];

    // Status parsing
    int parseSafeInt(dynamic val) {
      if (val is int) return val;
      if (val is num) return val.toInt();
      if (val is String) return int.tryParse(val) ?? 0;
      return 0;
    }

    final detailsId = parseSafeInt(widget.event['details_id']);
    final constraintId = parseSafeInt(widget.event['constraint_id']);
    final slotsCount = parseSafeInt(widget.event['slots_count']);

    print("EVENT CARD RENDER: ${widget.event}");

    return MouseRegion(
      onEnter: (_) => _onHover(true),
      onExit: (_) => _onHover(false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        transform: Matrix4.identity()..translate(0.0, _isHovered ? -5.0 : 0.0),
        decoration: BoxDecoration(
          color: const Color(0xFF13131D),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _isHovered ? const Color(0xFF7C3AED).withOpacity(0.5) : Colors.white.withOpacity(0.05)),
          boxShadow: [
            if (_isHovered) BoxShadow(color: const Color(0xFF7C3AED).withOpacity(0.15), blurRadius: 20, spreadRadius: -5)
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // IMAGE COVER
            if (imageKey != null)
              SizedBox(
                height: 120,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  child: R2ImageWidget(imageKey: imageKey, borderRadius: 0),
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // HEADER INFO
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: const Color(0xFF7C3AED).withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                        child: Text(committee, style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 12, fontWeight: FontWeight.w600)),
                      ),
                      Row(
                        children: [
                          Text('₹$price', style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 14)),
                          const SizedBox(width: 8),
                          Icon(isExclusive ? Icons.lock : Icons.public, size: 14, color: isExclusive ? Colors.orange : Colors.white54),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // BODY
                  Text(eventName, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 16),

                  // STATUS INDICATORS
                  Row(
                    children: [
                      _buildStatusChip(detailsId > 0, 'Details'),
                      const SizedBox(width: 8),
                      _buildStatusChip(constraintId > 0, 'Constraints'),
                      const SizedBox(width: 8),
                      _buildStatusChip(slotsCount > 0, 'Slots'),
                    ],
                  ),

                  const SizedBox(height: 20),
                  const Divider(color: Colors.white10),
                  const SizedBox(height: 12),

                  // ACTION BUTTONS GRID
                  Wrap(
                    spacing: 8,
                    runSpacing: 12,
                    children: [
                      _buildActionButton(Icons.edit, 'Edit Event', () => ManageEventModals.showEventModal(context, ref, event: widget.event)),
                      _buildActionButton(Icons.info_outline, 'Details', () => ManageEventSubModals.showDetailsModal(context, ref, widget.event['id'])),
                      _buildActionButton(Icons.rule, 'Constraints', () => ManageEventSubModals.showConstraintsModal(context, ref, widget.event['id'])),
                      _buildActionButton(Icons.schedule, 'Slots', () => ManageEventSubModals.showSlotsModal(context, ref, widget.event['id'])),
                      _buildActionButton(Icons.group, 'Attendance', () { /* Map to Attendance UI */ }),
                      
                      if (widget.isAdmin) ...[
                        _buildActionButton(Icons.admin_panel_settings, 'Organisers', () => ManageEventModals.showOrganisersModal(context, ref, widget.event), isWarning: true),
                        _buildActionButton(Icons.delete_outline, 'Delete', () => ManageEventModals.showDeleteEventModal(context, ref, widget.event['id'], eventName), isDestructive: true),
                      ]
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(bool isActive, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? Colors.green.withOpacity(0.15) : Colors.red.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isActive ? Colors.green.withOpacity(0.5) : Colors.red.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isActive ? Icons.check_circle : Icons.cancel, size: 12, color: isActive ? Colors.green : Colors.red),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: isActive ? Colors.green : Colors.red, fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, VoidCallback onTap, {bool isDestructive = false, bool isWarning = false}) {
    Color baseColor = isDestructive ? Colors.redAccent : (isWarning ? Colors.orange : Colors.white);
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: baseColor.withOpacity(0.1),
          border: Border.all(color: baseColor.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: baseColor),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(color: baseColor, fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
