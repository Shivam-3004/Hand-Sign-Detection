# ==================================================
# CONFIGURATION AND MODEL LOADING
# ==================================================

import logging
from tensorflow.keras.models import load_model
import mediapipe as mp
from mediapipe.tasks import python
from mediapipe.tasks.python import vision
import os

logger = logging.getLogger(__name__)

# ==================================================
# CONSTANTS
# ==================================================
GESTURES = ['Alright', 'Good Afternoon', 'Good Morning', 'Hello', 'How are you']
MAX_FRAMES = 60
FEATURES = 120
CONFIDENCE_THRESHOLD = 0.70
PREDICT_EVERY_N_FRAMES = 5


BASE_DIR = os.path.dirname(os.path.abspath(__file__))
MODEL_PATH = os.path.join(BASE_DIR, "ml_model", "asl_model_augmented.h5")
TASK_MODEL_PATH = os.path.join(BASE_DIR, "ml_model", "hand_landmarker.task")

# ==================================================
# LOAD MODELS
# ==================================================
try:
    model = load_model(MODEL_PATH, compile=False)
    logger.info("Model loaded successfully.")
except Exception as e:
    logger.error(f"Failed to load model: {e}")
    raise

# Mediapipe setup
BaseOptions = python.BaseOptions
HandLandmarker = vision.HandLandmarker
HandLandmarkerOptions = vision.HandLandmarkerOptions
VisionRunningMode = vision.RunningMode

try:
    options = HandLandmarkerOptions(
        base_options=BaseOptions(model_asset_path=TASK_MODEL_PATH),
        running_mode=VisionRunningMode.IMAGE,
        num_hands=2
    )
    landmarker = HandLandmarker.create_from_options(options)
    logger.info("Hand landmarker loaded successfully.")
except Exception as e:
    logger.error(f"Failed to load hand landmarker: {e}")
    raise