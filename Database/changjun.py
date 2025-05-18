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
from typing import Optional # 검색 시 null 값을 확인하기 위한 module
import base64 # 이미지를 여러 개 불러 올 때 사용하는 변환
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
# ----------------------------------------------------------------------------------- #

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
# 1. 사용자가 처음 로그인 했을 때 본사 직원에 의해 게시글로 등록된 제품 list 를 보기 위해
# 게시글의 data 와 제품의 data 를 가져오는 함수 (Image 제외!)
# 검색어가 없는 경우에는 전체 data 가 나타나고 검색어가 있는 경우에는 검색어가 ptitle 에 포함된 data 가 나타난다.
@router.get('/select/allProductsRegistration/{keyword}')
async def selectAllProductsRegistration(keyword: Optional[str] = None):
    conn = connect()
    curs = conn.cursor()
    if not keyword or keyword.strip() == "":
        curs.execute( 
            """SELECT p.productsCode AS pProductCode,
            pr.ptitle,
            p.productsColor,
            p.productsPrice,
            p.productsName
            FROM products p
            JOIN productRegistration pr ON p.productsCode = pr.products_productsCode
            WHERE p.productsCode IN (
            SELECT MIN(productsCode)
            FROM products
            GROUP BY productsName)
            ORDER BY productsCode
            """)
    else :
        search_keyword = f"%{keyword.strip()}%"
        curs.execute( 
            """SELECT p.productsCode AS pProductCode,
            pr.ptitle,
            p.productsColor,
            p.productsPrice,
            p.productsName
            FROM products p
            JOIN productRegistration pr ON p.productsCode = pr.products_productsCode
            WHERE p.productsCode IN (
            SELECT MIN(productsCode)
            FROM products
            GROUP BY productsName)
            and ptitle LIKE %s
            ORDER BY productsCode
            """, (search_keyword,))
    rows = curs.fetchall()
    conn.close()
    result = [{'productsCode': row[0], 'ptitle':row[1], 'productsColor':row[2], 'productsPrice' : row[3], 'productsName' : row[4]}for row in rows]
    return {"results" : result}
# ----------------------------------------------------------------------------------- #
# 2. 사용자가 처음 로그인 했을 때 본사 직원에 의해 게시글로 등록된 제품 list 를 보기 위해
#  Image 를 가져오는 함수! 1. 과 함께 사용한다.
@router.get('/select/allProductsRegistration/image/{productsCode}')
async def selectNoticeDetailImage(productsCode : int):
    try:
        conn = connect()
        curs = conn.cursor()
        curs.execute(
            """
            SELECT 
            pr.introductionPhoto
            FROM products p
            JOIN productRegistration pr ON p.productsCode = pr.products_productsCode
            WHERE p.productsCode IN (
            SELECT MIN(productsCode)
            FROM products
            GROUP BY productsName) and productsCode = %s
            """, (productsCode,)
        )
        row = curs.fetchone()
        conn.close()
        if row and row[0]:
            return Response(
                content = row[0],
                media_type="image/jpeg",
                headers={"Cache-control" : "no-cache, no-store, must-revalidate"}
            )
        else:
            return {"result" : "No image found"}
    except Exception as e:
        print("Error :", e)
        return {"result" : "Error"}
# ----------------------------------------------------------------------------------- #

# --------------        customer_products_detail.dart        ------------------------ #
# 1. 사용자가 제품 List 에서 ontap 하여 상세보기 페이지로 이동 했을 때 제품에 관련된 data 를 보내줄 함수
@router.get("/select/selectedProduct")
async def selectUser(productsName : str):
    conn = connect()
    curs = conn.cursor()
    curs.execute(
        '''
        SELECT 
        p.productsCode,
        p.productsColor,
        p.productsName,
        p.productsPrice,
        p.productsSize
        FROM products p
        LEFT JOIN productRegistration r
        ON p.productsCode = r.products_ProductsCode
        WHERE productsName = %s
        ''', (productsName,)
    )
    rows = curs.fetchall()
    conn.close()
    result = [{'productsCode':row[0], 'productsColor':row[1], 'productsName' : row[2], 'productsPrice' : row[3], 'productsSize' : row[4]}for row in rows]
    return {'results' : result}
# ----------------------------------------------------------------------------------- #
# 2. 사용자가 선택한 제품의 이미지를 상세보기 페이지로 보내주는 함수
@router.get('/select/selectedProduct/image/{productsName}')
async def selectNoticeDetailImage(productsName : str):
    try:
        conn = connect()
        curs = conn.cursor()
        curs.execute("SELECT productsImage From products WHERE productsName =%s",(productsName,))
        row = curs.fetchone()
        conn.close()
        if row and row[0]:
            return Response(
                content = row[0],
                media_type="image/jpeg",
                headers={"Cache-control" : "no-cache, no-store, must-revalidate"}
            )
        else:
            return {"result" : "No image found"}
    except Exception as e:
        print("Error :", e)
        return {"result" : "Error"}
# ----------------------------------------------------------------------------------- #
# 3. 사용자가 선택한 제품의 소개글에 포함된 이미지 들을 보내주는 함수
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
# 1. 사용자가 공지사항 list 에서 자세히 보고 싶은 card 를 ontap 했을 때 이동되는 상세보기 페이지로
# 선택한 record 의 data 들을 보여줄 select 함수 (Image 제외!)
@router.get("/select/notice/detail")
async def selectNoticeDetail(title : str):
    conn = connect()
    curs = conn.cursor()
    curs.execute("SELECT title, content, date FROM createNotice WHERE title = %s", (title,))
    rows = curs.fetchall()
    conn.close()
    result = [{'title':row[0], 'content':row[1], 'date':row[2]}for row in rows]
    return {'results' : result}
# ----------------------------------------------------------------------------------- #
# 2. 위의 select 함수와 함께 image 를 불러오는 함수 (performance 를 위해 분리)
@router.get('/select/notive/detail/image/{title}')
async def selectNoticeDetailImage(title : str):
    try:
        conn = connect()
        curs = conn.cursor()
        curs.execute("SELECT photo From createNotice WHERE title =%s",(title,))
        row = curs.fetchone()
        conn.close()
        if row and row[0]:
            return Response(
                content = row[0],
                media_type="image/jpeg",
                headers={"Cache-control" : "no-cache, no-store, must-revalidate"}
            )
        else:
            return {"result" : "No image found"}
    except Exception as e:
        print("Error :", e)
        return {"result" : "Error"}
# ----------------------------------------------------------------------------------- #
# ----------------------------------------------------------------------------------- #


