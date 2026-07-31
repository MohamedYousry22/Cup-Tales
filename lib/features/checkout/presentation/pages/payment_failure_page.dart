import 'package:flutter/material.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/localization/language_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PaymentFailurePage extends StatelessWidget {
  const PaymentFailurePage({super.key});

  @override
  Widget build(BuildContext context) {
    context.watch<LanguageCubit>();
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 100, color: Colors.red),
              const SizedBox(height: 24),
              Text(
                context.tr('Payment Failed', 'فشلت عملية الدفع'),
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text(
                context.tr(
                  'Something went wrong with your transaction. Please try again.',
                  'حدث خطأ ما أثناء العملية. يرجى المحاولة مرة أخرى.',
                ),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
                child: Text(
                  context.tr('Try Again', 'المحاولة مرة أخرى'),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pushNamedAndRemoveUntil(
                    context, AppRouter.home, (route) => false),
                child: Text(context.loc.backToHome),
              )
            ],
          ),
        ),
      ),
    );
  }
}
