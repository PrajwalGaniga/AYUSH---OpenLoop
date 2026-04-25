# AYUSH — Project Overview & Technical Architecture

## 1. Project Summary
- **Project Name:** AYUSH (Predictive Ayurvedic Health Engine)
- **Purpose & Problem Solved:** AYUSH is a premium, AI-powered health companion platform that bridges ancient Ayurvedic wisdom with modern clinical technology. Its core goal is to holistically assess a user's health (Prakriti and OJAS) and predict their vitality ("OJAS" score) 3 days in advance using predictive machine learning.
- **Tech Stack:**
  - **Frontend:** Flutter (Riverpod for state management, GoRouter for navigation, Material 3, Custom Painters for UI)
  - **Backend:** FastAPI (Python 3.10+)
  - **Database:** MongoDB (Motor async driver)
  - **AI / ML Frameworks:** PyTorch (EfficientNet V2, LSTM), MediaPipe, PaddleOCR, YOLO
  - **External Cloud Services:** Google GenAI SDK (Gemini 2.5 Flash), Twilio (Emergency SMS)
- **Current Development Status:** Core feature modules (Auth, Onboarding, Food, Yoga, Community, Plant ID, Recipes) are fully built and functioning. The predictive daily logging infrastructure (LSTM data collection) and biometric modules (PPG, Tongue, Eye) are in the development pipeline.

---

## 2. Architecture Overview
AYUSH employs a modular, client-server architecture:
- **Mobile Client (Flutter):** Acts as the primary interface, capturing user inputs, streaming camera data (for Yoga and Plant scans), and rendering complex clinical dashboards like the Dosha Radar. It delegates heavy processing to the backend to conserve device battery and maintain high performance.
- **API Gateway & Processing (FastAPI):** Exposes RESTful endpoints grouped by module. It handles data validation (Pydantic), orchestrates ML inferences (invoking PyTorch models or external APIs like Gemini), and manages database connections.
- **Data Layer (MongoDB):** A NoSQL approach allowing flexible schema designs for complex medical histories, dynamic food logs, and geospatial community posts.
- **AI/ML Layer:** A hybrid approach using on-device processing where necessary (TFLite/MediaPipe) and heavy backend inference (EfficientNet, YOLO, PaddleOCR, Gemini) for robust results.

---

## 3. Completed Features (What Has Been Done)

### 1. Auth & Onboarding (`auth` & `onboarding`)
- **What it does:** Secure login and a 6-step clinical onboarding wizard capturing demographics, localized pain (body scan), Prakriti quiz, lifestyle habits, and medical reports.
- **Internal Logic:** The Prakriti Engine calculates exact Vata/Pitta/Kapha percentages based on 24 questions. The backend calculates an initial OJAS score (0-100). Gemini 2.5 Flash is used to extract vitals and notes directly from uploaded medical PDFs/images.
- **Status:** Complete.

### 2. Food Impact Analyzer (`food_scan`)
- **What it does:** Users take a picture of their meal, and the app calculates how it affects their OJAS score.
- **Internal Logic:** The backend uses a YOLO model to detect food items, maps them against a JSON database of Ayurvedic properties, and calculates an `ojas_delta`.
- **Status:** Complete (Missing daily log persistence).

### 3. Packaged Food Scanner (`packaged_food`)
- **What it does:** Users scan ingredient labels on packaged foods to get a "Buy or Skip" Ayurvedic recommendation.
- **Internal Logic:** PaddleOCR extracts the text from the image. Gemini 2.5 Flash analyzes the ingredients against the user's specific health profile (allergies, Prakriti) to flag harmful chemicals or incompatible items.
- **Status:** Complete.

### 4. Yoga Posture Analyzer (`yoga`)
- **What it does:** Real-time pose checking via the device camera, providing TTS (Text-to-Speech) feedback on alignment.
- **Internal Logic:** MediaPipe detects body joints. The backend calculates specific joint angles and compares them to ideal reference asanas to generate an accuracy percentage.
- **Status:** Complete (Missing daily log persistence).

### 5. Medicinal Plant Identifier (`plant`)
- **What it does:** Identifies Ayurvedic medicinal plants from photos and allows users to ask an AI questions about the plant.
- **Internal Logic:** PyTorch EfficientNet V2 model performs image classification. Gemini handles the Q&A interactions based on the identified plant context.
- **Status:** Complete.

### 6. Ayurvedic Recipe Generator (`recipe`)
- **What it does:** Generates personalized recipes based on current seasons (Ritucharya), dosha balance, and available ingredients, linking to YouTube tutorials.
- **Internal Logic:** Prompt engineering via Gemini 2.5 Flash combined with YouTube Data scraping/search.
- **Status:** Complete.

### 7. Plant Community (`community`)
- **What it does:** A social feed for discovering medicinal plants near the user. Users can post findings and request peer-to-peer contact.
- **Internal Logic:** Uses MongoDB Geohash indexing for efficient location-based querying.
- **Status:** Complete.

### 8. Emergency SOS (`sos`)
- **What it does:** Allows users to trigger an immediate SMS alert to emergency contacts.
- **Internal Logic:** Integrates the Twilio Python SDK to dispatch messages.
- **Status:** Complete.

---

## 4. Database Schema & Storage

| Collection Name | Key Fields | Trigger Action | Relationships |
| :--- | :--- | :--- | :--- |
| **`users`** | `_id`, `phone`, `password` (plaintext per spec), `profile` (dict: prakriti %, conditions, demographics, current `ojas`) | Account creation, Onboarding completion, Profile edits. | Root entity. |
| **`food_logs`** | `user_id`, `items_detected`, `ojas_delta`, `timestamp` | Triggered when a user scans a meal using the Food Impact Analyzer. | Belongs to `users`. |
| **`session_logs`** | `user_id`, `asana_name`, `duration`, `accuracy`, `timestamp` | Triggered when a user completes a Yoga Analyzer session. | Belongs to `users`. |
| **`plant_posts`** | `_id`, `user_id`, `plant_name`, `location.geohash`, `status`, `created_at` | Triggered when a user shares a plant finding to the community. | Belongs to `users`. |
| **`contact_requests`** | `from_user_id`, `to_user_id`, `status` | Triggered when a user requests to connect with a community member. | Links two `users`. |
| **`recipe_history`** | `user_id`, `recipe_hash`, `recipe_data`, `timestamp` | Triggered when a user saves a generated recipe. | Belongs to `users`. |

*(Note: `daily_logs`, `checkins`, `analysis_captures`, and `ojas_history` are mapped out in the architecture but not yet persisting in MongoDB).*

---

## 5. API Routes & Endpoints

| Method | Endpoint Path | Description | Auth Required |
| :--- | :--- | :--- | :--- |
| **POST** | `/api/v1/auth/register` | Registers a new user. | No |
| **POST** | `/api/v1/auth/login` | Authenticates user and returns JWT. | No |
| **GET** | `/api/v1/auth/me` | Fetches current user profile. | Yes |
| **POST** | `/api/v1/step1...6` | Submits individual steps of the onboarding wizard. | Yes |
| **POST** | `/api/v1/food/scan` | YOLO detection of food items from an image. | Yes |
| **POST** | `/api/v1/food/analyze` | Calculates nutritional/Ayurvedic breakdown. | Yes |
| **POST** | `/api/v1/packaged_food/analyze` | OCR + Gemini analysis of packaged food labels. | Yes |
| **POST** | `/api/v1/recipe/generate` | Generates a custom recipe. | Yes |
| **GET** | `/api/v1/recipe/youtube` | Fetches YouTube video links for a recipe. | Yes |
| **GET** | `/api/v1/yoga/asanas` | Lists available yoga postures. | Yes |
| **POST** | `/api/v1/yoga/check_pose` | Analyzes joint angles against a specific asana. | Yes |
| **POST** | `/api/v1/plant/identify` | Classifies an image of a medicinal plant. | Yes |
| **POST** | `/api/v1/plant/ask` | Contextual Q&A about an identified plant. | Yes |
| **POST** | `/api/v1/sos/trigger` | Dispatches emergency Twilio SMS. | Yes |

---

## 6. ML / AI Components

1.  **Google Gemini 2.5 Flash API:**
    *   **Purpose:** Medical report text extraction, personalized packaged food safety analysis, and contextual recipe generation.
2.  **PaddleOCR:**
    *   **Purpose:** Robust text extraction from unstructured images of packaged food ingredient labels.
3.  **YOLO (You Only Look Once):**
    *   **Purpose:** Object detection to identify distinct food items on a plate for caloric and Ayurvedic breakdown.
4.  **MediaPipe:**
    *   **Purpose:** Real-time human pose estimation (identifying 33 3D bodily landmarks) for the Yoga posture checker.
5.  **EfficientNet V2 (PyTorch):**
    *   **Purpose:** Medicinal plant image classification.
    *   **Storage:** Weights saved locally (`efficientnet_v2_best_final`), loaded into memory via Python predictors on FastAPI startup.
6.  **LSTM (PyTorch) - *Pending Integration*:**
    *   **Purpose:** Predicts OJAS score 3 days in advance.
    *   **Architecture:** Input (7 days x 12 features) -> LSTM(64) -> LSTM(32) -> Dense(16) -> Output(1).
    *   **Preprocessing:** MinMaxScaler (`normalizer.pt`).

---

## 7. Blockchain Components
*(No blockchain or Web3 components are implemented in this project).*

---

## 8. Frontend Pages & Components

| Screen / Page | Route Path | Description |
| :--- | :--- | :--- |
| **Auth** | `/login`, `/register` | Handles user authentication and session initialization. |
| **Onboarding** | `/onboarding/0...5` | 6-step wizard collecting health data, doshas, and PDFs. |
| **Ojas Reveal** | `/ojas-reveal` | Highly animated screen revealing the initial calculated OJAS score. |
| **Home/Dashboard** | `/home` | Main landing page with quick actions and summary metrics. |
| **Profile** | `/profile`, `/profile/edit` | Displays the dynamic Dosha Radar chart and allows edits. |
| **Food Scan** | `/food/scan...results` | Camera interface, confirmation, and deep audit results. |
| **Packaged Food** | `/packaged-food/scan` | OCR camera capture and analysis result screens. |
| **Recipe** | `/recipe/select...history` | Ingredient selector, recipe viewer, cooking mode, and history. |
| **Yoga** | `/yoga/home...check` | Asana catalog, detailed instructions, and real-time camera pose checking. |
| **Plant ID** | `/plant/camera...ask` | Camera capture, confidence results, and AI chat interface. |
| **Community** | `/community` | Map/List view of geotagged plant posts. |

---

## 9. Final Achievements & Outcomes
- **End-to-End Multi-Modal Platform:** Successfully integrated Image Classification, Object Detection, OCR, Pose Estimation, and LLM text generation into a single cohesive mobile application.
- **Clinical-Lifestyle UI/UX:** Built a premium, animated, and state-managed Flutter frontend that successfully gamifies complex Ayurvedic health data.
- **Extensible Micro-Module Backend:** A highly robust FastAPI architecture that cleanly separates routing, database interactions, and ML inference code, ensuring stability.

---

## 10. What Is Pending / Future Scope

### 1. The Predictive Logging Pipeline (Critical Missing Piece)
While modules are fully functional individually, they do not currently save their discrete events (e.g., `food_quality_score`, `yoga_accuracy`) to a unified `daily_logs` collection. A midnight cron consolidation job needs to be implemented to generate the daily 12-feature vector.

### 2. Biometric Capture Modules (Module A, B, C)
- **PPG Heart Rate:** Extracting BPM and HRV via the device flashlight and rear camera (detrend -> bandpass -> FFT).
- **Tongue Analysis:** OpenCV HSV segmentation to determine coating and color scores.
- **Eye Analysis:** LAB colorspace thresholding to determine redness index and jaundice flags.

### 3. The LSTM Predictive Engine
Once the `daily_logs` are populating correctly, the backend must integrate the PyTorch LSTM model to query the 7-day sequences, predict the OJAS drop, and generate rule-based Interventions (e.g., *CRITICAL ALERT: Pitta user -> recommend cooling foods*).

### 4. Known Bugs to Address
- **Yoga MediaPipe Latency:** Streaming raw video to the backend is highly inefficient. MediaPipe processing should be migrated to run entirely on-device within Flutter.
- **Food Data Loss:** The YOLO and PaddleOCR modules currently overwrite the `ojas` score dynamically but fail to append the results to an event ledger, causing data loss for trend analysis.
