import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../services/supabase_service.dart';
import '../models/support_ticket_model.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({Key? key}) : super(key: key);

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  final TextEditingController _searchController = TextEditingController();
  final SupabaseService _supabaseService = SupabaseService();
  final ImagePicker _imagePicker = ImagePicker();

  List<String> _faqQuestions = [
    'Как отменить поездку?',
    'Как изменить данные ребенка?',
    'Как узнать информацию о водителе?',
  ];
  List<String> _filteredQuestions = [];
  bool _isSearching = false;

  List<SupportTicket> _tickets = [];
  bool _isLoadingTickets = true;

  @override
  void initState() {
    super.initState();
    _filteredQuestions = List.from(_faqQuestions);
    _searchController.addListener(_filterQuestions);
    _loadTickets();
  }

  Future<void> _loadTickets() async {
    setState(() {
      _isLoadingTickets = true;
    });

    try {
      final tickets = await _supabaseService.getUserTickets();
      setState(() {
        _tickets = tickets;
        _isLoadingTickets = false;
      });
    } catch (e) {
      debugPrint('Ошибка загрузки обращений: $e');
      setState(() {
        _isLoadingTickets = false;
      });
    }
  }

  void _filterQuestions() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _isSearching = query.isNotEmpty;
      if (query.isEmpty) {
        _filteredQuestions = List.from(_faqQuestions);
      } else {
        _filteredQuestions = _faqQuestions
            .where((question) => question.toLowerCase().contains(query))
            .toList();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _isSearching ? _buildSearchResults() : _buildFAQSection(),
                    _buildSupportContactSection(),
                    _buildTicketStatusSection(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: Colors.white,
      height: 104,
      child: Column(
        children: [
          // Верхняя часть с заголовком и кнопкой назад
          SizedBox(
            height: 52,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: SvgPicture.asset(
                      'assets/icons/arrow_back.svg',
                      width: 12.5,
                      height: 20,
                    ),
                  ),
                  const Expanded(
                    child: Center(
                      child: Text(
                        'Поддержка',
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(
                      width: 32), // Для выравнивания заголовка по центру
                ],
              ),
            ),
          ),
          // Поле поиска
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Поиск',
                  hintStyle: const TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 16,
                    color: Color(0xFFADAEBC),
                  ),
                  border: InputBorder.none,
                  prefixIcon: Padding(
                    padding: const EdgeInsets.all(12),
                    child: SvgPicture.asset(
                      'assets/icons/search.svg',
                      width: 16,
                      height: 16,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  suffixIcon: _isSearching
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 16),
                          onPressed: () {
                            _searchController.clear();
                          },
                        )
                      : null,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_filteredQuestions.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: Column(
            children: [
              const Icon(
                Icons.search_off,
                size: 48,
                color: Color(0xFF9CA3AF),
              ),
              const SizedBox(height: 16),
              Text(
                'По запросу "${_searchController.text}" ничего не найдено',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 16,
                  color: Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Результаты поиска',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: _filteredQuestions.map((question) {
                final isMultiline = question.length > 30;
                return Column(
                  children: [
                    _buildFAQItem(question, isMultiline: isMultiline),
                    const SizedBox(height: 12),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAQSection() {
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Частые вопросы',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                _buildFAQItem('Как отменить поездку?'),
                const SizedBox(height: 12),
                _buildFAQItem('Как изменить данные ребенка?'),
                const SizedBox(height: 12),
                _buildFAQItem('Как узнать информацию о водителе?',
                    isMultiline: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAQItem(String question, {bool isMultiline = false}) {
    return GestureDetector(
      onTap: () => _showFAQAnswer(question),
      child: Container(
        width: double.infinity,
        height: isMultiline ? 80 : 56,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  question,
                  style: const TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              SvgPicture.asset(
                'assets/icons/chevron_right.svg',
                width: 16,
                height: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFAQAnswer(String question) {
    String answer = '';

    if (question == 'Как отменить поездку?') {
      answer = 'Чтобы отменить поездку:\n\n'
          '1. Откройте текущую поездку в приложении\n'
          '2. Нажмите кнопку "Отменить поездку" внизу экрана\n'
          '3. Выберите причину отмены\n'
          '4. Подтвердите отмену\n\n'
          'Обратите внимание, что при отмене поездки менее чем за 5 минут до прибытия водителя может взиматься плата за отмену.';
    } else if (question == 'Как изменить данные ребенка?') {
      answer = 'Для изменения данных ребенка:\n\n'
          '1. Откройте боковое меню, нажав на иконку в левом верхнем углу\n'
          '2. В разделе "Мои дети" найдите нужного ребенка\n'
          '3. Нажмите на запись о ребенке и удерживайте\n'
          '4. Выберите "Редактировать"\n'
          '5. Внесите необходимые изменения и нажмите "Сохранить"';
    } else if (question == 'Как узнать информацию о водителе?') {
      answer = 'Информация о водителе доступна после подтверждения заказа:\n\n'
          '1. Откройте текущую поездку\n'
          '2. В верхней части экрана отображается имя водителя, его рейтинг и фото\n'
          '3. Нажмите на карточку водителя, чтобы увидеть подробную информацию\n'
          '4. Здесь вы найдете данные о стаже работы, марке автомобиля и его номере\n\n'
          'Также вы можете позвонить водителю или написать ему сообщение через приложение.';
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          question,
          style: const TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: SingleChildScrollView(
          child: Text(
            answer,
            style: const TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 16,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Понятно',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF3B82F6),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupportContactSection() {
    return Container(
      color: Colors.white,
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Связь с поддержкой',
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _buildContactItem(
                'Чат',
                'assets/icons/chat.svg',
                const Color(0xFFEFF6FF),
                onTap: _openSupportChat,
              ),
              const SizedBox(width: 16),
              _buildContactItem(
                'Телефон',
                'assets/icons/phone.svg',
                const Color(0xFFECFDF5),
                onTap: () => _callSupport('+7 800 555 35 35'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildContactItem(
                'Email',
                'assets/icons/email.svg',
                const Color(0xFFF5F3FF),
                onTap: () => _sendEmail('support@mama-taxi.ru'),
              ),
              const SizedBox(width: 16),
              _buildContactItem(
                'Жалоба',
                'assets/icons/flag.svg',
                const Color(0xFFFFF7ED),
                onTap: _openComplaintForm,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem(String title, String iconPath, Color backgroundColor,
      {required VoidCallback onTap}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 80,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(
                iconPath,
                width: 24,
                height: 24,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openSupportChat() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Чат с поддержкой',
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: const Text(
          'Чат с оператором поддержки будет доступен в ближайшее время. Пожалуйста, попробуйте позже или воспользуйтесь другими способами связи.',
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 16,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Закрыть',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF3B82F6),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _callSupport(String phoneNumber) async {
    final Uri uri = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Не удалось совершить звонок'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _sendEmail(String email) async {
    final Uri uri = Uri.parse('mailto:$email?subject=Обращение в поддержку');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Не удалось открыть почтовый клиент'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _openComplaintForm() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Отправить жалобу',
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const TextField(
              decoration: InputDecoration(
                labelText: 'Тема жалобы',
                border: OutlineInputBorder(),
              ),
              maxLines: 1,
            ),
            const SizedBox(height: 16),
            const TextField(
              decoration: InputDecoration(
                labelText: 'Описание проблемы',
                border: OutlineInputBorder(),
              ),
              maxLines: 5,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.attach_file, size: 20),
                TextButton(
                  onPressed: () {},
                  child: const Text('Прикрепить файл'),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Отмена',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Жалоба отправлена'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
            ),
            child: const Text(
              'Отправить',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketStatusSection() {
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Статус обращения',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 16),
          _isLoadingTickets
              ? const Center(child: CircularProgressIndicator())
              : _tickets.isEmpty
                  ? _buildEmptyTicketsMessage()
                  : _buildTicketsList(),
        ],
      ),
    );
  }

  Widget _buildEmptyTicketsMessage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        width: double.infinity,
        height: 120,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.support_agent,
              size: 40,
              color: Color(0xFF9CA3AF),
            ),
            const SizedBox(height: 16),
            const Text(
              'У вас пока нет обращений в поддержку',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 16,
                color: Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _createNewTicket,
              child: const Text(
                'Создать обращение',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 16,
                  color: Color(0xFF3B82F6),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTicketsList() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          ..._tickets.map((ticket) => _buildTicketItem(ticket)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _createNewTicket,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Создать новое обращение',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 16,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketItem(SupportTicket ticket) {
    final dateFormat = DateFormat('dd MMMM yyyy, HH:mm', 'ru_RU');
    final formattedDate = dateFormat.format(ticket.createdAt);

    return GestureDetector(
      onTap: () => _showTicketDetails(ticket),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Обращение #${ticket.id.substring(0, 4)}',
                  style: const TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    color: ticket.getStatusColor(),
                    borderRadius: BorderRadius.circular(9999),
                  ),
                  child: Text(
                    ticket.getStatusText(),
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 14,
                      color: ticket.getStatusTextColor(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              ticket.subject,
              style: const TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                SvgPicture.asset(
                  'assets/icons/clock.svg',
                  width: 14,
                  height: 14,
                ),
                const SizedBox(width: 8),
                Text(
                  formattedDate,
                  style: const TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _createNewTicket() {
    final subjectController = TextEditingController();
    final descriptionController = TextEditingController();
    File? selectedFile;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text(
            'Новое обращение',
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: subjectController,
                  decoration: const InputDecoration(
                    labelText: 'Тема обращения',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 1,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Описание проблемы',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 5,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.attach_file, size: 20),
                    TextButton(
                      onPressed: () async {
                        final pickedFile = await _imagePicker.pickImage(
                          source: ImageSource.gallery,
                        );
                        if (pickedFile != null) {
                          setState(() {
                            selectedFile = File(pickedFile.path);
                          });
                        }
                      },
                      child: Text(
                        selectedFile != null
                            ? 'Файл выбран'
                            : 'Прикрепить файл',
                      ),
                    ),
                  ],
                ),
                if (selectedFile != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle,
                            color: Colors.green, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            selectedFile!.path.split('/').last,
                            style: const TextStyle(fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 16),
                          onPressed: () {
                            setState(() {
                              selectedFile = null;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Отмена',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                if (subjectController.text.isEmpty ||
                    descriptionController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Заполните все поля'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                  return;
                }

                Navigator.of(context).pop();

                // Показываем индикатор загрузки
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) =>
                      const Center(child: CircularProgressIndicator()),
                );

                try {
                  final ticketId = await _supabaseService.createSupportTicket(
                    subject: subjectController.text,
                    description: descriptionController.text,
                  );

                  if (ticketId != null && selectedFile != null) {
                    await _supabaseService.uploadSupportFile(
                        selectedFile!, ticketId);
                  }

                  // Закрываем диалог загрузки
                  if (mounted) {
                    Navigator.of(context).pop();
                  }

                  // Обновляем список обращений
                  _loadTickets();

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Обращение успешно создано'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                } catch (e) {
                  // Закрываем диалог загрузки
                  if (mounted) {
                    Navigator.of(context).pop();
                  }

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Ошибка: ${e.toString()}'),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
              ),
              child: const Text(
                'Отправить',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTicketDetails(SupportTicket ticket) {
    final messageController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Text(
              'Обращение #${ticket.id.substring(0, 4)}',
              style: const TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            Chip(
              label: Text(
                ticket.getStatusText(),
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 12,
                  color: ticket.getStatusTextColor(),
                ),
              ),
              backgroundColor: ticket.getStatusColor(),
              padding: EdgeInsets.zero,
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Тема: ${ticket.subject}',
                style: const TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Создано: ${DateFormat('dd MMMM yyyy, HH:mm', 'ru_RU').format(ticket.createdAt)}',
                style: const TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 14,
                  color: Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Описание проблемы:',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                ticket.description,
                style: const TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 14,
                ),
              ),
              if (ticket.operatorResponse != null) ...[
                const SizedBox(height: 16),
                const Text(
                  'Ответ оператора:',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    ticket.operatorResponse!,
                    style: const TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
              if (ticket.status != TicketStatus.closed) ...[
                const SizedBox(height: 16),
                const Text(
                  'Добавить комментарий:',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: messageController,
                  decoration: const InputDecoration(
                    hintText: 'Введите комментарий...',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ],
          ),
        ),
        actions: [
          if (ticket.status != TicketStatus.closed)
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();

                final result = await _supabaseService.closeTicket(ticket.id);
                if (result) {
                  _loadTickets();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Обращение закрыто'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                }
              },
              child: const Text(
                'Закрыть обращение',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.red,
                ),
              ),
            ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Закрыть',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF3B82F6),
              ),
            ),
          ),
          if (ticket.status != TicketStatus.closed &&
              messageController.text.isNotEmpty)
            ElevatedButton(
              onPressed: () async {
                if (messageController.text.isEmpty) return;

                Navigator.of(context).pop();

                // Временное решение: обновляем обращение вместо добавления сообщения
                // Когда таблица support_messages будет создана, раскомментировать код ниже
                /*
                final result = await _supabaseService.addMessageToTicket(
                  ticketId: ticket.id,
                  message: messageController.text,
                );
                */

                // Временное решение: показываем уведомление без реального сохранения
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                          'Комментарий будет добавлен после создания таблицы support_messages'),
                      duration: Duration(seconds: 3),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
              ),
              child: const Text(
                'Отправить',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
