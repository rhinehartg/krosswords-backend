# Krosswords Backend

A Ruby on Rails backend application for a crossword puzzle app with admin interface.

## Features

- **Rails 8.1** with PostgreSQL database
- **Devise authentication** for both regular users and admin users
- **Active Admin** for comprehensive administrative interface
- **Sprockets asset pipeline** for Active Admin compatibility
- **Sample data** with seeds for development

## Setup

1. **Install dependencies:**
   ```bash
   bundle install
   ```

2. **Set up database:**
   ```bash
   rails db:create
   rails db:migrate
   rails db:seed
   ```

3. **Start the server:**
   ```bash
   rails server
   ```

## Access

- **Main app**: http://localhost:3000
- **Active Admin**: http://localhost:3000/admin
- **Admin login**: http://localhost:3000/admin_users/sign_in
- **User login**: http://localhost:3000/users/sign_in
- **User registration**: http://localhost:3000/users/sign_up

## Default Credentials

### Admin Users
- **Primary Admin**: admin@example.com / password
- **Super Admin**: superadmin@example.com / admin123

### Sample Users
- john@example.com / password123
- jane@example.com / password123
- bob@example.com / password123
- alice@example.com / password123

## Admin Interface

The Active Admin interface provides:
- **User Management**: View, create, edit, and delete regular users
- **Admin User Management**: Manage admin users
- **Search & Filtering**: Find users by email, creation date, etc.
- **Bulk Actions**: Perform actions on multiple users
- **Export Functionality**: Export user data

## Technology Stack

- **Ruby 3.4.6**
- **Rails 8.1.0**
- **PostgreSQL** database
- **Devise** for authentication
- **Active Admin** for admin interface
- **Sprockets** for asset pipeline
- **Sass** for styling

## Development

This is a clean, simple Rails application ready for building your crossword puzzle features. The foundation includes:

- Secure authentication system
- Administrative interface
- Database setup with proper migrations
- Sample data for development
- Asset pipeline configuration

Perfect foundation for building your crossword puzzle app!
