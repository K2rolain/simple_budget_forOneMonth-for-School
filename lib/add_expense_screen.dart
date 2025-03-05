import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
    var now = DateTime.now();
    await FirebaseFirestore.instance.collection('expenses').add({
      'amount': amount,
      'category': category,
      'timestamp': Timestamp.now(),
      'year': now.year,
      'month': now.month,
    });
  }
}
