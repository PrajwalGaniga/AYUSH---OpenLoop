# AYUSH Platform: OJAS (Vitality) Score Algorithm

This document outlines the detailed algorithmic process used in the AYUSH backend to calculate a user's **OJAS Score** (Vitality Score). The engine computes this score holistically by factoring in pre-existing medical conditions and specific daily lifestyle choices.

## 1. Base Score
Every user starts with an inherent vitality baseline.
* **Base Ojas Score:** `100`

---

## 2. Penalty Deductions (Dosha/Dhatu Depletion)
Penalties represent habits, environments, or conditions that actively deplete vitality and lower the overall Ojas.

### 🏥 Medical & Health Conditions
Deductions are applied dynamically based on arrays of reported or extracted medical conditions.
* **Chronic Conditions:** `-15 points` *(Applied per condition)*
  * *Example: Diabetes, Hypertension, Asthma.*
* **Diagnosed Conditions:** `-5 points` *(Applied per condition)*
  * *Example: Recent infections, acute illness.*
* **Mental Health Conditions:** `-5 points` *(Applied per condition)*
  * *Example: Anxiety, Depression.*

### 🛌 Sleep & Recovery
* **Poor Sleep:** `-5 points`
  * *Triggered if reported sleep is `< 6 hours`.*

### 🧘‍♂️ Activity & Occupation
* **Sedentary Lifestyle:** `-5 points`
  * *Triggered if occupation type is strictly `sedentary`.*

### 🍷 Vices & Stress
* **Smoking Habit:** `-10 points`
  * *Triggered if smoking status is `regular` or `heavy`.*
* **Regular Alcohol Use:** `-7 points`
  * *Triggered if alcohol consumption is `regular` or `heavy`.*
* **Chronic High Stress:** `-8 points`
  * *Triggered if stress levels are reported as `often`, `very_often`, or `always`.*

### 💧 Nutrition & Intake
* **Poor Hydration:** `-3 points`
  * *Triggered if daily water intake is `< 1.5 Liters`.*

---

## 3. Bonus Additions (Ojas Builders)
Bonuses represent proactive lifestyle choices and habits that build immunity, balance doshas, and increase vitality.

### 🧘‍♂️ Mind & Body Practices
* **Yoga Practice:** `+5 points`
  * *Triggered if the user actively practices Yoga.*
* **Meditation Practice:** `+5 points`
  * *Triggered if the user actively practices Meditation.*

### 🥗 Diet & Nutrition
* **Plant-based Diet:** `+3 points`
  * *Triggered if diet type is `vegetarian` or `vegan`.*
* **Excellent Hydration:** `+3 points`
  * *Triggered if daily water intake is `≥ 2.5 Liters`.*

### 🏃‍♂️ Recovery & Activity
* **Healthy Sleep:** `+4 points`
  * *Triggered if sleep hours are strictly between `7` and `9` hours.*
* **Regular Exercise:** `+5 points`
  * *Triggered if exercise frequency is `3_4_week` (3-4 times a week) or `daily`.*

---

## 4. Final Calculation & Constraints

The system aggregates the base score, all triggered penalties, and all triggered bonuses. Because Ojas represents a percentage scale of vitality, the engine applies clamping logic to ensure the final score never exceeds logical boundaries.

**Formula:**
`Final Score = Base Score (100) + Total Bonuses - Total Penalties`

**Constraint Logic:**
```python
final_score = max(0, min(100, base + total_penalty + total_bonus))
```
* **Maximum Score:** `100` (Even if a perfectly healthy person acquires extra bonuses, it caps at 100).
* **Minimum Score:** `0` (If penalties exceed the base 100 points, the score bottoms out at 0, representing a state of absolute medical urgency/depletion).

---

## 📝 Example Calculation Scenarios

### Case 1: The Healthy Yogi
* Base: `100`
* Bonuses: Vegan (`+3`), Yoga (`+5`), Meditation (`+5`), Exercise Daily (`+5`), Sleep 8 hrs (`+4`), Water 3L (`+3`)
* Penalties: None (`0`)
* Math: `100 + 25 - 0 = 125`
* **Final Ojas:** `100` (Clamped maximum)

### Case 2: The Stressed Corporate Worker
* Base: `100`
* Bonuses: None (`0`)
* Penalties: Sedentary (`-5`), High Stress (`-8`), Sleep 5 hrs (`-5`), Water 1L (`-3`)
* Math: `100 + 0 - 21 = 79`
* **Final Ojas:** `79`

### Case 3: The Chronic Patient
* Base: `100`
* Bonuses: Vegetarian (`+3`), Sleep 8 hrs (`+4`)
* Penalties: Chronic Diabetes (`-15`), Hypertension (`-15`), Regular Smoking (`-10`)
* Math: `100 + 7 - 40 = 67`
* **Final Ojas:** `67`
