import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/verification_model.dart';
import '../services/supabase_service.dart';
import '../services/verification_service.dart';
import '../utils/constants.dart';

class DriverVerificationScreen extends StatefulWidget {
  const DriverVerificationScreen({Key? key}) : super(key: key);

  @override
  State<DriverVerificationScreen> createState() =>
      _DriverVerificationScreenState();
}

class _DriverVerificationScreenState extends State<DriverVerificationScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  late final VerificationService _verificationService;

  bool _isLoading = true;
  late DriverVerification _verification;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _verificationService =
        VerificationService(supabaseService: _supabaseService);
    _loadVerificationData();
  }

  // Загрузка данных о верификации
  Future<void> _loadVerificationData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final driverId = _supabaseService.currentUserId;
      if (driverId == null) {
        throw Exception('Не удалось получить ID водителя');
      }

      final verification =
          await _verificationService.getDriverVerification(driverId);

      setState(() {
        _verification = verification;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Ошибка загрузки данных о верификации: $e');

      // Используем демо-данные
      setState(() {
        _verification = DriverVerification.demo();
        _isLoading = false;
      });
    }
  }

  // Загрузка документа
  Future<void> _uploadDocument(VerificationDocument document) async {
    try {
      // Открываем галерею для выбора фотографии
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        setState(() {
          _isLoading = true;
        });

        final driverId = _supabaseService.currentUserId;
        if (driverId == null) {
          throw Exception('Не удалось получить ID водителя');
        }

        final success = await _verificationService.uploadDocument(
          driverId,
          document.id,
          pickedFile,
        );

        if (success) {
          // Перезагружаем данные
          await _loadVerificationData();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Документ успешно загружен'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Ошибка загрузки документа'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Ошибка выбора или загрузки документа: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text(
          'Документы и верификация',
          style: TextStyle(
            fontFamily: 'Manrope',
            fontSize: 16,
            fontWeight: FontWeight.w400,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        shadowColor: Colors.black.withOpacity(0.05),
        leading: Container(
          margin: const EdgeInsets.only(left: 16),
          child: const Icon(
            Icons.badge_outlined,
            size: 17.5,
          ),
        ),
        leadingWidth: 40,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () {
                Navigator.pushNamed(context, '/driver/profile');
              },
              child: const CircleAvatar(
                radius: 16,
                backgroundColor: Colors.grey,
                backgroundImage:
                    AssetImage('assets/images/avatar_placeholder.png'),
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadVerificationData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    // Сообщение о статусе верификации
                    _buildVerificationStatusMessage(),

                    // Секция загрузки документов
                    _buildDocumentsSection(),

                    // Процесс верификации
                    _buildVerificationProcess(),

                    // Информация о безопасности
                    _buildSecurityInfo(),

                    // Нижний отступ для прокрутки
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  // Сообщение о статусе верификации
  Widget _buildVerificationStatusMessage() {
    // Если верификация не пройдена, показываем сообщение
    if (_verification.status == VerificationStatus.notVerified ||
        _verification.status == VerificationStatus.rejected) {
      return Container(
        margin: const EdgeInsets.only(top: 16, left: 16, right: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.error_outline,
              color: Color(0xFFB91C1C),
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Верификация не пройдена',
                    style: const TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFFB91C1C),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Загрузите необходимые документы',
                    style: const TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 14,
                      color: Color(0xFFDC2626),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox(height: 16);
  }

  // Секция загрузки документов
  Widget _buildDocumentsSection() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(24),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Загрузка документов',
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          // Список документов
          Column(
            children: _verification.documents.map((doc) {
              return _buildDocumentItem(doc);
            }).toList(),
          ),
        ],
      ),
    );
  }

  // Элемент документа
  Widget _buildDocumentItem(VerificationDocument document) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    document.getIcon(),
                    size: 14,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    document.title,
                    style: const TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              Text(
                document.isRequired ? 'Требуется' : 'Опционально',
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 14,
                  color: document.isRequired
                      ? const Color(0xFFEF4444)
                      : Colors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Кнопка загрузки
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _uploadDocument(document),
              icon: const Icon(
                Icons.file_upload_outlined,
                size: 14,
                color: Color(0xFF1D4ED8),
              ),
              label: Text(
                document.isUploaded ? 'Заменить' : 'Загрузить',
                style: const TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 14,
                  color: Color(0xFF1D4ED8),
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEFF6FF),
                foregroundColor: const Color(0xFF1D4ED8),
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),

          // Если документ загружен, показываем статус
          if (document.isUploaded) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  document.status == DocumentStatus.verified
                      ? Icons.check_circle
                      : Icons.access_time_filled,
                  size: 16,
                  color: document.status == DocumentStatus.verified
                      ? Colors.green
                      : Colors.orange,
                ),
                const SizedBox(width: 8),
                Text(
                  document.status == DocumentStatus.verified
                      ? 'Подтверждено'
                      : 'На проверке',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 14,
                    color: document.status == DocumentStatus.verified
                        ? Colors.green
                        : Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // Процесс верификации
  Widget _buildVerificationProcess() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Процесс верификации',
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          // Шаги верификации
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                // Шаг 1 - Загрузка документов
                _buildVerificationStep(
                  title: 'Загрузка документов',
                  isActive: _verification.currentStep >= 1,
                  isCompleted: _verification.currentStep > 1,
                  stepNumber: 1,
                ),
                const SizedBox(height: 16),

                // Шаг 2 - Проверка данных
                _buildVerificationStep(
                  title: 'Проверка данных',
                  isActive: _verification.currentStep >= 2,
                  isCompleted: _verification.currentStep > 2,
                  stepNumber: 2,
                ),
                const SizedBox(height: 16),

                // Шаг 3 - Подтверждение
                _buildVerificationStep(
                  title: 'Подтверждение',
                  isActive: _verification.currentStep >= 3,
                  isCompleted:
                      _verification.status == VerificationStatus.verified,
                  stepNumber: 3,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Шаг верификации
  Widget _buildVerificationStep({
    required String title,
    required bool isActive,
    required bool isCompleted,
    required int stepNumber,
  }) {
    return Row(
      children: [
        // Номер шага в кружке
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF3B82F6) : const Color(0xFFE5E7EB),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              stepNumber.toString(),
              style: TextStyle(
                color: isActive ? Colors.white : Colors.black54,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Информация о шаге
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontFamily: 'Manrope',
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: isActive ? Colors.black : Colors.grey,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              isCompleted
                  ? 'Завершено'
                  : isActive
                      ? 'В процессе'
                      : 'Ожидание',
              style: TextStyle(
                fontFamily: 'Manrope',
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Информация о безопасности
  Widget _buildSecurityInfo() {
    return Container(
      margin: const EdgeInsets.only(top: 16, left: 16, right: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.security,
            color: Colors.black54,
            size: 16,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Ваши данные надежно защищены и',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 14,
                    color: Color(0xFF4B5563),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'используются только для верификации.',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 14,
                    color: Color(0xFF4B5563),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
