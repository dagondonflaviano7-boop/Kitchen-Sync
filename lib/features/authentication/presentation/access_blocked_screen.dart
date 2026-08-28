import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AccessBlockedScreen extends StatefulWidget {
  final String title;
  final String message;
  final String statusLabel;
  final IconData icon;
  final VoidCallback? onRetry;

  const AccessBlockedScreen({
    super.key,
    required this.title,
    required this.message,
    this.statusLabel = 'Store access unavailable',
    this.icon = Icons.lock_outline,
    this.onRetry,
  });

  @override
  State<AccessBlockedScreen> createState() => _AccessBlockedScreenState();
}

class _AccessBlockedScreenState extends State<AccessBlockedScreen> {
  static const Color _green = Color(0xFF2E6B4F);
  static const Color _paper = Color(0xFFF8F6F1);
  static const Color _ink = Color(0xFF183027);
  static const Color _muted = Color(0xFF64756B);
  static const Color _line = Color(0xFFDBE5DD);
  static const Color _dangerSoft = Color(0xFFF9E9E6);

  bool _checkingAccess = false;
  bool _signingOut = false;

  Future<void> _retry() async {
    final VoidCallback? retryAction = widget.onRetry;

    if (retryAction == null || _checkingAccess || _signingOut) {
      return;
    }

    setState(() {
      _checkingAccess = true;
    });

    try {
      retryAction();
    } finally {
      if (mounted) {
        setState(() {
          _checkingAccess = false;
        });
      }
    }
  }

  Future<void> _signOut() async {
    if (_checkingAccess || _signingOut) {
      return;
    }

    setState(() {
      _signingOut = true;
    });

    try {
      await FirebaseAuth.instance.signOut();
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to sign out: $error',
          ),
        ),
      );

      setState(() {
        _signingOut = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _paper,
      body: SafeArea(
        child: Stack(
          children: [
            const Positioned(
              top: -150,
              right: -130,
              child: _AmbientCircle(
                size: 390,
                color: Color(0xBDDFEBE2),
              ),
            ),
            const Positioned(
              bottom: -175,
              left: -110,
              child: _AmbientCircle(
                size: 330,
                color: Color(0xFFE7EDE3),
              ),
            ),
            Column(
              children: [
                const _KitchenSyncAccessHeader(),
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(
                        20,
                        36,
                        20,
                        24,
                      ),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: 496,
                        ),
                        child: _buildAccessCard(context),
                      ),
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(
                    20,
                    0,
                    20,
                    22,
                  ),
                  child: Text(
                    'Need access? Contact your '
                    'Kitchen Sync administrator.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF6D7D73),
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
    );
  }

  Widget _buildAccessCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        27,
        37,
        27,
        27,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: _line,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1C1D4935),
            blurRadius: 58,
            offset: Offset(0, 22),
          ),
          BoxShadow(
            color: Color(0x0A1D4935),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _LockIndicator(
            icon: widget.icon,
          ),
          const SizedBox(height: 26),
          Text(
            widget.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _ink,
              fontSize: 34,
              height: 1.12,
              fontWeight: FontWeight.w700,
              letterSpacing: -1.1,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            widget.message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _muted,
              fontSize: 16,
              height: 1.58,
            ),
          ),
          const SizedBox(height: 23),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 11,
              vertical: 7,
            ),
            decoration: BoxDecoration(
              color: _dangerSoft,
              borderRadius: BorderRadius.circular(99),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 16,
                  color: Color(0xFF8D332B),
                ),
                const SizedBox(width: 7),
                Flexible(
                  child: Text(
                    widget.statusLabel,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF8D332B),
                      fontSize: 13,
                      height: 1.25,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 27),
          const Divider(
            height: 1,
            color: _line,
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              final bool stackButtons = constraints.maxWidth < 330;

              final Widget retryButton = _buildRetryButton();

              final Widget signOutButton = _buildSignOutButton();

              if (stackButtons) {
                return Column(
                  children: [
                    retryButton,
                    const SizedBox(height: 12),
                    signOutButton,
                  ],
                );
              }

              if (widget.onRetry == null) {
                return signOutButton;
              }

              return Row(
                children: [
                  Expanded(
                    child: retryButton,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: signOutButton,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 22),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.verified_user_outlined,
                size: 16,
                color: Color(0xFF74887A),
              ),
              SizedBox(width: 7),
              Flexible(
                child: Text(
                  'Access is managed by your '
                  'Kitchen Sync administrator.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF74887A),
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRetryButton() {
    if (widget.onRetry == null) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: _checkingAccess || _signingOut ? null : _retry,
        style: OutlinedButton.styleFrom(
          foregroundColor: _green,
          side: const BorderSide(
            color: Color(0xFFB8CABE),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        icon: _checkingAccess
            ? const SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: _green,
                ),
              )
            : const Icon(
                Icons.refresh,
                size: 19,
              ),
        label: Text(
          _checkingAccess ? 'Checking access...' : 'Retry',
          style: const TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildSignOutButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton.icon(
        onPressed: _checkingAccess || _signingOut ? null : _signOut,
        style: FilledButton.styleFrom(
          backgroundColor: _green,
          foregroundColor: Colors.white,
          disabledBackgroundColor: _green.withValues(alpha: 0.72),
          disabledForegroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        icon: _signingOut
            ? const SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(
                Icons.logout,
                size: 19,
              ),
        label: Text(
          _signingOut ? 'Signing out...' : 'Sign out',
          style: const TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _KitchenSyncAccessHeader extends StatelessWidget {
  const _KitchenSyncAccessHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(
        minHeight: 72,
      ),
      decoration: const BoxDecoration(
        color: Color(0xC2F8F6F1),
        border: Border(
          bottom: BorderSide(
            color: Color(0xC7DBE5DD),
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 14,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 1040,
          ),
          child: const Row(
            children: [
              _KitchenSyncBrandMark(),
              SizedBox(width: 11),
              Text(
                'Kitchen Sync Access',
                style: TextStyle(
                  color: Color(0xFF1D4935),
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _KitchenSyncBrandMark extends StatelessWidget {
  const _KitchenSyncBrandMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: const Color(0xFF2E6B4F),
        borderRadius: BorderRadius.circular(11),
        boxShadow: const [
          BoxShadow(
            color: Color(0x2E2E6B4F),
            blurRadius: 16,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: const Icon(
        Icons.restaurant,
        size: 20,
        color: Colors.white,
      ),
    );
  }
}

class _LockIndicator extends StatelessWidget {
  final IconData icon;

  const _LockIndicator({
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 112,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 108,
            height: 108,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(
                  0x33A34036,
                ),
              ),
            ),
          ),
          Container(
            width: 86,
            height: 86,
            decoration: const BoxDecoration(
              color: Color(0xFFF8E8E5),
              shape: BoxShape.circle,
            ),
          ),
          Container(
            width: 74,
            height: 74,
            decoration: BoxDecoration(
              color: const Color(0xFFFFFAFA),
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0x1AA34036),
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1AA34036),
                  blurRadius: 22,
                  offset: Offset(0, 9),
                ),
              ],
            ),
            child: Icon(
              icon,
              size: 36,
              color: const Color(0xFFA34036),
            ),
          ),
        ],
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
