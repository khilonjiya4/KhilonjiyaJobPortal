import 'package:supabase_flutter/supabase_flutter.dart';

class SearchService {
  final SupabaseClient _db = Supabase.instance.client;

  // =========================================================
  // SEARCH JOBS (Paginated + Filters)
  // =========================================================

  Future<List<Map<String, dynamic>>> searchJobs({
    required String query,
    int page = 0,
    String? district,
    String? jobType,
    int? minSalary,
  }) async {
    final int pageSize = 20;

    var builder = _db
        .from('job_listings')
        .select('''
          id,
          job_title,
          district,
          salary_min,
          salary_max,
          work_mode,
          employment_type,
          created_at,
          companies (
            id,
            name,
            logo_url,
            is_verified
          )
        ''')
        .eq('status', 'active');

    // Full text search
    if (query.trim().isNotEmpty) {
      builder = builder.textSearch('search_vector', query);
    }

    // Filters
    if (district != null && district.isNotEmpty) {
      builder = builder.eq('district', district);
    }

    if (jobType != null && jobType.isNotEmpty) {
      builder = builder.eq('employment_type', jobType);
    }

    if (minSalary != null && minSalary > 0) {
      builder = builder.gte('salary_max', minSalary);
    }

    final res = await builder
        .order('created_at', ascending: false)
        .range(page * pageSize, (page + 1) * pageSize - 1);

    return List<Map<String, dynamic>>.from(res);
  }

  // =========================================================
  // SAVE USER SEARCH HISTORY
  // =========================================================

  Future<void> saveUserSearch(String keyword) async {
    final user = _db.auth.currentUser;
    if (user == null) return;

    await _db.from('user_search_history').insert({
      'user_id': user.id,
      'keyword': keyword,
    });
  }

  Future<List<String>> getDistricts() async {
  final res = await _db
      .from('assam_district_master')
      .select('district_name')
      .order('district_name', ascending: true);

  return res
      .map<String>((e) => e['district_name'].toString())
      .toList();
}

  // =========================================================
  // GET USER RECENT SEARCHES
  // =========================================================

  Future<List<String>> getRecentSearches() async {
    final user = _db.auth.currentUser;
    if (user == null) return [];

    final res = await _db
        .from('user_search_history')
        .select('keyword')
        .eq('user_id', user.id)
        .order('searched_at', ascending: false)
        .limit(6);

    return res.map<String>((e) => e['keyword'].toString()).toSet().toList();
  }

  // =========================================================
  // GET TRENDING SEARCHES
  // =========================================================

  Future<List<String>> getTrendingSearches() async {
    final res = await _db
        .from('search_trends')
        .select('keyword')
        .order('search_count', ascending: false)
        .limit(6);

    return res.map<String>((e) => e['keyword'].toString()).toList();
  }

  // =========================================================
  // INCREMENT TREND COUNTER
  // =========================================================

  Future<void> incrementTrend(String keyword) async {
    await _db.rpc('increment_search_trend', params: {
      'p_keyword': keyword,
    });
  }
}