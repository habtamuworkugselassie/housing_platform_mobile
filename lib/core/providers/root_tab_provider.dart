import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Current bottom navigation tab index. Home can set this to 1 to switch to Explore (e.g. "See All").
final rootTabIndexProvider = StateProvider<int>((ref) => 0);
