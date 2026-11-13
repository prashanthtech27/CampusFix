# CampusFix

**Campus Issue Reporting and Resolution System**

CampusFix is a Flutter-based mobile application designed to make campus maintenance complaints easier to report, assign, track, and resolve. It provides separate workflows for students, maintenance staff, and coordinators.

## Project Overview

In many campuses, maintenance issues are reported through informal or disconnected channels such as verbal communication, messages, emails, or written requests. This can make it difficult to track complaints, assign responsibility, and confirm that an issue has been resolved.

CampusFix brings the complaint process into one application so that users can follow each issue through its resolution workflow.

## Key Features

### Student
- Register and log in.
- Submit campus maintenance complaints.
- View submitted complaints and their status.
- Track complaint progress.
- Receive and view complaint-related notifications.
- Manage profile information.

### Maintenance Staff
- View complaints assigned to them.
- Review complaint details.
- Accept or decline an assignment.
- Update the progress of assigned work.
- Mark work as resolved and provide a resolution comment.

### Coordinator / Admin
- View and review reported complaints.
- Assign complaints to maintenance staff.
- Monitor assignments and complaint status.
- Review completed work and verify resolution.
- Close complaints after verification.
- Access dashboard and reporting-related screens.

> Features may vary as development progresses. Update this section whenever a feature is added, changed, or removed.

## Complaint Workflow

1. **Report:** A student submits a maintenance complaint.
2. **Review and assignment:** The coordinator reviews the complaint and assigns it to suitable maintenance staff.
3. **Accept or decline:** The assigned staff member accepts the task or declines it so it can be reassigned.
4. **Resolution:** Staff works on the issue, updates its progress, and marks it as resolved with a comment.
5. **Verification and closure:** The coordinator verifies the work and closes the complaint.

## Technology Stack

| Area | Technology |
|---|---|
| Mobile application | Flutter |
| Programming language | Dart |
| Authentication | Firebase Authentication |
| Database | Cloud Firestore |
| Development tools | Visual Studio Code / Android Studio |
| Version control | Git and GitHub |

## Project Structure

```text
lib/
├── main.dart
├── screens/
│   ├── coordinator/
│   ├── staff/
│   ├── student/
│   ├── home_page.dart
│   ├── login_page.dart
│   └── register_page.dart
├── services/
│   ├── auth_service.dart
│   └── complaint_service.dart
└── widgets/
```

The `screens` directory contains role-specific application pages. The `services` directory contains authentication and complaint-related logic, while `widgets` contains reusable UI components.

## Getting Started

### Prerequisites

Install the following before running the project:

- [Flutter SDK](https://docs.flutter.dev/get-started/install)
- [Dart SDK](https://dart.dev/get-dart) (included with Flutter)
- [Android Studio](https://developer.android.com/studio) or [Visual Studio Code](https://code.visualstudio.com/)
- Git
- An Android emulator or a physical Android device

### 1. Clone the repository

```bash
git clone https://github.com/prashanthtech27/CampusFix.git
cd CampusFix
```

### 2. Install dependencies

```bash
flutter pub get
```

### 3. Configure Firebase

CampusFix uses Firebase Authentication and Cloud Firestore.

- Open the Firebase project associated with your development environment.
- Register/configure the Android app using its matching application ID.
- Configure Firebase for Flutter using the official FlutterFire setup instructions.
- Ensure the Firebase configuration files and generated options match your Firebase project.
- Enable the authentication method used by the application.
- Create and configure the required Cloud Firestore database and security rules.

Do not add Firebase Admin SDK service-account private keys, passwords, or other server secrets to this repository. Review Firebase security rules before using real student or campus data.

### 4. Run the application

Check connected devices:

```bash
flutter devices
```

Run CampusFix:

```bash
flutter run
```

## Team

**Team Name:** Byte Builders

**Team Members:**
- Prashanth
- Vihar Kalagi
- Raghu
- Yashwanth

**Institution:** East West College of Engineering  
**Department:** Computer Science and Engineering

## Project Status

CampusFix is an academic project under development. Features, screens, and workflows may be updated as implementation and testing continue.

## Contributing

This project is maintained by the Byte Builders team. Team members should create a separate branch for a feature or fix, test their changes, and submit a pull request for review before merging into `main`.

## License

No open-source license has been specified for this repository. All rights remain with the project authors unless a license is added.
