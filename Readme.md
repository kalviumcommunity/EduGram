# 📚 Rural Coaching Management App

A lightweight, offline-first mobile application built using **Flutter** and **Firebase** to help rural coaching centers manage student attendance and academic progress efficiently.

---

## 📌 Problem Statement

Rural coaching centers often rely on paper registers to track student attendance and academic performance. This leads to:

* Loss or damage of records
* Manual calculation of attendance and marks
* No performance analytics
* Parents being unaware of student progress
* Difficulty using complex digital systems
* Poor internet connectivity issues

There is a need for a simple, reliable, and accessible digital solution tailored for rural environments.

---

## 🎯 Objective

To build a lightweight mobile application that:

* Replaces paper-based attendance registers
* Automatically tracks student performance
* Works even with low internet connectivity
* Provides secure cloud backup
* Is simple enough for non-technical teachers

---

## 👥 Target Users

### Admin (Institute Owner)

* Create and manage institute
* Add teachers
* Assign batches
* View overall reports

### Teacher (Primary User)

* Create batches
* Add students
* Take attendance
* Enter marks
* View reports

---

## 🏗️ System Architecture

The app follows an **Offline-First Architecture**:

```
Mobile Device (Local Storage)
        ↓
   Auto Sync System
        ↓
Firebase Cloud (Permanent Backup)
```

* Data is stored locally first
* Automatically synced when internet becomes available
* Prevents data loss even in low-network rural areas

---

## 🚀 Core Features (MVP)

* Phone OTP Authentication
* Batch Management
* Student Management
* Attendance Tracking
* Attendance History

---

## 📊 Future Enhancements

* Marks & Test Management
* Performance Analytics
* Parent Notifications
* Fees Tracking
* Admin Dashboard

---

## 🛠️ Tech Stack

**Frontend:** Flutter
**Backend:** Firebase Firestore
**Authentication:** Firebase Phone OTP
**Local Storage:** Hive / SQLite
**Cloud Backup:** Firebase

---

## 📱 Lightweight Design Goals

* App size under 50 MB
* Optimized for low-end Android devices
* Minimal data consumption
* Fast loading screens
* Simple and clean UI

---

## 🔒 Why This Solution Works

| Problem            | Solution             |
| ------------------ | -------------------- |
| Registers get lost | Cloud backup         |
| Manual calculation | Automatic reports    |
| Low internet       | Offline-first design |
| Complex systems    | Simple mobile UI     |

---

## 🏁 Development Strategy

The app is built feature-by-feature:

1. Authentication
2. Batch Management
3. Student Management
4. Attendance System
5. Reports & Enhancements

This ensures stability and incremental progress.

---

## 📌 Project Vision

To digitally empower rural coaching centers with a simple, reliable, and accessible student management system.

---
