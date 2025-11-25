import 'package:flutter/material.dart';

void main() {
  runApp(const Black3App());
}

// 1. Data Models and Enums
class Player {
  String name;
  int totalScore;
  int currentRoundPoints; // Score for the just-completed round

  Player({required this.name, this.totalScore = 0, this.currentRoundPoints = 0});
}

class RoundHistory {
  final String bidderName;
  final int bidAmount;
  // Stores the score received *this round* for each player, e.g., {'Player A': 200, 'Player B': 200, 'Player C': 0}
  final Map<String, int> roundScores;

  RoundHistory({required this.bidderName, required this.bidAmount, required this.roundScores});
}

// Removed GamePhase.playerInfo
enum GamePhase {
  enterPlayers,
  enterBid,
  recordScore,
  totalScores,
}

class Black3App extends StatelessWidget {
  const Black3App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Black 3 Tracker',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
        ),
      ),
      home: const Black3GameTracker(),
    );
  }
}

class Black3GameTracker extends StatefulWidget {
  const Black3GameTracker({super.key});

  @override
  State<Black3GameTracker> createState() => _Black3GameTrackerState();
}

class _Black3GameTrackerState extends State<Black3GameTracker> {
  // Game State Variables
  GamePhase _currentPhase = GamePhase.enterPlayers;
  List<Player> _players = [];
  int _numberOfPlayers = 5;
  List<TextEditingController> _nameControllers = [];

  // New: History of all completed rounds
  List<RoundHistory> _roundHistory = [];

  // Bid State Variables
  String? _currentBidText; // Holds the string value for the dropdown (e.g., '150')
  String? _currentBidderName;
  int _currentBidCount = 0; // Holds the parsed integer value
  // This list is now fixed size 3 (the absolute maximum partners possible)
  List<String?> _currentPartnerNames = List.filled(3, null);

  // Available bids from 150 to 250 in steps of 5
  final List<String> _availableBids = List<int>.generate(
    (250 - 150) ~/ 5 + 1,
        (i) => 150 + i * 5,
  ).map((e) => e.toString()).toList();

  @override
  void initState() {
    super.initState();
    _initializePlayerNameControllers();
    _currentBidText = _availableBids.first;
    _currentBidCount = int.parse(_currentBidText!);
  }

  void _initializePlayerNameControllers() {
    _nameControllers = List.generate(
      _numberOfPlayers,
      // Ensure controllers have default text
          (index) => TextEditingController(),
    );
    _players = List.generate(
      _numberOfPlayers,
          (index) => Player(name: 'Player ${index + 1}'),
    );
  }

  // --- Utility Getters ---

  /// Determines the MAXIMUM number of partners allowed based on the bid amount.
  int get _getMaxPartnerCount {
    if (_currentBidCount == 0) return 0;
    if (_currentBidCount < 200) return 1;
    if (_currentBidCount < 225) return 2;
    return 3;
  }

  /// Gets the full Player object for the current bidder. Returns null if no players exist.
  Player? get _currentBidder {
    if (_players.isEmpty) return null;
    return _players.firstWhere(
          (p) => p.name == _currentBidderName,
      // Fallback to the first player if the name is unexpectedly not found (shouldn't happen)
      orElse: () => _players.first,
    );
  }

  /// Gets the list of Player objects who are partners.
  List<Player> get _currentPartners => _players
  // We only consider the selected partners (non-null entries) as current partners
      .where((p) => _currentPartnerNames.whereType<String>().contains(p.name))
      .toList();

  /// Gets the list of Player objects who are the Defenders (Team B).
  List<Player> get _defenders {
    // The attacker team (Team A) consists of the bidder and all selected partners
    final teamA = [_currentBidderName, ..._currentPartnerNames.whereType<String>()];
    return _players
        .where((p) => !teamA.contains(p.name))
        .toList();
  }

  // --- Phase Navigation and Logic ---

  void _addPlayer() {
    setState(() {
      _numberOfPlayers++;
      _nameControllers.add(TextEditingController(text: 'Player $_numberOfPlayers'));
      _players.add(Player(name: 'Player $_numberOfPlayers'));
    });
  }

  void _removePlayer(int index) {
    if (_numberOfPlayers > 2) {
      setState(() {
        _numberOfPlayers--;
        _nameControllers.removeAt(index).dispose();
        _players.removeAt(index);
      });
    }
  }

  void _nextPhase() {
    setState(() {
      switch (_currentPhase) {
        case GamePhase.enterPlayers:
        // Update player names from controllers
          for (int i = 0; i < _numberOfPlayers; i++) {
            _players[i].name = _nameControllers[i].text.trim().isEmpty
                ? 'Player ${i + 1}'
                : _nameControllers[i].text.trim();
          }

          // **Direct transition from enterPlayers to enterBid**
          // Initialize bid state for the new round
          _currentBidderName = _players.first.name;
          _currentBidText = _availableBids.first;
          _currentBidCount = int.parse(_currentBidText!);
          _currentPartnerNames = List.filled(3, null);

          _currentPhase = GamePhase.enterBid;
          break;

      // Removed case GamePhase.playerInfo:

        case GamePhase.enterBid:
          _processBidEntry();
          break;
        case GamePhase.recordScore:
        // _recordScoreForTeam handles the history and totals update
          _currentPhase = GamePhase.totalScores;
          break;
        case GamePhase.totalScores:
        // Start a new game
          _currentPhase = GamePhase.enterPlayers;
          _players.clear();
          _roundHistory.clear();
          _initializePlayerNameControllers();
          break;
      }
    });
  }

  void _processBidEntry() {
    // 1. Check Bidder and Bid Value
    if (_currentBidderName == null) {
      _showSnackbar('Please select a bidder.');
      return;
    }

    if (_currentBidCount == 0) {
      _showSnackbar('Please select a valid bid count.');
      return;
    }

    // 2. Check Partners against the NEW rule (max allowed)
    final maxAllowedPartners = _getMaxPartnerCount;
    // Count selected partners (non-null entries in the entire list)
    final selectedPartners = _currentPartnerNames.where((n) => n != null).length;

    // The player must select a number of partners less than or equal to the maximum allowed.
    if (selectedPartners > maxAllowedPartners) {
      _showSnackbar('You can select a MAXIMUM of $maxAllowedPartners partner(s) based on the bid of $_currentBidCount. Please review your selection.');
      return;
    }

    // 3. Move to next phase
    setState(() {
      _currentPhase = GamePhase.recordScore;
    });
  }

  void _recordScoreForTeam(bool isTeamAWin) {
    // Safely get the current bidder. If null, something is wrong, but the UI should prevent this.
    final bidder = _currentBidder;
    if (bidder == null) return;

    // This map will store the score *received* this round (bid amount or 0) for the history ledger
    Map<String, int> roundScores = {};

    // Team A consists of the bidder and all actively selected partners
    final teamA = [bidder, ..._currentPartners];
    final teamB = _defenders;

    final winningTeam = isTeamAWin ? teamA : teamB;

    // 1. Assign scores to players based on your requested ledger format (winning team gets bid amount, losers get 0)
    for (var player in _players) {
      if (winningTeam.map((p) => p.name).contains(player.name)) {
        player.currentRoundPoints = _currentBidCount;
      } else {
        player.currentRoundPoints = 0;
      }
      roundScores[player.name] = player.currentRoundPoints;
      // 2. Update total scores
      player.totalScore += player.currentRoundPoints;
    }

    // 3. Record the round history
    final history = RoundHistory(
      bidderName: _currentBidderName!,
      bidAmount: _currentBidCount,
      roundScores: roundScores,
    );
    setState(() {
      _roundHistory.add(history);
    });

    _nextPhase(); // Move to total scores display
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 4),
        backgroundColor: Colors.red.shade700,
      ),
    );
  }

  // --- UI Builders ---

  Widget _buildEnterPlayers() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Text(
            'Enter $_numberOfPlayers Players',
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _numberOfPlayers,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _nameControllers[index],
                        decoration: InputDecoration(
                          labelText: 'Player ${index + 1} Name',
                          border: const OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                          ),
                        ),
                      ),
                    ),
                    if (_numberOfPlayers > 2)
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                        onPressed: () => _removePlayer(index),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton.icon(
            onPressed: _addPlayer,
            icon: const Icon(Icons.person_add),
            label: const Text('Add Player'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade700,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.all(15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 24.0),
          child: FilledButton(
            // This button now transitions directly to the bid phase
            onPressed: _nextPhase,
            child: const Text('Confirm Players and Start Bidding'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.all(15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEnterBid() {
    final availableBidderNames = _players.map((p) => p.name).toList();

    // The list of names available to be a partner (excludes the current bidder)
    final availablePartnerNames = _players.map((p) => p.name).where((name) => name != _currentBidderName).toList();
    final maxPartnerCount = _getMaxPartnerCount;

    // Ensure _currentBidderName is set on initial load
    if (_currentBidderName == null && _players.isNotEmpty) {
      _currentBidderName = _players.first.name;
    }

    // Clear partner selections if the bid or bidder has changed,
    // though the list size remains 3.
    if (_currentPartnerNames.length != 3) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _currentPartnerNames = List.filled(3, null);
          });
        }
      });
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Round Bid & Partners',
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          // 1. Bidder Selection
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              labelText: 'Select Bidder',
              border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
              prefixIcon: Icon(Icons.gavel),
            ),
            value: _currentBidderName,
            items: availableBidderNames
                .map((name) => DropdownMenuItem(value: name, child: Text(name)))
                .toList(),
            onChanged: (String? newValue) {
              setState(() {
                _currentBidderName = newValue;
                // Clear partner selections if the bidder changes
                _currentPartnerNames = List.filled(3, null);
              });
            },
          ),
          const SizedBox(height: 16),
          // 2. Bid Count (NOW A DROPDOWN)
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              labelText: 'Select Bid Count (150 - 250 in +5)',
              border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
              prefixIcon: Icon(Icons.score),
            ),
            value: _currentBidText,
            items: _availableBids
                .map((bid) => DropdownMenuItem(value: bid, child: Text(bid)))
                .toList(),
            onChanged: (String? newValue) {
              setState(() {
                _currentBidText = newValue;
                _currentBidCount = int.tryParse(newValue ?? '0') ?? 0;
                // Clear partner selections if the bid changes
                _currentPartnerNames = List.filled(3, null);
              });
            },
          ),
          const SizedBox(height: 20),

          // 3. Partner Rules Display
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            color: Theme.of(context).colorScheme.secondaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Text(
                'Maximum Partners Allowed: $maxPartnerCount (Bid < 200: Max 1, 200-224: Max 2, >= 225: Max 3)',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSecondaryContainer,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // 4. Partner Selection (Dynamic Dropdowns - only show up to the maximum allowed)
          ...List.generate(maxPartnerCount, (index) {
            final partnerIndex = index;

            // Calculate occupied names by checking other partner dropdowns (excluding the current one).
            final occupiedNames = _currentPartnerNames
                .asMap()
                .entries
                .where((entry) => entry.key != index && entry.value != null)
                .map((entry) => entry.value!)
                .toList();

            // Filter the available names: Must not be the bidder, and must not be selected by another partner slot.
            final itemsForThisDropdown = availablePartnerNames
                .where((name) => !occupiedNames.contains(name))
                .toList();

            // Add the currently selected value for this specific dropdown back into its item list
            // if it's not null and is a valid player name (this resolves the assertion error)
            if (_currentPartnerNames[index] != null &&
                !itemsForThisDropdown.contains(_currentPartnerNames[index]!)) {
              itemsForThisDropdown.add(_currentPartnerNames[index]!);
              itemsForThisDropdown.sort(); // Keep it sorted for consistency
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: DropdownButtonFormField<String>(
                key: ValueKey('partner-dropdown-$index'), // Added key for better stability
                decoration: InputDecoration(
                  labelText: 'Partner ${index + 1} Name (Optional)',
                  border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                  prefixIcon: const Icon(Icons.handshake),
                ),
                value: _currentPartnerNames[index],
                items: [
                  const DropdownMenuItem<String>(value: null, child: Text('No Partner')), // Allows selection of 0 partners
                  ...itemsForThisDropdown
                      .map((name) => DropdownMenuItem(value: name, child: Text(name)))
                      .toList()
                ],
                onChanged: (String? newValue) {
                  setState(() {
                    _currentPartnerNames[partnerIndex] = newValue;
                  });
                },
              ),
            );
          }),

          const SizedBox(height: 20),
          // 5. Confirm Button
          FilledButton(
            onPressed: _processBidEntry,
            child: const Text('Confirm Bid & Teams'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.all(15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordScore() {
    // Safely unwrap current bidder
    final bidderName = _currentBidderName;
    if (bidderName == null) return const Center(child: Text('Error: No bidder selected.'));

    // Only include non-null partners in Team A string display
    final teamA = [bidderName, ..._currentPartnerNames.whereType<String>()].join(', ');
    final teamB = _defenders.map((p) => p.name).join(', ');

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Who Won the Round?',
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Text(
            'Bid Amount: $_currentBidCount',
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 15),
          Text(
            'Bid By: $bidderName',
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),
          // Team A Button (Attackers/Bidder's Team)
          _buildTeamButton(
            label: 'Team A Wins (Lead By $bidderName)',
            teamMembers: teamA,
            color: Colors.lightGreen,
            onPressed: () => _recordScoreForTeam(true),
          ),
          const SizedBox(height: 20),
          // Team B Button (Defenders/Against Team)
          _buildTeamButton(
            label: 'Team B Wins (Defenders)',
            teamMembers: teamB,
            color: Colors.redAccent,
            onPressed: () => _recordScoreForTeam(false),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamButton({
    required String label,
    required String teamMembers,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 5,
      ),
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(teamMembers, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  // Builds the score history table
  Widget _buildScoreHistory() {
    if (_players.isEmpty) {
      return const Center(child: Text('No players or score history recorded.'));
    }

    final playerNames = _players.map((p) => p.name).toList();

    // The columns for the DataTable. First column is the round detail, rest are players.
    List<DataColumn> columns = [
      const DataColumn(label: Text('Round Details', style: TextStyle(fontWeight: FontWeight.bold))),
      ...playerNames.map((name) => DataColumn(
        label: Text(name.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold)),
        tooltip: name,
      )),
    ];

    // Rows for each round history item
    List<DataRow> roundRows = _roundHistory.map((history) {
      // Find the names of the partners for display (players who matched the bid amount but weren't the bidder)
      final bidder = history.bidderName;
      final partners = history.roundScores.keys
          .where((name) => name != bidder && history.roundScores[name] == history.bidAmount)
          .toList();

      final roundDetail = '${bidder}: ${history.bidAmount} ';

      List<DataCell> scoreCells = playerNames.map((name) {
        final score = history.roundScores[name] ?? 0;
        return DataCell(
          Text(
            score.toString(),
            style: TextStyle(
              fontWeight: score > 0 ? FontWeight.bold : FontWeight.normal,
              color: score > 0 ? Colors.green.shade700 : Colors.grey.shade500,
            ),
          ),
        );
      }).toList();

      return DataRow(cells: [
        DataCell(SizedBox(width: 150, child: Text(roundDetail, style: const TextStyle(fontSize: 12)))),
        ...scoreCells,
      ]);
    }).toList();

    // Row for the final totals
    List<DataCell> totalScoreCells = playerNames.map((name) {
      final player = _players.firstWhere((p) => p.name == name);
      return DataCell(
        Text(
          player.totalScore.toString(),
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.deepPurple),
        ),
      );
    }).toList();

    final totalRow = DataRow(
      color: WidgetStateProperty.resolveWith((states) => Colors.deepPurple.shade50),
      cells: [
        const DataCell(Text('Total:', style: TextStyle(fontWeight: FontWeight.bold))),
        ...totalScoreCells,
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Text(
            'Score History Ledger',
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 20,
              dataRowMinHeight: 40,
              dataRowMaxHeight: 60,
              headingRowColor: WidgetStateProperty.resolveWith((states) => Colors.grey.shade200),
              columns: columns,
              rows: [...roundRows, totalRow],
            ),
          ),
        ),
        // Navigation buttons moved below the table
        Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 24.0),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => _currentPhase = GamePhase.enterBid),
                  child: const Text('New Round'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: FilledButton(
                  onPressed: _nextPhase,
                  child: const Text('New Game'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.all(15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- Main Build Method ---

  @override
  Widget build(BuildContext context) {
    Widget currentWidget;
    String title;

    switch (_currentPhase) {
      case GamePhase.enterPlayers:
        title = 'Black 3: Setup';
        currentWidget = _buildEnterPlayers();
        break;

      case GamePhase.enterBid:
        title = 'Round: Enter Bid';
        currentWidget = _buildEnterBid();
        break;
      case GamePhase.recordScore:
        title = 'Round: Record Score';
        currentWidget = _buildRecordScore();
        break;
      case GamePhase.totalScores:
        title = 'Score History';
        currentWidget = _buildScoreHistory();
        break;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: currentWidget,
    );
  }
}