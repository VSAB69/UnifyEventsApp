import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:go_router/go_router.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/manage_events_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:unify_events/shared/widgets/r2_image_widget.dart';

class ManageEventModals {
  static Future<void> showDeleteEventModal(
    BuildContext context,
    WidgetRef ref,
    int eventId,
    String eventName,
  ) async {
    return showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1B1B26),
        title: Text(
          'Delete $eventName?',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          'This action cannot be undone. Are you sure you want to delete this event?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              try {
                await ref.read(dioProvider).delete('/events/$eventId/');
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Event Deleted'),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                  ref.invalidate(manageEventsProvider);
                }
              } catch (e) {
                if (ctx.mounted)
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed: $e'),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
              }
            },
            child: const Text(
              'Delete',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Future<void> showOrganisersModal(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> event,
  ) async {
    return showDialog(
      context: context,
      builder: (ctx) => _OrganisersSplitModal(event: event),
    );
  }

  static void showEventModal(
    BuildContext context,
    WidgetRef ref, {
    Map<String, dynamic>? event,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _EventFormModal(event: event),
    );
  }
}

class _OrganisersSplitModal extends ConsumerStatefulWidget {
  final Map<String, dynamic> event;
  const _OrganisersSplitModal({required this.event});
  @override
  ConsumerState<_OrganisersSplitModal> createState() =>
      _OrganisersSplitModalState();
}

class _OrganisersSplitModalState extends ConsumerState<_OrganisersSplitModal> {
  List<int> _assignedIds = [];
  bool _isLoading = false;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _assignedIds = List<int>.from(widget.event['organisers'] ?? []);
  }

  Future<void> _submit() async {
    setState(() => _isLoading = true);
    try {
      await ref
          .read(dioProvider)
          .patch(
            '/events/${widget.event['id']}/',
            data: {"organisers": _assignedIds},
          );
      if (mounted) {
        Navigator.pop(context);
        ref.invalidate(manageEventsProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Organisers saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      String errMsg = e.toString();
      if (e is DioError)
        errMsg = e.response?.data?.toString() ?? e.message ?? "Unknown error";
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed: $errMsg',
              style: const TextStyle(fontSize: 12),
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      print("API ERROR: $errMsg");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final organisersAsync = ref.watch(organisersProvider);

    return AlertDialog(
      backgroundColor: const Color(0xFF1B1B26),
      title: const Text(
        'Manage Organisers',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        height: 400,
        child: organisersAsync.when(
          data: (allOrganisers) {
            final available = allOrganisers
                .where(
                  (o) =>
                      !_assignedIds.contains(o['id']) &&
                      (o['user_display']?.toString().toLowerCase().contains(
                            _search,
                          ) ??
                          false),
                )
                .toList();
            final assignedList = allOrganisers
                .where((o) => _assignedIds.contains(o['id']))
                .toList();

            return Column(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Assigned',
                        style: TextStyle(
                          color: Colors.white54,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF0A0A0F),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: assignedList.isEmpty
                              ? const Center(
                                  child: Text(
                                    'None',
                                    style: TextStyle(color: Colors.white54),
                                  ),
                                )
                              : ListView.builder(
                                  itemCount: assignedList.length,
                                  itemBuilder: (ctx, i) => ListTile(
                                    title: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            assignedList[i]['user_display'] ??
                                                'ID: ${assignedList[i]['id']}',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 13,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    trailing: IconButton(
                                      icon: const Icon(
                                        Icons.remove_circle,
                                        color: Colors.redAccent,
                                        size: 20,
                                      ),
                                      onPressed: () => setState(
                                        () => _assignedIds.remove(
                                          assignedList[i]['id'],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Available',
                        style: TextStyle(
                          color: Colors.white54,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      TextField(
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                        ),
                        onChanged: (v) =>
                            setState(() => _search = v.toLowerCase()),
                        decoration: InputDecoration(
                          hintText: 'Search...',
                          hintStyle: const TextStyle(color: Colors.white54),
                          filled: true,
                          fillColor: const Color(0xFF0A0A0F),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 8,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF0A0A0F),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ListView.builder(
                            itemCount: available.length,
                            itemBuilder: (ctx, i) => ListTile(
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      available[i]['user_display'] ??
                                          'ID: ${available[i]['id']}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              trailing: IconButton(
                                icon: const Icon(
                                  Icons.add_circle,
                                  color: Color(0xFF7C3AED),
                                  size: 20,
                                ),
                                onPressed: () => setState(
                                  () => _assignedIds.add(available[i]['id']),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const Center(
            child: Text(
              'Failed to load organisers',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF7C3AED),
          ),
          onPressed: _isLoading ? null : _submit,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Text('Save', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}

class _EventFormModal extends ConsumerStatefulWidget {
  final Map<String, dynamic>? event;
  const _EventFormModal({this.event});
  @override
  ConsumerState<_EventFormModal> createState() => _EventFormModalState();
}

class _EventFormModalState extends ConsumerState<_EventFormModal> {
  late TextEditingController _nameCtrl;
  late TextEditingController _committeeCtrl;
  late TextEditingController _priceCtrl;
  int? _selectedParentEventId;
  int? _selectedCategoryId;
  bool _isExclusive = false;
  File? _imageFile;
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(
      text: widget.event?['name']?.toString() ?? '',
    );
    _committeeCtrl = TextEditingController(
      text: widget.event?['parent_committee']?.toString() ?? '',
    );
    _priceCtrl = TextEditingController(
      text: widget.event?['price']?.toString() ?? '',
    );

    _selectedParentEventId = widget.event?['parent_event'] is int
        ? widget.event!['parent_event']
        : int.tryParse(widget.event?['parent_event']?.toString() ?? '');
    _selectedCategoryId = widget.event?['category'] is int
        ? widget.event!['category']
        : int.tryParse(widget.event?['category']?.toString() ?? '');
    _isExclusive =
        widget.event?['exclusivity'] == true ||
        widget.event?['exclusivity'] == 'EXCLUSIVE';
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) setState(() => _imageFile = File(picked.path));
  }

  Future<void> _submit() async {
    setState(() => _isLoading = true);
    try {
      FormData fd = FormData();
      Map<String, dynamic> payload = {};

      if (widget.event == null) {
        if (_nameCtrl.text.isNotEmpty) payload["name"] = _nameCtrl.text;
        if (_committeeCtrl.text.isNotEmpty)
          payload["parent_committee"] = _committeeCtrl.text;
        if (_selectedParentEventId != null)
          payload["parent_event"] = _selectedParentEventId;
        if (_selectedCategoryId != null)
          payload["category"] = _selectedCategoryId;
        if (_priceCtrl.text.isNotEmpty)
          payload["price"] = int.tryParse(_priceCtrl.text) ?? 0;
        payload["exclusivity"] = _isExclusive ? "true" : "false";
      } else {
        if (_nameCtrl.text != widget.event!['name'])
          payload["name"] = _nameCtrl.text;
        if (_committeeCtrl.text !=
            widget.event!['parent_committee']?.toString())
          payload["parent_committee"] = _committeeCtrl.text;
        if (_selectedParentEventId != widget.event!['parent_event'])
          payload["parent_event"] = _selectedParentEventId;
        if (_selectedCategoryId != widget.event!['category'])
          payload["category"] = _selectedCategoryId;
        if (int.tryParse(_priceCtrl.text) != widget.event!['price'])
          payload["price"] = int.tryParse(_priceCtrl.text) ?? 0;
        final exc = _isExclusive ? "true" : "false";
        if (exc != widget.event!['exclusivity']?.toString().toLowerCase())
          payload["exclusivity"] = exc;
      }

      for (var entry in payload.entries) {
        if (entry.value != null && entry.value.toString().isNotEmpty) {
          fd.fields.add(MapEntry(entry.key, entry.value.toString()));
        }
      }

      if (_imageFile != null) {
        fd.files.add(
          MapEntry("image", await MultipartFile.fromFile(_imageFile!.path)),
        );
      }

      final dio = ref.read(dioProvider);
      if (widget.event == null) {
        await dio.post('/events/', data: fd);
      } else {
        await dio.patch('/events/${widget.event!['id']}/', data: fd);
      }

      if (mounted) {
        Navigator.pop(context);
        ref.invalidate(manageEventsProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Event saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      String errMsg = e.toString();
      if (e is DioError)
        errMsg = e.response?.data?.toString() ?? e.message ?? "Unknown error";
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed: $errMsg',
              style: const TextStyle(fontSize: 12),
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      print("API ERROR: $errMsg");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final parentEventsAsync = ref.watch(parentEventsProvider);

    return SafeArea(
      child: Container(
        height: MediaQuery.of(context).size.height * 0.85,
        padding: const EdgeInsets.only(bottom: 20),
        decoration: const BoxDecoration(
          color: Color(0xFF1B1B26),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.event == null ? 'Create Event' : 'Edit Event',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              _buildField('Event Name', _nameCtrl),
              const SizedBox(height: 16),
              _buildField('Parent Committee ID (optional)', _committeeCtrl),
              const SizedBox(height: 16),
              categoriesAsync.when(
                data: (cats) => DropdownButtonFormField<int>(
                  value: _selectedCategoryId,
                  dropdownColor: const Color(0xFF1B1B26),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Category',
                    labelStyle: const TextStyle(color: Colors.white54),
                    filled: true,
                    fillColor: const Color(0xFF0A0A0F),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: cats
                      .map(
                        (c) => DropdownMenuItem<int>(
                          value: c['id'],
                          child: Text(c['name'] ?? 'ID: ${c['id']}'),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _selectedCategoryId = v),
                ),
                loading: () => const CircularProgressIndicator(),
                error: (_, __) => const Text(
                  'Failed to load categories',
                  style: TextStyle(color: Colors.red),
                ),
              ),
              const SizedBox(height: 16),
              parentEventsAsync.when(
                data: (parents) => DropdownButtonFormField<int>(
                  value: _selectedParentEventId,
                  dropdownColor: const Color(0xFF1B1B26),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Parent Event (optional)',
                    labelStyle: const TextStyle(color: Colors.white54),
                    filled: true,
                    fillColor: const Color(0xFF0A0A0F),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: [
                    const DropdownMenuItem<int>(
                      value: null,
                      child: Text("None"),
                    ),
                    ...parents.map(
                      (p) => DropdownMenuItem<int>(
                        value: p['id'],
                        child: Text(p['name'] ?? 'ID: ${p['id']}'),
                      ),
                    ),
                  ],
                  onChanged: (v) => setState(() => _selectedParentEventId = v),
                ),
                loading: () => const CircularProgressIndicator(),
                error: (_, __) => const Text(
                  'Failed to load events',
                  style: TextStyle(color: Colors.red),
                ),
              ),
              const SizedBox(height: 16),
              _buildField('Price', _priceCtrl, isNum: true),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text(
                  'Exclusive Event',
                  style: TextStyle(color: Colors.white),
                ),
                activeColor: const Color(0xFF7C3AED),
                value: _isExclusive,
                onChanged: (v) => setState(() => _isExclusive = v),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 120,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A0A0F),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF7C3AED).withOpacity(0.5),
                    ),
                  ),
                  child: _imageFile != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(_imageFile!, fit: BoxFit.cover),
                        )
                      : (widget.event?['image_key'] != null &&
                            widget.event!['image_key'].toString().isNotEmpty)
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: R2ImageWidget(
                            imageKey: widget.event!['image_key'],
                            fit: BoxFit.cover,
                          ),
                        )
                      : const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.image,
                              color: Color(0xFF7C3AED),
                              size: 32,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'No Image',
                              style: TextStyle(color: Colors.white54),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C3AED),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _isLoading ? null : _submit,
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Save Event',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController ctrl, {
    bool isNum = false,
  }) {
    return TextField(
      controller: ctrl,
      style: const TextStyle(color: Colors.white),
      keyboardType: isNum ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        filled: true,
        fillColor: const Color(0xFF0A0A0F),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
