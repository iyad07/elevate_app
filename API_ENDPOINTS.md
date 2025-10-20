# Elevate API Endpoints

Base URL: `http://127.0.0.1:8000`

## Auth & Headers
- Protected routes require `Authorization: Bearer <token>`.
- Token is obtained from `POST /api/auth/login`.
- Decimal amounts are accepted as numbers, but sending strings (e.g., `"250.00"`) avoids float rounding.

---

## Auth (`/api/auth`)

### POST `/api/auth/register`
- Body: `{ "email": "you@example.com", "password": "<pass>", "full_name": "Your Name" }`
- Response: `{ "email": "you@example.com", "full_name": "Your Name" }`
- Errors: `400 Email already registered`

### POST `/api/auth/login`
- Body: `{ "email": "you@example.com", "password": "<pass>" }`
- Response: `{ "access_token": "<JWT>", "token_type": "bearer" }`
- Errors: `401 Invalid credentials`

### POST `/api/auth/logout`
- Response: `{ "message": "Logged out" }`

### GET `/api/auth/profile`
- Headers: `Authorization`
- Response: `{ "email": "you@example.com", "full_name": "Your Name" }`

### PUT `/api/auth/profile`
- Headers: `Authorization`
- Body: `{ "full_name": "New Name" }`
- Response: `{ "email": "you@example.com", "full_name": "New Name" }`

---

## Wallet (`/api/wallet`)

### GET `/api/wallet/balance`
- Headers: `Authorization`
- Response: `{ "balance": "100.00", "currency": "GHS" }`

### POST `/api/wallet/add-funds`
- Headers: `Authorization`
- Body: `{ "amount": "100.00", "currency": "GHS" }`
- Response: `{ "balance": "200.00", "currency": "GHS" }`

### POST `/api/wallet/withdraw`
- Headers: `Authorization`
- Body: `{ "amount": "40.00", "currency": "GHS" }`
- Response: `{ "balance": "160.00", "currency": "GHS" }`
- Errors: `400 Insufficient funds`

### GET `/api/wallet/transactions`
- Headers: `Authorization`
- Response: `{ "items": [{ "id": 1, "type": "deposit|withdraw|trade", "amount": "50.00", "currency": "GHS", "status": "success|failed", "reference": "REF123" }] }`

---

## Payments (`/api/payments`)

### POST `/api/payments/initialize`
- Headers: `Authorization`
- Body: `{ "email": "you@example.com", "amount": "250.00", "currency": "GHS", "callback_url": "https://your.app/callback" }`
- Response: `{ "authorization_url": "https://...", "access_code": "...", "reference": "..." }`
- Notes: Amount is converted to smallest unit (pesewas) internally.

### GET `/api/payments/verify/{reference}`
- Headers: `Authorization`
- Response: `{ "status": "success|failed|unknown", "amount": "250.00", "currency": "GHS", "transaction_date": "2024-01-01T00:00:00Z", "customer": "you@example.com" }`

### GET `/api/payments/banks?country=gh`
- Headers: `Authorization`
- Query: `country` (default `gh`)
- Response: `{ "items": [{ "name": "GCB Bank", "code": "GCB" }] }`

### POST `/api/payments/webhook`
- Body: Provided by Paystack; any JSON allowed for testing.
- Response: `{ "received": true }`

---

## Portfolio (`/api/portfolio`)

### GET `/api/portfolio` (alias of `/holdings`)
- Headers: `Authorization`
- Response: `{ "items": [{ "symbol": "AAPL", "quantity": 2, "averagePrice": "150.00", "currentPrice": 152.3, "totalValue": "304.60", "gainLoss": 4.6 }] }`

### GET `/api/portfolio/holdings`
- Headers: `Authorization`
- Response: same as above

### POST `/api/portfolio/buy`
- Headers: `Authorization`
- Body: `{ "symbol": "AAPL", "quantity": "2", "price": "150.00" }`
- Response: holdings snapshot
- Errors: `400 Insufficient funds`

### POST `/api/portfolio/sell`
- Headers: `Authorization`
- Body: `{ "symbol": "AAPL", "quantity": "1", "price": "155.00" }`
- Response: holdings snapshot
- Errors: `400 Not enough shares to sell`

### GET `/api/portfolio/performance`
- Headers: `Authorization`
- Response: `{ "totalValue": 1234.56, "change": 12.34, "changePercent": 1.0 }`

### GET `/api/portfolio/history`
- Headers: `Authorization`
- Response: `{ "items": [{ "symbol": "AAPL", "side": "buy|sell", "quantity": "1", "price": "150.00", "timestamp": "2024-01-01T00:00:00" }] }`

---

## Stocks (`/api/stocks`)

### GET `/api/stocks/quote/{symbol}`
- Response: `{ "symbol": "AAPL", "price": 152.3, "change": 1.5, "changePercent": 0.99, "high": 153.0, "low": 150.2, "volume": 123456, "latestTradingDay": "2024-01-01" }`

### GET `/api/stocks/profile/{symbol}`
- Response: `{ "name": "Apple Inc.", "logo": "https://...", "exchange": "NASDAQ", "industry": "Technology", "country": "USA", "marketCapitalization": 2.3e12 }`

### GET `/api/stocks/candle/{symbol}`
- Query: `resolution`, `from`, `to` (UNIX epoch seconds)
- Response: `{ "timestamps": [...], "opens": [...], "highs": [...], "lows": [...], "closes": [...], "volumes": [...] }`

### GET `/api/stocks/search?q=<query>`
- Response: `{ "results": [{ "symbol": "AAPL", "name": "Apple Inc." }] }`

### GET `/api/stocks/news?symbol=<symbol>`
- Response: `{ "items": [{ "headline": "...", "source": "...", "url": "...", "datetime": 1690000000 }] }`

### GET `/api/stocks/popular`
- Response: `{ "items": [{ "symbol": "AAPL", "name": "Apple Inc." }] }`

---

## Dashboard (`/api/dashboard`)

### GET `/api/dashboard/net-worth`
- Headers: `Authorization`
- Response: `{ "totalValue": "1234.56", "change": 12.34, "changePercent": 1.0 }`

### GET `/api/dashboard/recent-transactions`
- Headers: `Authorization`
- Response: `{ "items": [{ "type": "deposit|withdraw|trade", "amount": "50.00", "currency": "GHS", "timestamp": "2024-01-01T00:00:00" }] }`

### GET `/api/dashboard/performance`
- Headers: `Authorization`
- Response: `{ "totalValue": 1234.56, "change": 12.34, "changePercent": 1.0 }`

---

## Notes
- For `Decimal` fields (`amount`, `price`, `quantity`, `balance`), strings are safest for precision.
- Common error codes: `400` for business rule violations (insufficient funds/shares), `401` for auth failures.
- Swagger UI is available at `http://127.0.0.1:8000/docs` for live testing.