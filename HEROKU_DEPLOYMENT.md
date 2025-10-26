# Heroku Deployment Environment Variables

## Required Environment Variables

### Database
- `DATABASE_URL` - Automatically provided by Heroku PostgreSQL addon
- `RAILS_MASTER_KEY` - Required for Rails encrypted credentials

### Application Configuration
- `RAILS_ENV` - Set to "production" (automatically set by Heroku)
- `RAILS_LOG_LEVEL` - Set to "info" for production (optional, defaults to "info")
- `HOST` - Your Heroku app domain (e.g., "your-app-name.herokuapp.com")

### Optional Environment Variables
- `GEMINI_API_KEY` - Google Gemini API key for AI puzzle generation (optional)

## Setting Environment Variables on Heroku

### Using Heroku CLI:
```bash
# Set the Rails master key (get this from config/master.key)
heroku config:set RAILS_MASTER_KEY=your_master_key_here

# Set your app host
heroku config:set HOST=your-app-name.herokuapp.com

# Set Gemini API key (optional)
heroku config:set GEMINI_API_KEY=your_gemini_api_key_here
```

### Using Heroku Dashboard:
1. Go to your app's Settings tab
2. Click "Reveal Config Vars"
3. Add the environment variables listed above

## Database Setup

The Heroku PostgreSQL addon will automatically provide the `DATABASE_URL` environment variable. The app.json configuration includes the `heroku-postgresql:mini` addon which is the cheapest PostgreSQL option.

## Deployment Commands

```bash
# Create a new Heroku app
heroku create your-app-name

# Add PostgreSQL addon (if not using app.json)
heroku addons:create heroku-postgresql:mini

# Deploy from staging branch
git push heroku staging:main

# Run database migrations
heroku run rails db:migrate

# Check app status
heroku ps
```

## Cost Optimization

- Using `heroku-postgresql:mini` ($5/month) - cheapest PostgreSQL option
- Using `basic` dyno size (free tier available, $7/month for basic)
- Single web dyno configuration in app.json

## Troubleshooting

- Check logs: `heroku logs --tail`
- Check database: `heroku pg:info`
- Restart app: `heroku restart`
- Run console: `heroku run rails console`
