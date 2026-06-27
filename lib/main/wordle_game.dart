enum LetterStatus { initial, notInWord, inWord, correct }

class WordleGame {
  final int maxAttempts;
  final int lettersPerWord;
  int _currentAttempt = 0;
  String _targetWord = '';
  final List<String> _board;
  final List<LetterStatus> _boardStatus;
  final Map<String, LetterStatus> _keyboardStatus = {};

  WordleGame({
    required String targetWord,
    this.maxAttempts = 6,
    this.lettersPerWord = 5,
  }) : _targetWord = targetWord.toLowerCase(),
       _board = List.filled(maxAttempts * lettersPerWord, ''),
       _boardStatus = List.filled(
         maxAttempts * lettersPerWord,
         LetterStatus.initial,
       );

  void newGame(String newWord) {
    _currentAttempt = 0;
    _board.fillRange(0, _board.length, '');
    _boardStatus.fillRange(0, _boardStatus.length, LetterStatus.initial);
    _keyboardStatus.clear();
    _targetWord = newWord.toLowerCase();
  }

  String get targetWord => _targetWord;
  List<String> get board => _board;
  List<LetterStatus> get boardStatus => _boardStatus;
  Map<String, LetterStatus> get keyboardStatus => _keyboardStatus;
  int get currentAttempt => _currentAttempt;

  void submitGuess() {
    if (_currentAttempt >= maxAttempts) return;

    final guessStartIndex = _currentAttempt * lettersPerWord;
    final guessEndIndex = guessStartIndex + lettersPerWord;
    final guess = _board.sublist(guessStartIndex, guessEndIndex).join();

    if (guess.length != lettersPerWord) return;

    final targetLetters = _targetWord.split('');
    final guessLetters = guess.split('');

    for (int i = 0; i < lettersPerWord; i++) {
      final index = guessStartIndex + i;
      if (guessLetters[i] == targetLetters[i]) {
        _boardStatus[index] = LetterStatus.correct;
        _updateKeyboardStatus(guessLetters[i], LetterStatus.correct);
        targetLetters[i] = ''; // Mark as used
      }
    }

    for (int i = 0; i < lettersPerWord; i++) {
      final index = guessStartIndex + i;
      if (_boardStatus[index] == LetterStatus.initial) {
        if (targetLetters.contains(guessLetters[i])) {
          _boardStatus[index] = LetterStatus.inWord;
          _updateKeyboardStatus(guessLetters[i], LetterStatus.inWord);
          targetLetters[targetLetters.indexOf(guessLetters[i])] = '';
        } else {
          _boardStatus[index] = LetterStatus.notInWord;
          _updateKeyboardStatus(guessLetters[i], LetterStatus.notInWord);
        }
      }
    }

    _currentAttempt++;
  }

  void _updateKeyboardStatus(String letter, LetterStatus status) {
    final currentStatus = _keyboardStatus[letter];
    if (currentStatus == null ||
        status == LetterStatus.correct ||
        (currentStatus != LetterStatus.correct &&
            status == LetterStatus.inWord)) {
      _keyboardStatus[letter] = status;
    } else if (currentStatus == LetterStatus.initial) {
      _keyboardStatus[letter] = status;
    }
  }

  bool get isGameWon {
    if (_currentAttempt == 0) return false;
    final guessStartIndex = (_currentAttempt - 1) * lettersPerWord;
    final guessEndIndex = guessStartIndex + lettersPerWord;
    final lastGuess = _board.sublist(guessStartIndex, guessEndIndex).join();
    return lastGuess == _targetWord;
  }

  bool get isGameLost => !isGameWon && _currentAttempt == maxAttempts;
}
