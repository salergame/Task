import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../utils/constants.dart';

class Child {
  final String id;
  final String name;
  final int age;
  final String? photoUrl;
  final File? photoFile;

  Child({
    required this.id,
    required this.name,
    required this.age,
    this.photoUrl,
    this.photoFile,
  });
}

class AddChildModal extends StatefulWidget {
  final Function(Child child) onAdd;

  const AddChildModal({super.key, required this.onAdd});

  @override
  State<AddChildModal> createState() => _AddChildModalState();
}

class _AddChildModalState extends State<AddChildModal> {
  final TextEditingController _nameController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  int _selectedAge = 8;
  String? _photoUrl;
  File? _photoFile;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  // Выбор изображения из галереи
  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 500,
        maxHeight: 500,
        imageQuality: 90,
      );

      if (pickedFile != null) {
        setState(() {
          _photoFile = File(pickedFile.path);
          _photoUrl = null; // Сбрасываем URL, так как теперь у нас есть файл
        });
      }
    } catch (e) {
      // Обработка ошибок выбора изображения
      debugPrint('Ошибка при выборе изображения: $e');
    }
  }

  // Сделать фото с камеры
  Future<void> _takePhoto() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 500,
        maxHeight: 500,
        imageQuality: 90,
      );

      if (pickedFile != null) {
        setState(() {
          _photoFile = File(pickedFile.path);
          _photoUrl = null; // Сбрасываем URL, так как теперь у нас есть файл
        });
      }
    } catch (e) {
      // Обработка ошибок выбора изображения
      debugPrint('Ошибка при съемке фото: $e');
    }
  }

  // Показать выбор источника изображения
  void _showImageSourceActionSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppSizes.borderRadiusLarge),
          topRight: Radius.circular(AppSizes.borderRadiusLarge),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Выбрать из галереи'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage();
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Сделать фото'),
                onTap: () {
                  Navigator.of(context).pop();
                  _takePhoto();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.modalBorderRadius),
      ),
      child: Container(
        width: 358,
        height: 500,
        child: Column(
          children: [
            // Заголовок и кнопка закрытия
            Container(
              height: AppSizes.modalHeaderHeight,
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: AppColors.modalDivider, width: 1),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSizes.paddingLarge,
                  AppSizes.paddingLarge,
                  AppSizes.paddingLarge,
                  AppSizes.padding,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(AppStrings.addChild, style: AppTextStyles.modalTitle),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                ),
              ),
            ),

            // Форма добавления
            Container(
              padding: const EdgeInsets.all(AppSizes.paddingLarge),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Аватар ребенка
                  Center(
                    child: Stack(
                      children: [
                        Container(
                          width: AppSizes.avatarSize,
                          height: AppSizes.avatarSize,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.grey[300],
                            image:
                                _photoFile != null
                                    ? DecorationImage(
                                      image: FileImage(_photoFile!),
                                      fit: BoxFit.cover,
                                    )
                                    : _photoUrl != null
                                    ? DecorationImage(
                                      image: NetworkImage(_photoUrl!),
                                      fit: BoxFit.cover,
                                    )
                                    : null,
                          ),
                          child:
                              (_photoFile == null && _photoUrl == null)
                                  ? const Icon(
                                    Icons.person,
                                    size: 40,
                                    color: Colors.grey,
                                  )
                                  : null,
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            width: AppSizes.avatarEditButtonSize,
                            height: AppSizes.avatarEditButtonSize,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              icon: const Icon(
                                Icons.camera_alt,
                                size: 16,
                                color: Colors.white,
                              ),
                              onPressed: _showImageSourceActionSheet,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Имя ребенка
                  Text(AppStrings.childName, style: AppTextStyles.formLabel),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      hintText: AppStrings.enterName,
                      hintStyle: TextStyle(color: AppColors.placeholderText),
                      filled: true,
                      fillColor: AppColors.inputBackground,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderSide: BorderSide.none,
                        borderRadius: BorderRadius.circular(
                          AppSizes.borderRadius,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Возраст ребенка
                  Text(AppStrings.age, style: AppTextStyles.formLabel),
                  const SizedBox(height: 8),
                  Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppColors.inputBackground,
                      borderRadius: BorderRadius.circular(
                        AppSizes.borderRadius,
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: _selectedAge,
                        isExpanded: true,
                        icon: const Icon(Icons.keyboard_arrow_down),
                        style: const TextStyle(
                          fontSize: 16,
                          fontFamily: 'Rubik',
                          color: AppColors.text,
                        ),
                        onChanged: (int? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _selectedAge = newValue;
                            });
                          }
                        },
                        items:
                            List.generate(
                              18,
                              (index) => index + 1,
                            ).map<DropdownMenuItem<int>>((int value) {
                              return DropdownMenuItem<int>(
                                value: value,
                                child: Text('$value лет'),
                              );
                            }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Кнопки
            Container(
              padding: const EdgeInsets.all(AppSizes.paddingLarge),
              child: Row(
                children: [
                  // Кнопка Отмена
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.text,
                          side: BorderSide(color: AppColors.border),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppSizes.borderRadius,
                            ),
                          ),
                        ),
                        child: Text(
                          AppStrings.cancel,
                          style: AppTextStyles.buttonText,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Кнопка Добавить
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () {
                          if (_nameController.text.isNotEmpty) {
                            // Создаем нового ребенка
                            final child = Child(
                              id:
                                  DateTime.now().millisecondsSinceEpoch
                                      .toString(),
                              name: _nameController.text,
                              age: _selectedAge,
                              photoUrl: _photoUrl,
                              photoFile: _photoFile,
                            );
                            // Вызываем callback
                            widget.onAdd(child);
                            // Закрываем модальное окно
                            Navigator.of(context).pop();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppSizes.borderRadius,
                            ),
                          ),
                        ),
                        child: Text(
                          AppStrings.add,
                          style: AppTextStyles.buttonText,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
