import 'package:supabase_flutter/supabase_flutter.dart';

class SliderService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Fetch active slider items ordered by display_order
  Future<List<Map<String, dynamic>>> fetchActiveSliders() async {
    try {
      final response = await _supabase
          .from('slider')
          .select()
          .eq('is_active', true)
          .order('display_order', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }
}