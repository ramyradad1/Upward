// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Upward';

  @override
  String get loginTitle => 'Sign In';

  @override
  String get loginSubtitle => 'Sign in to manage your assets';

  @override
  String get emailLabel => 'Email';

  @override
  String get passwordLabel => 'Password';

  @override
  String get loginButton => 'Sign In';

  @override
  String get dashboardTitle => 'Assets';

  @override
  String get searchHint => 'Search serial, asset tag, or user...';

  @override
  String get filterAll => 'All Assets';

  @override
  String get filterInStock => 'In Stock';

  @override
  String get filterAssigned => 'Assigned';

  @override
  String get filterRepair => 'Repair';

  @override
  String get filterBroken => 'Broken';

  @override
  String get addAsset => 'Add Asset';

  @override
  String get noAssets => 'No assets found';

  @override
  String get deleteAsset => 'Delete Asset';

  @override
  String get editAsset => 'Edit Asset';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get logout => 'Logout';

  @override
  String get adminAccess => 'Admin Access';

  @override
  String get adminEmail => 'Admin Email';

  @override
  String get companies => 'Companies';

  @override
  String get users => 'Users';

  @override
  String get profile => 'Profile';

  @override
  String get theme => 'Theme';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeSystem => 'System';

  @override
  String get noCompanies => 'No companies yet';

  @override
  String get language => 'Language';
}
