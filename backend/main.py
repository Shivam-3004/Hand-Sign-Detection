from collections import Counter
import os
import shutil
import tempfile
from pathlib import Path

from fastapi import FastAPI, UploadFile, File, HTTPException
from PIL import Image

from prediction import (
    extract_frames_from_video,
    predict_frames,
    predict_gesture,
)

# Create a FastAPI application instance. This will be used to
# register request handlers for the HTTP API.
app = FastAPI()


@app.post("/upload")
async def upload_image(image: UploadFile = File(...)):
    """Endpoint for uploading an image file.

    The client should POST an image file under the form field
    named "image". The handler validates that the uploaded file
    is an image, converts it to a PIL Image, and then calls
    :func:`predict_gesture` to obtain predictions from the
    trained model. The response includes the prediction results.
    """

    # Validate content type to ensure an image was sent
    if not image.content_type.startswith("image/"):
        raise HTTPException(status_code=400, detail="File must be an image")

    # Open the uploaded file and convert to RGB (model expects 3-channel data)
    img = Image.open(image.file).convert("RGB")

    # Run the prediction helper and return its result
    result = predict_gesture(img)

    return {"prediction": result}


# ---------------------------------------------------------------------
# video handling endpoint
# ---------------------------------------------------------------------

@app.post("/upload_video")
async def upload_video(
    video: UploadFile = File(...),
    interval: int = 1,
    max_frames: int | None = None,
):
    """Handle a video upload by extracting frames and classifying them.

    Parameters are accepted as query parameters so the Flutter front-end can
    configure how many frames are sampled.
    """

    if not video.content_type.startswith("video/"):
        raise HTTPException(status_code=400, detail="File must be a video")

    # write buffer to disk (OpenCV can't read file-like objects)
    suffix = Path(video.filename).suffix or ".mp4"
    with tempfile.NamedTemporaryFile(delete=False, suffix=suffix) as tmp:
        shutil.copyfileobj(video.file, tmp)
        tmp_path = tmp.name

    try:
        frames = extract_frames_from_video(
            tmp_path, interval=interval, max_frames=max_frames
        )
    except Exception as exc:
        raise HTTPException(status_code=400, detail=str(exc))
    finally:
        try:
            os.remove(tmp_path)
        except OSError:
            pass

    if not frames:
        raise HTTPException(status_code=400, detail="No frames could be extracted")

    predictions = predict_frames(frames)
    most_common = Counter(p["prediction"] for p in predictions).most_common(1)[0][0]
    return {"prediction": most_common, "per_frame": predictions}