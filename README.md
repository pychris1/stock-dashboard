# Stock Dashboard

A real-time stock monitoring dashboard built on Azure. Tracks live prices, shows 10-day price history charts, and lets you add or remove any ticker you want.



---

## What it does

- Pulls live stock prices from the Alpha Vantage API
- Displays price, daily change, and volume for multiple stocks at once
- Click any stock card to see a 10-day price history chart
- Add any ticker via the search bar, remove ones you don't care about
- Prices auto-refresh every 60 seconds

---

## How it's built

The frontend is a plain HTML/JS page hosted on Azure Static Web Apps. When it needs stock data it calls an Azure Function, which fetches the API key from Key Vault and makes the request to Alpha Vantage.
```
Browser → Azure Static Web Apps (frontend)
              ↓
         Azure Function (Python)
              ↓
         Azure Key Vault (API key stored here, not in code)
              ↓
         Alpha Vantage API (live market data)
```

**Stack:**
- Azure Functions (Python 3.11) — serverless backend
- Azure Key Vault + Managed Identity — secrets management, no hardcoded credentials
- Azure Static Web Apps — frontend hosting
- GitHub Actions — auto-deploys on every push to master
- Azure Bicep — entire infrastructure defined as code in `main.bicep`

---

## Infrastructure as Code

All Azure resources are defined in `main.bicep`. If you wanted to tear everything down and rebuild from scratch:
```bash
az deployment group create \
  --resource-group <your-rg> \
  --template-file main.bicep \
  --parameters alphaVantageKey="<your-key>"
```

That single command recreates the storage account, Key Vault, Function App, managed identity permissions, and Static Web App.

---

## Challenges

This project took a lot more troubleshooting than expected, which honestly made it more useful to build.

Some things I ran into:
- Azure Key Vault defaults to RBAC now, not Access Policies — had to assign `Key Vault Secrets Officer` to myself before I could even write a secret
- Python 3.14 isn't stable on Azure Functions yet — downgraded to 3.11 to fix a persistent 503 on the SCM endpoint
- The `func` CLI kept timing out on deployment — ended up switching to GitHub Actions with a Service Principal, which is the better approach anyway
- Packages compiled on Ubuntu (the GitHub Actions runner) weren't compatible with Azure's older Linux environment — fixed by passing `--platform manylinux2014_x86_64` to pip
- CORS wasn't configured on the Function App, so the frontend couldn't talk to the backend until I added the Static Web App's domain to the allowed origins

---

## Notes

Alpha Vantage's free tier allows 25 API requests per day. If some stock cards show "Rate limit — try later" that's why — it resets every 24 hours.
