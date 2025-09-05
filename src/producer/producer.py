# Add this method to your producer.py (replace the existing fetch_real_prices method)

def fetch_real_prices(self):
    """Fetch real metals prices from MetalpriceAPI"""
    try:
        if not self.config.API_KEY:
            logger.warning("No API key configured, using simulated data only")
            return None
            
        # MetalpriceAPI endpoint and headers
        url = "https://api.metalpriceapi.com/v1/latest"
        headers = {
            "X-API-KEY": self.config.API_KEY,
            "Content-Type": "application/json"
        }
        
        # Request metals: XAU (Gold), XAG (Silver), XPT (Platinum), XPD (Palladium)
        params = {
            "base": "USD",
            "currencies": "XAU,XAG,XPT,XPD"
        }
        
        response = requests.get(url, headers=headers, params=params, timeout=10)
        
        if response.status_code == 200:
            data = response.json()
            logger.info("Successfully fetched real metals prices from MetalpriceAPI")
            self.last_real_fetch = time.time()
            return self.parse_metalpriceapi_response(data)
        else:
            logger.warning(f"MetalpriceAPI request failed: {response.status_code} - {response.text}")
            return None
            
    except requests.RequestException as e:
        logger.warning(f"MetalpriceAPI request failed: {e}")
        return None

def parse_metalpriceapi_response(self, api_data):
    """Parse MetalpriceAPI response into standard format"""
    try:
        parsed_prices = {}
        
        if 'success' in api_data and api_data['success'] and 'rates' in api_data:
            rates = api_data['rates']
            
            # MetalpriceAPI returns rates as 1/price for metals
            # XAU, XAG, XPT, XPD are metals (need to calculate 1/rate for USD price)
            metal_mapping = {
                'XAU': 'GOLD',
                'XAG': 'SILVER', 
                'XPT': 'PLATINUM',
                'XPD': 'PALLADIUM'
            }
            
            for api_symbol, our_symbol in metal_mapping.items():
                if api_symbol in rates:
                    # MetalpriceAPI returns rates where 1 USD = X metal units
                    # We want price per unit, so we calculate 1/rate
                    rate = rates[api_symbol]
                    if rate > 0:
                        price_per_unit = 1 / rate
                        parsed_prices[our_symbol] = round(price_per_unit, 2)
                        
        return parsed_prices if parsed_prices else None
        
    except Exception as e:
        logger.error(f"Error parsing MetalpriceAPI response: {e}")
        return None

# Usage in Docker run command:
# -e API_KEY=your_metalpriceapi_key
