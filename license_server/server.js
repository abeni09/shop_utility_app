const express = require('express');
const cors = require('cors');
const fs = require('fs');
const path = require('path');
const crypto = require('crypto');

const PORT = process.env.PORT || 3100;
const DB_FILE = path.join(__dirname, 'db.json');

// Helper to load db
function loadDB() {
  if (!fs.existsSync(DB_FILE)) {
    const initialDB = { keys: {} };
    fs.writeFileSync(DB_FILE, JSON.stringify(initialDB, null, 2));
    return initialDB;
  }
  try {
    const data = fs.readFileSync(DB_FILE, 'utf8');
    return JSON.parse(data);
  } catch (e) {
    console.error('Error reading db.json, returning empty database', e);
    return { keys: {} };
  }
}

// Helper to save db
function saveDB(db) {
  fs.writeFileSync(DB_FILE, JSON.stringify(db, null, 2));
}

// Generate random license key
function generateLicenseKey() {
  const parts = [];
  for (let i = 0; i < 4; i++) {
    parts.push(crypto.randomBytes(2).toString('hex').toUpperCase());
  }
  return `SYNC-${parts.join('-')}`;
}

// CLI Key Generation Utility
if (process.argv.includes('--generate')) {
  const db = loadDB();
  const args = process.argv.slice(2);
  const countIndex = args.indexOf('--count');
  let count = 5;
  if (countIndex !== -1 && args[countIndex + 1]) {
    count = parseInt(args[countIndex + 1], 10) || 5;
  }

  console.log(`\n🔑 Generating ${count} yearly subscription license keys...\n`);
  const newKeys = [];
  for (let i = 0; i < count; i++) {
    const newKey = generateLicenseKey();
    db.keys[newKey] = {
      deviceId: null,
      expiryDate: null,
      createdAt: new Date().toISOString(),
      isActive: true
    };
    newKeys.push(newKey);
    console.log(`  - ${newKey}`);
  }
  saveDB(db);
  console.log(`\n💾 Saved keys to db.json. Run 'npm start' to start the server.\n`);
  process.exit(0);
}

// Create Express Server
const app = express();
app.use(cors());
app.use(express.json());
app.use(express.static(path.join(__dirname, 'public')));

// Logger middleware
app.use((req, res, next) => {
  console.log(`[${new Date().toISOString()}] ${req.method} ${req.url}`);
  next();
});

// Activate license endpoint
app.post('/license/activate', (req, res) => {
  const { key, device_id } = req.body;

  if (!key || !device_id) {
    return res.status(400).json({
      success: false,
      message: 'Missing key or device_id in request body'
    });
  }

  const trimmedKey = key.trim().toUpperCase();
  const db = loadDB();

  const record = db.keys[trimmedKey];
  if (!record) {
    return res.status(404).json({
      success: false,
      message: 'License key not found. Please verify spelling or contact support.'
    });
  }

  if (!record.isActive) {
    return res.status(403).json({
      success: false,
      message: 'This license key has been deactivated/revoked.'
    });
  }

  // Key already bound check
  if (record.deviceId && record.deviceId !== device_id) {
    return res.status(400).json({
      success: false,
      message: 'This license key is already activated on another device.'
    });
  }

  // If already activated on this device, just return the existing expiry date
  if (record.deviceId === device_id && record.expiryDate) {
    return res.status(200).json({
      success: true,
      expiry_date: record.expiryDate,
      message: 'License key is already active on this device.'
    });
  }

  // Bind key and set expiration to 1 year from now
  const expiryDate = new Date();
  expiryDate.setFullYear(expiryDate.getFullYear() + 1);
  const expiryStr = expiryDate.toISOString();

  record.deviceId = device_id;
  record.expiryDate = expiryStr;
  record.activatedAt = new Date().toISOString();

  saveDB(db);

  return res.status(200).json({
    success: true,
    expiry_date: expiryStr,
    message: 'License activated successfully!'
  });
});

// Check license status endpoint
app.get('/license/status', (req, res) => {
  const { key, device_id } = req.query;

  if (!key || !device_id) {
    return res.status(400).json({
      success: false,
      message: 'Missing key or device_id query parameters'
    });
  }

  const trimmedKey = key.trim().toUpperCase();
  const db = loadDB();

  const record = db.keys[trimmedKey];
  if (!record || record.deviceId !== device_id) {
    return res.status(200).json({
      status: 'invalid',
      message: 'Invalid license details.'
    });
  }

  if (!record.isActive) {
    return res.status(200).json({
      status: 'revoked',
      message: 'This license key has been deactivated.'
    });
  }

  const expiry = new Date(record.expiryDate);
  if (new Date() > expiry) {
    return res.status(200).json({
      status: 'expired',
      expiry_date: record.expiryDate,
      message: 'License has expired.'
    });
  }

  return res.status(200).json({
    status: 'active',
    expiry_date: record.expiryDate,
    message: 'License is active.'
  });
});

// ADMIN API ENDPOINTS (CRUD)

// 1. Get all licenses
app.get('/api/licenses', (req, res) => {
  const db = loadDB();
  const licenses = Object.keys(db.keys).map(key => ({
    key,
    ...db.keys[key]
  }));
  // Sort by createdAt descending
  licenses.sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));
  res.json(licenses);
});

// 2. Create or generate license(s)
app.post('/api/licenses', (req, res) => {
  const { customKey, generateCount } = req.body;
  const db = loadDB();

  if (customKey && customKey.trim()) {
    const key = customKey.trim().toUpperCase();
    if (db.keys[key]) {
      return res.status(400).json({ success: false, message: 'License key already exists' });
    }
    db.keys[key] = {
      deviceId: null,
      expiryDate: null,
      createdAt: new Date().toISOString(),
      isActive: true
    };
    saveDB(db);
    return res.json({ success: true, message: `Custom key '${key}' created.` });
  }

  const count = parseInt(generateCount, 10) || 1;
  const newKeys = [];
  for (let i = 0; i < count; i++) {
    const newKey = generateLicenseKey();
    db.keys[newKey] = {
      deviceId: null,
      expiryDate: null,
      createdAt: new Date().toISOString(),
      isActive: true
    };
    newKeys.push(newKey);
  }
  saveDB(db);
  return res.json({ success: true, message: `Generated ${count} license keys.`, keys: newKeys });
});

// 3. Update license details
app.put('/api/licenses/:key', (req, res) => {
  const key = req.params.key.toUpperCase();
  const { deviceId, expiryDate, isActive } = req.body;
  const db = loadDB();

  if (!db.keys[key]) {
    return res.status(404).json({ success: false, message: 'License key not found' });
  }

  if (deviceId !== undefined) {
    db.keys[key].deviceId = deviceId === '' ? null : deviceId;
    if (deviceId === '') {
      delete db.keys[key].activatedAt;
    }
  }

  if (expiryDate !== undefined) {
    db.keys[key].expiryDate = expiryDate === '' ? null : expiryDate;
  }

  if (isActive !== undefined) {
    db.keys[key].isActive = !!isActive;
  }

  saveDB(db);
  res.json({ success: true, message: 'License key updated successfully' });
});

// 4. Delete license
app.delete('/api/licenses/:key', (req, res) => {
  const key = req.params.key.toUpperCase();
  const db = loadDB();

  if (!db.keys[key]) {
    return res.status(404).json({ success: false, message: 'License key not found' });
  }

  delete db.keys[key];
  saveDB(db);
  res.json({ success: true, message: 'License key deleted successfully' });
});

// Seed an initial demo key on startup if database is empty
const db = loadDB();
const initialDemoKey = 'SYNC-DEMO-KEY-2026';
if (!db.keys[initialDemoKey]) {
  db.keys[initialDemoKey] = {
    deviceId: null,
    expiryDate: null,
    createdAt: new Date().toISOString(),
    isActive: true
  };
  saveDB(db);
  console.log(`\n🔑 Seeded initial demo key: ${initialDemoKey}`);
}

app.listen(PORT, () => {
  console.log(`🚀 ShopSync license server running on port ${PORT}`);
});
