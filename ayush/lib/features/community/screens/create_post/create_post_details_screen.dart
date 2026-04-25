import 'dart:io';
import 'package:flutter/material.dart';
import 'create_post_location_screen.dart';

class CreatePostDetailsScreen extends StatefulWidget {
  final List<File> photos;
  final String? prefilledPlantName;

  const CreatePostDetailsScreen({
    super.key,
    required this.photos,
    this.prefilledPlantName,
  });

  @override
  State<CreatePostDetailsScreen> createState() => _CreatePostDetailsScreenState();
}

class _CreatePostDetailsScreenState extends State<CreatePostDetailsScreen> {
  late final TextEditingController _plantNameCtrl;
  final TextEditingController _descCtrl = TextEditingController();
  final TextEditingController _whatsappCtrl = TextEditingController();
  String? _availability;
  String _contactPreference = 'in_app';
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _plantNameCtrl = TextEditingController(text: widget.prefilledPlantName ?? '');
  }

  @override
  void dispose() {
    _plantNameCtrl.dispose();
    _descCtrl.dispose();
    _whatsappCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1F3C),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('Plant Details',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
            Text('Step 2 of 3',
                style: TextStyle(color: Colors.white38, fontSize: 12)),
          ],
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionLabel('Plant Name'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _plantNameCtrl,
                hint: 'e.g. Tulsi, Neem, Aloe Vera',
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),

              const SizedBox(height: 20),
              _sectionLabel('Description'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _descCtrl,
                hint: 'Describe the plant, its condition, quantity available...',
                maxLines: 4,
                maxLength: 300,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),

              const SizedBox(height: 20),
              _sectionLabel('Availability'),
              const SizedBox(height: 10),
              Row(
                children: [
                  _availabilityChip('few', '🟡 Few', const Color(0xFFf4a261)),
                  const SizedBox(width: 8),
                  _availabilityChip('moderate', '🔵 Moderate', const Color(0xFF457b9d)),
                  const SizedBox(width: 8),
                  _availabilityChip('abundant', '🟢 Abundant', const Color(0xFF2d6a4f)),
                ],
              ),
              if (_availability == null)
                const Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: Text('Please select availability',
                      style: TextStyle(color: Colors.redAccent, fontSize: 12)),
                ),

              const SizedBox(height: 24),
              _sectionLabel('How should people contact you?'),
              const SizedBox(height: 8),
              _contactOption('in_app', '📨 In-app message'),
              _contactOption('whatsapp', '💬 WhatsApp'),
              _contactOption('none', '🚫 Do not contact'),

              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                child: _contactPreference == 'whatsapp'
                    ? Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: _buildTextField(
                          controller: _whatsappCtrl,
                          hint: '+91 9876543210',
                          label: 'WhatsApp number',
                          keyboardType: TextInputType.phone,
                        ),
                      )
                    : const SizedBox.shrink(),
              ),

              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _submit,
                  child: const Text('Next: Confirm Location →', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(
    text,
    style: const TextStyle(color: Colors.white60, fontSize: 12, letterSpacing: 0.5),
  );

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    String? label,
    int maxLines = 1,
    int? maxLength,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) =>
      TextFormField(
        controller: controller,
        maxLines: maxLines,
        maxLength: maxLength,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white),
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white38),
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white24),
          counterStyle: const TextStyle(color: Colors.white38),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.white24),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF4CAF50)),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.redAccent),
          ),
          filled: true,
          fillColor: const Color(0xFF1E3A5F),
        ),
      );

  Widget _availabilityChip(String value, String label, Color color) {
    final selected = _availability == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _availability = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? color.withOpacity(0.3) : const Color(0xFF1E3A5F),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: selected ? color : Colors.white24),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? Colors.white : Colors.white54,
              fontSize: 13,
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _contactOption(String value, String label) {
    return RadioListTile<String>(
      value: value,
      groupValue: _contactPreference,
      activeColor: const Color(0xFF4CAF50),
      title: Text(label, style: const TextStyle(color: Colors.white70, fontSize: 14)),
      contentPadding: EdgeInsets.zero,
      dense: true,
      onChanged: (v) => setState(() => _contactPreference = v!),
    );
  }

  void _submit() {
    if (_formKey.currentState?.validate() != true) return;
    if (_availability == null) {
      setState(() {}); // trigger validation display
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreatePostLocationScreen(
          photos: widget.photos,
          plantName: _plantNameCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          availability: _availability!,
          contactPreference: _contactPreference,
          whatsappNumber: _contactPreference == 'whatsapp'
              ? _whatsappCtrl.text.trim()
              : null,
        ),
      ),
    );
  }
}
