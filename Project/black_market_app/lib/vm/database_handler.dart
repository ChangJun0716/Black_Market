import 'package:black_market_app/model/products.dart';
import 'package:black_market_app/model/purchase.dart';
import 'package:black_market_app/model/users.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHandler {
  Future<Database> initializeDB() async {
    String path = await getDatabasesPath();
    return openDatabase(
      join(path, 'blackMarket.db'),
      onCreate: (db, version) async {
        await db.execute(
          "create table affiliation(aJobGradeCode text primary key, aUserid text)",
        );
        await db.execute(
          "create table createApprovalDocument(cuserid text, cajobGradeCode text, name text, title text, content text, date text, rejectedReason text, approvalStatus text, approvalRequestExpense integer)",
        );
        await db.execute(
          "create table createNotice(cuserid text, cajobGradeCode text, title text, content text, date text, photo blob)",
        );
        await db.execute(
          "create table daffiliation(dstoreCode text, duserId text)",
        );
        await db.execute(
          "create table dispatch(dUserid text, daJobGradeCode text, dProductCode text, dispatchDate text, dispatchedQuantity integer)",
        );
        await db.execute(
          "create table grade(jobGradeCode text primary key, gradeName text, joinDate text)",
        );
        await db.execute(
          "create table manufacturers(manufacturerName text primary key)",
        );
        await db.execute(
          "create table order(orderQuantity text, orderDate text, orderStatus text, orderPrice integer, ajobGradCode text, oaUserid text, oproductCode text, omamufacturer text)",
        );
        await db.execute(
          "create table productRegistration(paUserid text, paJobGradeCode text, pProductCode text, introductionPhoto blob, productDescription text)",
        );
        await db.execute(
          "create table products(productsCode text primary key, productsColor text, productsName text, productsPrice integer, productsSize integer, productsImage blob)",
        );
        await db.execute(
          "create table purchase(purchaseId text primary key, purchaseDate text, purchaseQuanity integer, purchaseCardId integer, pStoreCode text, purchaseDeliveryStatus text, oproductCode text, purchasePrice integer)",
        );
        await db.execute(
          "create table returnInvestigation(raUserid text, raJobGradeCode text, rreturnCode integer, rmanufacturerName text, recordDate text, resolutionDetails text)",
        );
        await db.execute(
          "create table return(returnCode integer primary key, ruserId text, rProductCode text, returnReason text, returnDate text, returnCategory text, prosessionStateus text)",
        );
        await db.execute(
          "create table stockReceipts(saUserid text, saJobGradeCode text, stockReceiptsQuantityReceived integer, stockReceiptsReceipDate text, sproductCode text, smanufacturerName text)",
        );
        await db.execute(
          "create table store(storeCode text primary key, storeName text, address text, longitude real, latitude real)",
        );
        await db.execute(
          "create table users(userid text primary key, password text, name text, phone text, memberType integer, birthDate text, gender text)",
        );
      },
      version: 1,
    );
  }

  // --------------- Users -------------------- //
  // login.dart : User login id & pw check (query)
  Future<int> loginUsers(String id, String pw) async {
    final Database db = await initializeDB();
    final List<Map<String, Object?>> queryResult = await db.rawQuery(
      "select count(*) from users where userid = ? and password = ?",
      [id, pw],
    );
    int count = Sqflite.firstIntValue(queryResult) ?? 0;
    return count;
  }

  // ------------------------------------------------ //
  // login.dart : Check login success users memberType (query)
  Future<int> userMemberType(String id) async {
    final Database db = await initializeDB();
    final List<Map<String, Object?>> queryResult = await db.rawQuery(
      "select memberType from users where userid = ?",
      [id],
    );
    int count = Sqflite.firstIntValue(queryResult) ?? 0;
    return count;
  }

  // ------------------------------------------------ //
  // create_account.dart : id double check (query)
  Future<int> idDoubleCheck(String id) async {
    final Database db = await initializeDB();
    final List<Map<String, Object?>> queryResult = await db.rawQuery(
      "select count(*) from users where userid = ?",
      [id],
    );
    int count = Sqflite.firstIntValue(queryResult) ?? 0;
    return count;
  }

  // ------------------------------------------------ //
  // create_account.dart : create account (insert)
  Future<int> insertUserInfo(Users account) async {
    int result = 0;
    final Database db = await initializeDB();
    result = await db.rawInsert(
      "insert into users(userid, password, name, birthDate, gender, phone, memberType) values (?,?,?,?,?,?,?)",
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
  // customer_product_detial.dart : selected product information (query)
  Future<List<Products>> querySelectedProducts(String name) async {
    final Database db = await initializeDB();
    final List<Map<String, Object?>> queryResult = await db.rawQuery('''
    SELECT * FROM products 
    WHERE productsName = ?
  ''',
  [name]
  );

    return queryResult.map((e) => Products.formMap(e)).toList();
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
  // ------------------------------------------------ //
}// class