import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Current Month Budget Tracker',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Current Month Budget Tracker')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 300,
              height: 100,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.all(20),
                  textStyle: const TextStyle(fontSize: 22, color: Colors.white),
                ),
                onPressed: () async {
                  bool expenseAdded = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddExpenseScreen(),
                    ),
                  );
                },
                child: const Text('LISA KULU', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: 300,
              height: 100,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.all(20),
                  textStyle: const TextStyle(fontSize: 22, color: Colors.white),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ViewExpensesScreen()),
                  );
                },
                child: const Text('VAATA KULUSID', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({Key? key}) : super(key: key);

  @override
  _AddExpenseScreenState createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final TextEditingController _amountController = TextEditingController();
  String _selectedCategory = 'Toit';
  final List<String> _categories = ['Toit', 'Transport', 'Meelelahutus', 'Arved', 'Riided', 'Olme', 'Muu'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Lisa kulu')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'Summa (€)')
            ),
            SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              items: _categories.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value!;
                });
              },
              decoration: InputDecoration(labelText: 'Kategooria'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                if (_amountController.text.isNotEmpty) {
                  double amount = double.parse(_amountController.text);
                  try {
                    await addExpenseToFirebase(amount, _selectedCategory);

                    Navigator.pop(context, true);

                    _amountController.clear();
                  } catch (e) {
                    Navigator.pop(context, false);
                  }
                } else {
                  Navigator.pop(context, false);
                }
              },
              child: Text('Lisa kulu'),
            )
          ],
        ),
      ),
    );
  }

  Future<void> addExpenseToFirebase(double amount, String category) async {
    try {
      var now = DateTime.now();
      await FirebaseFirestore.instance.collection('expenses').add({
        'amount': amount,
        'category': category,
        'timestamp': Timestamp.now(),
        'year': now.year,
        'month': now.month,
      });
    } catch (e) {
      rethrow;
    }
  }
}

class ViewExpensesScreen extends StatelessWidget {
  const ViewExpensesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Vaata kulusid'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: DatabaseHelper().getExpenses(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('Kulud puuduvad.'));
          } else {
            var expenses = snapshot.data!;

            Map<String, double> categorySums = {};
            String monthYear = DateFormat('MMMM yyyy').format(DateTime.now());

            for (var expense in expenses) {
              categorySums[expense['category']] = (categorySums[expense['category']] ?? 0) + expense['amount'];

              if (expense['timestamp'] != null) {
                DateTime timestamp = expense['timestamp'].toDate();
                monthYear = DateFormat('MMMM yyyy').format(timestamp);
              }
            }

            var sortedCategories = categorySums.keys.toList()
              ..sort((a, b) => categorySums[b]!.compareTo(categorySums[a]!));

            return ListView(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: Text(
                    'Kuu: $monthYear',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ),
                ...sortedCategories.map((category) {
                  double totalAmount = categorySums[category]!;

                  Color categoryColor = _getCategoryColor(category).withOpacity(0.5);

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => CategoryDetailScreen(category: category)),
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: categoryColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.all(16),
                      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            category,
                            style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '${totalAmount.toStringAsFixed(2)} €',
                            style: TextStyle(color: Colors.black),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ],
            );
          }
        },
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Toit':
        return Colors.green;
      case 'Transport':
        return Colors.blue;
      case 'Meelelahutus':
        return Colors.purple;
      case 'Arved':
        return Colors.red;
      case 'Riided':
        return Colors.orange;
      case 'Olme':
        return Colors.brown;
      case 'Muu':
        return Colors.grey;
      default:
        return Colors.blueGrey;
    }
  }
}





class CategoryDetailScreen extends StatelessWidget {
  final String category;

  const CategoryDetailScreen({Key? key, required this.category}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Kategooria: $category')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: DatabaseHelper().getExpensesForCategory(category),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('Kulud puuduvad.'));
          } else {
            var expenses = snapshot.data!;

            return ListView.builder(
              itemCount: expenses.length,
              itemBuilder: (context, index) {
                var expense = expenses[index];
                return ListTile(
                  title: Text('${expense['amount']} €', style: TextStyle(color: Colors.black)),
                  subtitle: Text(expense['category'], style: TextStyle(color: Colors.black)),
                );
              },
            );
          }
        },
      ),
    );
  }
}


class DatabaseHelper {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<List<Map<String, dynamic>>> getExpenses() async {
    try {
      var now = DateTime.now();
      var firstDayOfMonth = DateTime(now.year, now.month, 1);
      var lastDayOfMonth = DateTime(now.year, now.month + 1, 0);

      var querySnapshot = await _db
          .collection('expenses')
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(firstDayOfMonth))
          .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(lastDayOfMonth))
          .get();

      return querySnapshot.docs.map((doc) {
        return {
          'amount': doc['amount'],
          'category': doc['category'],
        };
      }).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getExpensesForCategory(String category) async {
    try {
      var now = DateTime.now();
      var firstDayOfMonth = DateTime(now.year, now.month, 1);
      var lastDayOfMonth = DateTime(now.year, now.month + 1, 0);

      var querySnapshot = await _db
          .collection('expenses')
          .where('category', isEqualTo: category)
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(firstDayOfMonth))
          .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(lastDayOfMonth))
          .orderBy('timestamp', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        return {
          'amount': doc['amount'],
          'category': doc['category'],
        };
      }).toList();
    } catch (e) {
      return [];
    }
  }
}