import 'package:body_builder/body_builder.dart';

class PaginatedSampleState extends PaginatedState<String> {}

class SearchSampleState extends PaginatedState<String> {}

class BasicSampleState extends SimpleStateProvider<String> {}

class MultiProviderSampleState extends RelatedStateProvider<int, String> {}
