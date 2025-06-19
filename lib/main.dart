import 'package:cctv/data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';
import 'package:video_player/video_player.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with OSMMixinObserver {
  MapController controller = MapController(
    initPosition: GeoPoint(latitude: -6.9025, longitude: 107.6187),
    // initMapWithUserPosition: UserTrackingOption(
    //   enableTracking: true,
    //   unFollowUser: true,
    // ),
  );

  VideoPlayerController? videoPlayerController;

  bool isShowDetail = false;
  bool isMapLoading = true;
  Map cctvActive = {};

  @override
  void initState() {
    controller.addObserver(this);
    super.initState();
  }

  @override
  Future<void> mapIsReady(bool isReady) async {
    if (!isReady) return;
    setState(() => isMapLoading = false);

    for (var cctv in cctvs) {
      controller.addMarker(
        GeoPoint(
          latitude: double.tryParse('${cctv['lat']}') ?? 0.0,
          longitude: double.tryParse('${cctv['lng']}') ?? 0.0,
        ),
        markerIcon: MarkerIcon(icon: Icon(Icons.video_call)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              AnimatedSize(
                duration: kThemeAnimationDuration,
                child: Visibility(
                  visible: isShowDetail,
                  child: SafeArea(
                    child: Column(
                      children: [
                        SizedBox(height: 16),
                        Text('${cctvActive['cctv_name']}'),
                        SizedBox(height: 16),
                        videoPlayerController != null
                            ? SizedBox(
                                height: 200,
                                child: VideoPlayer(videoPlayerController!),
                              )
                            : SizedBox(),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: OSMFlutter(
                  controller: controller,
                  osmOption: OSMOption(
                    zoomOption: const ZoomOption(
                      initZoom: 15,
                      maxZoomLevel: 19,
                    ),
                    userLocationMarker: UserLocationMaker(
                      personMarker: const MarkerIcon(
                        icon: Icon(
                          Icons.location_history_rounded,
                          color: Colors.red,
                          size: 48,
                        ),
                      ),
                      directionArrowMarker: const MarkerIcon(
                        icon: Icon(Icons.double_arrow, size: 48),
                      ),
                    ),
                  ),
                  onGeoPointClicked: (p0) async {
                    cctvActive = cctvs.firstWhere(
                      (e) =>
                          '${p0.latitude}' == '${e['lat']}' &&
                          '${p0.longitude}' == '${e['lng']}',
                      orElse: () => {},
                    );
                    if (cctvActive.isEmpty) return;
                    print(cctvActive);

                    setState(() => isShowDetail = true);
                    videoPlayerController = VideoPlayerController.networkUrl(
                      Uri.parse('${cctvActive['stream_cctv']}'),
                    );
                    await videoPlayerController?.initialize();

                    setState(() {});
                    await Future.delayed(Duration(seconds: 1), () {});
                    videoPlayerController?.play();
                  },
                ),
              ),
            ],
          ),
          Visibility(visible: isMapLoading, child: LinearProgressIndicator()),
        ],
      ),
    );
  }
}
