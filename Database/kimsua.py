#2팀 팀원 김수아 서버 파일 

#sqllite로 개발한 소스 파이썬 서버 프로그래밍으로 바꾸기

#2025_05_17 
# 사진 리스트를  바이트로 바꾸기 위해 import pickle 추가 
# post ,product 부분 작성 


#----import-----
import pickle
from fastapi import APIRouter, UploadFile,Request, File, Form
from fastapi.responses import Response,JSONResponse
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import List
import pymysql
import base64
import json
#ip선언
ip = "127.0.0.1"
router = APIRouter()

# MySQL server connect()
def connect():
    return pymysql.connect(
        host=ip,
        user="root",
        password="qwer1234",
        db="mydb",
        charset="utf8"
    )
# post 관련  : ----------------------
# 등록 
@router.post("/insert/products/post")
async def insert_post( ptitle: str =Form(...),introductionPhoto : UploadFile = Form(...),products_productsCode : int = Form(...),users_userid : str = Form(...),contentBlocks:List[UploadFile] = File(...)):
    try:
        image_data = await introductionPhoto.read()
        content_data_list = []
        for file in contentBlocks:
            content_data_list.append(await file.read())
        conn = connect()
        curs = conn.cursor()
        serialized_content = pickle.dumps(content_data_list)
        sql = "INSERT INTO productRegistration(ptitle,introductionPhoto,products_productsCode,users_userid,contentBlocks) VALUES (%s,%s,%s,%s,%s)"
        curs.execute(sql,(ptitle,image_data,products_productsCode,users_userid,serialized_content))
        conn.commit()
        conn.close()
        return{"result" : "OK"}
    except Exception as e:
        print("Error : ",e)
        return{"resule":"Error"}

#검색 [물건 게시글 리스트]
@router.get("/select/products/post/list")
async def select_product_posts():
    try:
        conn = connect()
        curs = conn.cursor()
        sql = """
            SELECT pr.ptitle, pr.users_userid, p.productsName
            FROM productRegistration pr
            JOIN products p ON pr.products_productsCode = p.productsCode
        """
        curs.execute(sql)
        rows = curs.fetchall()
        conn.close()
        result = [{'ptitle' :row[0],'paUserid' : row[1],'productsName' : row[2]}for row in rows]
        
        return JSONResponse(content=result)

    except Exception as e:
        print("Error:", e)
        return JSONResponse(status_code=500, content={"result": "Error", "detail": str(e)})

#게시글 작성할 물건 검색 
@router.get("/select/products/post")
async def get_products():
    try:
        conn = connect()
        curs = conn.cursor()
        sql = """
        SELECT 
        MIN(productsCode) AS productsCode,
        productsName,
        MAX(productsColor) AS productsColor,
        MAX(productsSize) AS productsSize,
        MAX(productsOPrice) AS productsOPrice,
        MAX(productsPrice) AS productsPrice
        FROM products
        GROUP BY productsName;

        """
        curs.execute(sql)
        rows = curs.fetchall()
        conn.close()
        result = [{'productsCode' :row[0],'productsName' : row[1],'productsColor' : row[2],'productsSize' :row[3],'productsOPrice':row[4],'productsPrice':row[5]}for row in rows]

        return {"result" :result }
    except Exception as e:
        return {"result": "Error", "detail": str(e)}
    

# product 관련  : ----------------------
# 등록 

@router.post('/insert/products')
async def insert_products(productsName : str =Form(...),productsColor : str = Form(...),productsSize : int = Form(...),productsOPrice : int = Form(...),productsPrice : str = Form(...),productsImage:UploadFile = File(...)):
    try:
        image_data = await productsImage.read()
        conn = connect()
        curs = conn.cursor()
        sql = "INSERT INTO products(productsName,productsColor,productsSize,productsOPrice,productsPrice,productsImage) VALUES (%s,%s,%s,%s,%s,%s)"
        curs.execute(sql,(productsName,productsColor,productsSize,productsOPrice,productsPrice,image_data))
        conn.commit()
        conn.close()
        return{"result" : "OK"}
    except Exception as e:
        print("Error : ",e)
        return{"resule":"Error"}
    

# 물건 조회
@router.get("/select/products")
async def select_all_products():
    try:
        conn = connect()
        curs = conn.cursor()

        sql = "SELECT productsCode, productsName, productsColor, productsSize, productsOPrice, productsPrice FROM products"
        curs.execute(sql)
        rows = curs.fetchall()
        conn.close()
        result = [{'productsCode' :row[0],'productsName' : row[1],'productsColor' : row[2],'productsSize' :row[3],'productsOPrice':row[4],'productsPrice':row[5]}for row in rows]

        return {"result" :result }

    except Exception as e:
        print("Error:", e)
        return {"result": "Error"}
# 해당 코드에 해당하는 원가 금액 조회
@router.get("/select/products/productsOPrice/{productsCode}")
async def select_products_productsOPrice(productsCode : int):
    try:
        conn = connect()
        curs = conn.cursor()
        sql = "SELECT productsOPrice FROM products WHERE productsCode = %s"
        curs.execute(sql,(productsCode,))
        result = curs.fetchall()
        return {"result" :result}

    except Exception as e:
        print("Error:", e)
        return {"result": "Error"}
    
# 해당 이름에 해당하는 물건 조회 
@router.get("/select/products/{productsName}")
async def select_all_products(productsName : str):
    try:
        conn = connect()
        curs = conn.cursor()
        sql = "SELECT productsCode, productsName, productsColor, productsSize, productsOPrice, productsPrice FROM products WHERE productsName LIKE %s OR productsCode LIKE %s"
        like_pattern = f"%{productsName}%"
        curs.execute(sql, (like_pattern, like_pattern))
        rows = curs.fetchall()
        conn.close()
        result = [{'productsCode' :row[0],'productsName' : row[1],'productsColor' : row[2],'productsSize' :row[3],'productsOPrice':row[4],'productsPrice':row[5]}for row in rows]

        return {"result" :result }

    except Exception as e:
        print("Error:", e)
        return {"result": "Error"}

# manufacturers 관련  : ----------------------
# 제조사
# 등록 

@router.post('/insert/manufacturers')
async def insert_products(manufacturerName : str =Form(...)):
    try:
        conn = connect()
        curs = conn.cursor()
        sql = "INSERT INTO manufacturers(manufacturerName) VALUES (%s)"
        curs.execute(sql,(manufacturerName,))
        conn.commit()
        conn.close()
        return{"result" : "OK"}
    except Exception as e:
        print("Error : ",e)
        return{"resule":"Error"}
# 검색 
@router.get("/select/manufacturers")
async def select_manufacturers():
    try:
        conn = connect()
        curs = conn.cursor()
        sql = "SELECT manufacturerName FROM manufacturers"
        curs.execute(sql)
        rows = curs.fetchall()
        conn.close()
        return {"result": [row[0] for row in rows]}
    except Exception as e:
        print("Error : ",e)
        return{"result":"Error"}
    

    

# 재고 관련  : ----------------------

#본사에 있는 재고량
@router.post("/select/currentStock")
async def selete_currentStock(productsCode :str = Form(...)):
    try:
        conn = connect()
        curs = conn.cursor()
        # 입고 수량 확인 
        sql = "SELECT SUM(stockReceiptsQuantityReceived) AS totalReceived FROM stockReceipts WHERE products_productsCode = %s "
        curs.execute(sql,(productsCode,))
        sSum = curs.fetchone()[0] or 0
        # 출고 수량 확인 
        sql = "SELECT SUM(dispatchedQuantity) AS totalReceived FROM dispatch WHERE Purchase_products_productsCode = %s "
        curs.execute(sql,(productsCode,))
        oSum = curs.fetchone()[0] or 0
        return {"result": sSum-oSum}
    except Exception as e:
        print("Error : ",e)
        return{"result":"Error"}
    
#입고 등록 
@router.post('/insert/products/stockReceipts')
async def insert_stockReceipts(stockReceiptsQuantityReceived : int =Form(...),stockReceiptsReceipDate : str = Form(...),manufacturers_manufacturerName : str = Form(...),users_userid : str = Form(...),products_productsCode : int = Form(...)):
    try:
        conn = connect()
        curs = conn.cursor()
        sql = "INSERT INTO stockReceipts(stockReceiptsQuantityReceived,stockReceiptsReceipDate,manufacturers_manufacturerName,users_userid,products_productsCode) VALUES (%s,%s,%s,%s,%s)"
        curs.execute(sql,(stockReceiptsQuantityReceived,stockReceiptsReceipDate,manufacturers_manufacturerName,users_userid,products_productsCode))
        conn.commit()
        conn.close()
        return{"result" : "OK"}
    except Exception as e:
        print("Error : ",e)
        return{"result":"Error"}
#입고 검색
@router.post('/select/products/stockReceipts')
async def select_stockReceipts():
    try:
        conn = connect()
        curs = conn.cursor()
        sql = "SELECT * FROM stockReceipts"
        curs.execute(sql)
        rows = curs.fetchall()
        conn.close()
        result = [{'stockReceiptsQuantityReceived' :row[0],'stockReceiptsReceipDate' : row[1],'manufacturers_manufacturerName' : row[2],'users_userid' :row[3],'products_productsCode':row[4],}for row in rows]

        return{"result" : result}
    except Exception as e:
        print("Error : ",e)
        return{"result":"Error"}

#출고 등록
@router.post('/insert/products/dispatch')
async def insert_products_dispath(dispatchedQuantity : int =Form(...),dispatchDate : str = Form(...),Purchase_purchaseId: int = Form(...),users_userid : str = Form(...),Purchase_users_userid : str = Form(...),Purchase_store_storeCode :int =Form(...),Purchase_products_productsCode:int =Form(...)):
    try:
        conn = connect()
        curs = conn.cursor()
        sql = "INSERT INTO dispatch(dispatchedQuantity,dispatchDate,Purchase_purchaseId,users_userid,Purchase_users_userid,Purchase_store_storeCode,Purchase_products_productsCode) VALUES (%s,%s,%s,%s,%s,%s,%s)"
        curs.execute(sql,(dispatchedQuantity,dispatchDate,Purchase_purchaseId,users_userid,Purchase_users_userid,Purchase_store_storeCode,Purchase_products_productsCode))
        conn.commit()
        conn.close()
        return{"result" : "OK"}
    except Exception as e:
        print("Error : ",e)
        return{"result":"Error"}
    
#출고 검색
@router.post('/select/products/dispatch')
async def select_dispatch():
    try:
        conn = connect()
        curs = conn.cursor()
        sql = "SELECT dispatchedQuantity,dispatchDate,users_userid,Purchase_store_storeCode,Purchase_products_productsCode FROM dispatch"
        curs.execute(sql)
        rows = curs.fetchall()
        conn.close()
        result = [{'dispatchedQuantity' :row[0],'dispatchDate' : row[1],'users_userid' : row[2],'Purchase_store_storeCode' :row[3],'Purchase_products_productsCode':row[4],}for row in rows]

        return{"result" : result}
    except Exception as e:
        print("Error : ",e)
        return{"result":"Error"}

# 대리점 관련 : ---------------------
#등록 
@router.post('/insert/store')
async def insert_store(storeCode : int =Form(...),storeName : str = Form(...),longitude : float = Form(...),latitude : float = Form(...),address : str = Form(...)):
    try:
        conn = connect()
        curs = conn.cursor()
        sql = "INSERT INTO store(storeCode,storeName,longitude,latitude,address) VALUES (%s,%s,%s,%s,%s)"
        curs.execute(sql,(storeCode,storeName,longitude,latitude,address))
        conn.commit()
        conn.close()
        return{"result" : "OK"}
    except Exception as e:
        print("Error : ",e)
        return{"result":"Error"}
#중복 검색 
@router.get("/select/store/{storeCode}")
async def select_store_1(storeCode : int):
    try:
        conn = connect()
        curs = conn.cursor()
        sql = "SELECT manufacturerName FROM store WHERE sstoreCode = %s"
        curs.execute(sql,(storeCode,))
        rows = curs.fetchall()
        conn.close()
        return {"result": [row[0] for row in rows]}
    except Exception as e:
        print("Error : ",e)
        return{"result":"Error"}
    
#대리점 검색 
@router.get("/select/store")
async def select_store():
    try:
        conn = connect()
        curs = conn.cursor()
        sql = "SELECT storeName,storeCode FROM store"
        curs.execute(sql)
        rows = curs.fetchall()
        conn.close()
        return {"result": [{'storeName' : row[0],'storeCode' :row[1]} for row in rows]}
    except Exception as e:
        print("Error : ",e)
        return{"result":"Error"}
    
# 구매 관련 : ---------------------
#대리점에 들어오면 구매 완료 되어 있는 물건 찾기 
@router.post("/select/Purchase/store")
async def select_Purchase_store(store_storeCode :int=Form(...),products_productsCode :int =Form(...)):
    try:
        conn = connect()
        curs = conn.cursor()
        sql = "SELECT purchaseId,users_userid,PurchaseQuanity FROM Purchase WHERE store_storeCode = %s AND PurchaseDeliveryStatus = '주문완료' AND products_productsCode =%s"
        curs.execute(sql,(store_storeCode,products_productsCode))
        rows = curs.fetchall() 
        conn.close()
        return {"result": [{'purchaseId' : row[0],'users_userid' :row[1],'PurchaseQuanity':row[2]} for row in rows]}
    except Exception as e:
        print("Error : ",e)
        return{"result":"Error"}
    
#출고 후 주문 상태 업데이트 
@router.post("/update/Purchase/state")
async def update_Purchase_state(purchaseId:int =Form(...)):
    try:
        conn = connect()
        curs = conn.cursor()
        sql = "UPDATE  Purchase SET PurchaseDeliveryStatus ='본사출고완료' WHERE purchaseId =%s"
        curs.execute(sql,(purchaseId,))
        conn.commit()
        conn.close()
        return {"result": "OK"}
    except Exception as e:
        print("Error : ",e)
        return{"result":"Error"}
    
# 발주 관련 : ---------------------
#발주 등록
@router.post('/insert/oders')
async def insert_oders(orderId : int =Form(...),orderStatus : str = Form(...),orderQuantity : str = Form(...),orderDate : str = Form(...),manufacturers_manufacturerName :str = Form(...),users_userid :str = Form(...),products_productsCode:int = Form(...)):
    try:
        conn = connect()
        curs = conn.cursor()
        sql = "INSERT INTO oders(orderId,orderStatus,orderQuantity,orderDate,manufacturers_manufacturerName,users_userid,products_productsCode) VALUES (%s,%s,%s,%s,%s,%s,%s)"
        curs.execute(sql,(orderId,orderStatus,orderQuantity,orderDate,manufacturers_manufacturerName,users_userid,products_productsCode))
        conn.commit()
        conn.close()
        return{"result" : "OK"}
    except Exception as e:
        print("Error : ",e)
        return{"result":"Error"}
    

# 발주서 관련 : ---------------------
# 발주서 등록 
@router.post('/insert/oders/createApprovalDocument')
async def insert_oders_createApprovalDocument(title : str =Form(...),content : str = Form(...),date : str = Form(...),approvalRequestExpense:str= Form(...),users_userid :str = Form(...),jobGradeCode :int = Form(...),checkGradeCode : int = Form(...),oders_orderId :int =Form(...)):
    try:
        conn = connect()
        curs = conn.cursor()
        sql = "INSERT INTO oders(title,content,date,approvalRequestExpense,users_userid,jobGradeCode,checkGradeCode,oders_orderId) VALUES (%s,%s,%s,%s,%s,%s,%s,%s)"
        curs.execute(sql,(title,content,date,approvalRequestExpense,users_userid,jobGradeCode,checkGradeCode,oders_orderId))
        conn.commit()
        conn.close()
        return{"result" : "OK"}
    except Exception as e:
        print("Error : ",e)
        return{"result":"Error"}

# 작성자 직급을 들고 옴 

@router.get("/select/gradejobcode/{users_userid}")
async def select_gradejobcode_userid(users_userid:str):
    try:
        conn = connect()
        curs = conn.cursor()
        sql = "SELECT grade_jobGradeCode FROM affiliation WHERE users_userid = %s "
        curs.execute(sql,(users_userid,))
        rows = curs.fetchall() 
        conn.close()
        return {"result": rows[0]}
    except Exception as e:
        print("Error : ",e)
        return{"result":"Error"}

#직급 전체 검색 
@router.get("/select/gradejobcode")
async def select_gradejobcode():
    try:
        conn = connect()
        curs = conn.cursor()
        sql = "SELECT * FROM grade"
        curs.execute(sql)
        rows = curs.fetchall()
        conn.close()
        return {"result": [{'jobGradeCode' : row[0],"gradeName" : row[1]} for row in rows]}
    except Exception as e:
        print("Error : ",e)
        return{"result":"Error"}

#발주 그룹번호 만들기 
@router.get("/select/oders/groubby")
async def select_oders_groubby():
    try:
        conn = connect()
        curs = conn.cursor()
        curs.execute("SELECT MAX(orderID) as maxId FROM oders")
        result = curs.fetchall()
        conn.close()
        return {"result" : 0 if result == "" else  result}
    except Exception as e:
        print("Error : ",e)
        return{"result":"Error"}

#approvalStep 승인 등록 
@router.post("/insert/approvalStep")
async def insert_approvalStep(documentId : int= Form(...),):
    try:
        conn = connect()
        curs = conn.cursor()
        sql = "INSERT INTO oders(documentId,content,date,approvalRequestExpense,users_userid,jobGradeCode,checkGradeCode,oders_orderId) VALUES (%s,%s,%s,%s,%s,%s,%s,%s)"
        curs.execute(sql)
        conn.commit()
        conn.close()
        return{"result" : "OK"}
    except Exception as e:
        print("Error : ",e)
        return{"result":"Error"}



