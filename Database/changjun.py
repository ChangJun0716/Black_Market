"""
author      : ChangJun Lee
description : blackmarket_app 과 연동되는 database 를 사용 할 CRUD 기능을 가진 함수 class 
date        : 2025.05.17
version     : 1
"""
# -------------------------------- Import ------------------------------------------- #
from fastapi import APIRouter, UploadFile, File, Form
from fastapi.responses import Response, JSONResponse
from pydantic import BaseModel
import pymysql
import pickle # list 형식의 이미지 를 불러 오기위한 module
from typing import Optional # 검색 시 null 값을 확인하기 위한 module
import base64 # 이미지를 여러 개 불러 올 때 사용하는 변환
#선언될 ip
ip = "127.0.0.1"
# -------------------------------- Property  ---------------------------------------- #
router = APIRouter()
# Host

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
#  Image 를 가져오는 함수 1. 과 함께 사용한다.
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
# 3. 사용자가 선택한 제품의 소개글에 포함된 이미지 들의 url index 를 보내주는 함수
@router.get("/select/products/contentImageUrls/{productsCode}")
async def get_content_image_urls(productsCode: int):
    try:
        conn = connect()
        curs = conn.cursor()
        curs.execute(
            "SELECT contentBlocks FROM productRegistration WHERE products_productsCode = %s",
            (productsCode,)
        )
        row = curs.fetchone()
        conn.close()

        if not row or not row[0]:
            return JSONResponse(content={"result": "No content found"}, status_code=404)

        # contentBlocks 역직렬화
        image_list = pickle.loads(row[0])
        # 이미지 수만큼의 URL 리스트 구성
        urls = [
            f"http://{ip}:8000/changjun/select/products/contentImage/{productsCode}/{i}"
            for i in range(len(image_list))
        ]
        return {
            "productCode": productsCode,
            "contentImages": urls
        }
    except Exception as e:
        return JSONResponse(content={"result": f"Error: {str(e)}"}, status_code=500)
# ----------------------------------------------------------------------------------- #
# 4. 사용자가 선택한 제품의 소개글에 포함된 이미지 들을 보내주는 함수
@router.get("/select/selectedProducts/contentBlock/{productsCode}/{index}")
async def get_content_image(productsCode: int, index: int):
    try:
        conn = connect()
        curs = conn.cursor()
        curs.execute(
            "SELECT contentBlocks FROM productRegistration WHERE products_productsCode = %s",
            (productsCode,)
        )
        row = curs.fetchone()
        conn.close()
        if row:
            image_list = pickle.loads(row[0])  # list of images
            print(image_list)
            if 0 <= index < len(image_list):
                return Response(
                    content=image_list[index],
                    media_type="image/jpeg",
                    headers={"Cache-control": "no-cache, no-store, must-revalidate"}
                )
            else:
                return {"result": "Invalid image index"}
        else:
            return {"result": "No image found"}
    except Exception as e:
        print("Error:", e)
        return {"result": "Error"}
# ----------------------------------------------------------------------------------- #
# 5. 사용자가 값을 모두 지정한 뒤 장바구니에 담거나 주문을 진행한다.
@router.post("/insert/purchase")
async def insertPurchase(
    users_userid : str=Form(...), purchasePrice : str=Form(...), PurchaseQuanity : str=Form(...), PurchaseDate : str=Form(...), 
    PurchaseDeliveryStatus : str=Form(...), products_productsCode : str=Form(...), store_storeCode : str=Form(...)):
        try:
            conn = connect()
            curs = conn.cursor()
            sql = 'INSERT INTO purchase (users_userid, purchasePrice, PurchaseQuanity, PurchaseDate, PurchaseDeliveryStatus, products_productsCode, store_storeCode) VALUES (%s,%s,%s,%s,%s,%s,%s)'
            curs.execute(sql, (users_userid, purchasePrice, PurchaseQuanity, PurchaseDate, PurchaseDeliveryStatus, products_productsCode, store_storeCode))
            conn.commit()
            conn.close()
            return {'result' : 'OK'}
        except Exception as e :
            print("Error : ", e)
            return {"result" : "Error" }
# ----------------------------------------------------------------------------------- #

# --------------        customer_shopping_cart.dart        -------------------------- #
# 1. 장바구니 리스트에서 사용자의 userid 와 결재상태 : '장바구니' 인 data 들을 불러오는 함수
@router.get('/select/shoppingCart/')
async def selectShoppingCart(userid : str):
    conn = connect()
    curs = conn.cursor()
    curs.execute(
        """
        SELECT 
        p.purchaseId, 
        pr.productsName, 
        p.PurchaseQuanity, 
        p.purchasePrice, 
        s.storeName,
        pr.productsCode
        FROM purchase p
        INNER JOIN products pr ON p.products_productsCode = pr.productsCode
        INNER JOIN store s ON p.store_storeCode = s.storeCode
        WHERE p.users_userid = %s AND p.purchaseDeliveryStatus = '장바구니'
        """, (userid,)
    )
    rows = curs.fetchall()
    conn.close()
    result = [{'purchaseId' : row[0], 'productsName' : row[1], 'PurchaseQuanity': row[2], 'purchasePrice' : row[3],'storeName' : row[4], 'productsCode': row[5]}for row in rows]
    return {'results' : result}
# ----------------------------------------------------------------------------------- #
# 2. 장바구니 리스트에서 위의 1. 과 함께 장바구니에 담긴 제품의 Image data를 불러오는 함수
@router.get('/select/shoppingCart/image/{productsCode}')
async def selectShoppingCartImage(productsCode : int):
    try:
        conn = connect()
        curs = conn.cursor()
        curs.execute(
            """
            SELECT 
            productsImage
            FROM products 
            WHERE productsCode = %s
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
# 3. 장바구니 리스트에서 data 를 삭제하는 함수
@router.delete("/delete/purchase/{seq}")
async def deletePurchase(seq : int):
    try :
        conn = connect()
        curs = conn.cursor()
        curs.execute("DELETE FROM Purchase where purchaseId=%s", (seq,))
        conn.commit()
        conn.close()
        return {'result' : "OK"}
    except Exception as e:
        print("Error :", e)
        return {'result' : 'Error'}
# ----------------------------------------------------------------------------------- #
# 4. 장바구니 리스트에서 결제를 진행하여 '장바구니' 상태를 '결재완료' 로 바꾸는 함수
@router.post('/update/Purchase')
async def update(purchaseId : int=Form(...)):
    try :
        conn = connect()
        curs = conn.cursor()
        sql = "UPDATE Purchase SET PurchaseDeliveryStatus= '주문완료' Where purchaseId=%s"
        curs.execute(sql,(purchaseId))
        conn.commit()
        conn.close()
        return {"result" : "OK"}
    except Exception as e:
        print("ERROR :", e)
        return {"result" : "Error"}
# ----------------------------------------------------------------------------------- #
# --------------        customer_purchase_list.dart        -------------------------- #
# 사용자가 구매한 제품의 상태가 '장바구니' 가 아닌 데이터 들을 불러오는 함수
@router.get('/select/Purchase/')
async def selectPurchase(userid : str):
    conn = connect()
    curs = conn.cursor()
    curs.execute(
        """
        SELECT 
        p.purchaseId, 
        pr.productsName, 
        p.PurchaseQuanity, 
        p.purchasePrice, 
        s.storeName,
        pr.productsCode,
        P.PurchaseDeliveryStatus,
        p.PurchaseDate
        FROM purchase p
        INNER JOIN products pr ON p.products_productsCode = pr.productsCode
        INNER JOIN store s ON p.store_storeCode = s.storeCode
        WHERE p.users_userid = %s AND p.purchaseDeliveryStatus != '장바구니'
        """, (userid,)
    )
    rows = curs.fetchall()
    conn.close()
    result = [{'purchaseId' : row[0], 'productsName' : row[1], 'PurchaseQuanity': row[2], 'purchasePrice' : row[3],'storeName' : row[4], 'productsCode': row[5], 'PurchaseDeliveryStatus' : row[6], 'PurchaseDate' : row[7]}for row in rows]
    return {'results' : result}
# ----------------------------------------------------------------------------------- #

# --------------        customer_purchase_detail.dart        ------------------------ #
# 사용자의 결제 내역에서 선택된 결제 정보를 상세보기로 출력하기 위해 data 를 불러오는 함수
@router.get('/select/selectedPurchase/')
async def selectSelectedPurchase(purchaseId : str):
    conn = connect()
    curs = conn.cursor()
    curs.execute(
        """
        SELECT 
        pu.purchaseId,
        p.productsName,
        p.productsColor,
        p.productsSize,
        pu.purchasePrice,
        pu.purchaseQuanity,
        pu.purchaseDeliveryStatus,
        pu.PurchaseDate,
        s.storeName
        FROM purchase pu
        JOIN products p ON pu.products_productsCode = p.productsCode
        LEFT JOIN productRegistration pr ON p.productsCode = pr.products_productsCode
        JOIN store s ON pu.store_storeCode = s.storeCode
        WHERE pu.purchaseId = %s
        """, (purchaseId,))
    rows = curs.fetchall()
    conn.close()
    result = [{'purchaseId' : row[0], 'productsName' : row[1], 'productsColor': row[2], 'productsSize' : row[3],'purchasePrice' : row[4], 'purchaseQuanity': row[5], 'PurchaseDeliveryStatus' : row[6], 'PurchaseDate' : row[7], 'storeName' : row[8]}for row in rows]
    return {'results' : result}
# ----------------------------------------------------------------------------------- #
# 2. 사용자가 선택한 결제내역의 제품 이미지를 상세보기 페이지로 보내주는 함수
@router.get('/select/selectedPurchase/image/{purchaseId}')
async def selectSelectedPurchaseImage(purchaseId : str):
    try:
        conn = connect()
        curs = conn.cursor()
        curs.execute(
        """
        SELECT 
        p.productsImage
        FROM purchase pu
        JOIN products p ON pu.products_productsCode = p.productsCode
        LEFT JOIN productRegistration pr ON p.productsCode = pr.products_productsCode
        JOIN store s ON pu.store_storeCode = s.storeCode
        WHERE pu.purchaseId = %s
        """, (purchaseId,))
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

# ----------------        customer_select_store.dart        ------------------------- #
# 1. 대리점 선택 화면에서 전체 대리점의 data 를 불러오는 함수
@router.get("/select/store")
async def selectStore():
    conn = connect()
    curs = conn.cursor()
    curs.execute("SELECT * FROM store")
    rows = curs.fetchall()
    conn.close()
    result = [{'storeCode':row[0], 'storeName':row[1], 'longitude' : row[2], 'latitude' : row[3], 'address' : row[4]}for row in rows]
    return {'results' : result}
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


