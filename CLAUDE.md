# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Citycontacts is a Rails 8 SaaS template built for rapid application development. It's a social networking app that helps users connect with others in their city through various social platforms.

## Core Architecture

### Models & Database
- **User**: Central user model with Devise authentication, includes Stripe billing integration
- **City**: Geographic locations where users can connect
- **SocialConnection**: Links users to cities with social platform context
- **UserSocialProfile**: Stores user profile data from connected social platforms (Twitter/X)

### Key Features
- Social authentication (Twitter/X OAuth integration)
- Subscription billing via Stripe
- Admin panel via ActiveAdmin
- A/B testing with Split
- Background jobs via Delayed Job
- Rich text blog CMS

### Social Integration Architecture
The app connects users through cities via social platforms:
1. Users authenticate with social providers (Twitter)
2. `SocialConnection` model links users to cities
3. `UserSocialProfile` stores platform-specific profile data
4. Controllers: `TwitterAuthController` and `SocialConnectionsController`

## Development Commands

### Running the Application
```bash
bin/dev                    # Start all services (web, redis, active_admin watcher)
```

### Testing
```bash
bundle exec rspec                      # Run all tests
bundle exec rspec spec/models          # Run model tests only
bundle exec rspec spec/controllers     # Run controller tests only
HEADED=TRUE bundle exec rspec          # Run tests in browser (headed mode)
```

### Code Quality
```bash
rubocop                    # Check code style
rubocop -a                 # Auto-fix safe issues
rubocop -A                 # Auto-fix all issues (more aggressive)
```

### Database
```bash
rails db:migrate          # Run migrations
rails db:seed             # Seed database
```

## Key Configuration

### Development Dependencies
- Foreman manages multiple processes via `Procfile.dev`
- Redis server runs on port 6379 for background jobs and caching
- ActiveAdmin has its own watcher process for asset compilation

### Authentication & Authorization
- Devise handles user authentication with custom controllers
- Admin users access Split dashboard and other admin features
- Social OAuth flows handled by dedicated controllers

### Background Processing
- Uses Delayed Job (custom fork for Rails 7+ compatibility)
- Worker process commented out in Procfile.dev but available

### Testing Infrastructure
- RSpec with FactoryBot for test data
- Capybara + Selenium for integration testing
- SimpleCov with TailwindCSS theming for coverage reports
- Webmock for HTTP request stubbing

## Important Files
- `config/routes.rb` - Defines OAuth callback routes and resource routing
- `bin/dev` - Development startup script with Redis cleanup
- `Procfile.dev` - Process definitions for local development
- `lib/tasks/scheduler.rake` - Cron job definitions
- `app/models/concerns/` - Shared model behaviors (Signupable, Onboardable, Billable)