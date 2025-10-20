import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:ella_passenger/features/auth/data/device_datasource.dart';
import 'package:ella_passenger/features/auth/data/firebase_auth_datasource.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../features/auth/data/auth_repository_impl.dart';
import '../features/auth/data/user_profile_datasource.dart';
import '../features/auth/domain/auth_repository.dart';
import '../features/auth/presentation/notifiers/phone_auth_notifier.dart';

List<SingleChildWidget> buildAuthProviders() => [
  Provider<FirebaseAuth>(create: (_) => FirebaseAuth.instance),
  Provider<FirebaseFirestore>(create: (_) => FirebaseFirestore.instance),
  Provider<FirebaseFunctions>(create: (_) => FirebaseFunctions.instanceFor(region: 'europe-west1')),
  Provider<FirebaseAuthDataSource>(
    create: (c) => FirebaseAuthDataSource(c.read<FirebaseAuth>()),
  ),
  Provider<UserProfileDataSource>(
    create: (c) => UserProfileDataSource(c.read<FirebaseFirestore>()),
  ),
  Provider<DeviceDataSource>(
    create: (c) =>
        DeviceDataSource(c.read<FirebaseFunctions>(), c.read<FirebaseAuth>()),
  ),
  Provider<AuthRepository>(
    create: (c) => AuthRepositoryImpl(c.read<FirebaseAuthDataSource>()),
  ),
  ChangeNotifierProvider<PhoneAuthNotifier>(
    create: (c) => PhoneAuthNotifier(
      authDs: c.read<FirebaseAuthDataSource>(),
      profileDs: c.read<UserProfileDataSource>(),
      deviceDs: c.read<DeviceDataSource>(),
    ),
  ),
];
