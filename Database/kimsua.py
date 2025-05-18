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
@router.post("/insert/product/post")
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
@router.get("/kimsua/select/products/post/list")
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
        SELECT * FROM products p
        WHERE p.productsCode = (
            SELECT MIN(productsCode)
            FROM products
            WHERE productsName = p.productsName
        )
        GROUP BY p.productsName
        ORDER BY p.productsName
        """
        curs.execute(sql)
        rows = curs.fetchall()
        conn.close()
        return rows
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
    
# 해당 이름에 해당하는 물건 조회 
@router.get("/select/products/{productsName}")
async def select_all_products(productsName : str):
    try:
        conn = connect()
        curs = conn.cursor()
        sql = "SELECT productsCode, productsName, productsColor, productsSize, productsOPrice, productsPrice FROM products WHERE productsName LIKE = %s OR productsCode LIKE = %s"
        like_pattern = f"%{productsName}%"
        curs.execute(sql, (like_pattern,),(like_pattern,))
        rows = curs.fetchall()
        conn.close()
        result = [{'productsCode' :row[0],'productsName' : row[1],'productsColor' : row[2],'productsSize' :row[3],'productsOPrice':row[4],'productsPrice':row[5]}for row in rows]

        return {"result" :result }

    except Exception as e:
        print("Error:", e)
        return {"result": "Error"}