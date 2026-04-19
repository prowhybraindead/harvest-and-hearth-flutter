import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../constants/translations.dart';
import '../models/food_item.dart';
import 'backend_api_service.dart';

/// Daily summary at 09:00 local time when there are expired / expiring-soon items.
class ExpiryReminderService {
  ExpiryReminderService._();
  static final ExpiryReminderService instance = ExpiryReminderService._();

  static const prefsKeyEnabled = 'expiry_reminders_enabled';
  static const _channelId = 'harvest_expiry';
  static const _channelIdUrgent = 'harvest_expiry_urgent';
  /// High-importance channel for immediate / heads-up notifications (Android 8+).
  static const _channelIdImmediate = 'harvest_expiry_immediate';
  static const _notificationIdSummary = 10001;
  static const _notificationIdSimulatorTest = 10002;
  static const _notificationIdUrgent = 10003;
  static const _prefsUrgentLastDate = 'expiry_urgent_last_date';
  static const _prefsSummaryLogLast = 'expiry_summary_log_last';

  static const payloadSummary = 'expiry:summary';
  static const payloadUrgent = 'expiry:urgent';
  static const payloadSimulator = 'expiry:simulator';

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  final StreamController<String> _tapPayloadController =
      StreamController<String>.broadcast();

  Stream<String> get tapPayloadStream => _tapPayloadController.stream;

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    tzdata.initializeTimeZones();
    try {
      final tzName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(tzName));
    } catch (e, st) {
      debugPrint('ExpiryReminderService timezone: $e\n$st');
      tz.setLocalLocation(tz.getLocation('UTC'));
    }

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    await _plugin.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload != null && payload.isNotEmpty) {
          _tapPayloadController.add(payload);
        }
      },
    );

    final launchDetails = await _plugin.getNotificationAppLaunchDetails();
    final launchPayload = launchDetails?.notificationResponse?.payload;
    if (launchDetails?.didNotificationLaunchApp == true &&
        launchPayload != null &&
        launchPayload.isNotEmpty) {
      _tapPayloadController.add(launchPayload);
    }

    if (Platform.isAndroid) {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await android?.createNotificationChannel(
        const AndroidNotificationChannel(
          _channelId,
          'Nhắc hạn thực phẩm',
          description: 'Thông báo khi có mặt hàng sắp hết hạn hoặc đã hết hạn',
          importance: Importance.defaultImportance,
        ),
      );
      await android?.createNotificationChannel(
        const AndroidNotificationChannel(
          _channelIdUrgent,
          'Harvest & Hearth — Cảnh báo khẩn',
          description: 'Cảnh báo ngay khi có thực phẩm đã hết hạn',
          importance: Importance.high,
        ),
      );
      await android?.createNotificationChannel(
        const AndroidNotificationChannel(
          _channelIdImmediate,
          'Harvest & Hearth — Thông báo ngay',
          description: 'Thông báo thử và cảnh báo hiển thị ngay',
          importance: Importance.high,
        ),
      );
    }
    _initialized = true;
  }

  Future<bool> remindersEnabled() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(prefsKeyEnabled) ?? true;
  }

  Future<void> setRemindersEnabled(bool value) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(prefsKeyEnabled, value);
    if (!value) {
      await cancelAll();
    }
  }

  Future<void> requestPostNotificationsPermissionIfNeeded() async {
    if (!Platform.isAndroid) return;
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestNotificationsPermission();
  }

  Future<void> syncInventory(
    List<FoodItem> items, {
    required String language,
    String? userId,
  }) async {
    if (!_initialized) await init();
    final enabled = await remindersEnabled();
    if (!enabled) {
      await _plugin.cancel(_notificationIdSummary);
      return;
    }

    final expiring = items.where((e) => e.isExpiringSoon && !e.isExpired).length;
    final expiredItems = items.where((e) => e.isExpired).toList();
    final expired = expiredItems.length;
    final expiringItems = items.where((e) => e.isExpiringSoon && !e.isExpired).toList();
    if (expiring == 0 && expired == 0) {
      await _plugin.cancel(_notificationIdSummary);
      await _plugin.cancel(_notificationIdUrgent);
      return;
    }

    final lang = language == 'ENG' ? 'ENG' : 'VIE';
    final title = Translations.get('expiry_notif_summary_title', lang);
    final body = Translations.get('expiry_notif_summary_body', lang)
        .replaceAll('{expired}', '$expired')
        .replaceAll('{expiring}', '$expiring');

    final summaryLines = _buildSummaryLines(
      expiredItems: expiredItems,
      expiringItems: expiringItems,
      language: lang,
    );

    final android = AndroidNotificationDetails(
      _channelId,
      'Nhắc hạn thực phẩm',
      channelDescription: 'Tóm tắt mỗi ngày lúc 9:00',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      icon: 'ic_stat_harvest',
      styleInformation: InboxStyleInformation(
        summaryLines,
        contentTitle: title,
        summaryText: body,
      ),
    );
    const ios = DarwinNotificationDetails();
    final details = NotificationDetails(android: android, iOS: ios);

    await _plugin.cancel(_notificationIdSummary);

    final scheduled = _nextNineAm();
    try {
      await _plugin.zonedSchedule(
        _notificationIdSummary,
        title,
        body,
        scheduled,
        details,
        payload: payloadSummary,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e, st) {
      debugPrint('ExpiryReminderService zonedSchedule: $e\n$st');
    }

    await _logSummaryNotificationIfNeeded(
      userId: userId,
      title: title,
      message: body,
    );

    await _maybeShowUrgentExpired(
      expiredItems: expiredItems,
      language: lang,
      userId: userId,
    );
  }

  Future<void> _maybeShowUrgentExpired({
    required List<FoodItem> expiredItems,
    required String language,
    String? userId,
  }) async {
    if (expiredItems.isEmpty) {
      await _plugin.cancel(_notificationIdUrgent);
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final todayKey = '${today.year.toString().padLeft(4, '0')}-'
        '${today.month.toString().padLeft(2, '0')}-'
        '${today.day.toString().padLeft(2, '0')}';
    final lastSent = prefs.getString(_prefsUrgentLastDate);
    if (lastSent == todayKey) return;

    final title = Translations.get('expiry_notif_urgent_title', language);
    final body = Translations.get('expiry_notif_urgent_body', language)
        .replaceAll('{expired}', '${expiredItems.length}');
    final itemNames = expiredItems.map((e) => '- ${e.name}').take(6).join('\n');
    final bigText = '$body\n\n$itemNames';

    final android = AndroidNotificationDetails(
      _channelIdUrgent,
      'Harvest & Hearth — Cảnh báo khẩn',
      channelDescription: 'Cảnh báo ngay khi có thực phẩm đã hết hạn',
      importance: Importance.high,
      priority: Priority.high,
      icon: 'ic_stat_harvest',
      visibility: NotificationVisibility.public,
      category: AndroidNotificationCategory.alarm,
      styleInformation: BigTextStyleInformation(bigText),
      enableVibration: true,
      playSound: true,
    );
    const ios = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    await _plugin.show(
      _notificationIdUrgent,
      title,
      body,
      NotificationDetails(android: android, iOS: ios),
      payload: payloadUrgent,
    );
    await prefs.setString(_prefsUrgentLastDate, todayKey);

    await _logNotificationToBackend(
      userId: userId,
      title: title,
      message: body,
      type: 'expiry',
    );
  }

  Future<void> _logSummaryNotificationIfNeeded({
    required String? userId,
    required String title,
    required String message,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '${_todayKey()}|${userId ?? ''}|$message';
    final last = prefs.getString(_prefsSummaryLogLast);
    if (last == key) return;

    await _logNotificationToBackend(
      userId: userId,
      title: title,
      message: message,
      type: 'expiry',
    );
    await prefs.setString(_prefsSummaryLogLast, key);
  }

  String _todayKey() {
    final now = DateTime.now();
    return '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
  }

  Future<void> _logNotificationToBackend({
    required String? userId,
    required String title,
    required String message,
    required String type,
  }) async {
    if (userId == null || userId.isEmpty) return;
    if (!BackendApiService.instance.isConfigured) return;
    try {
      await BackendApiService.instance.createNotificationLog(
        title: title,
        message: message,
        type: type,
      );
    } catch (e, st) {
      debugPrint('ExpiryReminderService notification log: $e\n$st');
    }
  }

  List<String> _buildSummaryLines({
    required List<FoodItem> expiredItems,
    required List<FoodItem> expiringItems,
    required String language,
  }) {
    final labels = language == 'ENG'
        ? (expired: 'Expired', expiring: 'Expiring soon')
        : (expired: 'Hết hạn', expiring: 'Sắp hết hạn');
    final lines = <String>[
      '${labels.expired}: ${expiredItems.length}',
      '${labels.expiring}: ${expiringItems.length}',
    ];

    final previewNames = {
      ...expiredItems.map((e) => e.name),
      ...expiringItems.map((e) => e.name),
    }.take(4);
    if (previewNames.isNotEmpty) {
      lines.add(previewNames.join(', '));
    }
    return lines;
  }

  tz.TZDateTime _nextNineAm() {
    final now = tz.TZDateTime.now(tz.local);
    var t = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      9,
      0,
    );
    if (!t.isAfter(now)) {
      t = t.add(const Duration(days: 1));
    }
    return t;
  }

  Future<void> cancelAll() async {
    if (!_initialized) await init();
    await _plugin.cancel(_notificationIdSummary);
    await _plugin.cancel(_notificationIdSimulatorTest);
    await _plugin.cancel(_notificationIdUrgent);
  }

  /// Immediate notification with the same copy as the daily summary (QA / time simulator).
  /// Returns `false` if the user denied notification permission (Android 13+ / iOS).
  Future<bool> showImmediateTestSummary({
    required int expiring,
    required int expired,
    required String language,
    String? userId,
  }) async {
    if (!_initialized) await init();

    if (Platform.isAndroid) {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final granted = await android?.requestNotificationsPermission();
      if (granted == false) {
        debugPrint('ExpiryReminderService: POST_NOTIFICATIONS denied');
        return false;
      }
    } else if (Platform.isIOS) {
      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      final ok = await ios?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      if (ok == false) {
        debugPrint('ExpiryReminderService: iOS notification permission denied');
        return false;
      }
    }

    final lang = language == 'ENG' ? 'ENG' : 'VIE';
    final title = Translations.get('expiry_notif_test_title', lang);
    final body = Translations.get('expiry_notif_test_body', lang)
        .replaceAll('{expired}', '$expired')
        .replaceAll('{expiring}', '$expiring');

    final android = AndroidNotificationDetails(
      _channelIdImmediate,
      'Harvest & Hearth — Thông báo ngay',
      channelDescription: 'Thông báo thử và cảnh báo hiển thị ngay',
      importance: Importance.high,
      priority: Priority.high,
      icon: 'ic_stat_harvest',
      visibility: NotificationVisibility.public,
      showWhen: true,
      enableVibration: true,
      playSound: true,
      styleInformation: BigTextStyleInformation(body),
    );
    const ios = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    final details = NotificationDetails(android: android, iOS: ios);

    try {
      await _plugin.show(
        _notificationIdSimulatorTest,
        title,
        body,
        details,
        payload: payloadSimulator,
      );

      await _logNotificationToBackend(
        userId: userId,
        title: title,
        message: body,
        type: 'expiry_test',
      );

      return true;
    } catch (e, st) {
      debugPrint('ExpiryReminderService showImmediateTestSummary: $e\n$st');
      return false;
    }
  }
}
