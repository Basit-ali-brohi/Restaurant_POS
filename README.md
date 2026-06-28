<div align="center">

# 🍽️ CloudPOS Pro

### Enterprise Restaurant Management & Point-of-Sale System

A full-featured, MySQL-backed **Restaurant POS** for Windows desktop — built with Flutter.
Billing, kitchen display, inventory, recipe costing, payroll, multi-branch analytics and
FBR/SRB tax compliance, all in one offline-first application.

![Platform](https://img.shields.io/badge/Platform-Windows%20Desktop-0a7bbb)
![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.10-0175C2?logo=dart)
![State](https://img.shields.io/badge/State-Riverpod-7C4DFF)
![Database](https://img.shields.io/badge/Database-MySQL%20%2F%20MariaDB-00758F?logo=mysql&logoColor=white)
![Currency](https://img.shields.io/badge/Currency-PKR-2E7D32)

</div>

---

## 📖 Overview

**CloudPOS Pro** is an end-to-end restaurant operations platform covering the full service
lifecycle — from taking an order at the counter, routing it to the right kitchen station,
through payment, inventory deduction, accounting and reporting. Every record persists to a
**MySQL / MariaDB** database, so all data survives restarts and is queryable from any SQL tool.

The UI follows a clean, modern **indigo "CloudPOS"** design language with full **dark / light
mode**, and the data layer is wired for **Pakistani operations** (PKR currency, FBR/SRB tax
authorities, CNIC fields, QR fiscal invoicing).

---

## ✨ Features

### Operations
| Module | Highlights |
|---|---|
| **Dashboard** | Live KPIs, revenue trend chart, order-mix donut, top sellers, low-stock alerts, recent orders, quick actions |
| **POS Counter** | Dine-in / takeaway / delivery, visual table picker, item variations & modifiers, split bill, multi-tender payment (Cash / Card / Mobile Wallet), printable receipts |
| **Floor & Tables** | Live colour-coded table monitor, seat / transfer / merge, out-of-service state, add & delete tables |
| **Kitchen Display (KDS)** | Per-station ticket routing (Grill / Main / Beverage), Accept → Cooking → Ready lifecycle, time-ageing alerts, re-fire from history |
| **Menu Editor** | Categories & items, modifiers, **time-based "Happy Hour" pricing**, stock toggle, publish flow |

### Management
| Module | Highlights |
|---|---|
| **Stock & Recipes** | Inventory valuation, low/expiry flags, goods receiving, wastage, branch transfer, add/edit/delete items |
| **Recipe Costing** | Ingredient-level cost allocation, food-cost %, margin and recommended price vs. target |
| **Purchase Orders** | Requisition lifecycle — Draft → Approval → Dispatch → **Receive (auto-updates stock)** |
| **Suppliers / SRM** | Vendor ledger, reliability scoring, lead times, outstanding payables |
| **CRM & Loyalty** | Customer profiles, loyalty tiers, segments, marketing campaigns |
| **Reservations** | Bookings with party size, table assignment, confirm / seat / cancel |
| **Staff & Payroll** | Roster, clock in/out, salary sheets, printable **payslips (PDF)**, CNIC records |
| **Finance & P&L** | Expense ledger with invoice attachments, full Profit & Loss statement |
| **Tax Settings** | GST / SRB / PRA / VAT profiles, fiscal sync, **FBR QR invoicing** |
| **Multi-Branch** | Cross-branch performance comparison |
| **Delivery Hub** | Rider fleet, trip progress, commission ledgers |
| **Online Orders** | Web / Foodpanda / Careem aggregator feed with status flow |
| **Feedback** | Ratings scoreboard + complaint resolution tracking |
| **Business Insights** | Revenue by channel, payment mix, top sellers |
| **Audit Log** | Immutable forensic record of system events |

### Platform
- 🔐 **Role-Based Access Control (RBAC)** — Manager, Floor Manager, Head Chef, Server, Bartender
- 🗄️ **MySQL persistence** — 19 tables, every create / edit / delete written to the database
- 🧾 **PDF generation** — receipts & payslips (view, print, download)
- 🌗 **Dark / light theme**
- 💵 **PKR currency** throughout

---

## 🛠️ Tech Stack

| Layer | Technology |
|---|---|
| **Framework** | Flutter (Windows desktop) |
| **Language** | Dart 3.10 |
| **State management** | Riverpod |
| **Database** | MySQL / MariaDB via `mysql_client` |
| **Charts** | `fl_chart` |
| **PDF / Print** | `pdf`, `printing` |
| **Files / QR** | `file_picker`, `qr` |
| **Fonts** | `google_fonts` |

---

## 🚀 Getting Started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.x) with **Windows desktop** enabled
- A running **MySQL** or **MariaDB** server (e.g. via XAMPP)

### 1. Database setup
Create a database and a user the app can connect with:

```sql
CREATE DATABASE restaurant_pos;
CREATE USER 'posuser'@'localhost' IDENTIFIED BY 'Pos@12345';
CREATE USER 'posuser'@'127.0.0.1' IDENTIFIED BY 'Pos@12345';
GRANT ALL PRIVILEGES ON restaurant_pos.* TO 'posuser'@'localhost';
GRANT ALL PRIVILEGES ON restaurant_pos.* TO 'posuser'@'127.0.0.1';
FLUSH PRIVILEGES;
```

> All tables are **created automatically** on first launch — no manual schema import needed.

### 2. Configure the connection
Connection settings live in [`lib/core/database/db_service.dart`](lib/core/database/db_service.dart).
Update them to match your environment if different:

```dart
static const String host = '127.0.0.1';
static const int    port = 3307;   // XAMPP MariaDB; use 3306 for default MySQL
static const String user = 'posuser';
static const String password = 'Pos@12345';
static const String database = 'restaurant_pos';
```

> If the database is unreachable the app still runs, falling back to in-memory seed data.

### 3. Run the app
```bash
flutter pub get
flutter run -d windows
```

---

## 📂 Project Structure

```
lib/
├── core/
│   ├── database/        # MySQL gateway (DbService) + schema
│   ├── auth/            # RBAC permissions
│   ├── shell/           # App shell, sidebar, top bar
│   ├── theme/           # Colours & light/dark tones
│   ├── pdf/             # Receipt & payslip PDF builders
│   └── providers/       # Theme, navigation, bootstrap
└── features/
    ├── pos/             # POS counter, cart, payment, receipts
    ├── kitchen/         # KDS, order timeline (history)
    ├── table_management/# Floor & tables
    ├── menu/            # Menu editor + happy-hour pricing
    ├── inventory/       # Stock, suppliers
    ├── recipes/         # Recipe costing
    ├── purchasing/      # Purchase orders
    ├── crm/             # Customers & loyalty
    ├── reservations/    # Bookings
    ├── staff_payroll/   # Staff & payslips
    ├── finance/         # Expenses & P&L
    ├── tax/             # Tax profiles & FBR QR
    ├── branches/        # Multi-branch
    ├── delivery/        # Delivery hub & online orders
    ├── feedback/        # Ratings & complaints
    ├── dashboard/       # Overview, sales, shift, history
    ├── audit/           # Forensic audit log
    ├── notifications/   # Notification center
    ├── insights/        # Business analytics
    └── auth/            # Login & sessions
```

---

## 🗃️ Database Schema (auto-created)

`orders`, `order_lines`, `customers`, `suppliers`, `employees`, `stock_items`,
`menu_items`, `purchase_orders`, `purchase_order_lines`, `reservations`, `expenses`,
`sales`, `audit_log`, `recipes`, `branches`, `riders`, `restaurant_tables`,
`feedback`, `app_state`

---

## 🔑 Roles (RBAC)

| Role | Access |
|---|---|
| **Manager / Admin** | Full access to every module |
| **Floor Manager** | Operations + CRM, reservations, staff, insights (no finance/tax/audit) |
| **Head Chef** | Kitchen, inventory, menu, recipes, suppliers, purchase orders |
| **Server / Bartender** | POS, floor, kitchen, order history |

Use the **role quick-select** on the login screen to try each role.

---

## 📜 License

Proprietary — © Basit. All rights reserved.
