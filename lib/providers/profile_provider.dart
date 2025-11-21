import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/profile_service.dart';
import 'auth_provider.dart';

final profileServiceProvider = Provider<ProfileService>((ref) {
  return ProfileService();
});

final userProfileStreamProvider = StreamProvider<Map<String, dynamic>?>((ref) {
  final authState = ref.watch(authStateProvider);
  final user = authState.value;

  if (user == null) {
    return Stream<Map<String, dynamic>?>.value(null);
  }

  final profileService = ref.watch(profileServiceProvider);
  return profileService.getUserProfileStream();
});

