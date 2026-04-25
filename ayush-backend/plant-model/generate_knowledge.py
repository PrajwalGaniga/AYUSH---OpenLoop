import json

with open("c:/Users/ASUS/Desktop/OpenLoop/ayush-backend/plant-model/plant_matadata.json", "r", encoding="utf-8") as f:
    meta = json.load(f)

labels = meta["metadata"]["tflite_class_order"]

knowledge = {
    "metadata": {
        "project": "AYUSH",
        "module": "6 — Medicinal Plant Identifier",
        "version": "1.0",
        "total_plants": 30,
        "tflite_model": "plant_classifier_int8.tflite",
        "tflite_class_order": labels,
        "confidence_thresholds": {
            "high": 0.70,
            "medium": 0.50
        },
        "disclaimer": meta["metadata"]["disclaimer"]
    },
    "plants": {},
    "safety_level_config": {
        "safe_with_guidance": {
            "banner_color": "#2d6a4f",
            "banner_text": "Generally safe — follow recommended doses",
            "icon": "✓"
        },
        "caution_external_only": {
            "banner_color": "#f4a261",
            "banner_text": "External use only — do not ingest without expert guidance",
            "icon": "⚠️"
        },
        "toxic_expert_only": {
            "banner_color": "#e63946",
            "banner_text": "TOXIC — For educational reference only. Never self-administer.",
            "icon": "☠️"
        }
    }
}

for i, label in enumerate(labels):
    if label == "aloevera":
        # Copy full data from metadata
        knowledge["plants"][label] = meta["plants"]["aloevera"]
    else:
        # Placeholder data
        is_arali = (label == "arali")
        is_ekka = (label == "ekka")
        
        safety_level = "safe_with_guidance"
        toxicity_warning = None
        if is_arali:
            safety_level = "toxic_expert_only"
            toxicity_warning = "TOXIC — Nerium oleander contains cardiac glycosides. Internal use can cause fatal arrhythmia. Never self-administer. Display red banner in Flutter."
        elif is_ekka:
            safety_level = "caution_external_only"
            toxicity_warning = "Latex is caustic — external use only, never near eyes. Internal use only under Ayurvedic expert supervision."
            
        knowledge["plants"][label] = {
            "id": i,
            "tflite_class_index": i,
            "names": {
                "common": label.replace("_", " ").title(),
                "scientific": "Scientific Name Placeholder",
                "sanskrit": "Sanskrit Placeholder",
                "kannada": "Kannada Placeholder",
                "hindi": "Hindi Placeholder",
                "tamil": "Tamil Placeholder"
            },
            "quick_facts": {
                "plant_type": "Placeholder",
                "parts_used": ["Placeholder"],
                "primary_use": "Placeholder",
                "taste_rasa": "Placeholder",
                "virya": "Placeholder",
                "vipaka": "Placeholder",
                "ama_risk": "low"
            },
            "dosha_effect": {
                "vata": "neutral",
                "pitta": "neutral",
                "kapha": "neutral",
                "summary": "Placeholder dosha summary"
            },
            "prakriti_advice": {
                "vata": "Placeholder vata advice",
                "pitta": "Placeholder pitta advice",
                "kapha": "Placeholder kapha advice"
            },
            "ayurvedic_properties": {
                "guna": ["Placeholder Guna"],
                "agni_impact": "Placeholder agni impact",
                "classical_reference": "Placeholder classical reference"
            },
            "medicinal_uses": [
                {
                    "use": "Placeholder Use",
                    "method": "Placeholder Method",
                    "frequency": "Placeholder Frequency",
                    "duration": "Placeholder Duration"
                }
            ],
            "intake_methods": {
                "external": ["Placeholder external use"],
                "internal": ["Placeholder internal use"],
                "avoided_forms": ["Placeholder avoided form"]
            },
            "contraindications": [
                "Placeholder contraindication"
            ],
            "drug_interactions": [],
            "condition_suitability": {
                "safe_for": ["Placeholder condition"],
                "avoid_if": ["Placeholder condition"],
                "use_with_caution": ["Placeholder condition"]
            },
            "seasonal_advice": {
                "best_season": "Placeholder best season",
                "avoid_season": "Placeholder avoid season"
            },
            "fun_fact": "Placeholder fun fact. Team to fill in later.",
            "safety_level": safety_level,
            "toxicity_warning": toxicity_warning,
            "image_asset": f"assets/plants/{label}.png"
        }

with open("c:/Users/ASUS/Desktop/OpenLoop/ayush-backend/plant-model/plant_knowledge.json", "w", encoding="utf-8") as f:
    json.dump(knowledge, f, indent=2, ensure_ascii=False)

print("Generated plant_knowledge.json")
