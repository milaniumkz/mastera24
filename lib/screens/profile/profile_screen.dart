import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/errors/app_error_mapper.dart';
import '../../models/settlement_location.dart';
import '../../services/firestore_service.dart';
import '../../services/osm_settlement_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/phone_utils.dart';
import '../../widgets/premium_layout.dart';
import '../../widgets/executor_reviews_section.dart';
import '../../widgets/safe_network_image.dart';
import '../../widgets/settlement_picker_form_field.dart';
import '../../widgets/user_avatar.dart';
import '../customer/my_orders_screen.dart';
import '../media/portfolio_carousel_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  String? _role;
  bool _loading = true;
  bool _saving = false;
  bool _avatarUploading = false;
  bool _isAdmin = false;
  SettlementLocation? _settlement;
  String _avatarUrl = '';
  List<Map<String, dynamic>> _portfolio = [];

  @override
  void initState() {
    super.initState();
    _phoneController.text = '+7';
    _load();
  }

  Future<void> _load() async {
    final user = FirebaseAuth.instance.currentUser!;
    final snapshot = await FirestoreService().getUserProfile(user.uid);
    final data = snapshot.data() ?? {};

    _nameController.text = data['name'] ?? '';
    _phoneController.text = PhoneUtils.format(data['phone'] ?? '');
    _role = data['role'] ?? 'customer';
    _isAdmin = _role == 'admin';
    _avatarUrl = data['avatarUrl']?.toString() ?? '';
    final settlement = SettlementLocation.fromProfileMap(data);
    _settlement = settlement.isEmpty ? null : settlement;
    final list = data['portfolio'] as List<dynamic>? ?? [];
    _portfolio = list.map((e) => Map<String, dynamic>.from(e as Map)).toList();

    setState(() => _loading = false);
  }

  Future<void> _save() async {
    if (_saving) return;
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (PhoneUtils.normalize(_phoneController.text).length != 11) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Используйте формат +7 (###) ###-##-##.')),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final user = FirebaseAuth.instance.currentUser!;
      await FirestoreService().updateUserProfile(
        uid: user.uid,
        name: _nameController.text.trim(),
        phone: PhoneUtils.format(_phoneController.text.trim()),
        role: _role ?? 'customer',
        settlement: _settlement!,
        avatarUrl: _avatarUrl,
        portfolio: _portfolio,
      );

      if (mounted) {
        setState(() => _saving = false);
        Navigator.of(context).pop();
      }
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppErrorMapper.map(
              error,
              fallback: 'Не удалось сохранить профиль. Попробуйте снова.',
            ),
          ),
        ),
      );
    }
  }

  Future<List<String>> _pickAndUploadImages() async {
    final picker = ImagePicker();
    final pickedList = await picker.pickMultiImage(maxWidth: 1400);
    if (pickedList.isEmpty) return [];

    final user = FirebaseAuth.instance.currentUser!;
    final urls = <String>[];
    for (final picked in pickedList) {
      final fileName = DateTime.now().millisecondsSinceEpoch.toString();
      final ref = FirebaseStorage.instance.ref().child(
        'portfolio/${user.uid}/$fileName.jpg',
      );
      await ref.putData(
        await picked.readAsBytes(),
        SettableMetadata(contentType: 'image/jpeg'),
      );
      urls.add(await ref.getDownloadURL());
    }
    return urls;
  }

  Future<void> _pickAndUploadAvatar() async {
    if (_avatarUploading) return;

    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
    );
    if (picked == null) return;

    setState(() => _avatarUploading = true);
    try {
      final user = FirebaseAuth.instance.currentUser!;
      final fileName = DateTime.now().millisecondsSinceEpoch.toString();
      final ref = FirebaseStorage.instance.ref().child(
        'avatars/${user.uid}/$fileName.jpg',
      );
      await ref.putData(
        await picked.readAsBytes(),
        SettableMetadata(contentType: 'image/jpeg'),
      );
      final url = await ref.getDownloadURL();
      if (!mounted) return;
      setState(() => _avatarUrl = url);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppErrorMapper.map(
              error,
              fallback: 'Не удалось загрузить фото профиля. Попробуйте снова.',
            ),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _avatarUploading = false);
      }
    }
  }

  Future<void> _addPortfolioItem() => _openPortfolioEditor();

  Future<void> _editPortfolioItem(int index) {
    return _openPortfolioEditor(index: index);
  }

  Future<void> _openPortfolioEditor({int? index}) async {
    final existing = index == null ? null : _portfolio[index];
    final titleController = TextEditingController(
      text: existing?['title']?.toString() ?? '',
    );
    final descriptionController = TextEditingController(
      text: existing?['description']?.toString() ?? '',
    );
    List<String> imageUrls =
        (existing?['images'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .where((e) => e.isNotEmpty)
            .toList() ??
        ((existing?['imageUrl'] as String?)?.isNotEmpty == true
            ? [existing!['imageUrl'].toString()]
            : <String>[]);

    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text(
                index == null ? 'Добавить работу' : 'Изменить работу',
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Название работы',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Описание работы',
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final urls = await _pickAndUploadImages();
                        if (urls.isNotEmpty) {
                          setStateDialog(
                            () => imageUrls = [...imageUrls, ...urls],
                          );
                        }
                      },
                      icon: const Icon(Icons.photo),
                      label: Text(
                        imageUrls.isEmpty
                            ? 'Добавить фото'
                            : 'Фото: ${imageUrls.length}',
                      ),
                    ),
                    if (imageUrls.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 118,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: imageUrls.length,
                          separatorBuilder: (_, index) =>
                              const SizedBox(width: 8),
                          itemBuilder: (context, photoIndex) => Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: SafeNetworkImage(
                                  imageUrl: imageUrls[photoIndex],
                                  width: 108,
                                  height: 108,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: IconButton.filledTonal(
                                  icon: const Icon(Icons.close, size: 18),
                                  onPressed: () {
                                    setStateDialog(
                                      () => imageUrls.removeAt(photoIndex),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (index != null) ...[
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: () async {
                            final urls = await _pickAndUploadImages();
                            if (urls.isNotEmpty) {
                              setStateDialog(() => imageUrls = urls);
                            }
                          },
                          icon: const Icon(Icons.swap_horiz),
                          label: const Text('Заменить все фото'),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Text(
                        'После изменений нажмите “Сохранить”, потом сохраните профиль.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ] else
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'Добавьте хотя бы одно фото.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    if (index != null) ...[
                      const SizedBox(height: 12),
                      TextButton.icon(
                        onPressed: () => Navigator.of(context).pop('delete'),
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Удалить работу'),
                        style: TextButton.styleFrom(
                          foregroundColor: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop('cancel'),
                  child: const Text('Отмена'),
                ),
                FilledButton(
                  onPressed: imageUrls.isEmpty
                      ? null
                      : () => Navigator.of(context).pop('save'),
                  child: const Text('Сохранить'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == 'save' && imageUrls.isNotEmpty) {
      setState(() {
        final payload = {
          'title': titleController.text.trim(),
          'description': descriptionController.text.trim(),
          'images': imageUrls,
        };
        if (index == null) {
          _portfolio.add(payload);
        } else {
          _portfolio[index] = payload;
        }
      });
    } else if (result == 'delete' && index != null) {
      setState(() => _portfolio.removeAt(index));
    }

    titleController.dispose();
    descriptionController.dispose();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Профиль')),
      body: PremiumPageBody(
        maxWidth: 1380,
        child: ListView(
          children: [
            PremiumHeroBanner(
              eyebrow: '',
              title: 'Профиль',
              subtitle: '',
              stats: [
                PremiumStatChip(
                  label: 'Роль',
                  value: _role == 'executor'
                      ? 'Исполнитель'
                      : _role == 'admin'
                      ? 'Админ'
                      : 'Заказчик',
                ),
                PremiumStatChip(label: 'Работ', value: '${_portfolio.length}'),
                PremiumStatChip(
                  label: 'Город',
                  value: _settlement?.city ?? 'Не выбран',
                ),
              ],
            ),
            const SizedBox(height: 22),
            PremiumSplitLayout(
              secondaryFlex: 3,
              primary: PremiumPanel(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Column(
                          children: [
                            UserAvatar(
                              imageUrl: _avatarUrl,
                              name: _nameController.text,
                              radius: 44,
                              bordered: true,
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              alignment: WrapAlignment.center,
                              children: [
                                OutlinedButton.icon(
                                  onPressed: _avatarUploading
                                      ? null
                                      : _pickAndUploadAvatar,
                                  icon: const Icon(Icons.photo_camera_outlined),
                                  label: Text(
                                    _avatarUploading
                                        ? 'Загрузка...'
                                        : _avatarUrl.isEmpty
                                        ? 'Добавить фото'
                                        : 'Сменить фото',
                                  ),
                                ),
                                if (_avatarUrl.isNotEmpty)
                                  TextButton.icon(
                                    onPressed: _avatarUploading
                                        ? null
                                        : () => setState(() => _avatarUrl = ''),
                                    icon: const Icon(Icons.delete_outline),
                                    label: const Text('Убрать'),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const MyOrdersScreen(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.assignment_outlined),
                          label: const Text('Мои заказы'),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Личные данные',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 18),
                      TextField(
                        controller: _nameController,
                        onChanged: (_) => setState(() {}),
                        decoration: const InputDecoration(labelText: 'Имя'),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [PhoneInputFormatter()],
                        decoration: const InputDecoration(labelText: 'Телефон'),
                      ),
                      const SizedBox(height: 16),
                      SettlementPickerFormField(
                        initialValue: _settlement,
                        searchService: OsmSettlementService(),
                        onSelected: (value) {
                          setState(() => _settlement = value);
                        },
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Роль',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      if (_isAdmin)
                        const Text('Роль администратора нельзя менять.')
                      else
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            ChoiceChip(
                              label: const Text('Заказчик'),
                              selected: _role == 'customer',
                              onSelected: (_) =>
                                  setState(() => _role = 'customer'),
                            ),
                            ChoiceChip(
                              label: const Text('Исполнитель'),
                              selected: _role == 'executor',
                              onSelected: (_) =>
                                  setState(() => _role = 'executor'),
                            ),
                          ],
                        ),
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: _saving ? null : _save,
                        child: Text(_saving ? 'Сохраняем...' : 'Сохранить'),
                      ),
                    ],
                  ),
                ),
              ),
              secondary: _role != 'executor'
                  ? const SizedBox.shrink()
                  : PremiumPanel(
                      accented: true,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Мои наглядные работы',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 10),
                          if (_portfolio.isEmpty)
                            const Text('Пока нет работ в портфолио.')
                          else
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount:
                                        PremiumLayout.isDesktop(context)
                                        ? 3
                                        : 2,
                                    mainAxisSpacing: 12,
                                    crossAxisSpacing: 12,
                                    childAspectRatio: 0.9,
                                  ),
                              itemCount: _portfolio.length,
                              itemBuilder: (context, index) {
                                final item = _portfolio[index];
                                final images =
                                    (item['images'] as List<dynamic>?)
                                        ?.map((e) => e.toString())
                                        .where((e) => e.isNotEmpty)
                                        .toList() ??
                                    ((item['imageUrl'] as String?)
                                                ?.isNotEmpty ==
                                            true
                                        ? [item['imageUrl'].toString()]
                                        : <String>[]);
                                final cover = images.isNotEmpty
                                    ? images.first
                                    : '';
                                return Stack(
                                  children: [
                                    InkWell(
                                      onTap: images.isEmpty
                                          ? null
                                          : () {
                                              Navigator.of(context).push(
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                      PortfolioCarouselScreen(
                                                        images: images,
                                                      ),
                                                ),
                                              );
                                            },
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          border: Border.all(
                                            color: AppTheme.line,
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Expanded(
                                              child: ClipRRect(
                                                borderRadius:
                                                    const BorderRadius.vertical(
                                                      top: Radius.circular(16),
                                                    ),
                                                child: cover.isNotEmpty
                                                    ? SafeNetworkImage(
                                                        imageUrl: cover,
                                                        width: double.infinity,
                                                        fit: BoxFit.cover,
                                                      )
                                                    : Container(
                                                        color: AppTheme
                                                            .surfaceMuted,
                                                        child: const Center(
                                                          child: Icon(
                                                            Icons.photo,
                                                          ),
                                                        ),
                                                      ),
                                              ),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.all(12),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    item['title'] ??
                                                        'Без названия',
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: Theme.of(
                                                      context,
                                                    ).textTheme.titleMedium,
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    item['description'] ?? '',
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      top: 6,
                                      right: 6,
                                      child: DecoratedBox(
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(
                                            alpha: 0.9,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            18,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              tooltip: 'Редактировать',
                                              icon: const Icon(
                                                Icons.edit_outlined,
                                              ),
                                              onPressed: () =>
                                                  _editPortfolioItem(index),
                                            ),
                                            IconButton(
                                              tooltip: 'Удалить',
                                              icon: const Icon(
                                                Icons.delete_outline,
                                              ),
                                              onPressed: () {
                                                setState(
                                                  () => _portfolio.removeAt(
                                                    index,
                                                  ),
                                                );
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          const SizedBox(height: 14),
                          OutlinedButton.icon(
                            onPressed: _addPortfolioItem,
                            icon: const Icon(Icons.add),
                            label: const Text('Добавить фото'),
                          ),
                          const SizedBox(height: 12),
                          FilledButton.icon(
                            onPressed: _saving ? null : _save,
                            icon: const Icon(Icons.save_outlined),
                            label: Text(
                              _saving ? 'Сохраняем...' : 'Сохранить фото',
                            ),
                          ),
                          const SizedBox(height: 24),
                          ExecutorReviewsSection(
                            executorId: FirebaseAuth.instance.currentUser!.uid,
                            title: 'Отзывы заказчиков',
                            emptyText: 'Пока нет отзывов от заказчиков.',
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
