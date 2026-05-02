import logging
import numpy as np
import tensorflow as tf
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
MODEL_PATH = os.path.join(BASE_DIR, "ml_model", "asl_model_augmented.h5")  # back to .h5
TASK_MODEL_PATH = os.path.join(BASE_DIR, "ml_model", "hand_landmarker.task")

# ==================================================
# MODEL WRAPPER
# Same interface as TFLiteModel — nothing else in the
# codebase needs to change.
# model(inp, training=False) skips Keras overhead vs
# model.predict() which logs, batches, and callbacks
# on every single call.
# ==================================================
class KerasModel:
    def __init__(self, path: str):
        self._model = tf.keras.models.load_model(path, compile=False)
        # Warm-up: eliminates the slow first-request spike
        dummy = np.zeros((1, MAX_FRAMES, FEATURES), dtype=np.float32)
        self._model(dummy, training=False)
        logger.info("Keras model loaded and warmed up.")

    def predict(self, sequence: np.ndarray) -> np.ndarray:
        inp = sequence.astype(np.float32)[np.newaxis, ...]
        return self._model(inp, training=False).numpy()[0]

try:
    model = KerasModel(MODEL_PATH)
except Exception as e:
    logger.error(f"Failed to load model: {e}")
    raise

# ==================================================
# MEDIAPIPE
# ==================================================
BaseOptions = python.BaseOptions
HandLandmarker = vision.HandLandmarker
HandLandmarkerOptions = vision.HandLandmarkerOptions
VisionRunningMode = vision.RunningMode

try:
    options = HandLandmarkerOptions(
        base_options=BaseOptions(model_asset_path=TASK_MODEL_PATH),
        running_mode=VisionRunningMode.IMAGE,
        num_hands=1,
        min_hand_detection_confidence=0.6,
        min_hand_presence_confidence=0.6,
        min_tracking_confidence=0.5,
    )
    landmarker = HandLandmarker.create_from_options(options)
    logger.info("Hand landmarker loaded.")
except Exception as e:
    logger.error(f"Failed to load hand landmarker: {e}")
    raise