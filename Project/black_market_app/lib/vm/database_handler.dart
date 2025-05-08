import 'dart:convert';

import 'package:black_market_app/model/product_registration.dart';
import 'package:black_market_app/model/products.dart';
import 'package:black_market_app/model/return_investigation.dart';
import 'package:black_market_app/model/stock_receipts.dart';
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
        "CREATE TABLE productRegistration(paUserid TEXT, paJobGradeCode TEXT, pProductCode TEXT, introductionPhoto BLOB, ptitle TEXT, contentJson TEXT)"
      );



        
        // Table: products (match with Products model)
        await db.execute(
          "CREATE TABLE IF NOT EXISTS Products(productsCode INTEGER PRIMARY KEY AUTOINCREMENT,productsColor TEXT,productsName TEXT,productsPrice INTEGER,productsSize INTEGER,productsImage BLOB)",
        );
        
        // Table: purchase (match with Purchase model)
        await db.execute(
          "CREATE TABLE purchase(purchaseId TEXT PRIMARY KEY, purchaseDate TEXT, purchaseQuanity INTEGER, purchaseCardId INTEGER, pStoreCode TEXT, purchaseDeliveryStatus TEXT, oproductCode TEXT, purchasePrice INTEGER)",
        );
        
        // Table: returnInvestigation (match with ReturnInvestigation model)
        await db.execute(
        "CREATE TABLE returnInvestigation(raUserid TEXT, raJobGradeCode TEXT, rreturnCode INTEGER, rmanufacturerName TEXT, recordDate TEXT, resolutionDetails TEXT)"
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
//제품 등록 메소드 
Future<int> insertProduct(Products product) async {
  final db = await initializeDB();
  return await db.insert(
    'Products',
    {
      'productsColor': product.productsColor,
      'productsName': product.productsName,
      'productsPrice': product.productsPrice,
      'productsSize': product.productsSize,
      'productsImage': product.productsImage,
    },
    conflictAlgorithm: ConflictAlgorithm.replace,
  );
}

//제품 조회 
Future<List<Products>> getAllProducts1() async {
  final db = await initializeDB();
  final List<Map<String, dynamic>> result = await db.query('products');
  return result.map((item) => Products.fromMap(item)).toList();
}

//게시글 조회
Future<List<ProductRegistration>> getAllProductPosts() async {
  final db = await initializeDB();
  final result = await db.query('productRegistration');
  return result.map((e) => ProductRegistration.fromMap(e)).toList();
}
//개시글 등록
 Future<int> insertProductRegistration(ProductRegistration post) async {
    final db = await initializeDB();
    return await db.insert(
      'productRegistration',
      {
        'paUserid': post.paUserid,
        'pProductCode': post.pProductCode,
        'introductionPhoto': post.introductionPhoto,
        'ptitle': post.ptitle,
        'contentJson': jsonEncode(post.contentBlocks.map((e) => e.toMap()).toList()),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
  //같은 제품의 게시글이 올라가 있는지 확인 
  Future<ProductRegistration?> getProductRegistrationByProductCode(String productCode) async {
  final db = await initializeDB();
  final result = await db.query(
    'productRegistration',
    where: 'pProductCode = ?',
    whereArgs: [productCode],
  );

  if (result.isNotEmpty) {
    return ProductRegistration.fromMap(result.first);
  } else {
    return null;
  }
}
//제품 이름으로 검색 
Future<List<String>> getDistinctProductNames() async {
  final db = await initializeDB();
  final result = await db.rawQuery(
    'SELECT DISTINCT productsName FROM products ORDER BY productsName'
  );
  return result.map((e) => e['productsName'].toString()).toList();
}

//재품 이름 함수 2
Future<List<Products>> getProductsByName(String name) async {
  final db = await initializeDB();
  final List<Map<String, dynamic>> result = await db.query(
    'products',
    where: 'productsName = ?',
    whereArgs: [name],
  );
  return result.map((item) => Products.fromMap(item)).toList();
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
    return queryResult.map((e) => Products.fromMap(e)).toList();
  }

  // ------------------------------------------------ //
  Future<List<Map<String, dynamic>>> queryProductDetails(
    String productName,
  ) async {
    final Database db = await initializeDB();

    final result = await db.rawQuery(
      '''
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
  ''',
      [productName],
    );

    return result;
  }

  // --------------------Purchase---------------------- //
  Future<int> addShopingCart(Purchase purchase) async {
    int result = 0;
    final Database db = await initializeDB();
    result = await db.rawInsert(
      "insert into purchase(pStoreCode,  oproductCode, purchaseQuantity, purchaseDate, purchasePrice, purchaseDeliverystatus, purchaseCartId) values (?,?,?,?,?,?)",
      [
        purchase.pStoreCode,
        purchase.oproductCode,
        purchase.purchaseQuanity,
        purchase.purchaseDate,
        purchase.purchasePrice,
        purchase.purchaseDeliveryStatus,
        purchase.purchaseCardId,
      ],
    );
    return result;
  }

  // ------------------------------------------------ //
  // query : announcement (notice)
  Future<List<CreateNotice>> queryAnnouncment() async {
    final Database db = await initializeDB();
    final List<Map<String, Object?>> queryResult = await db.rawQuery(
      "select * from createNotice ",
    );
    return queryResult.map((e) => CreateNotice.fromMap(e)).toList();
  }

  // ------------------------------------------------ //
  // query shopping Cart
  Future<List<shoppingCart>> queryShoppingCart(String pUserId) async {
    final Database db = await initializeDB();
    final List<Map<String, Object?>> queryResult = await db.rawQuery(
      "SELECT pr.productsName, pr.productsImage, p.purchaseQuantity FROM purchase p INNER JOIN products pr ON p.oproductCode = pr.productsCode WHERE p.pUserId = ? and pr.purchaseDeliveryStatus = '장바구니'",
      [pUserId],
    );
    return queryResult.map((e) => shoppingCart.fromMap(e)).toList();
  }

  // ------------------------------------------------ //
  // query store
  Future<List<Store>> queryStore() async {
    final Database db = await initializeDB();
    final List<Map<String, Object?>> queryResult = await db.rawQuery(
      "select * from store",
    );
    return queryResult.map((e) => Store.fromMap(e)).toList();
  }
  // ------------------------------------------------ //

  // Store Manager : Get Scheduled Products by Date and Store (Using Map result)
  // Query adjusted for 'pUserId', 'oproductCode' case. purchaseId is int.
  Future<List<Map<String, dynamic>>> getScheduledProductsByDateAndStore(
    DateTime date,
    String storeCode,
  ) async {
    final Database db = await initializeDB(); // initializeDB 호출
    final List<Map<String, dynamic>> queryResult = await db.rawQuery(
      '''
      SELECT
        p.purchaseId, -- int
        p.purchaseDate,
        p.purchaseQuanity,
        p.purchaseCardId, -- nullable int
        p.pStoreCode,
        p.purchaseDeliveryStatus,
        p.oproductCode, -- case sensitive
        p.purchasePrice,
        p.pUserId, -- new field
        pr.productsColor,
        pr.productsSize,
        u.name AS customerName,
        s.storeName AS storeName
      FROM purchase p
      JOIN products pr ON p.oproductCode = pr.productsCode -- join key adjusted for case
      JOIN users u ON p.pUserId = u.userid -- join key adjusted for pUserId case
      JOIN store s ON p.pStoreCode = s.storeCode
      WHERE p.purchaseDate = ? AND p.pStoreCode = ?
    ''',
      [date.toIso8601String().split('T')[0], storeCode],
    );
    // db.close();
    return queryResult; // Map keys match select statement aliases/names
  }

  // Store Manager : Get Received Inventory by Date Range and User (Using Map result)
  // Query adjusted for 'sproductCode' case.
  Future<List<Map<String, dynamic>>> getReceivedInventoryByDateRangeAndUser(
    DateTime startDate,
    DateTime endDate,
    String userId,
  ) async {
    final Database db = await initializeDB(); // initializeDB 호출
    final List<Map<String, dynamic>> queryResult = await db.rawQuery(
      '''
      SELECT
        sr.sproductCode, -- case sensitive
        pr.productsName,
        pr.productsColor,
        pr.productsSize,
        SUM(sr.stockReceiptsQuantityReceived) AS receivedQuantity
      FROM stockReceipts sr
      JOIN products pr ON sr.sproductCode = pr.productsCode -- join key adjusted for case
      WHERE sr.stockReceiptsReceipDate BETWEEN ? AND ?
      AND sr.saUserid = ?
      GROUP BY sr.sproductCode, pr.productsName, pr.productsColor, pr.productsSize
      ORDER BY pr.productsName
    ''',
      [
        startDate.toIso8601String().split('T')[0],
        endDate.toIso8601String().split('T')[0],
        userId,
      ],
    );
    // db.close();
    return queryResult; // Map keys match select statement aliases/names
  }

  // Store Manager : Get Returns by Date (Using Map result)
  // Query adjusted for 'rProductCode', 'processionStatus' case.
  Future<List<Map<String, dynamic>>> getReturnsByDate(DateTime date) async {
    final Database db = await initializeDB(); // initializeDB 호출
    final List<Map<String, dynamic>> queryResult = await db.rawQuery(
      '''
      SELECT
        r.returnCode, -- int
        r.ruserId,
        r.rProductCode, -- case sensitive
        pr.productsColor,
        pr.productsSize,
        r.returnDate,
        r.processionStatus -- adjusted column name case
      FROM return r
      JOIN products pr ON r.rProductCode = pr.productsCode -- join key adjusted for case
      WHERE r.returnDate = ?
      ORDER BY r.returnCode
    ''',
      [date.toIso8601String().split('T')[0]],
    );
    // db.close();
    return queryResult; // Map keys match select statement aliases/names
  }

  // Store Return Application: Get Purchase details by purchaseId
  // Used to get pUserId and oproductCode for return. purchaseId is int.
  Future<Map<String, dynamic>?> getPurchaseDetailsByPurchaseId(
    int purchaseId,
  ) async {
    // purchaseId type is int
    final Database db = await initializeDB(); // initializeDB 호출
    final List<Map<String, dynamic>> queryResult = await db.rawQuery(
      "SELECT pUserId, oproductCode FROM purchase WHERE purchaseId = ?", // adjusted column names case
      [purchaseId],
    );

    // db.close();
    if (queryResult.isNotEmpty) {
      return queryResult.first; // First result
    } else {
      return null; // No matching purchase
    }
  }

  // Store Return Application: Insert new return record
  // returnCode is INTEGER PRIMARY KEY. processionStatus case.
  Future<int> insertReturnRecord(Map<String, dynamic> returnData) async {
    final Database db = await initializeDB(); // initializeDB 호출
    // returnCode는 INTEGER PRIMARY KEY autoincrement가 아니므로,
    // 만약 자동 생성되지 않는다면 returnData 맵에 포함되어야 합니다.
    // 스키마에는 INTEGER PRIMARY KEY로만 되어 있으나, SQLite 동작에 따라 자동 생성될 수도 있습니다.
    // 자동 생성된다는 가정을 유지하고, 아니라면 returnData에 returnCode 값을 추가해야 합니다.
    int result = await db.insert('return', {
      // 'returnCode': returnData['returnCode'], // If returnCode is manually provided
      'ruserId': returnData['ruserId'],
      'rProductCode': returnData['rProductCode'],
      'returnReason': returnData['returnReason'],
      'returnDate': returnData['returnDate'], // YYYY-MM-DD string
      'returnCategory': returnData['returnCategory'],
      'processionStatus':
          returnData['processionStatus'], // adjusted column name case
    });
    // db.close();
    return result;
  }

  // Store Product Condition: Get Pickup Ready Orders for a specific store
  // Query adjusted for 'pUserId', 'oproductCode', 'purchaseQuanity' case. purchaseId is int.
  Future<List<Map<String, dynamic>>> getPickupReadyOrdersByStore(
    String storeCode, {
    String? searchQuery,
  }) async {
    final Database db = await initializeDB(); // initializeDB 호출
    // TODO: 실제 '픽업 대기' 상태 값을 사용하도록 수정해야 합니다.
    const String pickupStatus =
        'Ready for Pickup'; // <<< 중요: 실제 픽업 대기 상태 문자열로 변경!

    String sql = '''
      SELECT
        p.purchaseId, -- int
        p.purchaseDate,
        p.purchaseQuanity, -- case sensitive
        p.oproductCode, -- case sensitive
        pr.productsColor,
        pr.productsSize,
        u.name AS customerName, -- 고객 이름
        p.purchaseDeliveryStatus -- 현재 상태
      FROM purchase p
      JOIN users u ON p.pUserId = u.userid -- join key adjusted for pUserId case
      JOIN products pr ON p.oproductCode = pr.productsCode -- join key adjusted for case
      WHERE p.pStoreCode = ? AND p.purchaseDeliveryStatus = ?
    ''';

    List<dynamic> args = [storeCode, pickupStatus];

    // 검색어가 있다면 WHERE 절에 purchaseId 조건 추가. purchaseId는 integer.
    // 검색어는 문자열이므로 int로 변환하여 검색
    if (searchQuery != null && searchQuery.isNotEmpty) {
      int? searchId = int.tryParse(searchQuery);
      if (searchId != null) {
        sql += ' AND p.purchaseId = ?';
        args.add(searchId);
      } else {
        // 검색어가 숫자가 아니면 검색 조건 무시 또는 에러 처리
        print(
          'Warning: search query "$searchQuery" is not a valid purchaseId (integer)',
        );
        // 검색 결과 없음 처리 또는 다른 필드로 검색 로직 추가 가능
        return []; // 숫자가 아니면 검색 결과 없음으로 처리
      }
    }

    sql += ' ORDER BY p.purchaseDate DESC'; // 최신 주문부터 표시 (선택 사항)

    final List<Map<String, dynamic>> queryResult = await db.rawQuery(sql, args);
    // db.close();
    return queryResult; // Map keys match select statement aliases/names
  }

  // Store Product Condition: Update purchaseDeliveryStatus for a purchaseId
  // purchaseId type is int
  Future<int> updatePurchaseDeliveryStatus1(
    int purchaseId,
    String newStatus,
  ) async {
    // purchaseId type is int
    final Database db = await initializeDB(); // initializeDB 호출
    int result = await db.update(
      'purchase', // 업데이트할 테이블
      {'purchaseDeliveryStatus': newStatus}, // 업데이트할 컬럼과 값
      where: 'purchaseId = ?', // 업데이트 조건
      whereArgs: [purchaseId], // 조건에 사용될 인자 (int)
    );
    // db.close();
    return result;
  }

  // Company Create Store Manager: Get all stores - (이 메서드는 CompanyCreateAccount에서 더 이상 직접 사용되지 않습니다)
  Future<List<Map<String, dynamic>>> getAllStores() async {
    final Database db = await initializeDB(); // initializeDB 호출
    final List<Map<String, dynamic>> queryResult = await db.query(
      'store',
      columns: ['storeCode', 'storeName'],
      orderBy: 'storeName',
    );
    // db.close();
    return queryResult;
  }

  // Company Create Store Manager: Insert into daffiliation table - Links a user (대리점장) to a store
  // daffiliation has dstoreCode and duserId.
  Future<int> insertDaffiliation(String storeCode, String userId) async {
    final Database db = await initializeDB(); // initializeDB 호출
    int result = await db.insert('daffiliation', {
      'dstoreCode': storeCode,
      'duserId': userId,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
    // db.close();
    return result;
  }

  // Company Create Store: Insert new store record
  // Inserts data into the 'store' table. storeCode is PRIMARY KEY.
  Future<int> insertStoreInfo(Map<String, dynamic> storeData) async {
    final Database db = await initializeDB(); // initializeDB 호출
    int result = await db.insert(
      'store',
      storeData,
      conflictAlgorithm: ConflictAlgorithm.abort, // 키 중복 시 삽입 중단
    );
    // db.close();
    return result;
  }

  // Company Create Store: Check storeCode double check
  Future<int> storeCodeDoubleCheck(String storeCode) async {
    final Database db = await initializeDB(); // initializeDB 호출
    final List<Map<String, Object?>> queryResult = await db.rawQuery(
      "SELECT COUNT(*) FROM store WHERE storeCode = ?",
      [storeCode],
    );
    // db.close();
    int count = Sqflite.firstIntValue(queryResult) ?? 0;
    return count;
  }

  // Company Create Announcement: Insert new notice record
  // Inserts data into the 'createNotice' table.
  Future<int> insertNotice(Map<String, dynamic> noticeData) async {
    final Database db = await initializeDB();
    int result = await db.insert(
      'createNotice', // 삽입할 테이블
      noticeData, // 공지사항 정보 (Map 형태로 받음)
      // createNotice 테이블에는 primary key나 unique 제약 조건이 없는 것으로 보임 (initializeDB 기반)
      // 따라서 삽입 실패는 드물겠지만, DB 오류 가능성은 있음.
    );
    return result;
  }

  // Company Purchase List: Get total purchase amount for a date range and optional store
  // Aggregates purchasePrice from purchase table
  Future<int> getTotalPurchaseAmount({
    required DateTime startDate,
    required DateTime endDate,
    String? storeCode, // null이면 전체 대리점
  }) async {
    final Database db = await initializeDB();

    // 종료일의 시간을 하루의 끝으로 설정
    DateTime adjustedEndDate = DateTime(
      endDate.year,
      endDate.month,
      endDate.day,
      23,
      59,
      59,
    );

    String sql = '''
      SELECT SUM(purchasePrice) AS totalAmount
      FROM purchase
      WHERE purchaseDate BETWEEN ? AND ?
    ''';

    List<dynamic> args = [
      startDate.toIso8601String().split('T')[0],
      adjustedEndDate.toIso8601String().split('T')[0],
    ];

    // 특정 대리점 코드가 지정된 경우 조건 추가
    if (storeCode != null && storeCode.isNotEmpty) {
      sql += ' AND pStoreCode = ?';
      args.add(storeCode);
    }

    final List<Map<String, dynamic>> queryResult = await db.rawQuery(sql, args);

    // SUM 결과는 단일 행, 단일 컬럼으로 반환됩니다.
    if (queryResult.isNotEmpty && queryResult.first['totalAmount'] != null) {
      // SUM 결과가 INTEGER 또는 REAL일 수 있으므로 int로 변환
      return queryResult.first['totalAmount'] as int;
    }

    return 0; // 결과가 없거나 null이면 총액 0 반환
  }

  // Company Purchase List: Get purchase list details for a date range and optional store
  // Fetches purchase records with joined user and product info
  Future<List<Map<String, dynamic>>> getPurchaseList({
    required DateTime startDate,
    required DateTime endDate,
    String? storeCode, // null이면 전체 대리점
  }) async {
    final Database db = await initializeDB();

    // 종료일의 시간을 하루의 끝으로 설정
    DateTime adjustedEndDate = DateTime(
      endDate.year,
      endDate.month,
      endDate.day,
      23,
      59,
      59,
    );

    String sql = '''
      SELECT
        p.purchaseId,
        p.purchaseDate,
        p.purchaseQuanity,
        p.purchasePrice,
        p.pStoreCode,
        s.storeName, -- 대리점 이름 조인
        u.name AS customerName, -- 고객 이름 조인
        pr.productsName, -- 제품 이름 조인
        pr.productsColor,
        pr.productsSize
      FROM purchase p
      JOIN store s ON p.pStoreCode = s.storeCode
      JOIN users u ON p.pUserId = u.userid
      JOIN products pr ON p.oproductCode = pr.productsCode
      WHERE p.purchaseDate BETWEEN ? AND ?
    ''';

    List<dynamic> args = [
      startDate.toIso8601String().split('T')[0],
      adjustedEndDate.toIso8601String().split('T')[0],
    ];

    // 특정 대리점 코드가 지정된 경우 조건 추가
    if (storeCode != null && storeCode.isNotEmpty) {
      sql += ' AND p.pStoreCode = ?';
      args.add(storeCode);
    }

    sql += ' ORDER BY p.purchaseDate DESC'; // 최신순 정렬 (선택 사항)

    final List<Map<String, dynamic>> queryResult = await db.rawQuery(sql, args);

    return queryResult; // 구매 목록 (Map 리스트) 반환
  }

  // Company Purchase List: Get total purchase amount per store for a date range
  // Groups by storeCode and storeName to get per-store totals
  Future<List<Map<String, dynamic>>> getTotalPurchaseAmountPerStore({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final Database db = await initializeDB();

    // 종료일의 시간을 하루의 끝으로 설정
    DateTime adjustedEndDate = DateTime(
      endDate.year,
      endDate.month,
      endDate.day,
      23,
      59,
      59,
    );

    String sql = '''
      SELECT
        p.pStoreCode,
        s.storeName,
        SUM(p.purchasePrice) AS totalAmount
      FROM purchase p
      JOIN store s ON p.pStoreCode = s.storeCode
      WHERE p.purchaseDate BETWEEN ? AND ?
      GROUP BY p.pStoreCode, s.storeName -- 대리점별로 그룹화
      ORDER BY s.storeName -- 대리점 이름으로 정렬 (선택 사항)
    ''';

    List<dynamic> args = [
      startDate.toIso8601String().split('T')[0],
      adjustedEndDate.toIso8601String().split('T')[0],
    ];

    final List<Map<String, dynamic>> queryResult = await db.rawQuery(sql, args);

    return queryResult; // 대리점별 총액 목록 (Map 리스트) 반환
  }
}// class

