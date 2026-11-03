import os

filepath = 'lib/features/discovery/presentation/nearby_workers_screen.dart'

new_code = '''
class _WorkerDetailSheet extends ConsumerWidget {
  final WorkerProfileModel worker;

  const _WorkerDetailSheet({required this.worker});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(32),
                child: worker.profilePhotoUrl?.isNotEmpty == true
                    ? Image.network(worker.profilePhotoUrl!, width: 64, height: 64, fit: BoxFit.cover)
                    : Container(width: 64, height: 64, color: AppColors.primary, child: const Icon(Icons.person, color: Colors.white, size: 32)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(worker.displayName, style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    const SizedBox(height: 4),
                    Text('${worker.experienceYears} yrs experience', style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _infoCard('Rating', '${worker.averageRating.toStringAsFixed(1)} ★'),
              _infoCard('Rate', '₹${worker.hourlyRate.toInt()}/hr'),
              _infoCard('Status', worker.isVerified ? 'Verified' : 'New'),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () {
                // Navigate to chat or booking
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('Message', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _infoCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow ?? const Color(0xFFF6F3F5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 4),
          Text(value, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        ],
      ),
    );
  }
}
'''

with open(filepath, 'a') as f:
    f.write(new_code)
print("Appended _WorkerDetailSheet")
