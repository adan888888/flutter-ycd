import 'package:get/get_navigation/src/routes/get_route.dart';
import 'package:ycd/pages/baccarat_simulation/index.dart';
import 'package:ycd/pages/buy_records/index.dart';
import 'package:ycd/pages/currency_converter/index.dart';
import 'package:ycd/pages/digital_password_book/index.dart';
import 'package:ycd/pages/game_home/game_home_binding.dart';
import 'package:ycd/pages/game_home/game_home_view.dart';
import 'package:ycd/pages/home_page.dart';
import 'package:ycd/pages/investment_calculator/index.dart';
import 'package:ycd/pages/login/login_viw_widget/login_binding.dart';
import 'package:ycd/pages/login/login_viw_widget/login_view.dart';
import 'package:ycd/pages/rsi_analysis/index.dart';
import 'package:ycd/pages/rsi_strategy_backtest/index.dart';
import 'package:ycd/utils/app_middleware.dart';

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

  // 游戏相关
  static const String baccaratSimulation = '/baccarat-simulation';
}

/// 应用页面配置
class AppPages {
  static final pages = [
    // 主页面
    GetPage(
      name: AppRoutes.home,
      page: () => const HomePage(),
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
      page: () => const GameHomePage(title: 'v2.0'),
      binding: GameHomeBinding(),
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

    // 百家乐开奖模拟页面
    GetPage(
      name: AppRoutes.baccaratSimulation,
      page: () => const BaccaratSimulationView(),
      binding: BaccaratSimulationBinding(),
    ),
  ];
}
