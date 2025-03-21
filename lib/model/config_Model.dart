import 'dart:convert';

import '../utils/types _of.dart';


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
      ..tenantId = BXGetInt(json['tenantId'])
      ..tenantCode = BXGetString(json['tenantCode'])
      ..tenantSiteStatus = BXGetBool(json['tenantSiteStatus'])
      ..switchConfig = SwitchConfig.fromJson(json['switch'] ?? {})
      ..domains = Domains.fromJson(json['domains'] ?? {})
      ..timeZone = BXGetString(json['timeZone'])
      ..currencySymbol = BXGetString(json['currencySymbol'])
      ..currencyMain = BXGetString(json['currencyMain'])
      ..domainMain = BXGetString(json['domainMain'])
      ..skinTemplate = BXGetString(json['skinTemplate'])
      ..langMain = BXGetString(json['langMain'])
      ..compliance = BXGetString(json['compliance']);

  }

  Map<String, dynamic> toJson() {
    return {
      'domains':domains.toJson(),
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
      ..isVipSystem = BXGetBool(json['isVipSystem'])
      ..isPaymentMerchantIntegration = BXGetBool(json['isPaymentMerchantIntegration'])
      ..isPayoutMerchantIntegration = BXGetBool(json['isPayoutMerchantIntegration'])
      ..isThirdPartyGameApi = BXGetBool(json['isThirdPartyGameApi'])
      ..isLottery = BXGetBool(json['isLottery'])
      ..isOutsourcedCustomerService = BXGetBool(json['isOutsourcedCustomerService'])
      ..isRegisterMobileVerification = BXGetBool(json['isRegisterMobileVerification'])
      ..isRegisterEmailVerification = BXGetBool(json['isRegisterEmailVerification'])
      ..isSubTable = BXGetBool(json['isSubTable']);
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
    return Domains()
      ..activity = "https://${BXGetString(json['activity'])}";
  }

  Map<String, dynamic> toJson() {
    return {
      'activity': activity,
    };
  }
}
