import 'package:flutter_bloc/flutter_bloc.dart';
import 'app_language.dart';
import 'language_state.dart';
import '../local_storage/prefs_service.dart';
import '../di/injection_container.dart' as di;

class LanguageCubit extends Cubit<LanguageState> {
  LanguageCubit() : super(const LanguageState(language: AppLanguage.ar));

  Future<void> load() async {
    await di.appReady; // safe to call before SharedPrefs is ready
    final langCode = di.sl<PrefsService>().getAppLanguage();
    final lang = langCode == 'en' ? AppLanguage.en : AppLanguage.ar;
    if (!isClosed) emit(LanguageState(language: lang));
  }

  Future<void> setLanguage(AppLanguage language) async {
    await di.appReady;
    final langCode = language == AppLanguage.ar ? 'ar' : 'en';
    await di.sl<PrefsService>().setAppLanguage(langCode);
    if (!isClosed) emit(LanguageState(language: language));
  }
}
