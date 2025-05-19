import 'dart:convert';
import 'package:black_market_app/global.dart';
import 'package:black_market_app/message/custom_dialogue.dart';
import 'package:black_market_app/model/store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:latlong2/latlong.dart' as latlng;
import 'package:http/http.dart' as http;

class CustomerSelectStore extends StatefulWidget {
  const CustomerSelectStore({super.key});

  @override
  State<CustomerSelectStore> createState() => _UserMapState();
}

class _UserMapState extends State<CustomerSelectStore> {
// ------------------------------- Property ------------------------------------- //
  late Position currentPosition; // 숫자로 된 (암호화 된) 위치 정보     // geo
  late int kindChoice; // 앱바의 버튼 순서
  late double latData; // 위도 데이터
  late double longData; // 경도 데이터
  late MapController mapController; // 맵을 컨트롤 해주는 변수 // flutter map package
  late bool canRun; // Gps 신호를 받을지 말지 -> 받지 않으면 지도가 멈춘다.
  late List location; // 앱바의 버튼 표시
  final box = GetStorage();
  late String uid;
  List<Store> storeList = [];
  List data = [];

  // Segment Widget
  Map<int, Widget> segmentWidgets = {
    0: SizedBox(
      child: Text(
        '전체',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 12),
      ),
    ),
  };
// ------------------------------------------------------------------------------ //
  @override
  void initState() {
    super.initState();
    kindChoice = 0;
    mapController = MapController();
    canRun = false;
    checkLocationPermission();
    initStorage();
    getJSONData();
  }
// ------------------------------------------------------------------------------ //
// ------------------------------- Functions ------------------------------------ //
// 사용자가 로그인에 성공 할 경우 해당 userId 를 각 페이지에서 불러오는 함수
  initStorage() {
    uid = box.read('uid');
  }
// ------------------------------------------------------------------------------ //
// 전체 대리점의 data 를 불러오는 함수
getJSONData()async{
var response = await http.get(Uri.parse("http://$globalip:8000/changjun/select/store"));
  data.clear();
  data.addAll(json.decode(utf8.decode(response.bodyBytes))['results']);
  // print(data); // --- 1
  setState(() {});
}
// ------------------------------------------------------------------------------ //
  checkLocationPermission() async {
      // print('checkLocationPermission 실행');
    // async 로 해줘야 한다!
    LocationPermission permission = await Geolocator.checkPermission();
      // print('현재 permission 상태: $permission');
    if (permission == LocationPermission.denied) {
          // print('재요청 후 permission 상태: $permission');
      permission = await Geolocator.requestPermission(); // 한번 더 해준다!
    }
    if (permission == LocationPermission.deniedForever) {
      // print('권한이 영구적으로 거부됨');
      return;
    }
    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
        // print('getCurrentLocation 호출됨');
      getCurrentLocation();
    }
    // print("Permission: $permission");
  }
// ------------------------------------------------------------------------------ //
// 사용자의 현재 위치를 불러오는 함수
  getCurrentLocation() async {
    // async 로 만들어준다!
    Position position = await Geolocator.getCurrentPosition();
      // print('현재 위치 받음: ${position.latitude}, ${position.longitude}');
    currentPosition = position;
    canRun = true;
    latData = currentPosition.latitude;
    longData = currentPosition.longitude;
    setState(() {});
  }
// ------------------------------------------------------------------------------ //
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('대리점 선택'),
      ),
      body: canRun ? flutterMap() : Center(child: CircularProgressIndicator()),
    );
  } // build
// -------------------------------- Widgets ------------------------------------- //
  Widget flutterMap() {
    return FlutterMap(
      mapController: mapController,
      options: MapOptions(
        initialCenter: latlng.LatLng(latData, longData),
        initialZoom: 17.0,
      ),
      children: [
        TileLayer(
          urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
        ),
        MarkerLayer(
          markers: [
            Marker(
              width: 80,
              height: 80,
              point: latlng.LatLng(latData, longData),
              child: Column(
                children: [
                  Text(
                    "내 위치",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                      color: Colors.blue,
                    ),
                  ),
                  Icon(Icons.pin_drop, color: Colors.blue),
                ],
              ),
            ),
              ...data.where((res) => res["latitude"] != 0 && res["longitude"] != 0).map(
                (res) => Marker(
                  width: 80,
                  height: 80,
                  point: latlng.LatLng(res["latitude"], res["longitude"]),
                  child: GestureDetector(
                    onTap: () {
                      selectStore(res['storeName'], res['storeCode']);
                      // print(res['storeName']);
                      // print(res['storeCode']);
                    },
                    child: Column(
                      children: [
                        Text(
                          res['storeName'],
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                        Icon(Icons.location_on, color: Colors.red),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
// ------------------------------------------------------------------------------ //
// ----------------------------- Functions -------------------------------------- //
// marker ontap 하였을 경우
  selectStore(String storeName, int storeCode){
    CustomDialogue().showDialogue(
      title: '대리점 선택', 
      middleText: 
      '''
      선택하신 대리점은 $storeName 입니다. 
      이 지점을 픽업 지점으로 지정 하시겠습니까?
      ''',
      cancelText: '취소',
      onCancel: () => Get.back(),
      confirmText: '선택하기',
      onConfirm: () {
        // print(storeCode);
        Get.back(result: storeCode);
      },
    );
  }
// ------------------------------------------------------------------------------ //
}// class