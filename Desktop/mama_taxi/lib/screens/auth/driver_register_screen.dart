import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
// import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';
import '../../services/supabase_service.dart';
import '../../utils/constants.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/input_field.dart';
import '../../models/user_model.dart';
import '../../services/verification_service.dart';

class DriverRegisterScreen extends StatefulWidget {
  const DriverRegisterScreen({super.key});

  @override
  State<DriverRegisterScreen> createState() => _DriverRegisterScreenState();
}

class _DriverRegisterScreenState extends State<DriverRegisterScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _errorMessage;

  Uint8List? _selfieBytes;
  String? _passportFileName;
  String? _driverLicenseFileName;
  Uint8List? _passportBytes;
  Uint8List? _driverLicenseBytes;
  Uint8List? _selfEmployedDocBytes;
  String? _selfEmployedDocFileName;
  Uint8List? _taxiRegistryDocBytes;
  String? _taxiRegistryDocFileName;
  Uint8List? _carrierPermissionBytes;
  String? _carrierPermissionFileName;
  Uint8List? _criminalRecordBytes;
  String? _criminalRecordFileName;
  Uint8List? _tuberculosisCertBytes;
  String? _tuberculosisCertFileName;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _takeSelfie() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.camera);

    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _selfieBytes = bytes;
      });
    }
  }

  Future<void> _pickDocument(bool isPassport) async {
    final ImagePicker picker = ImagePicker();
    final XFile? file = await picker.pickImage(source: ImageSource.gallery);

    if (file != null) {
      final bytes = await file.readAsBytes();
      final name = file.name;

      setState(() {
        if (isPassport) {
          _passportFileName = name;
          _passportBytes = bytes;
        } else {
          _driverLicenseFileName = name;
          _driverLicenseBytes = bytes;
        }
      });
    }
  }

  Future<void> _pickExtraDocument(String type) async {
    final ImagePicker picker = ImagePicker();
    final XFile? file = await picker.pickImage(source: ImageSource.gallery);
    if (file != null) {
      final bytes = await file.readAsBytes();
      final name = file.name;
      setState(() {
        switch (type) {
          case 'selfEmployed':
            _selfEmployedDocFileName = name;
            _selfEmployedDocBytes = bytes;
            break;
          case 'taxiRegistry':
            _taxiRegistryDocFileName = name;
            _taxiRegistryDocBytes = bytes;
            break;
          case 'carrierPermission':
            _carrierPermissionFileName = name;
            _carrierPermissionBytes = bytes;
            break;
          case 'criminalRecord':
            _criminalRecordFileName = name;
            _criminalRecordBytes = bytes;
            break;
          case 'tuberculosisCert':
            _tuberculosisCertFileName = name;
            _tuberculosisCertBytes = bytes;
            break;
        }
      });
    }
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selfieBytes == null) {
      setState(() {
        _errorMessage = 'Необходимо сделать селфи';
      });
      return;
    }

    if (_passportBytes == null || _driverLicenseBytes == null ||
        _selfEmployedDocBytes == null || _taxiRegistryDocBytes == null ||
        _carrierPermissionBytes == null || _criminalRecordBytes == null || _tuberculosisCertBytes == null) {
      setState(() {
        _errorMessage = 'Необходимо загрузить все документы';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      debugPrint('Начало регистрации водителя');
      // Регистрация пользователя
      final supabaseService = SupabaseService();
      final response = await supabaseService.signUpWithEmail(
        _emailController.text.trim(),
        _passwordController.text,
        UserRole.driver,
      );

      debugPrint(
        'Ответ от сервера получен: ${response?.user != null ? 'Успешно' : 'Неудачно'}',
      );

      if (response?.user != null) {
        try {
          final user = response!.user!;
          debugPrint('Загрузка селфи');
          // Загрузка селфи
          final selfieUrl = await supabaseService.uploadFile(
            _selfieBytes!,
            'selfie.jpg',
            'driver_photos',
          );
          debugPrint('Селфи загружено: $selfieUrl');

          debugPrint('Загрузка паспорта');
          // Загрузка паспорта
          final passportUrl = await supabaseService.uploadFile(
            _passportBytes!,
            _passportFileName!,
            'driver_documents',
          );
          debugPrint('Паспорт загружен: $passportUrl');

          debugPrint('Загрузка водительского удостоверения');
          // Загрузка водительского удостоверения
          final licenseUrl = await supabaseService.uploadFile(
            _driverLicenseBytes!,
            _driverLicenseFileName!,
            'driver_documents',
          );
          debugPrint('Водительское удостоверение загружено: $licenseUrl');

          debugPrint('Загрузка дополнительных документов');
          final selfEmployedUrl = await supabaseService.uploadFile(
            _selfEmployedDocBytes!,
            _selfEmployedDocFileName!,
            'driver_documents',
          );
          final taxiRegistryUrl = await supabaseService.uploadFile(
            _taxiRegistryDocBytes!,
            _taxiRegistryDocFileName!,
            'driver_documents',
          );
          final carrierPermissionUrl = await supabaseService.uploadFile(
            _carrierPermissionBytes!,
            _carrierPermissionFileName!,
            'driver_documents',
          );
          final criminalRecordUrl = await supabaseService.uploadFile(
            _criminalRecordBytes!,
            _criminalRecordFileName!,
            'driver_documents',
          );
          final tuberculosisCertUrl = await supabaseService.uploadFile(
            _tuberculosisCertBytes!,
            _tuberculosisCertFileName!,
            'driver_documents',
          );
          debugPrint('Документы загружены');

          debugPrint('Обновление профиля водителя');
          // Обновление профиля водителя
          await supabaseService.updateUserProfile(
            UserModel(
              id: user.id,
              email: _emailController.text.trim(),
              phone: _phoneController.text.trim(),
              avatarUrl: selfieUrl,
              role: 'driver',
              fullName:
                  '', // пустое значение, т.к. у нас нет этих данных на этом экране
            ),
          );
          debugPrint('Профиль обновлен');

          debugPrint('Обновление документов водителя');
          // Обновление документов водителя
          final userId = user.id;
          await supabaseService.updateDriverProfile(userId, {
            'passport_url': passportUrl,
            'driver_license_url': licenseUrl,
            'self_employed_doc_url': selfEmployedUrl,
            'taxi_registry_doc_url': taxiRegistryUrl,
            'carrier_permission_url': carrierPermissionUrl,
            'criminal_record_url': criminalRecordUrl,
            'tuberculosis_cert_url': tuberculosisCertUrl,
          });
          debugPrint('Документы обновлены');

          // Инициализируем документы для верификации
          final verificationService =
              VerificationService(supabaseService: supabaseService);
          await verificationService.initializeFromDriverProfile(userId);
          debugPrint('Документы инициализированы для верификации');

          // Перенаправляем на экран карты водителя
          if (mounted) {
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/driver/map',
              (route) => false,
            );
          }
        } catch (e) {
          debugPrint('Ошибка при загрузке документов: $e');
          setState(() {
            _errorMessage = 'Ошибка при загрузке документов. Попробуйте позже.';
          });
        }
      } else {
        debugPrint('Пользователь не создан, но ошибки нет');
        setState(() {
          _errorMessage = 'Не удалось завершить регистрацию. Попробуйте позже.';
        });
      }
    } on AuthException catch (e) {
      debugPrint('AuthException при регистрации: ${e.message}');
      setState(() {
        if (e.message.contains('already registered') ||
            e.message.contains('already exists')) {
          _errorMessage = 'Пользователь с таким email уже зарегистрирован';
        } else if (e.message.contains('password')) {
          _errorMessage = 'Ошибка в пароле: ${e.message}';
        } else if (e.message.contains('email')) {
          _errorMessage = 'Ошибка в email: ${e.message}';
        } else {
          _errorMessage = e.message;
        }
      });
    } catch (e) {
      debugPrint('Неизвестная ошибка при регистрации: $e');
      setState(() {
        _errorMessage = 'Ошибка при регистрации: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          AppStrings.driverRegistration,
          style: AppTextStyles.heading,
        ),
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.padding),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSection(
                  title: AppStrings.phoneLogin,
                  child: Column(
                    children: [
                      InputField(
                        label: 'Email',
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Введите email';
                          }
                          if (!RegExp(
                            r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                          ).hasMatch(value)) {
                            return 'Введите корректный email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      InputField(
                        label: 'Пароль',
                        controller: _passwordController,
                        obscureText: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Введите пароль';
                          }
                          if (value.length < 6) {
                            return 'Пароль должен содержать минимум 6 символов';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      InputField(
                        label: AppStrings.phoneNumber,
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        prefix: const Padding(
                          padding: EdgeInsets.only(left: 16),
                          child: Text('+7', style: AppTextStyles.body),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Введите номер телефона';
                          }
                          if (!RegExp(r'^\d{10}$').hasMatch(value)) {
                            return 'Введите корректный номер телефона';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _buildSection(
                  title: AppStrings.socialLogin,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSocialButton(onTap: () {}, icon: Icons.apple),
                      _buildSocialButton(
                        onTap: () {},
                        icon: Icons.g_mobiledata,
                      ),
                      _buildSocialButton(onTap: () {}, icon: Icons.facebook),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _buildSection(
                  title: AppStrings.photoControl,
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: _takeSelfie,
                        child: Container(
                          height: 142,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: AppColors.border,
                              width: 2,
                              style: BorderStyle.solid,
                            ),
                            borderRadius: BorderRadius.circular(
                              AppSizes.borderRadius,
                            ),
                          ),
                          child: _selfieBytes != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(
                                    AppSizes.borderRadius - 2,
                                  ),
                                  child: Image.memory(
                                    _selfieBytes!,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                  ),
                                )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.camera_alt, size: 30),
                                    const SizedBox(height: 8),
                                    Text(
                                      AppStrings.takeSelfie,
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(AppSizes.paddingSmall),
                        decoration: BoxDecoration(
                          color: AppColors.infoBackground,
                          borderRadius: BorderRadius.circular(
                            AppSizes.borderRadius,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.info_outline,
                              color: AppColors.infoText,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                AppStrings.goodLighting,
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.infoText,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(AppSizes.paddingSmall),
                        decoration: BoxDecoration(
                          color: AppColors.warningBackground,
                          borderRadius: BorderRadius.circular(
                            AppSizes.borderRadius,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.access_time,
                              color: AppColors.warningText,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              AppStrings.pendingVerification,
                              style: AppTextStyles.body.copyWith(
                                color: AppColors.warningText,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _buildSection(
                  title: AppStrings.uploadDocuments,
                  child: Column(
                    children: [
                      _buildDocumentButton(
                        title: AppStrings.passport,
                        fileName: _passportFileName,
                        onTap: () => _pickDocument(true),
                      ),
                      const SizedBox(height: 12),
                      _buildDocumentButton(
                        title: AppStrings.driverLicense,
                        fileName: _driverLicenseFileName,
                        onTap: () => _pickDocument(false),
                      ),
                      const SizedBox(height: 12),
                      _buildDocumentButton(
                        title: 'Самозанятый или ИП (документ)',
                        fileName: _selfEmployedDocFileName,
                        onTap: () => _pickExtraDocument('selfEmployed'),
                      ),
                      const SizedBox(height: 12),
                      _buildDocumentButton(
                        title: 'Сведения об автомобиле в реестре легковых такси',
                        fileName: _taxiRegistryDocFileName,
                        onTap: () => _pickExtraDocument('taxiRegistry'),
                      ),
                      const SizedBox(height: 12),
                      _buildDocumentButton(
                        title: 'Разрешение перевозчика',
                        fileName: _carrierPermissionFileName,
                        onTap: () => _pickExtraDocument('carrierPermission'),
                      ),
                      const SizedBox(height: 12),
                      _buildDocumentButton(
                        title: 'Справка о несудимости',
                        fileName: _criminalRecordFileName,
                        onTap: () => _pickExtraDocument('criminalRecord'),
                      ),
                      const SizedBox(height: 12),
                      _buildDocumentButton(
                        title: 'Справка из туберкулезного центра',
                        fileName: _tuberculosisCertFileName,
                        onTap: () => _pickExtraDocument('tuberculosisCert'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      _errorMessage!,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.primary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                PrimaryButton(
                  text: AppStrings.continue_,
                  onPressed: _register,
                  isLoading: _isLoading,
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.padding),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSizes.borderRadiusLarge),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.subheading),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildSocialButton({
    required VoidCallback onTap,
    required IconData icon,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        height: 46,
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(AppSizes.borderRadius),
        ),
        child: Center(child: Icon(icon, color: AppColors.black, size: 24)),
      ),
    );
  }

  Widget _buildDocumentButton({
    required String title,
    required VoidCallback onTap,
    String? fileName,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(AppSizes.borderRadius),
        ),
        child: Row(
          children: [
            const Icon(Icons.description_outlined, size: 18),
            const SizedBox(width: 12),
            Expanded(child: Text(fileName ?? title, style: AppTextStyles.body)),
            const Icon(Icons.upload_file, size: 14),
          ],
        ),
      ),
    );
  }
}
