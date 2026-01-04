# Xen — Ultra-Minimalist Job Marketplace

Xen is a modern, high-performance job finder application built with Flutter and Firebase. It follows an "Ultra-Minimalist" and "Flat 2.0" design philosophy, focusing on visual excellence, speed, and real-time interactions.

## ✨ Core Features

- **Live Notification System**: Real-time alerts for job applications and interactions with rich detail views.
- **Smart Matching System**: Dynamic "Matching Tag" logic that highlights jobs aligning with user interests.
- **Real-time Synchronization**: Job listings and application statuses sync instantly with Firestore (Live Listeners).
- **Personalized Job Feed**: Recommended jobs based on user-selected global interests.
- **Admin Management**: Role-based controls for hiring managers (Add, Edit, Delete jobs).
- **Profile Customization**: Profile picture management with sub-2MB size checks and web-friendly storage integration.
- **Modern UI**: Smooth gradients, micro-animations, and a curated HSL-tailored color palette.

## 🛠 Tech Stack

- **Framework**: [Flutter](https://flutter.dev)
- **State Management**: [Riverpod](https://riverpod.dev) (Notifier & AsyncValue)
- **Backend**: [Firebase](https://firebase.google.com) (Auth, Firestore, Cloud Storage)
- **Navigation**: [GoRouter](https://pub.dev/packages/go_router)
- **Data Modeling**: [Freezed](https://pub.dev/packages/freezed) & [JsonSerializable](https://pub.dev/packages/json_serializable)
- **Typography**: Work Sans & Inter

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (Latest Stable)
- Firebase Account & Project

### Setup

1. **Clone the repository:**
   ```bash
   git clone https://github.com/Raveloon/Xen.git
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Firebase Configuration:**
   - Configure your Firebase project using [FlutterFire CLI](https://firebase.google.com/docs/flutter/setup).
   - Ensure `firebase_options.dart` is generated in `lib/`.

4. **Run the application:**
   ```bash
   flutter run
   ```

5. **Screeenshots:**

Giriş Ekranı :
   
<img width="451" height="990" alt="image" src="https://github.com/user-attachments/assets/a35a20be-c44d-4e46-9f51-830a4352a08e" />

Anasayfa :

<img width="364" height="812" alt="image" src="https://github.com/user-attachments/assets/8767be82-936c-4394-afad-6f78f367b231" />

Hamburger Menu : 

<img width="362" height="815" alt="image" src="https://github.com/user-attachments/assets/56ebcd65-53fc-452d-881e-26f8ba6f25bc" />

İlgi Alanı Seçme Sayfası (admin):

<img width="368" height="812" alt="image" src="https://github.com/user-attachments/assets/6f5fec58-24e0-4d83-9f14-a6c785dd300e" />

Kişiye Özel İlan Sayfası ;

<img width="369" height="802" alt="image" src="https://github.com/user-attachments/assets/0fb25b98-0806-4495-b9bf-d656e3cba1a7" />

Favoriler :

<img width="371" height="806" alt="image" src="https://github.com/user-attachments/assets/28fa9545-7ace-4f40-aeee-76a6d18056b6" />


## 📄 License

This project is for demonstration and portfolio purposes. All rights reserved.
