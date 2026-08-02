import 'package:flutter/material.dart';
import 'base_custom_modal.dart';
import 'create_channel_modal.dart';

/// Desktop-модалка создания группы (наследуется от CreateChannelModal)
class CreateGroupModal extends CreateChannelModal {
  const CreateGroupModal({
    super.key,
    super.isEditing = false,
    super.initialData,
  }) : super(
          isGroup: true,
          modalTag: 'ГРУППА',
          title: 'СОЗДАТЬ ГРУППУ',
        );

  static Future<void> show({
    required BuildContext context,
    bool isEditing = false,
    Map<String, dynamic>? initialData,
  }) {
    return BaseCustomModal.show(
      context: context,
      modal: CreateGroupModal(
        isEditing: isEditing,
        initialData: initialData,
      ),
    );
  }
}
