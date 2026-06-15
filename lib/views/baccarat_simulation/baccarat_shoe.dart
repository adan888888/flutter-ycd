import 'dart:math';

/// 8 副牌百家乐牌靴（416 张，无放回发牌，切牌后换靴）
class BaccaratShoe {
  BaccaratShoe([Random? random]) : _random = random ?? Random();

  static const int deckCount = 8;
  static const int cardsPerDeck = 52;
  static const int totalCards = deckCount * cardsPerDeck;

  /// 切牌剩余张数随机范围（含两端）
  static const int cutCardMinRemaining = 12;
  static const int cutCardMaxRemaining = 20;

  /// 单局最多发 6 张，低于此值必须换靴
  static const int minCardsPerHand = 6;

  static const _suits = ['♠', '♥', '♦', '♣'];
  static const _ranks = ['A', '2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K'];

  final Random _random;
  final List<Map<String, dynamic>> _cards = [];
  int _drawIndex = 0;

  /// 本靴切牌位：剩余张数 ≤ 该值时换靴（洗牌后由用户点击随机）
  int _cutCardRemaining = cutCardMaxRemaining;

  int get remaining => _cards.length - _drawIndex;

  int get cutCardRemaining => _cutCardRemaining;

  bool get hasActiveShoe => _cards.isNotEmpty && remaining > 0;

  bool get needsReshuffle =>
      !hasActiveShoe || remaining < minCardsPerHand || remaining <= _cutCardRemaining;

  /// 随机本靴切牌位（12～20 张）
  void randomizeCutCard() {
    _cutCardRemaining = cutCardMinRemaining +
        _random.nextInt(cutCardMaxRemaining - cutCardMinRemaining + 1);
  }

  /// 新靴：8 副共 416 张洗牌（切牌在洗牌之后进行）
  void shuffle() {
    _cards.clear();
    _drawIndex = 0;
    for (var deck = 0; deck < deckCount; deck++) {
      for (final suit in _suits) {
        for (final rank in _ranks) {
          _cards.add(_makeCard(suit, rank));
        }
      }
    }
    _cards.shuffle(_random);
  }

  /// 每局开始前是否需换靴（仅判断，不洗牌）
  bool needsReshuffleBeforeHand() => needsReshuffle;

  /// 从牌靴顶发一张牌（无放回）；牌靴用尽时需先换新靴
  Map<String, dynamic> draw() {
    if (remaining <= 0) {
      throw StateError('牌靴已空');
    }
    return _cards[_drawIndex++];
  }

  static Map<String, dynamic> _makeCard(String suit, String rank) {
    final int value;
    if (rank == 'A') {
      value = 1;
    } else if (rank == '10' || rank == 'J' || rank == 'Q' || rank == 'K') {
      value = 0;
    } else {
      value = int.parse(rank);
    }

    return {
      'suit': suit,
      'rank': rank,
      'value': value,
      'display': '$rank$suit',
    };
  }
}
