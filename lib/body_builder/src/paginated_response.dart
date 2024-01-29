import 'package:json_annotation/json_annotation.dart';

mixin class PaginatedResponse<T> {
  @JsonKey(name: 'data')
  List<T>? items;
  @JsonKey(name: 'path')
  String? path;
  @JsonKey(name: 'current_page')
  int? currentPage;
  @JsonKey(name: 'last_page')
  int? lastPage;

  // This class is intended to be used as a mixin, and should not be
  // extended directly.
  factory PaginatedResponse._() => throw Exception('No');
}
