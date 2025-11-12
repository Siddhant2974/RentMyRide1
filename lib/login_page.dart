import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _isRegister = false;
  bool _loading = false;
  final _emailCtl = TextEditingController();
  final _passCtl = TextEditingController();
  final _nameCtl = TextEditingController();

  void _showSnack(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _submit() async {
    final email = _emailCtl.text.trim();
    final pass = _passCtl.text;
    final name = _nameCtl.text.trim();
    if (email.isEmpty || pass.isEmpty || (_isRegister && name.isEmpty)) {
      _showSnack('Please fill required fields');
      return;
    }
    setState(() => _loading = true);
    try {
      if (_isRegister) {
        final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: pass,
        );
        await cred.user?.updateDisplayName(name);
      } else {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: pass,
        );
      }
      // On success navigate to app root (AuthGate will show MainScreen)
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/');
    } on FirebaseAuthException catch (e) {
      _showSnack(e.message ?? e.code);
    } catch (e) {
      _showSnack('Error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signInAnonymously(BuildContext context) async {
    setState(() => _loading = true);
    try {
      await FirebaseAuth.instance.signInAnonymously();
      // Navigate to main screen via named route so we avoid circular imports
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/main');
    } on FirebaseAuthException catch (e) {
      final msg = e.code == 'operation-not-allowed'
          ? 'Anonymous sign-in is disabled in Firebase. Enable it in Console → Authentication → Sign-in method → Anonymous.'
          : (e.message ?? 'Sign in failed: ${e.code}');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Sign in failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _emailCtl.dispose();
    _passCtl.dispose();
    _nameCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primary = Colors.orange;
    return Scaffold(
      backgroundColor: Color(0xFFF6F8FA),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Card(
              elevation: 10,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: primary,
                          child: Icon(
                            Icons.directions_car,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'RentMyRide',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              _isRegister
                                  ? 'Create your account'
                                  : 'Welcome back',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: 18),
                    if (_isRegister)
                      TextField(
                        controller: _nameCtl,
                        decoration: InputDecoration(
                          prefixIcon: Icon(Icons.person),
                          hintText: 'Full name',
                        ),
                      ),
                    if (_isRegister) SizedBox(height: 12),
                    TextField(
                      controller: _emailCtl,
                      decoration: InputDecoration(
                        prefixIcon: Icon(Icons.email),
                        hintText: 'Email',
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    SizedBox(height: 12),
                    TextField(
                      controller: _passCtl,
                      decoration: InputDecoration(
                        prefixIcon: Icon(Icons.lock),
                        hintText: 'Password',
                      ),
                      obscureText: true,
                    ),
                    SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 14),
                          child: _loading
                              ? SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  _isRegister ? 'Create account' : 'Sign in',
                                  style: TextStyle(fontSize: 16),
                                ),
                        ),
                      ),
                    ),
                    SizedBox(height: 12),
                    TextButton(
                      onPressed: _loading
                          ? null
                          : () {
                              setState(() => _isRegister = !_isRegister);
                            },
                      child: Text(
                        _isRegister
                            ? 'Have an account? Sign in'
                            : 'New here? Create an account',
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Or continue with',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                    SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          onPressed: () =>
                              _showSnack('Google sign-in not implemented'),
                          icon: Icon(
                            Icons.g_mobiledata,
                            color: primary,
                            size: 30,
                          ),
                        ),
                        SizedBox(width: 12),
                        IconButton(
                          onPressed: () =>
                              _showSnack('Apple sign-in not implemented'),
                          icon: Icon(
                            Icons.apple,
                            color: Colors.black,
                            size: 26,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.login),
                      label: const Text('Sign in anonymously'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueGrey,
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      onPressed: () => _signInAnonymously(context),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
