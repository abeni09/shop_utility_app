# ShopSync License Activation Server

A simple, production-ready Node.js Express server to handle and activate yearly subscription license keys for the ShopSync application.

## Features
- **Local JSON Database**: Stores keys, activation status, and expiry dates locally in `db.json`.
- **Hardware Binding**: Automatically binds a generated license key to a unique Device ID on first activation.
- **Generate License Keys**: Command-line interface tool to instantly generate valid license keys.
- **Demo Key Bypasses**: Automatically seeds a test demo key `SYNC-DEMO-KEY-2026` on first run.

## Setup & Running

1. **Install Dependencies**:
   ```bash
   cd license_server
   npm install
   ```

2. **Start the Server**:
   ```bash
   npm start
   ```
   The server will start running at `http://localhost:3000`.

## Generating License Keys
To generate subscription license keys, use the generate script:
```bash
# Generate 5 license keys (default)
npm run generate

# Generate a custom number of license keys
npm run generate -- --count 10
```
This generates random keys in the format `SYNC-XXXX-XXXX-XXXX-XXXX` and adds them to `db.json`.

## Flutter Application Integration
To connect the ShopSync Flutter app to your custom server:
1. Open [license_service.dart](file:///home/abeni/.gemini/antigravity/scratch/shop_utility_app/lib/features/license/data/license_service.dart).
2. Change the `_apiEndpoint` variable to point to your hosted server URL:
   ```dart
   static const String _apiEndpoint = 'https://your-license-server.herokuapp.com/license/activate';
   ```
   *(Note: For local testing on an Android Emulator, use `http://10.0.2.2:3000/license/activate`)*
