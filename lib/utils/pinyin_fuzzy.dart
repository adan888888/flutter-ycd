/// 更多功能搜索用的拼音模糊匹配：全拼、首字母、混拼，以及 z/zh、c/ch、s/sh、
/// n/l、an/ang、en/eng、in/ing 这几组模糊音。
bool pinyinFuzzyContains(String text, String query) {
  final raw = query.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '');
  if (raw.isEmpty) return true;
  if (text.toLowerCase().contains(raw)) return true;

  final syllables = <String>[];
  for (final rune in text.runes) {
    final pinyin = _pinyin[String.fromCharCode(rune)];
    if (pinyin != null) syllables.add(pinyin);
  }
  if (syllables.isEmpty) return false;

  final foldedQuery = _foldFuzzy(raw);
  final folded = syllables.map(_foldFuzzy).toList();
  if (folded.join().contains(foldedQuery)) return true;

  final initials = folded.map((syllable) => syllable[0]).join();
  if (initials.contains(foldedQuery)) return true;

  for (var start = 0; start < folded.length; start++) {
    if (_consume(folded, start, foldedQuery, 0)) return true;
  }
  return false;
}

/// 测试用：返回 [text] 里还没有拼音的汉字。
Iterable<String> missingPinyinCharacters(String text) sync* {
  final seen = <String>{};
  for (final rune in text.runes) {
    final char = String.fromCharCode(rune);
    if (_han.hasMatch(char) && !_pinyin.containsKey(char) && seen.add(char)) {
      yield char;
    }
  }
}

bool _consume(List<String> syllables, int index, String query, int offset) {
  if (offset == query.length) return true;
  if (index == syllables.length) return false;
  final syllable = syllables[index];
  final maxLength = syllable.length < query.length - offset
      ? syllable.length
      : query.length - offset;
  for (var length = maxLength; length >= 1; length--) {
    if (syllable.startsWith(query.substring(offset, offset + length)) &&
        _consume(syllables, index + 1, query, offset + length)) {
      return true;
    }
  }
  return false;
}

String _foldFuzzy(String input) {
  return input
      .replaceAll('zh', 'z')
      .replaceAll('ch', 'c')
      .replaceAll('sh', 's')
      .replaceAll('ang', 'an')
      .replaceAll('eng', 'en')
      .replaceAll('ing', 'in')
      .replaceAll('l', 'n');
}

final _han = RegExp(r'[\u4e00-\u9fff]');

const _pinyin = <String, String>{
  '按': 'an',
  '暗': 'an',
  '本': 'ben',
  '闭': 'bi',
  '并': 'bing',
  '不': 'bu',
  '步': 'bu',
  '部': 'bu',
  '藏': 'cang',
  '撤': 'che',
  '程': 'cheng',
  '重': 'chong',
  '出': 'chu',
  '除': 'chu',
  '次': 'ci',
  '从': 'cong',
  '当': 'dang',
  '的': 'de',
  '登': 'deng',
  '动': 'dong',
  '额': 'e',
  '返': 'fan',
  '放': 'fang',
  '分': 'fen',
  '复': 'fu',
  '改': 'gai',
  '给': 'gei',
  '功': 'gong',
  '关': 'guan',
  '规': 'gui',
  '含': 'han',
  '号': 'hao',
  '和': 'he',
  '红': 'hong',
  '后': 'hou',
  '换': 'huan',
  '回': 'hui',
  '恢': 'hui',
  '或': 'huo',
  '机': 'ji',
  '即': 'ji',
  '记': 'ji',
  '减': 'jian',
  '将': 'jiang',
  '金': 'jin',
  '仅': 'jin',
  '据': 'ju',
  '开': 'kai',
  '可': 'ke',
  '快': 'kuai',
  '框': 'kuang',
  '列': 'lie',
  '亮': 'liang',
  '流': 'liu',
  '录': 'lu',
  '率': 'lv',
  '绿': 'lv',
  '能': 'neng',
  '排': 'pai',
  '赔': 'pei',
  '朋': 'peng',
  '期': 'qi',
  '启': 'qi',
  '其': 'qi',
  '前': 'qian',
  '切': 'qie',
  '清': 'qing',
  '全': 'quan',
  '入': 'ru',
  '色': 'se',
  '删': 'shan',
  '上': 'shang',
  '设': 'she',
  '示': 'shi',
  '使': 'shi',
  '手': 'shou',
  '数': 'shu',
  '输': 'shu',
  '水': 'shui',
  '所': 'suo',
  '随': 'sui',
  '条': 'tiao',
  '题': 'ti',
  '投': 'tou',
  '退': 'tui',
  '望': 'wang',
  '为': 'wei',
  '位': 'wei',
  '享': 'xiang',
  '消': 'xiao',
  '销': 'xiao',
  '显': 'xian',
  '下': 'xia',
  '新': 'xin',
  '修': 'xiu',
  '序': 'xu',
  '页': 'ye',
  '一': 'yi',
  '义': 'yi',
  '隐': 'yin',
  '赢': 'ying',
  '用': 'yong',
  '友': 'you',
  '有': 'you',
  '余': 'yu',
  '与': 'yu',
  '则': 'ze',
  '账': 'zhang',
  '照': 'zhao',
  '值': 'zhi',
  '置': 'zhi',
  '中': 'zhong',
  '注': 'zhu',
  '主': 'zhu',
  '自': 'zi',
  '最': 'zui',
};
