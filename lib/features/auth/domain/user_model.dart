import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_model.freezed.dart';
part 'user_model.g.dart';

@freezed
abstract class UserModel with _$UserModel {
  const factory UserModel({
    required String id,
    required String username,
    required String password,
    @Default('') String fullName,
    @Default([]) List<String> interests,
    @Default([]) List<String> favoriteIds,
    String? photoUrl,
  }) = _UserModel;




  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);
}

extension UserModelX on UserModel {
  bool get isAdmin => username == 'emre' || username == 'emre@xen.com';
}
