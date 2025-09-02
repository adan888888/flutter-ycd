import '../utils/types_of.dart';

class ConfigModel {
  int tenantId = 0; // Default value set to 0
  String tenantCode = ''; // Default value set to empty string
  bool tenantSiteStatus = false; // Default value set to 0
  SwitchConfig switchConfig = SwitchConfig();

  String timeZone = ''; // Default value set to empty string
  String currencyMain = ''; // Default value set to empty string
  String domainMain = ''; // Default value set to empty string
  String skinTemplate = ''; // Default value set to empty string
  String langMain = ''; // Default value set to empty string
  String compliance = ''; // Default value set to empty string
  Domains domains = Domains();
  String currencySymbol = '';
  ConfigModel();

  factory ConfigModel.fromJson(Map<String, dynamic> json) {
    return ConfigModel()
      ..tenantId = bxGetInt(json['tenantId'])
      ..tenantCode = bxGetString(json['tenantCode'])
      ..tenantSiteStatus = bxGetBool(json['tenantSiteStatus'])
      ..switchConfig = SwitchConfig.fromJson(json['switch'] ?? {})
      ..domains = Domains.fromJson(json['domains'] ?? {})
      ..timeZone = bxGetString(json['timeZone'])
      ..currencySymbol = bxGetString(json['currencySymbol'])
      ..currencyMain = bxGetString(json['currencyMain'])
      ..domainMain = bxGetString(json['domainMain'])
      ..skinTemplate = bxGetString(json['skinTemplate'])
      ..langMain = bxGetString(json['langMain'])
      ..compliance = bxGetString(json['compliance']);
  }

  Map<String, dynamic> toJson() {
    return {
      'domains': domains.toJson(),
      'tenantId': tenantId,
      'tenantCode': tenantCode,
      'currencySymbol': currencySymbol,
      'tenantSiteStatus': tenantSiteStatus,
      'switch': switchConfig.toJson(),
      'timeZone': timeZone,
      'currencyMain': currencyMain,
      'domainMain': domainMain,
      'skinTemplate': skinTemplate,
      'langMain': langMain,
      'compliance': compliance,
    };
  }
}

class SwitchConfig {
  bool isVipSystem = false; // Default value set to false
  bool isPaymentMerchantIntegration = false; // Default value set to false
  bool isPayoutMerchantIntegration = false; // Default value set to false
  bool isThirdPartyGameApi = false; // Default value set to false
  bool isLottery = false; // Default value set to false
  bool isOutsourcedCustomerService = false; // Default value set to false
  bool isRegisterMobileVerification = false; // Default value set to false
  bool isRegisterEmailVerification = false; // Default value set to false
  bool isSubTable = false; // Default value set to false

  SwitchConfig();

  factory SwitchConfig.fromJson(Map<String, dynamic> json) {
    return SwitchConfig()
      ..isVipSystem = bxGetBool(json['isVipSystem'])
      ..isPaymentMerchantIntegration = bxGetBool(json['isPaymentMerchantIntegration'])
      ..isPayoutMerchantIntegration = bxGetBool(json['isPayoutMerchantIntegration'])
      ..isThirdPartyGameApi = bxGetBool(json['isThirdPartyGameApi'])
      ..isLottery = bxGetBool(json['isLottery'])
      ..isOutsourcedCustomerService = bxGetBool(json['isOutsourcedCustomerService'])
      ..isRegisterMobileVerification = bxGetBool(json['isRegisterMobileVerification'])
      ..isRegisterEmailVerification = bxGetBool(json['isRegisterEmailVerification'])
      ..isSubTable = bxGetBool(json['isSubTable']);
  }

  Map<String, dynamic> toJson() {
    return {
      'isVipSystem': isVipSystem,
      'isPaymentMerchantIntegration': isPaymentMerchantIntegration,
      'isPayoutMerchantIntegration': isPayoutMerchantIntegration,
      'isThirdPartyGameApi': isThirdPartyGameApi,
      'isLottery': isLottery,
      'isOutsourcedCustomerService': isOutsourcedCustomerService,
      'isRegisterMobileVerification': isRegisterMobileVerification,
      'isRegisterEmailVerification': isRegisterEmailVerification,
      'isSubTable': isSubTable,
    };
  }
}

class Domains {
  String activity = ""; // Default value set to false

  Domains();

  factory Domains.fromJson(Map<String, dynamic> json) {
    return Domains()..activity = "https://${bxGetString(json['activity'])}";
  }

  Map<String, dynamic> toJson() {
    return {
      'activity': activity,
    };
  }
}
