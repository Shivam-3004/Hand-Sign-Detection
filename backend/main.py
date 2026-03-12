from fastapi import FastAPI, UploadFile, File, HTTPException
from PIL import Image
from io import BytesIO
from prediction import predict_gesture

# ---------------------------------------------------------------------------
# FastAPI application
# The backend exposes a single /upload endpoint that accepts an image, runs
# Vision Transformer inference, and returns the predicted hand-sign label with
# a confidence score.
#
# Expected flow:
#   Flutter (camera frame every 300-500 ms)
#     → POST /upload  (multipart/form-data, field "image")
#     ← JSON  { "prediction": { "prediction": "A", "confidence": 0.97, ... } }
# ---------------------------------------------------------------------------

app = FastAPI(title="HandSign Recognition API")


@app.get("/")
def health_check():
    """Simple liveness probe so the Flutter app can verify the server is up."""
    return {"status": "ok"}


@app.post("/upload")
async def upload_image(image: UploadFile = File(...)):
    """Receive a single image frame and return the recognised hand-sign.

    The client (Flutter) should POST the image under the form field named
    **image**.  The handler validates the content type, converts the upload to
    a PIL Image (RGB), and delegates to :func:`predict_gesture` for inference.

    Returns
    -------
    JSON
        ``prediction``  – top predicted label (e.g. ``"A"``)
        ``confidence``  – model confidence for that label (0–1)
        ``top_3_predictions`` – list of the three most likely labels with
                                their confidence scores
    """

    # --- validate that an image was actually sent --------------------------
    if not image.content_type.startswith("image/"):
        raise HTTPException(
            status_code=400,
            detail=f"Expected an image file, got '{image.content_type}'.",
        )

    # --- decode to PIL -----------------------------------------------------
    try:
        contents = await image.read()
        img = Image.open(BytesIO(contents)).convert("RGB")
    except Exception as exc:
        raise HTTPException(
            status_code=400,
            detail=f"Could not decode image: {exc}",
        )

    # --- run inference and return result -----------------------------------
    result = predict_gesture(img)
    return {"prediction": result}
