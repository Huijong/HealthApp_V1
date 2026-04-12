from fastapi import FastAPI, File, UploadFile, Header, HTTPException, Form, Request
from fastapi.responses import JSONResponse, HTMLResponse, FileResponse
import shutil
import os
import json
from datetime import datetime, timedelta
from motor.motor_asyncio import AsyncIOMotorClient
import firebase_admin
from firebase_admin import credentials, messaging
from pydantic import BaseModel

app = FastAPI()
# ---------------- [보안 설정 추가] ---------------- #
# 허용할 IP 주소들을 리스트에 넣으세요 (본인의 공인 IP)
# ALLOWED_IPS = ["210.94.41.89","0.0.0.1"]
#
#
# @app.middleware("http")
# async def ip_filter_middleware(request: Request, call_next):
#     # 1. Cloudflare를 사용하는 경우 실제 사용자 IP는 'cf-connecting-ip' 헤더에 담겨 옵니다.
#     # 2. 직접 접속하는 경우에는 request.client.host를 사용합니다.
#     client_ip = request.headers.get("cf-connecting-ip") or request.client.host
#
#     # 허용 리스트에 없는 IP라면 403 에러 발생
#     if client_ip not in ALLOWED_IPS:
#         # 로그 확인용 (선택 사항)
#         print(f"차단된 접근 시도: {client_ip}")
#         raise HTTPException(status_code=403, detail="Forbidden: Access denied for this IP.")
#
#     response = await call_next(request)
#     return response


# ------------------------------------------------ #
# 1. 저장 경로 설정
UPLOAD_DIR = "D:/HealthApp_Data"
TEMP_DIR = os.path.join(UPLOAD_DIR, "temp")
if not os.path.exists(UPLOAD_DIR):
    os.makedirs(UPLOAD_DIR)
if not os.path.exists(TEMP_DIR):
    os.makedirs(TEMP_DIR)

# 2. 데이터베이스 연결
client = AsyncIOMotorClient("mongodb://localhost:27017/")
db = client["health_db"]
collection = db["upload_history"]
notices_collection = db["notices"]

# 3. 보안 키
SECRET_API_KEY = "my_private_key_50"

# 4. Firebase Admin 설정
FIREBASE_KEY_PATH = r"D:\HealthApp_Server\service-account.json"
try:
    if not firebase_admin._apps:
        cred = credentials.Certificate(FIREBASE_KEY_PATH)
        firebase_admin.initialize_app(cred)
        print("Firebase Admin이 성공적으로 초기화되었습니다.")
except Exception as e:
    print(f"Firebase 초기화 에러: {e}")

class NoticeRequest(BaseModel):
    title: str
    body: str

@app.post("/admin/send-notice")
async def send_notice(request: NoticeRequest, x_api_key: str = Header(None)):
    if x_api_key != SECRET_API_KEY:
        raise HTTPException(status_code=403, detail="Invalid API Key")
    
    try:
        message = messaging.Message(
            notification=messaging.Notification(
                title=request.title,
                body=request.body,
            ),
            data={
                "click_action": "FLUTTER_NOTIFICATION_CLICK",
                "screen": "notice"
            },
            topic="all_users"
        )
        response = messaging.send(message)
        
        # 공지사항 DB 저장
        doc = {
            "title": request.title,
            "body": request.body,
            "created_at": datetime.utcnow() # UTC 기준 저장
        }
        await notices_collection.insert_one(doc)

        return {"status": "success", "message_id": response}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Firebase 전송 실패: {str(e)}")

@app.get("/admin/device-count")
async def get_device_count():
    try:
        # DB에 저장된 고유한 user_id 개수를 반환하여 가입 기기 수로 간주합니다.
        unique_users = await collection.distinct("user_id")
        return {"device_count": len(unique_users)}
    except Exception as e:
        return {"device_count": 0}

@app.get("/check-user/{user_id}")
async def check_user(user_id: str):
    try:
        count = await collection.count_documents({"user_id": user_id})
        return {"exists": count > 0}
    except Exception as e:
        return {"exists": False, "detail": str(e)}

@app.get("/notices")
async def get_all_notices():
    try:
        # 최근 50개의 공지사항 불러오기
        cursor = notices_collection.find({}).sort("created_at", -1).limit(50)
        notices_list = await cursor.to_list(length=50)
        results = []
        for doc in notices_list:
            created_at = doc.get("created_at")
            if isinstance(created_at, datetime):
                # 표시를 위해 KST(+9시간) 변환
                kst_time = created_at + timedelta(hours=9)
                time_str = kst_time.strftime("%y.%m.%d %H:%M")
            else:
                time_str = ""

            results.append({
                "id": str(doc["_id"]),
                "title": doc.get("title", ""),
                "body": doc.get("body", ""),
                "created_at": time_str
            })
        return {"status": "success", "data": results}
    except Exception as e:
        return {"status": "error", "detail": str(e)}


@app.post("/upload/chunk")
async def upload_chunk(
        session_id: str = Form(...),
        filename: str = Form(...),
        chunk_index: int = Form(...),
        chunk: UploadFile = File(...),
        x_api_key: str = Header(None)
):
    if x_api_key != SECRET_API_KEY:
        raise HTTPException(status_code=403, detail="Invalid API Key")

    file_temp_dir = os.path.join(TEMP_DIR, session_id, filename)
    os.makedirs(file_temp_dir, exist_ok=True)

    chunk_path = os.path.join(file_temp_dir, f"{chunk_index}.part")
    with open(chunk_path, "wb") as buffer:
        shutil.copyfileobj(chunk.file, buffer)

    return {"status": "success", "chunk_index": chunk_index}


@app.post("/upload/complete")
async def upload_complete(
        session_id: str = Form(...),
        user_id: str = Form(...),
        watch_model: str = Form(...),
        strap: str = Form(...),
        pos: str = Form(...),
        fit: str = Form(...),
        training: str = Form(...),
        location: str = Form(...),
        remarks: str = Form(...),
        total_chunks_map: str = Form(...),
        x_api_key: str = Header(None)
):
    if x_api_key != SECRET_API_KEY:
        raise HTTPException(status_code=403, detail="Invalid API Key")

    try:
        chunks_map = json.loads(total_chunks_map)
    except Exception:
        raise HTTPException(status_code=400, detail="Invalid chunks map format")

    uploaded_files_info = []

    for filename, total_chunks in chunks_map.items():
        file_temp_dir = os.path.join(TEMP_DIR, session_id, filename)

        for i in range(total_chunks):
            if not os.path.exists(os.path.join(file_temp_dir, f"{i}.part")):
                raise HTTPException(status_code=400, detail=f"Missing chunk {i} for {filename}")

        # 서버 장비의 지역에 상관없이 파일명을 항상 KST(한국시간) 기준으로 생성
        kst_now = datetime.utcnow() + timedelta(hours=9)
        timestamp = kst_now.strftime("%Y%m%d_%H%M%S")
        final_filename = f"{timestamp}_{filename}"
        final_path = os.path.join(UPLOAD_DIR, final_filename)

        with open(final_path, "wb") as final_file:
            for i in range(total_chunks):
                chunk_path = os.path.join(file_temp_dir, f"{i}.part")
                with open(chunk_path, "rb") as chunk_file:
                    shutil.copyfileobj(chunk_file, final_file)
                os.remove(chunk_path)

        os.rmdir(file_temp_dir)

        uploaded_files_info.append({
            "original_name": filename,
            "saved_name": final_filename,
            "path": final_path,
            "url": f"/download/{final_filename}"
        })

    session_dir = os.path.join(TEMP_DIR, session_id)
    if os.path.exists(session_dir):
        os.rmdir(session_dir)

    # 몽고DB 저장 (DB에는 국제 표준인 UTC로 저장)
    doc = {
        "user_id": user_id,
        "watch_model": watch_model,
        "strap": strap,
        "pos": pos,
        "fit": fit,
        "training": training,
        "location": location,
        "remarks": remarks,
        "files": uploaded_files_info,
        "uploaded_at": datetime.utcnow()
    }
    await collection.insert_one(doc)

    return JSONResponse(content={"message": "Upload & Merge completed successfully!", "files": uploaded_files_info})


@app.get("/history", response_class=HTMLResponse)
async def get_history(key: str = None):
    try:
        if key != "my_secret":
            raise HTTPException(status_code=403, detail="Forbidden: Invalid Secret Key")

        cursor = collection.find({}).sort("uploaded_at", -1).limit(100)
        history_list = await cursor.to_list(length=100)

        js_data = []
        for doc in history_list:
            uploaded_at = doc.get("uploaded_at") or doc.get("upload_date") or ""

            # 여기서 뷰(화면)에 뿌려줄 때만 UTC 시간에 9시간(+9)을 더해 KST로 만들어줍니다!
            if isinstance(uploaded_at, datetime):
                kst_time = uploaded_at + timedelta(hours=9)
                time_str = kst_time.strftime("%Y-%m-%d %H:%M:%S")
            elif isinstance(uploaded_at, str):
                time_str = uploaded_at[:19].replace("T", " ")
            else:
                time_str = "알 수 없음"

            user_id = doc.get("user_id", "Unknown")
            watch_model = doc.get("watch_model", "N/A")
            strap = doc.get("strap", "N/A")
            training = doc.get("training", "N/A")
            pos = doc.get("pos", "-")
            fit = doc.get("fit", "-")
            location = doc.get("location", "")
            remarks = doc.get("remarks", "")

            files = doc.get("files", [])
            files_html = "<ul class='files-ul'>"
            if files:
                for f in files:
                    fname = f.get("original_name") or f.get("name") or "Unknown file"
                    furl = f.get("url")
                    if not furl:
                        saved_name = f.get("saved_name")
                        furl = f"/download/{saved_name}" if saved_name else "#"
                    files_html += f"<li><a href='{furl}' class='dl-link'>💾 다운로드: {fname}</a></li>"
            else:
                files_html += "<li>(첨부파일 없음)</li>"
            files_html += "</ul>"

            js_data.append({
                "time_str": time_str,
                "user_id": str(user_id).strip(),
                "watch_model": str(watch_model).strip(),
                "strap": str(strap).strip(),
                "training": str(training).strip(),
                "pos": str(pos).strip(),
                "fit": str(fit).strip(),
                "location": str(location).strip(),
                "remarks": str(remarks).strip(),
                "files_html": files_html
            })

        js_data_json = json.dumps(js_data, ensure_ascii=False)

        # ---------------- HTML 및 JS 렌더링 ---------------- #
        html_content = f"""
        <html>
            <head>
                <title>업로드 히스토리 대시보드</title>
                <meta charset="utf-8">
                <style>
                    body {{ font-family: 'Malgun Gothic', 'Apple SD Gothic Neo', sans-serif; background-color: #f7f9fc; padding: 30px; color: #333; }}
                    h1 {{ color: #2c3e50; font-size: 24px; margin-bottom: 20px; }}

                    /* Summary Box (통계표) */
                    .summary-box {{ background: #fff; padding: 20px; border-radius: 8px; box-shadow: 0 4px 6px rgba(0,0,0,0.05); margin-bottom: 20px; line-height: 1.8; font-size: 14px;}}
                    .stat-row {{ margin-bottom: 12px; display: flex; align-items: center; }}
                    .stat-title {{ font-weight: bold; width: 100px; color: #34495e; flex-shrink: 0; }}
                    
                    /* 스택드 바 (Stacked Bar) 스타일 */
                    .stacked-bar-container {{
                        display: flex;
                        width: 100%;
                        height: 28px; /* 바 두께 증가 */
                        background: #eee;
                        border-radius: 6px;
                        overflow: hidden;
                    }}
                    .stacked-bar-segment {{
                        height: 100%;
                        display: flex;
                        align-items: center;
                        justify-content: center;
                        color: white;
                        font-size: 12px;
                        font-weight: bold;
                        white-space: nowrap; /* 텍스트 줄바꿈 방지 */
                        overflow: hidden; /* 영역 밖 텍스트 숨김 */
                        text-overflow: ellipsis; /* 말줄임표 처리 */
                        padding: 0 4px;
                        box-sizing: border-box;
                        transition: width 0.4s ease;
                    }}
                    .stacked-bar-segment:hover {{
                        opacity: 0.9;
                    }}

                    /* Filters Box (필터 영역) */
                    .filters-box {{ background: #fff; padding: 15px; border-radius: 8px; box-shadow: 0 4px 6px rgba(0,0,0,0.05); margin-bottom: 20px; display: flex; flex-wrap: wrap; gap: 10px; }}
                    .filters-box select {{ padding: 8px; border: 1px solid #ccc; border-radius: 4px; font-size: 13px; outline: none; min-width: 130px; cursor: pointer; }}
                    .filters-box select:focus {{ border-color: #4CAF50; }}

                    /* Table */
                    table {{ width: 100%; border-collapse: collapse; background: #fff; box-shadow: 0 4px 6px rgba(0,0,0,0.05); border-radius: 8px; overflow: hidden; }}
                    th, td {{ padding: 12px 15px; border-bottom: 1px solid #eee; text-align: left; font-size: 13px; }}
                    th {{ background-color: #4CAF50; color: white; font-weight: bold; font-size: 14px; }}
                    tr:hover {{ background-color: #f1f8e9; }}

                    /* 뱃지, 링크 속성 */
                    .badge {{ background: #e0f2f1; color: #00796b; padding: 4px 8px; border-radius: 12px; font-weight: bold; font-size: 12px; border: 1px solid #b2dfdb; }}
                    .files-ul {{ margin: 0; padding-left: 15px; font-size: 13px; color: #555; list-style-type: none; }}
                    .files-ul li {{ margin-bottom: 6px; }}
                    .dl-link {{ color: #00796b; text-decoration: none; font-weight: bold; }}
                    .dl-link:hover {{ text-decoration: underline; color: #004d40; }}
                    .remarks {{ color: #888; font-size: 12px; margin-top: 5px; }}
                </style>
            </head>
            <body>
                <h1>📊 운동 기록</h1>

                <!-- 건수 요약 표시 -->
                <div class="summary-box">
                    <div class="stat-row"><div class="stat-title">사용자 ID</div> <div id="stat-user_id" style="flex-grow:1;"></div></div>
                    <div class="stat-row"><div class="stat-title">워치 모델</div> <div id="stat-watch_model" style="flex-grow:1;"></div></div>
                    <div class="stat-row"><div class="stat-title">스트랩</div> <div id="stat-strap" style="flex-grow:1;"></div></div>
                    <div class="stat-row"><div class="stat-title">운동 종류</div> <div id="stat-training" style="flex-grow:1;"></div></div>
                    <div class="stat-row"><div class="stat-title">착용 위치</div> <div id="stat-pos" style="flex-grow:1;"></div></div>
                    <div class="stat-row"><div class="stat-title">착용 정도</div> <div id="stat-fit" style="flex-grow:1;"></div></div>
                    <div class="stat-row"><div class="stat-title">장소</div> <div id="stat-location" style="flex-grow:1;"></div></div>
                </div>

                <!-- 필터 셀렉트 박스 -->
                <div class="filters-box">
                    <select id="filter-user_id" onchange="applyFilters()"><option value="">사용자 ID (전체)</option></select>
                    <select id="filter-watch_model" onchange="applyFilters()"><option value="">워치 모델 (전체)</option></select>
                    <select id="filter-strap" onchange="applyFilters()"><option value="">스트랩 (전체)</option></select>
                    <select id="filter-training" onchange="applyFilters()"><option value="">운동 종류 (전체)</option></select>
                    <select id="filter-pos" onchange="applyFilters()"><option value="">착용 위치 (전체)</option></select>
                    <select id="filter-fit" onchange="applyFilters()"><option value="">착용 정도 (전체)</option></select>
                    <select id="filter-location" onchange="applyFilters()"><option value="">장소 (전체)</option></select>
                </div>

                <!-- 히스토리 테이블 -->
                <table>
                    <thead>
                        <tr>
                            <th width="12%">수신 일시</th>
                            <th width="8%">사용자 ID</th>
                            <th width="12%">워치 모델</th>
                            <th width="10%">스트랩</th>
                            <th width="8%">운동 종류</th>
                            <th width="8%">착용 위치</th>
                            <th width="8%">착용 정도</th>
                            <th width="10%">장소</th>
                            <th width="10%">특이사항</th>
                            <th width="14%">전송된 파일 목록</th>
                        </tr>
                    </thead>
                    <tbody id="historyTbody">
                        <!-- JS로 채워질 영역 -->
                    </tbody>
                </table>

                <script>
                    const historyData = {js_data_json};
                    const totalCount = historyData.length;

                    // 스택드 바에 사용할 색상 팔레트
                    const chartColors = [
                        '#4CAF50', '#2196F3', '#FF9800', '#9C27B0', '#F44336', 
                        '#00BCD4', '#795548', '#FFEB3B', '#607D8B', '#E91E63'
                    ];

                    // 특정 칼럼의 등장 빈도(건수)를 계산하는 함수
                    function getFreq(key) {{
                        const freq = {{}};
                        historyData.forEach(row => {{
                            let val = row[key];
                            if (!val || val.trim() === "" || val.trim() === "/" || val.trim() === "-" || val.trim() === " ") val = "없음";
                            freq[val] = (freq[val] || 0) + 1;
                        }});
                        return freq;
                    }}

                    // 건수 요약 스택드 바 렌더링 함수
                    function renderStats(key, containerId) {{
                        const freq = getFreq(key);
                        let html = '<div class="stacked-bar-container">';
                        
                        let colorIndex = 0;
                        // 빈도수가 높은 순으로 정렬하여 바 구성 (UI 보기 좋음)
                        const sortedItems = Object.entries(freq).sort((a, b) => b[1] - a[1]);
                        
                        for (let [val, count] of sortedItems) {{
                            if (totalCount === 0) break;
                            const percentage = (count / totalCount) * 100;
                            const bgColor = chartColors[colorIndex % chartColors.length];
                            
                            // 항목별 데이터 텍스트
                            const text = `${{val}}(${{count}}/${{totalCount}})`;
                            
                            html += `
                                <div class="stacked-bar-segment" 
                                     style="width: ${{percentage}}%; background-color: ${{bgColor}};" 
                                     title="${{val}} (${{count}}건, ${{percentage.toFixed(1)}}%)">
                                    ${{text}}
                                </div>
                            `;
                            colorIndex++;
                        }}
                        
                        html += '</div>';
                        document.getElementById(containerId).innerHTML = html;
                    }}

                    // 필터 드롭다운 렌더링 함수
                    function renderOptions(key, selectId) {{
                        const freq = getFreq(key);
                        const select = document.getElementById(selectId);
                        for (let val in freq) {{
                            select.innerHTML += `<option value="${{val}}">${{val}} ( ${{freq[val]}}건 )</option>`;
                        }}
                    }}

                    // 메인 테이블 그리기 함수
                    function drawTable(data) {{
                        const tbody = document.getElementById("historyTbody");
                        let html = "";
                        data.forEach(row => {{
                            let pr = row.pos; if(pr.trim() === "" || pr.trim() === "-") pr = "없음";
                            let fr = row.fit; if(fr.trim() === "" || fr.trim() === "-") fr = "없음";

                            html += `
                                <tr>
                                    <td>${{row.time_str}}</td>
                                    <td><strong>${{row.user_id}}</strong></td>
                                    <td><span style='color:#00796b; font-weight:bold;'>${{row.watch_model}}</span></td>
                                    <td><span>${{row.strap}}</span></td>
                                    <td><span class='badge'>${{row.training}}</span></td>
                                    <td>${{pr}}</td>
                                    <td>${{fr}}</td>
                                    <td>${{row.location}}</td>
                                    <td><div class='remarks'>${{row.remarks}}</div></td>
                                    <td>${{row.files_html}}</td>
                                </tr>
                            `;
                        }});
                        tbody.innerHTML = html;
                    }}

                    // 사용자가 필터를 바꿀때마다 호출되는 함수
                    function applyFilters() {{
                        const fUser = document.getElementById("filter-user_id").value;
                        const fWatch = document.getElementById("filter-watch_model").value;
                        const fStrap = document.getElementById("filter-strap").value;
                        const fTrain = document.getElementById("filter-training").value;
                        const fPos = document.getElementById("filter-pos").value;
                        const fFit = document.getElementById("filter-fit").value;
                        const fLoc = document.getElementById("filter-location").value;

                        const filtered = historyData.filter(row => {{
                            let ur = row.user_id || "없음";
                            let wr = row.watch_model || "없음";
                            let sr = row.strap || "없음";
                            let tr = row.training || "없음";
                            let pr = row.pos || "없음"; if(pr.trim() === "-" || pr.trim() === "") pr = "없음";
                            let fr = row.fit || "없음"; if(fr.trim() === "-" || fr.trim() === "") fr = "없음";
                            let lr = row.location || "없음"; if(lr.trim() === "") lr = "없음";

                            if (fUser && ur !== fUser) return false;
                            if (fWatch && wr !== fWatch) return false;
                            if (fStrap && sr !== fStrap) return false;
                            if (fTrain && tr !== fTrain) return false;
                            if (fPos && pr !== fPos) return false;
                            if (fFit && fr !== fFit) return false;
                            if (fLoc && lr !== fLoc) return false;
                            return true;
                        }});

                        drawTable(filtered); // 필터링 된 데이터만 테이블에 다시 그림
                    }}

                    // 페이지 처음 로딩 시 모두 세팅
                    window.onload = function() {{
                        renderStats("user_id", "stat-user_id");
                        renderStats("watch_model", "stat-watch_model");
                        renderStats("strap", "stat-strap");
                        renderStats("training", "stat-training");
                        renderStats("pos", "stat-pos");
                        renderStats("fit", "stat-fit");
                        renderStats("location", "stat-location");

                        renderOptions("user_id", "filter-user_id");
                        renderOptions("watch_model", "filter-watch_model");
                        renderOptions("strap", "filter-strap");
                        renderOptions("training", "filter-training");
                        renderOptions("pos", "filter-pos");
                        renderOptions("fit", "filter-fit");
                        renderOptions("location", "filter-location");

                        drawTable(historyData);
                    }};
                </script>
            </body>
        </html>
        """

        return HTMLResponse(content=html_content)

    except Exception as e:
        return HTMLResponse(content=f"<h1>서버 내부 오류</h1><p>{str(e)}</p>", status_code=500)


@app.get("/download/{filename}")
@app.get("/files/{filename}")
async def download_file(filename: str):
    file_path = os.path.join(UPLOAD_DIR, filename)
    if os.path.exists(file_path):
        return FileResponse(path=file_path, filename=filename)
    raise HTTPException(status_code=404, detail="File not found")
