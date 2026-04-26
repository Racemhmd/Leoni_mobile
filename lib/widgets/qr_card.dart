import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/design_system.dart';

class QrCard extends StatelessWidget {
  final String matricule;
  
  const QrCard({super.key, required this.matricule});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: AppSpacing.m),
      padding: const EdgeInsets.all(AppSpacing.l),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('MY ID CARD', style: AppTypography.label.copyWith(color: AppColors.employeePrimary)),
                  const SizedBox(height: 4),
                  Text('Scan to Pay', style: AppTypography.headerSmall),
                ],
              ),
              Icon(Icons.qr_code_scanner, color: AppColors.employeePrimary.withOpacity(0.5)),
            ],
          ),
          const SizedBox(height: AppSpacing.l),
          Center(
            child: QrImageView(
              data: matricule,
              version: QrVersions.auto,
              size: 200.0,
              foregroundColor: AppColors.textDark,
            ),
          ),
          const SizedBox(height: AppSpacing.m),
          Text(
            matricule, 
            style: GoogleFonts.robotoMono(
              fontSize: 18, 
              fontWeight: FontWeight.bold, 
              letterSpacing: 2.0,
              color: AppColors.textLight
            )
          ),
        ],
      ),
    );
  }
}
