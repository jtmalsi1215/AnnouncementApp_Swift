# TRABILIS - A Travel Booking Mangement System

![project-banner](/Acadvisory/Simulator Screenshot .png.png)

## 📖 About

Trabilis is a comprehensive booking management solution engineered to digitize operations for Lindela Travel & Tours.

The primary goal was to replace manual bookkeeping, reservation tracking, and payment processing with a centralized, automated web platform. Beyond just administrative efficiency, the application focuses on modernizing the customer experience by integrating immersive 360° Virtual Tours (via Pannellum) and an AI-powered Helpdesk Assistant (via Botpress).

## 🎓 Story

I built this as my senior capstone project at Our Lady of Fatima University. My objective was to challenge myself beyond standard "CRUD" web applications. I wanted to tackle real-world software engineering problems—such as handling complex booking workflows, automating document generation, and managing role-based security—to demonstrate my readiness for the professional tech industry.

## 🚀 Live Demos

This project is architected as two separate applications to ensure security and separation of concerns.

> ⚠️ **Note on Performance:** The backend is hosted on a free Render instance.
> Please allow **30-50 seconds** for the initial load while the server wakes up.
> Subsequent requests will be instant.

## ✨ Key Features

**[🔗 Visit Public Site](https://trabilis.vercel.app)**

### 🌐 Client Portal (Public Facing)

-   **Full-Cycle Booking Engine:** Users can search, reserve, and pay for both Flights and Tour Packages seamlessly.
-   **Interactive 360° Virtual Tours:** Integrated **Pannellum** to provide immersive, panoramic previews of tourist destinations directly in the browser.
-   **Automated Document Generation:** System automatically generates PDF invoices/receipts and emails them to the user upon successful payment.
-   **Real-Time Application Tracking:** Users can monitor the status of their Flight, Tour, and Visa applications via a unified tracking page.
-   **AI-Powered Support:** Integrated **Botpress** chatbot to handle common customer inquiries and guide users through the booking process.

**[🔗 Visit Admin Dashboard](https://your-admin-link.vercel.app)**

### 🛡️ Admin Dashboard (Internal Operations)

-   **Role-Based Access Control (RBAC):** Granular permission settings (Admins vs. Staff) to secure sensitive modules.
-   **Operational Workflow Management:** Features a task assignment system to delegate specific bookings to staff members.
-   **Data Visualization & Analytics:** Interactive charts providing insights into booking trends, revenue, and flight/tour popularity.
-   **Content Management System (CMS):** Full control to create/edit Tour Packages and customize system settings (Visa requirements, Email templates).
-   **Notification Hub:** A centralized system with filtering capabilities to alert admins of new bookings and inquiries.
-   **Customer Feedback Loop:** Built-in rating system that collects and displays user reviews after trip completion.

-   **🔐 Demo Credentials:**
    -   **Email:** `lorenz@admin.com`
    -   **Password:** `12345678`

## 🛠 Tech Stack

**Frontend:**

-   **React (Vite)** – For a fast, component-based UI.
-   **Tailwind CSS** – For rapid, mobile-responsive styling.

**Backend & Database:**

-   **Supabase** – Managed PostgreSQL database with built-in Auth and Realtime subscriptions.
-   **Node.js / Express** – REST API handling secure transactions and background processes.

**Tools:**

-   **Git / GitHub** – Version control.
-   **Vercel** – Deployment pipeline.

---

## 📂 Project Structure

This repository is a **monorepo** containing two distinct React applications:

```text
├── /client          # Public-facing application (React + Tailwind)
│   ├── src/         # UI Components for public view
│   └── package.json
│
├── /admin           # Protected administrative panel (React + Tailwind)
│   ├── src/         # Dashboard views & Supabase CRUD logic
│   └── package.json
│
└── README.md        # Documentation
```
