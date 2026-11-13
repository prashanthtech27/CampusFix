# CampusFix

**Campus Issue Reporting and Resolution System**

CampusFix is a Flutter-based application designed to make campus maintenance complaints easier to report, assign, track, and resolve. It provides separate workflows for students, maintenance staff, and coordinators.

## Project Overview

Campus maintenance issues may be reported through disconnected channels, making it difficult to track progress, assign responsibility, and confirm resolution. CampusFix brings the complaint process into one application and gives each role a clear set of actions.

## Key Features

### Student
- Register and log in.
- Submit campus maintenance complaints by category and location.
- View submitted complaints and their current status.
- Track complaint progress.
- View complaint-related notifications.
- Manage profile information.

### Maintenance Staff
- View complaints assigned to them.
- Review complaint details.
- Track assigned, in-progress, and completed work.
- Update the progress of assigned complaints.

### Coordinator
- View and manage reported complaints.
- Assign complaints to maintenance staff.
- Monitor staff workloads and complaint status.
- Review complaint analytics and department statistics.
- Generate and export complaint reports.
- Manage coordinator settings.

## Complaint Workflow

1. **Report:** A student submits a maintenance complaint.
2. **Review and assignment:** The coordinator reviews the complaint and assigns it to suitable maintenance staff.
3. **Accept and work:** Staff reviews the assignment and works on the issue.
4. **Update:** Staff updates the complaint status and records the work outcome.
5. **Verification and closure:** The coordinator reviews the completed work and closes the complaint.

## Application Screenshots

The screenshots below use test/demo data.

### Student Module

| Login | Registration |
|---|---|
| ![Student login](assets/screenshots/student/login-student.png) | ![Student registration](assets/screenshots/student/student-registration.png) |

| Student dashboard | My complaints |
|---|---|
| ![Student dashboard](assets/screenshots/student/student-dashboard.png) | ![My complaints](assets/screenshots/student/my-complaints.png) |

| Complaint details | Report an issue |
|---|---|
| ![Complaint details](assets/screenshots/student/complaint-details.png) | ![Report issue](assets/screenshots/student/report-issue.png) |

| Notifications | Student profile |
|---|---|
| ![Notifications](assets/screenshots/student/notifications.png) | ![Student profile](assets/screenshots/student/student-profile-overview.png) |

| Profile details | Edit profile |
|---|---|
| ![Profile details](assets/screenshots/student/student-profile-details.png) | ![Edit profile](assets/screenshots/student/edit-profile.png) |

### Maintenance Staff Module

| Staff login | Staff dashboard |
|---|---|
| ![Maintenance login](assets/screenshots/staff/maintenance-login.png) | ![Staff dashboard](assets/screenshots/staff/staff-dashboard.png) |

| Assigned issues – empty state | Assigned issues – in progress |
|---|---|
| ![No assigned issues](assets/screenshots/staff/assigned-issues-empty.png) | ![In progress issues](assets/screenshots/staff/assigned-issues-in-progress.png) |

| Completed issues |
|---|
| ![Completed issues](assets/screenshots/staff/assigned-issues-completed.png) |

### Coordinator Module

| Coordinator login | Coordinator dashboard |
|---|---|
| ![Coordinator login](assets/screenshots/coordinator/coordinator-login.png) | ![Coordinator dashboard](assets/screenshots/coordinator/coordinator-dashboard.png) |

| Navigation menu | Staff management |
|---|---|
| ![Coordinator navigation](assets/screenshots/coordinator/coordinator-navigation.png) | ![Staff management](assets/screenshots/coordinator/staff-management-overview.png) |

| Staff list | Complaint management |
|---|---|
| ![Staff list](assets/screenshots/coordinator/staff-management-list.png) | ![Complaint management](assets/screenshots/coordinator/complaint-management.png) |

| Assignment overview | Assignment list |
|---|---|
| ![Assignment overview](assets/screenshots/coordinator/assignment-management-overview.png) | ![Assignment list](assets/screenshots/coordinator/assignment-management-list.png) |

| Analytics overview | Analytics charts |
|---|---|
| ![Analytics overview](assets/screenshots/coordinator/analytics-overview.png) | ![Analytics charts](assets/screenshots/coordinator/analytics-charts.png) |

| Reports management | Staff performance report |
|---|---|
| ![Reports management](assets/screenshots/coordinator/reports-management.png) | ![Staff performance](assets/screenshots/coordinator/staff-performance-reports.png) |

| Coordinator settings | Notification preferences |
|---|---|
| ![Coordinator settings](assets/screenshots/coordinator/coordinator-settings.png) | ![Notification preferences](assets/screenshots/coordinator/coordinator-notification-settings.png) |

## Technology Stack

| Area | Technology |
|---|---|
| Mobile application | Flutter |
| Programming language | Dart |
| Authentication | Firebase Authentication |
| Database | Cloud Firestore |
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
└── widgets/
```

## Getting Started

### Prerequisites
- Flutter SDK
- Android Studio or Visual Studio Code
- Git
- Android emulator or physical Android device

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

CampusFix uses Firebase Authentication and Cloud Firestore. Configure the Firebase project for your own development environment and ensure the Android application ID and generated FlutterFire options match your Firebase project. Enable the authentication method used by the app and configure the required Firestore database and security rules.

Do not commit Firebase Admin SDK service-account private keys, passwords, or server secrets. Review Firebase security rules before using real student or campus data.

### 4. Run the application

```bash
flutter devices
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

CampusFix is an academic project under development. Features and workflows may change as implementation and testing continue.

## License

No open-source license has been specified for this repository. All rights remain with the project authors unless a license is added.
