import 'dart:async';

import 'package:flutter/material.dart';

class ProfileLoadingScreen extends StatefulWidget {
  const ProfileLoadingScreen({super.key});

  @override
  State<ProfileLoadingScreen> createState() => _ProfileLoadingScreenState();
}

class _ProfileLoadingScreenState extends State<ProfileLoadingScreen>
    with SingleTickerProviderStateMixin {
  static const Color _green = Color(0xFF2E6B4F);
  static const Color _deepGreen = Color(0xFF1D4935);
  static const Color _mint = Color(0xFFE8F1EC);
  static const Color _paper = Color(0xFFF8F6F1);
  static const Color _ink = Color(0xFF183027);
  static const Color _muted = Color(0xFF6D7D73);
  static const Color _line = Color(0xFFDCE5DE);

  static const List<String> _statusMessages = <String>[
    'Checking profile permissions',
    'Confirming assigned store',
    'Validating team access',
  ];

  late final AnimationController _animationController;
  Timer? _statusTimer;
  int _statusIndex = 0;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    _statusTimer = Timer.periodic(
      const Duration(milliseconds: 2600),
      (_) {
        if (!mounted) {
          return;
        }

        setState(() {
          _statusIndex = (_statusIndex + 1) % _statusMessages.length;
        });
      },
    );
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    return Scaffold(
      backgroundColor: _paper,
      body: SafeArea(
        child: Stack(
          children: [
            const Positioned(
              top: -130,
              right: -110,
              child: _AmbientCircle(
                size: 330,
                color: Color(0xB8D3E6D9),
              ),
            ),
            const Positioned(
              bottom: -160,
              left: -100,
              child: _AmbientCircle(
                size: 300,
                color: Color(0xE6E1EBDE),
              ),
            ),
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 28,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 450,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Kitchen Sync',
                        style: TextStyle(
                          color: _deepGreen,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 28),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(
                          28,
                          42,
                          28,
                          30,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: _line,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x1A1B3D2B),
                              blurRadius: 46,
                              offset: Offset(0, 18),
                            ),
                            BoxShadow(
                              color: Color(0x0A1B3D2B),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _SecurityIndicator(
                              controller: _animationController,
                              reduceMotion: reduceMotion,
                            ),
                            const SizedBox(height: 28),
                            const Text(
                              'Verifying access',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: _ink,
                                fontSize: 32,
                                height: 1.18,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -1,
                              ),
                            ),
                            const SizedBox(height: 13),
                            const Text(
                              'Loading your Kitchen Sync profile '
                              'and assigned store...',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: _muted,
                                fontSize: 16,
                                height: 1.55,
                              ),
                            ),
                            const SizedBox(height: 31),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(99),
                              child: SizedBox(
                                height: 7,
                                child: reduceMotion
                                    ? Container(
                                        color: _mint,
                                        alignment: Alignment.center,
                                        child: FractionallySizedBox(
                                          widthFactor: 0.42,
                                          child: Container(
                                            color: _green,
                                          ),
                                        ),
                                      )
                                    : const LinearProgressIndicator(
                                        color: _green,
                                        backgroundColor: Color(0xFFE4EBE6),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 250),
                              child: Row(
                                key: ValueKey<int>(_statusIndex),
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const _StatusDot(),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      _statusMessages[_statusIndex],
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: _deepGreen,
                                        fontSize: 14,
                                        height: 1.4,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            const Divider(
                              color: _line,
                              height: 1,
                            ),
                            const SizedBox(height: 21),
                            const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.lock_outline,
                                  size: 15,
                                  color: Color(0xFF729281),
                                ),
                                SizedBox(width: 7),
                                Flexible(
                                  child: Text(
                                    'Your access is being '
                                    'verified securely',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Color(0xFF789085),
                                      fontSize: 13,
                                      height: 1.4,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SecurityIndicator extends StatelessWidget {
  final AnimationController controller;
  final bool reduceMotion;

  const _SecurityIndicator({
    required this.controller,
    required this.reduceMotion,
  });

  @override
  Widget build(BuildContext context) {
    const Color green = Color(0xFF2E6B4F);
    const Color mint = Color(0xFFE8F1EC);

    return SizedBox.square(
      dimension: 108,
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, child) {
          final double progress = reduceMotion ? 0 : controller.value;

          final double scale = 0.82 + (progress * 0.38);
          final double opacity = reduceMotion ? 0.25 : (1 - progress);

          return Stack(
            alignment: Alignment.center,
            children: [
              Transform.scale(
                scale: scale,
                child: Opacity(
                  opacity: opacity.clamp(0, 1),
                  child: Container(
                    width: 98,
                    height: 98,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: green.withValues(alpha: 0.30),
                      ),
                    ),
                  ),
                ),
              ),
              Container(
                width: 78,
                height: 78,
                decoration: BoxDecoration(
                  color: mint,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: green.withValues(alpha: 0.08),
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x1F2E6B4F),
                      blurRadius: 22,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.verified_user_outlined,
                  size: 39,
                  color: green,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  const _StatusDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 7,
      height: 7,
      decoration: const BoxDecoration(
        color: Color(0xFF2E6B4F),
        shape: BoxShape.circle,
      ),
    );
  }
}

class _AmbientCircle extends StatelessWidget {
  final double size;
  final Color color;

  const _AmbientCircle({
    required this.size,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
