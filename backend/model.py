import torch
from functools import lru_cache
from transformers import ViTConfig, ViTForImageClassification


@lru_cache(maxsize=1)
def get_model() -> ViTForImageClassification:
    """Load and cache the fine-tuned ViT model from *model.pt*.

    The model is loaded once and reused for every subsequent request.
    ``model.pt`` must exist in the working directory.

    Returns
    -------
    ViTForImageClassification
        Model in evaluation mode, ready for inference.

    Notes
    -----
    This module is kept for standalone use or testing.  The FastAPI
    application loads the model via ``prediction._load_model_and_processor``
    which also initialises the image processor in the same cached call.
    """

    config = ViTConfig(num_labels=35)
    model = ViTForImageClassification(config)

    weights = torch.load("model.pt", map_location="cpu")
    model.load_state_dict(weights)

    model.eval()
    return model
