import azure.functions as func
import json
import os

def main(req: func.HttpRequest) -> func.HttpResponse:
    try:
        # Step 1 - Test basic function works
        symbol = req.route_params.get("symbol", "AAPL").upper()
        
        # Step 2 - Test Key Vault connection
        from azure.identity import DefaultAzureCredential
        from azure.keyvault.secrets import SecretClient
        
        vault_url = "https://stock-dashboard-project.vault.azure.net/"
        credential = DefaultAzureCredential()
        client = SecretClient(vault_url=vault_url, credential=credential)
        secret = client.get_secret("AlphaVantageKey")
        
        # Step 3 - Test Alpha Vantage API
        import requests
        url = f"https://www.alphavantage.co/query?function=GLOBAL_QUOTE&symbol={symbol}&apikey={secret.value}"
        response = requests.get(url)
        data = response.json()
        
        return func.HttpResponse(
            json.dumps({
                "debug": "all steps passed",
                "symbol": symbol,
                "raw_response": data
            }),
            mimetype="application/json"
        )
        
    except Exception as e:
        # Return the FULL error instead of empty response
        return func.HttpResponse(
            json.dumps({"error": str(e), "type": type(e).__name__}),
            mimetype="application/json",
            status_code=500
        )
