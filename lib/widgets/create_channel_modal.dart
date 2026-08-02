import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../services/api_service.dart';
import 'avatar_cropper.dart';
import 'base_custom_modal.dart';
import 'custom_toast.dart';

/// Desktop-модалка создания канала (служит базой для создания группы и модалок редактирования)
class CreateChannelModal extends BaseCustomModal {
  final bool isGroup;
  final bool isEditing;
  final Map<String, dynamic>? initialData;

  const CreateChannelModal({
    super.key,
    this.isGroup = false,
    this.isEditing = false,
    this.initialData,
    super.modalTag = 'КАНАЛ',
    super.title = 'СОЗДАТЬ КАНАЛ',
  });

  static Future<void> show({
    required BuildContext context,
    bool isGroup = false,
    bool isEditing = false,
    Map<String, dynamic>? initialData,
  }) {
    return BaseCustomModal.show(
      context: context,
      modal: CreateChannelModal(
        isGroup: isGroup,
        isEditing: isEditing,
        initialData: initialData,
      ),
    );
  }

  @override
  State<CreateChannelModal> createState() => CreateChannelModalState();
}

class CreateChannelModalState extends BaseCustomModalState<CreateChannelModal> {
  late final TextEditingController nameController;
  late final TextEditingController usernameController;
  late final TextEditingController descriptionController;

  File? avatarFile;
  bool isPrivate = false;
  bool isLoading = false;
  String? errorMessage;

  bool get isGroup => widget.isGroup;
  bool get isEditing => widget.isEditing;

  @override
  double get modalWidth => 520.0;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.initialData?['name']?.toString() ?? '');
    usernameController = TextEditingController(text: widget.initialData?['username']?.toString() ?? '');
    descriptionController = TextEditingController(text: widget.initialData?['description']?.toString() ?? '');
    isPrivate = widget.initialData?['privacy'] == 'private' || widget.initialData?['is_private'] == true;
  }

  @override
  void dispose() {
    nameController.dispose();
    usernameController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  @override
  String getModalTitle(BuildContext context) {
    final lang = Localizations.localeOf(context).languageCode.toLowerCase();
    if (isEditing) {
      return isGroup
          ? _ChannelModalL10n.get('edit_group_tag', lang).toUpperCase()
          : _ChannelModalL10n.get('edit_channel_tag', lang).toUpperCase();
    }
    return isGroup
        ? _ChannelModalL10n.get('create_group_tag', lang).toUpperCase()
        : _ChannelModalL10n.get('create_channel_tag', lang).toUpperCase();
  }

  Future<void> pickAvatar() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );
      if (result != null && result.files.single.path != null) {
        final rawFile = File(result.files.single.path!);
        if (mounted) {
          final croppedFile = await AvatarCropper.show(context, rawFile);
          if (croppedFile != null && mounted) {
            setState(() {
              avatarFile = croppedFile;
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Error picking avatar for channel/group: $e');
    }
  }

  Future<void> handleSave() async {
    final name = nameController.text.trim();
    final username = usernameController.text.trim();
    final lang = Localizations.localeOf(context).languageCode.toLowerCase();

    if (name.isEmpty) {
      setState(() {
        errorMessage = isGroup
            ? _ChannelModalL10n.get('err_group_name', lang)
            : _ChannelModalL10n.get('err_channel_name', lang);
      });
      return;
    }

    if (!isPrivate && username.isEmpty) {
      setState(() {
        errorMessage = _ChannelModalL10n.get('err_username_required', lang);
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    final api = ApiService();
    final description = descriptionController.text.trim();

    final response = isGroup
        ? await api.createGroup(
            name: name,
            username: !isPrivate ? username : null,
            description: description.isNotEmpty ? description : null,
            isPrivate: isPrivate,
            avatarFile: avatarFile,
          )
        : await api.createChannel(
            name: name,
            username: !isPrivate ? username : null,
            description: description.isNotEmpty ? description : null,
            isPrivate: isPrivate,
            avatarFile: avatarFile,
          );

    if (!mounted) return;

    setState(() {
      isLoading = false;
    });

    if (response.success) {
      CustomToast.show(
        context,
        isGroup
            ? _ChannelModalL10n.get('group_created', lang)
            : _ChannelModalL10n.get('channel_created', lang),
        type: ToastType.success,
      );
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        errorMessage = response.error ?? _ChannelModalL10n.get('err_generic', lang);
      });
    }
  }

  @override
  Widget buildContent(BuildContext context, ScrollController scrollController, bool isDark, double scale) {
    final lang = Localizations.localeOf(context).languageCode.toLowerCase();

    final cardBg = isDark ? const Color(0xFF141416) : const Color(0xFFF4F4F5);
    final borderColor = isDark ? const Color(0xFF242428) : const Color(0xFFE4E4E7);
    final inputBg = isDark ? const Color(0xFF18181B) : const Color(0xFFFFFFFF);
    final textPrimary = isDark ? Colors.white : Colors.black;
    final textSecondary = isDark ? Colors.white54 : Colors.black54;

    final headerTitle = isEditing
        ? (isGroup ? _ChannelModalL10n.get('title_edit_group', lang) : _ChannelModalL10n.get('title_edit_channel', lang))
        : (isGroup ? _ChannelModalL10n.get('title_create_group', lang) : _ChannelModalL10n.get('title_create_channel', lang));

    return SingleChildScrollView(
      controller: scrollController,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            headerTitle,
            style: TextStyle(
              fontSize: 18 * scale,
              fontWeight: FontWeight.w700,
              color: textPrimary,
              fontFamily: 'Inter',
            ),
          ),
          SizedBox(height: 18 * scale),

          // Error Banner
          if (errorMessage != null) ...[
            Container(
              padding: EdgeInsets.all(12 * scale),
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8 * scale),
                border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 18 * scale),
                  SizedBox(width: 8 * scale),
                  Expanded(
                    child: Text(
                      errorMessage!,
                      style: TextStyle(
                        fontSize: 12 * scale,
                        color: Colors.redAccent,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16 * scale),
          ],

          // Avatar Header & Main Info Section
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar Picker Container
              GestureDetector(
                onTap: pickAvatar,
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Stack(
                    children: [
                      Container(
                        width: 72 * scale,
                        height: 72 * scale,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: cardBg,
                          border: Border.all(color: borderColor, width: 1.5),
                          image: avatarFile != null
                              ? DecorationImage(
                                  image: FileImage(avatarFile!),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: avatarFile == null
                            ? Center(
                                child: FaIcon(
                                  isGroup ? FontAwesomeIcons.users : FontAwesomeIcons.bullhorn,
                                  size: 26 * scale,
                                  color: textSecondary,
                                ),
                              )
                            : null,
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: EdgeInsets.all(5 * scale),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isDark ? const Color(0xFF27272A) : const Color(0xFFE4E4E7),
                            border: Border.all(color: isDark ? const Color(0xFF0C0C0C) : Colors.white, width: 2),
                          ),
                          child: Icon(
                            Icons.camera_alt_rounded,
                            size: 13 * scale,
                            color: textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 16 * scale),

              // Name Field
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isGroup
                          ? _ChannelModalL10n.get('label_group_name', lang)
                          : _ChannelModalL10n.get('label_channel_name', lang),
                      style: TextStyle(
                        fontSize: 12 * scale,
                        fontWeight: FontWeight.w600,
                        color: textSecondary,
                        fontFamily: 'Inter',
                      ),
                    ),
                    SizedBox(height: 6 * scale),
                    TextField(
                      controller: nameController,
                      style: TextStyle(fontSize: 14 * scale, color: textPrimary, fontFamily: 'Inter'),
                      decoration: InputDecoration(
                        hintText: isGroup
                            ? _ChannelModalL10n.get('hint_group_name', lang)
                            : _ChannelModalL10n.get('hint_channel_name', lang),
                        hintStyle: TextStyle(fontSize: 13 * scale, color: textSecondary.withValues(alpha: 0.6)),
                        filled: true,
                        fillColor: inputBg,
                        contentPadding: EdgeInsets.symmetric(horizontal: 14 * scale, vertical: 12 * scale),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8 * scale),
                          borderSide: BorderSide(color: borderColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8 * scale),
                          borderSide: BorderSide(color: isDark ? Colors.white54 : Colors.black54),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: 16 * scale),

          // Privacy Type Toggle
          Text(
            _ChannelModalL10n.get('label_privacy', lang),
            style: TextStyle(
              fontSize: 12 * scale,
              fontWeight: FontWeight.w600,
              color: textSecondary,
              fontFamily: 'Inter',
            ),
          ),
          SizedBox(height: 8 * scale),
          Row(
            children: [
              Expanded(
                child: _buildPrivacyOption(
                  context: context,
                  isDark: isDark,
                  scale: scale,
                  selected: !isPrivate,
                  title: _ChannelModalL10n.get('privacy_public_title', lang),
                  subtitle: _ChannelModalL10n.get('privacy_public_sub', lang),
                  icon: Icons.public_rounded,
                  onTap: () => setState(() => isPrivate = false),
                ),
              ),
              SizedBox(width: 10 * scale),
              Expanded(
                child: _buildPrivacyOption(
                  context: context,
                  isDark: isDark,
                  scale: scale,
                  selected: isPrivate,
                  title: _ChannelModalL10n.get('privacy_private_title', lang),
                  subtitle: _ChannelModalL10n.get('privacy_private_sub', lang),
                  icon: Icons.lock_outline_rounded,
                  onTap: () => setState(() => isPrivate = true),
                ),
              ),
            ],
          ),

          SizedBox(height: 16 * scale),

          // Public Link / Username (Only if public)
          if (!isPrivate) ...[
            Text(
              _ChannelModalL10n.get('label_link', lang),
              style: TextStyle(
                fontSize: 12 * scale,
                fontWeight: FontWeight.w600,
                color: textSecondary,
                fontFamily: 'Inter',
              ),
            ),
            SizedBox(height: 6 * scale),
            TextField(
              controller: usernameController,
              style: TextStyle(fontSize: 14 * scale, color: textPrimary, fontFamily: 'Inter'),
              decoration: InputDecoration(
                prefixText: '@',
                prefixStyle: TextStyle(fontSize: 14 * scale, fontWeight: FontWeight.bold, color: textPrimary),
                hintText: _ChannelModalL10n.get('hint_username', lang),
                hintStyle: TextStyle(fontSize: 13 * scale, color: textSecondary.withValues(alpha: 0.6)),
                filled: true,
                fillColor: inputBg,
                contentPadding: EdgeInsets.symmetric(horizontal: 14 * scale, vertical: 12 * scale),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8 * scale),
                  borderSide: BorderSide(color: borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8 * scale),
                  borderSide: BorderSide(color: isDark ? Colors.white54 : Colors.black54),
                ),
              ),
            ),
            SizedBox(height: 16 * scale),
          ],

          // Description Field
          Text(
            _ChannelModalL10n.get('label_description', lang),
            style: TextStyle(
              fontSize: 12 * scale,
              fontWeight: FontWeight.w600,
              color: textSecondary,
              fontFamily: 'Inter',
            ),
          ),
          SizedBox(height: 6 * scale),
          TextField(
            controller: descriptionController,
            maxLines: 3,
            style: TextStyle(fontSize: 14 * scale, color: textPrimary, fontFamily: 'Inter'),
            decoration: InputDecoration(
              hintText: _ChannelModalL10n.get('hint_description', lang),
              hintStyle: TextStyle(fontSize: 13 * scale, color: textSecondary.withValues(alpha: 0.6)),
              filled: true,
              fillColor: inputBg,
              contentPadding: EdgeInsets.all(14 * scale),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8 * scale),
                borderSide: BorderSide(color: borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8 * scale),
                borderSide: BorderSide(color: isDark ? Colors.white54 : Colors.black54),
              ),
            ),
          ),

          SizedBox(height: 24 * scale),

          // Action Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Cancel Button
              TextButton(
                onPressed: isLoading ? null : () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 18 * scale, vertical: 12 * scale),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8 * scale)),
                ),
                child: Text(
                  _ChannelModalL10n.get('cancel', lang),
                  style: TextStyle(
                    fontSize: 13 * scale,
                    color: textSecondary,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
              SizedBox(width: 8 * scale),

              // Submit Button
              ElevatedButton(
                onPressed: isLoading ? null : handleSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? Colors.white : Colors.black,
                  foregroundColor: isDark ? Colors.black : Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 22 * scale, vertical: 12 * scale),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8 * scale)),
                ),
                child: isLoading
                    ? SizedBox(
                        width: 16 * scale,
                        height: 16 * scale,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: isDark ? Colors.black : Colors.white,
                        ),
                      )
                    : Text(
                        isEditing
                            ? _ChannelModalL10n.get('save', lang)
                            : _ChannelModalL10n.get('create', lang),
                        style: TextStyle(
                          fontSize: 13 * scale,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Inter',
                        ),
                      ),
              ),
            ],
          ),
          SizedBox(height: 8 * scale),
        ],
      ),
    );
  }

  Widget _buildPrivacyOption({
    required BuildContext context,
    required bool isDark,
    required double scale,
    required bool selected,
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final activeBg = isDark ? const Color(0xFF27272A) : const Color(0xFFE4E4E7);
    final inactiveBg = isDark ? const Color(0xFF141416) : const Color(0xFFF4F4F5);
    final borderColor = selected
        ? (isDark ? Colors.white : Colors.black)
        : (isDark ? const Color(0xFF242428) : const Color(0xFFE4E4E7));

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: EdgeInsets.all(12 * scale),
          decoration: BoxDecoration(
            color: selected ? activeBg : inactiveBg,
            borderRadius: BorderRadius.circular(8 * scale),
            border: Border.all(color: borderColor, width: selected ? 1.5 : 1),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 18 * scale,
                color: selected
                    ? (isDark ? Colors.white : Colors.black)
                    : (isDark ? Colors.white38 : Colors.black38),
              ),
              SizedBox(width: 10 * scale),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 13 * scale,
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                        color: isDark ? Colors.white : Colors.black,
                        fontFamily: 'Inter',
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11 * scale,
                        color: isDark ? Colors.white54 : Colors.black54,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChannelModalL10n {
  static const Map<String, Map<String, String>> _map = {
    'ru': {
      'create_channel_tag': 'КАНАЛ',
      'create_group_tag': 'ГРУППА',
      'edit_channel_tag': 'РЕДАКТИРОВАНИЕ КАНАЛА',
      'edit_group_tag': 'РЕДАКТИРОВАНИЕ ГРУППЫ',
      'title_create_channel': 'Создание канала',
      'title_create_group': 'Создание группы',
      'title_edit_channel': 'Редактировать канал',
      'title_edit_group': 'Редактировать группу',
      'label_channel_name': 'Название канала',
      'label_group_name': 'Название группы',
      'hint_channel_name': 'Например, Новости Xaneo',
      'hint_group_name': 'Например, Команда разработчиков',
      'label_privacy': 'Тип',
      'privacy_public_title': 'Публичный',
      'privacy_public_sub': 'Доступен по ссылке',
      'privacy_private_title': 'Частный',
      'privacy_private_sub': 'Только по инвайту',
      'label_link': 'Публичная ссылка (@tag)',
      'hint_username': 'укажите_ссылку',
      'label_description': 'Описание (необязательно)',
      'hint_description': 'Расскажите о вашей группе или канале...',
      'cancel': 'Отмена',
      'create': 'Создать',
      'save': 'Сохранить',
      'err_channel_name': 'Введите название канала',
      'err_group_name': 'Введите название группы',
      'err_username_required': 'Для публичного типа требуется ссылка',
      'err_generic': 'Ошибка создания',
      'channel_created': 'Канал успешно создан!',
      'group_created': 'Группа успешно создана!',
    },
    'en': {
      'create_channel_tag': 'CHANNEL',
      'create_group_tag': 'GROUP',
      'edit_channel_tag': 'EDIT CHANNEL',
      'edit_group_tag': 'EDIT GROUP',
      'title_create_channel': 'Create Channel',
      'title_create_group': 'Create Group',
      'title_edit_channel': 'Edit Channel',
      'title_edit_group': 'Edit Group',
      'label_channel_name': 'Channel Name',
      'label_group_name': 'Group Name',
      'hint_channel_name': 'e.g. Xaneo News',
      'hint_group_name': 'e.g. Developer Team',
      'label_privacy': 'Privacy Type',
      'privacy_public_title': 'Public',
      'privacy_public_sub': 'Accessible via link',
      'privacy_private_title': 'Private',
      'privacy_private_sub': 'Invite only',
      'label_link': 'Public Link (@tag)',
      'hint_username': 'enter_handle',
      'label_description': 'Description (optional)',
      'hint_description': 'Tell people about your group or channel...',
      'cancel': 'Cancel',
      'create': 'Create',
      'save': 'Save',
      'err_channel_name': 'Please enter channel name',
      'err_group_name': 'Please enter group name',
      'err_username_required': 'Public handle is required for public privacy',
      'err_generic': 'Creation failed',
      'channel_created': 'Channel successfully created!',
      'group_created': 'Group successfully created!',
    },
    'es': {
      'create_channel_tag': 'CANAL',
      'create_group_tag': 'GRUPO',
      'edit_channel_tag': 'EDITAR CANAL',
      'edit_group_tag': 'EDITAR GRUPO',
      'title_create_channel': 'Crear Canal',
      'title_create_group': 'Crear Grupo',
      'title_edit_channel': 'Editar Canal',
      'title_edit_group': 'Editar Grupo',
      'label_channel_name': 'Nombre del canal',
      'label_group_name': 'Nombre del grupo',
      'hint_channel_name': 'p. ej. Noticias Xaneo',
      'hint_group_name': 'p. ej. Equipo de Desarrollo',
      'label_privacy': 'Tipo de privacidad',
      'privacy_public_title': 'Público',
      'privacy_public_sub': 'Accesible por enlace',
      'privacy_private_title': 'Privado',
      'privacy_private_sub': 'Solo con invitación',
      'label_link': 'Enlace público (@tag)',
      'hint_username': 'nombre_usuario',
      'label_description': 'Descripción (opcional)',
      'hint_description': 'Describe tu grupo o canal...',
      'cancel': 'Cancelar',
      'create': 'Crear',
      'save': 'Guardar',
      'err_channel_name': 'Introduce el nombre del canal',
      'err_group_name': 'Introduce el nombre del grupo',
      'err_username_required': 'El enlace público es obligatorio para canal público',
      'err_generic': 'Error al crear',
      'channel_created': '¡Canal creado con éxito!',
      'group_created': '¡Grupo creado con éxito!',
    },
    'fr': {
      'create_channel_tag': 'CHAÎNE',
      'create_group_tag': 'GROUPE',
      'edit_channel_tag': 'MODIFIER CHAÎNE',
      'edit_group_tag': 'MODIFIER GROUPE',
      'title_create_channel': 'Créer une chaîne',
      'title_create_group': 'Créer un groupe',
      'title_edit_channel': 'Modifier la chaîne',
      'title_edit_group': 'Modifier le groupe',
      'label_channel_name': 'Nom de la chaîne',
      'label_group_name': 'Nom du groupe',
      'hint_channel_name': 'ex. Actualités Xaneo',
      'hint_group_name': 'ex. Équipe de développement',
      'label_privacy': 'Confidentialité',
      'privacy_public_title': 'Public',
      'privacy_public_sub': 'Accessible par lien',
      'privacy_private_title': 'Privé',
      'privacy_private_sub': 'Sur invitation seulement',
      'label_link': 'Lien public (@tag)',
      'hint_username': 'nom_utilisateur',
      'label_description': 'Description (optionnelle)',
      'hint_description': 'Présentez votre groupe ou chaîne...',
      'cancel': 'Annuler',
      'create': 'Créer',
      'save': 'Enregistrer',
      'err_channel_name': 'Veuillez saisir le nom de la chaîne',
      'err_group_name': 'Veuillez saisir le nom du groupe',
      'err_username_required': 'Le lien public est requis pour le mode public',
      'err_generic': 'Échec de la création',
      'channel_created': 'Chaîne créée avec succès !',
      'group_created': 'Groupe créé avec succès !',
    },
    'ar': {
      'create_channel_tag': 'قناة',
      'create_group_tag': 'مجموعة',
      'edit_channel_tag': 'تعديل القناة',
      'edit_group_tag': 'تعديل المجموعة',
      'title_create_channel': 'إنشاء قناة',
      'title_create_group': 'إنشاء مجموعة',
      'title_edit_channel': 'تعديل القناة',
      'title_edit_group': 'تعديل المجموعة',
      'label_channel_name': 'اسم القناة',
      'label_group_name': 'اسم المجموعة',
      'hint_channel_name': 'مثال: أخبار Xaneo',
      'hint_group_name': 'مثال: فريق التطوير',
      'label_privacy': 'نوع الخصوصية',
      'privacy_public_title': 'عامة',
      'privacy_public_sub': 'متاحة عبر الرابط',
      'privacy_private_title': 'خاصة',
      'privacy_private_sub': 'بدعوة فقط',
      'label_link': 'الرابط العام (@tag)',
      'hint_username': 'اسم_المستخدم',
      'label_description': 'الوصف (اختياري)',
      'hint_description': 'أخبر الناس عن مجموعتك أو قناتك...',
      'cancel': 'إلغاء',
      'create': 'إنشاء',
      'save': 'حفظ',
      'err_channel_name': 'الرجاء إدخال اسم القناة',
      'err_group_name': 'الرجاء إدخال اسم المجموعة',
      'err_username_required': 'الرابط العام مطلوب للقنوات العامة',
      'err_generic': 'فشل الإنشاء',
      'channel_created': 'تم إنشاء القناة بنجاح!',
      'group_created': 'تم إنشاء المجموعة بنجاح!',
    },
    'ja': {
      'create_channel_tag': 'チャンネル',
      'create_group_tag': 'グループ',
      'edit_channel_tag': 'チャンネル編集',
      'edit_group_tag': 'グループ編集',
      'title_create_channel': 'チャンネルを作成',
      'title_create_group': 'グループを作成',
      'title_edit_channel': 'チャンネルを編集',
      'title_edit_group': 'グループを編集',
      'label_channel_name': 'チャンネル名',
      'label_group_name': 'グループ名',
      'hint_channel_name': '例: Xaneoニュース',
      'hint_group_name': '例: 開発チーム',
      'label_privacy': '公開タイプ',
      'privacy_public_title': '公開',
      'privacy_public_sub': 'リンクでアクセス可能',
      'privacy_private_title': '非公開',
      'privacy_private_sub': '招待のみ',
      'label_link': '公開リンク (@tag)',
      'hint_username': 'ユーザー名',
      'label_description': '説明（任意）',
      'hint_description': 'グループやチャンネルの紹介を入力...',
      'cancel': 'キャンセル',
      'create': '作成',
      'save': '保存',
      'err_channel_name': 'チャンネル名を入力してください',
      'err_group_name': 'グループ名を入力してください',
      'err_username_required': '公開設定にはユーザー名リンクが必要です',
      'err_generic': '作成に失敗しました',
      'channel_created': 'チャンネルを正常に作成しました！',
      'group_created': 'グループを正常に作成しました！',
    },
    'ko': {
      'create_channel_tag': '채널',
      'create_group_tag': '그룹',
      'edit_channel_tag': '채널 편집',
      'edit_group_tag': '그룹 편집',
      'title_create_channel': '채널 만들기',
      'title_create_group': '그룹 만들기',
      'title_edit_channel': '채널 편집',
      'title_edit_group': '그룹 편집',
      'label_channel_name': '채널 이름',
      'label_group_name': '그룹 이름',
      'hint_channel_name': '예: Xaneo 뉴스',
      'hint_group_name': '예: 개발자 팀',
      'label_privacy': '공개 유형',
      'privacy_public_title': '공개',
      'privacy_public_sub': '링크로 접근 가능',
      'privacy_private_title': '비공개',
      'privacy_private_sub': '초대전용',
      'label_link': '공개 링크 (@tag)',
      'hint_username': '사용자명 입력',
      'label_description': '설명 (선택사항)',
      'hint_description': '그룹 또는 채널에 대한 설명을 입력하세요...',
      'cancel': '취소',
      'create': '만들기',
      'save': '저장',
      'err_channel_name': '채널 이름을 입력하세요',
      'err_group_name': '그룹 이름을 입력하세요',
      'err_username_required': '공개 설정시 공개 링크 태그가 필요합니다',
      'err_generic': '생성에 실패했습니다',
      'channel_created': '채널이 성공적으로 생성되었습니다!',
      'group_created': '그룹이 성공적으로 생성되었습니다!',
    },
    'zh': {
      'create_channel_tag': '频道',
      'create_group_tag': '群组',
      'edit_channel_tag': '编辑频道',
      'edit_group_tag': '编辑群组',
      'title_create_channel': '创建频道',
      'title_create_group': '创建群组',
      'title_edit_channel': '编辑频道',
      'title_edit_group': '编辑群组',
      'label_channel_name': '频道名称',
      'label_group_name': '群组名称',
      'hint_channel_name': '例如：Xaneo 新闻',
      'hint_group_name': '例如：开发团队',
      'label_privacy': '公开类型',
      'privacy_public_title': '公开',
      'privacy_public_sub': '可通过链接访问',
      'privacy_private_title': '私密',
      'privacy_private_sub': '仅限受邀加入',
      'label_link': '公开链接 (@tag)',
      'hint_username': '输入用户名',
      'label_description': '简介 (可选)',
      'hint_description': '向大家介绍您的群组或频道...',
      'cancel': '取消',
      'create': '创建',
      'save': '保存',
      'err_channel_name': '请输入频道名称',
      'err_group_name': '请输入群组名称',
      'err_username_required': '公开模式必须填写公开链接标签',
      'err_generic': '创建失败',
      'channel_created': '频道创建成功！',
      'group_created': '群组创建成功！',
    },
  };

  static String get(String key, String lang) {
    final l = _map.containsKey(lang) ? lang : 'en';
    return _map[l]?[key] ?? _map['en']?[key] ?? key;
  }
}
