import azure.functions as func
import requests
import json
import logging
from azure.identity import DefaultAzureCredential
from azure.keyvault.secrets import SecretClient

def get_api_key():
    vault_url = "https://stock-dashboard-project.vault.azure.net/"
    credential = DefaultAzureCredential()
    client = SecretClient(vault_url=vault_url, credential=credential)
    return client.get_secret("AlphaVantageKey").value

def main(req: func.HttpRequest) -> func.HttpResponse:
    symbol = req.route_params.get("symbol", "AAPL").upper()
    
    try:
        api_key = get_api_key()
        url = f"https://www.alphavantage.co/query?function=GLOBAL_QUOTE&symbol={symbol}&apikey={api_key}"
        response = requests.get(url)
        data = response.json()
        
        quote = data.get("Global Quote", {})
        result = {
            "symbol": symbol,
            "price": quote.get("05. price", "N/A"),
            "change": quote.get("09. change", "N/A"),
            "change_percent": quote.get("10. change percent", "N/A"),
            "volume": quote.get("06. volume", "N/A")
        }
        
        logging.info(f"Fetched stock data for {symbol}")
        return func.HttpResponse(json.dumps(result), mimetype="application/json")
    
    except Exception as e:
        logging.error(f"Error: {str(e)}")
        return func.HttpResponse(f"Error: {str(e)}", status_code=500)
