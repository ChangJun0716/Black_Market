#2팀 팀원 김수아 서버 파일 

#sqllite로 개발한 소스 파이썬 서버 프로그래밍으로 바꾸기

#2025_05_17 
# 원래는 없었던 디비에 Map 형태로 보내는데 Map 안에 Map을 넣어 이미지 여러장을 리스트로 전달하는 방식 

#----import-----
from fastapi import APIRouter, UploadFile, File, Form
from fastapi.responses import Response
from pydantic import BaseModel
import pymysql
#ip선언
ip = "127.0.0.1";
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

