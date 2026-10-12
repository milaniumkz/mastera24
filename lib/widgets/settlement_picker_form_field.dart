import 'dart:async';

import 'package:flutter/material.dart';

import '../models/settlement_location.dart';
import '../services/osm_settlement_service.dart';

class SettlementPickerFormField extends FormField<SettlementLocation> {
  SettlementPickerFormField({
    super.key,
    super.initialValue,
    required ValueChanged<SettlementLocation> onSelected,
    OsmSettlementService? searchService,
    String labelText = 'Населенный пункт',
    String hintText = 'Выберите населенный пункт',
    String emptyErrorText = 'Укажите населенный пункт',
  }) : super(
         validator: (value) =>
             value == null || value.isEmpty ? emptyErrorText : null,
         builder: (state) {
           Future<void> openPicker() async {
             final result = await showModalBottomSheet<SettlementLocation>(
               context: state.context,
               isScrollControlled: true,
               showDragHandle: true,
               useSafeArea: true,
               builder: (_) => _SettlementSearchSheet(
                 searchService: searchService ?? OsmSettlementService(),
                 initialValue: state.value,
               ),
             );
             if (result == null) {
               return;
             }
             state.didChange(result);
             onSelected(result);
           }

           final selected = state.value;
           return InkWell(
             onTap: openPicker,
             borderRadius: BorderRadius.circular(16),
             child: InputDecorator(
               decoration: InputDecoration(
                 labelText: labelText,
                 errorText: state.errorText,
                 suffixIcon: const Icon(Icons.search),
               ),
               child: selected == null || selected.isEmpty
                   ? Text(
                       hintText,
                       style: Theme.of(
                         state.context,
                       ).textTheme.bodyMedium?.copyWith(color: Colors.black54),
                     )
                   : Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                         Text(
                           selected.city,
                           style: Theme.of(state.context).textTheme.titleMedium,
                         ),
                         if (selected.region.isNotEmpty) ...[
                           const SizedBox(height: 2),
                           Text(
                             selected.region,
                             style: Theme.of(state.context).textTheme.bodySmall,
                           ),
                         ],
                       ],
                     ),
             ),
           );
         },
       );
}

class _SettlementSearchSheet extends StatefulWidget {
  final OsmSettlementService searchService;
  final SettlementLocation? initialValue;

  const _SettlementSearchSheet({
    required this.searchService,
    this.initialValue,
  });

  @override
  State<_SettlementSearchSheet> createState() => _SettlementSearchSheetState();
}

class _SettlementSearchSheetState extends State<_SettlementSearchSheet> {
  final _controller = TextEditingController();
  Timer? _debounce;
  int _requestId = 0;
  bool _loading = false;
  String? _error;
  List<SettlementLocation> _results = [];

  @override
  void initState() {
    super.initState();
    if (widget.initialValue?.city.isNotEmpty == true) {
      _controller.text = widget.initialValue!.city;
      _scheduleSearch(widget.initialValue!.city);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _scheduleSearch(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      _search(value);
    });
  }

  Future<void> _search(String value) async {
    final query = value.trim();
    if (query.length < 2) {
      if (!mounted) return;
      setState(() {
        _results = [];
        _loading = false;
        _error = null;
      });
      return;
    }

    final requestId = ++_requestId;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final results = await widget.searchService.searchSettlements(query);
      if (!mounted || requestId != _requestId) {
        return;
      }
      setState(() {
        _results = results;
        _loading = false;
      });
    } catch (_) {
      if (!mounted || requestId != _requestId) {
        return;
      }
      setState(() {
        _results = [];
        _loading = false;
        _error = 'Не удалось загрузить населенные пункты.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 8, 16, 16 + bottomInset),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.72,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Выбор населенного пункта',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Поиск по OSM',
                hintText: 'Например, Алматы или Каскелен',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: _scheduleSearch,
            ),
            const SizedBox(height: 12),
            if (_loading) const LinearProgressIndicator(),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
            if (!_loading &&
                _error == null &&
                _controller.text.trim().length < 2)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text('Введите минимум 2 символа.'),
              ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.separated(
                itemCount: _results.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final item = _results[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(item.city),
                    subtitle: Text(
                      item.region.isEmpty ? item.displayName : item.region,
                    ),
                    onTap: () => Navigator.of(context).pop(item),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
