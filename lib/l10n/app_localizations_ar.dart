// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'أبوارد';

  @override
  String get loginTitle => 'تسجيل الدخول';

  @override
  String get loginSubtitle => 'سجل الدخول لإدارة الأصول الخاصة بك';

  @override
  String get emailLabel => 'البريد الإلكتروني';

  @override
  String get passwordLabel => 'كلمة المرور';

  @override
  String get loginButton => 'تسجيل الدخول';

  @override
  String get dashboardTitle => 'الأصول';

  @override
  String get searchHint =>
      'ابحث عن الرقم التسلسلي، علامة الأصل، أو المستخدم...';

  @override
  String get filterAll => 'كل الأصول';

  @override
  String get filterInStock => 'في المخزون';

  @override
  String get filterAssigned => 'تم التعيين';

  @override
  String get filterRepair => 'تحت الصيانة';

  @override
  String get filterBroken => 'تالف';

  @override
  String get addAsset => 'إضافة أصل';

  @override
  String get noAssets => 'لم يتم العثور على أصول';

  @override
  String get deleteAsset => 'حذف الأصل';

  @override
  String get editAsset => 'تعديل الأصل';

  @override
  String get save => 'حفظ';

  @override
  String get cancel => 'إلغاء';

  @override
  String get logout => 'تسجيل الخروج';

  @override
  String get adminAccess => 'وصول المسؤول';

  @override
  String get adminEmail => 'بريد المسؤول';

  @override
  String get companies => 'الشركات';

  @override
  String get users => 'المستخدمين';

  @override
  String get profile => 'الملف الشخصي';

  @override
  String get theme => 'المظهر';

  @override
  String get themeLight => 'فاتح';

  @override
  String get themeDark => 'داكن';

  @override
  String get themeSystem => 'النظام';

  @override
  String get noCompanies => 'لا توجد شركات حتى الآن';

  @override
  String get language => 'اللغة';
}
