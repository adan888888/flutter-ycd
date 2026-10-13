import 'package:flutter_test/flutter_test.dart';
import 'package:ycd/utils/pinyin_fuzzy.dart';

void main() {
  test('matches full pinyin, initials, mixed spelling, and fuzzy pairs', () {
    expect(pinyinFuzzyContains('显示序号', 'x'), isTrue);
    expect(pinyinFuzzyContains('显示序号', 'xs'), isTrue);
    expect(pinyinFuzzyContains('显示序号', 'xsxh'), isTrue);
    expect(pinyinFuzzyContains('显示序号', 'xianshi'), isTrue);
    expect(pinyinFuzzyContains('显示序号', 'xshi'), isTrue);
    expect(pinyinFuzzyContains('返回上步', 'fh'), isTrue);
    expect(pinyinFuzzyContains('返回上步', 'fanhui'), isTrue);
    expect(pinyinFuzzyContains('关闭自动主题', 'zhuti'), isTrue);
    expect(pinyinFuzzyContains('关闭自动主题', 'zt'), isTrue);
    expect(pinyinFuzzyContains('账号', 'zhanghao'), isTrue);
    expect(pinyinFuzzyContains('排列数据', 'pl'), isTrue);
    expect(pinyinFuzzyContains('消除数据', 'xiao'), isTrue);
    expect(pinyinFuzzyContains('绿赢', 'lv'), isTrue);
    expect(pinyinFuzzyContains('排列数据', 'xiao'), isFalse);
    expect(pinyinFuzzyContains('显示序号', '显示'), isTrue);
  });

  test('every menu character has a pinyin', () {
    const corpus = '''
排列数据 消除数据 修改本金 修改位置 删除所有数据 重置流水 分享给朋友 返回上步
修改期望值 修改赔率 退出程序 隐藏序号 显示序号 红输绿赢 红赢绿输
关闭自动主题 开启自动主题 隐藏消数列 显示消数列 隐藏快照列 显示快照列
按当前规则重新排列投注数据 清除消数列中的全部数据 使用输入框中的金额修改本金
将下注次数设为随机次数减 删除当前账号的全部数据，不可恢复
从最后一条投注记录重置流水 分享给朋友，功能即将开放 撤销最后一条投注记录
使用输入框中的数值修改期望值 使用输入框中的数值修改赔率
退出当前账号并返回登录页 显示或隐藏投注记录序号 切换红色与绿色的输赢含义
亮色，其余暗色；关闭后仅手动切换主题 显示或隐藏投注记录的消数列 显示或隐藏投注记录的重启快照列
''';
    expect(missingPinyinCharacters(corpus), isEmpty);
  });
}
