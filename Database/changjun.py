"""
author      : ChangJun Lee
description : blackmarket_app 과 연동되는 database 를 사용 할 CRUD 기능을 가진 함수 class 
date        : 2025.05.17
version     : 1
"""
# -------------------------------- Import ------------------------------------------- #
from fastapi import APIRouter, UploadFile, File, Form
from fastapi.responses import Response
from pydantic import BaseModel
import pymysql
#선언될 ip
ip = "127.0.0.1"
# -------------------------------- Property  ---------------------------------------- #
router = APIRouter()

# MySQL server host
def connect():
    return pymysql.connect(
        host=ip,
        user="root",
        password="qwer1234",
        db="mydb",
        charset="utf8"
    )
# -------------------------------- Functions ---------------------------------------- #
# ------------------         create_account.dart        ----------------------------- #
# 1. 사용자가 앱을 사용하기 위해 회원가입을 할 때 입력한 정보를 Database 에 insert 하는 함수
@router.post("/insertUserAccount")
async def insertUserAccount(
    userid : str=Form(...), password : str=Form(...), name : str=Form(...), phone : str=Form(...), 
    birthDate : str=Form(...), gender : str=Form(...), memberType : str=Form(...)):
        try:
            conn = connect()
            curs = conn.cursor()
            sql = 'INSERT INTO users (userid, password, name, phone, birthDate, gender, memberType) VALUES (%s,%s,%s,%s,%s,%s,%s)'
            curs.execute(sql, (userid, password, name, phone, birthDate, gender, memberType))
            conn.commit()
            conn.close()
            return {'result' : 'OK'}
        except Exception as e :
            print("Error : ", e)
            return {"result" : "Error" }
# ----------------------------------------------------------------------------------- #
# 2. 사용자가 회원가입을 할 때 아이디의 중복을 확인하기 위해 Database 에 입력한 값의 유무를 확인하는 함수
@router.get('/selectUseridDoubleCheck')
async def selectUseridDoubleCheck(userid : str):
    conn = connect()
    curs = conn.cursor()
    curs.execute("SELECT count(*) From users WHERE userid =%s", (userid, ))
    rows = curs.fetchall()
    conn.close()
    result = [{'count' : row[0]}for row in rows]
    return {'results' : result}
# ------------------------         login.dart        -------------------------------- #
# 1. 회원가입을 한 사용자가 앱을 사용하기 위해 ID 와 PW 를 입력하였을 때 database 와의 일치를 확인하는 함수
@router.get("/selectUser")
async def selectUser(userid : str, password : str):
    conn = connect()
    curs = conn.cursor()
    curs.execute("SELECT count(*), memberType FROM users WHERE userid =%s and password =%s", (userid, password))
    rows = curs.fetchall()
    conn.close()
    result = [{'count':row[0], 'memberType':row[1]}for row in rows]
    return {'results' : result}
# ----------------------------------------------------------------------------------- #
# --------------        customer_products_list.dart        -------------------------- #
# ----------------------------------------------------------------------------------- #
# --------------        customer_products_detail.dart        ------------------------ #
# ----------------------------------------------------------------------------------- #
# --------------        customer_shopping_cart.dart        -------------------------- #
# ----------------------------------------------------------------------------------- #
# --------------        customer_purchase_list.dart        -------------------------- #
# ----------------------------------------------------------------------------------- #
# --------------        customer_purchase_detail.dart        ------------------------ #
# ----------------------------------------------------------------------------------- #
# --------------        customer_announcement_list.dart        ---------------------- #
# 1. 사용자가 본사 직원에 의해 작성된 공지사항 list 를 확인 할 수 있는 페이지로 data 띄우기 위해 select 하는 함수
@router.get("/select/notice")
async def selectNotice():
    conn = connect()
    curs = conn.cursor()
    curs.execute("SELECT title, date FROM createNotice")
    rows = curs.fetchall()
    conn.close()
    result = [{'title':row[0], 'date':row[1]}for row in rows]
    return {'results' : result}
# ----------------------------------------------------------------------------------- #
# --------------        customer_announcement_detail.dart        -------------------- #
# ----------------------------------------------------------------------------------- #
# ----------------------------------------------------------------------------------- #
# ----------------------------------------------------------------------------------- #


