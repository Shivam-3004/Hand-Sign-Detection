# ==================================================
# FASTAPI BACKEND (FLUTTER COMPATIBLE)
# Hand Gesture → Text API
# ==================================================

# Install:
# pip install fastapi uvicorn opencv-python mediapipe tensorflow numpy pillow

import io
import numpy as np
from PIL import Image

from fastapi import FastAPI, File, UploadFile, Form
from fastapi.responses import JSONResponse

import mediapipe as mp
from mediapipe.tasks import python
from mediapipe.tasks.python import vision

from tensorflow.keras.models import load_model


# ==================================================
# LOAD MODEL
# ==================================================
MODEL_PATH = "asl_model_final.h5"
TASK_MODEL_PATH = "hand_landmarker.task"

model = load_model(MODEL_PATH)


# ==================================================
# LABELS
# ==================================================
GESTURES = ['Alright', 'Good Afternoon', 'Good Morning', 'Hello', 'How are you']


# ==================================================
# SETTINGS
# ==================================================
MAX_FRAMES = 60
FEATURES = 120
CONFIDENCE_THRESHOLD = 0.70
PREDICT_EVERY_N_FRAMES = 5


# ==================================================
# FASTAPI
# ==================================================
app = FastAPI()


# ==================================================
# MEDIAPIPE SETUP
# ==================================================
BaseOptions = python.BaseOptions
HandLandmarker = vision.HandLandmarker
HandLandmarkerOptions = vision.HandLandmarkerOptions
VisionRunningMode = vision.RunningMode

options = HandLandmarkerOptions(
    base_options=BaseOptions(model_asset_path=TASK_MODEL_PATH),
    running_mode=VisionRunningMode.IMAGE,  # IMPORTANT CHANGE
    num_hands=2
)

landmarker = HandLandmarker.create_from_options(options)


# ==================================================
# USER STATE (IMPORTANT FOR MULTIPLE USERS)
# ==================================================
user_sequences = {}
user_frame_counters = {}
user_predictions = {}


# ==================================================
# FEATURE HELPERS
# ==================================================
def calc_distance(p1, p2):
    return np.linalg.norm(np.array(p1) - np.array(p2))


def calc_angle(a, b, c):
    a, b, c = np.array(a), np.array(b), np.array(c)

    ba = a - b
    bc = c - b

    cosine = np.dot(ba, bc) / (np.linalg.norm(ba) * np.linalg.norm(bc) + 1e-6)
    return np.arccos(cosine)


# ==================================================
# FEATURE EXTRACTION
# ==================================================
def get_features(result):

    frame_features = []

    if result.hand_landmarks:

        for hand in result.hand_landmarks[:2]:

            points = [(lm.x, lm.y) for lm in hand]

            wrist = points[0]
            norm_points = [(x - wrist[0], y - wrist[1]) for x, y in points]

            # raw keypoints
            for p in norm_points:
                frame_features.extend(p)

            # distance features
            pairs = [(4, 8), (8, 12), (12, 16), (16, 20)]

            for i, j in pairs:
                frame_features.append(calc_distance(points[i], points[j]))

            # angle features
            triplets = [(0, 5, 8), (0, 9, 12), (0, 13, 16)]

            for a, b, c in triplets:
                frame_features.append(calc_angle(points[a], points[b], points[c]))

    # FIXED SIZE
    if len(frame_features) < FEATURES:
        frame_features.extend([0] * (FEATURES - len(frame_features)))
    else:
        frame_features = frame_features[:FEATURES]

    return frame_features


# ==================================================
# MAIN API (IMPORTANT)
# ==================================================
@app.post("/predict-frame")
async def predict_frame(
    file: UploadFile = File(...),
    user_id: str = Form(...)
):

    # Initialize user if new
    if user_id not in user_sequences:
        user_sequences[user_id] = []
        user_frame_counters[user_id] = 0
        user_predictions[user_id] = "Waiting..."

    sequence = user_sequences[user_id]
    frame_counter = user_frame_counters[user_id]

    # Read image
    contents = await file.read()
    image = Image.open(io.BytesIO(contents)).convert("RGB")
    frame = np.array(image)

    # Mediapipe processing
    mp_image = mp.Image(
        image_format=mp.ImageFormat.SRGB,
        data=frame
    )

    result = landmarker.detect(mp_image)

    features = get_features(result)

    sequence.append(features)

    if len(sequence) > MAX_FRAMES:
        sequence = sequence[-MAX_FRAMES:]

    frame_counter += 1

    # Prediction
    if len(sequence) == MAX_FRAMES and frame_counter % PREDICT_EVERY_N_FRAMES == 0:

        input_data = np.expand_dims(sequence, axis=0)

        pred = model.predict(input_data, verbose=0)[0]

        class_id = np.argmax(pred)
        conf = pred[class_id]

        if conf >= CONFIDENCE_THRESHOLD:
            user_predictions[user_id] = f"{GESTURES[class_id]} ({conf:.2f})"
        else:
            user_predictions[user_id] = "Detecting..."

    # Save back state
    user_sequences[user_id] = sequence
    user_frame_counters[user_id] = frame_counter

    return JSONResponse({
        "prediction": user_predictions[user_id]
    })


# ==================================================
# HEALTH CHECK
# ==================================================
@app.get("/")
def home():
    return {"message": "Gesture API Running 🚀"}


# ==================================================
# RUN
# ==================================================
# uvicorn main:app --reload
