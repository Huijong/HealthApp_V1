import 'dart:io';
import 'dart:convert';
import 'dart:ui';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'upload_channel',
    'Background Uploads',
    description: 'Notifications for background file uploads',
    importance: Importance.low,
  );

  await flutterLocalNotificationsPlugin.initialize(
    settings: const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/launcher_icon'),
    ),
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  service.on('stopService').listen((event) {
    service.stopSelf();
  });

  service.on('startUpload').listen((event) async {
    if (event == null) return;

    try {
      List<dynamic> rawFiles = event['files'];
      
      // 강력한 타입 캐스팅 우회 (Type Cast Error 방지)
      List<Map<String, dynamic>> files = [];
      for (var element in rawFiles) {
         files.add(Map<String, dynamic>.from(element as Map));
      }

      String? userId = event['userId'];
      String? pos = event['pos'];
      String? fit = event['fit'];
      String? training = event['training'];
      String? watchModel = event['watchModel'];
      String? strap = event['strap'];
      String? activityName = event['activityName'];
      String? location = event['location'];
      String? remarks = event['remarks'];

      if (service is AndroidServiceInstance) {
        service.setAsForegroundService();
        await flutterLocalNotificationsPlugin.show(
          id: 888,
          title: '업로드 진행 중',
          body: '파일 업로드를 시작합니다 (0%)',
          notificationDetails: const NotificationDetails(
            android: AndroidNotificationDetails('upload_channel', 'Background Uploads', ongoing: true, icon: '@mipmap/launcher_icon'),
          ),
        );
      }

      final dio = Dio();
      dio.options.headers['x-api-key'] = 'my_private_key_50';
      dio.options.connectTimeout = const Duration(minutes: 5);
      dio.options.receiveTimeout = const Duration(minutes: 30);
      dio.options.sendTimeout = const Duration(minutes: 30);

      int totalBytes = files.fold(0, (sum, f) => sum + (f['size'] as int));
      int bytesAlreadyUploaded = 0;

      String sessionId = DateTime.now().millisecondsSinceEpoch.toString();
      Map<String, int> chunksMap = {};
      int chunkSize = 30 * 1024 * 1024; // 30 MB chunks

      for (var f in files) {
        String path = f['path'];
        String name = f['name'];
        File file = File(path);
        int fileLength = await file.length();
        
        int chunksCount = (fileLength / chunkSize).ceil();
        if (chunksCount == 0) chunksCount = 1; 
        chunksMap[name] = chunksCount;

        RandomAccessFile raf = await file.open(mode: FileMode.read);
        
        for (int i = 0; i < chunksCount; i++) {
          int bytesToRead = (i == chunksCount - 1) ? fileLength - (i * chunkSize) : chunkSize;
          List<int> chunkBytes = await raf.read(bytesToRead);
          
          var formData = FormData.fromMap({
            'session_id': sessionId,
            'filename': name,
            'chunk_index': i,
            'chunk': MultipartFile.fromBytes(chunkBytes, filename: '$name.part$i'),
          });
          
          await dio.post(
            'https://health-port.work/upload/chunk',
            data: formData,
            onSendProgress: (sent, total) {
              if (total > 0) {
                double chunkProgress = sent / total;
                double overallProgress = (bytesAlreadyUploaded + (bytesToRead * chunkProgress)) / totalBytes;

                service.invoke('uploadProgress', {'progress': overallProgress});
                
                if (service is AndroidServiceInstance) {
                   int percentage = (overallProgress * 100).floor();
                   service.setForegroundNotificationInfo(
                     title: "파일 업로드 진행 중",
                     content: "$percentage% 완료 (백그라운드)",
                   );
                }
              }
            },
          );
          bytesAlreadyUploaded += bytesToRead;
        }
        await raf.close();
      }

      var completeFormData = FormData.fromMap({
        'session_id': sessionId.toString(),
        'user_id': (userId ?? 'Unknown').toString(),
        'activity_name': (activityName ?? 'Unknown').toString(),
        'watch_model': (watchModel ?? 'Unknown').toString(),
        'strap': (strap ?? 'Unknown').toString(),
        'pos': (pos == null || pos.isEmpty) ? ' ' : pos.toString(),
        'fit': (fit == null || fit.isEmpty) ? ' ' : fit.toString(),
        'training': (training == null || training.isEmpty) ? ' ' : training.toString(),
        'location': (location == null || location.isEmpty) ? ' ' : location.toString(),
        'remarks': (remarks == null || remarks.isEmpty) ? ' ' : remarks.toString(),
        'total_chunks_map': jsonEncode(chunksMap).toString(),
      });

      await dio.post(
        'https://health-port.work/upload/complete',
        data: completeFormData,
      );

      // 로컬 히스토리에 기록 저장
      try {
        final prefs = await SharedPreferences.getInstance();
        String historyStr = prefs.getString('upload_history') ?? '[]';
        List<dynamic> historyList = jsonDecode(historyStr);

        final now = DateTime.now();
        String dateStr = "${now.year}.${now.month.toString().padLeft(2, '0')}.${now.day.toString().padLeft(2, '0')} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
        String sizeStr = (totalBytes / (1024 * 1024)).toStringAsFixed(1) + ' MB';

        Map<String, dynamic> newHistory = {
          'id': sessionId,
          'activityName': activityName ?? 'Unknown',
          'type': 'Success',
          'date': dateStr,
          'tags': [training ?? ' ', watchModel ?? ' ', strap ?? ' ', pos ?? ' ', fit ?? ' '],
          'durationStr': 'Uploaded successfully',
          'fileSize': sizeStr,
          'isSuccess': true,
        };
        
        historyList.add(newHistory);
        await prefs.setString('upload_history', jsonEncode(historyList));
      } catch (e) {
        // SharedPreferences 저장 실패 무시
      }

      service.invoke('uploadComplete', {'success': true});
      if (service is AndroidServiceInstance) {
         await flutterLocalNotificationsPlugin.show(
           id: 888, title: '업로드 성공!', body: '백그라운드 파일 전송이 성공적으로 완료되었습니다.',
           notificationDetails: const NotificationDetails(android: AndroidNotificationDetails('upload_channel', 'Background Uploads', ongoing: false, icon: '@mipmap/launcher_icon')),
         );
         service.setAsBackgroundService();
      }
      
    } catch (e, stack) {
      String errMsg = e.toString();
      if (e is DioException) {
         errMsg = "Dio응답 오류 ${e.response?.statusCode}: ${e.response?.data}";
      } else {
         errMsg = "백그라운드 에러: $e\n$stack";
      }
      service.invoke('uploadComplete', {
        'success': false,
        'error': errMsg, // Changed 'message' to 'error' to match flutter screen listener!
      });
      if (service is AndroidServiceInstance) {
         await flutterLocalNotificationsPlugin.show(
           id: 888, title: '업로드 실패', body: '오류 발생, 앱에서 확인해주세요.',
           notificationDetails: const NotificationDetails(android: AndroidNotificationDetails('upload_channel', 'Background Uploads', ongoing: false, icon: '@mipmap/launcher_icon')),
         );
         service.setAsBackgroundService();
      }
    }
  });
}
