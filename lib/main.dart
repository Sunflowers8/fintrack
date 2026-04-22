import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'firebase_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: firebaseOptions);
  runApp(const FinTrackApp());
}

class FinTrackApp extends StatelessWidget {
  const FinTrackApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FinTrack',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          return snapshot.hasData ? const DashboardScreen() : const LoginScreen();
        },
      ),
    );
  }
}

// ── LOGIN SCREEN ──────────────────────────────────────────
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  bool _isLoading = false;
  bool _isRegister = false;
  String? _error;
  String? _success;

  Future<void> _submit() async {
    setState(() { _isLoading = true; _error = null; _success = null; });

    // Validation
    if (_emailCtrl.text.trim().isEmpty || _passCtrl.text.trim().isEmpty) {
      setState(() { _error = 'Please fill in all fields.'; _isLoading = false; });
      return;
    }

    if (_isRegister && _passCtrl.text != _confirmPassCtrl.text) {
      setState(() { _error = 'Passwords do not match.'; _isLoading = false; });
      return;
    }

    if (_isRegister && _passCtrl.text.length < 6) {
      setState(() { _error = 'Password must be at least 6 characters.'; _isLoading = false; });
      return;
    }

    try {
      if (_isRegister) {
        // Register user
        UserCredential cred = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
          email: _emailCtrl.text.trim(),
          password: _passCtrl.text.trim(),
        );
        // Send email verification
        await cred.user!.sendEmailVerification();
        setState(() {
          _success = '✅ Account created! A verification email has been sent to ${_emailCtrl.text.trim()}. Please verify before logging in.';
          _isRegister = false;
        });
      } else {
        // Login
        UserCredential cred = await FirebaseAuth.instance
            .signInWithEmailAndPassword(
          email: _emailCtrl.text.trim(),
          password: _passCtrl.text.trim(),
        );
        // Check if email is verified
        if (!cred.user!.emailVerified) {
          await FirebaseAuth.instance.signOut();
          setState(() {
            _error = '⚠️ Please verify your email first. Check your inbox for the verification link.';
          });
        }
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _error = e.message);
    }
    setState(() => _isLoading = false);
  }

  Future<void> _forgotPassword() async {
    if (_emailCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Please enter your email address first.');
      return;
    }
    try {
      await FirebaseAuth.instance
          .sendPasswordResetEmail(email: _emailCtrl.text.trim());
      setState(() {
        _success = '📧 Password reset email sent to ${_emailCtrl.text.trim()}. Check your inbox!';
        _error = null;
      });
    } on FirebaseAuthException catch (e) {
      setState(() => _error = e.message);
    }
  }

  Future<void> _resendVerification() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
        setState(() => _success = '📧 Verification email resent to ${user.email}');
      } else {
        // Sign in temporarily to resend
        UserCredential cred = await FirebaseAuth.instance
            .signInWithEmailAndPassword(
          email: _emailCtrl.text.trim(),
          password: _passCtrl.text.trim(),
        );
        if (!cred.user!.emailVerified) {
          await cred.user!.sendEmailVerification();
          await FirebaseAuth.instance.signOut();
          setState(() => _success = '📧 Verification email resent!');
        }
      }
    } catch (e) {
      setState(() => _error = 'Enter your email and password then try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.teal.shade50,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.teal.shade100,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.account_balance_wallet, size: 60, color: Colors.teal),
              ),
              const SizedBox(height: 16),
              const Text('FinTrack',
                  style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.teal)),
              const Text('Personal Budget Tracker',
                  style: TextStyle(color: Colors.grey, fontSize: 14)),
              const SizedBox(height: 32),

              // Toggle Login / Register
              Container(
                decoration: BoxDecoration(
                  color: Colors.teal.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() { _isRegister = false; _error = null; _success = null; }),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: !_isRegister ? Colors.teal : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text('Login',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: !_isRegister ? Colors.white : Colors.teal,
                            fontWeight: FontWeight.bold,
                          )),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() { _isRegister = true; _error = null; _success = null; }),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _isRegister ? Colors.teal : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text('Register',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _isRegister ? Colors.white : Colors.teal,
                            fontWeight: FontWeight.bold,
                          )),
                      ),
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 24),

              // Email field
              TextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.email),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 16),

              // Password field
              TextField(
                controller: _passCtrl,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),

              // Confirm password (register only)
              if (_isRegister) ...[
                const SizedBox(height: 16),
                TextField(
                  controller: _confirmPassCtrl,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock_outline),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
              ],

              // Forgot password (login only)
              if (!_isRegister) ...[
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _forgotPassword,
                    child: const Text('Forgot Password?', style: TextStyle(color: Colors.teal)),
                  ),
                ),
              ] else
                const SizedBox(height: 12),

              // Error message
              if (_error != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 18),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13))),
                  ]),
                ),

              // Success message
              if (_success != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(children: [
                    const Icon(Icons.check_circle_outline, color: Colors.green, size: 18),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_success!, style: const TextStyle(color: Colors.green, fontSize: 13))),
                  ]),
                ),

              const SizedBox(height: 16),

              // Main button
              SizedBox(
                width: double.infinity, height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(_isRegister ? '📝 Create Account' : '🔐 Login',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),

              // Resend verification
              if (!_isRegister) ...[
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _resendVerification,
                  child: const Text("Didn't receive verification email? Resend",
                      style: TextStyle(color: Colors.grey, fontSize: 12)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── DASHBOARD SCREEN ──────────────────────────────────────
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [const HomeTab(), const AddTransactionScreen(), const ReportsScreen()];
    return Scaffold(
      body: screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.add_circle), label: 'Add'),
          NavigationDestination(icon: Icon(Icons.bar_chart), label: 'Reports'),
        ],
      ),
    );
  }
}

// ── HOME TAB ──────────────────────────────────────────────
class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  Stream<List<Map<String, dynamic>>> get _txStream =>
      FirebaseFirestore.instance
          .collection('users').doc(_uid).collection('transactions')
          .orderBy('date', descending: true)
          .snapshots()
          .map((s) => s.docs.map((d) => {...d.data(), 'id': d.id}).toList());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FinTrack 💰', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.logout),
              onPressed: () => FirebaseAuth.instance.signOut()),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _txStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final tx = snapshot.data ?? [];
          final income = tx.where((t) => t['type'] == 'income')
              .fold(0.0, (s, t) => s + (t['amount'] as num).toDouble());
          final expense = tx.where((t) => t['type'] == 'expense')
              .fold(0.0, (s, t) => s + (t['amount'] as num).toDouble());

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // KPI Cards
                Row(children: [
                  _kpiCard('Income', income, Colors.green, Icons.arrow_upward),
                  const SizedBox(width: 8),
                  _kpiCard('Expense', expense, Colors.red, Icons.arrow_downward),
                  const SizedBox(width: 8),
                  _kpiCard('Savings', income - expense, Colors.teal, Icons.savings),
                ]),
                const SizedBox(height: 24),

                if (tx.isNotEmpty) ...[
                  // PIE CHART
                  const Text('Expense by Category',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  FinPieChart(transactions: tx),
                  const SizedBox(height: 24),

                  // BAR CHART
                  const Text('Income vs Expense',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  FinBarChart(income: income, expense: expense),
                  const SizedBox(height: 24),
                ],

                // Recent Transactions
                const Text('Recent Transactions',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                if (tx.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: Column(children: [
                        Icon(Icons.receipt_long, size: 60, color: Colors.grey),
                        SizedBox(height: 12),
                        Text('No transactions yet.\nTap Add to get started!',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey)),
                      ]),
                    ),
                  )
                else
                  ...tx.take(5).map((t) => TransactionTile(transaction: t)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _kpiCard(String label, double amount, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 11, color: color)),
          Text('Rs ${amount.toStringAsFixed(0)}',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
        ]),
      ),
    );
  }
}

// ── PIE CHART ─────────────────────────────────────────────
class FinPieChart extends StatelessWidget {
  final List<Map<String, dynamic>> transactions;
  const FinPieChart({super.key, required this.transactions});

  @override
  Widget build(BuildContext context) {
    final Map<String, double> totals = {};
    for (var t in transactions.where((t) => t['type'] == 'expense')) {
      totals[t['category']] = (totals[t['category']] ?? 0) + (t['amount'] as num).toDouble();
    }

    if (totals.isEmpty) return const SizedBox();

    final colors = [Colors.red, Colors.orange, Colors.blue, Colors.purple, Colors.teal, Colors.green];
    final entries = totals.entries.toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 8)],
      ),
      child: Column(
        children: [
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 40,
                sections: entries.asMap().entries.map((e) {
                  final color = colors[e.key % colors.length];
                  final total = totals.values.reduce((a, b) => a + b);
                  final pct = (e.value.value / total * 100);
                  return PieChartSectionData(
                    color: color,
                    value: e.value.value,
                    title: '${pct.toStringAsFixed(0)}%',
                    radius: 60,
                    titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Legend
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: entries.asMap().entries.map((e) {
              final color = colors[e.key % colors.length];
              return Row(mainAxisSize: MainAxisSize.min, children: [
                Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                const SizedBox(width: 4),
                Text('${e.value.key} (Rs ${e.value.value.toStringAsFixed(0)})',
                    style: const TextStyle(fontSize: 11)),
              ]);
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ── BAR CHART ─────────────────────────────────────────────
class FinBarChart extends StatelessWidget {
  final double income;
  final double expense;
  const FinBarChart({super.key, required this.income, required this.expense});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 8)],
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: (income > expense ? income : expense) * 1.3,
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  switch (value.toInt()) {
                    case 0: return const Text('Income', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green));
                    case 1: return const Text('Expense', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.red));
                    default: return const Text('');
                  }
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          gridData: FlGridData(show: false),
          barGroups: [
            BarChartGroupData(x: 0, barRods: [
              BarChartRodData(
                toY: income,
                color: Colors.green,
                width: 50,
                borderRadius: BorderRadius.circular(6),
              ),
            ]),
            BarChartGroupData(x: 1, barRods: [
              BarChartRodData(
                toY: expense,
                color: Colors.red,
                width: 50,
                borderRadius: BorderRadius.circular(6),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}
// ── TRANSACTION TILE ──────────────────────────────────────
class TransactionTile extends StatelessWidget {
  final Map<String, dynamic> transaction;
  const TransactionTile({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction['type'] == 'income';
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isIncome ? Colors.green.shade100 : Colors.red.shade100,
          child: Icon(isIncome ? Icons.arrow_upward : Icons.arrow_downward,
              color: isIncome ? Colors.green : Colors.red, size: 18),
        ),
        title: Text(transaction['title'], style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('${transaction['category']} • ${transaction['date']}'),
        trailing: Text(
          '${isIncome ? '+' : '-'} Rs ${(transaction['amount'] as num).toStringAsFixed(0)}',
          style: TextStyle(color: isIncome ? Colors.green : Colors.red, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

// ── ADD TRANSACTION SCREEN ────────────────────────────────
class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});
  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _titleCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  String _type = 'expense';
  String _category = 'Food';
  bool _isLoading = false;

  final _categories = ['Food', 'Housing', 'Transport', 'Health', 'Entertainment', 'Salary', 'Freelance', 'Other'];

  Future<void> _submit() async {
    if (_titleCtrl.text.isEmpty || _amountCtrl.text.isEmpty) return;
    setState(() => _isLoading = true);
    final uid = FirebaseAuth.instance.currentUser!.uid;
    await FirebaseFirestore.instance
        .collection('users').doc(uid).collection('transactions')
        .add({
      'title': _titleCtrl.text,
      'amount': double.tryParse(_amountCtrl.text) ?? 0,
      'type': _type,
      'category': _category,
      'date': DateTime.now().toString().substring(0, 10),
    });
    _titleCtrl.clear();
    _amountCtrl.clear();
    setState(() => _isLoading = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Saved to Firebase! ✅'), backgroundColor: Colors.teal),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Transaction', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Transaction Type', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(children: [
              _typeBtn('Income', Icons.arrow_upward, Colors.green, _type == 'income', () => setState(() => _type = 'income')),
              const SizedBox(width: 12),
              _typeBtn('Expense', Icons.arrow_downward, Colors.red, _type == 'expense', () => setState(() => _type = 'expense')),
            ]),
            const SizedBox(height: 20),
            TextField(
              controller: _titleCtrl,
              decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder(), prefixIcon: Icon(Icons.title)),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _amountCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Amount (Rs)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.currency_rupee)),
            ),
            const SizedBox(height: 16),
            const Text('Category', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _category,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => setState(() => _category = v!),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity, height: 50,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _submit,
                icon: const Icon(Icons.add),
                label: Text(_isLoading ? 'Saving...' : 'Add Transaction', style: const TextStyle(fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal, foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _typeBtn(String label, IconData icon, Color color, bool selected, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? color : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: selected ? color : Colors.grey.shade300),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, color: selected ? Colors.white : color, size: 18),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(color: selected ? Colors.white : color, fontWeight: FontWeight.bold)),
          ]),
        ),
      ),
    );
  }
}

// ── REPORTS SCREEN ────────────────────────────────────────
class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users').doc(_uid).collection('transactions')
            .orderBy('date', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data?.docs ?? [];
          final tx = docs.map((d) => {...(d.data() as Map<String, dynamic>), 'id': d.id}).toList();
          final income = tx.where((t) => t['type'] == 'income').fold(0.0, (s, t) => s + (t['amount'] as num).toDouble());
          final expense = tx.where((t) => t['type'] == 'expense').fold(0.0, (s, t) => s + (t['amount'] as num).toDouble());
          final savingsRate = income > 0 ? (income - expense) / income * 100 : 0.0;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.teal, Colors.tealAccent],
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Monthly Summary', style: TextStyle(color: Colors.white70, fontSize: 14)),
                    const SizedBox(height: 8),
                    Text('Rs ${(income - expense).toStringAsFixed(0)} saved',
                        style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Row(children: [
                      _chip('Income', 'Rs ${income.toStringAsFixed(0)}'),
                      const SizedBox(width: 8),
                      _chip('Expense', 'Rs ${expense.toStringAsFixed(0)}'),
                      const SizedBox(width: 8),
                      _chip('Saved', '${savingsRate.toStringAsFixed(1)}%'),
                    ]),
                  ]),
                ),
                const SizedBox(height: 20),
                const Text('All Transactions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                if (tx.isEmpty)
                  const Center(child: Padding(
                    padding: EdgeInsets.all(40),
                    child: Text('No transactions yet.', style: TextStyle(color: Colors.grey)),
                  ))
                else
                  ...tx.map((t) => TransactionTile(transaction: t)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _chip(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(8)),
        child: Column(children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10)),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
        ]),
      ),
    );
  }
}