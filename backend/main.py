# ==================================================
# FASTAPI BACKEND (FLUTTER COMPATIBLE)
# Hand Gesture → Text API
# ==================================================

import logging
import asyncio
import numpy as np
import cv2
from concurrent.futures import ThreadPoolExecutor

from fastapi import FastAPI, File, UploadFile, Form, HTTPException
from fastapi.responses import JSONResponse
from fastapi.middleware.cors import CORSMiddleware
import mediapipe as mp

from config import landmarker, MAX_FRAMES
from utils import process_frame, reset_user, get_features, user_sequences, periodic_cleanup
from contextlib import asynccontextmanager

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

_executor = ThreadPoolExecutor(max_workers=2)
# ==================================================
# FASTAPI APP
# ==================================================
@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup: launch background cleanup task
    async def _cleanup_loop():
        while True:
            await asyncio.sleep(60)
            periodic_cleanup()
    task = asyncio.create_task(_cleanup_loop())
    
    yield 

    task.cancel()

def _sync_process(image_bytes: bytes, user_id: str):
    """All CPU-heavy work in one function — runs in thread pool."""
    # Decode with cv2 (faster than PIL for this use case)
    nparr = np.frombuffer(image_bytes, np.uint8)
    frame = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
    if frame is None:
        raise ValueError("Invalid image data")
    
    # Resize only if frame is large (saves MediaPipe time)
    h, w = frame.shape[:2]
    if h > 320 or w > 320:
        frame = cv2.resize(frame, (320, 320), interpolation=cv2.INTER_AREA)

    frame_rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
    mp_image = mp.Image(image_format=mp.ImageFormat.SRGB, data=frame_rgb)
    result = landmarker.detect(mp_image)

    features = get_features(result)
    hand_visible = bool(result.hand_landmarks)
    prediction = process_frame(user_id, features)
    return prediction, hand_visible

app = FastAPI(title="Hand Gesture API", version="1.0.0", lifespan=lifespan)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ==================================================
# API ENDPOINTS
# ==================================================

@app.post("/predict-frame")
async def predict_frame(
    file: UploadFile = File(...),
    user_id: str = Form(...)
):
    if not file.content_type.startswith("image/"):
        raise HTTPException(status_code=400, detail="Invalid file type.")

    contents = await file.read()

    loop = asyncio.get_running_loop()
    try:
        prediction, hand_visible = await loop.run_in_executor(
            _executor, _sync_process, contents, user_id
        )
    except Exception as e:
        logger.error(f"Processing error for user={user_id}: {e}")
        raise HTTPException(status_code=500, detail="Internal server error")

    if prediction is None:
        return JSONResponse({"prediction": None, "hand_visible": False,
                             "buffer_ready": False, "frame_count": 0})

    frame_count = len(user_sequences.get(user_id, []))
    logger.info(f"user={user_id}, prediction={prediction}")

    return JSONResponse({
        "prediction": prediction,
        "hand_visible": hand_visible,
        "buffer_ready": frame_count >= MAX_FRAMES,
        "frame_count": frame_count
    })

@app.post("/reset-session")
async def reset_user_endpoint(user_id: str = Form(...)):
    reset_user(user_id)
    return {"status": "reset"}


@app.get("/")
def home():
    return {"status": "ok"}
# ==================================================
# RUN SERVER
# ==================================================
# uvicorn main:app --reload --host 0.0.0.0 --port 8000