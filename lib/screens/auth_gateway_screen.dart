import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import 'package:lottie/lottie.dart';

class AuthGatewayScreen extends StatefulWidget {
  const AuthGatewayScreen({super.key});

  @override
  State<AuthGatewayScreen> createState() => _AuthGatewayScreenState();
}

class _AuthGatewayScreenState extends State<AuthGatewayScreen> {
  final PageController _pageController = PageController(viewportFraction: 0.8);
  int _currentPage = 0;

  final List<_CarouselItem> _items = [
    _CarouselItem(
      title: 'Seize the\nDay',
      subtitle: 'Start your morning with daily motivation and actionable steps towards your goals.',
      color: const Color(0xFFFFF3BF), // Deeper pastel yellow
      icon: Icons.wb_sunny_rounded,
      lottieAsset: 'assets/images/bird.json',
    ),
    _CarouselItem(
      title: 'Dream\nBig',
      subtitle: 'Turn your aspirations into reality. Plan, track, and achieve your bucket list.',
      color: const Color(0xFFFFD8D8), // Deeper pastel pink
      icon: Icons.auto_awesome_rounded,
      lottieAsset: 'assets/images/finance.json',
    ),
    _CarouselItem(
      title: 'Map Your\nWorld',
      subtitle: 'Pin your travels, visualize your journey, and see how far you\'ve come.',
      color: const Color(0xFFD0EBFF), // Deeper pastel blue
      icon: Icons.map_rounded,
      lottieAsset: 'assets/images/travel-icons.json',
    ),
    _CarouselItem(
      title: 'Your Life\nStory',
      subtitle: 'Capture memories, thoughts, and moments in your private, secure journal.',
      color: const Color(0xFFE5DBFF), // Pastel purple
      icon: Icons.book_rounded,
      lottieAsset: 'assets/images/sport.json',
    ),
  ];

  void _showAuthModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _AuthModal(),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20.0),
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
mainAxisAlignment: MainAxisAlignment.start,
            children: [
              // Carousel
              SizedBox(
                height: 650,
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  itemCount: _items.length,
                  itemBuilder: (context, index) {
                    return AnimatedBuilder(
                      animation: _pageController,
                      builder: (context, child) {
                        double value = 1.0;
                         if (_pageController.position.haveDimensions) {
                           value = _pageController.page! - index;
                           value = (1 - (value.abs() * 0.3)).clamp(0.0, 1.0);
                         } else {
                           // Initial state before layout
                           value = index == _currentPage ? 1.0 : 0.7;
                         }
                         
                         final double curve = Curves.easeOut.transform(value);
                         
                        return Center(
                          child: SizedBox(
                            height: curve * 550, // Scale height
                            width: curve * 350,   // Scale width
                            child: child,
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10.0), // Reduced horizontal padding
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Placeholder Card
                            Expanded(
                              child: Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: _items[index].color.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(40),
                                ),
                                child: _items[index].lottieAsset != null
                                    ? Lottie.asset(
                                        _items[index].lottieAsset!,
                                        fit: BoxFit.contain,
                                      )
                                    : Icon(
                                        _items[index].icon,
                                        size: 100,
                                        color: _items[index].color,
                                      ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            // Title
                            Text(
                              _items[index].title,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.outfit(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                height: 1.1,
                                color: theme.textTheme.displayLarge?.color,
                              ),
                            ),
                            const SizedBox(height: 10),
                            // Subtitle
                            Text(
                              _items[index].subtitle,
                              textAlign: TextAlign.center,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.dmSans(
                                fontSize: 16,
                                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              
              // Indicators
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_items.length, (index) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    height: 8,
                    width: _currentPage == index ? 24 : 8,
                    decoration: BoxDecoration(
                      color: _currentPage == index 
                        ? theme.colorScheme.primary 
                        : theme.colorScheme.primary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
              
              const SizedBox(height: 48),

                // Auth Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: _SocialButton(
                  text: _currentPage == _items.length - 1 ? 'Continue with Email' : 'Next',
                  icon: _currentPage == _items.length - 1 ? Icons.email_outlined : Icons.arrow_forward,
                  color: _currentPage == _items.length - 1 ? theme.colorScheme.primary : Colors.black,
                  textColor: Colors.white,
                  onPressed: () {
                    if (_currentPage == _items.length - 1) {
                      _showAuthModal(context);
                    } else {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    }
                  },
                ),
              ),
              const SizedBox(height: 24),
              
              // Footer Terms
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Text(
                  'By clicking "Continue" you acknowledge that you have read and agree to Bloom Terms of Service and Privacy Policy.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
}

class _CarouselItem {
  final String title;
  final String subtitle;
  final Color color;
  final IconData icon;
  final String? lottieAsset;

  _CarouselItem({
    required this.title,
    required this.subtitle,
    required this.color,
    required this.icon,
    this.lottieAsset,
  });
}

class _SocialButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final Color color;
  final Color textColor;
  final VoidCallback onPressed;

  const _SocialButton({
    required this.text,
    required this.icon,
    required this.color,
    required this.textColor,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: textColor,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 24),
          const SizedBox(width: 12),
          Text(
            text,
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthModal extends StatefulWidget {
  const _AuthModal();

  @override
  State<_AuthModal> createState() => _AuthModalState();
}

class _AuthModalState extends State<_AuthModal> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _loginMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Clear message when switching tabs manually
    _tabController.addListener(() {
      if (_tabController.indexIsChanging || _tabController.animation?.value != _tabController.index) {
        setState(() {}); // Rebuild to switch visible widget
        if (_tabController.indexIsChanging) {
          _loginMessage = null;
        }
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        // height: Removed fixed height for flexibility
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(30),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min, // Wrap content height
          children: [
            const SizedBox(height: 12),
            // Drag Handle
            Container(
              height: 4,
              width: 40,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            
            // Tab Bar
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.grey.withOpacity(0.1)),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(30),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: Colors.white,
                unselectedLabelColor: theme.textTheme.bodyMedium?.color,
                labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                padding: const EdgeInsets.all(4),
                dividerColor: Colors.transparent,
                onTap: (index) {
                  setState(() {}); // Ensure instant update on tap
                },
                tabs: const [
                  Tab(
                    text: 'Log In',
                    icon: Icon(Icons.login_rounded),
                    iconMargin: EdgeInsets.only(bottom: 4),
                  ),
                  Tab(
                    text: 'Sign Up',
                    icon: Icon(Icons.person_add_rounded),
                    iconMargin: EdgeInsets.only(bottom: 4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Form Content - Flexible Height
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutQuart,
              alignment: Alignment.topCenter,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _tabController.index == 0
                    ? _LoginCard(key: const ValueKey('login'), infoMessage: _loginMessage)
                    : _SignupCard(
                        key: const ValueKey('signup'),
                        onSwitchToLogin: () {
                          setState(() {
                             _loginMessage = "Account created! Verify in email to login.";
                             _tabController.animateTo(0);
                          });
                        }),
              ),
            ),
            const SizedBox(height: 24), // Bottom padding
          ],
        ),
      ),
    ),
  );
}
}

class _LoginCard extends StatefulWidget {
  final String? infoMessage;

  const _LoginCard({super.key, this.infoMessage});

  @override
  State<_LoginCard> createState() => _LoginCardState();
}

class _LoginCardState extends State<_LoginCard> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await AuthService().signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      
      // Sync metadata to public.profiles table
      await StorageService().syncProfile();
      
      if (mounted) Navigator.pop(context); // Close modal on success
    } on AuthException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (e) {
      setState(() => _errorMessage = 'An unexpected error occurred');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            if (widget.infoMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Text(
                  widget.infoMessage!,
                  style: GoogleFonts.dmSans(color: Colors.green, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Text(
                  _errorMessage!,
                  style: GoogleFonts.dmSans(color: Colors.redAccent),
                  textAlign: TextAlign.center,
                ),
              ),
            _buildTextField(
              controller: _emailController,
              label: 'Email Address',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _passwordController,
              label: 'Password',
              icon: Icons.lock_outline,
              obscureText: true,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _login,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isLoading
                  ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Log In'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    TextInputType? keyboardType,
  }) {
    final theme = Theme.of(context);
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: GoogleFonts.dmSans(color: theme.textTheme.bodyLarge?.color),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 22),
        filled: true,
        fillColor: theme.colorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      validator: (value) => value != null && value.isNotEmpty ? null : 'Required',
    );
  }
}

class _SignupCard extends StatefulWidget {
  final VoidCallback onSwitchToLogin;

  const _SignupCard({super.key, required this.onSwitchToLogin});

  @override
  State<_SignupCard> createState() => _SignupCardState();
}

class _SignupCardState extends State<_SignupCard> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;
    if (_passwordController.text != _confirmController.text) {
      setState(() => _errorMessage = "Passwords do not match");
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final displayName = _nameController.text.trim();
      await AuthService().signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        displayName: displayName.isNotEmpty ? displayName : null,
      );
      
      // Sync metadata to public.profiles table if user is available
      await StorageService().syncProfile();

      if (mounted) {
        widget.onSwitchToLogin();
      }
    } on AuthException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (e) {
      setState(() => _errorMessage = 'An unexpected error occurred');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Text(
                  _errorMessage!,
                  style: GoogleFonts.dmSans(color: Colors.redAccent),
                  textAlign: TextAlign.center,
                ),
              ),
            _buildTextField(
              controller: _nameController,
              label: 'Display Name',
              icon: Icons.person_outline,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _emailController,
              label: 'Email Address',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _passwordController,
              label: 'Password',
              icon: Icons.lock_outline,
              obscureText: true,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _confirmController,
              label: 'Confirm Password',
              icon: Icons.lock_outline,
              obscureText: true,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _signup,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isLoading
                  ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Sign Up'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    TextInputType? keyboardType,
  }) {
    final theme = Theme.of(context);
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: GoogleFonts.dmSans(color: theme.textTheme.bodyLarge?.color),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 22),
        filled: true,
        fillColor: theme.colorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      validator: (value) => value != null && value.isNotEmpty ? null : 'Required',
    );
  }
}
