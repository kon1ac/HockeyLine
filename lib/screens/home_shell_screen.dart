import 'dart:convert';
import 'dart:io';
import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:file_picker/file_picker.dart';
import 'package:hockeyline/models/app_enums.dart';
import 'package:hockeyline/models/line.dart';
import 'package:hockeyline/models/note.dart';
import 'package:hockeyline/models/player.dart';
import 'package:hockeyline/models/statistics.dart';
import 'package:hockeyline/models/user.dart';
import 'package:hockeyline/providers/auth_provider.dart';
import 'package:hockeyline/providers/lines_provider.dart';
import 'package:hockeyline/providers/stats_provider.dart';
import 'package:hockeyline/providers/team_provider.dart';
import 'package:hockeyline/theme/app_theme.dart';
import 'package:hockeyline/widgets/design_widgets.dart';
import 'package:provider/provider.dart';

class HomeShellScreen extends StatefulWidget {
  const HomeShellScreen({super.key});

  @override
  State<HomeShellScreen> createState() => _HomeShellScreenState();
}

class _HomeShellScreenState extends State<HomeShellScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TeamProvider>().loadPlayers();
      context.read<LinesProvider>().loadLines();
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = <Widget>[
      const _RosterPage(),
      const _FavoritesPage(),
      const _LinesPage(),
      const _StatsPage(),
      const _ProfilePage(),
    ];
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double w = constraints.maxWidth;
        final bool isWide = w >= 880;
        final EdgeInsets navSafe = EdgeInsets.only(
          bottom: MediaQuery.paddingOf(context).bottom,
        );
        if (!isWide) {
          return Scaffold(
            body: AnimatedSwitcher(
              duration: AppMotion.pageSwitch,
              child: KeyedSubtree(
                key: ValueKey<int>(_currentIndex),
                child: pages[_currentIndex],
              ),
            ),
            bottomNavigationBar: Padding(
              padding: navSafe,
              child: NavigationBar(
                selectedIndex: _currentIndex,
                onDestinationSelected: (int index) => setState(() => _currentIndex = index),
                destinations: const <NavigationDestination>[
                  NavigationDestination(
                    icon: Icon(Icons.groups_outlined),
                    selectedIcon: Icon(Icons.groups),
                    label: 'Состав',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.star_outline),
                    selectedIcon: Icon(Icons.star),
                    label: 'Избранное',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.hub_outlined),
                    selectedIcon: Icon(Icons.hub),
                    label: 'Звенья',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.insert_chart_outlined),
                    selectedIcon: Icon(Icons.insert_chart),
                    label: 'Статистика',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.person_outline),
                    selectedIcon: Icon(Icons.person),
                    label: 'Профиль',
                  ),
                ],
              ),
            ),
          );
        }
        return Scaffold(
          body: Row(
            children: <Widget>[
              NavigationRail(
                extended: w >= 1200,
                minWidth: 72,
                minExtendedWidth: 200,
                selectedIndex: _currentIndex,
                onDestinationSelected: (int index) {
                  setState(() => _currentIndex = index);
                },
                labelType: NavigationRailLabelType.all,
                destinations: const <NavigationRailDestination>[
                  NavigationRailDestination(
                    icon: Icon(Icons.groups_outlined),
                    selectedIcon: Icon(Icons.groups),
                    label: Text('Состав'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.star_outline),
                    selectedIcon: Icon(Icons.star),
                    label: Text('Избранное'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.hub_outlined),
                    selectedIcon: Icon(Icons.hub),
                    label: Text('Звенья'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.insert_chart_outlined),
                    selectedIcon: Icon(Icons.insert_chart),
                    label: Text('Статистика'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.person_outline),
                    selectedIcon: Icon(Icons.person),
                    label: Text('Профиль'),
                  ),
                ],
              ),
              const VerticalDivider(width: 1),
              Expanded(
                child: AnimatedSwitcher(
                  duration: AppMotion.pageSwitch,
                  child: KeyedSubtree(
                    key: ValueKey<int>(_currentIndex),
                    child: pages[_currentIndex],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RosterPage extends StatelessWidget {
  const _RosterPage();

  @override
  Widget build(BuildContext context) {
    final TeamProvider teamProvider = context.watch<TeamProvider>();
    final bool isAdmin = context.watch<AuthProvider>().isAdmin;
    final bool isGuest = context.watch<AuthProvider>().isGuest;
    final List<Player> players = teamProvider.players;
    final bool isLoading = teamProvider.isLoading;
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double w = constraints.maxWidth;
        final double pad = w >= 600 ? AppSpacing.s20 : AppSpacing.s12;
        return Scaffold(
          appBar: AppBar(
            title: const Text('Состав'),
            bottom: hockeyIceAppBarBottom(),
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (isGuest) const GuestModeBanner(),
              Padding(
                padding: EdgeInsets.fromLTRB(pad, AppSpacing.s12, pad, AppSpacing.s8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      child: TextField(
                        onChanged: teamProvider.updateSearchQuery,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.search),
                          hintText: 'Поиск по имени или фамилии',
                        ),
                      ),
                    ),
                    if (isAdmin) ...<Widget>[
                      const SizedBox(width: AppSpacing.s8),
                      IconButton.filled(
                        style: IconButton.styleFrom(
                          minimumSize: const Size(48, 48),
                          backgroundColor: AppColors.accent,
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.add),
                        onPressed: () => _openPlayerForm(context),
                      ),
                    ],
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: pad),
                child: _FilterToolbar(teamProvider: teamProvider),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => context.read<TeamProvider>().loadPlayers(),
                  child: AnimatedSwitcher(
                    duration: AppMotion.pageSwitch,
                    child: isLoading
                        ? const Center(
                            child: CircularProgressIndicator(color: AppColors.accent),
                          )
                        : players.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: EdgeInsets.all(pad),
                            children: <Widget>[
                              const SizedBox(height: AppSpacing.s32),
                              EmptyStateView(
                                icon: Icons.groups_outlined,
                                title: 'Пока нет игроков',
                                subtitle: 'Добавьте первого игрока в команду.',
                                actionLabel: isAdmin ? 'Добавить игрока' : null,
                                onAction: isAdmin ? () => _openPlayerForm(context) : null,
                              ),
                            ],
                          )
                        : LayoutBuilder(
                            builder: (BuildContext context, BoxConstraints inner) {
                              final bool useGrid = inner.maxWidth >= 640;
                              final int columns = inner.maxWidth >= 1100 ? 3 : 2;
                              final EdgeInsets listPad = EdgeInsets.fromLTRB(
                                pad,
                                AppSpacing.s4,
                                pad,
                                AppSpacing.s16,
                              );
                              if (!useGrid) {
                                return ListView.builder(
                                  itemCount: players.length,
                                  padding: listPad,
                                  itemBuilder: (BuildContext context, int index) {
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: AppSpacing.s8),
                                      child: _PlayerCard(
                                        player: players[index],
                                        teamProvider: teamProvider,
                                      ),
                                    );
                                  },
                                );
                              }
                              return GridView.builder(
                                padding: listPad,
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: columns,
                                  mainAxisSpacing: AppSpacing.s12,
                                  crossAxisSpacing: AppSpacing.s12,
                                  childAspectRatio: columns >= 3 ? 2.5 : 2.65,
                                ),
                                itemCount: players.length,
                                itemBuilder: (BuildContext context, int index) {
                                  return _PlayerCard(
                                    player: players[index],
                                    teamProvider: teamProvider,
                                  );
                                },
                              );
                            },
                          ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FilterToolbar extends StatelessWidget {
  const _FilterToolbar({required this.teamProvider});

  final TeamProvider teamProvider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: <Widget>[
              _ChipButton(
                label: 'Все',
                onTap: () => teamProvider.updateFilters(
                  clearPosition: true,
                  clearStatus: true,
                  clearRoster: true,
                ),
              ),
              _ChipButton(
                label: 'Вратари',
                onTap: () => teamProvider.updateFilters(
                  position: PlayerPosition.goalkeeper,
                ),
              ),
              _ChipButton(
                label: 'Защитники',
                onTap: () => teamProvider.updateFilters(
                  position: PlayerPosition.defender,
                ),
              ),
              _ChipButton(
                label: 'Нападающие',
                onTap: () => teamProvider.updateFilters(
                  position: PlayerPosition.forward,
                ),
              ),
              _ChipButton(
                label: 'В заявке',
                onTap: () => teamProvider.updateFilters(rosterStatus: true),
              ),
              _ChipButton(
                label: 'Травмирован',
                onTap: () => teamProvider.updateFilters(status: PlayerStatus.injured),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: AppSpacing.s8, bottom: AppSpacing.s4),
          child: Row(
            children: <Widget>[
              Text(
                'Сортировка:',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.muted,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButton<PlayerSortType>(
                  value: teamProvider.sortType,
                  isExpanded: true,
                  dropdownColor: AppColors.surface,
                  items: const <DropdownMenuItem<PlayerSortType>>[
                    DropdownMenuItem<PlayerSortType>(
                      value: PlayerSortType.nameAsc,
                      child: Text('Имя А-Я'),
                    ),
                    DropdownMenuItem<PlayerSortType>(
                      value: PlayerSortType.nameDesc,
                      child: Text('Имя Я-А'),
                    ),
                    DropdownMenuItem<PlayerSortType>(
                      value: PlayerSortType.ageAsc,
                      child: Text('Возраст по возрастанию'),
                    ),
                    DropdownMenuItem<PlayerSortType>(
                      value: PlayerSortType.ageDesc,
                      child: Text('Возраст по убыванию'),
                    ),
                  ],
                  onChanged: (PlayerSortType? value) {
                    if (value != null) {
                      teamProvider.updateSortType(value);
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PlayerCard extends StatelessWidget {
  const _PlayerCard({required this.player, required this.teamProvider});

  final Player player;
  final TeamProvider teamProvider;

  static const TextStyle _subtitleOnCard = TextStyle(
    fontFamily: 'Roboto',
    fontSize: 13,
    color: Color(0xFF616161),
    height: 1.3,
  );

  @override
  Widget build(BuildContext context) {
    final bool isGuest = context.watch<AuthProvider>().isGuest;
    return PlayerCardSurface(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => _PlayerDetailsScreen(playerId: player.id),
          ),
        ),
        leading: SizedBox(
          width: 52,
          height: 52,
          child: Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              Positioned.fill(
                child: CircleAvatar(
                  backgroundColor: const Color(0xFFE0E0E0),
                  foregroundImage: player.photoUrl == null || player.photoUrl!.trim().isEmpty
                      ? null
                      : _resolvePlayerPhotoProvider(player.photoUrl!.trim()),
                  child: const Icon(Icons.person_outline, color: AppColors.onPlayerCard),
                ),
              ),
              Positioned(
                right: -2,
                bottom: -2,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Text(
                    '${player.number}',
                    style: const TextStyle(
                      fontFamily: 'Roboto',
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      height: 1,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        title: Text(
          player.fullName,
          style: const TextStyle(
            fontFamily: 'Roboto',
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: AppColors.onPlayerCard,
          ),
        ),
        subtitle: Text(
          '${teamProvider.formatPosition(player.position)}'
          ' · ${player.inRoster ? 'В заявке' : 'Вне заявки'}',
          style: _subtitleOnCard,
        ),
        trailing: IconButton(
          style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
          icon: Icon(
            player.isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
            color: player.isFavorite ? const Color(0xFFFFB300) : AppColors.muted,
          ),
          onPressed: isGuest
              ? null
              : () {
                  context.read<TeamProvider>().toggleFavorite(player.id);
                },
        ),
      ),
    );
  }
}

class _LinesPage extends StatelessWidget {
  const _LinesPage();

  @override
  Widget build(BuildContext context) {
    final linesProvider = context.watch<LinesProvider>();
    final TeamProvider team = context.watch<TeamProvider>();
    final bool isGuest = context.watch<AuthProvider>().isGuest;
    final List<Player> roster = team.rosterPlayers;
    final List<Line> lines = linesProvider.lines;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Звенья'),
        bottom: hockeyIceAppBarBottom(),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (isGuest) const GuestModeBanner(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.s16,
                vertical: AppSpacing.s12,
              ),
              children: <Widget>[
                Text('Игроки в заявке', style: AppTextStyles.titleSection(context)),
                const SizedBox(height: AppSpacing.s4),
                Text(
                  'Перетащите игрока в нужное звено.',
                  style: AppTextStyles.bodySmallMuted(context),
                ),
                const SizedBox(height: AppSpacing.s12),
          Wrap(
            spacing: AppSpacing.s8,
            runSpacing: AppSpacing.s8,
            children: roster
                .map(
                  (Player player) => isGuest
                      ? Chip(
                          label: Text(
                            '${player.fullName} (${_shortPosition(player.position)})',
                          ),
                        )
                      : Draggable<String>(
                          data: player.id,
                          feedback: Material(
                            child: Chip(
                              label: Text(
                                '${player.fullName} (${_shortPosition(player.position)})',
                              ),
                            ),
                          ),
                          child: Chip(
                            label: Text(
                              '${player.fullName} (${_shortPosition(player.position)})',
                            ),
                          ),
                        ),
                )
                .toList(),
          ),
          const SizedBox(height: AppSpacing.s12),
          ...lines.map((Line line) {
            final int capacity = linesProvider.lineCapacity(line.type);
            final String title = switch (line.type) {
              LineType.goalkeeper => 'Вратарская пара ${line.lineNumber}',
              LineType.forward => 'Звено нападения ${line.lineNumber}',
              LineType.defense => 'Пара защиты ${line.lineNumber}',
            };
            final List<String> validIds = line.playerIds
                .where((String id) {
                  final Player? player = team.playerById(id);
                  if (player == null) {
                    return false;
                  }
                  return linesProvider.isPositionAllowedForLine(
                    playerPosition: player.position,
                    lineType: line.type,
                  );
                })
                .toList(growable: false);
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.s12),
              child: SecondaryCardSurface(
                padding: EdgeInsets.zero,
                child: DragTarget<String>(
                onWillAcceptWithDetails: (DragTargetDetails<String> details) {
                  final Player? player = team.playerById(details.data);
                  if (player == null) {
                    return false;
                  }
                  final bool positionAllowed = linesProvider.isPositionAllowedForLine(
                    playerPosition: player.position,
                    lineType: line.type,
                  );
                  if (!positionAllowed) {
                    return false;
                  }
                  return linesProvider.canAddPlayerToLine(
                    line: line,
                    playerId: player.id,
                  );
                },
                onAcceptWithDetails: isGuest
                    ? null
                    : (DragTargetDetails<String> details) async {
                        final Player? player = team.playerById(details.data);
                        if (player == null) {
                          return;
                        }
                        final bool isAllowed = linesProvider.isPositionAllowedForLine(
                          playerPosition: player.position,
                          lineType: line.type,
                        );
                        if (!isAllowed) {
                          if (context.mounted) {
                            showAppSnackBar(
                              context,
                              switch (line.type) {
                                LineType.goalkeeper =>
                                  'В эту линию можно добавить только вратарей',
                                LineType.forward =>
                                  'В звено нападения можно добавить только нападающих',
                                LineType.defense =>
                                  'В пару защиты можно добавить только защитников',
                              },
                              error: true,
                            );
                          }
                          return;
                        }
                        if (!linesProvider.canAddPlayerToLine(
                          line: line,
                          playerId: player.id,
                        )) {
                          if (context.mounted) {
                            showAppSnackBar(
                              context,
                              'Линия заполнена: максимум $capacity игроков',
                              error: true,
                            );
                          }
                          return;
                        }
                        await linesProvider.movePlayer(
                          playerId: details.data,
                          targetLineId: line.id,
                          playerPosition: player.position,
                        );
                      },
                builder: (context, _, __) => ListTile(
                  title: Text('$title (${validIds.length}/$capacity)'),
                  subtitle: validIds.isEmpty
                      ? const Text('-')
                      : Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: validIds
                              .map(
                                (String id) => InputChip(
                                  label: Text(team.playerById(id)!.fullName),
                                  onDeleted: isGuest ? null : () {
                                    linesProvider.removePlayerFromLine(
                                      playerId: id,
                                      lineId: line.id,
                                    );
                                  },
                                ),
                              )
                              .toList(growable: false),
                        ),
                ),
              ),
            ),
            );
          }),
          const SizedBox(height: AppSpacing.s8),
          OutlinedButton.icon(
            onPressed: isGuest ? null : () async {
              await linesProvider.clearAllLines();
              if (context.mounted) {
                showAppSnackBar(context, 'Все звенья очищены', success: true);
              }
            },
            icon: const Icon(Icons.clear_all),
            label: const Text('Очистить все звенья'),
          ),
          const SizedBox(height: AppSpacing.s8),
          ElevatedButton(
            onPressed: isGuest ? null : () async {
              await linesProvider.saveLines();
              if (context.mounted) {
                showAppSnackBar(context, 'Состав звеньев сохранён', success: true);
              }
            },
            child: const Text('Сохранить звенья'),
          ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FavoritesPage extends StatelessWidget {
  const _FavoritesPage();

  @override
  Widget build(BuildContext context) {
    final TeamProvider team = context.watch<TeamProvider>();
    final bool isGuest = context.watch<AuthProvider>().isGuest;
    final List<Player> favorites = team.favoritePlayers;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Избранное'),
        bottom: hockeyIceAppBarBottom(),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (isGuest) const GuestModeBanner(),
          Expanded(
            child: favorites.isEmpty
                ? EmptyStateView(
                    icon: Icons.star_outline,
                    title: 'Нет избранных игроков',
                    subtitle: 'Отметьте звёздочкой игроков в составе.',
                  )
                : LayoutBuilder(
                    builder: (BuildContext context, BoxConstraints c) {
                      final double pad = c.maxWidth >= 600 ? AppSpacing.s20 : AppSpacing.s12;
                      return ListView.builder(
                        padding: EdgeInsets.fromLTRB(pad, AppSpacing.s12, pad, AppSpacing.s24),
                        itemCount: favorites.length,
                        itemBuilder: (BuildContext context, int index) {
                          final Player player = favorites[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.s12),
                            child: Dismissible(
                              key: ValueKey<String>('favorite-${player.id}'),
                              direction: DismissDirection.endToStart,
                              background: ColoredBox(
                                color: AppColors.accent.withValues(alpha: 0.88),
                                child: const Align(
                                  alignment: Alignment.centerRight,
                                  child: Padding(
                                    padding: EdgeInsets.only(right: AppSpacing.s16),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: <Widget>[
                                        Icon(Icons.star_outline, color: Colors.white, size: 22),
                                        SizedBox(height: AppSpacing.s4),
                                        Text(
                                          'Убрать\nиз избранного',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            height: 1.15,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              onDismissed: (_) {
                                context.read<TeamProvider>().toggleFavorite(player.id);
                              },
                              child: PlayerCardSurface(
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 4,
                                  ),
                                  title: Text(
                                    player.fullName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.onPlayerCard,
                                    ),
                                  ),
                                  subtitle: Text(
                                    '${team.formatPosition(player.position)} · #${player.number}',
                                    style: const TextStyle(color: Color(0xFF616161), fontSize: 13),
                                  ),
                                  trailing: IconButton(
                                    style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
                                    onPressed: () => context.read<TeamProvider>().toggleFavorite(player.id),
                                    icon: const Icon(Icons.delete_outline, color: AppColors.muted),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _StatsPage extends StatelessWidget {
  const _StatsPage();

  @override
  Widget build(BuildContext context) {
    final List<Player> players = context.watch<TeamProvider>().players;
    final bool isAdmin = context.watch<AuthProvider>().isAdmin;
    final bool isGuest = context.watch<AuthProvider>().isGuest;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Статистика'),
        bottom: hockeyIceAppBarBottom(),
      ),
      body: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double w = constraints.maxWidth;
          final double chartBlockHeight = w < 520 ? 400.0 : 220.0;
          final EdgeInsets pad = EdgeInsets.symmetric(
            horizontal: w >= 600 ? AppSpacing.s16 : AppSpacing.s12,
            vertical: AppSpacing.s8,
          );
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (isGuest) const GuestModeBanner(),
              Padding(
                padding: pad,
                child: Wrap(
                  spacing: AppSpacing.s8,
                  runSpacing: AppSpacing.s8,
                  alignment: WrapAlignment.start,
                  children: <Widget>[
                    ElevatedButton(
                      onPressed: () async {
                        final String path = await context
                            .read<StatsProvider>()
                            .exportStatsAsCsv(players);
                        if (context.mounted) {
                          showAppSnackBar(
                            context,
                            'CSV сохранён: $path',
                            success: true,
                          );
                        }
                      },
                      child: const Text('Экспорт CSV'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        final String path = await context
                            .read<StatsProvider>()
                            .exportStatsAsPdf(players);
                        if (context.mounted) {
                          showAppSnackBar(
                            context,
                            'PDF сохранён: $path',
                            success: true,
                          );
                        }
                      },
                      child: const Text('Экспорт PDF'),
                    ),
                  ],
                ),
              ),
              if (players.isEmpty)
                Expanded(
                  child: EmptyStateView(
                    icon: Icons.insert_chart_outlined,
                    title: 'Нет данных для статистики',
                    subtitle: 'Добавьте игроков в составе.',
                  ),
                )
              else ...<Widget>[
                SizedBox(
                  height: chartBlockHeight,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: pad.horizontal / 2),
                    child: _StatsCharts(players: players, layoutWidth: w),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: EdgeInsets.only(bottom: pad.bottom + AppSpacing.s8),
                    itemCount: players.length,
                    itemBuilder: (BuildContext context, int index) {
                      final Player player = players[index];
                      return ListTile(
                        title: Text(
                          player.fullName,
                          style: AppTextStyles.bodyEmphasis(context).copyWith(
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        subtitle: Text(
                          'Игр: ${player.statistics.games}, '
                          'Г: ${player.statistics.goals}, '
                          'П: ${player.statistics.assists}, '
                          'Очки: ${player.statistics.points}, '
                          '+/-: ${player.statistics.plusMinus}',
                          style: AppTextStyles.statsFigures(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.85),
                          ),
                        ),
                        trailing: isAdmin
                            ? PopupMenuButton<String>(
                                onSelected: (String action) {
                                  final team = context.read<TeamProvider>();
                                  if (action == 'goal') {
                                    team.incrementStats(playerId: player.id, goals: 1);
                                  } else if (action == 'assist') {
                                    team.incrementStats(playerId: player.id, assists: 1);
                                  } else if (action == 'penalty') {
                                    team.incrementStats(playerId: player.id, penalties: 2);
                                  }
                                },
                                itemBuilder: (_) => const <PopupMenuEntry<String>>[
                                  PopupMenuItem<String>(
                                    value: 'goal',
                                    child: Text('+ Гол'),
                                  ),
                                  PopupMenuItem<String>(
                                    value: 'assist',
                                    child: Text('+ Передача'),
                                  ),
                                  PopupMenuItem<String>(
                                    value: 'penalty',
                                    child: Text('+ Штраф'),
                                  ),
                                ],
                              )
                            : null,
                      );
                    },
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _ProfilePage extends StatelessWidget {
  const _ProfilePage();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Профиль'),
        bottom: hockeyIceAppBarBottom(),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (auth.isGuest) const GuestModeBanner(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.s16),
              children: <Widget>[
          Text(
            'Email: ${auth.currentUser?.email ?? '-'}',
            style: AppTextStyles.bodyEmphasis(context),
          ),
          const SizedBox(height: AppSpacing.s8),
          Text(
            'Роль: ${auth.currentUser?.role.name ?? '-'}',
            style: AppTextStyles.bodySmallMuted(context),
          ),
          const SizedBox(height: AppSpacing.s24),
          if (!auth.isSystemAdmin(auth.currentUser?.id ?? '')) ...<Widget>[
            ElevatedButton(
              onPressed: () async {
                await auth.deleteCurrentAccount();
              },
              child: const Text('Удалить аккаунт'),
            ),
            const SizedBox(height: AppSpacing.s8),
          ],
          ElevatedButton(
            onPressed: () async {
              await context.read<AuthProvider>().signOut();
            },
            child: const Text('Выйти из аккаунта'),
          ),
          const SizedBox(height: AppSpacing.s8),
          if (!auth.isGuest) ...<Widget>[
            OutlinedButton.icon(
              onPressed: () async {
                final String path = await context.read<TeamProvider>().exportFullAppDataJson();
                if (context.mounted) {
                  showAppSnackBar(
                    context,
                    'Полный бэкап данных сохранён: $path',
                    success: true,
                  );
                }
              },
              icon: const Icon(Icons.download_outlined),
              label: const Text('Экспорт полных данных (JSON)'),
            ),
            const SizedBox(height: AppSpacing.s8),
          ],
          if (!auth.isGuest) ...<Widget>[
            OutlinedButton.icon(
              onPressed: () async {
                final bool? ok = await showDialog<bool>(
                  context: context,
                  builder: (BuildContext ctx) => AlertDialog(
                    title: const Text('Импорт из JSON'),
                    content: const Text(
                      'Файл должен быть в том же формате, что экспорт приложения (users, players, lines, notes). '
                      'Текущие данные на устройстве будут полностью заменены содержимым файла.',
                    ),
                    actions: <Widget>[
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: const Text('Отмена'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.of(ctx).pop(true),
                        child: const Text('Выбрать файл'),
                      ),
                    ],
                  ),
                );
                if (ok != true || !context.mounted) {
                  return;
                }
                final FilePickerResult? pick = await FilePicker.platform.pickFiles(
                  type: FileType.custom,
                  allowedExtensions: <String>['json'],
                  withData: true,
                );
                if (pick == null || pick.files.isEmpty || !context.mounted) {
                  return;
                }
                final PlatformFile file = pick.files.single;
                final String? content = file.bytes != null
                    ? utf8.decode(file.bytes!, allowMalformed: false)
                    : (file.path != null ? await File(file.path!).readAsString() : null);
                if (content == null || content.isEmpty) {
                  showAppDialog(
                    context: context,
                    title: 'Ошибка импорта',
                    message: 'Не удалось прочитать файл',
                    isError: true,
                  );
                  return;
                }
                final TeamProvider team = context.read<TeamProvider>();
                final AuthProvider authProvider = context.read<AuthProvider>();
                final String? importError = await team.importBackupJson(content);
                if (!context.mounted) {
                  return;
                }
                if (importError != null) {
                  showAppDialog(
                    context: context,
                    title: 'Ошибка импорта',
                    message: importError,
                    isError: true,
                  );
                  return;
                }
                authProvider.invalidateSystemAccountsCache();
                await authProvider.ensureSystemAccounts();
                await authProvider.reconcileSessionAfterDataChange();
                await context.read<LinesProvider>().loadLines();
                if (!context.mounted) {
                  return;
                }
                if (!context.read<AuthProvider>().isAuthorized) {
                  showAppSnackBar(
                    context,
                    'Данные импортированы. Текущий пользователь отсутствует в файле — войдите снова.',
                    success: true,
                  );
                } else {
                  showAppSnackBar(context, 'Данные успешно импортированы из JSON.', success: true);
                }
              },
              icon: const Icon(Icons.upload_file_outlined),
              label: const Text('Импорт из JSON (бэкап)'),
            ),
            const SizedBox(height: AppSpacing.s8),
          ],
          if (auth.isAdmin) ...<Widget>[
            const SizedBox(height: AppSpacing.s24),
            Text(
              'Управление пользователями',
              style: AppTextStyles.titleSection(context),
            ),
            const SizedBox(height: AppSpacing.s8),
            const _UsersAdminPanel(),
          ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChipButton extends StatelessWidget {
  const _ChipButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4),
      child: SizedBox(
        height: 48,
        child: Center(
          child: ActionChip(
            label: Text(label),
            onPressed: onTap,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
      ),
    );
  }
}

class _PlayerDetailsScreen extends StatelessWidget {
  const _PlayerDetailsScreen({required this.playerId});

  final String playerId;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final TeamProvider team = context.watch<TeamProvider>();
    final Player? player = team.playerById(playerId);
    if (player == null) {
      return const Scaffold(body: Center(child: Text('Игрок не найден')));
    }
    final List<Note> notes = team.notesByPlayerId(playerId);
    return Scaffold(
      appBar: AppBar(
        title: Text(player.fullName),
        bottom: hockeyIceAppBarBottom(),
        actions: <Widget>[
          if (auth.isAdmin)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _openPlayerForm(context, existing: player),
            ),
          if (auth.isAdmin)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () async {
                await team.deletePlayer(player.id);
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              },
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.s16),
        children: <Widget>[
          Center(
            child: SizedBox(
              width: 104,
              height: 104,
              child: Stack(
                clipBehavior: Clip.none,
                children: <Widget>[
                  Positioned.fill(
                    child: CircleAvatar(
                      radius: 48,
                      backgroundColor: const Color(0xFFE0E0E0),
                      foregroundImage: player.photoUrl == null || player.photoUrl!.trim().isEmpty
                          ? null
                          : _resolvePlayerPhotoProvider(player.photoUrl!.trim()),
                      child: const Icon(Icons.person_outline, size: 34, color: AppColors.onPlayerCard),
                    ),
                  ),
                  Positioned(
                    right: 2,
                    bottom: 2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${player.number}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.s12),
          Text(
            'Амплуа: ${team.formatPosition(player.position)}',
            style: AppTextStyles.bodyEmphasis(context),
          ),
          const SizedBox(height: AppSpacing.s4),
          Text(
            'Возраст: ${player.age} лет',
            style: AppTextStyles.bodySmallMuted(context),
          ),
          SwitchListTile(
            value: player.inRoster,
            onChanged: auth.isGuest ? null : (bool value) async {
              await team.toggleRoster(player.id, value);
              if (!value && context.mounted) {
                await context.read<LinesProvider>().removePlayerFromAllLines(player.id);
              }
            },
            title: const Text('Включить в заявку на матч'),
          ),
          const SizedBox(height: AppSpacing.s16),
          Text('Заметки', style: AppTextStyles.titleSection(context)),
          const SizedBox(height: AppSpacing.s8),
          ...notes.map(
            (Note note) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.s8),
              child: SecondaryCardSurface(
                padding: EdgeInsets.zero,
                child: ListTile(
                  title: Text(note.text),
                  subtitle: Text(
                    'Автор: ${note.authorId}',
                    style: AppTextStyles.bodySmallMuted(context),
                  ),
                  trailing: PopupMenuButton<String>(
                    enabled: !auth.isGuest,
                    onSelected: (String action) {
                      if (action == 'edit') {
                        _openNoteDialog(context, player.id, note: note);
                      } else if (action == 'delete') {
                        team.deleteNote(
                          noteId: note.id,
                          currentUserId: auth.currentUser?.id ?? '',
                          canDeleteAny: auth.isAdmin,
                        );
                      }
                    },
                    itemBuilder: (_) => const <PopupMenuEntry<String>>[
                      PopupMenuItem<String>(value: 'edit', child: Text('Изменить')),
                      PopupMenuItem<String>(value: 'delete', child: Text('Удалить')),
                    ],
                  ),
                ),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: auth.isGuest ? null : () => _openNoteDialog(context, player.id),
            child: const Text('Добавить заметку'),
          ),
        ],
      ),
    );
  }
}

Future<void> _openNoteDialog(
  BuildContext context,
  String playerId, {
  Note? note,
}) async {
  final TextEditingController controller = TextEditingController(
    text: note?.text ?? '',
  );
  final bool? submit = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(note == null ? 'Новая заметка' : 'Редактирование заметки'),
      content: TextField(
        controller: controller,
        maxLines: 3,
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Отмена'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Сохранить'),
        ),
      ],
    ),
  );
  if (submit != true || !context.mounted) {
    return;
  }
  final AuthProvider auth = context.read<AuthProvider>();
  final TeamProvider team = context.read<TeamProvider>();
  if (note == null) {
    await team.addNote(
      playerId: playerId,
      authorId: auth.currentUser?.id ?? '',
      text: controller.text,
    );
  } else {
    await team.updateNote(
      noteId: note.id,
      text: controller.text,
      currentUserId: auth.currentUser?.id ?? '',
      canEditAny: auth.isAdmin,
    );
  }
}

Future<void> _openPlayerForm(BuildContext context, {Player? existing}) async {
  final TextEditingController firstName = TextEditingController(
    text: existing?.firstName ?? '',
  );
  final TextEditingController lastName = TextEditingController(
    text: existing?.lastName ?? '',
  );
  final TextEditingController number = TextEditingController(
    text: existing?.number.toString() ?? '',
  );
  final TextEditingController height = TextEditingController(
    text: existing?.height?.toString() ?? '',
  );
  final TextEditingController weight = TextEditingController(
    text: existing?.weight?.toString() ?? '',
  );
  final TextEditingController photoUrl = TextEditingController(
    text: existing?.photoUrl ?? '',
  );
  PlayerPosition position = existing?.position ?? PlayerPosition.forward;
  PlayerStatus status = existing?.status ?? PlayerStatus.active;
  DateTime birthDate = existing?.birthDate ?? DateTime(2004, 1, 1);
  await showDialog<void>(
    context: context,
    builder: (_) => StatefulBuilder(
      builder: (BuildContext context, void Function(void Function()) setState) {
        return AlertDialog(
          title: Text(existing == null ? 'Добавить игрока' : 'Редактировать игрока'),
          content: SizedBox(
            width: 420,
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints c) {
                final bool wide = c.maxWidth >= 380;
                final Widget numberField = TextField(
                  controller: number,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Номер'),
                );
                final Widget positionDropdown = DropdownButton<PlayerPosition>(
                  value: position,
                  isExpanded: true,
                  items: const <DropdownMenuItem<PlayerPosition>>[
                    DropdownMenuItem(
                      value: PlayerPosition.goalkeeper,
                      child: Text('Вратарь'),
                    ),
                    DropdownMenuItem(
                      value: PlayerPosition.defender,
                      child: Text('Защитник'),
                    ),
                    DropdownMenuItem(
                      value: PlayerPosition.forward,
                      child: Text('Нападающий'),
                    ),
                  ],
                  onChanged: (PlayerPosition? value) {
                    if (value != null) {
                      setState(() {
                        position = value;
                      });
                    }
                  },
                );
                return SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      ExpansionTile(
                        title: Text(
                          'Личные данные',
                          style: AppTextStyles.titleSection(context),
                        ),
                        initiallyExpanded: true,
                        children: <Widget>[
                          TextField(
                            controller: firstName,
                            decoration: const InputDecoration(labelText: 'Имя'),
                          ),
                          const SizedBox(height: AppSpacing.s8),
                          TextField(
                            controller: lastName,
                            decoration: const InputDecoration(labelText: 'Фамилия'),
                          ),
                          const SizedBox(height: AppSpacing.s8),
                          if (wide)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Expanded(flex: 2, child: numberField),
                                const SizedBox(width: AppSpacing.s12),
                                Expanded(flex: 3, child: positionDropdown),
                              ],
                            )
                          else
                            numberField,
                          const SizedBox(height: AppSpacing.s8),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton(
                              onPressed: () async {
                                final DateTime? picked = await showDatePicker(
                                  context: context,
                                  firstDate: DateTime(1965),
                                  lastDate: DateTime.now(),
                                  initialDate: birthDate,
                                );
                                if (picked != null) {
                                  setState(() {
                                    birthDate = picked;
                                  });
                                }
                              },
                              child: Text(
                                'Дата рождения: ${birthDate.year}-${birthDate.month}-${birthDate.day}',
                              ),
                            ),
                          ),
                        ],
                      ),
                      ExpansionTile(
                        title: Text(
                          'Амплуа и статус',
                          style: AppTextStyles.titleSection(context),
                        ),
                        children: <Widget>[
                          if (!wide) ...<Widget>[
                            positionDropdown,
                            const SizedBox(height: AppSpacing.s8),
                          ],
                          DropdownButton<PlayerStatus>(
                            value: status,
                            isExpanded: true,
                            items: const <DropdownMenuItem<PlayerStatus>>[
                              DropdownMenuItem(
                                value: PlayerStatus.active,
                                child: Text('В строю'),
                              ),
                              DropdownMenuItem(
                                value: PlayerStatus.injured,
                                child: Text('Травмирован'),
                              ),
                            ],
                            onChanged: (PlayerStatus? value) {
                              if (value != null) {
                                setState(() {
                                  status = value;
                                });
                              }
                            },
                          ),
                        ],
                      ),
                      ExpansionTile(
                        title: Text(
                          'Тело и фото',
                          style: AppTextStyles.titleSection(context),
                        ),
                        children: <Widget>[
                          TextField(
                            controller: height,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Рост (см)'),
                          ),
                          const SizedBox(height: AppSpacing.s8),
                          TextField(
                            controller: weight,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Вес (кг)'),
                          ),
                          const SizedBox(height: AppSpacing.s8),
                          TextField(
                            controller: photoUrl,
                            decoration: const InputDecoration(labelText: 'URL фото'),
                          ),
                          const SizedBox(height: AppSpacing.s8),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                final FilePickerResult? result = await FilePicker.platform.pickFiles(
                                  type: FileType.custom,
                                  allowedExtensions: <String>['jpg', 'jpeg', 'png', 'webp'],
                                );
                                final String? path = result?.files.single.path;
                                if (path == null || path.isEmpty) {
                                  return;
                                }
                                setState(() {
                                  photoUrl.text = path;
                                });
                              },
                              icon: const Icon(Icons.photo_library_outlined),
                              label: const Text('Выбрать фото с устройства'),
                            ),
                          ),
                          if (photoUrl.text.trim().isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: AppSpacing.s8),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(AppRadius.sm),
                                child: Image(
                                  image: _resolvePlayerPhotoProvider(photoUrl.text.trim()),
                                  height: 120,
                                  width: 120,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const SizedBox(
                                    height: 120,
                                    width: 120,
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(color: AppColors.surface),
                                      child: Icon(Icons.broken_image_outlined),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: () async {
                final TeamProvider team = context.read<TeamProvider>();
                final Player draft = Player(
                  id: existing?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                  firstName: firstName.text.trim(),
                  lastName: lastName.text.trim(),
                  birthDate: birthDate,
                  position: position,
                  number: int.tryParse(number.text) ?? 0,
                  height: int.tryParse(height.text),
                  weight: int.tryParse(weight.text),
                  photoUrl: photoUrl.text.trim().isEmpty ? null : photoUrl.text.trim(),
                  status: status,
                  inRoster: existing?.inRoster ?? false,
                  statistics:
                      existing?.statistics ??
                      const Statistics(
                        games: 0,
                        goals: 0,
                        assists: 0,
                        penaltyMinutes: 0,
                        plusMinus: 0,
                      ),
                );
                final String? error = existing == null
                    ? await team.addPlayer(draft)
                    : await team.updatePlayer(draft);
                if (!context.mounted) {
                  return;
                }
                if (error != null) {
                  showAppDialog(
                    context: context,
                    title: 'Ошибка валидации',
                    message: error,
                    isError: true,
                  );
                  return;
                }
                Navigator.of(context).pop();
              },
              child: const Text('Сохранить'),
            ),
          ],
        );
      },
    ),
  );
}

ImageProvider<Object> _resolvePlayerPhotoProvider(String source) {
  final String normalized = source.trim();
  if (normalized.startsWith('http://') || normalized.startsWith('https://')) {
    return NetworkImage(normalized);
  }
  if (normalized.startsWith('file://')) {
    return FileImage(File(Uri.parse(normalized).toFilePath()));
  }
  if (normalized.startsWith('/') || RegExp(r'^[A-Za-z]:').hasMatch(normalized)) {
    return FileImage(File(normalized));
  }
  final Uri? maybeUri = Uri.tryParse(normalized);
  if (maybeUri != null && maybeUri.scheme == 'file') {
    return FileImage(File(maybeUri.toFilePath()));
  }
  if (maybeUri != null && maybeUri.hasScheme) {
    return NetworkImage(normalized);
  }
  if (normalized.contains(r'\')) {
    return FileImage(File(normalized));
  }
  if (normalized.contains('/') && !normalized.contains(' ')) {
    return FileImage(File(normalized));
  }
  if (!normalized.contains(' ')) {
    return NetworkImage('https://$normalized');
  }
  return FileImage(File(normalized));
}

String _shortPosition(PlayerPosition position) {
  switch (position) {
    case PlayerPosition.goalkeeper:
      return 'В';
    case PlayerPosition.defender:
      return 'З';
    case PlayerPosition.forward:
      return 'Н';
  }
}

class _StatsCharts extends StatelessWidget {
  const _StatsCharts({required this.players, required this.layoutWidth});

  final List<Player> players;
  final double layoutWidth;

  @override
  Widget build(BuildContext context) {
    if (players.isEmpty) {
      return EmptyStateView(
        icon: Icons.bar_chart_outlined,
        title: 'Нет данных для графиков',
        subtitle: 'Добавьте игроков в состав — тогда появятся диаграммы.',
      );
    }
    final Map<PlayerPosition, int> positionsCount = <PlayerPosition, int>{
      PlayerPosition.goalkeeper: players.where((Player p) => p.position == PlayerPosition.goalkeeper).length,
      PlayerPosition.defender: players.where((Player p) => p.position == PlayerPosition.defender).length,
      PlayerPosition.forward: players.where((Player p) => p.position == PlayerPosition.forward).length,
    };
    final List<Player> topScorers = List<Player>.from(players)
      ..sort((Player a, Player b) => b.statistics.points.compareTo(a.statistics.points));
    final List<Player> chartPlayers = topScorers.take(5).toList(growable: false);
    final double maxPoints = chartPlayers.isEmpty
        ? 1
        : chartPlayers
              .map((Player p) => p.statistics.points)
              .reduce((int a, int b) => a > b ? a : b)
              .toDouble();

    const Color pieGk = Color(0xFF42A5F5);
    const Color pieDef = Color(0xFF66BB6A);

    final Widget pieCard = Expanded(
      child: SecondaryCardSurface(
        padding: const EdgeInsets.all(AppSpacing.s8),
        child: Column(
            children: <Widget>[
              Text('Состав по амплуа', style: AppTextStyles.titleSection(context)),
              const SizedBox(height: AppSpacing.s8),
              Expanded(
                child: PieChart(
                  PieChartData(
                    centerSpaceRadius: 26,
                    sectionsSpace: 2,
                    sections: <PieChartSectionData>[
                      PieChartSectionData(
                        value: positionsCount[PlayerPosition.goalkeeper]!.toDouble(),
                        title: '${positionsCount[PlayerPosition.goalkeeper]}',
                        color: pieGk,
                      ),
                      PieChartSectionData(
                        value: positionsCount[PlayerPosition.defender]!.toDouble(),
                        title: '${positionsCount[PlayerPosition.defender]}',
                        color: pieDef,
                      ),
                      PieChartSectionData(
                        value: positionsCount[PlayerPosition.forward]!.toDouble(),
                        title: '${positionsCount[PlayerPosition.forward]}',
                        color: AppColors.accent,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.s8),
              Wrap(
                spacing: 10,
                runSpacing: 6,
                children: const <Widget>[
                  _LegendDot(color: pieGk, label: 'Вратари'),
                  _LegendDot(color: pieDef, label: 'Защитники'),
                  _LegendDot(color: AppColors.accent, label: 'Нападающие'),
                ],
              ),
            ],
          ),
      ),
    );

    final Widget barCard = Expanded(
      child: SecondaryCardSurface(
        padding: const EdgeInsets.all(AppSpacing.s8),
        child: Column(
            children: <Widget>[
              Text('Топ-5 по очкам', style: AppTextStyles.titleSection(context)),
              const SizedBox(height: AppSpacing.s8),
              Expanded(
                child: BarChart(
                  BarChartData(
                    maxY: maxPoints + 1,
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: maxPoints > 5 ? 2 : 1,
                      getDrawingHorizontalLine: (_) => FlLine(
                        color: AppColors.chartCool,
                        strokeWidth: 1,
                      ),
                    ),
                    borderData: FlBorderData(
                      show: true,
                      border: Border.all(color: AppColors.outline),
                    ),
                    titlesData: FlTitlesData(
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: true, reservedSize: 30),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (double value, TitleMeta meta) {
                            final int index = value.toInt();
                            if (index < 0 || index >= chartPlayers.length) {
                              return const SizedBox.shrink();
                            }
                            return Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                chartPlayers[index].lastName,
                                style: const TextStyle(fontSize: 10, fontFamily: 'Roboto'),
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    barGroups: <BarChartGroupData>[
                      for (int i = 0; i < chartPlayers.length; i++)
                        BarChartGroupData(
                          x: i,
                          barRods: <BarChartRodData>[
                            BarChartRodData(
                              toY: chartPlayers[i].statistics.points.toDouble(),
                              color: AppColors.accent,
                              width: 18,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
      ),
    );

    if (layoutWidth < 520) {
      return Column(
        children: <Widget>[
          pieCard,
          const SizedBox(height: AppSpacing.s8),
          barCard,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        pieCard,
        const SizedBox(width: AppSpacing.s8),
        barCard,
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(label),
      ],
    );
  }
}

class _UsersAdminPanel extends StatelessWidget {
  const _UsersAdminPanel();

  @override
  Widget build(BuildContext context) {
    final AuthProvider auth = context.read<AuthProvider>();
    return FutureBuilder<List<User>>(
      future: auth.allUsers(),
      builder: (BuildContext context, AsyncSnapshot<List<User>> snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final List<User> users = snapshot.data!;
        return Column(
          children: users.map((User user) {
            return SecondaryCardSurface(
              padding: EdgeInsets.zero,
              child: ListTile(
                title: Text(user.email, style: AppTextStyles.bodyEmphasis(context)),
                subtitle: Text(user.role.name, style: AppTextStyles.bodySmallMuted(context)),
                trailing: auth.isSystemAdmin(user.id)
                    ? Chip(
                        label: const Text('Системный администратор'),
                        avatar: const Icon(Icons.shield, size: 18),
                      )
                    : Wrap(
                        spacing: AppSpacing.s8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: <Widget>[
                          DropdownButton<UserRole>(
                            value: user.role,
                            items: UserRole.values
                                .map(
                                  (UserRole role) => DropdownMenuItem<UserRole>(
                                    value: role,
                                    child: Text(role.name),
                                  ),
                                )
                                .toList(growable: false),
                            onChanged: (UserRole? value) async {
                              if (value == null) {
                                return;
                              }
                              final String? error = await context.read<AuthProvider>().updateUserRole(
                                userId: user.id,
                                role: value,
                              );
                              if (context.mounted && error != null) {
                                showAppDialog(
                                  context: context,
                                  title: 'Ошибка изменения роли',
                                  message: error,
                                  isError: true,
                                );
                              }
                            },
                          ),
                          IconButton(
                            style: IconButton.styleFrom(
                              minimumSize: const Size(48, 48),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            onPressed: () async {
                              final String? error = await context.read<AuthProvider>().deleteUserById(
                                user.id,
                              );
                              if (context.mounted) {
                                if (error != null) {
                                  showAppDialog(
                                    context: context,
                                    title: 'Ошибка удаления',
                                    message: error,
                                    isError: true,
                                  );
                                } else {
                                  showAppSnackBar(context, 'Пользователь удалён', success: true);
                                }
                              }
                            },
                            icon: const Icon(Icons.delete_outline),
                          ),
                        ],
                      ),
              ),
            );
          }).toList(growable: false),
        );
      },
    );
  }
}

