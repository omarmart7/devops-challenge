## Votes UI App

This app is written in Node.js with an Angular UI and provides a unified interface for voting and viewing real-time results by consuming the votes API. This application requires the following environment variables to run:

```bash
# Votes API Configuration
VOTES_API_HOST=votes-api
VOTES_API_PORT=80

# Application Configuration
PORT=4000
```

See `.env-example` for a complete example of required environment variables.

### Local Development

This app is tested with **Node.js 16+**. To build this app:

```bash
# Install dependencies
npm ci

# For development with auto-reload
npm install -g nodemon
```

To run the application:

```bash
# Production
node server.js

# Development with auto-reload
nodemon server.js
```
