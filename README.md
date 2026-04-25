# AYUSH — Ayurvedic Health & Lifestyle Platform

AYUSH is a premium, AI-powered Ayurvedic health companion platform that bridges ancient Ayurvedic wisdom with modern clinical technology. 

The system uses a highly modular architecture split into a **Flutter mobile application** (Riverpod, modern clinical-lifestyle UI) and a **FastAPI backend** (MongoDB, integrating multiple AI/ML models like Gemini 2.5 Flash, MediaPipe, PyTorch, and PaddleOCR).

---

## 🌟 Comprehensive Features & Modules

AYUSH has evolved beyond its initial onboarding scope into a full-fledged holistic health platform. Here are the core features and modules integrated into the system:

### 1. User Profile & Onboarding (`auth` & `onboarding`)
* **Authentication:** Secure Phone + Password login with persistent sessions (JWT via `flutter_secure_storage`).
* **The 6-Step Onboarding Wizard:**
    1. **Basic Profile:** Demographics, metrics (metric/imperial), blood group.
    2. **Body Scan (Pain Mapping):** Interactive human silhouette with 35+ tappable regions for logging localized pain severity.
    3. **Prakriti Quiz:** Comprehensive 24-question assessment to determine Vata, Pitta, and Kapha constitution.
    4. **Lifestyle & Habits:** Diet, stress, sleep, water intake, and habit tracking.
    5. **Health History:** Expandable clinical condition selection and family history.
    6. **Report Upload (AI Extraction):** Uses **Gemini 2.5 Flash** to extract vitals and doctor notes from medical PDFs/images automatically.
* **Prakriti Engine:** Calculates the precise balance of Vata, Pitta, and Kapha.
* **OJAS Score Engine:** Computes a holistic vitality score (0-100) based on metrics, lifestyle, and medical reports.
* **Dynamic User Profile:** Includes a high-fidelity triangular radar chart for real-time Dosha visualization and editable profile settings.

### 2. Packaged Food Scanner (`packaged_food`)
* **OCR Text Extraction:** Utilizes **PaddleOCR** to accurately extract ingredients and nutritional facts from images of packaged food labels.
* **Personalized AI Analysis:** Evaluates the extracted ingredients against the user's specific health profile (allergies, Dosha balance, medical conditions) using **Gemini 2.5 Flash**.
* **Actionable Insights:** Delivers a clear "Buy or Skip" recommendation alongside detailed nutritional warnings and benefits.

### 3. Food & Meal Analysis (`food_scan`)
* Allows users to log and scan their daily meals.
* Provides AI-driven dietary recommendations tailored to balance the user's specific Prakriti and improve their OJAS score.

### 4. Medicinal Plant Identifier (`plant`)
* **AI Image Recognition:** Identifies Ayurvedic medicinal plants from user-uploaded photos using a custom-trained **EfficientNet V2** ML model (built with PyTorch).
* **Botanical Insights:** Provides detailed Ayurvedic properties, benefits, and preparation usage for the identified plants.

### 5. Yoga Posture Analyzer (`yoga`)
* **Real-time Pose Estimation:** Utilizes Google's **MediaPipe** to track bodily landmarks.
* Provides users with alignment feedback and posture corrections to ensure Yoga asanas are performed safely and effectively.

### 6. Ayurvedic Recipe Generator (`recipe`)
* Generates personalized Ayurvedic recipes based on the user's current Dosha state and available ingredients.
* Features a persistent recipe history for saving favorite health-aligned meals.

### 7. Community & Forums (`community`)
* A dedicated social space for users to connect and share Ayurvedic practices.
* **Plant Posts:** Users can share geotagged plant discoveries (using MongoDB Geohash indexing).
* **Contact Requests:** Peer-to-peer connection management.

### 8. Emergency SOS & Fall Detection (`sos`)
* Incorporates safety mechanisms for vulnerable users.
* Integrates **Twilio** to send automated SMS emergency SOS alerts to designated contacts in case of a critical situation or detected fall.

---

## 🛠️ Technology Stack

### Mobile Frontend (`/ayush`)
* **Framework:** Flutter (Material 3)
* **State Management:** Riverpod (`flutter_riverpod`)
* **Routing:** GoRouter
* **Networking:** Dio (with custom JWT interceptors)
* **Design/Animations:** `flutter_animate`, Google Fonts (Playfair Display & Inter), custom canvas drawing (`CustomPainter`).
* **Storage:** `flutter_secure_storage`, `shared_preferences`

### Backend Service (`/ayush-backend`)
* **Framework:** FastAPI (Python 3.10+)
* **Database:** MongoDB (Motor async driver)
* **AI/ML Integrations:**
    * **Google GenAI SDK (Gemini 2.5 Flash):** Medical report extraction and food analysis.
    * **PaddleOCR & PaddlePaddle:** Packaged food label text extraction.
    * **PyTorch & TorchVision:** EfficientNet V2 plant identification.
    * **MediaPipe:** Yoga posture analysis.
* **External APIs:** Twilio (SOS Messaging).
* **Data Validation:** Pydantic

---

## 🚀 Setup & Installation

### 1. Backend (`/ayush-backend`)
1. Navigate to the backend directory:
   ```bash
   cd ayush-backend
   ```
2. Create and activate a Python virtual environment:
   ```bash
   python -m venv venv
   venv\Scripts\activate  # Windows
   ```
3. Install dependencies:
   ```bash
   pip install -r requirements.txt
   ```
4. Configure environment variables:
   Copy `.env.example` to `.env` and fill in your keys:
   ```env
   MONGODB_URL=mongodb://localhost:27017
   DATABASE_NAME=ayush_db
   JWT_SECRET=your_jwt_secret_key_here
   GEMINI_API_KEY=your_gemini_api_key_here
   TWILIO_ACCOUNT_SID=your_twilio_sid
   TWILIO_AUTH_TOKEN=your_twilio_token
   ```
5. Run the FastAPI server:
   ```bash
   uvicorn main:app --reload --host 0.0.0.0 --port 8000
   ```

### 2. Frontend (`/ayush`)
1. Navigate to the Flutter directory:
   ```bash
   cd ayush
   ```
2. Install dependencies:
   ```bash
   flutter pub get
   ```
3. Configure environment variables:
   Copy `.env.example` to `.env` and configure the backend URL:
   ```env
   API_BASE_URL=http://10.0.2.2:8000/api/v1  # Use 10.0.2.2 for Android Emulator, or localhost for iOS/Web
   GEMINI_API_KEY=your_gemini_api_key_here
   ```
4. Ensure image and animation assets are placed in `assets/images/` and `assets/lottie/`.
5. Run the app:
   ```bash
   flutter run
   ```

---

## 🎨 Design System

AYUSH employs a **Clinical-Lifestyle Hybrid** aesthetic to feel both medically trustworthy and holistically inviting.
* **Typography:** `Playfair Display` for elegant headings. `Inter` for highly readable clinical data.
* **Colors:**
  * Primary: Deep Teal (`#1F7A8C`) - Trust, stability, modern healthcare.
  * Secondary: Herbal Green (`#6BA368`) & Warm Sand (`#F4EDE4`) - Ayurvedic grounding.
  * Accents: Soft Gold (`#C8A951`) - Premium touches.
* **Dosha Palette:**
  * Vata: Indigo-purple
  * Pitta: Warm terracotta
  * Kapha: Teal-green

---

## 🔒 Notes on Implementation Details
* **Password Handling:** Passwords are currently configured to specific project requirements. In a production environment outside of these parameters, standard bcrypt hashing must be reintroduced.
* **Component Modularity:** The app utilizes a highly modular structure. Shared UI elements are abstracted to ensure consistency across the application.
* **Algorithmic Documentation:** The computational logic for the Vitality score has been documented. See [ojas_algorithm.md](./ojas_algorithm.md) for details on base scores, medical penalties, and lifestyle bonuses.
