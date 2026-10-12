import 'dart:async';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/errors/app_error_mapper.dart';
import '../../models/chat_thread.dart';
import '../../services/firestore_service.dart';
import '../../widgets/premium_layout.dart';
import '../../widgets/safe_network_image.dart';
import '../media/image_viewer_screen.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String title;
  final String? highlightMessageId;

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.title,
    this.highlightMessageId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _picker = ImagePicker();
  bool _sending = false;
  bool _highlightedOnce = false;
  int _lastRenderedMessageCount = 0;
  final Map<String, GlobalKey> _messageKeys = {};
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _notifications;
  bool _messagesLoaded = false;
  Timestamp? _lastReadIncomingAt;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _notifications = FirestoreService()
          .watchUserNotifications(user.uid)
          .listen(
            (_) {
              if (_messagesLoaded &&
                  mounted &&
                  ModalRoute.of(context)?.isCurrent == true) {
                _markNotificationsRead(user.uid);
              }
            },
            onError: (Object error) => debugPrint('Chat notifications: $error'),
          );
    }
  }

  Future<void> _markNotificationsRead(String uid) async {
    try {
      await FirestoreService().markChatNotificationsRead(
        recipientId: uid,
        chatId: widget.chatId,
      );
    } catch (error) {
      debugPrint('Mark chat notifications read: $error');
    }
  }

  Future<void> _markConversationRead(ChatThread chat, String uid) async {
    final incomingAt = chat.unreadIncomingAt(uid);
    try {
      if (incomingAt != null && incomingAt != _lastReadIncomingAt) {
        _lastReadIncomingAt = incomingAt;
        await FirestoreService().markChatRead(widget.chatId, uid, incomingAt);
      }
      await FirestoreService().markJobConversationNotificationsRead(
        recipientId: uid,
        jobId: chat.jobId,
        bidId: chat.bidId,
        chatId: widget.chatId,
      );
    } catch (error) {
      _lastReadIncomingAt = null;
      debugPrint('Mark conversation read: $error');
    }
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() => _sending = true);
    try {
      final user = FirebaseAuth.instance.currentUser!;
      await FirestoreService().sendMessage(
        chatId: widget.chatId,
        senderId: user.uid,
        text: text,
      );
      _controller.clear();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppErrorMapper.map(
              error,
              fallback: 'Не удалось отправить сообщение. Попробуйте снова.',
            ),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  Future<void> _sendImage() async {
    if (_sending) return;
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
    );
    if (picked == null) return;

    setState(() => _sending = true);
    try {
      final user = FirebaseAuth.instance.currentUser!;
      final fileName = DateTime.now().millisecondsSinceEpoch.toString();
      final ref = FirebaseStorage.instance.ref().child(
        'chat_uploads/${widget.chatId}/$fileName.jpg',
      );
      final bytes = await picked.readAsBytes();

      await _uploadBytes(ref: ref, bytes: bytes, contentType: 'image/jpeg');
      final url = await ref.getDownloadURL();

      await FirestoreService().sendMessage(
        chatId: widget.chatId,
        senderId: user.uid,
        text: '',
        imageUrl: url,
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppErrorMapper.map(
              error,
              fallback: 'Не удалось отправить изображение. Попробуйте снова.',
            ),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  Future<void> _sendFile() async {
    if (_sending) return;

    final result = await FilePicker.platform.pickFiles(withData: true);
    if (result == null || result.files.isEmpty) return;

    final picked = result.files.first;
    final bytes = picked.bytes;
    if (bytes == null || bytes.isEmpty) return;

    setState(() => _sending = true);
    try {
      final user = FirebaseAuth.instance.currentUser!;
      final fileName = picked.name;
      final ref = FirebaseStorage.instance.ref().child(
        'chat_uploads/${widget.chatId}/$fileName',
      );

      await _uploadBytes(
        ref: ref,
        bytes: bytes,
        contentType: _guessMimeType(picked.extension),
      );
      final url = await ref.getDownloadURL();

      await FirestoreService().sendMessage(
        chatId: widget.chatId,
        senderId: user.uid,
        text: '',
        fileUrl: url,
        fileName: fileName,
        fileType: picked.extension ?? '',
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppErrorMapper.map(
              error,
              fallback: 'Не удалось отправить файл. Попробуйте снова.',
            ),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  @override
  void dispose() {
    _notifications?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _uploadBytes({
    required Reference ref,
    required Uint8List bytes,
    String? contentType,
  }) {
    return ref.putData(bytes, SettableMetadata(contentType: contentType));
  }

  String? _guessMimeType(String? extension) {
    switch ((extension ?? '').toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'xls':
        return 'application/vnd.ms-excel';
      case 'xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case 'zip':
        return 'application/zip';
      default:
        return 'application/octet-stream';
    }
  }

  String _formatMessageTime(Timestamp? timestamp) {
    if (timestamp == null) {
      return '';
    }
    final date = timestamp.toDate();
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$day.$month $hour:$minute';
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _scrollToHighlighted(String messageId) {
    if (_highlightedOnce) return;
    final key = _messageKeys[messageId];
    if (key == null) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = key.currentContext;
      if (context != null) {
        Scrollable.ensureVisible(
          context,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOut,
        );
        _highlightedOnce = true;
      }
    });
  }

  Future<void> _openFile(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;
    final service = FirestoreService();

    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: PremiumPageBody(
        maxWidth: 1320,
        child: PremiumPanel(
          darker: false,
          padding: const EdgeInsets.all(0),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 22, 22, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Можете предложить свою цену',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                    const Chip(label: Text('Чат по заказу')),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                  stream: service.watchChat(widget.chatId),
                  builder: (context, chatSnapshot) {
                    if (chatSnapshot.hasError) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            'Не удалось открыть чат. Попробуйте открыть его из уведомлений или обновите страницу.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ),
                      );
                    }

                    if (!chatSnapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final chatData = chatSnapshot.data!.data();
                    final isParticipant =
                        chatData != null &&
                        (chatData['customerId'] == user.uid ||
                            chatData['executorId'] == user.uid);
                    if (!chatSnapshot.data!.exists || !isParticipant) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            'Чат не найден или недоступен. Откройте его заново из заявки или отклика.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ),
                      );
                    }

                    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: service.watchMessages(widget.chatId),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Text(
                                'Не удалось открыть чат. Попробуйте открыть его из уведомлений или обновите страницу.',
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                            ),
                          );
                        }

                        if (!snapshot.hasData) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        final messages = snapshot.data!.docs;
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (!mounted ||
                              ModalRoute.of(context)?.isCurrent != true) {
                            return;
                          }
                          _messagesLoaded = true;
                          final chat = ChatThread.fromDoc(chatSnapshot.data!);
                          final incomingAt = chat.unreadIncomingAt(user.uid);
                          final lastMessageAt = messages.isEmpty
                              ? null
                              : messages.last.data()['createdAt'];
                          if (incomingAt == null ||
                              (lastMessageAt is Timestamp &&
                                  incomingAt.compareTo(lastMessageAt) <= 0)) {
                            _markConversationRead(chat, user.uid);
                          }
                        });
                        if (messages.isEmpty) {
                          return const Center(
                            child: Text(
                              'Начните диалог. Здесь можно обсудить цену и детали заказа.',
                              textAlign: TextAlign.center,
                            ),
                          );
                        }

                        if (widget.highlightMessageId == null &&
                            messages.length != _lastRenderedMessageCount) {
                          _lastRenderedMessageCount = messages.length;
                          _scrollToBottom();
                        }

                        if (widget.highlightMessageId != null) {
                          _scrollToHighlighted(widget.highlightMessageId!);
                        }

                        return ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(18),
                          itemCount: messages.length,
                          itemBuilder: (context, index) {
                            final doc = messages[index];
                            final data = doc.data();
                            final isMe = data['senderId'] == user.uid;
                            final isHighlighted =
                                doc.id == widget.highlightMessageId;
                            final imageUrl = data['imageUrl'] as String?;
                            final fileUrl = data['fileUrl'] as String?;
                            final fileName = data['fileName'] as String?;
                            final createdAt = data['createdAt'] as Timestamp?;

                            _messageKeys.putIfAbsent(doc.id, () => GlobalKey());

                            return Align(
                              key: _messageKeys[doc.id],
                              alignment: isMe
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                              child: Container(
                                constraints: BoxConstraints(
                                  maxWidth: PremiumLayout.isDesktop(context)
                                      ? 520
                                      : 320,
                                ),
                                margin: const EdgeInsets.symmetric(vertical: 6),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: isHighlighted
                                      ? Theme.of(context).colorScheme.secondary
                                            .withValues(alpha: 0.3)
                                      : isMe
                                      ? Theme.of(context).colorScheme.primary
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: isHighlighted
                                      ? Border.all(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.secondary,
                                        )
                                      : null,
                                ),
                                child: Column(
                                  crossAxisAlignment: isMe
                                      ? CrossAxisAlignment.end
                                      : CrossAxisAlignment.start,
                                  children: [
                                    if ((data['text'] ?? '')
                                        .toString()
                                        .isNotEmpty)
                                      Text(
                                        data['text'] ?? '',
                                        style: TextStyle(
                                          color: isMe
                                              ? Colors.white
                                              : Colors.black87,
                                        ),
                                      ),
                                    if (imageUrl != null &&
                                        imageUrl.isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      GestureDetector(
                                        onTap: () {
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (_) => ImageViewerScreen(
                                                imageUrl: imageUrl,
                                              ),
                                            ),
                                          );
                                        },
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          child: SafeNetworkImage(
                                            imageUrl: imageUrl,
                                            width:
                                                PremiumLayout.isDesktop(context)
                                                ? 320
                                                : 220,
                                            height:
                                                PremiumLayout.isDesktop(context)
                                                ? 220
                                                : 160,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                    ],
                                    if (fileUrl != null &&
                                        fileUrl.isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      OutlinedButton.icon(
                                        onPressed: () => _openFile(fileUrl),
                                        icon: const Icon(Icons.attach_file),
                                        label: Text(fileName ?? 'Файл'),
                                      ),
                                    ],
                                    const SizedBox(height: 6),
                                    Text(
                                      _formatMessageTime(createdAt),
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isMe
                                            ? Colors.white70
                                            : Colors.black54,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
              const Divider(height: 1),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: _sending ? null : _sendImage,
                        icon: const Icon(Icons.photo),
                      ),
                      IconButton(
                        onPressed: _sending ? null : _sendFile,
                        icon: const Icon(Icons.attach_file),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          minLines: 1,
                          maxLines: 4,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _sending ? null : _send(),
                          decoration: const InputDecoration(
                            hintText: 'Сообщение...',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        onPressed: _sending ? null : _send,
                        icon: const Icon(Icons.send),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
