## Votes API

This app is written in Python and uses Flask to provide a backend API for vote submissions and results. This application requires the following environment variables to run:

```bash
# Database Configuration
POSTGRES_HOST=postgres
POSTGRES_USER=postgres
POSTGRES_PASSWORD=postgres
POSTGRES_DB=postgres

# Application Configuration
PORT=80
OPTION_A=Cats
OPTION_B=Dogs
```

See `.env-example` for a complete example of required environment variables.

### Local Development

This app is tested with **Python 3.9+**. To build with dependencies:

```bash
pip install -r requirements.txt
```

To run this app locally:

```bash
python app.py
```

### API Endpoints

- `GET /` - API information and voting options
- `GET /healthz` - Health check endpoint
- `POST /vote` - Submit a vote (JSON payload: `{"vote": "a"}` or `{"vote": "b"}`)
- `GET /results` - Get current voting results (JSON response)
