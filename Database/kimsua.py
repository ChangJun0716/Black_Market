#2팀 팀원 김수아 서버 파일 

#sqllite로 개발한 소스 파이썬 서버 프로그래밍으로 바꾸기

#2025_05_17 
# 사진 리스트를 Json으로 보내기 sqllate엔 없던 구문 추가 

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
@router.post("/insert/product")
async def upload_post( ptitle: str =Form(...),introductionPhoto : UploadFile = Form(...),products_productsCode : int = Form(...),users_userid : str = Form(...),contentBlocks:List[UploadFile] = File(...)):
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


@router.get("/kimsua/select/product/posts")
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

        result = []
        for row in rows:
            result.append({
                "ptitle": row[0],          # 게시글 제목
                "paUserid": row[1],        # 작성자 ID
                "productsName": row[2]     # 제품명
            })

        return JSONResponse(content=result)

    except Exception as e:
        print("Error:", e)
        return JSONResponse(status_code=500, content={"result": "Error", "detail": str(e)})


@router.get("/select/products")
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

