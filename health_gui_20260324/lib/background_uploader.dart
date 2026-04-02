import 'dart:io';
import 'dart:convert';
import 'dart:ui';
import 'package:dio/dio.dart';
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
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
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

    List<dynamic> rawFiles = event['files'];
    List<Map<String, dynamic>> files = rawFiles.cast<Map<String, dynamic>>();

    String userId = event['userId'];
    String pos = event['pos'];
    String fit = event['fit'];
    String training = event['training'];
    String location = event['location'];
    String remarks = event['remarks'];

    if (service is AndroidServiceInstance) {
      service.setAsForegroundService();
      flutterLocalNotificationsPlugin.show(
        id: 888,
        title: '업로드 진행 중',
        body: '파일 업로드를 시작합니다 (0%)',
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails('upload_channel', 'Background Uploads', ongoing: true, icon: '@mipmap/ic_launcher'),
        ),
      );
    }

    try {
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
        'session_id': sessionId,
        'user_id': userId,
        'pos': pos,
        'fit': fit,
        'training': training,
        'location': location,
        'remarks': remarks,
        'total_chunks_map': jsonEncode(chunksMap),
      });

      await dio.post(
        'https://health-port.work/upload/complete',
        data: completeFormData,
      );

      service.invoke('uploadComplete', {'success': true});
      if (service is AndroidServiceInstance) {
         flutterLocalNotificationsPlugin.show(
           id: 888, title: '업로드 성공!', body: '백그라운드 파일 전송이 성공적으로 완료되었습니다.',
           notificationDetails: const NotificationDetails(android: AndroidNotificationDetails('upload_channel', 'Background Uploads', ongoing: false, icon: '@mipmap/ic_launcher')),
         );
         service.setAsBackgroundService();
      }
      
    } catch (e) {
      service.invoke('uploadComplete', {'success': false, 'error': e.toString()});
      if (service is AndroidServiceInstance) {
         flutterLocalNotificationsPlugin.show(
           id: 888, title: '업로드 실패', body: '오류 발생: $e',
           notificationDetails: const NotificationDetails(android: AndroidNotificationDetails('upload_channel', 'Background Uploads', ongoing: false, icon: '@mipmap/ic_launcher')),
         );
         service.setAsBackgroundService();
      }
    }
  });
}
