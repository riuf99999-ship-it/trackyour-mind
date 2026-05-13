import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_state.dart';
import '../utils/constants.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isAuthenticated = false;
  final _pinController = TextEditingController();
  bool _showPinError = false;

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  void _authenticate(String enteredPin, String correctPin) {
    if (enteredPin == correctPin) {
      setState(() {
        _isAuthenticated = true;
        _showPinError = false;
      });
    } else {
      setState(() => _showPinError = true);
    }
    _pinController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Text(
          state.isArabic ? 'إعدادات المشرف' : 'Admin Settings',
          style: const TextStyle(color: AppColors.textPrimary, fontFamily: 'Cairo'),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isAuthenticated
          ? _buildSettingsContent(state)
          : _buildPinScreen(state),
    );
  }

  Widget _buildPinScreen(AppState state) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline, color: AppColors.primary, size: 64),
            const SizedBox(height: 24),
            Text(
              state.isArabic ? 'أدخل رمز المشرف' : 'Enter Admin PIN',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.bold,
                fontFamily: 'Cairo',
              ),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _pinController,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 6,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 24, letterSpacing: 8),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: _showPinError ? AppColors.danger : AppColors.primary,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: _showPinError ? AppColors.danger : AppColors.primary.withOpacity(0.5),
                  ),
                ),
                counterText: '',
                errorText: _showPinError
                    ? (state.isArabic ? 'الرمز غير صحيح' : 'Incorrect PIN')
                    : null,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _authenticate(_pinController.text, state.adminPin),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  state.isArabic ? 'دخول' : 'Enter',
                  style: const TextStyle(fontSize: 18, fontFamily: 'Cairo', color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsContent(AppState state) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // إعدادات اللغة
        _SectionTitle(title: state.isArabic ? 'اللغة' : 'Language'),
        _SettingCard(
          child: Row(
            children: [
              Text(
                state.isArabic ? 'اللغة الحالية' : 'Current Language',
                style: const TextStyle(color: AppColors.textPrimary, fontFamily: 'Cairo', fontSize: 16),
              ),
              const Spacer(),
              Switch(
                value: state.isArabic,
                onChanged: (v) => state.updateLanguage(v ? AppLanguage.arabic : AppLanguage.english),
                activeColor: AppColors.primary,
              ),
              Text(
                state.isArabic ? 'عربي' : 'English',
                style: const TextStyle(color: AppColors.textSecondary, fontFamily: 'Cairo'),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),
        
        // إعدادات تتبع العين
        _SectionTitle(title: state.isArabic ? 'تتبع العين' : 'Eye Tracking'),
        _SettingCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    state.isArabic ? 'مدة النظرة للتأكيد' : 'Gaze Duration',
                    style: const TextStyle(color: AppColors.textPrimary, fontFamily: 'Cairo', fontSize: 16),
                  ),
                  const Spacer(),
                  Text(
                    '${state.gazeDuration.toStringAsFixed(1)}s',
                    style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Slider(
                value: state.gazeDuration,
                min: 1.0,
                max: 5.0,
                divisions: 8,
                activeColor: AppColors.primary,
                inactiveColor: AppColors.surfaceLight,
                onChanged: state.updateGazeDuration,
              ),
              
              const SizedBox(height: 12),
              
              Row(
                children: [
                  Text(
                    state.isArabic ? 'حساسية الرمشة (EAR)' : 'Blink Sensitivity (EAR)',
                    style: const TextStyle(color: AppColors.textPrimary, fontFamily: 'Cairo', fontSize: 16),
                  ),
                  const Spacer(),
                  Text(
                    state.blinkThreshold.toStringAsFixed(2),
                    style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Slider(
                value: state.blinkThreshold,
                min: 0.1,
                max: 0.4,
                divisions: 15,
                activeColor: AppColors.primary,
                inactiveColor: AppColors.surfaceLight,
                onChanged: state.updateBlinkThreshold,
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),
        
        // إعدادات العرض
        _SectionTitle(title: state.isArabic ? 'العرض' : 'Display'),
        _SettingCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    state.isArabic ? 'حجم الخط' : 'Font Size',
                    style: const TextStyle(color: AppColors.textPrimary, fontFamily: 'Cairo', fontSize: 16),
                  ),
                  const Spacer(),
                  Text(
                    '${state.fontSize.toInt()}px',
                    style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Slider(
                value: state.fontSize,
                min: 14.0,
                max: 32.0,
                divisions: 9,
                activeColor: AppColors.primary,
                inactiveColor: AppColors.surfaceLight,
                onChanged: state.updateFontSize,
              ),
              
              const SizedBox(height: 8),
              
              Row(
                children: [
                  Text(
                    state.isArabic ? 'إظهار الاقتراحات' : 'Show Suggestions',
                    style: const TextStyle(color: AppColors.textPrimary, fontFamily: 'Cairo', fontSize: 16),
                  ),
                  const Spacer(),
                  Switch(
                    value: state.showSuggestions,
                    onChanged: (_) => state.toggleSuggestions(),
                    activeColor: AppColors.primary,
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),
        
        // إعدادات الطوارئ
        _SectionTitle(title: state.isArabic ? 'الطوارئ' : 'Emergency'),
        _SettingCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                state.isArabic ? 'رسالة الطوارئ' : 'Emergency Message',
                style: const TextStyle(color: AppColors.textPrimary, fontFamily: 'Cairo', fontSize: 16),
              ),
              const SizedBox(height: 8),
              _EditableField(
                initialValue: state.emergencyMessage,
                onChanged: state.updateEmergencyMessage,
                isArabic: state.isArabic,
                hint: state.isArabic ? 'رسالة الطوارئ...' : 'Emergency message...',
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 12),
        
        // جهات الطوارئ
        _SettingCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    state.isArabic ? 'جهات الطوارئ' : 'Emergency Contacts',
                    style: const TextStyle(color: AppColors.textPrimary, fontFamily: 'Cairo', fontSize: 16),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => _showAddContactDialog(context, state),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        state.isArabic ? '+ إضافة' : '+ Add',
                        style: const TextStyle(color: AppColors.primary, fontFamily: 'Cairo'),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (state.emergencyContacts.isEmpty)
                Text(
                  state.isArabic ? 'لا توجد جهات اتصال' : 'No contacts added',
                  style: const TextStyle(color: AppColors.textDisabled, fontFamily: 'Cairo'),
                )
              else
                ...state.emergencyContacts.asMap().entries.map((e) => _ContactTile(
                  contact: e.value,
                  onDelete: () => state.removeEmergencyContact(e.key),
                )),
            ],
          ),
        ),

        const SizedBox(height: 16),
        
        // تغيير PIN
        _SectionTitle(title: state.isArabic ? 'الأمان' : 'Security'),
        _SettingCard(
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              state.isArabic ? 'تغيير رمز المشرف' : 'Change Admin PIN',
              style: const TextStyle(color: AppColors.textPrimary, fontFamily: 'Cairo', fontSize: 16),
            ),
            subtitle: Text(
              state.isArabic ? 'الرمز الحالي: ${state.adminPin.replaceAll(RegExp(r'.'), '*')}' : 'Current: ${state.adminPin.replaceAll(RegExp(r'.'), '*')}',
              style: const TextStyle(color: AppColors.textSecondary, fontFamily: 'Cairo'),
            ),
            trailing: const Icon(Icons.arrow_forward_ios, color: AppColors.textSecondary, size: 16),
            onTap: () => _showChangePinDialog(context, state),
          ),
        ),
        
        const SizedBox(height: 40),
      ],
    );
  }

  void _showAddContactDialog(BuildContext context, AppState state) {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          state.isArabic ? 'إضافة جهة طوارئ' : 'Add Emergency Contact',
          style: const TextStyle(color: AppColors.textPrimary, fontFamily: 'Cairo'),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                labelText: state.isArabic ? 'الاسم' : 'Name',
                labelStyle: const TextStyle(color: AppColors.textSecondary),
                enabledBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.primary),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.accent),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                labelText: state.isArabic ? 'رقم الهاتف' : 'Phone Number',
                labelStyle: const TextStyle(color: AppColors.textSecondary),
                enabledBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.primary),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.accent),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(state.isArabic ? 'إلغاء' : 'Cancel', style: const TextStyle(color: AppColors.textSecondary, fontFamily: 'Cairo')),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty && phoneController.text.isNotEmpty) {
                state.addEmergencyContact(EmergencyContact(
                  name: nameController.text,
                  phone: phoneController.text,
                ));
                Navigator.pop(ctx);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: Text(state.isArabic ? 'إضافة' : 'Add', style: const TextStyle(fontFamily: 'Cairo', color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showChangePinDialog(BuildContext context, AppState state) {
    final newPinController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          state.isArabic ? 'تغيير الرمز' : 'Change PIN',
          style: const TextStyle(color: AppColors.textPrimary, fontFamily: 'Cairo'),
        ),
        content: TextField(
          controller: newPinController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          obscureText: true,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: InputDecoration(
            labelText: state.isArabic ? 'الرمز الجديد' : 'New PIN',
            labelStyle: const TextStyle(color: AppColors.textSecondary),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(state.isArabic ? 'إلغاء' : 'Cancel', style: const TextStyle(color: AppColors.textSecondary, fontFamily: 'Cairo')),
          ),
          ElevatedButton(
            onPressed: () {
              if (newPinController.text.length >= 4) {
                state.updateAdminPin(newPinController.text);
                Navigator.pop(ctx);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: Text(state.isArabic ? 'حفظ' : 'Save', style: const TextStyle(fontFamily: 'Cairo', color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          color: AppColors.accent,
          fontSize: 14,
          fontWeight: FontWeight.bold,
          fontFamily: 'Cairo',
          letterSpacing: 1,
        ),
      ),
    );
  }
}

class _SettingCard extends StatelessWidget {
  final Widget child;
  const _SettingCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.surfaceLight),
      ),
      child: child,
    );
  }
}

class _EditableField extends StatefulWidget {
  final String initialValue;
  final Function(String) onChanged;
  final bool isArabic;
  final String hint;

  const _EditableField({
    required this.initialValue,
    required this.onChanged,
    required this.isArabic,
    required this.hint,
  });

  @override
  State<_EditableField> createState() => _EditableFieldState();
}

class _EditableFieldState extends State<_EditableField> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      style: const TextStyle(color: AppColors.textPrimary, fontFamily: 'Cairo'),
      maxLines: 3,
      textDirection: widget.isArabic ? TextDirection.rtl : TextDirection.ltr,
      decoration: InputDecoration(
        hintText: widget.hint,
        hintStyle: const TextStyle(color: AppColors.textDisabled, fontFamily: 'Cairo'),
        filled: true,
        fillColor: AppColors.surfaceLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
      onChanged: widget.onChanged,
    );
  }
}

class _ContactTile extends StatelessWidget {
  final EmergencyContact contact;
  final VoidCallback onDelete;

  const _ContactTile({required this.contact, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.person, color: AppColors.primary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(contact.name, style: const TextStyle(color: AppColors.textPrimary, fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
                Text(contact.phone, style: const TextStyle(color: AppColors.textSecondary, fontFamily: 'Cairo', fontSize: 13)),
              ],
            ),
          ),
          GestureDetector(
            onTap: onDelete,
            child: const Icon(Icons.delete_outline, color: AppColors.danger, size: 22),
          ),
        ],
      ),
    );
  }
}
