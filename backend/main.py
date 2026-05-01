# ==================================================
# FASTAPI BACKEND (FLUTTER COMPATIBLE)
# Hand Gesture → Text API
# ==================================================

import io
import logging
import numpy as np
from PIL import Image

from fastapi import FastAPI, File, UploadFile, Form, HTTPException
from fastapi.responses import JSONResponse

import mediapipe as mp

from config import landmarker, MAX_FRAMES
from utils import process_frame, reset_user, get_features, user_sequences
from fastapi.middleware.cors import CORSMiddleware

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# ==================================================
# FASTAPI APP
# ==================================================
app = FastAPI(title="Hand Gesture API", version="1.0.0")

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
    """Predict gesture from uploaded frame image."""
    try:
        # Validate input
        if not file.content_type.startswith("image/"):
            raise HTTPException(status_code=400, detail="Invalid file type. Use PNG or JPG.")

        # Read and process image
        contents = await file.read()
        image = Image.open(io.BytesIO(contents)).convert("RGB")
        frame = np.array(image)

        # MediaPipe detection
        mp_image = mp.Image(image_format=mp.ImageFormat.SRGB, data=frame)
        result = landmarker.detect(mp_image)
        features = get_features(result)

        # Process and get prediction
        prediction = process_frame(user_id, features)

        logger.info(f"user={user_id}, prediction={prediction}")

        # Determine if hand is visible
        hand_visible = bool(result.hand_landmarks)

        frame_count = len(user_sequences.get(user_id, []))

        buffer_ready = frame_count >= MAX_FRAMES

        return JSONResponse({
            "prediction": prediction,
            "hand_visible": hand_visible,
            "buffer_ready": buffer_ready,
            "frame_count": frame_count
        })

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error in predict_frame: {e}")
        raise HTTPException(status_code=500, detail="Internal server error")

@app.post("/reset-session")
async def reset_user_endpoint(user_id: str = Form(...)):
    """Reset user sequence and prediction state."""
    reset_user(user_id)
    return {"status": "reset"}

@app.get("/")
def home():
    """Health check endpoint."""
    return {"status": "ok"}

# ==================================================
# RUN SERVER
# ==================================================
# uvicorn main:app --reload --host 0.0.0.0 --port 8000