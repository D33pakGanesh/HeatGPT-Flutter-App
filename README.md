# HeatGPT Flutter App

Flutter Android app for exploring Urban Heat Islands across Australian LGAs.

## Setup

1. Install Flutter 3.41.8
2. Set `flutter.sdk` in `android/local.properties`
3. Run `flutter pub get`
4. Run `flutter run -d <device>`

## Architecture

- **flutter_map** — interactive map with LGA polygon overlays
- **Riverpod** — state management
- **Dio** — HTTP client connecting to the HeatGPT backend API
- **fl_chart** — LST trend and scatter charts
- **pdf + share_plus** — PDF export

## Branches

- `main` — production-ready (future)
- `dev` — active development
