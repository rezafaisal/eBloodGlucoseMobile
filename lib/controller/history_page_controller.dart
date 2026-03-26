import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';

import '../service/utils_service.dart';

class HistoryPageController extends GetxController {
  final UtilService utilService = UtilService();
  final dayGlucoseSpots = <FlSpot>[].obs;
  final weightSpots = <FlSpot>[].obs;
  final max = 0.0.obs;
  final min = 0.0.obs;
  final average = '0'.obs;
  final token = ''.obs;
  final listDates = [].obs;
  final dateKeys = 0.obs;

  // Blood sugar chart data
  final beforeMealSpots = <FlSpot>[].obs;
  final afterMealSpots = <FlSpot>[].obs;
  final otherSpots = <FlSpot>[].obs;
  final dailyBars = <BarChartGroupData>[].obs;
  final weeklyBars = <BarChartGroupData>[].obs;
  final weeklyAverage = 0.0.obs;
  final dailyAverage = 0.0.obs;
  final isWeeklyMode = true.obs;

  // Daily view meal type spots
  final dailyBeforeMealSpots = <FlSpot>[].obs;
  final dailyAfterMealSpots = <FlSpot>[].obs;
  final dailyOtherSpots = <FlSpot>[].obs;

  // Weekly navigation
  final currentWeekOffset = 0.obs;

  // Monthly weight navigation
  final currentWeightMonth = DateTime.now().obs;
  final weightChange = '0'.obs;
  final isLoadingWeightData = false.obs;

  // Blood sugar history (new API endpoint)
  final bloodSugarHistorySpots = <FlSpot>[].obs;
  final bloodSugarHistoryDates = <DateTime>[].obs;
  final bloodSugarHistoryRawData = <Map<String, dynamic>>[].obs;
  final currentBloodSugarMonth = DateTime.now().obs;
  final isLoadingBloodSugarHistory = false.obs;
  final bloodSugarStats = {
    'average': 0.0,
    'min': 0.0,
    'max': 0.0,
    'count': 0,
  }.obs;

  // Flag to track if data needs refresh
  bool _needsRefresh = true;

  Set<String> uniqueDates = {};

  String dateToday = DateFormat('yyyy-MM-dd').format(DateTime.now());

  // Cache untuk menyimpan data yang sudah pernah di-load dari SERVER
  // Cache ini HANYA untuk data dari server, bukan data lokal
  final Map<String, Map<String, dynamic>> _bloodSugarCache = {};
  final Map<String, Map<String, dynamic>> _weightCache = {};

  // Cache expiry: 2 jam (data akan di-request ulang setelah 2 jam)
  static const Duration _cacheExpiry = Duration(hours: 2);
  @override
  Future<void> onInit() async {
    dayGlucoseSpots.value = utilService.chartData([]);
    await setupPage();

    // Use the current selected date from setupPage, or today if available
    String initialDate = dateToday; // fallback to today instead of yesterday
    if (listDates.isNotEmpty && dateKeys.value < listDates.length) {
      initialDate = listDates[dateKeys.value];
    }

    print(
        'DEBUG onInit: dateToday=$dateToday, dateKeys=${dateKeys.value}, listDates.length=${listDates.length}');
    print('DEBUG onInit: initialDate=$initialDate');
    if (listDates.isNotEmpty) {
      print(
          'DEBUG onInit: listDates=${listDates.take(5)}'); // Show first 5 dates
    }

    await getGlucoseHistory(initialDate);
    await loadWeightData(); // Load weight chart data
    await loadBloodSugarHistory(); // Load blood sugar history from API

    // Force update to ensure UI shows the correct data
    print('DEBUG onInit: Force updating UI after data load');
    update();

    super.onInit();
  }

  @override
  void onReady() {
    super.onReady();
    // Don't refresh here since onInit already handles it properly
    // refreshCurrentData();
  }

  // Method to refresh current data when returning to page
  void refreshCurrentData() {
    print(
        'DEBUG refreshCurrentData: _needsRefresh=$_needsRefresh, dateKeys=${dateKeys.value}, listDates.length=${listDates.length}');

    // Only refresh if data is available and needs refresh
    if (listDates.isEmpty) {
      print('DEBUG refreshCurrentData: listDates is empty, skipping refresh');
      return;
    }

    if (_needsRefresh && dateKeys.value < listDates.length) {
      String currentDate = listDates[dateKeys.value];
      print('DEBUG refreshCurrentData: loading date=$currentDate');
      getGlucoseHistory(currentDate);
      _needsRefresh = false; // Prevent multiple refreshes
    } else {
      // Force refresh to make sure we have the right data
      print('DEBUG refreshCurrentData: Force refreshing current selected date');
      if (dateKeys.value < listDates.length) {
        String currentDate = listDates[dateKeys.value];
        print('DEBUG refreshCurrentData: Force loading date=$currentDate');
        getGlucoseHistory(currentDate);
      }
    }
  }

  // Call this when navigation occurs to mark data as needing refresh
  void markForRefresh() {
    _needsRefresh = true;
  }

  Future<void> setupPage() async {
    if (Hive.isBoxOpen('glucoseData')) {
      var box = await Hive.openBox('glucoseData');
      List<dynamic> dataList = box.get('GlucoseList', defaultValue: []);

      // Collect all dates from data
      for (var entry in dataList) {
        DateTime date = DateTime.parse(entry['date']);
        String formattedDate = DateFormat('yyyy-MM-dd').format(date);
        DateTime today = DateTime.now();
        DateTime dateOnly = DateTime(date.year, date.month, date.day);
        DateTime todayOnly = DateTime(today.year, today.month, today.day);

        if (dateOnly.isBefore(todayOnly) ||
            dateOnly.isAtSameMomentAs(todayOnly)) {
          uniqueDates.add(formattedDate);
        }
      }

      // Generate a complete date range from earliest data to today
      if (uniqueDates.isNotEmpty) {
        List<String> sortedDates = uniqueDates.toList()..sort();
        DateTime earliestDate = DateTime.parse(sortedDates.first);
        DateTime today = DateTime.now();

        Set<String> completeDateRange = {};
        DateTime currentDate = earliestDate;
        while (currentDate.isBefore(today) ||
            currentDate.isAtSameMomentAs(
                DateTime(today.year, today.month, today.day))) {
          completeDateRange.add(DateFormat('yyyy-MM-dd').format(currentDate));
          currentDate = currentDate.add(const Duration(days: 1));
        }

        listDates.value = completeDateRange.toList()..sort();
      } else {
        // If no data, at least include today
        String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
        listDates.value = [today];
      }

      dateKeys.value =
          listDates.length - 1; // Start with the latest date (today)
      print(
          'DEBUG setupPage: listDates.length=${listDates.length}, dateKeys=${dateKeys.value}');
      print(
          'DEBUG setupPage: listDates.last=${listDates.isNotEmpty ? listDates.last : "empty"}');
    }
  }

  Future<void> getGlucoseHistory(String date) async {
    print('DEBUG getGlucoseHistory: Loading data for date=$date');
    if (Hive.isBoxOpen('glucoseData')) {
      var box = await Hive.openBox('glucoseData');
      populateData(box, date);
      _needsRefresh = false; // Reset flag after loading data
      update();
    }
  }

  void populateData(Box box, String date) {
    print('DEBUG populateData: Searching for data on date=$date');
    if (box.isNotEmpty) {
      DateTime dateTime = DateTime.parse(date);
      List<dynamic> dataList = box.get('GlucoseList', defaultValue: []);
      print('DEBUG populateData: Total data entries=${dataList.length}');

      // Print sample data dates for debugging
      if (dataList.isNotEmpty) {
        print('DEBUG populateData: Sample dates from data:');
        for (int i = 0; i < dataList.length && i < 5; i++) {
          var entry = dataList[i];
          print('  - ${entry['date']} (glucose: ${entry['blood_glucose']})');
        }
      }

      List<dynamic> dayDataList = dataList.where((entry) {
        DateTime date = DateTime.parse(entry['date']);
        return date.year == dateTime.year &&
            date.month == dateTime.month &&
            date.day == dateTime.day;
      }).toList();

      print(
          'DEBUG populateData: Found ${dayDataList.length} entries for date=$date');

      if (dayDataList.isNotEmpty) {
        double totalGlucose = 0.0;

        // Reset daily meal type spots
        Map<String, List<FlSpot>> dailyMealTypeSpots = {
          'before': [],
          'after': [],
          'other': [],
        };

        for (var entry in dayDataList) {
          double glucose = entry['blood_glucose'];
          if (min.value == 0.0) min.value = glucose;
          if (glucose < min.value) min.value = glucose;
          if (glucose > max.value) max.value = glucose;
          totalGlucose += glucose;

          // Process meal type for daily view
          DateTime entryDateTime = DateTime.parse(entry['date']);
          String mealType = (entry['meal_time'] ?? '').toString().toLowerCase();

          // Convert time to minutes since midnight for X-axis
          double timeInMinutes =
              (entryDateTime.hour * 60 + entryDateTime.minute).toDouble();

          // Add to spots based on meal type
          if (mealType.contains('sebelum') || mealType.contains('before')) {
            dailyMealTypeSpots['before']!.add(FlSpot(timeInMinutes, glucose));
          } else if (mealType.contains('setelah') ||
              mealType.contains('sesudah') ||
              mealType.contains('after')) {
            dailyMealTypeSpots['after']!.add(FlSpot(timeInMinutes, glucose));
          } else {
            dailyMealTypeSpots['other']!.add(FlSpot(timeInMinutes, glucose));
          }
        }

        average.value = (totalGlucose / dayDataList.length).toStringAsFixed(2);
        dailyAverage.value = double.parse(
            (totalGlucose / dayDataList.length).toStringAsFixed(2));

        // Update daily meal type spots
        dailyBeforeMealSpots.value = dailyMealTypeSpots['before']!;
        dailyAfterMealSpots.value = dailyMealTypeSpots['after']!;
        dailyOtherSpots.value = dailyMealTypeSpots['other']!;

        dayGlucoseSpots.value =
            utilService.chartData(dayDataList, dateDiff: dateTime);

        // Update statistics for daily mode
        updateStatistics();
      } else {
        // No data for this day
        dailyAverage.value = 0.0;
        dailyBeforeMealSpots.value = [];
        dailyAfterMealSpots.value = [];
        dailyOtherSpots.value = [];
        max.value = 0.0;
        min.value = 0.0;
      }
    }
  }

  Future<void> loadWeightData() async {
    isLoadingWeightData.value = true;
    try {
      // Format month for API (YYYY-MM)
      String monthParam =
          DateFormat('yyyy-MM').format(currentWeightMonth.value);

      // Check cache first
      if (_weightCache.containsKey(monthParam)) {
        final cachedData = _weightCache[monthParam]!;
        final DateTime cachedTime = cachedData['timestamp'];

        // Check if cache is still valid (belum expired)
        if (DateTime.now().difference(cachedTime) < _cacheExpiry) {
          print(
              '📦 Using cached weight data for $monthParam (cached ${DateTime.now().difference(cachedTime).inMinutes} minutes ago)');
          weightSpots.value = List<FlSpot>.from(cachedData['spots']);
          weightChange.value = cachedData['change'];
          isLoadingWeightData.value = false;
          return;
        } else {
          print('⏰ Cache expired for $monthParam, will fetch from server');
          _weightCache.remove(monthParam); // Remove expired cache
        }
      }

      // Get token from Hive - using 'token' box like other controllers
      if (Hive.isBoxOpen('token')) {
        var tokenBox = await Hive.openBox('token');
        final token = tokenBox.getAt(0);

        if (token == null) {
          print('❌ No token available for weight data request');
          Get.snackbar(
            'Error',
            'Token tidak tersedia. Silakan login kembali.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.orange,
            colorText: Colors.white,
            duration: const Duration(seconds: 3),
            icon: const Icon(Icons.warning, color: Colors.white),
          );
          await loadWeightDataFromLocal();
          isLoadingWeightData.value = false;
          return;
        }

        final connect = GetConnect();

        final url =
            '${utilService.url}/api/weight-readings/history?month=$monthParam';
        print('Making weight API request to: $url');

        // Make API request
        final response = await connect.get(
          url,
          headers: {'Authorization': 'Bearer $token'},
        ).timeout(const Duration(seconds: 20));

        print('Response status: ${response.statusCode}');
        if (response.statusCode == 200 && response.body != null) {
          final data = response.body;
          print('Weight API Response: $data');
          if (data['data'] != null) {
            List<dynamic> weightData = data['data'];
            weightChange.value = data['weightChange']?.toString() ?? '0';

            List<FlSpot> spots = [];

            // Convert API data to FlSpot for chart
            for (var entry in weightData) {
              double day = entry['day'].toDouble();
              double weight = entry['weight'].toDouble();
              spots.add(FlSpot(day, weight));
            }

            // Sort spots by day
            spots.sort((a, b) => a.x.compareTo(b.x));

            weightSpots.value = spots;

            // Save to cache dengan timestamp (hanya dari server)
            _weightCache[monthParam] = {
              'spots': spots,
              'change': weightChange.value,
              'timestamp': DateTime.now(), // Waktu cache disimpan
            };

            print(
                '✅ Weight data loaded from server: ${spots.length} entries for month $monthParam');
          } else {
            // No data for this month from server, try local
            print(
                '⚠️ No weight data from server for month $monthParam, trying local...');
            await loadWeightDataFromLocal();
          }
        } else {
          print(
              '❌ Failed to load weight data from server: ${response.statusCode}');
          Get.snackbar(
            'Info',
            'Gagal memuat data dari server. Menampilkan data lokal.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.orange,
            colorText: Colors.white,
            duration: const Duration(seconds: 2),
            icon: const Icon(Icons.cloud_off, color: Colors.white),
          );
          await loadWeightDataFromLocal();
        }
      } else {
        print('❌ Token box is not open');
        Get.snackbar(
          'Error',
          'Terjadi kesalahan sistem. Silakan restart aplikasi.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
          icon: const Icon(Icons.error, color: Colors.white),
        );
        await loadWeightDataFromLocal();
      }
    } catch (e) {
      print('❌ Error loading weight data from server: $e');
      Get.snackbar(
        'Info',
        'Tidak dapat terhubung ke server. Menampilkan data lokal.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
        icon: const Icon(Icons.cloud_off, color: Colors.white),
      );
      await loadWeightDataFromLocal();
    }
    isLoadingWeightData.value = false;
  }

  Future<void> loadBloodSugarData() async {
    try {
      var box = await Hive.openBox('glucoseData');
      List<dynamic> glucoseDataList = box.get('GlucoseList', defaultValue: []);

      if (glucoseDataList.isNotEmpty) {
        DateTime now = DateTime.now();

        // Calculate week start based on offset
        DateTime weekStart = now
            .subtract(Duration(days: 7 + (currentWeekOffset.value.abs() * 7)));
        DateTime weekEnd = weekStart.add(const Duration(days: 7));

        // Filter data for the selected week
        List<dynamic> weekData = glucoseDataList.where((entry) {
          DateTime entryDate = DateTime.parse(entry['date']);
          return entryDate.isAfter(weekStart) && entryDate.isBefore(weekEnd);
        }).toList();

        // Sort by date
        weekData.sort((a, b) =>
            DateTime.parse(a['date']).compareTo(DateTime.parse(b['date'])));

        // Group by day and meal type to calculate daily averages
        Map<int, Map<String, List<double>>> dailyMealData = {};
        Map<int, List<double>> dailyValues = {};
        double totalValue = 0;
        int totalCount = 0;

        for (var entry in weekData) {
          DateTime entryDate = DateTime.parse(entry['date']);
          double glucose = entry['blood_glucose'].toDouble();
          String mealTime = entry['meal_time'] ?? 'other';

          // Calculate day of week (0 = Monday)
          int dayOfWeek = (entryDate.weekday - 1) % 7;

          // Initialize daily data structure
          if (!dailyMealData.containsKey(dayOfWeek)) {
            dailyMealData[dayOfWeek] = {
              'before': [],
              'after': [],
              'other': [],
            };
          }

          // Categorize meal type and add to daily data
          String mealCategory = 'other';
          String lowerMealTime = mealTime.toLowerCase();
          if (lowerMealTime.contains('pagi') ||
              lowerMealTime.contains('before') ||
              lowerMealTime.contains('sebelum')) {
            mealCategory = 'before';
          } else if (lowerMealTime.contains('siang') ||
              lowerMealTime.contains('sore') ||
              lowerMealTime.contains('malam') ||
              lowerMealTime.contains('after') ||
              lowerMealTime.contains('setelah')) {
            mealCategory = 'after';
          }

          dailyMealData[dayOfWeek]![mealCategory]!.add(glucose);

          // Add to daily values for bar chart
          if (!dailyValues.containsKey(dayOfWeek)) {
            dailyValues[dayOfWeek] = [];
          }
          dailyValues[dayOfWeek]!.add(glucose);

          totalValue += glucose;
          totalCount++;
        }

        // Calculate daily averages for each meal type
        Map<String, List<FlSpot>> mealTypeSpots = {
          'before': [],
          'after': [],
          'other': [],
        };

        for (int day = 0; day < 7; day++) {
          if (dailyMealData.containsKey(day)) {
            // Calculate average for each meal type on this day
            for (String mealType in ['before', 'after', 'other']) {
              List<double> values = dailyMealData[day]![mealType]!;
              if (values.isNotEmpty) {
                double average = values.reduce((a, b) => a + b) / values.length;
                mealTypeSpots[mealType]!.add(FlSpot(day.toDouble(), average));
              }
            }
          }
        }

        // Calculate weekly average
        weeklyAverage.value = totalCount > 0
            ? double.parse((totalValue / totalCount).toStringAsFixed(2))
            : 0.0;

        // Calculate daily average (for today)
        DateTime today = DateTime.now();
        DateTime todayStart = DateTime(today.year, today.month, today.day);
        List<dynamic> todayData = glucoseDataList.where((entry) {
          DateTime entryDate = DateTime.parse(entry['date']);
          DateTime entryDay =
              DateTime(entryDate.year, entryDate.month, entryDate.day);
          return entryDay.isAtSameMomentAs(todayStart);
        }).toList();

        if (todayData.isNotEmpty) {
          double todayTotal = 0;
          for (var entry in todayData) {
            todayTotal +=
                (entry['blood_glucose'] ?? entry['glucose'] ?? 0).toDouble();
          }
          dailyAverage.value =
              double.parse((todayTotal / todayData.length).toStringAsFixed(2));
        } else {
          dailyAverage.value = 0.0;
        }

        // Update spots
        beforeMealSpots.value = mealTypeSpots['before']!;
        afterMealSpots.value = mealTypeSpots['after']!;
        otherSpots.value = mealTypeSpots['other']!;

        // Create bar chart data
        List<BarChartGroupData> bars = [];
        for (int i = 0; i < 7; i++) {
          double avgValue = 0;
          if (dailyValues.containsKey(i) && dailyValues[i]!.isNotEmpty) {
            avgValue = dailyValues[i]!.reduce((a, b) => a + b) /
                dailyValues[i]!.length;
          }
          bars.add(
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: avgValue,
                  color: Colors.blue.withOpacity(0.7),
                  width: 16,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(4),
                  ),
                ),
              ],
            ),
          );
        }
        dailyBars.value = bars;
        weeklyBars.value = bars; // Initially use the same data

        // Update statistics based on current mode
        updateStatistics();
      }
    } catch (e) {
      print('Error loading blood sugar data: $e');
    }
  }

  void toggleViewMode() {
    isWeeklyMode.value = !isWeeklyMode.value;
  }

  void previousWeek() {
    currentWeekOffset.value--;
    loadBloodSugarData(); // Reload data for the new week
  }

  void nextWeek() {
    if (currentWeekOffset.value < 0) {
      currentWeekOffset.value++;
      loadBloodSugarData(); // Reload data for the new week
    }
  }

  String getCurrentWeekLabel() {
    if (currentWeekOffset.value == 0) {
      return 'Minggu Ini';
    } else if (currentWeekOffset.value == -1) {
      return 'Minggu Lalu';
    } else {
      return '${currentWeekOffset.value.abs()} Minggu Lalu';
    }
  }

  // Method to refresh all data
  Future<void> refreshData() async {
    try {
      // Clear cache untuk force reload dari server
      _bloodSugarCache.clear();
      _weightCache.clear();

      // Reset all data
      uniqueDates.clear();
      listDates.clear();
      dayGlucoseSpots.clear();
      weightSpots.clear();
      beforeMealSpots.clear();
      afterMealSpots.clear();
      otherSpots.clear();
      dailyBeforeMealSpots.clear();
      dailyAfterMealSpots.clear();
      dailyOtherSpots.clear();
      dailyBars.clear();
      weeklyBars.clear();

      // Reset values
      max.value = 0.0;
      min.value = 0.0;
      average.value = '0';
      weeklyAverage.value = 0.0;
      dailyAverage.value = 0.0;
      currentWeekOffset.value = 0;
      _needsRefresh = true; // Mark for refresh

      print('🔄 Refreshing all data (cache cleared)...');

      // Reload all data
      await setupPage();
      await loadBloodSugarData();
      await loadWeightData(); // Also reload weight data
      await loadBloodSugarHistory(); // Load blood sugar history from API

      // Get current selected date or latest date
      if (listDates.isNotEmpty) {
        String currentDate = listDates[dateKeys.value];
        await getGlucoseHistory(currentDate);
      }

      _needsRefresh = false; // Reset flag after successful refresh

      Get.snackbar(
        'Berhasil',
        'Data berhasil dimuat ulang dari server',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.teal,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
        icon: const Icon(Icons.check_circle, color: Colors.white),
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Gagal memuat ulang data: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
        icon: const Icon(Icons.error, color: Colors.white),
      );
    }
  }

  // Method to calculate statistics based on active mode
  void updateStatistics() {
    List<double> currentValues = [];

    if (isWeeklyMode.value) {
      // For weekly mode, collect all values from line chart spots
      for (var spot in beforeMealSpots) {
        currentValues.add(spot.y);
      }
      for (var spot in afterMealSpots) {
        currentValues.add(spot.y);
      }
      for (var spot in otherSpots) {
        currentValues.add(spot.y);
      }
    } else {
      // For daily mode, collect all values from daily chart spots
      for (var spot in dailyBeforeMealSpots) {
        currentValues.add(spot.y);
      }
      for (var spot in dailyAfterMealSpots) {
        currentValues.add(spot.y);
      }
      for (var spot in dailyOtherSpots) {
        currentValues.add(spot.y);
      }
    }

    if (currentValues.isNotEmpty) {
      max.value = double.parse(
          currentValues.reduce((a, b) => a > b ? a : b).toStringAsFixed(2));
      min.value = double.parse(
          currentValues.reduce((a, b) => a < b ? a : b).toStringAsFixed(2));
    } else {
      max.value = 0.0;
      min.value = 0.0;
    }
  }

  // Monthly weight navigation methods
  void nextWeightMonth() {
    DateTime now = DateTime.now();
    DateTime currentMonth =
        DateTime(currentWeightMonth.value.year, currentWeightMonth.value.month);
    DateTime nextMonth = DateTime(currentMonth.year, currentMonth.month + 1);
    DateTime thisMonth = DateTime(now.year, now.month);

    // Don't allow navigation beyond current month
    if (nextMonth.isAfter(thisMonth)) {
      return;
    }

    currentWeightMonth.value = nextMonth;
    loadWeightData();
  }

  void previousWeightMonth() {
    DateTime now = DateTime.now();
    DateTime currentMonth =
        DateTime(currentWeightMonth.value.year, currentWeightMonth.value.month);
    DateTime previousMonth =
        DateTime(currentMonth.year, currentMonth.month - 1);
    DateTime januaryThisYear = DateTime(now.year, 1); // Januari tahun ini

    // Don't allow navigation beyond January of current year
    if (previousMonth.isBefore(januaryThisYear)) {
      print('Cannot go back beyond January ${now.year}');
      return;
    }

    print(
        'Navigating to previous month: ${DateFormat('yyyy-MM').format(previousMonth)}');
    currentWeightMonth.value = previousMonth;
    loadWeightData();
  }

  bool canGoNextWeightMonth() {
    DateTime now = DateTime.now();
    DateTime currentMonth =
        DateTime(currentWeightMonth.value.year, currentWeightMonth.value.month);
    DateTime nextMonth = DateTime(currentMonth.year, currentMonth.month + 1);
    DateTime thisMonth = DateTime(now.year, now.month);

    return nextMonth.isBefore(thisMonth) ||
        nextMonth.isAtSameMomentAs(thisMonth);
  }

  bool canGoPreviousWeightMonth() {
    DateTime now = DateTime.now();
    DateTime currentMonth =
        DateTime(currentWeightMonth.value.year, currentWeightMonth.value.month);
    DateTime previousMonth =
        DateTime(currentMonth.year, currentMonth.month - 1);
    DateTime januaryThisYear = DateTime(now.year, 1); // Januari tahun ini

    return previousMonth.isAfter(januaryThisYear) ||
        previousMonth.isAtSameMomentAs(januaryThisYear);
  }

  String getCurrentWeightMonthLabel() {
    try {
      return DateFormat('MMMM yyyy', 'id_ID').format(currentWeightMonth.value);
    } catch (e) {
      // Fallback to English if Indonesian locale is not available
      return DateFormat('MMMM yyyy', 'en_US').format(currentWeightMonth.value);
    }
  }

  // Get token for API calls
  Future<String> getToken() async {
    if (token.value.isEmpty) {
      if (Hive.isBoxOpen('token')) {
        var box = await Hive.openBox('token');
        if (box.isNotEmpty) {
          token.value = box.getAt(0);
        }
      }
    }
    return token.value;
  }

  // Load blood sugar history from API
  Future<void> loadBloodSugarHistory() async {
    isLoadingBloodSugarHistory.value = true;
    try {
      String monthParam =
          DateFormat('yyyy-MM').format(currentBloodSugarMonth.value);

      // Check cache first
      if (_bloodSugarCache.containsKey(monthParam)) {
        final cachedData = _bloodSugarCache[monthParam]!;
        final DateTime cachedTime = cachedData['timestamp'];

        // Check if cache is still valid (belum expired)
        if (DateTime.now().difference(cachedTime) < _cacheExpiry) {
          print(
              '📦 Using cached blood sugar data for $monthParam (cached ${DateTime.now().difference(cachedTime).inMinutes} minutes ago)');
          bloodSugarHistorySpots.value = List<FlSpot>.from(cachedData['spots']);
          bloodSugarHistoryDates.value =
              List<DateTime>.from(cachedData['dates']);
          bloodSugarHistoryRawData.value =
              List<Map<String, dynamic>>.from(cachedData['rawData']);
          bloodSugarStats.value = {
            'average': cachedData['stats']['average'],
            'min': cachedData['stats']['min'],
            'max': cachedData['stats']['max'],
            'count': cachedData['stats']['count'],
          };
          isLoadingBloodSugarHistory.value = false;
          return;
        } else {
          print('⏰ Cache expired for $monthParam, will fetch from server');
          _bloodSugarCache.remove(monthParam); // Remove expired cache
        }
      }

      String authToken = await getToken();
      if (authToken.isEmpty) {
        print('❌ Token not available for blood sugar history');
        Get.snackbar(
          'Error',
          'Token tidak tersedia. Silakan login kembali.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
          icon: const Icon(Icons.warning, color: Colors.white),
        );
        await loadBloodSugarHistoryFromLocal();
        isLoadingBloodSugarHistory.value = false;
        return;
      }

      final connect = GetConnect();
      final url =
          '${utilService.url}/api/blood-glucose/history?month=$monthParam';

      print('Loading blood sugar history from: $url');

      final response = await connect.get(
        url,
        headers: {'Authorization': 'Bearer $authToken'},
      ).timeout(const Duration(seconds: 20));

      print('Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = response.body;

        if (data != null && data['data'] != null) {
          List<dynamic> historyData = data['data'];

          // Prepare spots for different meal types
          List<FlSpot> beforeBreakfastSpots = [];
          List<FlSpot> afterBreakfastSpots = [];
          List<FlSpot> otherSpots = [];
          List<DateTime> dates = [];
          List<Map<String, dynamic>> rawDataList = [];

          // Calculate stats
          double totalAvg = 0;
          double minValue = double.infinity;
          double maxValue = 0;
          int totalCount = 0;
          int dataPointCount = 0;

          for (int i = 0; i < historyData.length; i++) {
            final entry = historyData[i];
            String dateStr = entry['date'] ?? '';
            DateTime entryDate = DateTime.parse(dateStr);
            int day = entryDate.day;

            // Process each meal type
            Map<String, dynamic>? beforeBreakfast = entry['Sebelum Sarapan'];
            Map<String, dynamic>? afterBreakfast = entry['Sesudah Sarapan'];
            Map<String, dynamic>? other = entry['Lainnya'];

            // Add before breakfast data (red)
            if (beforeBreakfast != null && beforeBreakfast['avg'] != null) {
              double avgValue = (beforeBreakfast['avg'] is int)
                  ? (beforeBreakfast['avg'] as int).toDouble()
                  : beforeBreakfast['avg'];
              beforeBreakfastSpots.add(FlSpot(day.toDouble(), avgValue));

              totalAvg += avgValue;
              dataPointCount++;

              double dayMin = (beforeBreakfast['min'] is int)
                  ? (beforeBreakfast['min'] as int).toDouble()
                  : beforeBreakfast['min'];
              double dayMax = (beforeBreakfast['max'] is int)
                  ? (beforeBreakfast['max'] as int).toDouble()
                  : beforeBreakfast['max'];
              int count = beforeBreakfast['count'] ?? 0;

              if (dayMin < minValue) minValue = dayMin;
              if (dayMax > maxValue) maxValue = dayMax;
              totalCount += count;
            }

            // Add after breakfast data (blue)
            if (afterBreakfast != null && afterBreakfast['avg'] != null) {
              double avgValue = (afterBreakfast['avg'] is int)
                  ? (afterBreakfast['avg'] as int).toDouble()
                  : afterBreakfast['avg'];
              afterBreakfastSpots.add(FlSpot(day.toDouble(), avgValue));

              totalAvg += avgValue;
              dataPointCount++;

              double dayMin = (afterBreakfast['min'] is int)
                  ? (afterBreakfast['min'] as int).toDouble()
                  : afterBreakfast['min'];
              double dayMax = (afterBreakfast['max'] is int)
                  ? (afterBreakfast['max'] as int).toDouble()
                  : afterBreakfast['max'];
              int count = afterBreakfast['count'] ?? 0;

              if (dayMin < minValue) minValue = dayMin;
              if (dayMax > maxValue) maxValue = dayMax;
              totalCount += count;
            }

            // Add other data (green) - only the latest/last measurement
            if (other != null && other['avg'] != null) {
              double avgValue = (other['avg'] is int)
                  ? (other['avg'] as int).toDouble()
                  : other['avg'];
              otherSpots.add(FlSpot(day.toDouble(), avgValue));

              totalAvg += avgValue;
              dataPointCount++;

              double dayMin = (other['min'] is int)
                  ? (other['min'] as int).toDouble()
                  : other['min'];
              double dayMax = (other['max'] is int)
                  ? (other['max'] as int).toDouble()
                  : other['max'];
              int count = other['count'] ?? 0;

              if (dayMin < minValue) minValue = dayMin;
              if (dayMax > maxValue) maxValue = dayMax;
              totalCount += count;
            }

            // Store date
            dates.add(entryDate);

            // Store raw data for tooltip
            rawDataList.add({
              'date': dateStr,
              'beforeBreakfast': beforeBreakfast,
              'afterBreakfast': afterBreakfast,
              'other': other,
            });
          }

          // Store all three meal type spots in rawData for chart access
          // Put meal type spots as first element
          List<Map<String, dynamic>> finalRawData = [
            {
              'mealTypeSpots': {
                'beforeBreakfast': beforeBreakfastSpots,
                'afterBreakfast': afterBreakfastSpots,
                'other': otherSpots,
              }
            },
            ...rawDataList,
          ];

          // Gunakan data yang ada (prioritas: before > after > other)
          // Ini fix untuk case dimana hanya ada kategori "Lainnya" saja
          List<FlSpot> primarySpots = beforeBreakfastSpots.isNotEmpty
              ? beforeBreakfastSpots
              : (afterBreakfastSpots.isNotEmpty
                  ? afterBreakfastSpots
                  : otherSpots);

          bloodSugarHistorySpots.value = primarySpots;
          bloodSugarHistoryDates.value = dates;
          bloodSugarHistoryRawData.value = finalRawData;

          // Update stats
          bloodSugarStats.value = {
            'average': dataPointCount > 0 ? totalAvg / dataPointCount : 0.0,
            'min': minValue == double.infinity ? 0.0 : minValue,
            'max': maxValue,
            'count': totalCount,
          };

          // Save to cache dengan timestamp (hanya dari server)
          _bloodSugarCache[monthParam] = {
            'spots': beforeBreakfastSpots,
            'dates': dates,
            'rawData': finalRawData,
            'stats': {
              'average': dataPointCount > 0 ? totalAvg / dataPointCount : 0.0,
              'min': minValue == double.infinity ? 0.0 : minValue,
              'max': maxValue,
              'count': totalCount,
            },
            'timestamp': DateTime.now(), // Waktu cache disimpan
          };

          print(
              '✅ Blood sugar data loaded from server: ${beforeBreakfastSpots.length} before, ${afterBreakfastSpots.length} after, ${otherSpots.length} other points');
        } else {
          print('⚠️ No blood sugar history data from server, trying local...');
          await loadBloodSugarHistoryFromLocal();
        }
      } else {
        print(
            '❌ Failed to load blood sugar history from server: ${response.statusCode}');
        Get.snackbar(
          'Info',
          'Gagal memuat data dari server. Menampilkan data lokal.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
          icon: const Icon(Icons.cloud_off, color: Colors.white),
        );
        await loadBloodSugarHistoryFromLocal();
      }
    } catch (e) {
      print('❌ Error loading blood sugar history from server: $e');
      Get.snackbar(
        'Info',
        'Tidak dapat terhubung ke server. Menampilkan data lokal.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
        icon: const Icon(Icons.cloud_off, color: Colors.white),
      );
      await loadBloodSugarHistoryFromLocal();
    }
    isLoadingBloodSugarHistory.value = false;
  }

  // Blood sugar month navigation methods
  void nextBloodSugarMonth() {
    DateTime now = DateTime.now();
    DateTime currentMonth = DateTime(
        currentBloodSugarMonth.value.year, currentBloodSugarMonth.value.month);
    DateTime nextMonth = DateTime(currentMonth.year, currentMonth.month + 1);
    DateTime thisMonth = DateTime(now.year, now.month);

    // Don't allow navigation beyond current month
    if (nextMonth.isAfter(thisMonth)) {
      return;
    }

    currentBloodSugarMonth.value = nextMonth;
    loadBloodSugarHistory();
  }

  void previousBloodSugarMonth() {
    DateTime now = DateTime.now();
    DateTime currentMonth = DateTime(
        currentBloodSugarMonth.value.year, currentBloodSugarMonth.value.month);
    DateTime previousMonth =
        DateTime(currentMonth.year, currentMonth.month - 1);
    DateTime januaryThisYear = DateTime(now.year, 1); // Januari tahun ini

    // Don't allow navigation beyond January of current year
    if (previousMonth.isBefore(januaryThisYear)) {
      print('Cannot go back beyond January ${now.year}');
      return;
    }

    print(
        'Navigating to previous month: ${DateFormat('yyyy-MM').format(previousMonth)}');
    currentBloodSugarMonth.value = previousMonth;
    loadBloodSugarHistory();
  }

  bool canGoNextBloodSugarMonth() {
    DateTime now = DateTime.now();
    DateTime currentMonth = DateTime(
        currentBloodSugarMonth.value.year, currentBloodSugarMonth.value.month);
    DateTime nextMonth = DateTime(currentMonth.year, currentMonth.month + 1);
    DateTime thisMonth = DateTime(now.year, now.month);

    return nextMonth.isBefore(thisMonth) ||
        nextMonth.isAtSameMomentAs(thisMonth);
  }

  bool canGoPreviousBloodSugarMonth() {
    DateTime now = DateTime.now();
    DateTime currentMonth = DateTime(
        currentBloodSugarMonth.value.year, currentBloodSugarMonth.value.month);
    DateTime previousMonth =
        DateTime(currentMonth.year, currentMonth.month - 1);
    DateTime januaryThisYear = DateTime(now.year, 1); // Januari tahun ini

    return previousMonth.isAfter(januaryThisYear) ||
        previousMonth.isAtSameMomentAs(januaryThisYear);
  }

  String getCurrentBloodSugarMonthLabel() {
    try {
      return DateFormat('MMMM yyyy', 'id_ID')
          .format(currentBloodSugarMonth.value);
    } catch (e) {
      // Fallback to English if Indonesian locale is not available
      return DateFormat('MMMM yyyy', 'en_US')
          .format(currentBloodSugarMonth.value);
    }
  }

  // Fallback: Load weight data from local Hive storage
  Future<void> loadWeightDataFromLocal() async {
    try {
      if (!Hive.isBoxOpen('weightData')) {
        print('Hive weightData box is not open');
        weightSpots.value = [];
        weightChange.value = '0';
        return;
      }

      var box = await Hive.openBox('weightData');
      List<dynamic> allWeightData = box.get('WeightList', defaultValue: []);

      if (allWeightData.isEmpty) {
        print('No local weight data available');
        weightSpots.value = [];
        weightChange.value = '0';
        return;
      }

      // Filter data untuk bulan yang dipilih
      DateTime selectedMonth = DateTime(
        currentWeightMonth.value.year,
        currentWeightMonth.value.month,
      );

      List<dynamic> monthData = allWeightData.where((entry) {
        DateTime entryDate = DateTime.parse(entry['date']);
        return entryDate.year == selectedMonth.year &&
            entryDate.month == selectedMonth.month;
      }).toList();

      print(
          'Found ${monthData.length} local weight entries for selected month');

      if (monthData.isEmpty) {
        weightSpots.value = [];
        weightChange.value = '0';
        return;
      }

      // Sort by date
      monthData.sort((a, b) =>
          DateTime.parse(a['date']).compareTo(DateTime.parse(b['date'])));

      // Create spots
      List<FlSpot> spots = [];
      for (var entry in monthData) {
        DateTime entryDate = DateTime.parse(entry['date']);
        int day = entryDate.day;
        double weight = (entry['weight'] is int)
            ? (entry['weight'] as int).toDouble()
            : entry['weight'];
        spots.add(FlSpot(day.toDouble(), weight));
      }

      // Calculate weight change
      if (spots.length >= 2) {
        double firstWeight = spots.first.y;
        double lastWeight = spots.last.y;
        double change = lastWeight - firstWeight;
        weightChange.value = change.toStringAsFixed(1);
      } else {
        weightChange.value = '0';
      }

      weightSpots.value = spots;

      // TIDAK save ke cache karena ini data lokal, bukan dari server
      print(
          '✅ Loaded weight data from local storage: ${spots.length} entries (fallback mode)');
    } catch (e) {
      print('Error loading weight from local storage: $e');
      weightSpots.value = [];
      weightChange.value = '0';
    }
  }

  // Fallback: Load blood sugar history from local Hive storage
  Future<void> loadBloodSugarHistoryFromLocal() async {
    try {
      if (!Hive.isBoxOpen('glucoseData')) {
        print('Hive glucoseData box is not open');
        bloodSugarHistorySpots.value = [];
        bloodSugarHistoryDates.value = [];
        bloodSugarHistoryRawData.value = [];
        bloodSugarStats.value = {
          'average': 0.0,
          'min': 0.0,
          'max': 0.0,
          'count': 0,
        };
        return;
      }

      var box = await Hive.openBox('glucoseData');
      List<dynamic> allGlucoseData = box.get('GlucoseList', defaultValue: []);

      if (allGlucoseData.isEmpty) {
        print('No local glucose data available');
        bloodSugarHistorySpots.value = [];
        bloodSugarHistoryDates.value = [];
        bloodSugarHistoryRawData.value = [];
        bloodSugarStats.value = {
          'average': 0.0,
          'min': 0.0,
          'max': 0.0,
          'count': 0,
        };
        return;
      }

      // Filter data untuk bulan yang dipilih
      DateTime selectedMonth = DateTime(
        currentBloodSugarMonth.value.year,
        currentBloodSugarMonth.value.month,
      );

      List<dynamic> monthData = allGlucoseData.where((entry) {
        DateTime entryDate = DateTime.parse(entry['date']);
        return entryDate.year == selectedMonth.year &&
            entryDate.month == selectedMonth.month;
      }).toList();

      print(
          'Found ${monthData.length} local glucose entries for selected month');

      if (monthData.isEmpty) {
        bloodSugarHistorySpots.value = [];
        bloodSugarHistoryDates.value = [];
        bloodSugarHistoryRawData.value = [];
        bloodSugarStats.value = {
          'average': 0.0,
          'min': 0.0,
          'max': 0.0,
          'count': 0,
        };
        return;
      }

      // Group by day and meal type
      Map<int, Map<String, List<double>>> dailyData = {};

      for (var entry in monthData) {
        DateTime entryDate = DateTime.parse(entry['date']);
        int day = entryDate.day;
        double glucose = (entry['blood_glucose'] is int)
            ? (entry['blood_glucose'] as int).toDouble()
            : entry['blood_glucose'];

        if (!dailyData.containsKey(day)) {
          dailyData[day] = {
            'beforeBreakfast': [],
            'afterBreakfast': [],
            'other': [],
          };
        }

        // Categorize by meal time or context
        String mealTime = (entry['meal_time'] ?? entry['context'] ?? '')
            .toString()
            .toLowerCase();

        if (mealTime.contains('sebelum') || mealTime.contains('before')) {
          dailyData[day]!['beforeBreakfast']!.add(glucose);
        } else if (mealTime.contains('setelah') ||
            mealTime.contains('sesudah') ||
            mealTime.contains('after')) {
          dailyData[day]!['afterBreakfast']!.add(glucose);
        } else {
          dailyData[day]!['other']!.add(glucose);
        }
      }

      // Calculate averages and create spots
      List<FlSpot> beforeBreakfastSpots = [];
      List<FlSpot> afterBreakfastSpots = [];
      List<FlSpot> otherSpots = [];
      List<DateTime> dates = [];
      List<Map<String, dynamic>> rawDataList = [];

      double totalAvg = 0;
      double minValue = double.infinity;
      double maxValue = 0;
      int totalCount = 0;
      int dataPointCount = 0;

      dailyData.forEach((day, mealData) {
        DateTime dayDate =
            DateTime(selectedMonth.year, selectedMonth.month, day);
        dates.add(dayDate);

        Map<String, dynamic> dayRawData = {
          'date': dayDate.toIso8601String(),
        };

        // Process before breakfast
        if (mealData['beforeBreakfast']!.isNotEmpty) {
          List<double> values = mealData['beforeBreakfast']!;
          double avg = values.reduce((a, b) => a + b) / values.length;
          double min = values.reduce((a, b) => a < b ? a : b);
          double max = values.reduce((a, b) => a > b ? a : b);

          beforeBreakfastSpots.add(FlSpot(day.toDouble(), avg));
          dayRawData['beforeBreakfast'] = {
            'avg': avg,
            'min': min,
            'max': max,
            'count': values.length,
          };

          totalAvg += avg;
          dataPointCount++;
          if (min < minValue) minValue = min;
          if (max > maxValue) maxValue = max;
          totalCount += values.length;
        }

        // Process after breakfast
        if (mealData['afterBreakfast']!.isNotEmpty) {
          List<double> values = mealData['afterBreakfast']!;
          double avg = values.reduce((a, b) => a + b) / values.length;
          double min = values.reduce((a, b) => a < b ? a : b);
          double max = values.reduce((a, b) => a > b ? a : b);

          afterBreakfastSpots.add(FlSpot(day.toDouble(), avg));
          dayRawData['afterBreakfast'] = {
            'avg': avg,
            'min': min,
            'max': max,
            'count': values.length,
          };

          totalAvg += avg;
          dataPointCount++;
          if (min < minValue) minValue = min;
          if (max > maxValue) maxValue = max;
          totalCount += values.length;
        }

        // Process other
        if (mealData['other']!.isNotEmpty) {
          List<double> values = mealData['other']!;
          double avg = values.reduce((a, b) => a + b) / values.length;
          double min = values.reduce((a, b) => a < b ? a : b);
          double max = values.reduce((a, b) => a > b ? a : b);

          otherSpots.add(FlSpot(day.toDouble(), avg));
          dayRawData['other'] = {
            'avg': avg,
            'min': min,
            'max': max,
            'count': values.length,
          };

          totalAvg += avg;
          dataPointCount++;
          if (min < minValue) minValue = min;
          if (max > maxValue) maxValue = max;
          totalCount += values.length;
        }

        rawDataList.add(dayRawData);
      });

      // Store results
      List<Map<String, dynamic>> finalRawData = [
        {
          'mealTypeSpots': {
            'beforeBreakfast': beforeBreakfastSpots,
            'afterBreakfast': afterBreakfastSpots,
            'other': otherSpots,
          }
        },
        ...rawDataList,
      ];

      // Gunakan data yang ada (prioritas: before > after > other)
      List<FlSpot> primarySpots = beforeBreakfastSpots.isNotEmpty
          ? beforeBreakfastSpots
          : (afterBreakfastSpots.isNotEmpty ? afterBreakfastSpots : otherSpots);

      bloodSugarHistorySpots.value = primarySpots;
      bloodSugarHistoryDates.value = dates;
      bloodSugarHistoryRawData.value = finalRawData;

      bloodSugarStats.value = {
        'average': dataPointCount > 0 ? totalAvg / dataPointCount : 0.0,
        'min': minValue == double.infinity ? 0.0 : minValue,
        'max': maxValue,
        'count': totalCount,
      };

      // TIDAK save ke cache karena ini data lokal, bukan dari server
      print('✅ Loaded blood sugar history from local storage (fallback mode)');
      print(
          'Data points: before=${beforeBreakfastSpots.length}, after=${afterBreakfastSpots.length}, other=${otherSpots.length}');
      print('Total readings: $totalCount');
    } catch (e) {
      print('Error loading from local storage: $e');
      bloodSugarHistorySpots.value = [];
      bloodSugarHistoryDates.value = [];
      bloodSugarHistoryRawData.value = [];
      bloodSugarStats.value = {
        'average': 0.0,
        'min': 0.0,
        'max': 0.0,
        'count': 0,
      };
    }
  }
}
