# StudXchange - Premium Student Marketplace

A premium, startup-level Flutter app for students to buy, sell, and exchange items within their campus.

## 🎯 Features

### 🏠 Home Screen
- Featured items carousel with premium cards
- Recent items list with smooth animations
- Welcome message with personalized greeting
- Floating action button for quick item addition
- Real-time item updates across all screens

### 🔍 Buy Screen
- Advanced search with real-time filtering
- Category filters with visual chips
- Price range slider
- Grid/List view toggle
- Sort options (Recent, Price, Name)
- Active filter indicators
- Premium card designs with hover effects

### ➕ Sell Screen
- Premium form design with gradient backgrounds
- Category selection with animated cards
- Real-time validation
- Success animation overlay
- Haptic feedback for better UX
- Professional input fields with icons

### 👤 Profile Screen
- User profile card with statistics
- Contact information display
- "My Items" section
- Item management (delete functionality)
- Logout with confirmation dialog
- Clean, modern card-based layout

### 🎨 UI/UX Features
- **Dark Theme**: Black background with yellow accent colors
- **Premium Animations**: Smooth transitions, fade effects, slide animations
- **Bottom Navigation**: Instagram-style navigation with 4 tabs
- **Haptic Feedback**: Tactile feedback for user interactions
- **Responsive Design**: Optimized for all screen sizes
- **Modern Cards**: Rounded corners (16+ radius), shadows, gradients

## 📁 Project Structure

```
lib/
├── main.dart                 # Main navigation controller with bottom nav
├── login.dart                # Login/signup screen
├── models/
│   └── item_model.dart       # Data model for items
├── data/
│   └── dummy_data.dart       # Sample data and categories
├── home/
│   └── home_screen.dart      # Home screen with featured/recent items
├── buy/
│   └── buy_screen.dart       # Browse/search/filter items
├── sell/
│   └── sell_screen.dart      # Add new item form
└── profile/
    └── profile_screen.dart   # User profile and my items
```

## 🚀 Getting Started

1. **Install Dependencies**
   ```bash
   flutter pub get
   ```

2. **Run the App**
   ```bash
   flutter run
   ```

3. **Login Credentials**
   - Email: Any valid email format (e.g., user@college.edu)
   - Password: Minimum 6 characters

## 🎨 Design System

### Colors
- **Primary**: Black (#000000)
- **Accent**: Yellow (#FFD600, #FFC107)
- **Surface**: Dark Grey (#1A1A1A, #2A2A2A)
- **Text**: White (#FFFFFF), Grey (#9E9E9E)

### Typography
- **Headings**: Bold, 20-28px
- **Body**: Regular, 14-16px
- **Captions**: Regular, 12px

### Components
- **Cards**: 16-20px border radius
- **Buttons**: Gradient backgrounds, 16-20px border radius
- **Inputs**: Dark background, yellow focus state
- **Navigation**: Custom bottom nav with animations

## 🔧 Technical Features

### State Management
- Global item list shared across screens
- Real-time updates when items are added/deleted
- Local filtering and search

### Animations
- Fade transitions for screen changes
- Slide animations for list items
- Scale animations for button interactions
- Success overlays with elastic effects

### Data Flow
- Items flow from main navigation to all screens
- Callback functions for add/delete operations
- Instant UI updates across all tabs

## 📱 Screenshots

The app features:
- Premium login screen with gradient branding
- Instagram-style bottom navigation
- Smooth tab transitions without reload
- Interactive cards with hover states
- Professional form designs
- Modern search and filter interfaces

## 🎯 Key Improvements

1. **Bottom Navigation**: Fixed navigation with 4 main tabs
2. **Premium UI**: Dark theme with yellow accents, rounded corners
3. **Smooth Animations**: Fade, slide, and scale transitions
4. **Real-time Updates**: Items instantly visible across all screens
5. **Advanced Search**: Category filters, price range, sorting
6. **Professional Forms**: Enhanced input design with validation
7. **User Profile**: Complete profile management with statistics

## 🚀 Future Enhancements

- Firebase integration for real data
- Image upload functionality
- Chat/messaging system
- Push notifications
- Advanced analytics
- Payment integration

---

**Built with ❤️ using Flutter**
