import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'job_model.freezed.dart';
part 'job_model.g.dart';

@freezed
abstract class JobModel with _$JobModel {
  const factory JobModel({
    required String id,
    required String title,
    required String company,
    required String location,
    @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)
    required DateTime datePosted,
    required double salary,
    required String description,
    required List<String> tags,
  }) = _JobModel;

  factory JobModel.fromJson(Map<String, dynamic> json) =>
      _$JobModelFromJson(json);
}

DateTime _timestampFromJson(dynamic date) {
  if (date is Timestamp) {
    return date.toDate();
  }
  return DateTime.parse(date as String);
}

dynamic _timestampToJson(DateTime date) => Timestamp.fromDate(date);
