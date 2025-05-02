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
          "create table products(productsCode text primary key, productsColor text, productsName text, productsPrice integer, productsSize integer)",
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
}// class