from fastapi import APIRouter, Form, Query
from fastapi.responses import Response
import pymysql

router = APIRouter()
ip = "127.0.0.1"

def connect():
        return pymysql.connect(
            host=ip,
            user="root",
            password="qwer1234", # 실제 비밀번호로 변경하세요.
            db="mydb",           # 실제 DB 이름으로 변경하세요.
            charset="utf8mb4",
        )

# --- Function ---

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
            store_info_tuple = cursor.fetchone()
            if store_info_tuple:
                response_data = {
                    "result": "OK",
                    "storeInfo": {
                        "storeCode": str(store_info_tuple[0]),
                        "storeName": store_info_tuple[1]
                    }
                }
                return response_data
            else:
                return {"result": "Error", "message": "Store information not found for this user"}
    except Exception as e:
        print("Error :", e)
        return {"result": "Error"}
    finally:
        if conn:
            conn.close()

# 입고 예정 제품 조회 API
# inhwan.py 파일 내부 get_scheduled_products 함수

# 특정 날짜 및 대리점의 입고 예정 제품 조회 API
@router.get("/store/scheduled-products/")
async def get_scheduled_products(date: str = Query(...), store_code: int = Query(...)): # date VARCHAR, store_code INT
    conn = connect()
    if conn is None:
        return {"result": "Error", "message": "Database connection error"}

    try:
        with conn.cursor() as cursor:
            # SQL 쿼리: 특정 날짜 및 대리점의 입고 예정 제품 조회 (Purchase 테이블 기준)
            sql = """
            SELECT
                p.purchaseId,           -- INT
                p.PurchaseDate,         -- VARCHAR
                p.PurchaseQuanity,      -- INT
                p.products_productsCode AS oproductCode, -- INT
                pr.productsColor,       -- VARCHAR
                pr.productsSize,        -- INT
                c.name AS customerName, -- VARCHAR (고객 이름)
                p.PurchaseDeliveryStatus -- VARCHAR
            FROM
                Purchase p
            JOIN
                products pr ON p.products_productsCode = pr.productsCode
            JOIN
                users c ON p.users_userid = c.userid -- 고객 정보 조인을 위한 users 테이블 (별칭 c)
            WHERE
                p.PurchaseDate = %s AND p.store_storeCode = %s; -- 날짜와 대리점 코드로 필터링
            """ # date는 %s에 바인딩, store_code는 %s에 바인딩

            cursor.execute(sql, (date, store_code)) # date와 store_code는 튜플 형태로 전달
            results = cursor.fetchall()

            # 결과를 딕셔너리 리스트로 변환 (컬럼 이름 매핑)
            # SELECT 절 순서 확인: purchaseId(0), PurchaseDate(1), ..., PurchaseDeliveryStatus(7)
            scheduled_list = []
            for row in results:
                scheduled_list.append({
                    "purchaseId": row[0],
                    "purchaseDate": row[1],
                    "purchaseQuanity": row[2],
                    "oproductCode": row[3],
                    "productsColor": row[4],
                    "productsSize": row[5],
                    "customerName": row[6],
                    "purchaseDeliveryStatus": row[7]
                })

            # 성공 응답 형식 통일: {"result": "OK", "results": [...], "message": "..."}
            message = "입고 예정 제품 목록 조회 성공"
            if not scheduled_list: # 결과 목록이 비어있으면 다른 메시지
                message = "해당 날짜에 입고 예정인 제품이 없습니다."

            return {"result": "OK", "results": scheduled_list, "message": message}

    except Exception as e:
        print("Error :", e) # 에러 로깅
        # 오류 발생 시 클라이언트에 에러 메시지 반환 (API 응답 형식 통일)
        return {"result": "Error", "message": f"입고 예정 제품 조회 중 오류 발생: {e}"}

    finally:
        if conn:
            conn.close()


# 매장 재고 현황 조회 API
# inhwan.py 파일 내부 get_inventory 함수

# 특정 날짜 범위 및 관리자 ID의 매장 재고 현황 조회 API
@router.get("/store/inventory/")
async def get_inventory(start_date: str = Query(...), end_date: str = Query(...), user_id: str = Query(...)):
    conn = connect()
    if conn is None:
        return {"result": "Error", "message": "Database connection error"}

    try:
        with conn.cursor() as cursor:
            # SQL 쿼리: 특정 기간 동안 특정 관리자가 입고 처리한 제품들의 집계 수량 조회
            sql = """
            SELECT
                pr.productsName,          -- 제품 이름 (VARCHAR)
                pr.productsColor,         -- 제품 색상 (VARCHAR)
                pr.productsSize,          -- 제품 사이즈 (INT)
                SUM(s.stockReceiptsQuantityReceived) AS receivedQuantity -- 집계된 수량 (INT)
            FROM
                stockReceipts s
            JOIN
                products pr ON s.products_productsCode = pr.productsCode
            WHERE
                s.stockReceiptsReceipDate BETWEEN %s AND %s
                AND s.users_userid = %s
            GROUP BY
                pr.productsName, pr.productsColor, pr.productsSize; -- 제품별 집계
            """ # 날짜 범위 및 입고 처리 관리자 ID로 필터링

            cursor.execute(sql, (start_date, end_date, user_id))
            results = cursor.fetchall()

            # 결과를 딕셔너리 리스트로 변환 (컬럼 이름 매핑)
            # SELECT 절 순서 확인: productsName(0), productsColor(1), productsSize(2), receivedQuantity(3)
            inventory_list = []
            for row in results:
                inventory_list.append({
                    "productsName": row[0],
                    "productsColor": row[1],
                    "productsSize": row[2], # INT
                    "receivedQuantity": row[3] # INT
                })

            # 성공 응답 형식 통일: {"result": "OK", "results": [...], "message": "..."}
            message = "재고 현황 조회 성공"
            if not inventory_list: # 결과 목록이 비어있으면 다른 메시지
                message = "해당 기간에 입고된 제품이 없습니다."

            return {"result": "OK", "results": inventory_list, "message": message}

    except Exception as e:
        print("Error :", e) # 에러 로깅
        # 오류 발생 시 클라이언트에 에러 메시지 반환 (API 응답 형식 통일)
        return {"result": "Error", "message": f"재고 현황 조회 중 오류 발생: {e}"}

    finally:
        if conn:
            conn.close()


# 픽업 대기 목록 조회 API
# inhwan.py 파일 내부 get_pickup_ready_orders 함수

# 특정 대리점의 픽업 대기 주문 목록 조회 API
@router.get("/store/pickup-ready-orders/")
async def get_pickup_ready_orders(store_code: int = Query(...)): # store_code는 INT
    conn = connect()
    if conn is None:
        return {"result": "Error", "message": "Database connection error"}

    try:
        with conn.cursor() as cursor:
            sql = """
            SELECT
                p.purchaseId,           -- INT
                p.PurchaseDate,         -- VARCHAR
                p.PurchaseQuanity,      -- INT
                p.products_productsCode AS oproductCode, -- INT
                pr.productsColor,       -- VARCHAR
                pr.productsSize,        -- INT
                c.name AS customerName, -- VARCHAR (고객 이름)
                p.PurchaseDeliveryStatus, -- VARCHAR
                p.users_userid AS pUserId -- <--- 관련된 구매의 사용자 ID 추가 (VARCHAR)
            FROM
                Purchase p
            JOIN
                products pr ON p.products_productsCode = pr.productsCode
            JOIN
                users c ON p.users_userid = c.userid -- 고객 정보 조인을 위한 users 테이블 (별칭 c)
            WHERE
                p.store_storeCode = %s
                AND p.PurchaseDeliveryStatus = 'Ready for Pickup'; -- 픽업 대기 상태로 필터링
            """ # store_code는 %s에 바인딩, 'Ready for Pickup'은 고정 문자열

            cursor.execute(sql, (store_code,)) # store_code는 튜플 형태로 전달
            results = cursor.fetchall() # 결과 모두 가져옴

            # 결과를 딕셔너리 리스트로 변환 (컬럼 이름 매핑)
            # SELECT 절 순서 확인: purchaseId(0), PurchaseDate(1), ..., pUserId(8)
            pickup_orders_list = []
            for row in results:
                pickup_orders_list.append({
                    "purchaseId": row[0],
                    "purchaseDate": row[1],
                    "purchaseQuanity": row[2],
                    "oproductCode": row[3],
                    "productsColor": row[4],
                    "productsSize": row[5],
                    "customerName": row[6],
                    "purchaseDeliveryStatus": row[7],
                    "pUserId": row[8] # <--- 가져온 pUserId 값 매핑 추가
                })

            # 성공 응답에 {"result": "OK"} 추가하여 Flutter와 형식 일치
            return {"result": "OK", "results": pickup_orders_list, "message": "픽업 대기 목록 조회 성공"}

    except Exception as e:
        print("Error :", e)
        # 오류 발생 시 클라이언트에 에러 메시지 반환 (API 응답 형식 통일)
        return {"result": "Error", "message": f"픽업 대기 목록 조회 중 오류 발생: {e}"}

    finally:
        if conn:
            conn.close()



# 구매 상태 업데이트 API
@router.post("/purchase/{purchase_id}/update-status/")
async def update_purchase_status(purchase_id: int, new_status: str = Form(...)):
    conn = connect()
    if conn is None:
        return {"result": "Error", "message": "Database connection error"}

    try:
        with conn.cursor() as cursor:
            sql = """
            UPDATE Purchase
            SET PurchaseDeliveryStatus = %s
            WHERE purchaseId = %s
            """
            cursor.execute(sql, (new_status, purchase_id))
            rows_affected = cursor.rowcount
            conn.commit()
            if rows_affected > 0:
                return {"result": "OK", "message": f"Successfully updated status for purchase ID {purchase_id}. Rows affected: {rows_affected}"}
            else:
                return {"result": "OK", "message": f"No purchase found with ID {purchase_id} or status is already {new_status}. Rows affected: {rows_affected}"}
    except Exception as e:
        if conn:
            conn.rollback()
        print("Error :", e)
        return {"result": "Error"} 
    finally:
        if conn:
            conn.close()

# 매장 반품 목록 조회 API
# inhwan.py 파일 내부 get_returns 함수

# 특정 날짜 및 사용자의 반품 기록 조회 API
@router.get("/store/returns/")
async def get_returns(date: str = Query(...), user_id: str = Query(...)):
    conn = connect()
    if conn is None:
        return {"result": "Error", "message": "Database connection error"}

    try:
        with conn.cursor() as cursor:
            sql = """
            SELECT
                r.returnCategory,
                r.returnDate,
                r.prosessionStateus, -- 오타 주의 (스키마 따름)
                r.returnReason,
                r.resolution,
                r.recordDate,
                r.users_userid AS ruserId, -- 반품 신청 사용자 ID (teststoreadmin)
                r.Purchase_purchaseId AS purchaseId, -- 관련된 구매 ID (1004)
                r.Purchase_users_userid AS pUserId, -- 관련된 구매의 사용자 ID (testcustomer1)
                r.Purchase_store_storeCode AS storeCode, -- 관련된 구매의 대리점 코드 (999)
                r.Purchase_products_productsCode AS oproductCode, -- 관련된 구매의 제품 코드 (101)
                pr.productsName, -- 제품 이름
                pr.productsColor, -- 제품 색상
                pr.productsSize -- 제품 사이즈
            FROM
                `return` r
            JOIN
                Purchase p ON r.Purchase_purchaseId = p.purchaseId
                          AND r.Purchase_users_userid = p.users_userid  -- <--- 이 부분을 r.Purchase_users_userid로 수정했습니다.
                          AND r.Purchase_store_storeCode = p.store_storeCode
                          AND r.Purchase_products_productsCode = p.products_productsCode
            JOIN
                products pr ON r.Purchase_products_productsCode = pr.productsCode
            WHERE
                r.returnDate = %s AND r.users_userid = %s;
            """ # 날짜와 반품 신청 사용자 ID로 필터링

            cursor.execute(sql, (date, user_id))
            results = cursor.fetchall()

            # 결과를 딕셔너리 리스트로 변환 (컬럼 이름 매핑)
            # SELECT 절의 순서: returnCategory(0), returnDate(1), ... productsSize(13)
            return_list = []
            for row in results:
                return_list.append({
                    "returnCode": f"{row[6]}_{row[1]}_{row[7]}_{row[10]}", # 임시 고유 ID 생성 (returnCode)
                    "returnCategory": row[0],
                    "returnDate": row[1],
                    "processionStatus": row[2], # 스키마 오타 유지
                    "returnReason": row[3],
                    "resolution": row[4],
                    "recordDate": row[5],
                    "ruserId": row[6],
                    "purchaseId": row[7],
                    "pUserId": row[8],
                    "storeCode": row[9],
                    "oproductCode": row[10],
                    "productsName": row[11],
                    "productsColor": row[12],
                    "productsSize": row[13]
                })

            return {"result": "OK", "results": return_list, "message": "반품 목록 조회 성공"}

    except Exception as e:
        print("Error :", e)
        return {"result": "Error", "message": f"반품 목록 조회 중 오류 발생: {e}"}

    finally:
        if conn:
            conn.close()



# 반품 신청 등록 API
# inhwan.py 파일 내부 add_return 함수

# 반품 신청 API (POST 요청)
@router.post("/returns/")
async def add_return(
    returnCategory: str = Form(...),
    returnDate: str = Form(...),
    prosessionStatus: str = Form(...), # 스키마 오타 주의
    returnReason: str = Form(...),
    resolution: str = Form(...),
    recordDate: str = Form(...),
    ruserId: str = Form(...), # 반품 신청 사용자 ID
    purchaseId: int = Form(...), # 관련 구매 ID
    purchaseUserId: str = Form(...), # 관련 구매 사용자 ID
    purchaseStoreCode: int = Form(...), # 관련 구매 대리점 코드
    purchaseProductCode: int = Form(...) # 관련 구매 제품 코드
):
    conn = connect()
    if conn is None:
        return {"result": "Error", "message": "Database connection error"}

    try:
        with conn.cursor() as cursor:
            # SQL 쿼리 수정: `return` 테이블 이름을 백틱으로 감쌈
            sql = """
            INSERT INTO `return`  -- <--- 여기서 return 테이블 이름을 백틱으로 감쌌습니다.
            (returnCategory, returnDate, prosessionStateus, returnReason,
             resolution, recordDate, users_userid,
             Purchase_purchaseId, Purchase_users_userid, Purchase_store_storeCode,
             Purchase_products_productsCode)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s);
            """

            # INSERT할 데이터 튜플
            # 컬럼 순서에 맞게 값들을 배치합니다.
            values = (
                returnCategory,
                returnDate,
                prosessionStatus, # 스키마 오타 유지
                returnReason,
                resolution,
                recordDate,
                ruserId,
                purchaseId,
                purchaseUserId,
                purchaseStoreCode,
                purchaseProductCode
            )

            cursor.execute(sql, values)

        conn.commit() # 변경사항 커밋

        return {"result": "OK", "message": "반품 신청 성공적으로 접수되었습니다."}

    except Exception as e:
        conn.rollback() # 오류 발생 시 롤백
        print("Error :", e) # 에러 로깅
        # 오류 발생 시 클라이언트에 에러 메시지 반환 (API 응답 형식 통일)
        return {"result": "Error", "message": f"반품 신청 중 오류 발생: {e}"}

    finally:
        if conn:
            conn.close()


# 로그인 API (inhwan.py 라우터에 포함)
@router.post("/login")
async def login(userid: str = Form(...), password: str = Form(...)):
    conn = connect()
    if conn is None:
        return {"result": "Error", "message": "Database connection error"}
    try:
        with conn.cursor() as cursor:
            sql = "SELECT userid, name, memberType FROM users WHERE userid = %s AND password = %s"
            cursor.execute(sql, (userid, password))
            user_tuple = cursor.fetchone()
            if user_tuple:
                response_data = {
                    "result": "OK",
                    "user": {
                        "userId": user_tuple[0],
                        "name": user_tuple[1],
                        "memberType": int(user_tuple[2])
                    }
                }
                # 대리점 관리자인 경우 소속 대리점 정보 추가 조회
                if int(user_tuple[2]) >= 3:
                    store_sql = """
                    SELECT s.storeCode, s.storeName
                    FROM store s
                    JOIN daffiliation d ON s.storeCode = d.store_storeCode
                    WHERE d.users_userid1 = %s
                    """
                    cursor.execute(store_sql, (user_tuple[0],))
                    store_info_tuple = cursor.fetchone()
                    if store_info_tuple:
                        response_data["user"]["storeInfo"] = {
                            "storeCode": str(store_info_tuple[0]),
                            "storeName": store_info_tuple[1]
                        }
                    else:
                        response_data["user"]["storeInfo"] = None
                        print(f"경고: 사용자 {user_tuple[0]} (memberType {user_tuple[2]})는 소속 대리점 정보가 없습니다.")
                return response_data
            else:
                return {"result": "Error", "message": "Invalid userid or password"}
    except Exception as e:
        print("Error :", e)
        return {"result": "Error"} 
    finally:
        if conn:
            conn.close()
