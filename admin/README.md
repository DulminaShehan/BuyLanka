[BuyLanka_README (1).md](https://github.com/user-attachments/files/31693083/BuyLanka_README.1.md)
# 🛒 BuyLanka

> A modern Sri Lankan multi-vendor food and local delivery platform
> built with Flutter and Supabase.

BuyLanka is a real-world delivery marketplace inspired by modern
platforms such as Uber Eats. The platform connects **customers,
shops/sellers, delivery riders, and administrators** in one ecosystem.

------------------------------------------------------------------------

## 🚀 Project Overview

BuyLanka is designed as a multi-role delivery platform where:

-   **Customers** discover nearby shops, browse products, place orders,
    and track deliveries.
-   **Sellers/Shops** manage their shop, menu/products, inventory, and
    incoming orders.
-   **Riders** receive delivery assignments, navigate to pickup and
    customer locations, and update delivery status.
-   **Admins** manage the entire platform through a web-based
    administration dashboard.

The project is being developed as a production-style portfolio project
with a focus on clean architecture, security, real-time features, and
scalable database design.

------------------------------------------------------------------------

## 👥 User Roles

### 🛒 Customer

Customers can:

-   Register and log in
-   Set and manage delivery addresses
-   Find nearby shops
-   Search for food/products
-   Browse shop menus
-   View product details
-   Add products to cart
-   Manage favorites
-   Place orders
-   Select payment methods
-   Track order status
-   Track rider location
-   View order history
-   Rate shops, products, and riders

### 🏪 Seller / Shop

Sellers are created and managed by the Admin.

Sellers can:

-   Log in using their assigned account
-   Manage shop details
-   Upload shop images
-   Set shop opening/closing status
-   Add products/menu items
-   Edit and delete products
-   Manage product availability
-   Manage prices and discounts
-   Receive customer orders
-   Accept or reject orders
-   Update preparation status
-   Mark orders as ready for pickup
-   View sales information

### 🚚 Rider

Riders are created and managed by the Admin.

Riders can:

-   Log in using their assigned account
-   Set online/offline availability
-   View assigned deliveries
-   Accept delivery assignments
-   View pickup location
-   View customer delivery location
-   Use maps and GPS
-   Update delivery status
-   Share live location during active deliveries
-   View delivery history
-   View earnings

### 👨‍💼 Admin

The Admin uses a separate web dashboard.

Admins can:

-   Manage customers
-   Create seller accounts
-   Manage sellers
-   Create rider accounts
-   Manage riders
-   Manage shops
-   Manage products
-   Manage categories
-   Manage orders
-   Manage deliveries
-   View platform statistics
-   Manage platform settings
-   Monitor the overall marketplace

------------------------------------------------------------------------

## 🔄 Order & Delivery Flow

``` text
Customer
   │
   ↓
Browse Shop
   │
   ↓
Select Products
   │
   ↓
Add to Cart
   │
   ↓
Checkout
   │
   ↓
Place Order
   │
   ↓
Seller Receives Order
   │
   ↓
Seller Accepts
   │
   ↓
Preparing
   │
   ↓
Ready for Pickup
   │
   ↓
Rider Assigned
   │
   ↓
Rider Picks Up
   │
   ↓
Rider Travels to Customer
   │
   ↓
Customer Receives Order
   │
   ↓
Delivered
```

------------------------------------------------------------------------

## 🗺️ Rider Map Flow

The rider experience uses location and map services.

### Before pickup

``` text
🚚 Rider → 🏪 Shop
```

### After pickup

``` text
🚚 Rider → 📍 Customer
```

The system is designed to support:

-   Current rider location
-   Shop/pickup location
-   Customer delivery location
-   Route display
-   Distance
-   Estimated travel time
-   Real-time rider location updates

------------------------------------------------------------------------

## 🏗️ System Architecture

``` text
                         BuyLanka
                            │
              ┌─────────────┼─────────────┐
              │             │             │
              ↓             ↓             ↓
        Customer App   Seller/Rider   Admin Web
          Flutter         Flutter        React
              │             │             │
              └─────────────┼─────────────┘
                            ↓
                         Supabase
                            │
             ┌──────────────┼──────────────┐
             ↓              ↓              ↓
        PostgreSQL       Supabase Auth   Storage
             │
             ↓
      Row Level Security
             │
             ↓
       Supabase Realtime
```

------------------------------------------------------------------------

## 🛠️ Technology Stack

### Mobile Application

-   Flutter
-   Dart
-   Riverpod
-   Flutter Router / routing solution
-   Responsive UI

### Backend / Cloud

-   Supabase
-   PostgreSQL
-   Supabase Authentication
-   Supabase Storage
-   Supabase Realtime
-   Row Level Security (RLS)

### Admin Dashboard

-   React
-   TypeScript
-   Vite
-   Supabase

### Maps & Location

-   GPS / device location services
-   Map provider integration
-   Route and location tracking

### Development Tools

-   Git
-   GitHub
-   VS Code
-   Antigravity

------------------------------------------------------------------------

## 📁 Repository Structure

``` text
BuyLanka/
│
├── mobile/
│   └── Flutter application
│
├── admin/
│   └── Admin web dashboard
│
├── supabase/
│   ├── migrations/
│   ├── seed/
│   └── functions/
│
├── docs/
│   ├── architecture/
│   ├── database/
│   └── api/
│
├── .gitignore
├── README.md
└── LICENSE
```

> The exact structure may evolve as the project grows.

------------------------------------------------------------------------

## 🔐 Security

BuyLanka uses role-based access control and Supabase Row Level Security.

### Customer

Customers can access only their own private information, carts,
addresses, orders, and reviews.

### Seller

Sellers can access only their own shop, products, and shop-related
orders.

### Rider

Riders can access only deliveries assigned to them and the information
required to complete those deliveries.

### Admin

Admins have platform management permissions.

### Important Security Rules

-   Never use the Supabase service-role key in the Flutter or React
    client.
-   Never hardcode secrets in source code.
-   Use environment variables for configuration.
-   Enable Row Level Security on protected tables.
-   Validate sensitive operations server-side/database-side where
    appropriate.
-   Never allow users to change their own role.

------------------------------------------------------------------------

## 🗄️ Planned Database Entities

The database is designed around entities such as:

``` text
profiles
shops
categories
products
product_images
addresses
carts
cart_items
orders
order_items
deliveries
riders
rider_locations
payments
reviews
favorites
notifications
```

Relationships will be finalized and maintained through Supabase
migrations.

------------------------------------------------------------------------

## 🌳 Git Workflow

BuyLanka follows a feature-based Git workflow.

``` text
main
  │
  └── develop
        │
        ├── feature/auth
        ├── feature/customer
        ├── feature/seller
        ├── feature/rider
        ├── feature/orders
        └── feature/admin
```

### Example

``` bash
git checkout develop

git checkout -b feature/rider-map

# Develop and test the feature

git add .
git commit -m "feat: add rider map and location tracking"

git push -u origin feature/rider-map
```

Features should be reviewed and merged into `develop` before eventually
reaching `main`.

------------------------------------------------------------------------

## 🚧 Development Roadmap

### Phase 1 --- Foundation

-   [x] Create Flutter project
-   [x] Create GitHub repository
-   [x] Configure Supabase project
-   [ ] Finalize database architecture
-   [ ] Configure authentication
-   [ ] Configure RLS

### Phase 2 --- Admin

-   [ ] Admin authentication
-   [ ] Admin dashboard
-   [ ] Seller management
-   [ ] Rider management
-   [ ] Customer management
-   [ ] Shop management
-   [ ] Product management
-   [ ] Order management
-   [ ] Delivery management
-   [ ] Reports

### Phase 3 --- Seller

-   [ ] Seller authentication
-   [ ] Seller dashboard
-   [ ] Shop management
-   [ ] Product/menu management
-   [ ] Product availability
-   [ ] Order management
-   [ ] Sales dashboard

### Phase 4 --- Rider

-   [ ] Rider authentication
-   [ ] Rider dashboard
-   [ ] Online/offline status
-   [ ] Delivery assignments
-   [ ] Delivery details
-   [ ] GPS location
-   [ ] Map integration
-   [ ] Pickup workflow
-   [ ] Customer delivery workflow
-   [ ] Live rider location
-   [ ] Delivery history
-   [ ] Earnings

### Phase 5 --- Customer

-   [ ] Customer authentication
-   [ ] Home screen
-   [ ] Location selection
-   [ ] Nearby shops
-   [ ] Search
-   [ ] Categories
-   [ ] Shop details
-   [ ] Product details
-   [ ] Cart
-   [ ] Checkout
-   [ ] Address management
-   [ ] Order creation
-   [ ] Order tracking
-   [ ] Rider tracking
-   [ ] Favorites
-   [ ] Reviews
-   [ ] Notifications
-   [ ] Order history

### Phase 6 --- Production

-   [ ] Testing
-   [ ] Security audit
-   [ ] Performance optimization
-   [ ] Error handling
-   [ ] Logging
-   [ ] Production deployment
-   [ ] Android release
-   [ ] Admin web deployment

------------------------------------------------------------------------

## 🧪 Testing

The project will include testing for:

-   Authentication
-   Role-based access
-   Database operations
-   RLS policies
-   Product management
-   Cart calculations
-   Order creation
-   Order status transitions
-   Delivery assignments
-   GPS/location handling
-   Map functionality
-   Realtime updates
-   UI responsiveness

------------------------------------------------------------------------

## 📱 Future Features

Potential future improvements include:

-   Online payments
-   Promo codes
-   Restaurant/shop offers
-   Scheduled orders
-   Multiple delivery addresses
-   In-app chat
-   Push notifications
-   Advanced delivery routing
-   Rider earnings analytics
-   Shop analytics
-   Customer loyalty system
-   Referral system
-   AI-based recommendations

------------------------------------------------------------------------

## 🎯 Project Goals

The main goals of BuyLanka are to:

1.  Build a realistic multi-vendor delivery platform.
2.  Learn and demonstrate advanced Flutter development.
3.  Practice Supabase and PostgreSQL.
4.  Implement role-based security with RLS.
5.  Implement GPS and map-based delivery tracking.
6.  Build real-time application features.
7.  Follow professional Git and software development practices.
8.  Create a strong portfolio project for CV and freelance
    opportunities.

------------------------------------------------------------------------

## 👨‍💻 Project Status

**Status:** 🚧 In Development

BuyLanka is actively being developed feature by feature.

The architecture and database may evolve during development as new
requirements are implemented.

------------------------------------------------------------------------

## 📄 License

This project is currently intended as a personal portfolio and learning
project.

License details will be added when the project reaches its release
stage.
