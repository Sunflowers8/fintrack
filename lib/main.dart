import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasData) return const DashboardScreen();
          return const LoginScreen();
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
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isRegister = false;
  String? _error;

  Future<void> _submit() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      if (_isRegister) {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      } else {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _error = e.message);
    }
    setState(() => _isLoading = false);
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
              const Icon(Icons.account_balance_wallet, size: 80, color: Colors.teal),
              const SizedBox(height: 12),
              const Text('FinTrack', style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.teal)),
              const Text('Personal Budget Tracker', style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 40),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder(), prefixIcon: Icon(Icons.email)),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder(), prefixIcon: Icon(Icons.lock)),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(color: Colors.red)),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(_isRegister ? 'Register' : 'Login', style: const TextStyle(fontSize: 16)),
                ),
              ),
              TextButton(
                onPressed: () => setState(() => _isRegister = !_isRegister),
                child: Text(_isRegister ? 'Already have an account? Login' : "Don't have an account? Register"),
              ),
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
    final screens = [
      const HomeTab(),
      const AddTransactionScreen(),
      const ReportsScreen(),
    ];
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

  Stream<List<Map<String, dynamic>>> get _txStream => FirebaseFirestore.instance
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
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => FirebaseAuth.instance.signOut(),
          )
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _txStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final transactions = snapshot.data ?? [];
          final income = transactions.where((t) => t['type'] == 'income').fold(0.0, (s, t) => s + (t['amount'] as num).toDouble());
          final expense = transactions.where((t) => t['type'] == 'expense').fold(0.0, (s, t) => s + (t['amount'] as num).toDouble());
          final savings = income - expense;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // KPI Cards
                Row(children: [
                  _KpiCard('Income', income, Colors.green, Icons.arrow_upward),
                  const SizedBox(width: 8),
                  _KpiCard('Expense', expense, Colors.red, Icons.arrow_downward),
                  const SizedBox(width: 8),
                  _KpiCard('Savings', savings, Colors.teal, Icons.savings),
                ]),
                const SizedBox(height: 20),
                if (transactions.isNotEmpty) ...[
                  const Text('Expense Breakdown', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _ExpenseBarChart(transactions: transactions),
                  const SizedBox(height: 20),
                ],
                const Text('Recent Transactions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                if (transactions.isEmpty)
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
                  ...transactions.take(5).map((t) => _TransactionTile(transaction: t)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _KpiCard(String label, double amount, Color color, IconData icon) {
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
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
        ]),
      ),
    );
  }
}

// ── EXPENSE BAR CHART ─────────────────────────────────────
class _ExpenseBarChart extends StatelessWidget {
  final List<Map<String, dynamic>> transactions;
  const _ExpenseBarChart({required this.transactions});

  @override
  Widget build(BuildContext context) {
    final Map<String, double> totals = {};
    for (var t in transactions.where((t) => t['type'] == 'expense')) {
      totals[t['category']] = (totals[t['category']] ?? 0) + (t['amount'] as num).toDouble();
    }
    final maxVal = totals.values.isEmpty ? 1.0 : totals.values.reduce((a, b) => a > b ? a : b);
    final colors = [Colors.red, Colors.orange, Colors.blue, Colors.purple, Colors.teal];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: totals.entries.toList().asMap().entries.map((entry) {
          final color = colors[entry.key % colors.length];
          final cat = entry.value.key;
          final val = entry.value.value;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(children: [
              SizedBox(width: 90, child: Text(cat, style: const TextStyle(fontSize: 12))),
              Expanded(
                child: Stack(children: [
                  Container(height: 20, decoration: BoxDecoration(
                    color: Colors.grey.shade200, borderRadius: BorderRadius.circular(4))),
                  FractionallySizedBox(
                    widthFactor: val / maxVal,
                    child: Container(height: 20, decoration: BoxDecoration(
                      color: color, borderRadius: BorderRadius.circular(4))),
                  ),
                ]),
              ),
              const SizedBox(width: 8),
              Text('Rs ${val.toStringAsFixed(0)}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
            ]),
          );
        }).toList(),
      ),
    );
  }
}

// ── TRANSACTION TILE ──────────────────────────────────────
class _TransactionTile extends StatelessWidget {
  final Map<String, dynamic> transaction;
  const _TransactionTile({required this.transaction});

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
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  String _type = 'expense';
  String _category = 'Food';
  bool _isLoading = false;

  final _categories = ['Food', 'Housing', 'Transport', 'Health', 'Entertainment', 'Salary', 'Freelance', 'Other'];

  Future<void> _submit() async {
    if (_titleController.text.isEmpty || _amountController.text.isEmpty) return;
    setState(() => _isLoading = true);
    final uid = FirebaseAuth.instance.currentUser!.uid;
    await FirebaseFirestore.instance
        .collection('users').doc(uid).collection('transactions')
        .add({
      'title': _titleController.text,
      'amount': double.tryParse(_amountController.text) ?? 0,
      'type': _type,
      'category': _category,
      'date': DateTime.now().toString().substring(0, 10),
    });
    _titleController.clear();
    _amountController.clear();
    setState(() => _isLoading = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transaction saved to Firebase! ✅'), backgroundColor: Colors.teal),
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
              _TypeButton('Income', Icons.arrow_upward, Colors.green, _type == 'income', () => setState(() => _type = 'income')),
              const SizedBox(width: 12),
              _TypeButton('Expense', Icons.arrow_downward, Colors.red, _type == 'expense', () => setState(() => _type = 'expense')),
            ]),
            const SizedBox(height: 20),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder(), prefixIcon: Icon(Icons.title)),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _amountController,
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
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _submit,
                icon: const Icon(Icons.add),
                label: Text(_isLoading ? 'Saving...' : 'Add Transaction', style: const TextStyle(fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _TypeButton(String label, IconData icon, Color color, bool selected, VoidCallback onTap) {
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
            .orderBy('date', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data?.docs ?? [];
          final transactions = docs.map((d) => {...(d.data() as Map<String, dynamic>), 'id': d.id}).toList();
          final income = transactions.where((t) => t['type'] == 'income').fold(0.0, (s, t) => s + (t['amount'] as num).toDouble());
          final expense = transactions.where((t) => t['type'] == 'expense').fold(0.0, (s, t) => s + (t['amount'] as num).toDouble());
          final savingsRate = income > 0 ? (income - expense) / income * 100 : 0.0;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Summary Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Colors.teal, Colors.tealAccent],
                        begin: Alignment.topLeft, end: Alignment.bottomRight),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Monthly Summary', style: TextStyle(color: Colors.white70, fontSize: 14)),
                    const SizedBox(height: 8),
                    Text('Rs ${(income - expense).toStringAsFixed(0)} saved',
                        style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Row(children: [
                      _StatChip('Income', 'Rs ${income.toStringAsFixed(0)}'),
                      const SizedBox(width: 8),
                      _StatChip('Expense', 'Rs ${expense.toStringAsFixed(0)}'),
                      const SizedBox(width: 8),
                      _StatChip('Saved', '${savingsRate.toStringAsFixed(1)}%'),
                    ]),
                  ]),
                ),
                const SizedBox(height: 20),
                const Text('All Transactions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                if (transactions.isEmpty)
                  const Center(child: Padding(
                    padding: EdgeInsets.all(40),
                    child: Text('No transactions yet.', style: TextStyle(color: Colors.grey)),
                  ))
                else
                  ...transactions.map((t) => _TransactionTile(transaction: t)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _StatChip(String label, String value) {
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