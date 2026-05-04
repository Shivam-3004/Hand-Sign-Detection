import 'package:flutter/material.dart';
import 'package:handsingdetection/theme/app_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server/gmail.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();
  final TextEditingController _occupationController = TextEditingController();
  final TextEditingController _feedbackController = TextEditingController();

  int _selectedRating = 0;
  bool _isLoading = false; // ← added

  Future<void> _submitFeedback() async {
    if (_feedbackController.text.trim().isEmpty) return;

    setState(() => _isLoading = true);

    try {
      // Save to Firestore
      await FirebaseFirestore.instance.collection('feedback').add({
        'name': _nameController.text,
        'country': _countryController.text,
        'occupation': _occupationController.text,
        'rating': _selectedRating,
        'feedback': _feedbackController.text,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Send email
      final smtpServer = gmail('detectionhandsign@gmail.com', 'axle bsqj kkiz amuo');
      final message = Message()
        ..from = Address('detectionhandsign@gmail.com', 'GestureAI')
        ..recipients.add('detectionhandsign@gmail.com')
        ..subject = 'New Feedback from ${_nameController.text}'
        ..text = '''
Name: ${_nameController.text}
Country: ${_countryController.text}
Occupation: ${_occupationController.text}
Rating: $_selectedRating

Feedback:
${_feedbackController.text}
        ''';

      await send(message, smtpServer);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Feedback submitted successfully!")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to send: $e")),
        );
      }
    } finally {
      setState(() => _isLoading = false);
      _nameController.clear();
      _countryController.clear();
      _occupationController.clear();
      _feedbackController.clear();
      setState(() => _selectedRating = 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [c.gradStart, c.gradMid, c.gradEnd],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // Header
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: c.bgCard,
                          shape: BoxShape.circle,
                          border: Border.all(color: c.border),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new, size: 16),
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      'Feedback',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Input Fields
                _inputField("Name", _nameController),
                const SizedBox(height: 12),

                _inputField("Country", _countryController),
                const SizedBox(height: 12),

                _inputField("Occupation", _occupationController),
                const SizedBox(height: 20),

                // Rating
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(5, (index) {
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedRating = index + 1;
                        });
                      },
                      child: Icon(
                        Icons.star,
                        size: 32,
                        color: index < _selectedRating
                            ? Colors.amber
                            : Colors.grey,
                      ),
                    );
                  }),
                ),

                const SizedBox(height: 20),

                // Feedback Text
                TextField(
                  controller: _feedbackController,
                  maxLines: 5,
                  decoration: InputDecoration(
                    hintText: "Write feedback...",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // Send Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _submitFeedback,
                    icon: _isLoading
                        ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                        : const Icon(Icons.send),
                    label: Text(_isLoading ? "Sending..." : "Send Feedback"),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _inputField(String hint, TextEditingController controller) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}