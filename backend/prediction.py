from functools import lru_cache

import torch
import torch.nn.functional as F
from PIL import Image
from transformers import ViTConfig, ViTForImageClassification, ViTImageProcessor

# ---------------------------------------------------------------------------
# Model & processor
# ---------------------------------------------------------------------------

@lru_cache(maxsize=1)
def _load_model_and_processor():
    """Load and cache the ViT model and image processor from disk.

    Caching ensures weights are loaded only once per server process, keeping
    every subsequent inference request fast.

    Files required in the working directory
    ----------------------------------------
    model.pt               – fine-tuned model weights
    config.json            – ViT configuration (num_labels=35, etc.)
    preprocessor_config.json – ViTImageProcessor configuration
    """

    config = ViTConfig.from_json_file("config.json")
    model = ViTForImageClassification(config)

    weights = torch.load("model.pt", map_location=torch.device("cpu"))
    model.load_state_dict(weights)
    model.eval()

    processor = ViTImageProcessor.from_pretrained("./")
    return model, processor


# ---------------------------------------------------------------------------
# Label mapping  (model output index → hand-sign character)
# ---------------------------------------------------------------------------

LABELS = {
    0: "1", 1: "2", 2: "3", 3: "4", 4: "5",
    5: "6", 6: "7", 7: "8", 8: "9",
    9: "A", 10: "B", 11: "C", 12: "D", 13: "E",
    14: "F", 15: "G", 16: "H", 17: "I", 18: "J",
    19: "K", 20: "L", 21: "M", 22: "N", 23: "O",
    24: "P", 25: "Q", 26: "R", 27: "S", 28: "T",
    29: "U", 30: "V", 31: "W", 32: "X", 33: "Y",
    34: "Z",
}


# ---------------------------------------------------------------------------
# Inference helpers
# ---------------------------------------------------------------------------

def _postprocess_logits(logits: torch.Tensor) -> dict:
    """Convert raw model logits into a structured prediction dictionary.

    Parameters
    ----------
    logits:
        Raw output tensor with shape ``(1, num_labels)``.

    Returns
    -------
    dict with keys:
        ``prediction``       – top label string (e.g. ``"A"``)
        ``confidence``       – probability of the top label (0–1)
        ``top_3_predictions``– list of ``{"gesture": str, "confidence": float}``
                               for the three most likely classes
    """

    probs = F.softmax(logits, dim=1)

    predicted_idx = torch.argmax(probs, dim=1).item()
    top_label = LABELS[predicted_idx]
    top_confidence = probs[0][predicted_idx].item()

    top_probs, top_indices = torch.topk(probs, 3)
    top_3 = [
        {
            "gesture": LABELS[top_indices[0][i].item()],
            "confidence": round(top_probs[0][i].item(), 4),
        }
        for i in range(3)
    ]

    return {
        "prediction": top_label,
        "confidence": round(top_confidence, 4),
        "top_3_predictions": top_3,
    }


def predict_gesture(img: Image.Image) -> dict:
    """Run inference on a single PIL image and return the prediction.

    This is the only public function needed by the FastAPI endpoint.

    Parameters
    ----------
    img:
        An RGB PIL Image (any resolution — the processor will resize it).

    Returns
    -------
    dict
        See :func:`_postprocess_logits` for the exact structure.
    """

    model, processor = _load_model_and_processor()

    inputs = processor(images=img, return_tensors="pt")
    with torch.no_grad():
        outputs = model(**inputs)

    return _postprocess_logits(outputs.logits)
