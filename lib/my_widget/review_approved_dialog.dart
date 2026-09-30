import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Figma A15 提示弹窗，可用于成功、权限和登录提示。
///
/// 调用示例：
/// `showDialog<void>(context: context, builder: (_) => const ReviewApprovedDialog());`
class ReviewApprovedDialog extends StatelessWidget {
  const ReviewApprovedDialog({
    super.key,
    this.title = '审核已通过',
    this.message = '恭喜您，账户审核已通过\n现在可以正常使用数策的所有功能',
    this.badgeText = '安全保障中，请放心使用',
    this.buttonText = '我知道了',
    this.secondaryButtonText,
    this.statusIcon,
    this.useFailureArtwork = false,
    this.useRestartArtwork = false,
    this.isDarkMode = false,
    this.onSecondary,
    this.onConfirmed,
  });

  final String title;
  final String message;
  final String badgeText;
  final String buttonText;
  final String? secondaryButtonText;
  final IconData? statusIcon;
  final bool useFailureArtwork;
  final bool useRestartArtwork;
  final bool isDarkMode;
  final VoidCallback? onSecondary;
  final VoidCallback? onConfirmed;

  static const _assetRoot = 'assets/images/figma_review_dialog';
  static const _primaryText = Color(0xFF0B072B);
  static const _brandBlue = Color(0xFF6E9CFF);
  static const _paleBlue = Color(0xFFF3F8FF);
  static const _border = Color(0xFFE9EBF4);

  /// Figma 390 宽画板上的弹窗宽度 310（约 79.5% 屏宽）。
  static const _designScreenWidth = 390.0;
  static const _designDialogWidth = 310.0;

  /// 暗色配色与 [ReviewInputDialog] 保持一致
  static const _darkSurface = Color(0xFF16212F);
  static const _darkPrimaryText = Color(0xFFF5F7FA);
  static const _darkBadgeFill = Color(0xFF1C2939);
  static const _darkAccent = Color(0xFF8AAEFF);
  static const _darkActionText = Color(0xFFB8A8F2);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final dialogWidth = screenWidth * _designDialogWidth / _designScreenWidth;
    final scale = dialogWidth / _designDialogWidth;
    final horizontalInset = (screenWidth - dialogWidth) / 2;
    final surface = isDarkMode ? _darkSurface : Colors.white;
    final primaryTextColor = isDarkMode ? _darkPrimaryText : _primaryText;
    final badgeFill = isDarkMode ? _darkBadgeFill : _paleBlue;
    final borderColor =
        isDarkMode ? Colors.white.withValues(alpha: 0.12) : _border;
    final accent = isDarkMode ? _darkAccent : _brandBlue;

    double s(double designPx) => designPx * scale;

    final titleStyle = TextStyle(
      color: primaryTextColor,
      fontSize: s(20),
      height: 22 / 20,
      fontWeight: FontWeight.w700,
    );
    final messageStyle = TextStyle(
      color: primaryTextColor,
      fontSize: s(14),
      height: 1.5,
      fontWeight: FontWeight.w400,
    );
    final badgeStyle = TextStyle(
      color: accent,
      fontSize: s(13),
      height: 1.5,
    );
    final illustrationSize = s(96);

    return Dialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: horizontalInset < 16 ? 16 : horizontalInset,
        vertical: 24,
      ),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: SizedBox(
        width: dialogWidth,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            Padding(
              padding: EdgeInsets.only(top: s(84)),
              child: Material(
                color: surface,
                borderRadius: BorderRadius.circular(s(20)),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(height: s(42)),
                    if (useFailureArtwork)
                      _FailureIllustration(size: illustrationSize)
                    else if (useRestartArtwork)
                      _RestartIllustration(size: illustrationSize)
                    else if (statusIcon == null)
                      _SuccessIllustration(size: illustrationSize)
                    else
                      _StatusIllustration(
                        icon: statusIcon!,
                        size: illustrationSize,
                        isDarkMode: isDarkMode,
                      ),
                    SizedBox(height: s(6)),
                    Text(title, textAlign: TextAlign.center, style: titleStyle),
                    if (message.isNotEmpty) ...[
                      SizedBox(height: s(10)),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: s(24)),
                        child: Text(
                          message,
                          textAlign: TextAlign.center,
                          style: messageStyle,
                        ),
                      ),
                    ],
                    if (badgeText.isNotEmpty) ...[
                      SizedBox(height: s(14)),
                      Container(
                        width: dialogWidth - s(48),
                        constraints: BoxConstraints(minHeight: s(32)),
                        alignment: Alignment.center,
                        padding: EdgeInsets.symmetric(
                          horizontal: s(12),
                          vertical: s(6),
                        ),
                        decoration: BoxDecoration(
                          color: badgeFill,
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(color: borderColor),
                        ),
                        child: Text(
                          badgeText,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: badgeStyle,
                        ),
                      ),
                    ],
                    SizedBox(height: s(20)),
                    Divider(height: 0.5, thickness: 0.5, color: borderColor),
                    _DialogActions(
                      scale: scale,
                      primaryText: buttonText,
                      secondaryText: secondaryButtonText,
                      isDarkMode: isDarkMode,
                      onPrimary: onConfirmed,
                      onSecondary: onSecondary,
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: FittedBox(
                fit: BoxFit.fitWidth,
                alignment: Alignment.topCenter,
                child: _HeaderArtwork(surfaceColor: surface),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 与 [ReviewApprovedDialog] 同款的输入弹窗。
///
/// 输入校验不通过时弹窗会保持打开；校验通过后才关闭并回传内容。
class ReviewInputDialog extends StatefulWidget {
  const ReviewInputDialog({
    super.key,
    required this.title,
    required this.message,
    required this.badgeText,
    required this.hintText,
    required this.onSubmitted,
    this.initialValue = '',
    this.buttonText = '保存',
    this.secondaryButtonText = '取消',
    this.statusIcon = Icons.edit_outlined,
    this.isDarkMode = false,
    this.keyboardType,
    this.inputFormatters,
    this.validator,
  });

  final String title;
  final String message;
  final String badgeText;
  final String hintText;
  final String initialValue;
  final String buttonText;
  final String secondaryButtonText;
  final IconData statusIcon;
  final bool isDarkMode;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String value)? validator;
  final ValueChanged<String> onSubmitted;

  @override
  State<ReviewInputDialog> createState() => _ReviewInputDialogState();
}

class _ReviewInputDialogState extends State<ReviewInputDialog> {
  late final TextEditingController _controller;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final value = _controller.text.trim();
    final error = widget.validator?.call(value);
    if (error != null) {
      setState(() => _errorText = error);
      return;
    }
    Navigator.of(context).pop();
    widget.onSubmitted(value);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDarkMode;
    final screenWidth = MediaQuery.sizeOf(context).width;
    const designDialogWidth = ReviewApprovedDialog._designDialogWidth;
    final dialogWidth = screenWidth *
        designDialogWidth /
        ReviewApprovedDialog._designScreenWidth;
    final scale = dialogWidth / designDialogWidth;
    final horizontalInset = (screenWidth - dialogWidth) / 2;
    final surface = isDark ? const Color(0xFF16212F) : Colors.white;
    final primaryText =
        isDark ? const Color(0xFFF5F7FA) : ReviewApprovedDialog._primaryText;
    final secondaryText =
        isDark ? const Color(0xFFAAB3C1) : const Color(0xFF9AA3B4);
    final inputFill =
        isDark ? const Color(0xFF101926) : ReviewApprovedDialog._paleBlue;
    final badgeFill =
        isDark ? const Color(0xFF1C2939) : ReviewApprovedDialog._paleBlue;
    final border = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : ReviewApprovedDialog._border;
    final accent =
        isDark ? const Color(0xFF8AAEFF) : ReviewApprovedDialog._brandBlue;
    final actionText =
        isDark ? const Color(0xFFB8A8F2) : const Color(0xFF7460B4);

    double s(double designPx) => designPx * scale;

    return Dialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: horizontalInset < 16 ? 16 : horizontalInset,
        vertical: 24,
      ),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: SizedBox(
        width: dialogWidth,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            Padding(
              padding: EdgeInsets.only(top: s(84)),
              child: Material(
                color: surface,
                borderRadius: BorderRadius.circular(s(20)),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(height: s(42)),
                    _StatusIllustration(
                      icon: widget.statusIcon,
                      size: s(82),
                      isDarkMode: isDark,
                    ),
                    SizedBox(height: s(6)),
                    Text(
                      widget.title,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: primaryText,
                        fontSize: s(20),
                        height: 1.1,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (widget.message.isNotEmpty) ...[
                      SizedBox(height: s(8)),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: s(24)),
                        child: Text(
                          widget.message,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: primaryText,
                            fontSize: s(13),
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                    SizedBox(height: s(12)),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: s(24)),
                      child: TextField(
                        controller: _controller,
                        autofocus: true,
                        keyboardType: widget.keyboardType,
                        inputFormatters: widget.inputFormatters,
                        textAlign: TextAlign.center,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _submit(),
                        onChanged: (_) {
                          if (_errorText != null) {
                            setState(() => _errorText = null);
                          }
                        },
                        style: TextStyle(
                          color: primaryText,
                          fontSize: s(20),
                          fontWeight: FontWeight.w700,
                        ),
                        decoration: InputDecoration(
                          hintText: widget.hintText,
                          errorText: _errorText,
                          hintStyle: TextStyle(
                            color: secondaryText,
                            fontSize: s(13),
                            fontWeight: FontWeight.w400,
                          ),
                          filled: true,
                          fillColor: inputFill,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: s(12),
                            vertical: s(10),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(s(12)),
                            borderSide: BorderSide(color: border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(s(12)),
                            borderSide: BorderSide(
                              color: accent,
                              width: 1.4,
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (widget.badgeText.isNotEmpty) ...[
                      SizedBox(height: s(12)),
                      Container(
                        width: dialogWidth - s(48),
                        constraints: BoxConstraints(minHeight: s(32)),
                        alignment: Alignment.center,
                        padding: EdgeInsets.symmetric(
                          horizontal: s(12),
                          vertical: s(6),
                        ),
                        decoration: BoxDecoration(
                          color: badgeFill,
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(color: border),
                        ),
                        child: Text(
                          widget.badgeText,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: accent,
                            fontSize: s(12),
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                    SizedBox(height: s(18)),
                    Divider(
                      height: 0.5,
                      thickness: 0.5,
                      color: border,
                    ),
                    Material(
                      color: badgeFill,
                      child: SizedBox(
                        height: s(50),
                        child: Row(
                          children: [
                            Expanded(
                              child: _DialogActionButton(
                                text: widget.secondaryButtonText,
                                height: s(50),
                                fontSize: s(17),
                                backgroundColor: Colors.transparent,
                                textColor: actionText,
                                onTap: () => Navigator.of(context).pop(),
                              ),
                            ),
                            VerticalDivider(
                              width: 0.5,
                              thickness: 0.5,
                              color: border,
                            ),
                            Expanded(
                              child: _DialogActionButton(
                                text: widget.buttonText,
                                height: s(50),
                                fontSize: s(17),
                                backgroundColor: Colors.transparent,
                                textColor: actionText,
                                onTap: _submit,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: FittedBox(
                fit: BoxFit.fitWidth,
                alignment: Alignment.topCenter,
                child: _HeaderArtwork(surfaceColor: surface),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 与 [ReviewApprovedDialog] 同款的修改密码弹窗。
///
/// [onSubmit] 返回 null 表示修改成功并关闭弹窗；返回文案则显示在弹窗内，弹窗保持打开。
class ChangePasswordDialog extends StatefulWidget {
  const ChangePasswordDialog({
    super.key,
    required this.onSubmit,
    this.isDarkMode = false,
  });

  final Future<String?> Function(String oldPassword, String newPassword)
      onSubmit;
  final bool isDarkMode;

  @override
  State<ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<ChangePasswordDialog> {
  final _oldController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscure = true;
  bool _submitting = false;
  String? _errorText;

  @override
  void dispose() {
    _oldController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  String? _validate(String oldPwd, String newPwd, String confirmPwd) {
    if (oldPwd.isEmpty) return '请输入原密码';
    if (newPwd.isEmpty) return '请输入新密码';
    if (newPwd.length < 3) return '新密码至少 3 位';
    if (newPwd != confirmPwd) return '两次输入的新密码不一致';
    if (newPwd == oldPwd) return '新密码不能与原密码相同';
    return null;
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final oldPwd = _oldController.text;
    final newPwd = _newController.text;
    final error = _validate(oldPwd, newPwd, _confirmController.text);
    if (error != null) {
      setState(() => _errorText = error);
      return;
    }
    setState(() {
      _submitting = true;
      _errorText = null;
    });
    final result = await widget.onSubmit(oldPwd, newPwd);
    if (!mounted) return;
    if (result == null) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _submitting = false;
      _errorText = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDarkMode;
    final screenWidth = MediaQuery.sizeOf(context).width;
    const designDialogWidth = ReviewApprovedDialog._designDialogWidth;
    final dialogWidth = screenWidth *
        designDialogWidth /
        ReviewApprovedDialog._designScreenWidth;
    final scale = dialogWidth / designDialogWidth;
    final horizontalInset = (screenWidth - dialogWidth) / 2;
    final surface = isDark ? const Color(0xFF16212F) : Colors.white;
    final primaryText =
        isDark ? const Color(0xFFF5F7FA) : ReviewApprovedDialog._primaryText;
    final secondaryText =
        isDark ? const Color(0xFFAAB3C1) : const Color(0xFF9AA3B4);
    final inputFill =
        isDark ? const Color(0xFF101926) : ReviewApprovedDialog._paleBlue;
    final actionFill =
        isDark ? const Color(0xFF1C2939) : ReviewApprovedDialog._paleBlue;
    final border = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : ReviewApprovedDialog._border;
    final accent =
        isDark ? const Color(0xFF8AAEFF) : ReviewApprovedDialog._brandBlue;
    final actionText =
        isDark ? const Color(0xFFB8A8F2) : const Color(0xFF7460B4);

    double s(double designPx) => designPx * scale;

    Widget field(
      TextEditingController controller,
      String hint, {
      bool autofocus = false,
      bool isLast = false,
    }) {
      return Padding(
        padding: EdgeInsets.fromLTRB(s(24), 0, s(24), s(10)),
        child: TextField(
          controller: controller,
          autofocus: autofocus,
          obscureText: _obscure,
          autocorrect: false,
          enableSuggestions: false,
          textInputAction: isLast ? TextInputAction.done : TextInputAction.next,
          onSubmitted: isLast ? (_) => _submit() : null,
          onChanged: (_) {
            if (_errorText != null) setState(() => _errorText = null);
          },
          style: TextStyle(color: primaryText, fontSize: s(15)),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: secondaryText, fontSize: s(13)),
            filled: true,
            fillColor: inputFill,
            isDense: true,
            contentPadding: EdgeInsets.symmetric(
              horizontal: s(12),
              vertical: s(12),
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _obscure ? Icons.visibility_off : Icons.visibility,
                size: s(18),
                color: secondaryText,
              ),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(s(12)),
              borderSide: BorderSide(color: border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(s(12)),
              borderSide: BorderSide(color: accent, width: 1.4),
            ),
          ),
        ),
      );
    }

    return Dialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: horizontalInset < 16 ? 16 : horizontalInset,
        vertical: 24,
      ),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: SingleChildScrollView(
        child: SizedBox(
          width: dialogWidth,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: [
              Padding(
                padding: EdgeInsets.only(top: s(84)),
                child: Material(
                  color: surface,
                  borderRadius: BorderRadius.circular(s(20)),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(height: s(42)),
                      _StatusIllustration(
                        icon: Icons.lock_reset_rounded,
                        size: s(82),
                        isDarkMode: isDark,
                      ),
                      SizedBox(height: s(6)),
                      Text(
                        '修改密码',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: primaryText,
                          fontSize: s(20),
                          height: 1.1,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: s(14)),
                      field(_oldController, '原密码', autofocus: true),
                      field(_newController, '新密码'),
                      field(_confirmController, '确认新密码', isLast: true),
                      if (_errorText != null)
                        Padding(
                          padding: EdgeInsets.fromLTRB(s(24), 0, s(24), s(4)),
                          child: Text(
                            _errorText!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: const Color(0xFFE5484D),
                              fontSize: s(12),
                            ),
                          ),
                        ),
                      SizedBox(height: s(8)),
                      Divider(height: 0.5, thickness: 0.5, color: border),
                      Material(
                        color: actionFill,
                        child: SizedBox(
                          height: s(50),
                          child: Row(
                            children: [
                              Expanded(
                                child: _DialogActionButton(
                                  text: '取消',
                                  height: s(50),
                                  fontSize: s(17),
                                  backgroundColor: Colors.transparent,
                                  textColor: actionText,
                                  onTap: () => Navigator.of(context).pop(),
                                ),
                              ),
                              VerticalDivider(
                                width: 0.5,
                                thickness: 0.5,
                                color: border,
                              ),
                              Expanded(
                                child: _DialogActionButton(
                                  text: _submitting ? '提交中…' : '确认修改',
                                  height: s(50),
                                  fontSize: s(17),
                                  backgroundColor: Colors.transparent,
                                  textColor: actionText,
                                  onTap: _submit,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: FittedBox(
                  fit: BoxFit.fitWidth,
                  alignment: Alignment.topCenter,
                  child: _HeaderArtwork(surfaceColor: surface),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DialogActions extends StatelessWidget {
  const _DialogActions({
    required this.scale,
    required this.primaryText,
    required this.secondaryText,
    required this.onPrimary,
    required this.onSecondary,
    this.isDarkMode = false,
  });

  final double scale;
  final String primaryText;
  final String? secondaryText;
  final bool isDarkMode;
  final VoidCallback? onPrimary;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    final secondary = secondaryText;
    final actionHeight = 50 * scale;
    final actionFontSize = 17 * scale;
    final surfaceColor = isDarkMode
        ? ReviewApprovedDialog._darkBadgeFill
        : ReviewApprovedDialog._paleBlue;
    final borderColor = isDarkMode
        ? Colors.white.withValues(alpha: 0.12)
        : ReviewApprovedDialog._border;
    final actionTextColor = isDarkMode
        ? ReviewApprovedDialog._darkActionText
        : const Color(0xFF7460B4);

    if (secondary == null) {
      return _DialogActionButton(
        text: primaryText,
        height: actionHeight,
        fontSize: actionFontSize,
        backgroundColor: surfaceColor,
        textColor: isDarkMode
            ? ReviewApprovedDialog._darkPrimaryText
            : ReviewApprovedDialog._primaryText,
        onTap: () {
          Navigator.of(context).pop();
          onPrimary?.call();
        },
      );
    }

    return Material(
      color: surfaceColor,
      child: SizedBox(
        height: actionHeight,
        child: Row(
          children: [
            Expanded(
              child: _DialogActionButton(
                text: secondary,
                height: actionHeight,
                fontSize: actionFontSize,
                backgroundColor: Colors.transparent,
                textColor: actionTextColor,
                onTap: () {
                  Navigator.of(context).pop();
                  onSecondary?.call();
                },
              ),
            ),
            VerticalDivider(
              width: 0.5,
              thickness: 0.5,
              color: borderColor,
            ),
            Expanded(
              child: _DialogActionButton(
                text: primaryText,
                height: actionHeight,
                fontSize: actionFontSize,
                backgroundColor: Colors.transparent,
                textColor: actionTextColor,
                onTap: () {
                  Navigator.of(context).pop();
                  onPrimary?.call();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DialogActionButton extends StatelessWidget {
  const _DialogActionButton({
    required this.text,
    required this.onTap,
    this.height = 50,
    this.fontSize = 16,
    this.backgroundColor = ReviewApprovedDialog._paleBlue,
    this.textColor = ReviewApprovedDialog._primaryText,
  });

  final String text;
  final VoidCallback onTap;
  final double height;
  final double fontSize;
  final Color backgroundColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: SizedBox(
          width: double.infinity,
          height: height,
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                color: textColor,
                fontSize: fontSize,
                height: 1.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusIllustration extends StatelessWidget {
  const _StatusIllustration({
    required this.icon,
    required this.size,
    this.isDarkMode = false,
  });

  final IconData icon;
  final double size;
  final bool isDarkMode;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isDarkMode ? const Color(0xFF22334A) : const Color(0xFFEAF1FF),
        boxShadow: [
          BoxShadow(
            color:
                isDarkMode ? const Color(0x4D6E9CFF) : const Color(0x336E9CFF),
            blurRadius: size * 0.21,
          ),
        ],
      ),
      child: Icon(
        icon,
        size: size * 0.5,
        color: isDarkMode
            ? const Color(0xFF8AAEFF)
            : ReviewApprovedDialog._brandBlue,
      ),
    );
  }
}

class _SuccessIllustration extends StatelessWidget {
  const _SuccessIllustration({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            '${ReviewApprovedDialog._assetRoot}/success_glow.png',
            fit: BoxFit.cover,
          ),
          Image.asset(
            '${ReviewApprovedDialog._assetRoot}/success_check.png',
            fit: BoxFit.cover,
          ),
        ],
      ),
    );
  }
}

class _FailureIllustration extends StatelessWidget {
  const _FailureIllustration({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: ShaderMask(
        blendMode: BlendMode.dstIn,
        shaderCallback: (bounds) => const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white, Colors.white, Colors.transparent],
          stops: [0, 0.8956, 1],
        ).createShader(bounds),
        child: Image.asset(
          '${ReviewApprovedDialog._assetRoot}/failure_state.png',
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

class _RestartIllustration extends StatelessWidget {
  const _RestartIllustration({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Image.asset(
        '${ReviewApprovedDialog._assetRoot}/restart_state.png',
        fit: BoxFit.contain,
      ),
    );
  }
}

class _HeaderArtwork extends StatelessWidget {
  const _HeaderArtwork({this.surfaceColor = Colors.white});

  final Color surfaceColor;

  @override
  Widget build(BuildContext context) {
    const root = ReviewApprovedDialog._assetRoot;
    // 按 Figma 310 宽画板定位，外层 FittedBox 等比缩放到弹窗实际宽度，盖子与主体同宽
    return SizedBox(
      width: ReviewApprovedDialog._designDialogWidth,
      height: 110,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 7,
            top: 7,
            width: 269,
            height: 77,
            child: SvgPicture.asset('$root/header_panel.svg', fit: BoxFit.fill),
          ),
          Positioned(
            left: 27,
            top: 8,
            width: 28,
            height: 28,
            child: SvgPicture.asset('$root/header_accent.svg'),
          ),
          Positioned(
            left: 38,
            top: 8,
            width: 16,
            height: 28,
            child: SvgPicture.asset('$root/header_stroke.svg'),
          ),
          Positioned(
            left: 49,
            top: 45,
            child: Transform.rotate(
              angle: 0.092,
              child: const Text(
                '温馨提示',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22.7,
                  height: 20 / 22.7,
                  fontWeight: FontWeight.w800,
                  shadows: [Shadow(color: Color(0x4D000000), blurRadius: 2)],
                ),
              ),
            ),
          ),
          Positioned(
            left: 38,
            top: 64,
            width: 150,
            height: 17,
            child: SvgPicture.asset('$root/header_underline.svg'),
          ),
          Positioned(
            left: 164,
            top: 0,
            width: 146,
            height: 104,
            child: Image.asset(
              '$root/header_assistant.png',
              fit: BoxFit.contain,
              alignment: Alignment.centerRight,
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 27,
            child: SvgPicture.asset(
              '$root/header_bottom.svg',
              fit: BoxFit.fill,
              colorFilter: ColorFilter.mode(surfaceColor, BlendMode.srcIn),
            ),
          ),
        ],
      ),
    );
  }
}
