# Azure Functions for Eva-Bits (Production Architecture)

This folder contains the serverless **Azure Functions** microservices planned for the production deployment of **Eva-Bits Nic**.

## Architecture Overview

```
                      ┌──────────────────────────────────────┐
                      │    Eva-Bits Mobile App (Flutter)     │
                      └──────────────────┬───────────────────┘
                                         │
                                         ▼ HTTPS
                      ┌──────────────────────────────────────┐
                      │           Azure Functions            │
                      ├──────────────────┬───────────────────┤
                      │ NasaDataTrigger  │ IvyPredictTrigger │
                      └────────┬─────────┴─────────┬─────────┘
                               │                   │
                ┌──────────────▼──────┐     ┌──────▼──────────────────┐
                │ NASA POWER / SMAP   │     │ Azure AI Foundry Studio │
                │ Earth Observations  │     │ (GPT-4o / Phi-3 Mini)   │
                └─────────────────────┘     └─────────────────────────┘
```

## Functions Included

1. **`NasaDataTrigger`**:
   * **Route:** `GET /api/nasa-data?lat={lat}&lon={lon}`
   * Fetches daily agro-climatology data from NASA POWER (Solar Radiation, Precipitation, Temperature) and SMAP (Root zone soil moisture).
   * Implements 24-hour Redis/Blob caching to minimize external API latency.

2. **`IvyPredictTrigger`**:
   * **Route:** `POST /api/ivy-predict`
   * Accepts the farm structure (lots, crops) + coordinates.
   * Cross-references satellite indices with crop rotation algorithms in Azure AI Foundry Studio.
   * Returns grounded rotation schedules and soil preservation scores.

## Local Development & Testing

### Prerequisites
* [Azure Functions Core Tools v4](https://learn.microsoft.com/en-us/azure/azure-functions/functions-run-local)
* Python 3.10+ (or .NET 8)

### Running Locally
```bash
# 1. Copy local settings
cp local.settings.json.example local.settings.json

# 2. Install dependencies
pip install -r requirements.txt

# 3. Start local functions host
func start
```

## Deploying to Azure

```bash
# Log in to Azure
az login

# Deploy function app
func azure functionapp publish <YOUR_FUNCTION_APP_NAME>
```
