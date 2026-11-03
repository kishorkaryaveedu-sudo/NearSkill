/// SkillModel – maps to public.skills table
class SkillModel {
  final String skillId;
  final String skillName;
  final String status;

  const SkillModel({
    required this.skillId,
    required this.skillName,
    this.status = 'approved',
  });

  factory SkillModel.fromMap(Map<String, dynamic> map) {
    return SkillModel(
      skillId: map['skill_id'] ?? '',
      skillName: map['skill_name'] ?? '',
      status: map['status'] ?? 'approved',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'skill_id': skillId,
      'skill_name': skillName,
      'status': status,
    };
  }

  @override
  String toString() => 'SkillModel(skillId: $skillId, skillName: $skillName)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SkillModel && other.skillId == skillId;
  }

  @override
  int get hashCode => skillId.hashCode;
}
