import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wordle_app/main.dart';
import 'package:wordle_app/list/word_list.dart';
import 'package:wordle_app/list/answer_list.dart';
import 'package:wordle_app/list/word_list_id.dart';
import 'package:wordle_app/list/answer_list_id.dart';
import 'package:wordle_app/main/wordle_game.dart';

enum GameLanguage { english, indonesian }

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  WordleGame? _game;
  int currentIndex = 0;
  bool _isLoading = true;
  List<String> _wordList = [];
  Set<String> _allowedWordSet = {};

  GameLanguage _language = GameLanguage.english;

  List<String> _answerPool = [];
  final Set<String> _usedAnswers = {};

  List<AnimationController> _flipControllers = [];
  List<Animation<double>> _flipAnimations = [];

  final FocusNode _keyboardFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _initializeGame();
  }

  void _initializeControllers() {
    for (final controller in _flipControllers) {
      controller.dispose();
    }

    final numTiles = _game!.maxAttempts * _game!.lettersPerWord;
    _flipControllers = List.generate(
      numTiles,
      (index) => AnimationController(
        duration: const Duration(milliseconds: 300),
        vsync: this,
      ),
    );
    _flipAnimations = _flipControllers
        .map((controller) => Tween(begin: 0.0, end: 1.0).animate(controller))
        .toList();
  }

  List<String> get _currentWordList =>
      _language == GameLanguage.english ? wordList : wordListId;

  List<String> get _currentAnswerList =>
      _language == GameLanguage.english ? answerList : answerListId;

  Future<void> _initializeGame() async {
    setState(() => _isLoading = true);
    _allowedWordSet = Set.of(_currentWordList);
    final words = List.of(_currentWordList)..shuffle();
    if (!mounted) return;

    _answerPool = List.of(_currentAnswerList);
    _usedAnswers.clear();
    final firstAnswer = _pickNextAnswer();

    setState(() {
      _wordList = words;
      _game = WordleGame(targetWord: firstAnswer);
      _initializeControllers();
      _isLoading = false;
    });
  }

  Future<void> _switchLanguage(GameLanguage newLanguage) async {
    if (_language == newLanguage) return;
    setState(() {
      _language = newLanguage;
    });
    await _initializeGame();
  }

  String _pickNextAnswer() {
    if (_answerPool.isEmpty) {
      return _wordList.isNotEmpty
          ? _wordList[Random().nextInt(_wordList.length)]
          : '';
    }

    if (_usedAnswers.length >= _answerPool.length) {
      _usedAnswers.clear();
    }

    final available = _answerPool
        .where((w) => !_usedAnswers.contains(w))
        .toList();
    final chosen = available[Random().nextInt(available.length)];
    _usedAnswers.add(chosen);
    return chosen;
  }

  @override
  void dispose() {
    for (final controller in _flipControllers) {
      controller.dispose();
    }
    _keyboardFocusNode.dispose();
    super.dispose();
  }

  void _resetGame() {
    if (_answerPool.isEmpty) return;
    final newWord = _pickNextAnswer();
    setState(() {
      _game?.newGame(newWord);
      currentIndex = 0;
      for (var controller in _flipControllers) {
        controller.reset();
      }
    });
  }

  void _onLetterTap(String letter) {
    if (_game == null || _flipControllers.isEmpty) return;
    if (_flipControllers.any((c) => c.isAnimating)) return;
    if (_game!.isGameWon || _game!.isGameLost) return;
    if (currentIndex < (_game!.currentAttempt + 1) * _game!.lettersPerWord) {
      setState(() {
        _game!.board[currentIndex] = letter.toLowerCase();
        currentIndex++;
      });
    }
  }

  void _onDeleteTap() {
    if (_game == null || _flipControllers.isEmpty) return;
    if (_flipControllers.any((c) => c.isAnimating)) return;
    if (_game!.isGameWon || _game!.isGameLost) return;
    final startOfCurrentRow = _game!.currentAttempt * _game!.lettersPerWord;
    if (currentIndex > startOfCurrentRow) {
      setState(() {
        currentIndex--;
        _game!.board[currentIndex] = '';
      });
    }
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return;

    final key = event.logicalKey;

    if (key == LogicalKeyboardKey.backspace) {
      _onDeleteTap();
      return;
    }

    if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter) {
      _onSendTap();
      return;
    }

    final label = key.keyLabel;
    if (label.length == 1 && RegExp(r'^[a-zA-Z]$').hasMatch(label)) {
      _onLetterTap(label.toLowerCase());
    }
  }

  void _onSendTap() async {
    if (_game == null || _flipControllers.isEmpty) {
      if (_game == null) {
        await _initializeGame();
      }
      return;
    }

    if (_game!.isGameWon || _game!.isGameLost) {
      _resetGame();
      return;
    }

    final startOfCurrentRow = _game!.currentAttempt * _game!.lettersPerWord;
    final endOfCurrentRow = startOfCurrentRow + _game!.lettersPerWord;

    if (currentIndex == endOfCurrentRow) {
      final guess = _game!.board
          .sublist(startOfCurrentRow, endOfCurrentRow)
          .join()
          .toLowerCase();

      if (!_allowedWordSet.contains(guess)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Word not in list'),
            duration: Duration(seconds: 1),
          ),
        );
        return;
      }

      _game!.submitGuess();

      for (int i = 0; i < _game!.lettersPerWord; i++) {
        final index = startOfCurrentRow + i;
        await Future.delayed(const Duration(milliseconds: 150));
        _flipControllers[index].forward();
      }

      setState(() {});

      if (_game!.isGameWon || _game!.isGameLost) _showEndGameDialog();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Not enough letters'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wordle'),
        centerTitle: true,
        elevation: 2,
        actions: [
          PopupMenuButton<GameLanguage>(
            tooltip: 'Change language',
            initialValue: _language,
            onSelected: _isLoading ? null : _switchLanguage,
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: GameLanguage.english,
                child: Text('English'),
              ),
              PopupMenuItem(
                value: GameLanguage.indonesian,
                child: Text('Indonesian'),
              ),
            ],
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Center(
                child: Text(
                  _language == GameLanguage.english ? 'EN' : 'ID',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              themeNotifier.value == ThemeMode.dark
                  ? Icons.light_mode
                  : Icons.dark_mode,
            ),
            onPressed: () {
              setState(() {
                themeNotifier.value = themeNotifier.value == ThemeMode.dark
                    ? ThemeMode.light
                    : ThemeMode.dark;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _initializeGame,
          ),
        ],
      ),
      body: KeyboardListener(
        focusNode: _keyboardFocusNode,
        autofocus: true,
        onKeyEvent: _handleKeyEvent,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              children: [
                const SizedBox(height: 20),
                if (_isLoading)
                  const Expanded(
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_game == null)
                  const Expanded(
                    child: Center(child: Text('Could not start game.')),
                  )
                else
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: GridView.builder(
                        itemCount: _game!.board.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: _game!.lettersPerWord,
                          mainAxisSpacing: 8.0,
                          crossAxisSpacing: 8.0,
                        ),
                        itemBuilder: (context, index) {
                          final letter = _game!.board[index];
                          final status = _game!.boardStatus[index];

                          return AnimatedBuilder(
                            animation: _flipAnimations[index],
                            builder: (context, child) {
                              final angle =
                                  _flipAnimations[index].value * 3.14159;
                              final isFlipped = angle > 3.14159 / 2;
                              final frontChild = Container(
                                decoration: BoxDecoration(
                                  color: Colors.transparent,
                                  border: Border.all(
                                    color: letter.isNotEmpty
                                        ? Colors.grey.shade700
                                        : Colors.grey.shade400,
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                child: Center(
                                  child: Text(
                                    letter,
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color:
                                          Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? Colors.white
                                          : Colors.black,
                                    ),
                                  ),
                                ),
                              );
                              final backChild = Container(
                                decoration: BoxDecoration(
                                  color: _getTileColor(status),
                                  border: Border.all(
                                    color:
                                        _getTileColor(status) !=
                                            Colors.transparent
                                        ? Colors.transparent
                                        : letter.isNotEmpty
                                        ? Colors.grey.shade700
                                        : Colors.grey.shade400,
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                child: Center(
                                  child: Transform(
                                    alignment: Alignment.center,
                                    transform: Matrix4.rotationX(3.14159),
                                    child: Text(
                                      letter,
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              );

                              return Transform(
                                alignment: Alignment.center,
                                transform: Matrix4.identity()
                                  ..setEntry(3, 2, 0.001)
                                  ..rotateX(angle),
                                child: isFlipped ? backChild : frontChild,
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ),

                // --------------------------------------------------
                Container(
                  padding: const EdgeInsets.all(10.0),
                  child: _buildKeyboard(),
                ),

                const SizedBox(height: 10),

                // ----------------------------------------------
                ElevatedButton(
                  onPressed: _onSendTap,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(150, 45),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Text(
                    _game == null || _game!.isGameWon || _game!.isGameLost
                        ? 'New Game'
                        : 'Send',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),

                // ----------------------------------------
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getTileColor(LetterStatus status) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    switch (status) {
      case LetterStatus.correct:
        return Colors.green.shade400;
      case LetterStatus.inWord:
        return Colors.yellow.shade600;
      case LetterStatus.notInWord:
        return isDarkMode ? Colors.grey.shade700 : Colors.grey.shade400;
      case LetterStatus.initial:
        return Colors.transparent;
    }
  }

  Widget _buildKeyboard() {
    const row1 = ['q', 'w', 'e', 'r', 't', 'y', 'u', 'i', 'o', 'p'];
    const row2 = ['a', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l'];
    const row3 = ['z', 'x', 'c', 'v', 'b', 'n', 'm'];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(children: row1.map((l) => _buildFlexibleKey(l, 10)).toList()),
        const SizedBox(height: 8.0),

        Row(
          children: [
            const Spacer(flex: 5),
            ...row2.map((l) => _buildFlexibleKey(l, 10)),
            const Spacer(flex: 5),
          ],
        ),
        const SizedBox(height: 8.0),

        Row(
          children: [
            const Spacer(flex: 15),
            ...row3.map((l) => _buildFlexibleKey(l, 10)),
            _buildFlexibleBackspace(15),
          ],
        ),
      ],
    );
  }

  Widget _buildFlexibleKey(String letter, int flex) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2.0),
        child: _buildKey(letter),
      ),
    );
  }

  Widget _buildFlexibleBackspace(int flex) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2.0),
        child: _buildBackspaceKey(),
      ),
    );
  }

  Widget _buildKey(String letter) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final status = _game?.keyboardStatus[letter] ?? LetterStatus.initial;
    final tileColor = _getTileColor(status);
    final isDefault = tileColor == Colors.transparent;
    final keyColor = isDefault
        ? (isDarkMode ? Colors.grey.shade800 : Colors.grey.shade300)
        : tileColor;
    final textColor = isDefault
        ? (isDarkMode ? Colors.white : Colors.black)
        : Colors.white;

    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: () => _onLetterTap(letter),
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.zero,
          backgroundColor: keyColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6.0),
          ),
        ),
        child: Text(
          letter,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: textColor,
          ),
        ),
      ),
    );
  }

  Widget _buildBackspaceKey() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      height: 44,
      child: ElevatedButton(
        onPressed: _onDeleteTap,
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.zero,
          backgroundColor: isDarkMode
              ? Colors.grey.shade800
              : Colors.grey.shade300,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6.0),
          ),
        ),
        child: Icon(
          Icons.backspace_outlined,
          size: 20,
          color: isDarkMode ? Colors.white : Colors.black,
        ),
      ),
    );
  }

  void _showEndGameDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(_game?.isGameWon ?? false ? 'You Won!' : 'Game Over'),
          content: Text(
            'The word was: ${_game?.targetWord}\n\nWould you like to play again?',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('New Game'),
              onPressed: () {
                Navigator.of(context).pop();
                _resetGame();
              },
            ),
          ],
        );
      },
    );
  }
}
