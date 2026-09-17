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

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final dialogWidth = screenWidth * _designDialogWidth / _designScreenWidth;
    final scale = dialogWidth / _designDialogWidth;
    final horizontalInset = (screenWidth - dialogWidth) / 2;

    double s(double designPx) => designPx * scale;

    final titleStyle = TextStyle(
      color: _primaryText,
      fontSize: s(20),
      height: 22 / 20,
      fontWeight: FontWeight.w700,
    );
    final messageStyle = TextStyle(
      color: _primaryText,
      fontSize: s(14),
      height: 1.5,
      fontWeight: FontWeight.w400,
    );
    final badgeStyle = TextStyle(
      color: _brandBlue,
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
                color: Colors.white,
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
                          icon: statusIcon!, size: illustrationSize),
                    SizedBox(height: s(6)),
                    Text(title, textAlign: TextAlign.center, style: titleStyle),
                    SizedBox(height: s(10)),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: s(24)),
                      child: Text(
                        message,
                        textAlign: TextAlign.center,
                        style: messageStyle,
                      ),
                    ),
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
                        color: _paleBlue,
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(color: _border),
                      ),
                      child: Text(
                        badgeText,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: badgeStyle,
                      ),
                    ),
                    SizedBox(height: s(20)),
                    const Divider(height: 0.5, thickness: 0.5, color: _border),
                    _DialogActions(
                      scale: scale,
                      primaryText: buttonText,
                      secondaryText: secondaryButtonText,
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
              child: Transform.scale(
                scale: scale,
                alignment: Alignment.topCenter,
                child: const _HeaderArtwork(),
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
    final screenWidth = MediaQuery.sizeOf(context).width;
    const designDialogWidth = ReviewApprovedDialog._designDialogWidth;
    final dialogWidth = screenWidth *
        designDialogWidth /
        ReviewApprovedDialog._designScreenWidth;
    final scale = dialogWidth / designDialogWidth;
    final horizontalInset = (screenWidth - dialogWidth) / 2;

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
                color: Colors.white,
                borderRadius: BorderRadius.circular(s(20)),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(height: s(42)),
                    _StatusIllustration(
                      icon: widget.statusIcon,
                      size: s(82),
                    ),
                    SizedBox(height: s(6)),
                    Text(
                      widget.title,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: ReviewApprovedDialog._primaryText,
                        fontSize: s(20),
                        height: 1.1,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: s(8)),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: s(24)),
                      child: Text(
                        widget.message,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: ReviewApprovedDialog._primaryText,
                          fontSize: s(13),
                          height: 1.4,
                        ),
                      ),
                    ),
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
                          color: ReviewApprovedDialog._primaryText,
                          fontSize: s(20),
                          fontWeight: FontWeight.w700,
                        ),
                        decoration: InputDecoration(
                          hintText: widget.hintText,
                          errorText: _errorText,
                          hintStyle: TextStyle(
                            color: const Color(0xFF9AA3B4),
                            fontSize: s(13),
                            fontWeight: FontWeight.w400,
                          ),
                          filled: true,
                          fillColor: ReviewApprovedDialog._paleBlue,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: s(12),
                            vertical: s(10),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(s(12)),
                            borderSide: const BorderSide(
                              color: ReviewApprovedDialog._border,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(s(12)),
                            borderSide: const BorderSide(
                              color: ReviewApprovedDialog._brandBlue,
                              width: 1.4,
                            ),
                          ),
                        ),
                      ),
                    ),
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
                        color: ReviewApprovedDialog._paleBlue,
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(color: ReviewApprovedDialog._border),
                      ),
                      child: Text(
                        widget.badgeText,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: ReviewApprovedDialog._brandBlue,
                          fontSize: s(12),
                          height: 1.4,
                        ),
                      ),
                    ),
                    SizedBox(height: s(18)),
                    const Divider(
                      height: 0.5,
                      thickness: 0.5,
                      color: ReviewApprovedDialog._border,
                    ),
                    Material(
                      color: ReviewApprovedDialog._paleBlue,
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
                                textColor: const Color(0xFF7460B4),
                                onTap: () => Navigator.of(context).pop(),
                              ),
                            ),
                            const VerticalDivider(
                              width: 0.5,
                              thickness: 0.5,
                              color: ReviewApprovedDialog._border,
                            ),
                            Expanded(
                              child: _DialogActionButton(
                                text: widget.buttonText,
                                height: s(50),
                                fontSize: s(17),
                                backgroundColor: Colors.transparent,
                                textColor: const Color(0xFF7460B4),
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
              child: Transform.scale(
                scale: scale,
                alignment: Alignment.topCenter,
                child: const _HeaderArtwork(),
              ),
            ),
          ],
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
  });

  final double scale;
  final String primaryText;
  final String? secondaryText;
  final VoidCallback? onPrimary;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    final secondary = secondaryText;
    final actionHeight = 50 * scale;
    final actionFontSize = 17 * scale;

    if (secondary == null) {
      return _DialogActionButton(
        text: primaryText,
        height: actionHeight,
        fontSize: actionFontSize,
        onTap: () {
          Navigator.of(context).pop();
          onPrimary?.call();
        },
      );
    }

    return Material(
      color: ReviewApprovedDialog._paleBlue,
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
                textColor: const Color(0xFF7460B4),
                onTap: () {
                  Navigator.of(context).pop();
                  onSecondary?.call();
                },
              ),
            ),
            const VerticalDivider(
              width: 0.5,
              thickness: 0.5,
              color: ReviewApprovedDialog._border,
            ),
            Expanded(
              child: _DialogActionButton(
                text: primaryText,
                height: actionHeight,
                fontSize: actionFontSize,
                backgroundColor: Colors.transparent,
                textColor: const Color(0xFF7460B4),
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
  const _StatusIllustration({required this.icon, required this.size});

  final IconData icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFFEAF1FF),
        boxShadow: [
          BoxShadow(
            color: const Color(0x336E9CFF),
            blurRadius: size * 0.21,
          ),
        ],
      ),
      child:
          Icon(icon, size: size * 0.5, color: ReviewApprovedDialog._brandBlue),
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
  const _HeaderArtwork();

  @override
  Widget build(BuildContext context) {
    const root = ReviewApprovedDialog._assetRoot;
    return SizedBox(
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
            child:
                SvgPicture.asset('$root/header_bottom.svg', fit: BoxFit.fill),
          ),
        ],
      ),
    );
  }
}
