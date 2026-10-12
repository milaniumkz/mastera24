import 'package:flutter/material.dart';

import '../../models/settlement_location.dart';
import '../../services/auth_service.dart';
import '../../services/navigator_service.dart';
import '../../widgets/notification_bell_button.dart';
import '../../widgets/premium_layout.dart';
import '../../widgets/user_avatar.dart';
import '../customer/create_job_screen.dart';
import '../profile/profile_screen.dart';
import 'executor_bids_screen.dart';
import 'executor_jobs_screen.dart';

class ExecutorHomeScreen extends StatefulWidget {
  final String userId;
  final Map<String, dynamic> profile;
  final int initialIndex;

  static const routeName = '/executor-home';
  static final ValueNotifier<int> tabIndex = ValueNotifier<int>(0);
  static bool isTop = false;

  const ExecutorHomeScreen({
    super.key,
    required this.userId,
    required this.profile,
    this.initialIndex = 0,
  });

  @override
  State<ExecutorHomeScreen> createState() => _ExecutorHomeScreenState();
}

class _ExecutorHomeScreenState extends State<ExecutorHomeScreen>
    with RouteAware {
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    ExecutorHomeScreen.tabIndex.value = _index;
    ExecutorHomeScreen.tabIndex.addListener(_handleTabChange);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    NavigatorService.routeObserver.subscribe(
      this,
      ModalRoute.of(context)! as PageRoute,
    );
  }

  @override
  void dispose() {
    ExecutorHomeScreen.tabIndex.removeListener(_handleTabChange);
    NavigatorService.routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPush() {
    ExecutorHomeScreen.isTop = true;
  }

  @override
  void didPopNext() {
    ExecutorHomeScreen.isTop = true;
  }

  @override
  void didPushNext() {
    ExecutorHomeScreen.isTop = false;
  }

  @override
  void didPop() {
    ExecutorHomeScreen.isTop = false;
  }

  void _handleTabChange() {
    if (_index != ExecutorHomeScreen.tabIndex.value) {
      setState(() => _index = ExecutorHomeScreen.tabIndex.value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      ExecutorJobsScreen(
        currentUserId: widget.userId,
        profileName: widget.profile['name']?.toString().trim() ?? '',
        preferredSettlement: SettlementLocation.fromProfileMap(widget.profile),
      ),
      const ExecutorBidsScreen(),
    ];
    final isDesktop = PremiumLayout.isDesktop(context);
    final settlement = SettlementLocation.fromProfileMap(widget.profile);

    return Scaffold(
      appBar: AppBar(
        title: Text(_index == 0 ? 'Заявки' : 'Чаты по заказам'),
        actions: [
          const NotificationBellButton(),
          const ChatBadgeButton(),
          IconButton(
            onPressed: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const ProfileScreen()));
            },
            icon: UserAvatar(
              imageUrl: widget.profile['avatarUrl']?.toString(),
              name: widget.profile['name']?.toString(),
              radius: 16,
              bordered: true,
            ),
          ),
          IconButton(
            onPressed: () => AuthService().signOut(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: PremiumPageBody(
        maxWidth: 1400,
        child: isDesktop
            ? Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      width: 124,
                      child: PremiumPanel(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: NavigationRail(
                          selectedIndex: _index,
                          onDestinationSelected: (value) =>
                              ExecutorHomeScreen.tabIndex.value = value,
                          labelType: NavigationRailLabelType.all,
                          backgroundColor: Colors.transparent,
                          minWidth: 72,
                          destinations: const [
                            NavigationRailDestination(
                              icon: Icon(Icons.search),
                              label: Text('Заявки'),
                            ),
                            NavigationRailDestination(
                              icon: Icon(Icons.work_outline),
                              label: Text('Чаты'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 18),
                    Expanded(child: screens[_index]),
                  ],
                ),
              )
            : screens[_index],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => CreateJobScreen(
                initialSettlement: settlement.isEmpty ? null : settlement,
                executorMode: true,
              ),
            ),
          );
        },
        label: const Text('Новый заказ'),
        icon: const Icon(Icons.add),
      ),
      bottomNavigationBar: isDesktop
          ? null
          : BottomNavigationBar(
              currentIndex: _index,
              onTap: (value) => ExecutorHomeScreen.tabIndex.value = value,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.search),
                  label: 'Заявки',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.work_outline),
                  label: 'Чаты',
                ),
              ],
            ),
    );
  }
}
