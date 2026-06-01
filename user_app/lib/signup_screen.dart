import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'auth_provider.dart';
import 'login_screen.dart';
import 'app_theme.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen>
    with SingleTickerProviderStateMixin {
  final _formKey           = GlobalKey<FormState>();
  final nameController     = TextEditingController();
  final emailController    = TextEditingController();
  final passwordController = TextEditingController();
  final budgetController   = TextEditingController();   // ← NEW

  bool _obscurePassword = true;

  late AnimationController _animController;
  late Animation<double>   _fadeAnim;
  late Animation<Offset>   _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve:  Curves.easeOut,
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end:   Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    budgetController.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────────────────
  Future<void> signUpUser() async {
    if (!_formKey.currentState!.validate()) return;

    final budgetLimit = double.tryParse(budgetController.text.trim()) ?? 0;

    final user = await Provider.of<AuthProvider>(context, listen: false).signUp(
      name:        nameController.text.trim(),
      email:       emailController.text.trim(),
      password:    passwordController.text.trim(),
      budgetLimit: budgetLimit,
    );

    if (!mounted) return;

    if (user != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account Created!')),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Signup Failed')),
      );
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      body: OrbBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),

                      // ── Back button ──────────────────────────────────────
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.elevated,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: AppColors.border,
                              width: 1.2,
                            ),
                          ),
                          child: const Icon(
                            Icons.arrow_back_rounded,
                            color: AppColors.textPrimary,
                            size: 20,
                          ),
                        ),
                      ),

                      const SizedBox(height: 36),

                      // ── Headline ─────────────────────────────────────────
                      const Text(
                        "Create account",
                        style: TextStyle(
                          color:       AppColors.textPrimary,
                          fontSize:    32,
                          fontWeight:  FontWeight.w800,
                          letterSpacing: -0.8,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        "Start tracking your expenses today",
                        style: TextStyle(
                          color:    AppColors.textSecondary,
                          fontSize: 15,
                        ),
                      ),

                      const SizedBox(height: 44),

                      // ── Full name ─────────────────────────────────────────
                      TextFormField(
                        controller: nameController,
                        keyboardType: TextInputType.name,
                        textCapitalization: TextCapitalization.words,
                        style: const TextStyle(color: AppColors.textPrimary),
                        decoration: appInputDecoration(
                          label: "Full name",
                          prefixIcon: const Icon(
                            Icons.person_outline_rounded,
                            color: AppColors.textSecondary,
                            size: 20,
                          ),
                        ),
                        validator: (v) =>
                            (v == null || v.isEmpty) ? "Enter your name" : null,
                      ),

                      const SizedBox(height: 16),

                      // ── Email ─────────────────────────────────────────────
                      TextFormField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(color: AppColors.textPrimary),
                        decoration: appInputDecoration(
                          label: "Email address",
                          prefixIcon: const Icon(
                            Icons.alternate_email_rounded,
                            color: AppColors.textSecondary,
                            size: 20,
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return "Enter email";
                          if (!v.contains("@")) return "Enter valid email";
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // ── Password ──────────────────────────────────────────
                      TextFormField(
                        controller: passwordController,
                        obscureText: _obscurePassword,
                        style: const TextStyle(color: AppColors.textPrimary),
                        decoration: appInputDecoration(
                          label: "Password",
                          prefixIcon: const Icon(
                            Icons.lock_outline_rounded,
                            color: AppColors.textSecondary,
                            size: 20,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: AppColors.textSecondary,
                              size: 20,
                            ),
                            onPressed: () =>
                                setState(() => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return "Enter password";
                          if (v.length < 6) return "Minimum 6 characters";
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // ── Monthly Budget Limit (NEW) ─────────────────────────
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextFormField(
                            controller: budgetController,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                  RegExp(r'^\d+\.?\d{0,2}')),
                            ],
                            style: const TextStyle(color: AppColors.textPrimary),
                            decoration: appInputDecoration(
                              label: "Monthly budget limit (Rs)",
                              prefixIcon: const Icon(
                                Icons.account_balance_wallet_outlined,
                                color: AppColors.textSecondary,
                                size: 20,
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) {
                                return "Enter your monthly budget";
                              }
                              final val = double.tryParse(v);
                              if (val == null || val <= 0) {
                                return "Enter a valid amount";
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            "  You can change this later from the Dashboard.",
                            style: TextStyle(
                              color:    AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 36),

                      // ── Create Account button ─────────────────────────────
                      authProvider.isLoading
                          ? const Center(
                              child: SizedBox(
                                width:  26,
                                height: 26,
                                child: CircularProgressIndicator(
                                  color:       AppColors.primary,
                                  strokeWidth: 2.5,
                                ),
                              ),
                            )
                          : GradientButton(
                              onPressed: signUpUser,
                              child: const Text(
                                "Create Account",
                                style: TextStyle(
                                  color:         Colors.white,
                                  fontSize:      16,
                                  fontWeight:    FontWeight.w700,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),

                      const SizedBox(height: 28),

                      // ── Sign in link ──────────────────────────────────────
                      Center(
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: RichText(
                            text: const TextSpan(
                              text: "Already have an account?  ",
                              style: TextStyle(
                                color:    AppColors.textSecondary,
                                fontSize: 14,
                              ),
                              children: [
                                TextSpan(
                                  text: "Sign in",
                                  style: TextStyle(
                                    color:      AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
