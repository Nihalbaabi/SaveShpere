# Product Requirements Document (PRD)
**Product Name:** SaveSphere (formerly EcoTrack / EcoWatt)
**Platform:** Multi-platform (Android, iOS, Web, Windows)
**Tech Stack:** Flutter (Frontend), Firebase (Backend/Auth), ESP32 (Hardware IoT)

---

## 1. Product Overview
**SaveSphere** is a smart utility management and home automation application designed to help users track, analyze, and optimize their electricity and water consumption. By connecting to custom IoT hardware, the app provides real-time data monitoring, bidirectional smart home controls, slab-based billing predictions, and an intelligent AI assistant that offers insights and detects anomalies.

## 2. Target Audience
- **Eco-conscious Consumers:** Individuals looking to reduce their carbon and water footprints.
- **Budget-focused Households:** Users who want detailed forecasts on their upcoming utility bills based on active usage.
- **Smart Home Enthusiasts:** Users who want centralized, bidirectional control over room-specific appliances and water valves.

---

## 3. Core Features & Requirements

### 3.1. Real-Time Dashboard & Monitoring
- **Live Utility Feed:** Display real-time active power load (kW) and current water flow (L/min).
- **Hardware Status:** Visual indicator for IoT device connection status (e.g., ESP32 Online/Offline).
- **Quick Comparisons:** High-level dashboard cards comparing today's usage vs. yesterday's.

### 3.2. Deep Analytics (Energy & Water)
- **Unified Analytics Screen:** A toggle-based interface to seamlessly switch between Energy and Water metrics.
- **Consumption History:** Intuitive charting (graphs/bar charts) for daily, weekly, and monthly histograms.
- **Predictive Billing:** Slab-based calculation algorithms to estimate end-of-month bills based on current consumption velocity.
- **Zone Distribution:** Breakdown of power and water usage by specific rooms (e.g., Bedroom, Kitchen, Living Room).

### 3.3. Smart Home Synchronization & Control
- **Room-Level Control:** Bidirectional toggles to control power and water states for individual rooms.
- **Bulk Actions:** Global commands for "Turn all On/Off", controlling the main motor pump, or master water valves.
- **State Synchronization:** Zero-latency syncing between the physical hardware state, Firebase backend, and UI to prevent feedback loops.

### 3.4. SaveSphere AI Assistant
- **Conversational Interface:** Voice and text-based interaction for querying app data.
- **Intent Recognition:** Understands natural queries regarding:
  - Daily/Weekly/Monthly usage reports.
  - Room comparisons ("Which room consumes the most power?").
  - Current utility bill and end-of-month predictions.
  - Voice-activated hardware control ("Turn off the bedroom").
- **Proactive Intelligence:** Anomalous spike detection and automated saving suggestions (Severity-based alerts).

### 3.5. Security & Data Architecture
- **Authentication:** Secure Firebase manual login flow with strict user-specific data partitioning.
- **Cloud Database:** Structurally secure Firebase Realtime/Firestore rules preventing undefined node generation and unauthorized access.

---

## 4. User Scenarios / Use Cases
1. **The Bill Checker:** A user taps the AI Assistant and asks, "What's my expected water bill?" The AI calculates the current trajectory using the slab tariff and replies instantly.
2. **The Forgetful Leaver:** User realizes they left the bedroom lights/AC on. They open the app and toggle the "Bedroom" power off; Firebase syncs this to the ESP32 in real-time.
3. **The Data Nerd:** User wants to see if their new shower head saves water. They open the Analytics tab, switch to Water, and review the week-over-week consumption drop in liters.

---

## 5. Non-Functional Requirements
- **Performance:** 60fps polished UI with smooth animations (implemented using Flutter).
- **Aesthetics:** Premium, modern dark/light themes featuring glassmorphism elements, custom fonts, and micro-interactive widgets.
- **Scalability:** Codebase optimized through `dart fix` and structured with strong state-management Providers to support scaling easily without frame drops.

---

## 6. Future Scope / Roadmap
- Third-party IoT Integrations (e.g., Google Home, Alexa).
- Gamification of energy/water savings (community leaderboards, achievement badges).
- Machine Learning on-device model training for highly accurate localized anomaly detection.
