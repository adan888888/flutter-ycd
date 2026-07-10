import 'package:get/get.dart';

class DigitalPasswordBookState {
  // 密码本数据
  var passwordList = <PasswordItem>[].obs;
  var isLoading = false.obs;
  var randomSequence = <int>[
    18,
    5,
    22,
    9,
    1,
    14,
    25,
    7,
    11,
    2,
    20,
    15,
    3,
    19,
    24,
    10,
    6,
    23,
    12,
    4,
    17,
    8,
    21,
    13,
    16,
    26,
  ];

  // 搜索关键词
  var searchKeyword = ''.obs;

  // 匹配方向：false = 从前面往后匹配，true = 从后面往前面匹配
  var isReverseMatch = false.obs;

  // 搜索转换结果
  var searchPd = ''.obs;

  // 是否显示添加密码对话框
  var showAddDialog = false.obs;

  // 新增密码表单数据
  var newTitle = ''.obs;
  var newUsername = ''.obs;
  var newPassword = ''.obs;
  var newWebsite = ''.obs;
  var newNotes = ''.obs;

  // 是否显示密码
  var showPassword = <int, bool>{}.obs;

  // 选中的密码项
  var selectedItem = Rxn<PasswordItem>();

  // 当前选中的密码项（用于键盘操作）
  var currentSelectedItem = Rxn<PasswordItem>();

  // 是否显示编辑对话框
  var showEditDialog = false.obs;

  // 编辑密码表单数据
  var editTitle = ''.obs;
  var editUsername = ''.obs;
  var editPassword = ''.obs;
  var editWebsite = ''.obs;
  var editNotes = ''.obs;
}

// 密码项数据模型
class PasswordItem {
  final int id;
  final String title;
  final String username;
  final String password;
  final String website;
  final String notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  PasswordItem({
    required this.id,
    required this.title,
    required this.username,
    required this.password,
    required this.website,
    required this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'username': username,
      'password': password,
      'website': website,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory PasswordItem.fromJson(Map<String, dynamic> json) {
    return PasswordItem(
      id: json['id'],
      title: json['title'],
      username: json['username'],
      password: json['password'],
      website: json['website'] ?? '',
      notes: json['notes'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  PasswordItem copyWith({
    int? id,
    String? title,
    String? username,
    String? password,
    String? website,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PasswordItem(
      id: id ?? this.id,
      title: title ?? this.title,
      username: username ?? this.username,
      password: password ?? this.password,
      website: website ?? this.website,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
