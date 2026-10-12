import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/errors/app_error_mapper.dart';
import '../../models/executor_review.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/premium_layout.dart';
import '../../widgets/rating_stars.dart';
import '../../widgets/safe_network_image.dart';

class ReviewEditorScreen extends StatefulWidget {
  final String bidId;
  final String jobId;
  final String executorId;
  final String executorName;
  final ExecutorReview? initialReview;

  const ReviewEditorScreen({
    super.key,
    required this.bidId,
    required this.jobId,
    required this.executorId,
    required this.executorName,
    this.initialReview,
  });

  @override
  State<ReviewEditorScreen> createState() => _ReviewEditorScreenState();
}

class _ReviewEditorScreenState extends State<ReviewEditorScreen> {
  final _commentController = TextEditingController();
  bool _saving = false;
  bool _uploading = false;
  late int _rating;
  late List<String> _photoUrls;

  @override
  void initState() {
    super.initState();
    _rating = widget.initialReview?.rating ?? 5;
    _photoUrls = List<String>.from(widget.initialReview?.photoUrls ?? const []);
    _commentController.text = widget.initialReview?.comment ?? '';
  }

  Future<void> _pickImages() async {
    if (_uploading) return;
    final picker = ImagePicker();
    final pickedList = await picker.pickMultiImage(maxWidth: 1600);
    if (pickedList.isEmpty) return;

    setState(() => _uploading = true);
    try {
      final user = FirebaseAuth.instance.currentUser!;
      final urls = <String>[];
      for (final picked in pickedList) {
        final fileName = DateTime.now().millisecondsSinceEpoch.toString();
        final ref = FirebaseStorage.instance.ref().child(
          'review_uploads/${user.uid}/${widget.bidId}/$fileName.jpg',
        );
        await ref.putData(
          await picked.readAsBytes(),
          SettableMetadata(contentType: 'image/jpeg'),
        );
        urls.add(await ref.getDownloadURL());
      }
      if (!mounted) return;
      setState(() => _photoUrls = [..._photoUrls, ...urls]);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppErrorMapper.map(
              error,
              fallback: 'Не удалось загрузить фото для отзыва.',
            ),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _uploading = false);
      }
    }
  }

  Future<void> _save() async {
    if (_saving) return;
    if (_rating < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Поставьте оценку от 1 до 5 звезд.')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final user = FirebaseAuth.instance.currentUser!;
      final profileSnap = await FirestoreService().getUserProfile(user.uid);
      final profile = profileSnap.data() ?? {};

      await FirestoreService().upsertExecutorReview(
        bidId: widget.bidId,
        jobId: widget.jobId,
        customerId: user.uid,
        customerName: profile['name']?.toString().trim().isNotEmpty == true
            ? profile['name'].toString().trim()
            : 'Заказчик',
        customerAvatarUrl: profile['avatarUrl']?.toString() ?? '',
        executorId: widget.executorId,
        rating: _rating,
        comment: _commentController.text.trim(),
        photoUrls: _photoUrls,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Отзыв сохранен.')),
      );
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppErrorMapper.map(
              error,
              fallback: 'Не удалось сохранить отзыв. Попробуйте снова.',
            ),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.initialReview == null ? 'Оставить отзыв' : 'Изменить отзыв',
        ),
      ),
      body: PremiumPageBody(
        maxWidth: 900,
        child: PremiumPanel(
          child: ListView(
            children: [
              Text(
                widget.executorName.isEmpty
                    ? 'Отзыв исполнителю'
                    : 'Отзыв для ${widget.executorName}',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 14),
              Text(
                'Оценка',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              RatingStars(
                rating: _rating,
                size: 32,
                onChanged: (value) => setState(() => _rating = value),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: _commentController,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Комментарий',
                  hintText: 'Напишите, как прошла работа.',
                ),
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  OutlinedButton.icon(
                    onPressed: _uploading ? null : _pickImages,
                    icon: const Icon(Icons.photo_library_outlined),
                    label: Text(
                      _uploading
                          ? 'Загрузка...'
                          : _photoUrls.isEmpty
                          ? 'Добавить фото'
                          : 'Фото: ${_photoUrls.length}',
                    ),
                  ),
                ],
              ),
              if (_photoUrls.isNotEmpty) ...[
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: List.generate(_photoUrls.length, (index) {
                    final url = _photoUrls[index];
                    return Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: SafeNetworkImage(
                            imageUrl: url,
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: Material(
                            color: Colors.white.withValues(alpha: 0.92),
                            shape: const CircleBorder(),
                            child: IconButton(
                              visualDensity: VisualDensity.compact,
                              iconSize: 18,
                              onPressed: () {
                                setState(() => _photoUrls.removeAt(index));
                              },
                              icon: const Icon(Icons.close),
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ],
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _saving ? null : _save,
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.accent,
                ),
                child: Text(_saving ? 'Сохраняем...' : 'Сохранить отзыв'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
