# City Contacts App Plan

## Overview
City Contacts is a web application that helps users discover their social media connections in different cities. The app analyzes users' Twitter/X and LinkedIn connections to create city-based contact lists, making it easier to connect with people when traveling.

## Core Features

### 1. Social Media Integration
- Twitter/X API integration
  - OAuth authentication via Devise
  - Access to user's followers/following
  - Profile data extraction (location, name, profile picture)
- LinkedIn API integration
  - OAuth authentication via Devise
  - Access to user's connections
  - Profile data extraction

### 2. User Interface
- Dashboard showing:
  - Total connections by city
  - Quick access to most popular cities
- City-specific pages showing:
  - List of connections in that city
  - Profile pictures
  - Names
  - Direct links to social media profiles
  - Filtering and sorting options

### 3. Data Management
- Location data processing
  - City name standardization
  - Geocoding for accurate location mapping
- Connection data storage
  - Caching of social media data
  - Regular updates via background jobs

## Technical Requirements

### Frontend
- Rails views with Turbo/Hotwire
- Map visualization library (e.g., Mapbox, Google Maps)
- Responsive design with Tailwind CSS
- Stimulus.js for interactive components

### Backend
- Ruby on Rails (Speedrail template)
- PostgreSQL database
- Active Record models for:
  - Users
  - Social Media Connections
  - Cities
  - User Preferences
- Background jobs via Delayed Job
- API endpoints for:
  - Social media authentication
  - Data retrieval and processing
  - User preferences

### APIs
- Twitter/X API
- LinkedIn API
- Geocoding service (e.g., Google Maps Geocoding API)

## Implementation Phases

### Phase 1: MVP
1. Set up Speedrail template
2. Basic Twitter/X integration
3. Simple city-based connection listing
4. Basic UI for viewing connections

### Phase 2: Enhanced Features
1. LinkedIn integration
2. Map visualization
3. Advanced filtering and sorting
4. User preferences and settings

### Phase 3: Polish
1. Performance optimization
2. Enhanced UI/UX
3. Additional social media platforms
4. Analytics and insights

## Security Considerations
- Secure OAuth implementation via Devise
- Data privacy compliance
- Rate limiting for API calls
- Secure storage of user data
- Admin panel access control

## Future Enhancements
- Map visualization of connection locations
- Additional social media platforms
- Trip planning integration
- Meeting suggestions
- Connection strength indicators
- Automated city-based notifications

## Technical Stack
- Framework: Ruby on Rails (Speedrail template)
- Frontend: Rails views, Turbo/Hotwire, Stimulus.js
- Styling: Tailwind CSS
- Database: PostgreSQL
- Background Jobs: Delayed Job
- APIs: Twitter/X, LinkedIn, Geocoding
- Authentication: Devise
- Admin: Active Admin
- Deployment: Heroku
- CI/CD: GitHub Actions

## Next Steps
1. Set up Speedrail template
2. Configure Devise for authentication
3. Set up Twitter/X API integration
4. Create database schema
5. Implement basic connection listing
6. Develop city-based views 