import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class JobSeekerHomeService {
  final SupabaseClient _db = Supabase.instance.client;

  // ============================================================
  // STORAGE
  // ============================================================

  static const String _bucketJobFiles = 'job-files';
  static const String _folderPhotos = 'photos';
  static const String _folderResumes = 'resumes';

  // how long signed URLs should live
  static const int _signedUrlExpirySeconds = 60 * 60; // 1 hour

  // ============================================================
  // AUTH GUARD
  // ============================================================

  void _ensureAuthenticatedSync() {
    final user = _db.auth.currentUser;
    final session = _db.auth.currentSession;

    if (user == null || session == null) {
      throw Exception('Authentication required. Please login again.');
    }
  }

  String _userId() {
    _ensureAuthenticatedSync();
    return _db.auth.currentUser!.id;
  }

  // ============================================================
  // COMMON SELECT (Job + Company + Business Type)
  // ============================================================

  String get _jobWithCompanySelect => '''
    *,
    companies (
      id,
      name,
      slug,
      logo_url,
      industry,
      is_verified,
      rating,
      total_reviews,
      company_size,
      description,
      website,

      business_type_id,
      business_types_master (
        id,
        type_name,
        logo_url
      )
    )
  ''';

  // ============================================================
  // STORAGE HELPERS
  // ============================================================

  bool _looksLikeHttpUrl(String s) {
    final v = s.trim().toLowerCase();
    return v.startsWith('http://') || v.startsWith('https://');
  }

  String _cleanFileExt(String? ext) {
    if (ext == null) return '';
    final v = ext.trim().toLowerCase().replaceAll('.', '');
    if (v.isEmpty) return '';
    if (v.length > 8) return '';
    return v;
  }

  String _randomToken() {
    final r = Random();
    return "${DateTime.now().millisecondsSinceEpoch}_${r.nextInt(999999)}";
  }

  String _contentTypeFromExt(String ext) {
    switch (ext.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      default:
        return 'application/octet-stream';
    }
  }

  /// Convert a stored path like:
  ///   photos/{userId}/xxx.jpg
  /// into a signed URL.
  ///
  /// If already looks like http URL, returns as-is.
  Future<String> _toSignedUrlIfNeeded(String raw) async {
    final v = raw.trim();
    if (v.isEmpty) return '';
    if (_looksLikeHttpUrl(v)) return v;

    try {
      final signed = await _db.storage.from(_bucketJobFiles).createSignedUrl(
            v,
            _signedUrlExpirySeconds,
          );
      return signed;
    } catch (_) {
      // fallback: return original path
      return v;
    }
  }

  // ============================================================
  // PROFILE FILE UPLOADS
  // ============================================================

  /// Upload profile photo.
  ///
  /// Returns storage path like:
  ///   photos/{userId}/avatar_...jpg
  ///
  /// Store this in user_profiles.avatar_url
  Future<String> uploadMyProfilePhoto({
    required Uint8List bytes,
    required String fileExtension,
  }) async {
    _ensureAuthenticatedSync();
    final userId = _userId();

    final ext = _cleanFileExt(fileExtension);
    if (ext.isEmpty) {
      throw Exception("Invalid photo file type");
    }

    final path = '$_folderPhotos/$userId/avatar_${_randomToken()}.$ext';

    await _db.storage.from(_bucketJobFiles).uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            upsert: true,
            contentType: _contentTypeFromExt(ext),
          ),
        );

    return path;
  }

  /// Upload resume file.
  ///
  /// Returns storage path like:
  ///   resumes/{userId}/resume_...pdf
  ///
  /// Store this in user_profiles.resume_url
  Future<String> uploadMyResume({
    required Uint8List bytes,
    required String fileExtension,
  }) async {
    _ensureAuthenticatedSync();
    final userId = _userId();

    final ext = _cleanFileExt(fileExtension);
    if (ext.isEmpty) {
      throw Exception("Invalid resume file type");
    }

    final path = '$_folderResumes/$userId/resume_${_randomToken()}.$ext';

    await _db.storage.from(_bucketJobFiles).uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            upsert: true,
            contentType: _contentTypeFromExt(ext),
          ),
        );

    return path;
  }

  /// Upload resume + save to profile in DB
  Future<String> uploadMyResumeAndSave({
    required Uint8List bytes,
    required String fileExtension,
  }) async {
    final path = await uploadMyResume(bytes: bytes, fileExtension: fileExtension);

    await updateMyProfile({
      'resume_url': path,
    });

    return path;
  }


Future<List<Map<String, dynamic>>> fetchPremiumJobs({
  int offset = 0,
  int limit = 20,
}) async {
  _ensureAuthenticatedSync();

  final nowIso = DateTime.now().toIso8601String();

  final res = await _db
      .from('job_listings')
      .select(_jobWithCompanySelect)
      .eq('status', 'active')
      .gte('expires_at', nowIso)
      .eq('is_premium', true)
      .order('created_at', ascending: false)
      .range(offset, offset + limit - 1);

  return List<Map<String, dynamic>>.from(res);
}



Future<List<Map<String, dynamic>>> fetchCompanyJobs({
  required String companyId,
  int offset = 0,
  int limit = 20,
}) async {
  _ensureAuthenticatedSync();

  final nowIso = DateTime.now().toIso8601String();

  final res = await _db
      .from('job_listings')
      .select(_jobWithCompanySelect)
      .eq('status', 'active')
      .gte('expires_at', nowIso)
      .eq('company_id', companyId)
      .order('created_at', ascending: false)
      .range(offset, offset + limit - 1);

  return List<Map<String, dynamic>>.from(res);
}

  /// Upload photo + save to profile in DB
  Future<String> uploadMyPhotoAndSave({
    required Uint8List bytes,
    required String fileExtension,
  }) async {
    final path = await uploadMyProfilePhoto(
      bytes: bytes,
      fileExtension: fileExtension,
    );

    await updateMyProfile({
      'avatar_url': path,
    });

    return path;
  }




// ============================================================
  // JOB APPLICATIONS (REAL APPLY)
  // ============================================================

  /// Get or create the user's master application row in `job_applications`.
  /// Returns application_id (uuid string).
  Future<String> _getOrCreateMyMasterApplication({
    String? name,
    String? phone,
    String? email,
    String? district,
    String? address,
    String? education,
    String? experienceLevel,
    String? experienceDetails,
    String? skills,
    String? expectedSalary,
    String? availability,
    String? additionalInfo,
    String? resumeFileName,
    String? resumeFileUrl,
    String? photoFileName,
    String? photoFileUrl,
    List<String>? jobCategories,
  }) async {
    _ensureAuthenticatedSync();
    final userId = _userId();

    // 1) check existing
    final existing = await _db
        .from('job_applications')
        .select('id')
        .eq('user_id', userId)
        .maybeSingle();

    // 2) if exists -> update (light update)
    if (existing != null) {
      final appId = existing['id'].toString();

      final updatePayload = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      void put(String key, dynamic value) {
        if (value == null) return;
        if (value is String && value.trim().isEmpty) return;
        updatePayload[key] = value;
      }

      put('name', name);
      put('phone', phone);
      put('email', email);
      put('district', district);
      put('address', address);
      put('education', education);
      put('experience_level', experienceLevel);
      put('experience_details', experienceDetails);
      put('skills', skills);
      put('expected_salary', expectedSalary);
      put('availability', availability);
      put('additional_info', additionalInfo);

      put('resume_file_name', resumeFileName);
      put('resume_file_url', resumeFileUrl);
      put('photo_file_name', photoFileName);
      put('photo_file_url', photoFileUrl);

      if (jobCategories != null) {
        updatePayload['job_categories'] = jobCategories;
      }

      // only update if something meaningful exists
      if (updatePayload.length > 1) {
        await _db.from('job_applications').update(updatePayload).eq('id', appId);
      }

      return appId;
    }

    // 3) create new
    final insertPayload = <String, dynamic>{
      'user_id': userId,
      'name': (name ?? '').trim(),
      'phone': (phone ?? '').trim(),
      'email': (email ?? '').trim(),
      'district': (district ?? '').trim(),
      'address': (address ?? '').trim(),
      'education': (education ?? '').trim(),
      'experience_level': (experienceLevel ?? '').trim(),
      'experience_details': (experienceDetails ?? '').trim(),
      'skills': (skills ?? '').trim(),
      'expected_salary': (expectedSalary ?? '').trim(),
      'availability': (availability ?? '').trim(),
      'additional_info': (additionalInfo ?? '').trim(),
      'resume_file_name': (resumeFileName ?? '').trim(),
      'resume_file_url': (resumeFileUrl ?? '').trim(),
      'photo_file_name': (photoFileName ?? '').trim(),
      'photo_file_url': (photoFileUrl ?? '').trim(),
      'job_categories': jobCategories ?? <String>[],
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
      'status': 'submitted',
    };

    // required fields in schema: name, phone, email, skills
    if ((insertPayload['name'] as String).trim().isEmpty) {
      throw Exception("Name is required");
    }
    if ((insertPayload['phone'] as String).trim().isEmpty) {
      throw Exception("Phone is required");
    }
    if ((insertPayload['email'] as String).trim().isEmpty) {
      throw Exception("Email is required");
    }
    if ((insertPayload['skills'] as String).trim().isEmpty) {
      throw Exception("Skills are required");
    }

    final created = await _db
        .from('job_applications')
        .insert(insertPayload)
        .select('id')
        .single();

    return created['id'].toString();
  }

  /// Real apply to a job.
  ///
  /// - creates/updates master application in `job_applications`
  /// - inserts mapping row in `job_applications_listings`
  /// - returns true if applied, false if already applied
  Future<bool> applyToJob({
    required String jobId,
    required Map<String, dynamic> form,
  }) async {
    _ensureAuthenticatedSync();
    final userId = _userId();

    // 0) already applied guard
    final already = await hasAppliedToJob(jobId);
    if (already) return false;

    // 1) load profile (for defaults)
    final profile = await fetchMyProfile();

    final name = (form['name'] ?? profile['full_name'] ?? '').toString().trim();
    final phone =
        (form['phone'] ?? profile['mobile_number'] ?? '').toString().trim();
    final email = (form['email'] ?? profile['email'] ?? '').toString().trim();

    final district = (form['district'] ?? '').toString().trim();
    final address = (form['address'] ?? '').toString().trim();

    final education =
        (form['education'] ?? profile['highest_education'] ?? '')
            .toString()
            .trim();

    final experienceLevel = (form['experience_level'] ?? '').toString().trim();
    final experienceDetails =
        (form['experience_details'] ?? '').toString().trim();

    // required by schema
    final skills = (form['skills'] ??
            _skillsToText(profile['skills']) ??
            '')
        .toString()
        .trim();

    final expectedSalary = (form['expected_salary'] ??
            _expectedSalaryFromProfile(profile))
        .toString()
        .trim();

    final availability = (form['availability'] ?? '').toString().trim();
    final additionalInfo = (form['additional_info'] ?? '').toString().trim();

    // resume from profile (SIGNED url) is not good for DB.
    // So fetch raw paths for resume/avatar.
    final rawPaths = await fetchMyProfileRawPaths();

    final resumeRaw = (rawPaths['resume_url'] ?? '').toString().trim();
    final photoRaw = (rawPaths['avatar_url'] ?? '').toString().trim();

    // 2) ensure master application exists
    final applicationId = await _getOrCreateMyMasterApplication(
      name: name,
      phone: phone,
      email: email,
      district: district,
      address: address,
      education: education,
      experienceLevel: experienceLevel,
      experienceDetails: experienceDetails,
      skills: skills,
      expectedSalary: expectedSalary,
      availability: availability,
      additionalInfo: additionalInfo,
      resumeFileName: resumeRaw.isEmpty ? '' : 'resume',
      resumeFileUrl: resumeRaw,
      photoFileName: photoRaw.isEmpty ? '' : 'photo',
      photoFileUrl: photoRaw,
      jobCategories: _toStringList(form['job_categories']),
    );

    // 3) insert listing mapping
    try {
      await _db.from('job_applications_listings').insert({
        'application_id': applicationId,
        'listing_id': jobId,
        'user_id': userId,
        'applied_at': DateTime.now().toIso8601String(),
        'application_status': 'applied',
      });
    } catch (e) {
      // if unique constraint exists, this catches duplicate apply
      debugPrint("applyToJob insert error: $e");
      return false;
    }

    // 4) track activity (optional)
    try {
      await _db.from('user_job_activity').insert({
        'user_id': userId,
        'job_id': jobId,
        'activity_type': 'applied',
        'activity_date': DateTime.now().toIso8601String(),
      });
    } catch (_) {}

    return true;
  }

  String _skillsToText(dynamic raw) {
    if (raw == null) return '';
    if (raw is List) {
      final items = raw.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList();
      return items.join(', ');
    }
    return raw.toString();
  }

  String _expectedSalaryFromProfile(Map<String, dynamic> p) {
    final min = p['expected_salary_min'];
    final max = p['expected_salary_max'];

    int toInt(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      return int.tryParse(v.toString()) ?? 0;
    }

    final a = toInt(min);
    final b = toInt(max);

    if (a <= 0 && b <= 0) return '';
    if (a > 0 && b <= 0) return "₹$a / month";
    if (a <= 0 && b > 0) return "Up to ₹$b / month";
    return "₹$a - ₹$b / month";
  }

  List<String> _toStringList(dynamic raw) {
    if (raw == null) return [];
    if (raw is List) {
      return raw.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList();
    }
    return [];
  }
  // ============================================================
  // LOCATION HELPERS (Assam nearby logic)
  // ============================================================

  Future<bool> isUserInAssam() async {
    _ensureAuthenticatedSync();
    final userId = _userId();

    try {
      final p = await _db
          .from('user_profiles')
          .select('current_state, current_city, location')
          .eq('id', userId)
          .maybeSingle();

      if (p == null) return false;

      final state = (p['current_state'] ?? '').toString().trim().toLowerCase();
      final city = (p['current_city'] ?? '').toString().trim().toLowerCase();
      final loc = (p['location'] ?? '').toString().trim().toLowerCase();

      if (state == 'assam') return true;
      if (city.contains('assam')) return true;
      if (loc.contains('assam')) return true;

      return false;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, double>?> getMyCurrentLatLngFromProfile() async {
    _ensureAuthenticatedSync();
    final userId = _userId();

    try {
      final p = await _db
          .from('user_profiles')
          .select('current_latitude, current_longitude')
          .eq('id', userId)
          .maybeSingle();

      if (p == null) return null;

      double? toDouble(dynamic v) {
        if (v == null) return null;
        if (v is double) return v;
        if (v is int) return v.toDouble();
        return double.tryParse(v.toString());
      }

      final lat = toDouble(p['current_latitude']);
      final lng = toDouble(p['current_longitude']);

      if (lat == null || lng == null) return null;
      return {'lat': lat, 'lng': lng};
    } catch (_) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> fetchAssamDistrictMaster() async {
    final res = await _db
        .from('assam_districts_master')
        .select('district_name, latitude, longitude')
        .order('district_name', ascending: true);

    return List<Map<String, dynamic>>.from(res);
  }

  double _deg2rad(double deg) => deg * (pi / 180.0);

  double _haversineKm(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371.0;
    final dLat = _deg2rad(lat2 - lat1);
    final dLon = _deg2rad(lon2 - lon1);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_deg2rad(lat1)) *
            cos(_deg2rad(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return r * c;
  }

  Future<List<String>> getAssamDistrictsByDistance({
    required double userLat,
    required double userLng,
  }) async {
    try {
      final districts = await fetchAssamDistrictMaster();
      if (districts.isEmpty) return [];

      final scored = <Map<String, dynamic>>[];

      for (final d in districts) {
        final name = (d['district_name'] ?? '').toString().trim();
        if (name.isEmpty) continue;

        final lat = double.tryParse(d['latitude'].toString());
        final lng = double.tryParse(d['longitude'].toString());
        if (lat == null || lng == null) continue;

        final dist = _haversineKm(userLat, userLng, lat, lng);

        scored.add({
          'name': name,
          'dist': dist,
        });
      }

      scored.sort((a, b) {
        final da = (a['dist'] as double);
        final db = (b['dist'] as double);
        return da.compareTo(db);
      });

      return scored.map((e) => e['name'].toString()).toList();
    } catch (_) {
      return [];
    }
  }

  // ============================================================
  // JOB FEED (BASE) - PAGINATED
  // ============================================================

  Future<List<Map<String, dynamic>>> fetchJobs({
    int offset = 0,
    int limit = 20,
  }) async {
    _ensureAuthenticatedSync();

    final nowIso = DateTime.now().toIso8601String();

    final res = await _db
        .from('job_listings')
        .select(_jobWithCompanySelect)
        .eq('status', 'active')
        .gte('expires_at', nowIso)
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    return List<Map<String, dynamic>>.from(res);
  }

  // ============================================================
  // LATEST JOBS (PAGINATED)
  // ============================================================

  Future<List<Map<String, dynamic>>> fetchLatestJobs({
    int offset = 0,
    int limit = 20,
  }) async {
    return fetchJobs(offset: offset, limit: limit);
  }

  // ============================================================
  // JOBS POSTED TODAY (PAGINATED)
  // ============================================================

  Future<List<Map<String, dynamic>>> fetchJobsPostedToday({
    int offset = 0,
    int limit = 20,
  }) async {
    _ensureAuthenticatedSync();

    final nowIso = DateTime.now().toIso8601String();

    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 1));

    final res = await _db
        .from('job_listings')
        .select(_jobWithCompanySelect)
        .eq('status', 'active')
        .gte('expires_at', nowIso)
        .gte('created_at', start.toIso8601String())
        .lt('created_at', end.toIso8601String())
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    return List<Map<String, dynamic>>.from(res);
  }

  // ============================================================
  // JOBS NEARBY (PAGINATED + Assam logic)
  // ============================================================

  Future<List<Map<String, dynamic>>> fetchJobsNearby({
    int offset = 0,
    int limit = 20,
  }) async {
    _ensureAuthenticatedSync();

    final inAssam = await isUserInAssam();
    if (!inAssam) {
      return fetchLatestJobs(offset: offset, limit: limit);
    }

    final gps = await getMyCurrentLatLngFromProfile();
    if (gps == null) {
      return fetchLatestJobs(offset: offset, limit: limit);
    }

    final userLat = gps['lat']!;
    final userLng = gps['lng']!;

    final districtsOrdered = await getAssamDistrictsByDistance(
      userLat: userLat,
      userLng: userLng,
    );

    if (districtsOrdered.isEmpty) {
      return fetchLatestJobs(offset: offset, limit: limit);
    }

    final nowIso = DateTime.now().toIso8601String();

    final res = await _db
        .from('job_listings')
        .select(_jobWithCompanySelect)
        .eq('status', 'active')
        .gte('expires_at', nowIso)
        .inFilter('district', districtsOrdered)
        .order('created_at', ascending: false)
        .limit(800);

    final all = List<Map<String, dynamic>>.from(res);

    final districtRank = <String, int>{};
    for (int i = 0; i < districtsOrdered.length; i++) {
      districtRank[districtsOrdered[i].toLowerCase()] = i;
    }

    all.sort((a, b) {
      final da = (a['district'] ?? '').toString().trim().toLowerCase();
      final db = (b['district'] ?? '').toString().trim().toLowerCase();

      final ra = districtRank[da] ?? 9999;
      final rb = districtRank[db] ?? 9999;

      if (ra != rb) return ra.compareTo(rb);

      final ca = DateTime.tryParse((a['created_at'] ?? '').toString());
      final cb = DateTime.tryParse((b['created_at'] ?? '').toString());

      if (ca == null && cb == null) return 0;
      if (ca == null) return 1;
      if (cb == null) return -1;

      return cb.compareTo(ca);
    });

    if (offset >= all.length) return [];

    final end = (offset + limit) > all.length ? all.length : (offset + limit);
    return all.sublist(offset, end);
  }

  // ============================================================
  // RAW PATH FETCH (useful for edit screens)
  // ============================================================

  Future<Map<String, dynamic>> fetchMyProfileRawPaths() async {
    _ensureAuthenticatedSync();
    final userId = _userId();

    final res = await _db
        .from('user_profiles')
        .select('avatar_url, resume_url')
        .eq('id', userId)
        .maybeSingle();

    if (res == null) return {};
    return Map<String, dynamic>.from(res);
  }

  // ============================================================
  // JOBS FILTERED BY SALARY (MONTHLY)
  // ============================================================

  Future<List<Map<String, dynamic>>> fetchJobsByMinSalaryMonthly({
    required int minMonthlySalary,
    int offset = 0,
    int limit = 20,
  }) async {
    _ensureAuthenticatedSync();

    final nowIso = DateTime.now().toIso8601String();
    final minSalary = minMonthlySalary < 0 ? 0 : minMonthlySalary;

    final res = await _db
        .from('job_listings')
        .select(_jobWithCompanySelect)
        .eq('status', 'active')
        .gte('expires_at', nowIso)
        .or(
          'salary_period.is.null,salary_period.eq.Monthly,salary_period.eq.monthly',
        )
        .gte('salary_max', minSalary)
        .order('salary_max', ascending: false)
        .range(offset, offset + limit - 1);

    return List<Map<String, dynamic>>.from(res);
  }

  // ============================================================
  // RECOMMENDED JOBS (PAGINATED) - MIXED + RANDOM
  // ============================================================

  Future<List<Map<String, dynamic>>> getRecommendedJobs({
    int offset = 0,
    int limit = 20,
  }) async {
    _ensureAuthenticatedSync();

    final userId = _userId();
    final nowIso = DateTime.now().toIso8601String();

    List<String> preferredLocations = [];
    String currentCity = '';
    String highestEducation = '';
    int expectedSalaryMin = 0;

    try {
      final p = await _db
          .from('user_profiles')
          .select(
            'preferred_locations, current_city, highest_education, expected_salary_min',
          )
          .eq('id', userId)
          .maybeSingle();

      if (p != null) {
        final pl = p['preferred_locations'];
        if (pl is List) {
          preferredLocations = pl
              .map((e) => e.toString().trim())
              .where((e) => e.isNotEmpty)
              .toList();
        }

        currentCity = (p['current_city'] ?? '').toString().trim();
        highestEducation = (p['highest_education'] ?? '').toString().trim();

        final rawSalary = p['expected_salary_min'];
        if (rawSalary is int) expectedSalaryMin = rawSalary;
        if (rawSalary != null && rawSalary is! int) {
          expectedSalaryMin = int.tryParse(rawSalary.toString()) ?? 0;
        }
      }
    } catch (_) {}

    final cityLower = currentCity.toLowerCase();
    final eduLower = highestEducation.toLowerCase();

    final mixed = <Map<String, dynamic>>[];
    final seen = <String>{};

    void addJobs(List<Map<String, dynamic>> jobs, int score) {
      for (final j in jobs) {
        final id = j['id']?.toString() ?? '';
        if (id.isEmpty) continue;
        if (seen.contains(id)) continue;

        seen.add(id);
        j['__rec_score'] = score;
        mixed.add(j);
      }
    }

    // 1) Assam nearby districts
    try {
      final inAssam = await isUserInAssam();
      if (inAssam) {
        final gps = await getMyCurrentLatLngFromProfile();
        if (gps != null) {
          final districts = await getAssamDistrictsByDistance(
            userLat: gps['lat']!,
            userLng: gps['lng']!,
          );

          final top = districts.take(8).toList();

          if (top.isNotEmpty) {
            final res = await _db
                .from('job_listings')
                .select(_jobWithCompanySelect)
                .eq('status', 'active')
                .gte('expires_at', nowIso)
                .inFilter('district', top)
                .order('created_at', ascending: false)
                .limit(160);

            addJobs(List<Map<String, dynamic>>.from(res), 110);
          }
        }
      }
    } catch (_) {}

    // 2) preferred locations
    if (preferredLocations.isNotEmpty) {
      try {
        final res = await _db
            .from('job_listings')
            .select(_jobWithCompanySelect)
            .eq('status', 'active')
            .gte('expires_at', nowIso)
            .inFilter('district', preferredLocations)
            .order('created_at', ascending: false)
            .limit(160);

        addJobs(List<Map<String, dynamic>>.from(res), 95);
      } catch (_) {}
    }

    // 3) current city/district
    if (currentCity.trim().isNotEmpty) {
      try {
        final res = await _db
            .from('job_listings')
            .select(_jobWithCompanySelect)
            .eq('status', 'active')
            .gte('expires_at', nowIso)
            .ilike('district', '%$cityLower%')
            .order('created_at', ascending: false)
            .limit(140);

        addJobs(List<Map<String, dynamic>>.from(res), 85);
      } catch (_) {}
    }

    // 4) education match
    if (highestEducation.trim().isNotEmpty) {
      try {
        final res = await _db
            .from('job_listings')
            .select(_jobWithCompanySelect)
            .eq('status', 'active')
            .gte('expires_at', nowIso)
            .ilike('education_required', '%$eduLower%')
            .order('created_at', ascending: false)
            .limit(160);

        addJobs(List<Map<String, dynamic>>.from(res), 70);
      } catch (_) {}
    }

    // 5) expected salary match
    if (expectedSalaryMin > 0) {
      try {
        final res = await _db
            .from('job_listings')
            .select(_jobWithCompanySelect)
            .eq('status', 'active')
            .gte('expires_at', nowIso)
            .or(
              'salary_period.is.null,salary_period.eq.Monthly,salary_period.eq.monthly',
            )
            .gte('salary_max', expectedSalaryMin)
            .order('salary_max', ascending: false)
            .limit(160);

        addJobs(List<Map<String, dynamic>>.from(res), 75);
      } catch (_) {}
    }

    // 6) latest fallback
    try {
      final res = await _db
          .from('job_listings')
          .select(_jobWithCompanySelect)
          .eq('status', 'active')
          .gte('expires_at', nowIso)
          .order('created_at', ascending: false)
          .limit(220);

      addJobs(List<Map<String, dynamic>>.from(res), 40);
    } catch (_) {}

    final rnd = Random();
    mixed.shuffle(rnd);

    mixed.sort((a, b) {
      final sa = (a['__rec_score'] ?? 0) as int;
      final sb = (b['__rec_score'] ?? 0) as int;

      if ((sa - sb).abs() <= 10) {
        return rnd.nextBool() ? 1 : -1;
      }

      return sb.compareTo(sa);
    });

    if (offset >= mixed.length) return [];

    final end =
        (offset + limit) > mixed.length ? mixed.length : (offset + limit);
    final page = mixed.sublist(offset, end);

    for (final j in page) {
      j.remove('__rec_score');
    }

    return page;
  }

  Future<List<Map<String, dynamic>>> getJobsBasedOnActivity({
    int offset = 0,
    int limit = 20,
  }) async {
    return getRecommendedJobs(offset: offset, limit: limit);
  }

  // ============================================================
  // JOB DETAILS HELPERS
  // ============================================================

  Future<void> trackJobView(String jobId) async {
    try {
      final userId = _db.auth.currentUser?.id;
      if (userId == null) return;

      await _db.from('job_views').insert({
        'user_id': userId,
        'job_id': jobId,
        'viewed_at': DateTime.now().toIso8601String(),
        'device_type': 'mobile',
      });

      try {
        await _db.from('user_job_activity').insert({
          'user_id': userId,
          'job_id': jobId,
          'activity_type': 'viewed',
          'activity_date': DateTime.now().toIso8601String(),
        });
      } catch (_) {}
    } catch (e) {
      debugPrint('trackJobView error: $e');
    }
  }

  Future<List<Map<String, dynamic>>> fetchSimilarJobs({
    required String jobId,
    int limit = 12,
  }) async {
    _ensureAuthenticatedSync();

    final nowIso = DateTime.now().toIso8601String();

    try {
      final base = await _db
          .from('job_listings')
          .select('job_category_id, district, company_id')
          .eq('id', jobId)
          .maybeSingle();

      if (base == null) return [];

      final catId = base['job_category_id'];
      final district = base['district'];
      final companyId = base['company_id'];

      final res = await _db
          .from('job_listings')
          .select(_jobWithCompanySelect)
          .eq('status', 'active')
          .gte('expires_at', nowIso)
          .neq('id', jobId)
          .neq('company_id', companyId)
          .eq('job_category_id', catId)
          .eq('district', district)
          .order('created_at', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(res);
    } catch (_) {
      return [];
    }
  }

  Future<Map<String, dynamic>?> fetchCompanyDetails(String companyId) async {
    _ensureAuthenticatedSync();

    final res = await _db
        .from('companies')
        .select(
          '''
          id,
          name,
          slug,
          logo_url,
          website,
          description,
          industry,
          company_size,
          founded_year,
          headquarters_city,
          headquarters_state,
          rating,
          total_reviews,
          total_jobs,
          is_verified,

          business_type_id,
          business_types_master (
            id,
            type_name,
            logo_url
          )
        ''',
        )
        .eq('id', companyId)
        .maybeSingle();

    if (res == null) return null;
    return Map<String, dynamic>.from(res);
  }

  // ============================================================
  // FOLLOW COMPANY
  // ============================================================

  Future<bool> isCompanyFollowed(String companyId) async {
    _ensureAuthenticatedSync();

    final userId = _userId();

    final res = await _db
        .from('followed_companies')
        .select('id')
        .eq('user_id', userId)
        .eq('company_id', companyId)
        .maybeSingle();

    return res != null;
  }

  Future<bool> toggleFollowCompany(String companyId) async {
    _ensureAuthenticatedSync();

    final userId = _userId();

    final existing = await _db
        .from('followed_companies')
        .select('id')
        .eq('user_id', userId)
        .eq('company_id', companyId)
        .maybeSingle();

    if (existing != null) {
      await _db
          .from('followed_companies')
          .delete()
          .eq('user_id', userId)
          .eq('company_id', companyId);

      return false;
    }

    await _db.from('followed_companies').insert({
      'user_id': userId,
      'company_id': companyId,
      'followed_at': DateTime.now().toIso8601String(),
    });

    return true;
  }

  // ============================================================
  // COMPANY REVIEWS
  // ============================================================

  Future<List<Map<String, dynamic>>> fetchCompanyReviews({
    required String companyId,
    int limit = 20,
  }) async {
    _ensureAuthenticatedSync();

    final res = await _db
        .from('company_reviews')
        .select('id, rating, review_text, created_at, is_anonymous')
        .eq('company_id', companyId)
        .order('created_at', ascending: false)
        .limit(limit);

    return List<Map<String, dynamic>>.from(res);
  }

  // ============================================================
  // SAVED JOBS
  // ============================================================

  Future<Set<String>> getUserSavedJobs() async {
    _ensureAuthenticatedSync();

    final userId = _userId();

    final res =
        await _db.from('saved_jobs').select('job_id').eq('user_id', userId);

    return res.map<String>((e) => e['job_id'].toString()).toSet();
  }

  Future<List<Map<String, dynamic>>> getSavedJobs({
    int offset = 0,
    int limit = 20,
  }) async {
    _ensureAuthenticatedSync();

    final userId = _userId();

    final res = await _db
        .from('saved_jobs')
        .select(
          'saved_at, job_listings($_jobWithCompanySelect)',
        )
        .eq('user_id', userId)
        .order('saved_at', ascending: false)
        .range(offset, offset + limit - 1);

    return res.map<Map<String, dynamic>>((e) {
      final j = e['job_listings'];
      if (j is Map<String, dynamic>) return j;
      return Map<String, dynamic>.from(j);
    }).toList();
  }

  Future<bool> toggleSaveJob(String jobId) async {
    _ensureAuthenticatedSync();

    final userId = _userId();

    final existing = await _db
        .from('saved_jobs')
        .select('id')
        .eq('user_id', userId)
        .eq('job_id', jobId)
        .maybeSingle();

    if (existing != null) {
      await _db
          .from('saved_jobs')
          .delete()
          .eq('user_id', userId)
          .eq('job_id', jobId);

      return false;
    }

    await _db.from('saved_jobs').insert({
      'user_id': userId,
      'job_id': jobId,
      'saved_at': DateTime.now().toIso8601String(),
    });

    try {
      await _db.from('user_job_activity').insert({
        'user_id': userId,
        'job_id': jobId,
        'activity_type': 'saved',
        'activity_date': DateTime.now().toIso8601String(),
      });
    } catch (_) {}

    return true;
  }

  // ============================================================
  // APPLY STATUS
  // ============================================================

  Future<bool> hasAppliedToJob(String jobId) async {
    _ensureAuthenticatedSync();

    final userId = _userId();

    final res = await _db
        .from('job_applications_listings')
        .select('id')
        .eq('user_id', userId)
        .eq('listing_id', jobId)
        .maybeSingle();

    return res != null;
  }

  // ============================================================
  // APPLIED JOBS (PAGINATED)
  // ============================================================

  Future<List<Map<String, dynamic>>> fetchAppliedJobs({
    int offset = 0,
    int limit = 20,
  }) async {
    _ensureAuthenticatedSync();

    final userId = _userId();
    final nowIso = DateTime.now().toIso8601String();

    final res = await _db
        .from('job_applications_listings')
        .select('''
          applied_at,
          application_status,
          listing_id,
          job_listings($_jobWithCompanySelect)
        ''')
        .eq('user_id', userId)
        .order('applied_at', ascending: false)
        .range(offset, offset + limit - 1);

    final rows = List<Map<String, dynamic>>.from(res);

    final jobs = <Map<String, dynamic>>[];

    for (final r in rows) {
      final j = r['job_listings'];
      if (j == null) continue;

      final job = Map<String, dynamic>.from(j);

      job['applied_at'] = r['applied_at'];
      job['application_status'] = r['application_status'];

      final status = (job['status'] ?? '').toString();
      final expiresAt = (job['expires_at'] ?? '').toString();

      if (status != 'active') continue;
      if (expiresAt.isNotEmpty && expiresAt.compareTo(nowIso) < 0) continue;

      jobs.add(job);
    }

    return jobs;
  }

  // ============================================================
  // HOME SUMMARY
  // ============================================================

  Future<Map<String, dynamic>> getHomeProfileSummary() async {
    final user = _db.auth.currentUser;

    if (user == null) {
      return {
        "profileName": "Your Profile",
        "profileCompletion": 0,
        "lastUpdatedText": "Updated recently",
        "missingDetails": 0,
      };
    }

    try {
      final profile = await _db
          .from('user_profiles')
          .select(
            'full_name, profile_completion_percentage, last_profile_update',
          )
          .eq('id', user.id)
          .maybeSingle();

      String profileName = "Your Profile";
      int completion = 0;
      String lastUpdatedText = "Updated recently";

      if (profile != null) {
        final fullName = (profile['full_name'] ?? '').toString().trim();
        profileName = _firstNameOrFallback(fullName);

        completion =
            _toInt(profile['profile_completion_percentage']).clamp(0, 100);

        lastUpdatedText =
            _formatLastUpdated(profile['last_profile_update']?.toString());
      }

      return {
        "profileName": profileName,
        "profileCompletion": completion,
        "lastUpdatedText": lastUpdatedText,
        "missingDetails": completion >= 100 ? 0 : 1,
      };
    } catch (_) {
      return {
        "profileName": "Your Profile",
        "profileCompletion": 0,
        "lastUpdatedText": "Updated recently",
        "missingDetails": 0,
      };
    }
  }

  Future<int> getJobsPostedTodayCount() async {
    try {
      final now = DateTime.now();
      final start = DateTime(now.year, now.month, now.day);
      final end = start.add(const Duration(days: 1));

      final res = await _db
          .from('job_listings')
          .select('id')
          .eq('status', 'active')
          .gte('created_at', start.toIso8601String())
          .lt('created_at', end.toIso8601String());

      return (res as List).length;
    } catch (_) {
      return 0;
    }
  }

  // ============================================================
  // EXPECTED SALARY (PER MONTH)
  // ============================================================

  Future<int> getExpectedSalaryPerMonth() async {
    _ensureAuthenticatedSync();

    final userId = _userId();

    try {
      final profile = await _db
          .from('user_profiles')
          .select('expected_salary_min')
          .eq('id', userId)
          .maybeSingle();

      if (profile == null) return 0;

      final raw = profile['expected_salary_min'];
      if (raw == null) return 0;

      if (raw is int) return raw;
      return int.tryParse(raw.toString()) ?? 0;
    } catch (_) {
      return 0;
    }
  }

  Future<void> updateExpectedSalaryPerMonth(int salary) async {
    _ensureAuthenticatedSync();

    final userId = _userId();

    final clean = salary < 0 ? 0 : salary;
    final max = clean + 5000;

    await _db.from('user_profiles').update({
      'expected_salary_min': clean,
      'expected_salary_max': max,
      'last_profile_update': DateTime.now().toIso8601String(),
    }).eq('id', userId);
  }

  // ============================================================
  // PROFILE
  // ============================================================

  Future<Map<String, dynamic>> fetchMyProfile() async {
    _ensureAuthenticatedSync();
    final userId = _userId();

    final res = await _db
        .from('user_profiles')
        .select('''
          id,
          email,
          full_name,
          avatar_url,
          mobile_number,
          auth_provider,

          location,
          current_location,
          current_city,
          current_state,
          current_latitude,
          current_longitude,
          location_updated_at,
          default_search_radius_km,

          bio,
          skills,
          highest_education,
          total_experience_years,

          preferred_job_types,
          preferred_locations,
          expected_salary_min,
          expected_salary_max,
          notice_period_days,
          is_open_to_work,

          resume_url,
          resume_headline,
          resume_updated_at,

          is_profile_public,
          notification_enabled,
          job_alerts_enabled,
          language_preference,

          profile_completion_percentage,
          last_profile_update,

          current_job_title,
          current_company
        ''')
        .eq('id', userId)
        .maybeSingle();

    if (res == null) return {};

    final p = Map<String, dynamic>.from(res);

    // convert stored paths -> signed URLs for UI
    final avatarRaw = (p['avatar_url'] ?? '').toString();
    final resumeRaw = (p['resume_url'] ?? '').toString();

    final avatarSigned =
        avatarRaw.trim().isEmpty ? '' : await _toSignedUrlIfNeeded(avatarRaw);
    final resumeSigned =
        resumeRaw.trim().isEmpty ? '' : await _toSignedUrlIfNeeded(resumeRaw);

    return {
      ...p,

      // signed urls for UI
      'avatar_url': avatarSigned,
      'resume_url': resumeSigned,

      // old UI expects:
      'phone': p['mobile_number'],
      'location_text': p['location'],

      // old UI expects string:
      'preferred_job_type': _preferredJobTypeString(p['preferred_job_types']),

      // not in schema (kept for UI stability)
      'preferred_employment_type': 'Any',
    };
  }

  Future<void> updateMyProfile(Map<String, dynamic> payload) async {
    _ensureAuthenticatedSync();
    final userId = _userId();

    final mapped = <String, dynamic>{};

    void putString(String key, String payloadKey) {
      if (!payload.containsKey(payloadKey)) return;
      mapped[key] = (payload[payloadKey] ?? '').toString().trim();
    }

    void putInt(String key, String payloadKey) {
      if (!payload.containsKey(payloadKey)) return;
      mapped[key] = _toInt(payload[payloadKey]);
    }

    void putBool(String key, String payloadKey) {
      if (!payload.containsKey(payloadKey)) return;
      final v = payload[payloadKey];
      mapped[key] = (v == true);
    }

    // basic
    putString('full_name', 'full_name');
    putString('mobile_number', 'phone');

    // location
    putString('current_city', 'current_city');
    putString('current_state', 'current_state');
    putString('location', 'location_text');

    // profile
    putString('bio', 'bio');

    if (payload.containsKey('skills')) {
      mapped['skills'] = payload['skills'] ?? [];
    }

    putString('highest_education', 'highest_education');
    putInt('total_experience_years', 'total_experience_years');

    // salary
    if (payload.containsKey('expected_salary_min')) {
      final expectedSalaryMin = _toInt(payload['expected_salary_min']);
      final clean = expectedSalaryMin < 0 ? 0 : expectedSalaryMin;
      mapped['expected_salary_min'] = clean;
      mapped['expected_salary_max'] = clean > 0 ? clean + 5000 : 0;
    }

    putInt('notice_period_days', 'notice_period_days');

    // preferred job types
    if (payload.containsKey('preferred_job_type')) {
      final jt = (payload['preferred_job_type'] ?? 'Any').toString();
      mapped['preferred_job_types'] = _preferredJobTypesArray(jt);
    }

    // preferred locations
    if (payload.containsKey('preferred_locations')) {
      final v = payload['preferred_locations'];
      if (v is List) {
        mapped['preferred_locations'] = v
            .map((e) => e.toString().trim())
            .where((e) => e.isNotEmpty)
            .toList();
      } else {
        mapped['preferred_locations'] = [];
      }
    }

    // open to work
    putBool('is_open_to_work', 'is_open_to_work');

    // resume headline
    if (payload.containsKey('resume_headline')) {
      putString('resume_headline', 'resume_headline');
      mapped['resume_updated_at'] = DateTime.now().toIso8601String();
    }

    // storage paths ONLY (never store signed URL)
    if (payload.containsKey('avatar_url')) {
      final v = (payload['avatar_url'] ?? '').toString().trim();
      if (v.isNotEmpty && !_looksLikeHttpUrl(v)) {
        mapped['avatar_url'] = v;
      }
    }

    if (payload.containsKey('resume_url')) {
      final v = (payload['resume_url'] ?? '').toString().trim();
      if (v.isNotEmpty && !_looksLikeHttpUrl(v)) {
        mapped['resume_url'] = v;
        mapped['resume_updated_at'] = DateTime.now().toIso8601String();
      }
    }

    if (mapped.isEmpty) return;

    // completion needs existing + new values
    final existing = await _db
            .from('user_profiles')
            .select(
              'full_name, mobile_number, current_city, current_state, highest_education, total_experience_years, expected_salary_min, skills, bio, preferred_job_types, resume_url, avatar_url',
            )
            .eq('id', userId)
            .maybeSingle() ??
        {};

    final completion = _calculateProfileCompletion({
      ...Map<String, dynamic>.from(existing),
      ...mapped,
    });

    await _db.from('user_profiles').update({
      ...mapped,
      'profile_completion_percentage': completion,
      'last_profile_update': DateTime.now().toIso8601String(),
    }).eq('id', userId);
  }

  String _preferredJobTypeString(dynamic raw) {
    if (raw == null) return 'Any';
    if (raw is List) {
      if (raw.isEmpty) return 'Any';
      return raw.first.toString();
    }
    return raw.toString();
  }

  List<String> _preferredJobTypesArray(String jobType) {
    final v = jobType.trim();
    if (v.isEmpty || v.toLowerCase() == 'any') return [];
    return [v];
  }

  int _calculateProfileCompletion(Map<String, dynamic> p) {
    final fields = [
      'full_name',
      'mobile_number',
      'current_city',
      'current_state',
      'highest_education',
      'total_experience_years',
      'expected_salary_min',
      'skills',
      'bio',
      'preferred_job_types',
      'resume_url',
      'avatar_url',
    ];

    int filled = 0;

    for (final f in fields) {
      final v = p[f];

      bool ok = false;

      if (v == null) {
        ok = false;
      } else if (v is String) {
        ok = v.trim().isNotEmpty;
      } else if (v is int) {
        ok = v > 0;
      } else if (v is double) {
        ok = v > 0;
      } else if (v is List) {
        ok = v.isNotEmpty;
      } else {
        ok = v.toString().trim().isNotEmpty;
      }

      if (ok) filled++;
    }

    final pct = ((filled / fields.length) * 100).round();
    return pct.clamp(0, 100);
  }

  // ============================================================
  // TOP COMPANIES
  // ============================================================

  Future<List<Map<String, dynamic>>> fetchTopCompanies({
    int limit = 8,
  }) async {
    _ensureAuthenticatedSync();

    final res = await _db
        .from('companies_with_stats')
        .select(
          'id, name, slug, logo_url, industry, company_size, is_verified, total_jobs',
        )
        .order('total_jobs', ascending: false)
        .limit(limit);

    return List<Map<String, dynamic>>.from(res);
  }

  // ============================================================
  // NOTIFICATIONS
  // ============================================================

  Future<int> getUnreadNotificationsCount() async {
    _ensureAuthenticatedSync();

    final userId = _userId();

    final res = await _db
        .from('notifications')
        .select('id')
        .eq('user_id', userId)
        .eq('is_read', false);

    return (res as List).length;
  }

  // ============================================================
  // SUBSCRIPTION (PRO)
  // ============================================================

  Future<Map<String, dynamic>?> getMySubscription() async {
    _ensureAuthenticatedSync();
    final userId = _userId();

    final res = await _db
        .from('subscriptions')
        .select('id, user_id, status, plan_price, starts_at, expires_at')
        .eq('user_id', userId)
        .maybeSingle();

    if (res == null) return null;
    return Map<String, dynamic>.from(res);
  }

  Future<bool> isProActive() async {
    final sub = await getMySubscription();
    if (sub == null) return false;

    final status = (sub['status'] ?? 'inactive').toString();
    if (status != 'active') return false;

    final expiresAtRaw = sub['expires_at']?.toString();
    if (expiresAtRaw == null || expiresAtRaw.trim().isEmpty) return false;

    final expiresAt = DateTime.tryParse(expiresAtRaw);
    if (expiresAt == null) return false;

    return expiresAt.isAfter(DateTime.now());
  }

  Future<Map<String, dynamic>> createProOrder({
    int amountRupees = 999,
    String planKey = 'pro_monthly',
  }) async {
    _ensureAuthenticatedSync();

    final userId = _userId();

    final payload = {
      'user_id': userId,
      'amount_rupees': amountRupees,
      'plan_key': planKey,
    };

    final res =
        await _db.functions.invoke('create_razorpay_order', body: payload);

    if (res.status != 200) {
      throw Exception(
        'create_razorpay_order failed: ${res.status} ${res.data}',
      );
    }

    final data = res.data;
    if (data == null || data is! Map) {
      throw Exception('Invalid create_razorpay_order response');
    }

    return Map<String, dynamic>.from(data);
  }

  Future<bool> verifyProPayment({
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
    int amountRupees = 999,
    String planKey = 'pro_monthly',
  }) async {
    _ensureAuthenticatedSync();

    final userId = _userId();

    final payload = {
      'user_id': userId,
      'razorpay_order_id': razorpayOrderId,
      'razorpay_payment_id': razorpayPaymentId,
      'razorpay_signature': razorpaySignature,
      'amount_rupees': amountRupees,
      'plan_key': planKey,
    };

    final res =
        await _db.functions.invoke('verify_razorpay_payment', body: payload);

    if (res.status != 200) {
      throw Exception(
        'verify_razorpay_payment failed: ${res.status} ${res.data}',
      );
    }

    final data = res.data;
    if (data == null || data is! Map) return false;

    return (data['success'] ?? false) == true;
  }

  Future<bool> refreshProStatus() async {
    return isProActive();
  }

  // ============================================================
  // HELPERS
  // ============================================================

  void tellDebug(String msg) {
    if (kDebugMode) debugPrint(msg);
  }

  int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    return int.tryParse(v.toString()) ?? 0;
  }

  String _firstNameOrFallback(String fullName) {
    if (fullName.trim().isEmpty) return "Your Profile";
    final parts = fullName.trim().split(RegExp(r"\s+"));
    if (parts.isEmpty) return "Your Profile";
    return "${parts.first}'s profile";
  }

  String _formatLastUpdated(String? iso) {
    if (iso == null || iso.trim().isEmpty) return "Updated recently";

    final d = DateTime.tryParse(iso);
    if (d == null) return "Updated recently";

    final diff = DateTime.now().difference(d);

    if (diff.inMinutes < 60) return "Updated just now";
    if (diff.inHours < 24) return "Updated today";
    if (diff.inDays == 1) return "Updated 1d ago";
    if (diff.inDays < 7) return "Updated ${diff.inDays}d ago";
    if (diff.inDays < 30) return "Updated ${(diff.inDays / 7).floor()}w ago";

    return "Updated ${(diff.inDays / 30).floor()}mo ago";
  }
}