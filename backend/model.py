import torch
from functools import lru_cache
from transformers import ViTConfig, ViTForImageClassification


@lru_cache(maxsize=1)
def get_model():
    """Return a cached instance of the pre-trained Vision Transformer.

    By caching the value we avoid re-loading weights on every call, which
    keeps inference endpoints fast when multiple requests arrive.

    ``model.pt`` must exist in the current working directory when this
    function is invoked.

    Returns
    -------
    ViTForImageClassification
        model ready for evaluation (``model.eval()`` has been called).
    """

    config = ViTConfig(num_labels=35)
    model = ViTForImageClassification(config)

    weights = torch.load("model.pt", map_location="cpu")
    model.load_state_dict(weights)

    model.eval()
    return model