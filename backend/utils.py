import time
import numpy as np
from config import (
    FEATURES, GESTURES, CONFIDENCE_THRESHOLD,
    MAX_FRAMES, PREDICT_EVERY_N_FRAMES, model
)

# ==================================================
# USER STATE
# ==================================================
user_sequences = {}
user_frame_counters = {}
user_predictions = {}
user_last_seen = {}

# how long to keep inactive users (in seconds)
USER_TIMEOUT = 60  # 1 minute


def init_user(user_id):
    user_sequences[user_id] = []
    user_frame_counters[user_id] = 0
    user_predictions[user_id] = "Detecting..."
    user_last_seen[user_id] = time.time()


def reset_user(user_id):
    user_sequences.pop(user_id, None)
    user_frame_counters.pop(user_id, None)
    user_predictions.pop(user_id, None)
    user_last_seen.pop(user_id, None)


# ==================================================
# CLEANUP FUNCTION (IMPORTANT)
# ==================================================
def periodic_cleanup():                    
    """Called by background task every 60s, not on every frame."""
    current_time = time.time()
    to_delete = [
        uid for uid, last_seen in user_last_seen.items()
        if current_time - last_seen > USER_TIMEOUT
    ]
    for uid in to_delete:
        reset_user(uid)

# ==================================================
# FEATURE FUNCTIONS (same as before)
# ==================================================
def calc_distance(p1, p2):
    return np.linalg.norm(np.array(p1) - np.array(p2))


def calc_angle(a, b, c):
    a, b, c = np.array(a), np.array(b), np.array(c)
    ba = a - b
    bc = c - b
    cosine = np.dot(ba, bc) / (np.linalg.norm(ba) * np.linalg.norm(bc) + 1e-6)
    return np.arccos(np.clip(cosine, -1, 1))


def get_features(result):
    frame_features = []

    if result.hand_landmarks:
        for hand in result.hand_landmarks[:2]:
            points = [(lm.x, lm.y) for lm in hand]
            wrist = points[0]
            norm_points = [(x - wrist[0], y - wrist[1]) for x, y in points]

            for p in norm_points:
                frame_features.extend(p)

            pairs = [(4, 8), (8, 12), (12, 16), (16, 20)]
            for i, j in pairs:
                frame_features.append(calc_distance(points[i], points[j]))

            triplets = [(0, 5, 8), (0, 9, 12), (0, 13, 16)]
            for a, b, c in triplets:
                frame_features.append(calc_angle(points[a], points[b], points[c]))

    if len(frame_features) < FEATURES:
        frame_features.extend([0] * (FEATURES - len(frame_features)))
    else:
        frame_features = frame_features[:FEATURES]

    return frame_features


# ==================================================
# PREDICTION LOGIC
# ==================================================
def predict_gesture(sequence):
    seq_array = np.array(sequence, dtype=np.float32)  
    pred = model.predict(seq_array)                 

    class_id = np.argmax(pred)
    conf = float(pred[class_id])

    if conf >= CONFIDENCE_THRESHOLD:
        return f"{GESTURES[class_id]} ({conf:.2f})"

    return "Detecting..."


def process_frame(user_id, features):
    """Main processing function"""

    if user_id not in user_sequences:
        init_user(user_id)

    # update last seen
    user_last_seen[user_id] = time.time()

    sequence = user_sequences[user_id]
    frame_counter = user_frame_counters[user_id]

    sequence.append(features)

    if len(sequence) > MAX_FRAMES:
        del sequence[:-MAX_FRAMES]

    frame_counter = (frame_counter + 1) % 100000

    prediction = user_predictions[user_id]

    if len(sequence) == MAX_FRAMES and frame_counter % PREDICT_EVERY_N_FRAMES == 0:
        new_prediction = predict_gesture(sequence)
        if new_prediction is not None:
            prediction = new_prediction

    user_sequences[user_id] = sequence
    user_frame_counters[user_id] = frame_counter
    user_predictions[user_id] = prediction

    return prediction