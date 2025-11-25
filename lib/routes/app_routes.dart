import 'package:get/get_navigation/src/routes/get_route.dart';
import 'package:ycd/utils/app_middleware.dart';
import 'package:ycd/views/baccarat_simulation/baccarat_simulation_binding.dart';
import 'package:ycd/views/baccarat_simulation/baccarat_simulation_view.dart';
import 'package:ycd/views/buy_records/buy_records_binding.dart';
import 'package:ycd/views/buy_records/buy_records_view.dart';
import 'package:ycd/views/currency_converter/currency_converter_binding.dart';
import 'package:ycd/views/currency_converter/currency_converter_view.dart';
import 'package:ycd/views/digital_password_book/digital_password_book_binding.dart';
import 'package:ycd/views/digital_password_book/digital_password_book_view.dart';
import 'package:ycd/views/game/game_binding.dart';
import 'package:ycd/views/game/game_view.dart';
import 'package:ycd/views/home_view.dart';
import 'package:ycd/views/investment_calculator/investment_calculator_binding.dart';
import 'package:ycd/views/investment_calculator/investment_calculator_view.dart';
import 'package:ycd/views/login/login_viw_widget/login_binding.dart';
import 'package:ycd/views/login/login_viw_widget/login_view.dart';
import 'package:ycd/views/rsi_analysis/rsi_analysis_binding.dart';
import "package:ycd/views/rsi_analysis/rsi_analysis_view.dart";
import 'package:ycd/views/rsi_strategy_backtest/rsi_strategy_backtest_binding.dart';
import 'package:ycd/views/rsi_strategy_backtest/rsi_strategy_backtest_view.dart';
import 'package:ycd/views/aes_encrypt/aes_encrypt_binding.dart';
import 'package:ycd/views/aes_encrypt/aes_encrypt_view.dart';

/// 应用路由配置
class AppRoutes {
  // 主页面
  static const String home = '/home';

  // 认证相关
  static const String login = '/login';

  // 游戏相关
  static const String gameHome = '/gameHome';

  // 投资工具
  static const String investmentCalculator = '/investment-calculator';
  static const String rsiAnalysis = '/rsi-analysis';
  static const String rsiStrategyBacktest = '/rsi-strategy-backtest';
  static const String buyRecords = '/buy-records';
  static const String currencyConverter = '/currency-converter';
  static const String digitalPasswordBook = '/digital-password-book';
  static const String aesEncrypt = '/aes-encrypt';

  // 游戏相关
  static const String baccaratSimulation = '/baccarat-simulation';
}

/// 应用页面配置
class AppPages {
  static final pages = [
    // 主页面
    GetPage(
      name: AppRoutes.home,
      page: () => const HomeView(),
    ),

    // 认证页面
    GetPage(
      name: AppRoutes.login,
      page: () => const LoginWidget(),
      binding: LoginBinding(),
      middlewares: [
        AppMiddleware(),
      ],
    ),

    // 游戏页面
    GetPage(
      name: AppRoutes.gameHome,
      page: () => const GameView(title: 'v2.0'),
      binding: GameBinding(),
    ),

    // 投资工具页面
    GetPage(
      name: AppRoutes.investmentCalculator,
      page: () => const InvestmentCalculatorView(),
      binding: InvestmentCalculatorBinding(),
    ),
    GetPage(
      name: AppRoutes.rsiAnalysis,
      page: () => const RSIAnalysisView(),
      binding: RSIAnalysisBinding(),
    ),
    GetPage(
      name: AppRoutes.rsiStrategyBacktest,
      page: () => const RSIStrategyBacktestView(),
      binding: RSIStrategyBacktestBinding(),
    ),
    GetPage(
      name: AppRoutes.buyRecords,
      page: () => const BuyRecordsView(),
      binding: BuyRecordsBinding(),
    ),
    GetPage(
      name: AppRoutes.currencyConverter,
      page: () => const CurrencyConverterView(),
      binding: CurrencyConverterBinding(),
    ),
    GetPage(
      name: AppRoutes.digitalPasswordBook,
      page: () => const DigitalPasswordBookView(),
      binding: DigitalPasswordBookBinding(),
    ),
    GetPage(
      name: AppRoutes.aesEncrypt,
      page: () => const AesEncryptView(),
      binding: AesEncryptBinding(),
    ),

    // 百家乐开奖模拟页面
    GetPage(
      name: AppRoutes.baccaratSimulation,
      page: () => const BaccaratSimulationView(),
      binding: BaccaratSimulationBinding(),
    ),
  ];
}
