from fastapi import APIRouter, Form, Query 
from fastapi.responses import Response
import pymysql 


router = APIRouter() 
ip = "127.00.0.1"

def connect():
        return pymysql.connect(
            host=ip, 
            user="root",
            password="qwer1234", 
            db="mydb",           
            charset="utf8",
        )

# --- 대리점 관리 관련 API 엔드포인트 ---

# 특정 사용자의 소속 대리점 정보 조회 API
@router.get("/users/{user_id}/store")
async def get_user_store(user_id: str):
    conn = connect()
    if conn is None:
        return {"result": "Error", "message": "Database connection error"}
    try:
        with conn.cursor() as cursor:
            sql = """
            SELECT s.storeCode, s.storeName
            FROM store s
            JOIN daffiliation d ON s.storeCode = d.store_storeCode
            WHERE d.users_userid1 = %s
            """
            cursor.execute(sql, (user_id,))
            store_info = cursor.fetchone()
            if store_info:
                response_data = {
                    "result": "OK",
                    "storeInfo": {
                        "storeCode": str(store_info[0]),
                        "storeName": store_info[1]     
                    }
                }
                return response_data 
            else:
                 return {"result": "Error", "message": "Store information not found for this user"} # 정보 없음 오류 반환

    except Exception as e:
        print(f"소속 대리점 조회 API 오류: {e}")
        return {"result": "Error", "message": f"An error occurred fetching store info: {e}"} # 오류 반환
    finally:
        if conn:
            conn.close() # 연결 닫기

# 입고 예정 제품 조회 API
@router.get("/store/scheduled-products/")
async def get_scheduled_products(date: str = Query(..., description="날짜 (YYYY-MM-DD)"), store_code: str = Query(..., description="대리점 코드")):
    conn = connect()
    if conn is None:
        return {"result": "Error", "message": "Database connection error"}

    try:
        store_code_int = int(store_code) # int로 변환
    except ValueError:
        return {"result": "Error", "message": "Invalid store_code format. Must be an integer."} # 형식 오류 반환

    try:
        with conn.cursor() as cursor:
            # 쿼리 결과 컬럼 순서 중요! Flutter에서 사용할 이름 순서대로 맞추는 것이 좋습니다.
            sql = """
            SELECT
                p.purchaseId,               -- 0: int
                p.PurchaseDate,             -- 1: String
                p.PurchaseQuanity,          -- 2: int
                p.PurchaseCardId,           -- 3: String?
                s.storeCode,                -- 4: int
                p.PurchaseDeliveryStatus,   -- 5: String
                pr.productsCode,            -- 6: int
                CAST(p.purchasePrice AS SIGNED), -- 7: int
                pr.productsOPrice,          -- 8: int
                p.users_userid,             -- 9: String
                pr.productsColor,           -- 10: String
                pr.productsName,            -- 11: String
                pr.productsSize,            -- 12: int
                u.name,                     -- 13: String
                s.storeName                 -- 14: String
            FROM Purchase p
            JOIN products pr ON p.products_productsCode = pr.productsCode
            JOIN users u ON p.users_userid = u.userid
            JOIN store s ON p.store_storeCode = s.storeCode
            WHERE p.PurchaseDate = %s AND s.storeCode = %s
            """
            cursor.execute(sql, (date, store_code_int))
            scheduled_products_tuples = cursor.fetchall() # 결과를 튜플 리스트로 가져옴

            # 튜플 리스트를 딕셔너리 리스트로 매핑
            scheduled_products_list = []
            for row in scheduled_products_tuples:
                scheduled_products_list.append({
                    "purchaseId": row[0], # int
                    "purchaseDate": row[1], # String
                    "purchaseQuanity": row[2], # int
                    "purchaseCardId": row[3], # String?
                    "pStoreCode": str(row[4]), # int -> String
                    "purchaseDeliveryStatus": row[5], # String
                    "oproductCode": row[6], # int
                    "purchasePrice": row[7], # int
                    "productsOPrice": row[8], # int
                    "pUserId": row[9], # String
                    "productsColor": row[10], # String
                    "productsName": row[11], # String
                    "productsSize": row[12], # int
                    "customerName": row[13], # String
                    "storeName": row[14] # String
                })

            return {"results": scheduled_products_list} # JSON 자동 변환

    except Exception as e:
        print(f"입고 예정 제품 조회 API 오류: {e}")
        return {"results": [], "message": f"An error occurred fetching scheduled products: {e}"} # 오류 시 빈 리스트 반환
    finally:
        if conn:
            conn.close() # 연결 닫기

# 매장 재고 현황 조회 API
@router.get("/store/inventory/")
async def get_inventory(start_date: str = Query(..., description="시작 날짜 (YYYY-MM-DD)"), end_date: str = Query(..., description="종료 날짜 (YYYY-MM-DD)"), user_id: str = Query(..., description="사용자 ID (대리점 관리자 ID)")):
     conn = connect()
     if conn is None:
         return {"result": "Error", "message": "Database connection error"}

     try:
         with conn.cursor() as cursor:
             # 쿼리 결과 컬럼 순서 중요!
             sql = """
             SELECT
                 sr.products_productsCode,           -- 0: int
                 pr.productsName,                    -- 1: String
                 pr.productsColor,                   -- 2: String
                 pr.productsSize,                    -- 3: int
                 SUM(sr.stockReceiptsQuantityReceived) -- 4: int
             FROM stockReceipts sr
             JOIN products pr ON sr.products_productsCode = pr.productsCode
             WHERE sr.stockReceiptsReceipDate BETWEEN %s AND %s
             AND sr.users_userid = %s
             GROUP BY sr.products_productsCode, pr.productsName, pr.productsColor, pr.productsSize
             ORDER BY pr.productsName
             """
             cursor.execute(sql, (start_date, end_date, user_id))
             inventory_tuples = cursor.fetchall() # 결과를 튜플 리스트로 가져옴

             # 튜플 리스트를 딕셔너리 리스트로 매핑
             inventory_list = []
             for row in inventory_tuples:
                 inventory_list.append({
                     "sproductCode": row[0], # int
                     "productsName": row[1], # String
                     "productsColor": row[2], # String
                     "productsSize": row[3], # int
                     "receivedQuantity": row[4] # int
                 })

             return {"results": inventory_list} # JSON 자동 변환

     except Exception as e:
         print(f"매장 재고 조회 API 오류: {e}")
         return {"results": [], "message": f"An error occurred fetching inventory: {e}"} # 오류 시 빈 리스트 반환
     finally:
         if conn:
            conn.close() # 연결 닫기

# 픽업 대기 목록 조회 API
@router.get("/store/pickup-ready-orders/")
async def get_pickup_ready_orders(store_code: str = Query(..., description="대리점 코드")):
    conn = connect()
    if conn is None:
        return {"result": "Error", "message": "Database connection error"}

    try:
        store_code_int = int(store_code) # int로 변환
    except ValueError:
        return {"result": "Error", "message": "Invalid store_code format. Must be an integer."} # 형식 오류 반환

    try:
        with conn.cursor() as cursor:
             # 쿼리 결과 컬럼 순서 중요!
            sql = """
            SELECT
                p.purchaseId, -- 0: int
                p.PurchaseDate, -- 1: String
                p.PurchaseQuanity, -- 2: int
                pr.productsCode, -- 3: int
                pr.productsColor, -- 4: String
                pr.productsSize, -- 5: int
                u.name, -- 6: String
                p.PurchaseDeliveryStatus -- 7: String
            FROM Purchase p
            JOIN products pr ON p.products_productsCode = pr.productsCode
            JOIN users u ON p.users_userid = u.userid
            WHERE p.store_storeCode = %s
            AND p.PurchaseDeliveryStatus = %s
            """
            pickup_status_value = 'Ready for Pickup' # TODO: 실제 상태 값으로 변경하세요.

            cursor.execute(sql, (store_code_int, pickup_status_value))
            pickup_orders_tuples = cursor.fetchall() # 결과를 튜플 리스트로 가져옴

            # 튜플 리스트를 딕셔너리 리스트로 매핑
            pickup_orders_list = []
            for row in pickup_orders_tuples:
                 pickup_orders_list.append({
                    "purchaseId": row[0], # int
                    "purchaseDate": row[1], # String
                    "purchaseQuanity": row[2], # int
                    "oproductCode": row[3], # int
                    "productsColor": row[4], # String
                    "productsSize": row[5], # int
                    "customerName": row[6], # String
                    "purchaseDeliveryStatus": row[7] # String
                 })

            return {"results": pickup_orders_list} # JSON 자동 변환

    except Exception as e:
        print(f"픽업 대기 목록 조회 API 오류: {e}")
        return {"results": [], "message": f"An error occurred fetching pickup orders: {e}"} # 오류 시 빈 리스트 반환
    finally:
        if conn:
            conn.close() # 연결 닫기

# 구매 상태 업데이트 API
@router.post("/purchase/{purchase_id}/update-status/")
async def update_purchase_status(purchase_id: int, new_status: str = Form(...)):
     conn = connect()
     if conn is None:
         return {"result": "Error", "message": "Database connection error"}

     try:
         with conn.cursor() as cursor:
             # UPDATE 쿼리
             sql = """
             UPDATE Purchase
             SET PurchaseDeliveryStatus = %s
             WHERE purchaseId = %s
             """
             cursor.execute(sql, (new_status, purchase_id))

             rows_affected = cursor.rowcount

             conn.commit() # 변경사항 커밋

             if rows_affected > 0:
                 return {"result": "OK", "message": f"Successfully updated status for purchase ID {purchase_id}. Rows affected: {rows_affected}"}
             else:
                 # 변경되지 않았더라도 성공 메시지 반환 (예시 방식 따름)
                 return {"result": "OK", "message": f"No purchase found with ID {purchase_id} or status is already {new_status}. Rows affected: {rows_affected}"}

     except Exception as e:
         if conn:
            conn.rollback() # 오류 발생 시 롤백
         print(f"구매 상태 업데이트 API 오류: {e}")
         return {"result": "Error", "message": f"An error occurred updating purchase status: {e}"} # 오류 반환
     finally:
         if conn:
            conn.close() # 연결 닫기

# 매장 반품 목록 조회 API
@router.get("/store/returns/")
async def get_returns(date: str = Query(..., description="날짜 (YYYY-MM-DD)"), user_id: str = Query(..., description="반품 신청 사용자 ID")):
     conn = connect()
     if conn is None:
         return {"result": "Error", "message": "Database connection error"}

     try:
         with conn.cursor() as cursor:
             # 쿼리 결과 컬럼 순서 중요!
             sql = """
             SELECT
                 r.returnCategory, -- 0: String
                 r.returnDate, -- 1: String
                 r.prosessionStateus, -- 2: String (스키마 오타 유지)
                 r.returnReason, -- 3: String
                 r.resolution, -- 4: String
                 r.recordDate, -- 5: String
                 r.users_userid, -- 6: String
                 r.Purchase_purchaseId, -- 7: int
                 r.Purchase_products_productsCode, -- 8: int
                 pr.productsName, -- 9: String
                 pr.productsColor, -- 10: String
                 pr.productsSize, -- 11: int
                 CAST(pr.productsPrice AS SIGNED), -- 12: int
                 pr.productsOPrice -- 13: int
             FROM return r
             JOIN products pr ON r.Purchase_products_productsCode = pr.productsCode
             WHERE r.returnDate = %s
             AND r.users_userid = %s
             """
             cursor.execute(sql, (date, user_id))
             returns_tuples = cursor.fetchall() # 결과를 튜플 리스트로 가져옴

             # 튜플 리스트를 딕셔너리 리스트로 매핑
             returns_list = []
             for i, row in enumerate(returns_tuples):
                 # 임시 고유 ID 생성 (returnCode 역할을 할 수 있도록)
                 temp_return_id = f"{row[6]}_{row[1]}_{row[7]}_{row[8]}_{i}" # user_id_date_purchase_id_product_code_index

                 returns_list.append({
                     "returnCode": temp_return_id, # 임시 ID (String)
                     "returnCategory": row[0], # String
                     "returnDate": row[1], # String
                     "processionStatus": row[2], # String (스키마 오타 유지)
                     "returnReason": row[3], # String
                     "resolution": row[4], # String
                     "recordDate": row[5], # String
                     "ruserId": row[6], # String
                     "relatedPurchaseId": row[7], # int (관련된 구매 ID)
                     "rProductCode": row[8], # int (반품된 제품 코드)
                     "productsName": row[9], # String
                     "productsColor": row[10], # String
                     "productsSize": row[11], # int
                     "productsPrice": row[12], # int
                     "productsOPrice": row[13] # int
                 })


             return {"results": returns_list} # JSON 자동 변환

     except Exception as e:
         print(f"매장 반품 목록 조회 API 오류: {e}")
         return {"results": [], "message": f"An error occurred fetching returns: {e}"} # 오류 시 빈 리스트 반환
     finally:
         if conn:
            conn.close() # 연결 닫기

# 반품 신청 등록 API
@router.post("/returns/")
async def create_return_application(
    returnCategory: str = Form(...),
    returnDate: str = Form(...),
    prosessionStatus: str = Form(...), # 스키마 오타 유지
    returnReason: str = Form(...),
    resolution: str = Form(...),
    recordDate: str = Form(...),
    ruserId: str = Form(...), # return.users_userid 에 해당
    purchaseId: int = Form(...), # return.Purchase_purchaseId 에 해당
    purchaseUserId: str = Form(...), # return.Purchase_users_userid 에 해당
    purchaseStoreCode: int = Form(...), # return.Purchase_store_storeCode 에 해당
    purchaseProductCode: int = Form(...) # return.Purchase_products_productsCode 에 해당
):
     conn = connect()
     if conn is None:
         return {"result": "Error", "message": "Database connection error"}

     try:
         with conn.cursor() as cursor:
             # INSERT 쿼리
             sql = """
             INSERT INTO return (returnCategory, returnDate, prosessionStateus, returnReason, resolution, recordDate, users_userid, Purchase_purchaseId, Purchase_users_userid, Purchase_store_storeCode, Purchase_products_productsCode)
             VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
             """
             # 쿼리 실행 파라미터 순서 (스키마 순서와 일치)
             cursor.execute(sql, (
                 returnCategory,
                 returnDate,
                 prosessionStatus,
                 returnReason,
                 resolution,
                 recordDate,
                 ruserId,
                 purchaseId,
                 purchaseUserId,
                 purchaseStoreCode,
                 purchaseProductCode
             ))

             conn.commit() # 변경사항 커밋

             return {"result": "OK", "message": "Return application created successfully"} # 성공 메시지 반환

     except Exception as e:
         if conn:
            conn.rollback() # 오류 발생 시 롤백
         print(f"반품 신청 등록 API 오류: {e}")
         return {"result": "Error", "message": f"An error occurred creating return application: {e}"} # 오류 반환
     finally:
         if conn:
            conn.close() # 연결 닫기


# 로그인 API (inhwan.py 라우터에 포함)
@router.post("/login") # POST 요청
async def login(userid: str = Form(...), password: str = Form(...)):
    conn = connect()
    if conn is None:
        return {"result": "Error", "message": "Database connection error"}

    try:
        with conn.cursor() as cursor:
            # users 테이블에서 userid와 password가 일치하는 사용자 조회
            # 쿼리 결과 순서: userid, name, memberType
            sql = "SELECT userid, name, memberType FROM users WHERE userid = %s AND password = %s"
            cursor.execute(sql, (userid, password))
            user_tuple = cursor.fetchone() # 결과 하나를 튜플로 가져옴

            if user_tuple:
                # 로그인 성공
                response_data = {
                    "result": "OK",
                    "user": {
                        "userId": user_tuple[0], # String
                        "name": user_tuple[1], # String
                        "memberType": int(user_tuple[2]) # String -> int
                    }
                }

                # 대리점 관리자인 경우 (memberType >= 3 가정) 소속 대리점 정보 추가 조회
                if int(user_tuple[2]) >= 3:
                     # 쿼리 결과 순서: storeCode, storeName
                    store_sql = """
                    SELECT s.storeCode, s.storeName
                    FROM store s
                    JOIN daffiliation d ON s.storeCode = d.store_storeCode
                    WHERE d.users_userid1 = %s
                    """
                    cursor.execute(store_sql, (user_tuple[0],)) # 조회된 userid 사용
                    store_info_tuple = cursor.fetchone()

                    if store_info_tuple:
                        response_data["user"]["storeInfo"] = {
                            "storeCode": str(store_info_tuple[0]), # int -> String
                            "storeName": store_info_tuple[1] # String
                        }
                    else:
                         response_data["user"]["storeInfo"] = None
                         print(f"경고: 사용자 {user_tuple[0]} (memberType {user_tuple[2]})는 소속 대리점 정보가 없습니다.") # 로깅

                return response_data # JSON 자동 변환

            else:
                # 로그인 실패 (사용자 ID 또는 비밀번호 불일치)
                return {"result": "Error", "message": "Invalid userid or password"} # 오류 반환 (상태 코드 200)

    except Exception as e:
        print(f"로그인 API 오류: {e}")
        return {"result": "Error", "message": f"An error occurred during login: {e}"} # 오류 반환
    finally:
        if conn:
            conn.close() # 연결 닫기
