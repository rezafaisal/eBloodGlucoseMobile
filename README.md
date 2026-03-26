# Mobile Blood Glucose Monitoring Application

This mobile application is designed to help users monitor and manage blood glucose data in a practical, accessible, and portable way. The system integrates with a smartwatch equipped with a blood glucose sensor, enabling glucose-related measurements to be collected and processed through a mobile platform. By combining wearable sensing technology, mobile computing, and web-based data management, the application supports both real-time monitoring and long-term tracking of blood glucose conditions.

The mobile application is built using **Flutter**, a cross-platform mobile development framework. As a result, the application can run on both **Android** and **iOS** devices using a single codebase. This approach improves development efficiency, simplifies maintenance, and ensures a consistent user experience across multiple platforms.

In addition to functioning as a standalone monitoring tool, the mobile application is also connected to a **server-side database system** through a **web backend API**. Every blood glucose measurement recorded in the mobile app can be sent to the server, allowing the data to be stored centrally and accessed for further processing, monitoring, and visualization through a web application.

## System Overview

The overall system consists of three main components:

1. **Smartwatch with blood glucose sensor**  
   The smartwatch acts as the primary data source for measuring the user’s blood glucose level.

2. **Flutter-based mobile application**  
   The mobile app receives, manages, displays, and transmits blood glucose data. It serves as the main user interface for daily monitoring.

3. **Web-based system with backend API and frontend dashboard**  
   The web system is used to store, manage, and visualize measurement data on the server side.  
   - The **backend API** is built using **PHP**.  
   - The **web frontend** is built using **Vue**.  

The source code of the web application, including both backend and frontend, is available at:

`https://github.com/rezafaisal/eBloodGlucoseWeb`

## How the Application Works
The workflow of the application can be described as follows:

<p align="center">
  <img src="https://raw.githubusercontent.com/rezafaisal/eBloodGlucoseMobile/main/images/mobile_app.png" alt="Mobile Application Workflow" width="750">
</p>
The primary source of data comes from a **smartwatch equipped with a blood glucose sensor**. The smartwatch collects measurement data from the user and synchronizes the results with the mobile application. The mobile app then processes the received data and presents the information in a form that is easier for users to understand.

In addition to receiving data automatically from the smartwatch, the application also provides a manual input mechanism. This allows users to enter blood glucose readings themselves whenever automatic synchronization is not available or when values are obtained from another measuring device.

The workflow of the application can be described as follows:

### (A) User Login
The first step is user authentication. The user logs into the mobile application using registered account credentials. This login process ensures that all measurement data are linked to the correct user and helps protect the privacy of personal health information.

### (B) Manual and Automatic Input Data
After logging in, the user can record blood glucose data in two ways:
- **Automatic input**, where measurement data are received directly from the smartwatch sensor.
- **Manual input**, where the user enters blood glucose values manually into the application.

This dual-input mechanism improves flexibility and ensures that the system remains usable in different situations.

### (C) Predicted Glucose Status
After the data are entered or synchronized, the application processes the measurement results and displays the **predicted glucose status**. This feature helps users interpret their glucose condition more easily, instead of only viewing raw numerical values. The prediction result may indicate whether the user’s glucose level is within a normal range or falls into a condition that requires attention.

### (D) Tabular Blood Glucose Data History
The recorded data are stored and displayed in a **tabular history view**. This table allows users to review previous blood glucose measurements in a structured format, making it easier to check exact values, timestamps, and recent records.

### (E) Chart of Blood Glucose Data History
The application also provides a **chart visualization** of blood glucose history. This graphical view helps users identify patterns, trends, increases, decreases, and fluctuations in glucose levels over time. Compared with a table alone, charts make long-term monitoring more intuitive and informative.

## Data Transmission to Server

One of the important features of this mobile application is its ability to **send blood glucose measurement results to a server database**. After the measurement data are collected from the smartwatch or entered manually by the user, the mobile application communicates with a **web backend API** to transmit the data to the server.

This server communication enables several important functions:

- **Centralized data storage**, so measurement records are not only stored locally on the device
- **Data synchronization**, allowing the same user data to be accessed consistently across platforms
- **Integration with a web dashboard**, where glucose data can also be monitored and managed from a browser
- **Scalability for future development**, such as analytics, reporting, clinical monitoring, or remote healthcare integration

The **backend API** is developed using **PHP**, which handles requests from the mobile application, processes incoming blood glucose data, and stores the results in the server database. On top of this backend, a **web application frontend built with Vue** provides a user interface for viewing and managing the data through a browser.

This architecture makes the system more complete, because it combines:
- wearable sensing through the smartwatch,
- mobile interaction through Flutter,
- server-side data management through PHP-based APIs, and
- web-based visualization through Vue.

## Key Features

- Blood glucose monitoring through integration with a smartwatch sensor
- Secure user login and personalized data access
- Support for **automatic input** from the smartwatch
- Support for **manual input** from the user
- Predicted glucose status display
- Blood glucose history shown in **tabular format**
- Blood glucose history shown in **chart format**
- Transmission of measurement data from mobile app to **database server**
- Communication with a **web backend API**
- Cross-platform mobile support for **Android** and **iOS**
- Web-based monitoring and data management support

## Technology Stack

### Mobile Application
- **Flutter** for cross-platform mobile app development
- **Dart** as the primary programming language

### Web System
- **PHP** for backend API development
- **Vue** for frontend web application development

### Integration
- Smartwatch sensor as the blood glucose data source
- Web API communication between mobile app and server
- Database server for centralized blood glucose data storage

## Benefits of Using Flutter

Using Flutter provides several advantages for this project:
- A **single codebase** for Android and iOS
- Faster development and easier maintenance
- Consistent user interface across platforms
- Easier feature expansion in future versions
- Good performance for mobile health monitoring applications

## Web Application Source Code

The source code for the web application, including both the backend and frontend components, can be accessed through the following repository:

`https://github.com/rezafaisal/eBloodGlucoseWeb`

This repository contains:
- the **PHP-based backend API** used by the mobile application to send and retrieve blood glucose data, and
- the **Vue-based frontend web application** used for browser-based monitoring and management.

## Summary

In summary, this project is a complete blood glucose monitoring system that integrates a smartwatch, a Flutter-based mobile application, and a web-based server platform. The smartwatch provides blood glucose measurement data, which can be received automatically by the mobile app or entered manually by the user. The application then displays the predicted glucose status, stores historical measurements, and presents them in both table and chart formats.

Beyond local monitoring on the mobile device, the application also sends blood glucose measurement results to a centralized database server through a web backend API. The backend is implemented using PHP, while the web frontend is developed using Vue. This architecture enables both mobile and web-based access to the same data, making the system more flexible, scalable, and suitable for modern digital health monitoring.
