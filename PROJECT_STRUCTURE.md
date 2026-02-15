# FlatChore Project Breakdown

This document provides a detailed explanation of the FlatChore project structure, its components, and how they work together.

## 🚀 Overview
FlatChore is a Flutter application designed for flatmates to manage shared household tasks (chores). It uses **Firebase Authentication** for user management and **Cloud Firestore** as a real-time database to store flat and chore information.

---

## 📂 Project Structure

### 1. The Entry Point (`lib/main.dart`)
- **What it does**: This is where the app starts. It initializes Firebase services and sets up the root `MaterialApp`.
- **Key Component**: `MyApp` sets the global theme and points the "home" of the app to the `Wrapper` widget.

### 2. The Traffic Controller (`lib/screens/wrapper.dart`)
- **What it does**: Acts as a switchboard that decides which screen the user should see based on their "state."
- **Logic**:
    - **No User?** -> Show `LoginScreen`.
    - **User Logged In but No Flat?** -> Show `JoinFlatScreen`.
    - **User Logged In & Has Flat?** -> Show `HomeScreen`.

---

## 🏗️ Core Components

### 🟢 Data Models (`lib/models/`)
These are "Blueprints" for the data used in the app. They help convert raw data from Firebase into easy-to-use Dart objects.
- **`user_model.dart`**: Stores user info (ID, name, email, and the `currentFlatId`).
- **`flat_model.dart`**: Stores flat details (ID, name, password for joining, and list of member IDs).
- **`chore_model.dart`**: The most complex model. Stores chore title, frequency (Daily/Weekly), who is currently assigned, and the list of participants in the rotation.

### 🟡 Services (`lib/services/`)
These contain the "Business Logic." If the app needs to talk to the internet or a database, it happens here.
- **`auth_service.dart`**: Handles Sign In, Sign Up, and Sign Out using Firebase Auth.
- **`flat_service.dart`**: Manages flat creation, searching for flats by name, and joining/leaving flats.
- **`chore_service.dart`**: The "Heart" of the app. It handles:
    - **Streaming chores**: Listening for real-time updates.
    - **Completing chores**: Logic to rotate the chore to the next person and update the due date.
    - **History**: Saving a record every time someone completes a task.

### 🔵 Screens (`lib/screens/`)
These are the full pages the user sees.
- **Auth Screens**: `login_screen.dart` & `register_screen.dart`.
- **Flat Screens**: `create_flat_screen.dart` & `join_flat_screen.dart` (where you find your roommates).
- **Home Screens**:
    - `home_screen.dart`: The main dashboard showing all chores.
    - `add_chore_screen.dart`: A form to create new tasks.
    - `chore_detail_screen.dart`: Detailed view of a chore, including completion history.

### 🟣 Widgets (`lib/widgets/`)
Small, reusable UI building blocks.
- **`chore_card.dart`**: The card shown on the home screen for each task. It contains "Complete" buttons and status indicators.
- **`flat_drawer.dart`**: The side menu that allows users to switch between screens or leave the flat.

---

## ⚙️ Key App Logic: Chore Rotation
The rotation logic is located in `chore_service.dart` inside the `completeChore` function:
1. When a user clicks "Complete", the app finds the current `rotationIndex`.
2. It calculates the `nextIdx` by moving to the next person in the `participants` list.
3. It updates the `assignedTo` field to the next person.
4. It calculates the `nextDueDate` based on the frequency (e.g., adds 7 days for "Weekly").
5. Everything is updated in Firestore, which automatically refreshes the UI for all roommates via the `StreamBuilder`.

---

## 🛠️ Task List for Understanding
If you want to dive into the code, follow this order:
1. [ ] **`lib/models/user_model.dart`**: See how we represent a user.
2. [ ] **`lib/services/auth_service.dart`**: Understand how users log in.
3. [ ] **`lib/screens/wrapper.dart`**: See how we switch between Login and Home.
4. [ ] **`lib/services/chore_service.dart`**: Read `completeChore` to see how rotation works.
5. [ ] **`lib/widgets/chore_card.dart`**: See how we build a complex UI component.
