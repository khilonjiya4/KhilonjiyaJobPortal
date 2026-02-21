import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../core/ui/khilonjiya_ui.dart';

class CompanyCard extends StatelessWidget {
  final Map<String, dynamic> company;
  final VoidCallback? onTap;

  const CompanyCard({
    Key? key,
    required this.company,
    this.onTap,
  }) : super(key: key);

  static const double _cardHeight = 118;
  static const double _logoSize = _cardHeight * 0.32;
  static const double _companyLogoSize = 38;

  @override
  Widget build(BuildContext context) {
    final name = (company['name'] ?? '').toString().trim();
    final isVerified = (company['is_verified'] ?? false) == true;
    final totalJobs = _toInt(company['total_jobs']);

    final headquartersCity =
        (company['headquarters_city'] ?? '').toString().trim();
    final headquartersState =
        (company['headquarters_state'] ?? '').toString().trim();

    final companySize =
        (company['company_size'] ?? '').toString().trim();

    final companyLogoUrl =
        (company['logo_url'] ?? '').toString().trim();

    String businessType = '';
    String? businessLogoUrl;

    final bt = company['business_types_master'];

    if (bt is Map<String, dynamic>) {
      businessType = (bt['type_name'] ?? '').toString().trim();
      final url = (bt['logo_url'] ?? '').toString().trim();
      businessLogoUrl = url.isEmpty ? null : url;
    }

    if (businessType.isEmpty) {
      businessType =
          (company['industry'] ?? '').toString().trim();
    }

    if (businessType.isEmpty) businessType = "Business";

    if (businessLogoUrl == null || businessLogoUrl.isEmpty) {
      if (companyLogoUrl.isNotEmpty) {
        businessLogoUrl = companyLogoUrl;
      }
    }

    final location = _formatLocation(
      headquartersCity,
      headquartersState,
    );

    return InkWell(
      onTap: onTap,
      borderRadius: KhilonjiyaUI.r16,
      child: Container(
        constraints: const BoxConstraints(minHeight: _cardHeight), // ✅ only change
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: KhilonjiyaUI.r16,
          border: Border.all(color: KhilonjiyaUI.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      _CompanyLogo(
                        name: name,
                        logoUrl: companyLogoUrl,
                        size: _companyLogoSize,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                name.isEmpty
                                    ? "Company"
                                    : name,
                                maxLines: 1,
                                overflow:
                                    TextOverflow.ellipsis,
                                style:
                                    KhilonjiyaUI.cardTitle
                                        .copyWith(
                                  fontSize: 15.6,
                                  fontWeight:
                                      FontWeight.w900,
                                ),
                              ),
                            ),
                            if (isVerified)
                              const Padding(
                                padding:
                                    EdgeInsets.only(
                                        left: 6),
                                child: Icon(
                                  Icons
                                      .verified_rounded,
                                  size: 18,
                                  color:
                                      Color(0xFF2563EB),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  Text(
                    businessType,
                    maxLines: 1,
                    overflow:
                        TextOverflow.ellipsis,
                    style: KhilonjiyaUI.sub
                        .copyWith(
                      fontSize: 12.8,
                      fontWeight:
                          FontWeight.w800,
                      color:
                          const Color(0xFF64748B),
                    ),
                  ),

                  const SizedBox(height: 4),

                  if (location.isNotEmpty ||
                      companySize.isNotEmpty)
                    Text(
                      _combineLocationSize(
                          location, companySize),
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style: KhilonjiyaUI.sub
                          .copyWith(
                        fontSize: 12.2,
                        fontWeight:
                            FontWeight.w700,
                        color:
                            const Color(0xFF94A3B8),
                      ),
                    ),

                  const SizedBox(height: 8),

                  Text(
                    totalJobs <= 0
                        ? "No active jobs"
                        : "$totalJobs active job${totalJobs > 1 ? 's' : ''}",
                    maxLines: 1,
                    overflow:
                        TextOverflow.ellipsis,
                    style: KhilonjiyaUI.sub
                        .copyWith(
                      fontSize: 12.2,
                      fontWeight:
                          FontWeight.w800,
                      color:
                          const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 14),

            _BusinessTypeLogo(
              businessType: businessType,
              logoUrl: businessLogoUrl,
              size: _logoSize,
            ),
          ],
        ),
      ),
    );
  }

  int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }

  String _formatLocation(String city, String state) {
    if (city.isNotEmpty && state.isNotEmpty) {
      return "$city, $state";
    }
    return city.isNotEmpty ? city : state;
  }

  String _combineLocationSize(
      String location, String size) {
    if (location.isNotEmpty &&
        size.isNotEmpty) {
      return "$location • $size";
    }
    return location.isNotEmpty
        ? location
        : size;
  }
}

class _CompanyLogo extends StatelessWidget {
  final String name;
  final String logoUrl;
  final double size;

  const _CompanyLogo({
    required this.name,
    required this.logoUrl,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final letter =
        name.isNotEmpty ? name[0].toUpperCase() : "C";

    final colors = [
      const Color(0xFFE0F2FE),
      const Color(0xFFFCE7F3),
      const Color(0xFFEDE9FE),
      const Color(0xFFDCFCE7),
      const Color(0xFFFFEDD5),
    ];

    final index =
        name.isEmpty ? 0 : name.hashCode % colors.length;

    final bg = colors[index.abs()];

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: logoUrl.isEmpty
          ? Center(
              child: Text(
                letter,
                style: TextStyle(
                  fontSize: size * 0.45,
                  fontWeight:
                      FontWeight.w600,
                ),
              ),
            )
          : Image.network(
              logoUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  Center(
                child: Text(
                  letter,
                  style: TextStyle(
                    fontSize:
                        size * 0.45,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
              ),
            ),
    );
  }
}

class _BusinessTypeLogo extends StatelessWidget {
  final String businessType;
  final String? logoUrl;
  final double size;

  const _BusinessTypeLogo({
    required this.businessType,
    required this.logoUrl,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final letter =
        businessType.isNotEmpty
            ? businessType[0].toUpperCase()
            : "B";

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius:
            BorderRadius.circular(14),
        border:
            Border.all(color: KhilonjiyaUI.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: (logoUrl == null ||
              logoUrl!.isEmpty)
          ? Center(
              child: Text(
                letter,
                style: TextStyle(
                  fontSize:
                      size * 0.52,
                  fontWeight:
                      FontWeight.w900,
                  color: const Color(
                      0xFF0F172A),
                ),
              ),
            )
          : Image.network(
              logoUrl!,
              fit: BoxFit.cover,
              errorBuilder:
                  (_, __, ___) =>
                      Center(
                child: Text(
                  letter,
                  style: TextStyle(
                    fontSize:
                        size * 0.52,
                    fontWeight:
                        FontWeight.w900,
                    color: const Color(
                        0xFF0F172A),
                  ),
                ),
              ),
            ),
    );
  }
}