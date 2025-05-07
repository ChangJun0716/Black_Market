
import 'package:black_market_app/model/create_notice.dart';
import 'package:black_market_app/model/return_investigation.dart';
import 'package:black_market_app/model/shopping_cart_from_purchase.dart';
import 'package:black_market_app/model/stock_receipts.dart';
import 'package:black_market_app/model/products.dart';
import 'package:black_market_app/model/purchase.dart';
import 'package:black_market_app/model/users.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:intl/intl.dart';
import '../model/create_approval_document.dart';
import '../model/dispatch.dart';
import '../model/store.dart';

class DatabaseHandler {
  Future<Database> initializeDB() async {
    String path = await getDatabasesPath();
    return openDatabase(
      join(path, 'blackMarket.db'),
      onCreate: (db, version) async {
        // Table: affiliation
        await db.execute(
          "CREATE TABLE affiliation(aJobGradeCode TEXT PRIMARY KEY, aUserid TEXT)",
        );
        
        // Table: createApprovalDocument (match with CreateApprovalDocument model)
        await db.execute(
          "CREATE TABLE createApprovalDocument(cuserid TEXT, cajobGradeCode TEXT, name TEXT, title TEXT, content TEXT, date TEXT, rejectedReason TEXT, approvalStatus TEXT, approvalRequestExpense INTEGER)",
        );
        
        // Table: createNotice
        await db.execute(
          "CREATE TABLE createNotice(cuserid TEXT, cajobGradeCode TEXT, title TEXT, content TEXT, date TEXT, photo BLOB)",
        );
        
        // Table: daffiliation
        await db.execute(
          "CREATE TABLE daffiliation(dstoreCode TEXT, duserId TEXT)",
        );
        
        // Table: dispatch (대리점 ID 추가됨)
        await db.execute(
          "CREATE TABLE dispatch(dUserid TEXT, daJobGradeCode TEXT, dProductCode TEXT, dispatchDate TEXT, dispatchedQuantity INTEGER, dstoreCode TEXT)",
        );
        
        // Table: grade
        await db.execute(
          "CREATE TABLE grade(jobGradeCode TEXT PRIMARY KEY, gradeName TEXT, joinDate TEXT)",
        );
        
        // Table: manufacturers (match with Manufacturers model)
        await db.execute(
          "CREATE TABLE manufacturers(manufacturerName TEXT PRIMARY KEY)",
        );
        
        // Table: orders (match with Orders model)
        await db.execute(
          "CREATE TABLE orders(orderQuantity TEXT, orderDate TEXT, orderStatus TEXT, orderPrice INTEGER, ajobGradCode TEXT, oaUserid TEXT, oproductCode TEXT, omamufacturer TEXT)",
        );
        
        // Table: productRegistration
        await db.execute(
          "CREATE TABLE productRegistration(paUserid TEXT, paJobGradeCode TEXT, pProductCode TEXT, introductionPhoto BLOB, productDescription TEXT)",
        );
        
        // Table: products (match with Products model)
        await db.execute(
          "CREATE TABLE products(productsCode TEXT PRIMARY KEY, productsColor TEXT, productsName TEXT, productsPrice INTEGER, productsSize INTEGER, productsImage blob)",
        );
        
        // Table: purchase (match with Purchase model)
        await db.execute(
          "CREATE TABLE purchase(purchaseId integer PRIMARY KEY autoincrement, purchaseDate TEXT, purchaseQuanity INTEGER, purchaseCardId INTEGER, pStoreCode TEXT, purchaseDeliveryStatus TEXT, oproductCode TEXT, purchasePrice INTEGER, pUserId Text)",
        );
        
        // Table: returnInvestigation (match with ReturnInvestigation model)
        await db.execute(
          "CREATE TABLE returnInvestigation(raUserid TEXT, raJobGradeCode TEXT, rreturnCode INTEGER, rmanufacturerName TEXT, recordDate TEXT, resolutionDetails TEXT)",
        );
        
        // Table: return (match with Return model)
        await db.execute(
          "CREATE TABLE return(returnCode INTEGER PRIMARY KEY, ruserId TEXT, rProductCode TEXT, returnReason TEXT, returnDate TEXT, returnCategory TEXT, processionStatus TEXT)",
        );
        
        // Table: stockReceipts (match with StockReceipts model)
        await db.execute(
          "CREATE TABLE stockReceipts(saUserid TEXT, saJobGradeCode TEXT, stockReceiptsQuantityReceived INTEGER, stockReceiptsReceipDate TEXT, sproductCode TEXT, smanufacturerName TEXT)",
        );
        
        // Table: store (match with Store model)
        await db.execute(
          "CREATE TABLE store(storeCode TEXT PRIMARY KEY, storeName TEXT, address TEXT, longitude REAL, latitude REAL)",
        );
        
        // Table: users (match with Users model)
        await db.execute(
          "CREATE TABLE users(userid TEXT PRIMARY KEY, password TEXT, name TEXT, phone TEXT, memberType INTEGER, birthDate TEXT, gender TEXT)",
        );
      },
      version: 1,
    );
  }


  // 로그인 함수
  Future<int> loginUsers(String id, String pw) async {
    final Database db = await initializeDB();
    final List<Map<String, Object?>> queryResult = await db.rawQuery(
      "SELECT count(*) FROM users WHERE userid = ? AND password = ?",
      [id, pw],
    );
    int count = Sqflite.firstIntValue(queryResult) ?? 0;
    return count;
  }

  // 로그인 성공 시 사용자 회원 유형 반환
  Future<int> userMemberType(String id) async {
    final Database db = await initializeDB();
    final List<Map<String, Object?>> queryResult = await db.rawQuery(
      "SELECT memberType FROM users WHERE userid = ?",
      [id],
    );
    int count = Sqflite.firstIntValue(queryResult) ?? 0;
    return count;
  }

  // ID 중복 체크
  Future<int> idDoubleCheck(String id) async {
    final Database db = await initializeDB();
    final List<Map<String, Object?>> queryResult = await db.rawQuery(
      "SELECT count(*) FROM users WHERE userid = ?",
      [id],
    );
    int count = Sqflite.firstIntValue(queryResult) ?? 0;
    return count;
  }

  // 사용자 정보 입력
  Future<int> insertUserInfo(Users account) async {
    int result = 0;
    final Database db = await initializeDB();
    result = await db.rawInsert(

      "INSERT INTO users (userid, password, name, birthDate, gender, phone, memberType) VALUES (?, ?, ?, ?, ?, ?, ?)",
      [
        account.userid,
        account.password,
        account.name,
        account.birthDate,
        account.gender,
        account.phone,
        account.memberType,
      ],
    );
    return result;
  }


   // 제조사 목록 로딩
  Future<List<String>> getManufacturers() async {
    final db = await initializeDB();
    final result = await db.rawQuery("SELECT DISTINCT manufacturerName FROM manufacturers");
    return result.map((e) => e['manufacturerName'].toString()).toList();
  }
  Future<List<String>> getStores() async {
    final db = await initializeDB();
    final result = await db.rawQuery("SELECT storeName FROM store");
    return result.map((e) => e['storeName'].toString()).toList();
  }
 Future<List<Map<String, dynamic>>> getAllProducts() async {
    final db = await initializeDB();
    return await db.rawQuery("SELECT * FROM products");
  }
  Future<int> getTotalReceived(String productCode) async {
    final db = await initializeDB();
    return Sqflite.firstIntValue(await db.rawQuery(
          "SELECT SUM(stockReceiptsQuantityReceived) FROM stockReceipts WHERE sproductCode = ?",
          [productCode],
        )) ?? 0;
  }
  // 해당 제품의 총 출고량
  Future<int> getTotalDispatched(String productCode) async {
    final db = await initializeDB();
    return Sqflite.firstIntValue(await db.rawQuery(
          "SELECT SUM(dispatchedQuantity) FROM dispatch WHERE dProductCode = ?",
          [productCode],
        )) ?? 0;
  }
  // 특정 제조사명 조회 (최신 입고 기준)
  Future<String> getManufacturerByProduct(String productCode) async {
    final db = await initializeDB();
    final result = await db.rawQuery(
      "SELECT smanufacturerName FROM stockReceipts WHERE sproductCode = ? ORDER BY stockReceiptsReceipDate DESC LIMIT 1",
      [productCode],
    );
    return result.isNotEmpty ? result.first['smanufacturerName'].toString() : '없음';
  }
  // 특정 제품의 마지막 발주 정보
  Future<Map<String, dynamic>?> getLatestOrder(String productCode) async {
    final db = await initializeDB();
    final result = await db.rawQuery(
      "SELECT * FROM order WHERE oproductCode = ? ORDER BY orderDate DESC LIMIT 1",
      [productCode],
    );
    return result.isNotEmpty ? result.first : null;
  }
   // 특정 제품이 발주 이후 입고된 적 있는지 확인
  Future<bool> isReceivedAfterOrder(String productCode, String orderDate) async {
    final db = await initializeDB();
    final result = await db.rawQuery(
      "SELECT * FROM stockReceipts WHERE sproductCode = ? AND stockReceiptsReceipDate > ?",
      [productCode, orderDate],
    );
    return result.isNotEmpty;
  }
   // 대리점 코드로부터 재고량 계산 (출고 - 판매)
  Future<int> getStoreStock(String productCode, String? storeCode) async {
    final db = await initializeDB();

    final dispatched = Sqflite.firstIntValue(await db.rawQuery(
          "SELECT SUM(dispatchedQuantity) FROM dispatch d JOIN daffiliation a ON d.dUserid = a.duserId WHERE dProductCode = ? ${storeCode != null ? "AND a.dstoreCode = '$storeCode'" : ''}",
          [productCode],
        )) ?? 0;

    final sold = Sqflite.firstIntValue(await db.rawQuery(
          "SELECT SUM(purchaseQuanity) FROM purchase WHERE oproductCode = ? ${storeCode != null ? "AND pStoreCode = '$storeCode'" : ''}",
          [productCode],
        )) ?? 0;

    return dispatched - sold;
  }
  
  // 대리점 코드 얻기
  Future<String?> getStoreCodeByName(String storeName) async {
    final db = await initializeDB();
    final result = await db.rawQuery(
      "SELECT storeCode FROM store WHERE storeName = ?",
      [storeName],
    );
    return result.isNotEmpty ? result.first['storeCode'].toString() : null;
  }
  //발주 내용 입력하기
  Future<int> insertCreateApprovalDocument(CreateApprovalDocument doc) async {
  final db = await initializeDB();
  return await db.rawInsert(
    '''
    INSERT INTO createApprovalDocument(
      cuserid, cajobGradeCode, name, title, content, date, 
      rejectedReason, approvalStatus, approvalRequestExpense
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
    ''',
    [
      doc.cUserid,
      doc.cajobGradeCode,
      doc.name,
      doc.title,
      doc.content,
      doc.date.toIso8601String(),
      doc.rejectedReason,
      doc.approvalStatus,
      doc.approvalRequestExpense,
    ],
  );
}
//발주내역 등록하기
Future<int> insertOrder({
  required int quantity,
  required String date,
  required String status,
  required int price,
  required String jobGradeCode,
  required String userId,
  required String productCode,
  required String manufacturer,
}) async {
  final db = await initializeDB();
  return await db.rawInsert(
    '''
    INSERT INTO order (
      orderQuantity, orderDate, orderStatus, orderPrice, 
      ajobGradCode, oaUserid, oproductCode, omamufacturer
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    ''',
    [
      quantity.toString(),
      date,
      status,
      price,
      jobGradeCode,
      userId,
      productCode,
      manufacturer,
    ],
  );
}
//결재서 검색
Future<List<Map<String, dynamic>>> loadFilteredApprovals({
  required String status,
  DateTime? start,
  DateTime? end,
}) async {
  final db = await initializeDB();
  String query = "SELECT * FROM createApprovalDocument";
  List<String> whereClauses = [];
  List<dynamic> args = [];

  if (status != '전체') {
    whereClauses.add("approvalStatus = ?");
    args.add(status);
  }

  if (start != null && end != null) {
    whereClauses.add("date BETWEEN ? AND ?");
    args.add(DateFormat('yyyy-MM-dd').format(start));
    args.add(DateFormat('yyyy-MM-dd').format(end));
  }

  if (whereClauses.isNotEmpty) {
    query += " WHERE " + whereClauses.join(" AND ");
  }

  query += " ORDER BY date DESC";
  return await db.rawQuery(query, args);
}
// 결재 승인 처리
Future<void> updateApprovalStatus({
  required String userId,
  required String date,
  required String status,
}) async {
  final db = await initializeDB();
  await db.rawUpdate(
    '''
    UPDATE createApprovalDocument 
    SET approvalStatus = ? 
    WHERE cuserid = ? AND date = ?
    ''',
    [status, userId, date],
  );
}

// 결재 반려 처리 
Future<void> rejectApproval({
  required String userId,
  required String date,
  required String reason,
}) async {
  final db = await initializeDB();
  await db.rawUpdate(
    '''
    UPDATE createApprovalDocument 
    SET approvalStatus = '반려됨', rejectedReason = ? 
    WHERE cuserid = ? AND date = ?
    ''',
    [reason, userId, date],
  );
}

//입고 넣기 
Future<int> insertStockReceipt(StockReceipts receipt) async {
  final db = await initializeDB();
  return await db.rawInsert(
    '''
    INSERT INTO stockReceipts(
      saUserid,
      saJobGradeCode,
      stockReceiptsQuantityReceived,
      stockReceiptsReceipDate,
      sproductCode,
      smanufacturerName
    ) VALUES (?, ?, ?, ?, ?, ?)
    ''',
    [
      receipt.saUserid,
      receipt.saJobGradeCode,
      receipt.stockReceiptsQuantityReceived,
      receipt.stockReceiptsReceipDate.toIso8601String(), // <- 여기만 변환 필요
      receipt.sproductCode,
      receipt.smanufacturerName,
    ],
  );
}


//입고 되었을 때 발주 상태를 업그레이드 해주는 쿼리문
Future<void> updateOrderStateToEmpty(String productCode) async {
  final db = await initializeDB();
  await db.rawUpdate(
    '''
    UPDATE orders
    SET orderState = ''
    WHERE productCode = ?
    ''',
    [productCode],
  );
}
//대리점 불러올 때 쿼리문 
Future<List<Store>> getStoreList() async {
  final db = await initializeDB();
  final List<Map<String, dynamic>> maps = await db.query('store');
  return maps.map((e) => Store.fromMap(e)).toList();
}



//출고할 때 쿼리문 
Future<int> insertDispatch(Dispatch dispatch) async {
  final db = await initializeDB();
  return await db.rawInsert(
    '''
    INSERT INTO dispatch(
      dUserid,
      daJobGradeCode,
      dProductCode,
      dispatchDate,
      dispatchedQuantity,
      dstoreCode
    ) VALUES (?, ?, ?, ?, ?, ?)
    ''',
    [
      dispatch.dUserid,
      dispatch.daJobGradeCode,
      dispatch.dProductCode,
      dispatch.dispatchDate.toIso8601String(),
      dispatch.dispatchedQuantity,
      dispatch.dstoreCode,
    ],
  );
}
//출고 하고 본새 재고 업데이트 

Future<void> updateStock(String productCode, int newStock) async {
  final db = await initializeDB();
  await db.rawUpdate(
    '''
    UPDATE products
    SET currentStock = ?
    WHERE productsCode = ?
    ''',
    [newStock, productCode],
  );
}

// 본사에서 구매 해당 상품을 출고 했을 때 배송 상태 업데이트 하는 쿼리문 
Future<void> updatePurchaseDeliveryStatus(String productCode, String storeCode) async {
  final db = await initializeDB();
  await db.rawUpdate(
    '''
    UPDATE Purchase
    SET purchaseDeliveryStatus = '본사배송시작'
    WHERE oproductcode = ? AND pStoreCode = ?
    ''',
    [productCode, storeCode],
  );
}



//입출고 재고 리스트 불러오기 
Future<List<Map<String, dynamic>>> getCompanyStockList() async {
  final db = await initializeDB();
  final result = await db.rawQuery('''
    SELECT 
      p.productsCode,
      p.productsName,
      p.productsColor,
      p.productsSize,
      p.productsPrice,
      (
        SELECT smanufacturerName 
        FROM stockReceipts 
        WHERE sproductCode = p.productsCode 
        ORDER BY stockReceiptsReceipDate DESC 
        LIMIT 1
      ) AS manufacturerName,
      (
        SELECT IFNULL(SUM(stockReceiptsQuantityReceived), 0) 
        FROM stockReceipts 
        WHERE sproductCode = p.productsCode
      ) AS totalReceived,
      (
        SELECT IFNULL(SUM(dispatchedQuantity), 0) 
        FROM dispatch 
        WHERE dProductCode = p.productsCode
      ) AS totalDispatched
    FROM products p
  ''');

  for (var row in result) {
    final received = row['totalReceived'] as int? ?? 0;
    final dispatched = row['totalDispatched'] as int? ?? 0;
    row['currentStock'] = received - dispatched;
  }

  return result;
}

// 반품 리스트 필터링
Future<List<Map<String, dynamic>>> loadFilteredReturns({
  required String status,
  DateTime? start,
  DateTime? end,
}) async {
  final db = await initializeDB();
  String query = "SELECT * FROM return";
  List<String> whereClauses = [];
  List<dynamic> args = [];

  if (status != '전체') {
    whereClauses.add("prosessionStateus = ?");
    args.add(status);
  }

  if (start != null && end != null) {
    whereClauses.add("returnDate BETWEEN ? AND ?");
    args.add(DateFormat('yyyy-MM-dd').format(start));
    args.add(DateFormat('yyyy-MM-dd').format(end));
  }

  if (whereClauses.isNotEmpty) {
    query += " WHERE " + whereClauses.join(" AND ");
  }

  query += " ORDER BY returnDate DESC";
  return await db.rawQuery(query, args);
}

//반품 내용에 해결 되는 내용을 넣을

Future<int> insertReturnInvestigation(ReturnInvestigation ri) async {
  final db = await initializeDB();
  return await db.rawInsert(
    '''
    INSERT INTO returnInvestigation (
      raUserid, raJobGradeCode, rreturnCode, rmanufacturerName, 
      recordDate, resolutionDetails
    ) VALUES (?, ?, ?, ?, ?, ?)
    ''',
    [
      ri.raUserid,
      ri.raJobGradeCode,
      ri.rreturnCode,
      ri.rmanufacturerName,
      ri.recordDate.toIso8601String(),
      ri.resolutionDetails,
    ],
  );
}
//원인규명의 내용을 저장하고 수정할 수 있는 쿼리문 
Future<int> saveReturnInvestigation(ReturnInvestigation record) async {
  final db = await initializeDB();
  return await db.rawInsert(
    '''
    INSERT INTO returnInvestigation (
      raUserid,
      raJobGradeCode,
      rreturnCode,
      rmanufacturerName,
      recordDate,
      resolutionDetails
    ) VALUES (?, ?, ?, ?, ?, ?)
    ''',
    [
      record.raUserid,
      record.raJobGradeCode,
      record.rreturnCode,
      record.rmanufacturerName,
      record.recordDate.toIso8601String(),
      record.resolutionDetails,
    ],
  );
}
//원인규명 상태 변경 쿼리문 
Future<void> updateReturnStatus({
  required int returnCode,
  required String newStatus,
}) async {
  final db = await initializeDB();
  await db.rawUpdate(
    '''
    UPDATE return
    SET prosessionStateus = ?
    WHERE returnCode = ?
    ''',
    [newStatus, returnCode],
  );
}





  // ------------------Product----------------------- //
  // customer_product_list.dart : product list (query)
  Future<List<Products>> queryGroupedProducts() async {
    final Database db = await initializeDB();
    final List<Map<String, Object?>> queryResult = await db.rawQuery('''
    SELECT * FROM products 
    WHERE productsCode IN (
      SELECT MIN(productsCode)
      FROM products
      GROUP BY productsName
    )
    ORDER BY productsName
  ''');
    return queryResult.map((e) => Products.formMap(e)).toList();
  }
  // ------------------------------------------------ //
Future<List<Map<String, dynamic>>> queryProductDetails(String productName) async {
  final Database db = await initializeDB();

  final result = await db.rawQuery('''
    SELECT 
      p.productsCode,
      p.productsColor,
      p.productsName,
      p.productsPrice,
      p.productsSize,
      p.productsImage,
      r.introductionPhoto,
      r.productDescription
    FROM products p
    LEFT JOIN productRegistration r
    ON p.productsCode = r.pProductCode
    WHERE p.productsName = ?
  ''', [productName]);

  return result;
}

  // --------------------Purchase---------------------- //
  Future<int> addShopingCart(Purchase purchase)async{
    int result = 0;
    final Database db = await initializeDB();
    result = await db.rawInsert(
      "insert into purchase(pStoreCode,  oproductCode, purchaseQuantity, purchaseDate, purchasePrice, purchaseDeliverystatus, purchaseCartId) values (?,?,?,?,?,?)",
      [purchase.pStoreCode ,purchase.oproductCode, purchase.purchaseQuanity, purchase.purchaseDate, purchase.purchasePrice, purchase.purchaseDeliveryStatus, purchase.purchaseCardId]
    );
    return result;
  }
  // ------------------------------------------------ //
// query : announcement (notice)
  Future<List<CreateNotice>> queryAnnouncment()async{
    final Database db = await initializeDB();
    final List<Map<String, Object?>> queryResult = await db.rawQuery(
      "select * from createNotice "
    );
    return queryResult.map((e) => CreateNotice.fromMap(e)).toList();
  }
  // ------------------------------------------------ //
// query shopping Cart
  Future<List<shoppingCart>> queryShoppingCart(String pUserId)async{
    final Database db = await initializeDB();
    final List<Map<String, Object?>> queryResult = await db.rawQuery(
      "SELECT pr.productsName, pr.productsImage, p.purchaseQuantity FROM purchase p INNER JOIN products pr ON p.oproductCode = pr.productsCode WHERE p.pUserId = ? and pr.purchaseDeliveryStatus = '장바구니'",
      [pUserId]
    );
    return queryResult.map((e) => shoppingCart.fromMap(e)).toList();
  }
  // ------------------------------------------------ //
// query store
  Future<List<Store>> queryStore()async{
    final Database db = await initializeDB();
    final List<Map<String, Object?>> queryResult = await db.rawQuery(
      "select * from store"
    );
    return queryResult.map((e) => Store.fromMap(e)).toList();
  }
  // ------------------------------------------------ //
}// class