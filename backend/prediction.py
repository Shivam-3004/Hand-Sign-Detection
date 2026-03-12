import os
import tempfile
from functools import lru_cache
from typing import List, Optional

import cv2
import torch
import torch.nn.functional as F
from PIL import Image
from transformers import ViTConfig, ViTForImageClassification, ViTImageProcessor


# -------------------- model & processor loading --------------------
@lru_cache(maxsize=1)
def _load_model_and_processor():
    """Return a tuple of *(model, processor)* loaded from disk.

    We cache the result so that repeated requests don't reinstantiate the
    network.  The caching also makes the import-time overhead minimal, which
    is helpful when the FastAPI server reloads modules.
    """

    # configuration contains the number of output classes etc.
    config = ViTConfig.from_json_file("config.json")
    model = ViTForImageClassification(config)

    weights = torch.load("model.pt", map_location=torch.device("cpu"))
    model.load_state_dict(weights)
    model.eval()

    processor = ViTImageProcessor.from_pretrained("./")
    return model, processor


# Mapping from model output indices to human-readable gesture labels.
labels = {
    0: "1", 1: "2", 2: "3", 3: "4", 4: "5",
    5: "6", 6: "7", 7: "8", 8: "9",
    9: "A", 10: "B", 11: "C", 12: "D", 13: "E",
    14: "F", 15: "G", 16: "H", 17: "I", 18: "J",
    19: "K", 20: "L", 21: "M", 22: "N", 23: "O",
    24: "P", 25: "Q", 26: "R", 27: "S", 28: "T",
    29: "U", 30: "V", 31: "W", 32: "X", 33: "Y",
    34: "Z"
}


def _postprocess_logits(logits: torch.Tensor) -> dict:
    """Convert output logits into a structured prediction dictionary."""

    probs = F.softmax(logits, dim=1)
    predicted_class = torch.argmax(probs, dim=1).item()
    gesture = labels[predicted_class]
    confidence = probs[0][predicted_class].item()

    top_probs, top_indices = torch.topk(probs, 3)
    top_predictions = []
    for i in range(3):
        label = labels[top_indices[0][i].item()]
        score = top_probs[0][i].item()
        top_predictions.append({"gesture": label, "confidence": score})

    return {"prediction": gesture, "confidence": confidence, "top_3_predictions": top_predictions}


def predict_image(img: Image.Image) -> dict:
    """Run inference on a single PIL image and return the result.

    This is the core helper that every endpoint should use.  The old
    ``predict_gesture`` function is kept as an alias for backward
    compatibility.
    """

    model, processor = _load_model_and_processor()
    inputs = processor(images=img, return_tensors="pt")
    with torch.no_grad():
        outputs = model(**inputs)
    return _postprocess_logits(outputs.logits)


def predict_gesture(img: Image.Image) -> dict:
    # maintain original name for imports in other modules
    return predict_image(img)


def predict_frames(frames: List[Image.Image]) -> List[dict]:
    """Run inference on a list of frames, preserving order."""

    return [predict_image(f) for f in frames]


def extract_frames_from_video(
    path: str,
    interval: int = 1,
    max_frames: Optional[int] = None,
) -> List[Image.Image]:
    """Read a video file and return every ``interval``th frame as a PIL image.

    Args:
        path: filesystem path to the video.
        interval: only keep one frame every ``interval`` frames (default 1).
        max_frames: if set, stop after collecting this many frames.
    """

    cap = cv2.VideoCapture(path)
    if not cap.isOpened():
        raise ValueError(f"Unable to open video {path}")

    frames: List[Image.Image] = []
    count = 0
    while True:
        ret, frame = cap.read()
        if not ret:
            break
        if count % interval == 0:
            # convert BGR→RGB and to PIL
            img = Image.fromarray(cv2.cvtColor(frame, cv2.COLOR_BGR2RGB))
            frames.append(img)
            if max_frames and len(frames) >= max_frames:
                break
        count += 1

    cap.release()
    return frames
