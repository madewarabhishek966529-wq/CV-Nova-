/// Resume models. Every section key here must match SECTION_KEYS on the
/// backend (app/models/resume.py) — see [Resume.defaultSectionOrder].
library;

const List<String> kSectionKeys = [
  'personal_info',
  'headline',
  'summary',
  'experience',
  'projects',
  'education',
  'certifications',
  'achievements',
  'skills',
  'languages',
  'interests',
  'references',
  'links',
  'custom_sections',
];

const Map<String, String> kSectionLabels = {
  'personal_info': 'Personal Info',
  'headline': 'Headline',
  'summary': 'Professional Summary',
  'experience': 'Experience',
  'projects': 'Projects',
  'education': 'Education',
  'certifications': 'Certifications',
  'achievements': 'Achievements',
  'skills': 'Skills',
  'languages': 'Languages',
  'interests': 'Interests',
  'references': 'References',
  'links': 'Links',
  'custom_sections': 'Custom Sections',
};

String _s(dynamic v) => (v ?? '') as String;
List<String> _strList(dynamic v) =>
    (v as List?)?.map((e) => e.toString()).toList() ?? <String>[];

class PersonalInfo {
  PersonalInfo({
    this.fullName = '',
    this.email = '',
    this.phone = '',
    this.location = '',
    this.website = '',
  });

  final String fullName;
  final String email;
  final String phone;
  final String location;
  final String website;

  factory PersonalInfo.fromJson(Map<String, dynamic> json) => PersonalInfo(
        fullName: _s(json['full_name']),
        email: _s(json['email']),
        phone: _s(json['phone']),
        location: _s(json['location']),
        website: _s(json['website']),
      );

  Map<String, dynamic> toJson() => {
        'full_name': fullName,
        'email': email,
        'phone': phone,
        'location': location,
        'website': website,
      };

  PersonalInfo copyWith({
    String? fullName,
    String? email,
    String? phone,
    String? location,
    String? website,
  }) =>
      PersonalInfo(
        fullName: fullName ?? this.fullName,
        email: email ?? this.email,
        phone: phone ?? this.phone,
        location: location ?? this.location,
        website: website ?? this.website,
      );
}

class ExperienceItem {
  ExperienceItem({
    required this.id,
    this.company = '',
    this.role = '',
    this.location = '',
    this.startDate = '',
    this.endDate = '',
    this.isCurrent = false,
    List<String>? bullets,
  }) : bullets = bullets ?? [];

  final String id;
  final String company;
  final String role;
  final String location;
  final String startDate;
  final String endDate;
  final bool isCurrent;
  final List<String> bullets;

  factory ExperienceItem.fromJson(Map<String, dynamic> json) => ExperienceItem(
        id: _s(json['id']),
        company: _s(json['company']),
        role: _s(json['role']),
        location: _s(json['location']),
        startDate: _s(json['start_date']),
        endDate: _s(json['end_date']),
        isCurrent: (json['is_current'] as bool?) ?? false,
        bullets: _strList(json['bullets']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'company': company,
        'role': role,
        'location': location,
        'start_date': startDate,
        'end_date': endDate,
        'is_current': isCurrent,
        'bullets': bullets,
      };

  ExperienceItem copyWith({
    String? company,
    String? role,
    String? location,
    String? startDate,
    String? endDate,
    bool? isCurrent,
    List<String>? bullets,
  }) =>
      ExperienceItem(
        id: id,
        company: company ?? this.company,
        role: role ?? this.role,
        location: location ?? this.location,
        startDate: startDate ?? this.startDate,
        endDate: endDate ?? this.endDate,
        isCurrent: isCurrent ?? this.isCurrent,
        bullets: bullets ?? this.bullets,
      );
}

class EducationItem {
  EducationItem({
    required this.id,
    this.institution = '',
    this.degree = '',
    this.fieldOfStudy = '',
    this.startDate = '',
    this.endDate = '',
    this.grade = '',
    this.description = '',
  });

  final String id;
  final String institution;
  final String degree;
  final String fieldOfStudy;
  final String startDate;
  final String endDate;
  final String grade;
  final String description;

  factory EducationItem.fromJson(Map<String, dynamic> json) => EducationItem(
        id: _s(json['id']),
        institution: _s(json['institution']),
        degree: _s(json['degree']),
        fieldOfStudy: _s(json['field_of_study']),
        startDate: _s(json['start_date']),
        endDate: _s(json['end_date']),
        grade: _s(json['grade']),
        description: _s(json['description']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'institution': institution,
        'degree': degree,
        'field_of_study': fieldOfStudy,
        'start_date': startDate,
        'end_date': endDate,
        'grade': grade,
        'description': description,
      };

  EducationItem copyWith({
    String? institution,
    String? degree,
    String? fieldOfStudy,
    String? startDate,
    String? endDate,
    String? grade,
    String? description,
  }) =>
      EducationItem(
        id: id,
        institution: institution ?? this.institution,
        degree: degree ?? this.degree,
        fieldOfStudy: fieldOfStudy ?? this.fieldOfStudy,
        startDate: startDate ?? this.startDate,
        endDate: endDate ?? this.endDate,
        grade: grade ?? this.grade,
        description: description ?? this.description,
      );
}

class ProjectItem {
  ProjectItem({
    required this.id,
    this.name = '',
    this.description = '',
    List<String>? techStack,
    this.link = '',
    List<String>? bullets,
  })  : techStack = techStack ?? [],
        bullets = bullets ?? [];

  final String id;
  final String name;
  final String description;
  final List<String> techStack;
  final String link;
  final List<String> bullets;

  factory ProjectItem.fromJson(Map<String, dynamic> json) => ProjectItem(
        id: _s(json['id']),
        name: _s(json['name']),
        description: _s(json['description']),
        techStack: _strList(json['tech_stack']),
        link: _s(json['link']),
        bullets: _strList(json['bullets']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'tech_stack': techStack,
        'link': link,
        'bullets': bullets,
      };

  ProjectItem copyWith({
    String? name,
    String? description,
    List<String>? techStack,
    String? link,
    List<String>? bullets,
  }) =>
      ProjectItem(
        id: id,
        name: name ?? this.name,
        description: description ?? this.description,
        techStack: techStack ?? this.techStack,
        link: link ?? this.link,
        bullets: bullets ?? this.bullets,
      );
}

class CertificationItem {
  CertificationItem({
    required this.id,
    this.name = '',
    this.issuer = '',
    this.issueDate = '',
    this.expiryDate = '',
    this.credentialUrl = '',
  });

  final String id;
  final String name;
  final String issuer;
  final String issueDate;
  final String expiryDate;
  final String credentialUrl;

  factory CertificationItem.fromJson(Map<String, dynamic> json) => CertificationItem(
        id: _s(json['id']),
        name: _s(json['name']),
        issuer: _s(json['issuer']),
        issueDate: _s(json['issue_date']),
        expiryDate: _s(json['expiry_date']),
        credentialUrl: _s(json['credential_url']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'issuer': issuer,
        'issue_date': issueDate,
        'expiry_date': expiryDate,
        'credential_url': credentialUrl,
      };

  CertificationItem copyWith({
    String? name,
    String? issuer,
    String? issueDate,
    String? expiryDate,
    String? credentialUrl,
  }) =>
      CertificationItem(
        id: id,
        name: name ?? this.name,
        issuer: issuer ?? this.issuer,
        issueDate: issueDate ?? this.issueDate,
        expiryDate: expiryDate ?? this.expiryDate,
        credentialUrl: credentialUrl ?? this.credentialUrl,
      );
}

class AchievementItem {
  AchievementItem({required this.id, this.title = '', this.description = '', this.date = ''});

  final String id;
  final String title;
  final String description;
  final String date;

  factory AchievementItem.fromJson(Map<String, dynamic> json) => AchievementItem(
        id: _s(json['id']),
        title: _s(json['title']),
        description: _s(json['description']),
        date: _s(json['date']),
      );

  Map<String, dynamic> toJson() =>
      {'id': id, 'title': title, 'description': description, 'date': date};

  AchievementItem copyWith({String? title, String? description, String? date}) =>
      AchievementItem(
        id: id,
        title: title ?? this.title,
        description: description ?? this.description,
        date: date ?? this.date,
      );
}

const List<String> kLanguageProficiencies = ['basic', 'conversational', 'fluent', 'native'];

class LanguageItem {
  LanguageItem({required this.id, this.name = '', this.proficiency = 'conversational'});

  final String id;
  final String name;
  final String proficiency;

  factory LanguageItem.fromJson(Map<String, dynamic> json) => LanguageItem(
        id: _s(json['id']),
        name: _s(json['name']),
        proficiency: json['proficiency'] as String? ?? 'conversational',
      );

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'proficiency': proficiency};

  LanguageItem copyWith({String? name, String? proficiency}) => LanguageItem(
        id: id,
        name: name ?? this.name,
        proficiency: proficiency ?? this.proficiency,
      );
}

class ReferenceItem {
  ReferenceItem({required this.id, this.name = '', this.relationship = '', this.contact = ''});

  final String id;
  final String name;
  final String relationship;
  final String contact;

  factory ReferenceItem.fromJson(Map<String, dynamic> json) => ReferenceItem(
        id: _s(json['id']),
        name: _s(json['name']),
        relationship: _s(json['relationship']),
        contact: _s(json['contact']),
      );

  Map<String, dynamic> toJson() =>
      {'id': id, 'name': name, 'relationship': relationship, 'contact': contact};

  ReferenceItem copyWith({String? name, String? relationship, String? contact}) => ReferenceItem(
        id: id,
        name: name ?? this.name,
        relationship: relationship ?? this.relationship,
        contact: contact ?? this.contact,
      );
}

class LinkItemModel {
  LinkItemModel({required this.id, this.label = '', this.url = ''});

  final String id;
  final String label;
  final String url;

  factory LinkItemModel.fromJson(Map<String, dynamic> json) =>
      LinkItemModel(id: _s(json['id']), label: _s(json['label']), url: _s(json['url']));

  Map<String, dynamic> toJson() => {'id': id, 'label': label, 'url': url};

  LinkItemModel copyWith({String? label, String? url}) =>
      LinkItemModel(id: id, label: label ?? this.label, url: url ?? this.url);
}

class CustomSectionModel {
  CustomSectionModel({required this.id, this.title = '', List<String>? content})
      : content = content ?? [];

  final String id;
  final String title;
  final List<String> content;

  factory CustomSectionModel.fromJson(Map<String, dynamic> json) => CustomSectionModel(
        id: _s(json['id']),
        title: _s(json['title']),
        content: _strList(json['content']),
      );

  Map<String, dynamic> toJson() => {'id': id, 'title': title, 'content': content};

  CustomSectionModel copyWith({String? title, List<String>? content}) => CustomSectionModel(
        id: id,
        title: title ?? this.title,
        content: content ?? this.content,
      );
}

class ResumeSummary {
  ResumeSummary({
    required this.id,
    required this.title,
    required this.template,
    required this.themeColor,
    required this.isPrimary,
    required this.headline,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final String template;
  final String themeColor;
  final bool isPrimary;
  final String? headline;
  final DateTime updatedAt;

  factory ResumeSummary.fromJson(Map<String, dynamic> json) => ResumeSummary(
        id: json['id'] as String,
        title: json['title'] as String,
        template: json['template'] as String,
        themeColor: json['theme_color'] as String,
        isPrimary: json['is_primary'] as bool,
        headline: json['headline'] as String?,
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );
}

class Resume {
  Resume({
    required this.id,
    required this.userId,
    required this.title,
    this.template = 'modern',
    this.themeColor = '#4A3AFF',
    this.font = 'inter',
    this.isPrimary = false,
    this.photoUrl,
    this.headline,
    this.professionalSummary,
    PersonalInfo? personalInfo,
    List<ExperienceItem>? experience,
    List<ProjectItem>? projects,
    List<EducationItem>? education,
    List<CertificationItem>? certifications,
    List<AchievementItem>? achievements,
    List<String>? skills,
    List<LanguageItem>? languages,
    List<String>? interests,
    List<ReferenceItem>? references,
    List<LinkItemModel>? links,
    List<CustomSectionModel>? customSections,
    List<String>? sectionOrder,
    List<String>? hiddenSections,
    required this.updatedAt,
  })  : personalInfo = personalInfo ?? PersonalInfo(),
        experience = experience ?? [],
        projects = projects ?? [],
        education = education ?? [],
        certifications = certifications ?? [],
        achievements = achievements ?? [],
        skills = skills ?? [],
        languages = languages ?? [],
        interests = interests ?? [],
        references = references ?? [],
        links = links ?? [],
        customSections = customSections ?? [],
        sectionOrder = sectionOrder ?? List.of(kSectionKeys),
        hiddenSections = hiddenSections ?? [];

  final String id;
  final String userId;
  final String title;
  final String template;
  final String themeColor;
  final String font;
  final bool isPrimary;
  final String? photoUrl;
  final String? headline;
  final String? professionalSummary;
  final PersonalInfo personalInfo;
  final List<ExperienceItem> experience;
  final List<ProjectItem> projects;
  final List<EducationItem> education;
  final List<CertificationItem> certifications;
  final List<AchievementItem> achievements;
  final List<String> skills;
  final List<LanguageItem> languages;
  final List<String> interests;
  final List<ReferenceItem> references;
  final List<LinkItemModel> links;
  final List<CustomSectionModel> customSections;
  final List<String> sectionOrder;
  final List<String> hiddenSections;
  final DateTime updatedAt;

  factory Resume.fromJson(Map<String, dynamic> json) => Resume(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        title: json['title'] as String,
        template: json['template'] as String,
        themeColor: json['theme_color'] as String,
        font: json['font'] as String,
        isPrimary: json['is_primary'] as bool,
        photoUrl: json['photo_url'] as String?,
        headline: json['headline'] as String?,
        professionalSummary: json['professional_summary'] as String?,
        personalInfo: PersonalInfo.fromJson(
          (json['personal_info'] as Map?)?.cast<String, dynamic>() ?? {},
        ),
        experience: (json['experience'] as List? ?? [])
            .map((e) => ExperienceItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        projects: (json['projects'] as List? ?? [])
            .map((e) => ProjectItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        education: (json['education'] as List? ?? [])
            .map((e) => EducationItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        certifications: (json['certifications'] as List? ?? [])
            .map((e) => CertificationItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        achievements: (json['achievements'] as List? ?? [])
            .map((e) => AchievementItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        skills: _strList(json['skills']),
        languages: (json['languages'] as List? ?? [])
            .map((e) => LanguageItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        interests: _strList(json['interests']),
        references: (json['references'] as List? ?? [])
            .map((e) => ReferenceItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        links: (json['links'] as List? ?? [])
            .map((e) => LinkItemModel.fromJson(e as Map<String, dynamic>))
            .toList(),
        customSections: (json['custom_sections'] as List? ?? [])
            .map((e) => CustomSectionModel.fromJson(e as Map<String, dynamic>))
            .toList(),
        sectionOrder: _strList(json['section_order']),
        hiddenSections: _strList(json['hidden_sections']),
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );

  /// Payload for PUT /resumes/{id} — matches backend ResumeUpdate exactly
  /// (no id/user_id/created_at/updated_at, those are server-managed).
  Map<String, dynamic> toUpdateJson() => {
        'title': title,
        'template': template,
        'theme_color': themeColor,
        'font': font,
        'is_primary': isPrimary,
        'photo_url': photoUrl,
        'headline': headline,
        'professional_summary': professionalSummary,
        'personal_info': personalInfo.toJson(),
        'experience': experience.map((e) => e.toJson()).toList(),
        'projects': projects.map((e) => e.toJson()).toList(),
        'education': education.map((e) => e.toJson()).toList(),
        'certifications': certifications.map((e) => e.toJson()).toList(),
        'achievements': achievements.map((e) => e.toJson()).toList(),
        'skills': skills,
        'languages': languages.map((e) => e.toJson()).toList(),
        'interests': interests,
        'references': references.map((e) => e.toJson()).toList(),
        'links': links.map((e) => e.toJson()).toList(),
        'custom_sections': customSections.map((e) => e.toJson()).toList(),
        'section_order': sectionOrder,
        'hidden_sections': hiddenSections,
      };

  /// Full JSON serialization for local persistence.
  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'updated_at': updatedAt.toIso8601String(),
        ...toUpdateJson(),
      };

  ResumeSummary toSummary() => ResumeSummary(
        id: id,
        title: title,
        template: template,
        themeColor: themeColor,
        isPrimary: isPrimary,
        headline: headline,
        updatedAt: updatedAt,
      );

  Resume copyWith({
    String? title,
    String? template,
    String? themeColor,
    String? font,
    bool? isPrimary,
    String? photoUrl,
    String? headline,
    String? professionalSummary,
    PersonalInfo? personalInfo,
    List<ExperienceItem>? experience,
    List<ProjectItem>? projects,
    List<EducationItem>? education,
    List<CertificationItem>? certifications,
    List<AchievementItem>? achievements,
    List<String>? skills,
    List<LanguageItem>? languages,
    List<String>? interests,
    List<ReferenceItem>? references,
    List<LinkItemModel>? links,
    List<CustomSectionModel>? customSections,
    List<String>? sectionOrder,
    List<String>? hiddenSections,
  }) =>
      Resume(
        id: id,
        userId: userId,
        title: title ?? this.title,
        template: template ?? this.template,
        themeColor: themeColor ?? this.themeColor,
        font: font ?? this.font,
        isPrimary: isPrimary ?? this.isPrimary,
        photoUrl: photoUrl ?? this.photoUrl,
        headline: headline ?? this.headline,
        professionalSummary: professionalSummary ?? this.professionalSummary,
        personalInfo: personalInfo ?? this.personalInfo,
        experience: experience ?? this.experience,
        projects: projects ?? this.projects,
        education: education ?? this.education,
        certifications: certifications ?? this.certifications,
        achievements: achievements ?? this.achievements,
        skills: skills ?? this.skills,
        languages: languages ?? this.languages,
        interests: interests ?? this.interests,
        references: references ?? this.references,
        links: links ?? this.links,
        customSections: customSections ?? this.customSections,
        sectionOrder: sectionOrder ?? this.sectionOrder,
        hiddenSections: hiddenSections ?? this.hiddenSections,
        updatedAt: updatedAt,
      );
}
