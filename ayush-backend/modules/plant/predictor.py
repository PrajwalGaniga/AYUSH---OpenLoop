import os
import io
import torch
import torch.nn as nn
import torchvision.models as models
import torchvision.transforms as transforms
from PIL import Image, ImageFile

# Allow PIL to load truncated/incomplete image files from mobile cameras
ImageFile.LOAD_TRUNCATED_IMAGES = True

# Use the extracted .pth file
BASE_DIR = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
MODEL_PATH = os.path.join(BASE_DIR, "plant-model", "efficientnet_v2_best_final.pth")

CLASS_NAMES = [
    'Aloevera', 'Amla', 'Amruthaballi', 'Arali', 'Astma_weed',
    'Bamboo', 'Betel', 'Bhrami', 'Bringaraja', 'Castor',
    'Catharanthus', 'Coriender', 'Curry', 'Doddpathre', 'Drumstick',
    'Ekka', 'Eucalyptus', 'Ginger', 'Guava', 'Hibiscus',
    'Honge', 'Jasmine', 'Lemongrass', 'Marigold', 'Mint',
    'Neem', 'Nelavembu', 'Tamarind', 'Tulsi', 'Turmeric'
]

NUM_CLASSES = len(CLASS_NAMES)
DEVICE = torch.device("cuda" if torch.cuda.is_available() else "cpu")

transform = transforms.Compose([
    transforms.Resize((384, 384)),
    transforms.ToTensor(),
    transforms.Normalize(
        mean=[0.485, 0.456, 0.406],
        std=[0.229, 0.224, 0.225]
    )
])

class PlantPredictor:
    _instance = None
    _model = None

    @classmethod
    def get_instance(cls):
        if cls._instance is None:
            cls._instance = cls()
        return cls._instance

    def __init__(self):
        self.load_model()

    def load_model(self):
        if not os.path.exists(MODEL_PATH):
            raise FileNotFoundError(f"Model not found at: {MODEL_PATH}")

        print(f"Loading EfficientNetV2 model from {MODEL_PATH}...")
        self._model = models.efficientnet_v2_s(weights=None)
        self._model.classifier[1] = nn.Linear(
            self._model.classifier[1].in_features, NUM_CLASSES
        )

        self._model.load_state_dict(torch.load(MODEL_PATH, map_location=DEVICE, weights_only=True))
        self._model = self._model.to(DEVICE)
        self._model.eval()
        print("Model loaded successfully.")

    def predict(self, image_bytes: bytes):
        if self._model is None:
            self.load_model()

        img = Image.open(io.BytesIO(image_bytes)).convert("RGB")
        tensor = transform(img).unsqueeze(0).to(DEVICE)

        with torch.no_grad():
            outputs = self._model(tensor)
            probs = torch.softmax(outputs, dim=1)
            top5 = torch.topk(probs, 5)

        top5_results = []
        for i in range(5):
            idx = top5.indices[0][i].item()
            conf = top5.values[0][i].item()
            top5_results.append({
                "plantKey": CLASS_NAMES[idx].lower().replace(" ", "_"), # Keep plantKey format compatible with our frontend
                "plantName": CLASS_NAMES[idx],
                "confidence": conf
            })

        return top5_results
