import 'package:flutter_test/flutter_test.dart';
import 'package:xaneo/services/crypto_service.dart';

void main() {
  test('discussion mirror uses the original channel key', () {
    expect(
      CryptoService.decryptionChatIdForMessage('group_1', {
        'message_type': 'channel_post_mirror',
        'message_data': {'channel_id': 7},
      }),
      'channel_7',
    );
  });

  test('ordinary group messages keep the group key', () {
    expect(
      CryptoService.decryptionChatIdForMessage('group_1', {
        'message_type': 'regular',
        'message_data': {'channel_id': 7},
      }),
      'group_1',
    );
  });

  test('invalid channel metadata does not change the key', () {
    expect(
      CryptoService.decryptionChatIdForMessage('group_1', {
        'message_type': 'channel_post_mirror',
        'message_data': {'channel_id': 0},
      }),
      'group_1',
    );
  });

  test('live mirror can use its top-level channel id', () {
    expect(
      CryptoService.decryptionChatIdForMessage('group_1', {
        'message_type': 'channel_post_mirror',
        'channel_id': 7,
        'message_data': <String, dynamic>{},
      }),
      'channel_7',
    );
  });
}
