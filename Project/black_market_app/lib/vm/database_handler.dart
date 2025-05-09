import 'dart:convert';

import 'package:black_market_app/model/create_notice.dart';
import 'package:black_market_app/model/grade.dart';
import 'package:black_market_app/model/grouped_products.dart';
import 'package:black_market_app/model/manufacturers.dart';
import 'package:black_market_app/model/order.dart';
import 'package:black_market_app/model/product_registration.dart';
import 'package:black_market_app/model/products.dart';
import 'package:black_market_app/model/purchase.dart';
import 'package:black_market_app/model/purchase_detail.dart';
import 'package:black_market_app/model/return_investigation.dart';
import 'package:black_market_app/model/shopping_cart_from_purchase.dart';
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
          "CREATE TABLE affiliation(aJobGradeCode TEXT, aUserid TEXT,joinDate TEXT)",
        );

        // Table: createApprovalDocument (match with CreateApprovalDocument model)
        await db.execute(
          "CREATE TABLE createApprovalDocument(cuserid TEXT, cajobGradeCode TEXT,checkGradeCode TEXT,name TEXT, title TEXT, content TEXT, date TEXT, approvalStatus TEXT, approvalRequestExpense INTEGER,corderID INTEGER)",
        );

        // Table: createNotice
        await db.execute(
          "CREATE TABLE createNotice(cuserid TEXT, cajobGradeCode TEXT, title TEXT, content TEXT, date TEXT, photo BLOB)",
        );

        // Table: daffiliation
        await db.execute(
          "CREATE TABLE daffiliation(dstoreCode TEXT, duserId TEXT)",
        );
        //전자 결재 시스템 테이블 approvalstep
        await db.execute(
          'CREATE TABLE IF NOT EXISTS approvalstep (documentId INTEGER, stepOrder INTEGER, approverId TEXT, status TEXT, comment TEXT, actionDate TEXT)',
        );

        // Table: dispatch (대리점 ID 추가됨)
        await db.execute(
          "CREATE TABLE dispatch(dUserid TEXT, dProductCode TEXT, dispatchDate TEXT, dispatchedQuantity INTEGER, dstoreCode TEXT,dipurchaseId INTEGER)",
        );

        // Table: grade
        await db.execute(
          "CREATE TABLE grade(jobGradeCode TEXT PRIMARY KEY, gradeName TEXT)",
        );

        // Table: manufacturers (match with Manufacturers model)
        await db.execute(
          "CREATE TABLE manufacturers(manufacturerName TEXT PRIMARY KEY)",
        );

        // Table: orders (match with Orders model)
        await db.execute(
          "CREATE TABLE orders(orderID INTEGER , orderQuantity TEXT, orderDate TEXT, orderStatus TEXT, orderPrice INTEGER, oajobGradCode TEXT, oaUserid TEXT, oproductCode TEXT, omamufacturer TEXT)",
        );

        // Table: productRegistration
        await db.execute(
          "CREATE TABLE productRegistration(paUserid TEXT, pProductCode TEXT, introductionPhoto BLOB, ptitle TEXT, contentJson TEXT)",
        );

        // Table: products (match with Products model)
        await db.execute(
          "CREATE TABLE IF NOT EXISTS Products(productsCode INTEGER PRIMARY KEY AUTOINCREMENT,productsColor TEXT,productsName TEXT,productsPrice INTEGER,productsOPrice INTEGER,productsSize INTEGER,productsImage BLOB)",
        );

        // Table: purchase (match with Purchase model)
        await db.execute(
          "CREATE TABLE purchase(purchaseId INTEGER PRIMARY KEY AUTOINCREMENT, purchaseDate TEXT, purchaseQuanity INTEGER, purchaseCardId INTEGER, pStoreCode TEXT, purchaseDeliveryStatus TEXT, oproductCode INTEGER, purchasePrice INTEGER,pUserId TEXT)",
        );

        // Table: returnInvestigation (match with ReturnInvestigation model)
        await db.execute(
          'CREATE TABLE returnInvestigation (raUserid TEXT,raJobGradeCode TEXT,rreturnCode INTEGER,rmanufacturerName TEXT,recordDate TEXT,resolutionDetails TEXT) ',
        );

        // Table: return (match with Return model)
        await db.execute(
          "CREATE TABLE return(returnCode INTEGER PRIMARY KEY, ruserId TEXT, rProductCode TEXT, returnReason TEXT, returnDate TEXT, returnCategory TEXT, processionStatus TEXT)",
        );

        // Table: stockReceipts (match with StockReceipts model)
        await db.execute(
          "CREATE TABLE stockReceipts(saUserid TEXT, stockReceiptsQuantityReceived INTEGER, stockReceiptsReceipDate TEXT, sproductCode TEXT, smanufacturerName TEXT)",
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
    final result = await db.rawQuery(
      "SELECT DISTINCT manufacturerName FROM manufacturers",
    );
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
    return Sqflite.firstIntValue(
          await db.rawQuery(
            "SELECT SUM(stockReceiptsQuantityReceived) FROM stockReceipts WHERE sproductCode = ?",
            [productCode],
          ),
        ) ??
        0;
  }

  // 해당 제품의 총 출고량
  Future<int> getTotalDispatched(String productCode) async {
    final db = await initializeDB();
    return Sqflite.firstIntValue(
          await db.rawQuery(
            "SELECT SUM(dispatchedQuantity) FROM dispatch WHERE dProductCode = ?",
            [productCode],
          ),
        ) ??
        0;
  }

  // 특정 제조사명 조회 (최신 입고 기준)
  Future<String> getManufacturerByProduct(String productCode) async {
    final db = await initializeDB();
    final result = await db.rawQuery(
      "SELECT smanufacturerName FROM stockReceipts WHERE sproductCode = ? ORDER BY stockReceiptsReceipDate DESC LIMIT 1",
      [productCode],
    );
    return result.isNotEmpty
        ? result.first['smanufacturerName'].toString()
        : '없음';
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
  Future<bool> isReceivedAfterOrder(
    String productCode,
    String orderDate,
  ) async {
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

    final dispatched =
        Sqflite.firstIntValue(
          await db.rawQuery(
            "SELECT SUM(dispatchedQuantity) FROM dispatch d JOIN daffiliation a ON d.dUserid = a.duserId WHERE dProductCode = ? ${storeCode != null ? "AND a.dstoreCode = '$storeCode'" : ''}",
            [productCode],
          ),
        ) ??
        0;

    final sold =
        Sqflite.firstIntValue(
          await db.rawQuery(
            "SELECT SUM(purchaseQuanity) FROM purchase WHERE oproductCode = ? ${storeCode != null ? "AND pStoreCode = '$storeCode'" : ''}",
            [productCode],
          ),
        ) ??
        0;

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
    return await db.insert('stockReceipts', {
      'saUserid': receipt.saUserid,
      'stockReceiptsQuantityReceived': receipt.stockReceiptsQuantityReceived,
      'stockReceiptsReceipDate':
          receipt.stockReceiptsReceipDate.toIso8601String(),
      'sproductCode': receipt.sproductCode,
      'smanufacturerName': receipt.smanufacturerName,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
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
      dProductCode,
      dispatchDate,
      dispatchedQuantity,
      dstoreCode,
      dipurchaseId
    ) VALUES (?, ?, ?, ?, ?,?)
    ''',
      [
        dispatch.dUserid,
        dispatch.dProductCode,
        dispatch.dispatchDate.toIso8601String(),
        dispatch.dispatchedQuantity,
        dispatch.dstoreCode,
        dispatch.dipurchaseId,
      ],
    );
  }

  // 본사에서 구매 해당 상품을 출고 했을 때 배송 상태 업데이트 하는 쿼리문
  Future<void> updatePurchaseDeliveryStatus(int purchaseId) async {
    final db = await initializeDB();
    await db.update(
      'purchase',
      {'purchaseDeliveryStatus': '본사배송시작'},
      where: 'purchaseId = ?',
      whereArgs: [purchaseId],
    );
  }

  //입고 전부 계산
  Future<int> getTotalStockIn(String productCode) async {
    final db = await initializeDB();
    final result = await db.rawQuery(
      'SELECT SUM(stockReceiptsQuantityReceived) as totalIn FROM stockReceipts WHERE sproductCode = ?',
      [productCode],
    );
    return result.first['totalIn'] as int? ?? 0;
  }

  // 출고 전부 계산
  Future<int> getTotalStockOut(String productCode) async {
    final db = await initializeDB();
    final result = await db.rawQuery(
      'SELECT SUM(dispatchedQuantity) as totalOut FROM dispatch WHERE dProductCode = ?',
      [productCode],
    );
    return result.first['totalOut'] as int? ?? 0;
  }

  // 반품 리스트 필터링
  Future<List<Map<String, dynamic>>> loadFilteredReturns({
    required String status,
  }) async {
    final db = await initializeDB();

    String query = "SELECT * FROM return";
    List<String> whereClauses = [];
    List<dynamic> args = [];

    if (status != '전체') {
      whereClauses.add("processionStatus = ?");
      args.add(status);
    }

    if (whereClauses.isNotEmpty) {
      query += " WHERE " + whereClauses.join(" AND ");
    }

    query += " ORDER BY returnDate DESC";

    return await db.rawQuery(query, args);
  }

  //반품 상태 변경 쿼리문
  Future<void> updateReturnStatus({
    required int returnCode,
    required String newStatus,
  }) async {
    final db = await initializeDB();
    await db.rawUpdate(
      '''
    UPDATE return
    SET processionStatus = ?
    WHERE returnCode = ?
    ''',
      [newStatus, returnCode],
    );
  }

  //제품 등록 메소드
  Future<int> insertProduct(Products product) async {
    final db = await initializeDB();
    return await db.insert('Products', {
      'productsColor': product.productsColor,
      'productsName': product.productsName,
      'productsPrice': product.productsPrice,
      'productsOPrice': product.productsOPrice,
      'productsSize': product.productsSize,
      'productsImage': product.productsImage,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
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
  //개시글 등록
  Future<int> insertProductRegistration(ProductRegistration post) async {
    final db = await initializeDB();
    return await db.insert('productRegistration', {
      'paUserid': post.paUserid,
      'pProductCode': post.pProductCode,
      'introductionPhoto': post.introductionPhoto,
      'ptitle': post.ptitle,
      'contentJson': jsonEncode(
        post.contentBlocks.map((e) => e.toMap()).toList(),
      ),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  //같은 제품의 게시글이 올라가 있는지 확인
  Future<ProductRegistration?> getProductRegistrationByProductCode(
    String productCode,
  ) async {
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
      'SELECT DISTINCT productsName FROM products ORDER BY productsName',
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
  // Future<List<GroupedProduct>> queryGroupedProducts() async {
  //   final db = await initializeDB();
  //   final result = await db.rawQuery('''
  //     SELECT
  //       p.productsCode AS pProductCode,
  //       p.productsName,
  //       p.productsPrice,
  //       p.productsColor,
  //       pr.ptitle,
  //       pr.introductionPhoto
  //     FROM products p
  //     JOIN productRegistration pr ON p.productsCode = pr.pProductCode
  //     WHERE p.productsCode IN (
  //         SELECT MIN(productsCode)
  //         FROM products
  //         GROUP BY productsName
  //       )
  //     ORDER BY p.productsName;
  //   ''');

  //   return result.map((e) => GroupedProduct.fromMap(e)).toList();
  // }
  Future<List<GroupedProduct>> queryGroupedProducts({String? keyword}) async {
    final db = await initializeDB();

    // 기본 WHERE 조건
    String baseQuery = '''
    SELECT 
      p.productsCode AS pProductCode,
      p.productsName,
      p.productsPrice,
      p.productsColor,
      pr.ptitle,
      pr.introductionPhoto
    FROM products p
    JOIN productRegistration pr ON p.productsCode = pr.pProductCode
    WHERE p.productsCode IN (
      SELECT MIN(productsCode)
      FROM products
      GROUP BY productsName
    )
  ''';

    // 조건 및 파라미터
    List<String> whereArgs = [];
    if (keyword != null && keyword.isNotEmpty) {
      baseQuery += ' AND pr.ptitle LIKE ?';
      whereArgs.add('%$keyword%');
    }

    baseQuery += ' ORDER BY p.productsName;';

    final result = await db.rawQuery(baseQuery, whereArgs);
    return result.map((e) => GroupedProduct.fromMap(e)).toList();
  }

  // ------------------------------------------------ //
  Future<String?> findProductNameByTitle(String ptitle) async {
    final db = await initializeDB();
    final result = await db.rawQuery(
      '''
    SELECT p.productsName
    FROM products p
    JOIN productRegistration r ON p.productsCode = r.pProductCode
    WHERE r.ptitle = ?
    LIMIT 1
  ''',
      [ptitle],
    );

    if (result.isNotEmpty) {
      return result.first['productsName'].toString();
    }
    return null;
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
      r.introductionPhoto
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
      "insert into purchase(pUserId, pStoreCode, purchaseCardId, oproductCode, purchaseQuanity, purchaseDate, purchasePrice, purchaseDeliveryStatus) values (?,?,?,?,?,?,?,?)",
      [
        purchase.pUserId,
        purchase.pStoreCode,
        purchase.purchaseCardId,
        purchase.oproductCode,
        purchase.purchaseQuanity,
        purchase.purchaseDate,
        purchase.purchasePrice,
        purchase.purchaseDeliveryStatus,
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
  Future<List<ShoppingCart>> queryShoppingCart(String pUserId) async {
    final Database db = await initializeDB();
    final List<Map<String, Object?>> queryResult = await db.rawQuery(
      '''
    SELECT 
      p.purchaseId, 
      pr.productsName, 
      pr.productsImage, 
      p.purchaseQuanity, 
      p.purchasePrice, 
      s.storeName
    FROM purchase p
    INNER JOIN products pr ON p.oproductCode = pr.productsCode
    INNER JOIN store s ON p.pStoreCode = s.storeCode
    WHERE p.pUserId = ? AND p.purchaseDeliveryStatus = ?
    ''',
      [pUserId, '장바구니'],
    );
    return queryResult.map((e) => ShoppingCart.fromMap(e)).toList();
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
  // getScheduledProductsByDateAndStore 메서드 (pUserId 컬럼 다시 포함 및 users 테이블 조인)
  // getScheduledProductsByDateAndStore 메서드 (oproductCode integer 타입 반영, WHERE 절 수정)
  // getScheduledProductsByDateAndStore 메서드 (Products 대문자, pUserId 포함, oproductCode integer 반영)
  // getScheduledProductsByDateAndStore 메서드 (Products 대문자, pUserId 포함, oproductCode integer 반영)
  Future<List<Map<String, dynamic>>> getScheduledProductsByDateAndStore(
    DateTime date,
    String storeCode,
  ) async {
    final Database db = await initializeDB();
    final List<Map<String, dynamic>> queryResult = await db.rawQuery(
      '''
      SELECT
        p.purchaseId, -- integer PRIMARY KEY autoincrement
        p.purchaseDate,
        p.purchaseQuanity,
        p.purchaseCardId, -- nullable int
        p.pStoreCode,
        p.purchaseDeliveryStatus,
        p.oproductCode, -- integer
        p.purchasePrice,
        p.pUserId, -- pUserId 컬럼 선택 (스키마 대소문자 사용)
        pr.productsColor,
        pr.productsName, -- 제품 이름 추가 (필요시)
        pr.productsPrice, -- 제품 가격 추가 (필요시)
        pr.productsOPrice, -- 제품 원가 추가 (필요시)
        pr.productsSize,
        u.name AS customerName, -- users 테이블 조인하여 고객 이름 선택
        s.storeName AS storeName
      FROM purchase p
      JOIN Products pr ON p.oproductCode = pr.productsCode -- Products 테이블 조인 (대문자 P)
      JOIN users u ON p.pUserId = u.userid -- users 테이블 조인 (pUserId 스키마 대소문자 사용)
      JOIN store s ON p.pStoreCode = s.storeCode
      WHERE p.purchaseDate = ? AND p.pStoreCode = ?
    ''',
      [date.toIso8601String().split('T')[0], storeCode],
    );
    return queryResult;
  }

  // Store Manager : Get Received Inventory by Date Range and User (Using Map result)
  // Query adjusted for 'sproductCode' case.
  // getReceivedInventoryByDateRangeAndUser 메서드 (Products 대문자 반영)
  // getReceivedInventoryByDateRangeAndUser 메서드 (Products 대문자 반영, sproductCode TEXT vs productsCode INTEGER 조인 유지)
  Future<List<Map<String, dynamic>>> getReceivedInventoryByDateRangeAndUser(
    DateTime startDate,
    DateTime endDate,
    String userId,
  ) async {
    final Database db = await initializeDB();
    final List<Map<String, dynamic>> queryResult = await db.rawQuery(
      '''
      SELECT
        sr.sproductCode, pr.productsName, pr.productsColor, pr.productsSize,
        SUM(sr.stockReceiptsQuantityReceived) AS receivedQuantity
      FROM stockReceipts sr
      JOIN Products pr ON sr.sproductCode = pr.productsCode -- Products 테이블 조인 (대문자 P), TEXT vs INTEGER 조인
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
    return queryResult;
  }

  // Store Manager : Get Returns by Date (Using Map result)
  // Query adjusted for 'rProductCode', 'processionStatus' case.
  // getReturnsByDate 메서드 (Products 대문자 반영, rProductCode TEXT vs productsCode INTEGER 조인 유지)
  // getReturnsByDate 메서드 (Products 대문자 반영, rProductCode TEXT vs productsCode INTEGER 조인 유지)
  Future<List<Map<String, dynamic>>> getReturnsByDate(DateTime date) async {
    final Database db = await initializeDB();
    final List<Map<String, dynamic>> queryResult = await db.rawQuery(
      '''
      SELECT
        r.returnCode, r.ruserId, r.rProductCode,
        pr.productsColor, pr.productsSize, -- products 테이블 조인
        pr.productsName, -- 제품 이름 추가
        pr.productsPrice, -- 제품 가격 추가
        pr.productsOPrice, -- 제품 원가 추가
        r.returnReason, -- 반품 사유 추가
        r.returnDate, r.returnCategory, r.processionStatus
      FROM return r
      JOIN Products pr ON r.rProductCode = pr.productsCode -- Products 테이블 조인 (대문자 P), TEXT vs INTEGER 조인
      -- purchase 테이블과의 직접적인 연결(purchaseId) 또는 pStoreCode가 없으므로 대리점 필터링 불가능
      WHERE r.returnDate = ?
      ORDER BY r.returnCode
    ''',
      [date.toIso8601String().split('T')[0]],
    );

    // Note: 이 쿼리는 날짜로만 필터링하며 대리점별 필터링은 현재 스키마로는 불가능합니다.
    // 만약 대리점별 반품 목록이 필요하다면, return 테이블에 pStoreCode 또는 purchaseId 컬럼 추가가 필요합니다.

    return queryResult;
  }

  // Store Return Application: Get Purchase details by purchaseId
  // Used to get pUserId and oproductCode for return. purchaseId is int.
  // getPurchaseDetailsByPurchaseId 메서드 (pUserId 다시 포함, purchaseId integer 처리)
  // getPurchaseDetailsByPurchaseId 메서드 (pUserId 다시 포함, purchaseId integer 처리, oproductCode integer 타입 반영)
  // getPurchaseDetailsByPurchaseId 메서드 (pUserId 다시 포함, purchaseId integer 처리, oproductCode integer 타입 반영)
  Future<Map<String, dynamic>?> getPurchaseDetailsByPurchaseId(
    int purchaseId,
  ) async {
    // purchaseId는 int로 받음
    final Database db = await initializeDB();
    final List<Map<String, dynamic>> queryResult = await db.rawQuery(
      // pUserId 컬럼 다시 선택 (스키마 대소문자 사용), oproductCode는 integer
      "SELECT pUserId, oproductCode FROM purchase WHERE purchaseId = ?", // pUserId 선택
      [purchaseId], // purchaseId는 int로 전달
    );
    if (queryResult.isNotEmpty) {
      // pUserId와 oproductCode 모두 포함하여 반환
      return {
        'pUserId': queryResult.first['pUserId'],
        'oproductCode': queryResult.first['oproductCode'],
      };
    } else {
      return null;
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

  // getPickupReadyOrdersByStore 쿼리에서 JOIN 절의 pUserId 컬럼 대소문자 수정
  // getPickupReadyOrdersByStore 메서드 (pUserId 컬럼 다시 포함 및 users 테이블 조인, purchaseId integer 검색 처리)
  // getPickupReadyOrdersByStore 메서드 (pUserId 컬럼 다시 포함 및 users 테이블 조인, purchaseId integer 검색 처리, oproductCode integer 타입 반영)
  // getPickupReadyOrdersByStore 메서드 (Products 대문자, pUserId 포함 및 users 테이블 조인, purchaseId integer 검색 처리, oproductCode integer 타입 반영)
  // getPickupReadyOrdersByStore 메서드 (Products 대문자, pUserId 포함 및 users 테이블 조인, purchaseId integer 검색 처리, oproductCode integer 타입 반영)
  Future<List<Map<String, dynamic>>> getPickupReadyOrdersByStore(
    String storeCode, {
    String? searchQuery,
  }) async {
    final Database db = await initializeDB();
    const String pickupStatus =
        'Ready for Pickup'; // TODO: 실제 '픽업 대기' 상태 값을 사용하도록 수정해야 합니다.

    String sql = '''
      SELECT
        p.purchaseId, -- integer PRIMARY KEY autoincrement
        p.purchaseDate,
        p.purchaseQuanity,
        p.oproductCode, -- integer
        pr.productsColor,
        pr.productsSize,
        pr.productsName, -- 제품 이름 추가 (필요시)
        pr.productsPrice, -- 제품 가격 추가 (필요시)
        pr.productsOPrice, -- 제품 원가 추가 (필요시)
        u.name AS customerName, -- users 테이블 조인하여 고객 이름 선택
        p.purchaseDeliveryStatus, -- 현재 상태
        p.pUserId -- pUserId 컬럼 선택 (스키마 대소문자 사용)
      FROM purchase p
      JOIN Products pr ON p.oproductCode = pr.productsCode -- Products 테이블 조인 (대문자 P)
      JOIN users u ON p.pUserId = u.userid -- users 테이블 조인 (pUserId 스키마 대소문자 사용)
      -- JOIN store s ON p.pStoreCode = s.storeCode 필요하다면 추가
      WHERE p.pStoreCode = ? AND p.purchaseDeliveryStatus = ?
    ''';

    List<dynamic> args = [storeCode, pickupStatus];

    if (searchQuery != null && searchQuery.isNotEmpty) {
      // purchaseId가 이제 integer이므로 int.tryParse로 변환하여 검색
      int? searchId = int.tryParse(searchQuery);
      if (searchId != null) {
        sql += ' AND p.purchaseId = ?';
        args.add(searchId); // int로 전달
      } else {
        print(
          'Warning: search query "$searchQuery" is not a valid purchaseId (integer)',
        );
        return []; // 유효하지 않은 검색어면 빈 목록 반환
      }
    }

    sql += ' ORDER BY p.purchaseDate DESC';

    final List<Map<String, dynamic>> queryResult = await db.rawQuery(sql, args);
    return queryResult;
  }

  // Store Product Condition: Update purchaseDeliveryStatus for a purchaseId
  // purchaseId type is int
  // updatePurchaseDeliveryStatus 메서드 (purchaseId integer 처리)
  // updatePurchaseDeliveryStatus 메서드 (purchaseId integer 처리)
  // updatePurchaseDeliveryStatus 메서드 (purchaseId integer 처리)
  // updatePurchaseDeliveryStatus 메서드 (purchaseId integer 처리)
  Future<int> updatePurchaseDeliveryStatus1(
    int purchaseId,
    String newStatus,
  ) async {
    // purchaseId는 int로 받음
    final Database db = await initializeDB();
    int result = await db.update(
      'purchase',
      {'purchaseDeliveryStatus': newStatus},
      where: 'purchaseId = ?', // purchaseId는 integer
      whereArgs: [purchaseId], // purchaseId를 int로 전달
    );
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
  // getPurchaseList 메서드 (pUserId 컬럼 다시 포함 및 users 테이블 조인)
  // getPurchaseList 메서드 (pUserId 컬럼 다시 포함 및 users 테이블 조인, oproductCode integer 타입 반영)
  // getPurchaseList 메서드 (Products 대문자, pUserId 포함, oproductCode integer 반영)
  // getPurchaseList 메서드 (Products 대문자, pUserId 포함, oproductCode integer 반영)
  Future<List<Map<String, dynamic>>> getPurchaseList({
    required DateTime startDate,
    required DateTime endDate,
    String? storeCode,
  }) async {
    final Database db = await initializeDB();

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
        p.purchaseId, -- integer PRIMARY KEY autoincrement
        p.purchaseDate,
        p.purchaseQuanity,
        p.purchasePrice,
        p.pStoreCode,
        s.storeName, -- 대리점 이름 조인
        u.name AS customerName, -- users 테이블 조인하여 고객 이름 선택
        pr.productsName, -- 제품 이름 조인
        pr.productsColor,
        pr.productsSize,
        pr.productsOPrice, -- 제품 원가 추가 (필요시)
        p.oproductCode, -- integer
        p.pUserId -- pUserId 컬럼 선택 (스키마 대소문자 사용)
      FROM purchase p
      JOIN store s ON p.pStoreCode = s.storeCode
      JOIN users u ON p.pUserId = u.userid -- users 테이블 조인 (pUserId 스키마 대소문자 사용)
      JOIN Products pr ON p.oproductCode = pr.productsCode -- Products 테이블 조인 (대문자 P)
      WHERE p.purchaseDate BETWEEN ? AND ?
    ''';

    List<dynamic> args = [
      startDate.toIso8601String().split('T')[0],
      adjustedEndDate.toIso8601String().split('T')[0],
    ];

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

  // Get storeCode from daffiliation table by userId (duserId 컬럼 이름 소문자 가정)
  // Get storeCode from daffiliation table by userId (duserId 컬럼 이름 소문자 가정)
  // Get storeCode from daffiliation table by userId (스키마 대소문자 duserId, dstoreCode 사용)
  // Get storeCode from daffiliation table by userId (스키마 대소문자 duserId, dstoreCode 사용)
  Future<String?> getStoreCodeByUserId(String userId) async {
    final Database db = await initializeDB();
    final List<Map<String, Object?>> queryResult = await db.rawQuery(
      // daffiliation 테이블의 컬럼 이름을 스키마 정의(duserId, dstoreCode)와 동일하게 사용
      "SELECT dstoreCode FROM daffiliation WHERE duserId = ?", // <-- 이 줄 수정
      [userId],
    );
    if (queryResult.isNotEmpty) {
      // SELECT 절에서 dstoreCode를 사용했으므로 키 이름도 dstoreCode
      return queryResult.first['dstoreCode']
          ?.toString(); // <--- 이 줄 유지 또는 수정 필요시 수정
    }
    return null; // User not found in daffiliation
  }

  // Get storeName from store table by storeCode
  // Get storeName from store table by storeCode
  Future<String?> getStoreNameByStoreCode(String storeCode) async {
    final Database db = await initializeDB();
    final List<Map<String, Object?>> queryResult = await db.rawQuery(
      "SELECT storeName FROM store WHERE storeCode = ?",
      [storeCode],
    );
    if (queryResult.isNotEmpty) {
      return queryResult.first['storeName']?.toString();
    }
    return null; // Store not found
  }

  // ------------------------------ //
  // update purchase List : deliveryState '장바구니' -> '주문완료'
  Future<int> updatePurchaseList(int purchaseId, String deliveryState) async {
    final Database db = await initializeDB();
    final int result = await db.rawUpdate(
      '''
    UPDATE purchase 
    SET purchaseDeliveryStatus = ? 
    WHERE purchaseId = ?
    ''',
      [deliveryState, purchaseId],
    );
    return result;
  }

  // ------------------------------ //
  // query purchase List
  Future<List<Map<String, dynamic>>> queryUserPurchaseList(
    String pUserId,
  ) async {
    final Database db = await initializeDB();
    final List<Map<String, Object?>> queryResult = await db.rawQuery(
      '''
    SELECT 
      p.purchaseId,
      p.purchasePrice,
      p.purchaseDeliveryStatus,
      pr.productsName
    FROM purchase p
    JOIN products pr ON p.oproductCode = pr.productsCode
    WHERE p.pUserId = ? AND p.purchaseDeliveryStatus != '장바구니'
  ''',
      [pUserId],
    );

    return queryResult;
  }

  // ------------------------------ //
  // query announcement by title
  Future<List<CreateNotice>> queryAnnouncementByTitle(String title) async {
    final Database db = await initializeDB();
    final List<Map<String, Object?>> queryResult = await db.rawQuery(
      "select * from createNotice where title = ?",
      [title],
    );
    return queryResult.map((e) => CreateNotice.fromMap(e)).toList();
  }

  // ------------------------------ //
  Future<PurchaseDetail?> queryPurchaseDetail(int purchaseId) async {
    final Database db = await initializeDB();

    final result = await db.rawQuery(
      '''
    SELECT 
      p.productsName,
      p.productsColor,
      p.productsSize,
      p.productsImage,
      pr.ptitle,
      pu.purchasePrice,
      pu.purchaseQuanity,
      pu.purchaseDeliveryStatus,
      s.storeName
    FROM purchase pu
    JOIN products p ON pu.oProductCode = p.productsCode
    LEFT JOIN productRegistration pr ON p.productsCode = pr.pProductCode
    JOIN store s ON pu.pStoreCode = s.storeCode
    WHERE pu.purchaseId = ?
  ''',
      [purchaseId],
    );

    if (result.isNotEmpty) {
      return PurchaseDetail.fromMap(result.first);
    } else {
      return null;
    }
  }

  // ------------------------------ //
  Future<void> deletePurchaseItem(int purchaseId) async {
    final db = await initializeDB();
    await db.delete(
      'purchase',
      where: 'purchaseId = ?',
      whereArgs: [purchaseId],
    );
  }

  // ------------------------------ //
  Future<int> getProductStock(String productCode) async {
    final db = await initializeDB();

    // dispatch에서 제품별 수량 합계
    final dispatchResult = await db.rawQuery(
      '''
    SELECT SUM(dispatchedQuantity) as total FROM dispatch
    WHERE dProductCode = ?
  ''',
      [productCode],
    );

    final dispatched = dispatchResult.first['total'] as int? ?? 0;

    // purchase에서 장바구니 제외한 제품별 수량 합계
    final purchaseResult = await db.rawQuery(
      '''
    SELECT SUM(purchaseQuanity) as total FROM purchase
    WHERE oproductCode = ? AND purchaseDeliveryStatus != '장바구니'
  ''',
      [productCode],
    );

    final purchased = purchaseResult.first['total'] as int? ?? 0;

    return dispatched - purchased;
  }

  //제조사 추가
  Future<int> insertManufacturer(Manufacturers manufacturer) async {
    final db = await initializeDB();
    return await db.insert(
      'manufacturers',
      {'manufacturerName': manufacturer.manufacturerName},
      conflictAlgorithm: ConflictAlgorithm.ignore, // 중복 방지
    );
  }

  //제조사 검색
  Future<List<String>> getManufacturers1() async {
    final db = await initializeDB();
    final result = await db.rawQuery(
      "SELECT DISTINCT manufacturerName FROM manufacturers",
    );
    return result.map((e) => e['manufacturerName'].toString()).toList();
  }

  //출고 대리점과 같은거 찾기
  Future<List<int>> getPendingOrderIdsForDispatch(
    int productCode,
    String storeCode,
  ) async {
    final db = await initializeDB();
    final result = await db.rawQuery(
      '''
    SELECT purchaseId FROM purchase 
    WHERE oproductCode = ? 
      AND pStoreCode = ? 
      AND purchaseDeliveryStatus = '주문완료'
    ''',
      [productCode.toString(), storeCode],
    );

    return result
        .map((row) {
          final rawId = row['purchaseId'];
          if (rawId is int) return rawId;
          if (rawId is String) return int.tryParse(rawId) ?? -1;
          return -1;
        })
        .where((id) => id != -1)
        .toList();
  }

  //주문 정보 가지고 오기
  Future<Purchase?> getPurchaseById(int purchaseId) async {
    final db = await initializeDB();
    final List<Map<String, dynamic>> result = await db.query(
      'purchase',
      where: 'purchaseId = ?',
      whereArgs: [purchaseId],
    );

    if (result.isNotEmpty) {
      return Purchase.formMap(result.first);
    }
    return null;
  }

  //입고 리스트
  Future<List<Map<String, dynamic>>> getAllStockReceipts() async {
    final db = await initializeDB();
    return await db.rawQuery('''
    SELECT * FROM stockReceipts
  ''');
  }

  //출고 리스트
  Future<List<Map<String, dynamic>>> getAllDispatches() async {
    final db = await initializeDB();
    return await db.rawQuery('''
    SELECT d.*, s.storeName
    FROM dispatch d
    LEFT JOIN store s ON d.dstoreCode = s.storeCode
  ''');
  }

  //직급 찾는 메소드
  Future<String> getJobGradeByUserId(String userId) async {
    final db = await initializeDB();
    final result = await db.query(
      'affiliation',
      where: 'aUserid = ?',
      whereArgs: [userId],
      limit: 1,
    );
    return result.isNotEmpty ? result.first['aJobGradeCode'] as String : '';
  }

  // 원가 가격을 들고오는 메소드
  Future<int> getProductOPriceByCode(int code) async {
    final db = await initializeDB();
    final result = await db.query(
      'products',
      columns: ['productsOPrice'],
      where: 'productsCode = ?',
      whereArgs: [code],
    );

    if (result.isNotEmpty && result.first['productsOPrice'] != null) {
      return result.first['productsOPrice'] as int;
    } else {
      return 0; // 기본값 또는 오류 처리
    }
  }

  //직급 들고오기
  Future<List<Grade>> getAllGrades() async {
    final db = await initializeDB();
    final List<Map<String, dynamic>> result = await db.query('grade');

    return result.map((map) => Grade.fromMap(map)).toList();
  }

  //orderid 구하는거
  Future<int> getNextOrderId() async {
    final db = await initializeDB();
    final result = await db.rawQuery(
      'SELECT MAX(orderID) as maxId FROM Orders',
    );

    if (result.isEmpty || result.first['maxId'] == null) {
      return 1; // 조회 결과가 없으면 1로 시작
    }

    final maxId = result.first['maxId'] as int;
    return maxId + 1;
  }

  Future<Map<String, String>> getUserInfoById(String userId) async {
    final db = await initializeDB();
    final result = await db.query(
      'Users',
      columns: ['name'],
      where: 'userid = ?',
      whereArgs: [userId],
    );
    if (result.isNotEmpty) {
      return {'name': result.first['name'].toString()};
    } else {
      throw Exception('사용자 정보를 찾을 수 없습니다.');
    }
  }

  //발주서 등록
  Future<void> insertCreateApprovalDocument(CreateApprovalDocument doc) async {
    final db = await initializeDB();
    await db.insert(
      'createApprovalDocument', // ✅ 테이블 이름 맞춤
      {
        'cuserid': doc.cUserid,
        'cajobGradeCode': doc.cajobGradeCode,
        'name': doc.name,
        'title': doc.title,
        'content': doc.content,
        'date': doc.date.toIso8601String(),
        'approvalStatus': doc.approvalStatus,
        'approvalRequestExpense': doc.approvalRequestExpense,
        'corderID': doc.corderID,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  //발주 등록
  Future<void> insertOrder(Orders order) async {
    final db = await initializeDB();
    await db.insert('Orders', {
      'orderID': order.orderID,
      'orderQuantity': order.orderQuantity,
      'orderStatus': order.orderStatus,
      'orderPrice': order.orderPrice,
      'oajobGradCode': order.oajobGradCode,
      'oaUserid': order.oaUserid,
      'oproductCode': order.oproductCode,
      'omamufacturer': order.omamufacturer,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  //결재선 아이디 찾기
  Future<String?> getGradeCodeByName(String gradeName) async {
    final db = await initializeDB();
    final result = await db.query(
      'grade', //
      columns: ['jobGradeCode'],
      where: 'gradeName = ?',
      whereArgs: [gradeName],
    );
    if (result.isNotEmpty) {
      return result.first['jobGradeCode'].toString();
    }
    return null;
  }
  //결재서 단계 입렵

  Future<void> insertApprovalSteps({
    required int documentId,
    required int requesterGrade,
    required int finalGrade,
  }) async {
    final db = await initializeDB();

    final gradeResult = await db.query(
      'grade',
      where: 'jobGradeCode > ? AND jobGradeCode <= ?',
      whereArgs: [requesterGrade, finalGrade],
      orderBy: 'jobGradeCode ASC',
    );

    int step = 1;
    for (final grade in gradeResult) {
      final gradeCode = grade['jobGradeCode'].toString();

      final userResult = await db.query(
        'affiliation',
        where: 'aJobGradeCode = ?',
        whereArgs: [gradeCode],
        limit: 1,
      );

      if (userResult.isNotEmpty) {
        final approverId = userResult.first['aUserid'].toString();

        await db.insert('approvalstep', {
          'documentId': documentId,
          'stepOrder': step,
          'approverId': approverId,
          'status': '대기',
          'comment': null,
          'actionDate': null,
        });
        step++;
      }
    }
  }

  //결재 승인
  Future<List<Map<String, dynamic>>> getApprovalStepsByDocumentId(
    int documentId,
  ) async {
    final db = await initializeDB();
    final result = await db.query(
      'approvalstep',
      where: 'documentId = ?',
      whereArgs: [documentId],
      orderBy: 'stepOrder ASC',
    );
    return result;
  }

  //승인 끝나면 발주완료
  Future<void> finalizeApproval({required int documentId}) async {
    final db = await initializeDB();

    // 1. 결재서 상태를 '승인'으로 변경
    await db.update(
      'createApprovalDocument',
      {'approvalStatus': '승인'},
      where: 'corderID = ?',
      whereArgs: [documentId],
    );

    await db.update(
      'orders',
      {'orderStatus': '발주완료'},
      where: 'orderID = ?',
      whereArgs: [documentId],
    );
  }

  //승인 상태 변경
  Future<void> approveStep({
    required int documentId,
    required String approverId,
  }) async {
    final db = await initializeDB();

    // 1. 모든 단계 로드
    final steps = await db.query(
      'approvalstep',
      where: 'documentId = ?',
      whereArgs: [documentId],
      orderBy: 'stepOrder ASC',
    );

    // 2. 첫 번째 '대기' 상태인 단계를 찾는다
    final pendingStep = steps.firstWhere(
      (step) => step['status'] == '대기',
      orElse: () => {},
    );

    // 3. 승인 요청자가 현재 차례가 아닐 경우 예외
    if (pendingStep.isEmpty || pendingStep['approverId'] != approverId) {
      throw Exception('승인할 수 있는 단계가 아닙니다.');
    }

    // 4. 해당 단계를 승인 처리
    await db.update(
      'approvalstep',
      {'status': '승인', 'actionDate': DateTime.now().toIso8601String()},
      where: 'documentId = ? AND approverId = ?',
      whereArgs: [documentId, approverId],
    );
  }

  //반려 했을 때
  Future<void> rejectStep({
    required int documentId,
    required String approverId,
    required String comment,
  }) async {
    final db = await initializeDB();

    // 1. 해당 단계 상태를 반려로 설정
    await db.update(
      'approvalstep',
      {
        'status': '반려',
        'comment': comment,
        'actionDate': DateTime.now().toIso8601String(),
      },
      where: 'documentId = ? AND approverId = ?',
      whereArgs: [documentId, approverId],
    );

    // 2. 결재서 자체 상태도 반려로 설정
    await db.update(
      'createApprovalDocument',
      {'approvalStatus': '반려'},
      where: 'corderID = ?',
      whereArgs: [documentId],
    );
  }

  //승인 진행중
  Future<void> updateApprovalDocumentStatus({
    required int documentId,
    required String newStatus,
  }) async {
    final db = await initializeDB();
    await db.update(
      'createApprovalDocument',
      {'approvalStatus': newStatus},
      where: 'corderID = ?',
      whereArgs: [documentId],
    );
  } //발주 리스트

  Future<List<Map<String, dynamic>>> getAllOrders() async {
    final db = await initializeDB();
    final result = await db.rawQuery('''
    SELECT o.*, p.productsName
    FROM orders o
    LEFT JOIN products p ON o.oproductCode = p.productsCode
    ORDER BY o.orderID DESC
  ''');
    return result;
  }

  //발주 리스트 검색
  Future<List<Map<String, dynamic>>> getOrderList({String? productName}) async {
    final db = await initializeDB();
    String query = '''
    SELECT o.*, p.productsName 
    FROM orders o
    LEFT JOIN products p ON o.oproductCode = p.productsCode
  ''';

    List<String> where = [];
    List<dynamic> args = [];

    if (productName != null && productName.isNotEmpty) {
      where.add("p.productsName LIKE ?");
      args.add('%$productName%');
    }

    if (where.isNotEmpty) {
      query += ' WHERE ' + where.join(' AND ');
    }

    query += ' ORDER BY o.orderID DESC';

    return await db.rawQuery(query, args);
  }

  //원인규명
  Future<void> insertReturnInvestigation({
    required String raUserid,
    required String raJobGradeCode,
    required int rreturnCode,
    required String rmanufacturerName,
    required String recordDate,
    required String resolutionDetails,
  }) async {
    final db = await initializeDB();
    await db.insert('returnInvestigation', {
      'raUserid': raUserid,
      'raJobGradeCode': raJobGradeCode,
      'rreturnCode': rreturnCode,
      'rmanufacturerName': rmanufacturerName,
      'recordDate': recordDate,
      'resolutionDetails': resolutionDetails,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }
}// class

