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
# ------------------------         Login.dart        -------------------------------- #
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
# ----------------------------------------------------------------------------------- #
# ----------------------------------------------------------------------------------- #


