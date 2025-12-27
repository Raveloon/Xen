// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'job_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_JobModel _$JobModelFromJson(Map<String, dynamic> json) => _JobModel(
  id: json['id'] as String,
  title: json['title'] as String,
  company: json['company'] as String,
  location: json['location'] as String,
  datePosted: _timestampFromJson(json['datePosted']),
  salary: (json['salary'] as num).toDouble(),
  description: json['description'] as String,
  tags: (json['tags'] as List<dynamic>).map((e) => e as String).toList(),
);

Map<String, dynamic> _$JobModelToJson(_JobModel instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'company': instance.company,
  'location': instance.location,
  'datePosted': _timestampToJson(instance.datePosted),
  'salary': instance.salary,
  'description': instance.description,
  'tags': instance.tags,
};
