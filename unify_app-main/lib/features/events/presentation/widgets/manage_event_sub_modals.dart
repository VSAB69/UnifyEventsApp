import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/manage_events_provider.dart';

class ManageEventSubModals {
  static void showDetailsModal(
    BuildContext context,
    WidgetRef ref,
    int eventId,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => _DetailsModal(eventId: eventId),
    );
  }

  static void showConstraintsModal(
    BuildContext context,
    WidgetRef ref,
    int eventId,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => _ConstraintsModal(eventId: eventId),
    );
  }

  static void showSlotsModal(BuildContext context, WidgetRef ref, int eventId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _SlotsListModal(eventId: eventId),
    );
  }
}

// --------------------------------------------------------------------------
// EVENT DETAILS MODAL
// --------------------------------------------------------------------------
class _DetailsModal extends ConsumerStatefulWidget {
  final int eventId;
  const _DetailsModal({required this.eventId});
  @override
  ConsumerState<_DetailsModal> createState() => _DetailsModalState();
}

class _DetailsModalState extends ConsumerState<_DetailsModal> {
  bool _isFetching = true;
  bool _isLoading = false;
  Map<String, dynamic>? _details;
  final venueCtrl = TextEditingController();
  final aboutCtrl = TextEditingController();
  DateTime? startDateTime;
  DateTime? endDateTime;

  @override
  void initState() {
    super.initState();
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    try {
      final res = await ref
          .read(dioProvider)
          .get('/event-details/', queryParameters: {'event': widget.eventId});
      List<dynamic> data = [];
      if (res.data is List)
        data = res.data;
      else if (res.data is Map && res.data['results'] != null)
        data = res.data['results'];

      if (data.isNotEmpty) {
        _details = data.first;
        venueCtrl.text = _details!['venue']?.toString() ?? '';
        aboutCtrl.text =
            _details!['description']?.toString() ??
            _details!['about']?.toString() ??
            '';
        startDateTime = _details!['start_datetime'] != null
            ? DateTime.tryParse(_details!['start_datetime'])
            : null;
        endDateTime = _details!['end_datetime'] != null
            ? DateTime.tryParse(_details!['end_datetime'])
            : null;
      }
    } catch (_) {}
    if (mounted) setState(() => _isFetching = false);
  }

  Future<void> _pickDateTime(bool isStart) async {
    final current = isStart ? startDateTime : endDateTime;
    final date = await showDatePicker(
      context: context,
      initialDate: current ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(current ?? DateTime.now()),
      );
      if (time != null && mounted) {
        setState(() {
          final dt = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
          if (isStart)
            startDateTime = dt;
          else
            endDateTime = dt;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isFetching) {
      return const AlertDialog(
        backgroundColor: Color(0xFF1B1B26),
        content: SizedBox(
          height: 100,
          child: Center(
            child: CircularProgressIndicator(color: Color(0xFF7C3AED)),
          ),
        ),
      );
    }

    final bool exists = _details != null;

    return AlertDialog(
      backgroundColor: const Color(0xFF1B1B26),
      title: Text(
        exists ? 'Edit Details' : 'Add Details',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Container(
        padding: const EdgeInsets.only(bottom: 20),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: venueCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Venue',
                  labelStyle: const TextStyle(color: Colors.white54),
                  filled: true,
                  fillColor: const Color(0xFF0A0A0F),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: aboutCtrl,
                maxLines: 3,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Description',
                  labelStyle: const TextStyle(color: Colors.white54),
                  filled: true,
                  fillColor: const Color(0xFF0A0A0F),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                title: const Text(
                  'Start Date & Time',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
                subtitle: Text(
                  startDateTime?.toString().split('.')[0] ?? 'Select...',
                  style: const TextStyle(color: Colors.white),
                ),
                trailing: const Icon(
                  Icons.calendar_month,
                  color: Color(0xFF7C3AED),
                ),
                onTap: () => _pickDateTime(true),
              ),
              ListTile(
                title: const Text(
                  'End Date & Time',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
                subtitle: Text(
                  endDateTime?.toString().split('.')[0] ?? 'Select...',
                  style: const TextStyle(color: Colors.white),
                ),
                trailing: const Icon(
                  Icons.calendar_month,
                  color: Color(0xFF7C3AED),
                ),
                onTap: () => _pickDateTime(false),
              ),
            ],
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
          onPressed: _isLoading
              ? null
              : () async {
                  setState(() => _isLoading = true);
                  try {
                    final payload = {
                      "event": widget.eventId,
                      "venue": venueCtrl.text,
                      "description": aboutCtrl.text,
                      if (startDateTime != null)
                        "start_datetime": startDateTime!.toIso8601String(),
                      if (endDateTime != null)
                        "end_datetime": endDateTime!.toIso8601String(),
                    };
                    payload.removeWhere((k, v) => v == null || v == "");

                    if (exists) {
                      await ref
                          .read(dioProvider)
                          .patch(
                            '/event-details/${_details!['id']}/',
                            data: payload,
                          );
                    } else {
                      await ref
                          .read(dioProvider)
                          .post('/event-details/', data: payload);
                    }
                    if (context.mounted) {
                      Navigator.pop(context);
                      ref.invalidate(manageEventsProvider);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Details saved successfully'),
                        ),
                      );
                    }
                  } catch (e) {
                    String errMsg = e.toString();
                    if (e is DioError)
                      errMsg =
                          e.response?.data?.toString() ??
                          e.message ??
                          "Unknown error";
                    if (context.mounted)
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Failed: $errMsg',
                            style: const TextStyle(fontSize: 12),
                          ),
                          backgroundColor: Colors.red,
                        ),
                      );
                    print("API ERROR: $errMsg");
                  }
                  if (mounted) setState(() => _isLoading = false);
                },
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

// --------------------------------------------------------------------------
// CONSTRAINTS MODAL
// --------------------------------------------------------------------------
class _ConstraintsModal extends ConsumerStatefulWidget {
  final int eventId;
  const _ConstraintsModal({required this.eventId});
  @override
  ConsumerState<_ConstraintsModal> createState() => _ConstraintsModalState();
}

class _ConstraintsModalState extends ConsumerState<_ConstraintsModal> {
  bool _isFetching = true;
  bool _isLoading = false;
  Map<String, dynamic>? _constraint;

  String bookingType = 'single';
  final lowerLimitCtrl = TextEditingController(text: '1');
  final upperLimitCtrl = TextEditingController(text: '1');
  bool isFixed = true;

  @override
  void initState() {
    super.initState();
    _fetchConstraints();
  }

  Future<void> _fetchConstraints() async {
    try {
      final res = await ref
          .read(dioProvider)
          .get('/constraints/', queryParameters: {'event': widget.eventId});
      List<dynamic> data = [];
      if (res.data is List)
        data = res.data;
      else if (res.data is Map && res.data['results'] != null)
        data = res.data['results'];

      if (data.isNotEmpty) {
        _constraint = data.first;
        bookingType =
            _constraint!['booking_type']?.toString().toLowerCase() ?? 'single';
        lowerLimitCtrl.text = _constraint!['lower_limit']?.toString() ?? '1';
        upperLimitCtrl.text = _constraint!['upper_limit']?.toString() ?? '1';
        isFixed = _constraint!['fixed'] == true;
      }
    } catch (_) {}
    if (mounted) setState(() => _isFetching = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isFetching) {
      return const AlertDialog(
        backgroundColor: Color(0xFF1B1B26),
        content: SizedBox(
          height: 100,
          child: Center(
            child: CircularProgressIndicator(color: Color(0xFF7C3AED)),
          ),
        ),
      );
    }

    final bool exists = _constraint != null;

    return AlertDialog(
      backgroundColor: const Color(0xFF1B1B26),
      title: Text(
        exists ? 'Edit Constraints' : 'Add Constraints',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Container(
        padding: const EdgeInsets.only(bottom: 20),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: bookingType,
                dropdownColor: const Color(0xFF1B1B26),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Booking Type',
                  labelStyle: const TextStyle(color: Colors.white54),
                  filled: true,
                  fillColor: const Color(0xFF0A0A0F),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
                items: const [
                  DropdownMenuItem(value: 'single', child: Text('Single')),
                  DropdownMenuItem(value: 'multiple', child: Text('Multiple')),
                ],
                onChanged: (v) => setState(() => bookingType = v!),
              ),
              if (bookingType == 'multiple') ...[
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text(
                    'Fixed Size Team',
                    style: TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                  activeColor: const Color(0xFF7C3AED),
                  value: isFixed,
                  onChanged: (v) => setState(() => isFixed = v),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (!isFixed) ...[
                      Expanded(
                        child: TextField(
                          controller: lowerLimitCtrl,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Lower Limit',
                            labelStyle: const TextStyle(color: Colors.white54),
                            filled: true,
                            fillColor: const Color(0xFF0A0A0F),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: TextField(
                        controller: upperLimitCtrl,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Upper Limit',
                          labelStyle: const TextStyle(color: Colors.white54),
                          filled: true,
                          fillColor: const Color(0xFF0A0A0F),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
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
          onPressed: _isLoading
              ? null
              : () async {
                  setState(() => _isLoading = true);
                  try {
                    final Map<String, dynamic> payload = {
                      "event": widget.eventId,
                      "booking_type": bookingType,
                      "fixed": bookingType == 'multiple' ? isFixed : false,
                    };

                    if (bookingType == 'multiple') {
                      if (isFixed) {
                        payload["upper_limit"] = int.parse(upperLimitCtrl.text);
                      } else {
                        payload["lower_limit"] = int.parse(lowerLimitCtrl.text);
                        payload["upper_limit"] = int.parse(upperLimitCtrl.text);
                      }
                    }

                    payload.removeWhere((k, v) => v == null || v == "");

                    if (exists) {
                      await ref
                          .read(dioProvider)
                          .put(
                            '/constraints/${_constraint!['id']}/',
                            data: payload,
                          );
                    } else {
                      await ref
                          .read(dioProvider)
                          .post('/constraints/', data: payload);
                    }
                    if (context.mounted) {
                      Navigator.pop(context);
                      ref.invalidate(manageEventsProvider);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Constraints saved')),
                      );
                    }
                  } catch (e) {
                    if (context.mounted)
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text('Failed: $e')));
                  }
                  if (mounted) setState(() => _isLoading = false);
                },
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

// --------------------------------------------------------------------------
// SLOTS MODAL (List + Add Form + Edit)
// --------------------------------------------------------------------------
class _SlotsListModal extends ConsumerStatefulWidget {
  final int eventId;
  const _SlotsListModal({required this.eventId});
  @override
  ConsumerState<_SlotsListModal> createState() => _SlotsListModalState();
}

class _SlotsListModalState extends ConsumerState<_SlotsListModal> {
  bool _isFetching = true;
  List<dynamic> _slots = [];

  DateTime? _selectedDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  final _capacityCtrl = TextEditingController();
  bool _isUnlimited = false;
  bool _isLoading = false;
  int? _editingSlotId;

  @override
  void initState() {
    super.initState();
    _fetchSlots();
  }

  Future<void> _fetchSlots() async {
    try {
      final res = await ref
          .read(dioProvider)
          .get('/event-slots/', queryParameters: {'event_id': widget.eventId});
      if (res.data is List) {
        _slots = res.data;
      } else if (res.data is Map && res.data['results'] != null) {
        _slots = res.data['results'];
      }
    } catch (_) {
      // Fallback if the endpoint is strictly /slots/ with ?event=
      try {
        final res2 = await ref
            .read(dioProvider)
            .get('/slots/', queryParameters: {'event': widget.eventId});
        if (res2.data is List)
          _slots = res2.data;
        else if (res2.data is Map && res2.data['results'] != null)
          _slots = res2.data['results'];
      } catch (_) {}
    }
    if (mounted) setState(() => _isFetching = false);
  }

  void _editSlot(Map<String, dynamic> slot) {
    setState(() {
      _editingSlotId = slot['id'];
      _selectedDate = slot['date'] != null
          ? DateTime.tryParse(slot['date'])
          : null;
      _startTime = slot['start_time'] != null
          ? TimeOfDay(
              hour: int.tryParse(slot['start_time'].split(':')[0]) ?? 0,
              minute: int.tryParse(slot['start_time'].split(':')[1]) ?? 0,
            )
          : null;
      _endTime = slot['end_time'] != null
          ? TimeOfDay(
              hour: int.tryParse(slot['end_time'].split(':')[0]) ?? 0,
              minute: int.tryParse(slot['end_time'].split(':')[1]) ?? 0,
            )
          : null;
      _isUnlimited = slot['unlimited_participants'] == true;
      _capacityCtrl.text = _isUnlimited
          ? ''
          : (slot['max_participants']?.toString() ??
                slot['available_participants']?.toString() ??
                '');
    });
  }

  void _cancelEdit() {
    setState(() {
      _editingSlotId = null;
      _selectedDate = null;
      _startTime = null;
      _endTime = null;
      _capacityCtrl.clear();
      _isUnlimited = false;
    });
  }

  Future<void> _submitSlot() async {
    setState(() => _isLoading = true);
    try {
      final dio = ref.read(dioProvider);
      final Map<String, dynamic> payload = {
        "event": widget.eventId,
        if (_selectedDate != null)
          "date":
              "${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}",
        if (_startTime != null)
          "start_time":
              "${_startTime!.hour.toString().padLeft(2, '0')}:${_startTime!.minute.toString().padLeft(2, '0')}:00",
        if (_endTime != null)
          "end_time":
              "${_endTime!.hour.toString().padLeft(2, '0')}:${_endTime!.minute.toString().padLeft(2, '0')}:00",
        "unlimited_participants": _isUnlimited,
      };
      if (!_isUnlimited && _capacityCtrl.text.isNotEmpty) {
        payload["max_participants"] = int.tryParse(_capacityCtrl.text);
      }

      if (_editingSlotId == null) {
        await dio.post('/event-slots/', data: payload);
      } else {
        await dio.put('/event-slots/$_editingSlotId/', data: payload);
      }

      if (mounted) {
        _cancelEdit();
        ref.invalidate(manageEventsProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _editingSlotId == null ? 'Slot added' : 'Slot updated',
            ),
            backgroundColor: Colors.green,
          ),
        );
        await _fetchSlots(); // Refresh local list
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
          ),
        );
      print("API ERROR: $errMsg");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteSlot(int id) async {
    try {
      await ref.read(dioProvider).delete('/event-slots/$id/');
      if (mounted) {
        ref.invalidate(manageEventsProvider);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Slot deleted')));
        await _fetchSlots(); // Refresh local list
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to delete: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Color(0xFF1B1B26),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: _isFetching
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF7C3AED)),
            )
          : Container(
              padding: const EdgeInsets.only(bottom: 20),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Manage Slots',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (_slots.isEmpty)
                      const Center(
                        child: Text(
                          "No Slots Configured",
                          style: TextStyle(color: Colors.white54),
                        ),
                      )
                    else
                      Column(
                        children: _slots
                            .map(
                              (slot) => Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0A0A0F),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          slot['date'] ?? 'N/A',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          '${slot['start_time']} - ${slot['end_time']}',
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 13,
                                          ),
                                        ),
                                        if (slot['unlimited_participants'] ==
                                            true)
                                          const Text(
                                            'Unlimited Capacity',
                                            style: TextStyle(
                                              color: Color(0xFF38BDF8),
                                              fontSize: 12,
                                            ),
                                          )
                                        else
                                          Text(
                                            'Capacity: ${slot['max_participants'] ?? slot['available_participants']}',
                                            style: const TextStyle(
                                              color: Color(0xFF38BDF8),
                                              fontSize: 12,
                                            ),
                                          ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(
                                            Icons.edit,
                                            color: Colors.white54,
                                          ),
                                          onPressed: () => _editSlot(slot),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.delete,
                                            color: Colors.redAccent,
                                          ),
                                          onPressed: () =>
                                              _deleteSlot(slot['id']),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    const Divider(color: Colors.white10),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _editingSlotId == null ? 'New Slot' : 'Edit Slot',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (_editingSlotId != null)
                          TextButton(
                            onPressed: _cancelEdit,
                            child: const Text(
                              'Cancel Edit',
                              style: TextStyle(color: Colors.redAccent),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final d = await showDatePicker(
                                context: context,
                                initialDate: _selectedDate ?? DateTime.now(),
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2100),
                              );
                              if (d != null) setState(() => _selectedDate = d);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 8,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0A0A0F),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _selectedDate != null
                                    ? "${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}"
                                    : "Select Date",
                                style: TextStyle(
                                  color: _selectedDate != null
                                      ? Colors.white
                                      : Colors.white54,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final t = await showTimePicker(
                                context: context,
                                initialTime: _startTime ?? TimeOfDay.now(),
                              );
                              if (t != null) setState(() => _startTime = t);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 8,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0A0A0F),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _startTime != null
                                    ? _startTime!.format(context)
                                    : "Start Time",
                                style: TextStyle(
                                  color: _startTime != null
                                      ? Colors.white
                                      : Colors.white54,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final t = await showTimePicker(
                                context: context,
                                initialTime: _endTime ?? TimeOfDay.now(),
                              );
                              if (t != null) setState(() => _endTime = t);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 8,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0A0A0F),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _endTime != null
                                    ? _endTime!.format(context)
                                    : "End Time",
                                style: TextStyle(
                                  color: _endTime != null
                                      ? Colors.white
                                      : Colors.white54,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildField(
                            'Capacity',
                            _capacityCtrl,
                            isNum: true,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SwitchListTile(
                            title: const Text(
                              'Unlimited',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 12,
                              ),
                            ),
                            value: _isUnlimited,
                            onChanged: (v) => setState(() => _isUnlimited = v),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF7C3AED),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _isLoading ? null : _submitSlot,
                        child: _isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                _editingSlotId == null
                                    ? 'Add Slot'
                                    : 'Save Slot',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
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
      keyboardType: isNum ? TextInputType.number : TextInputType.text,
      style: const TextStyle(color: Colors.white, fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54, fontSize: 11),
        filled: true,
        fillColor: const Color(0xFF0A0A0F),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
