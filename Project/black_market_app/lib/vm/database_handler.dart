import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHandler {
  Future<Database> initializeDB()async{
    String path = await getDatabasesPath();
    return openDatabase(
      join(path,'blackMarket.db'),
      onCreate: (db, version) async{
        await db.execute(
          "create table 테이블 명()"
        );
        await db.execute(
          "create table 테이블 명()"
        );
        await db.execute(
          "create table 테이블 명()"
        );
        await db.execute(
          "create table 테이블 명()"
        );
        await db.execute(
          "create table 테이블 명()"
        );
        await db.execute(
          "create table 테이블 명()"
        );
        await db.execute(
          "create table 테이블 명()"
        );
        await db.execute(
          "create table 테이블 명()"
        );
        await db.execute(
          "create table 테이블 명()"
        );
        await db.execute(
          "create table 테이블 명()"
        );
        await db.execute(
          "create table 테이블 명()"
        );
        await db.execute(
          "create table 테이블 명()"
        );
        await db.execute(
          "create table 테이블 명()"
        );
        await db.execute(
          "create table 테이블 명()"
        );
        await db.execute(
          "create table 테이블 명()"
        );
        await db.execute(
          "create table 테이블 명()"
        );
        await db.execute(
          "create table 테이블 명()"
        );
      },
      version: 1,
    );
  }
}// class