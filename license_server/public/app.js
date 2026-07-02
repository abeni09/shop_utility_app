// Application State
let allLicenses = [];

// Helper to escape HTML to prevent XSS vulnerabilities
function escapeHTML(str) {
  if (!str) return '';
  return String(str)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#39;');
}

// DOM Elements
const licensesListEl = document.getElementById('licenses-list');
const searchInput = document.getElementById('search-input');
const btnRefresh = document.getElementById('btn-refresh');

// Stats Counters
const statTotal = document.getElementById('stat-total');
const statBound = document.getElementById('stat-bound');
const statUnused = document.getElementById('stat-unused');
const statDeactivated = document.getElementById('stat-deactivated');

// Initialization
document.addEventListener('DOMContentLoaded', () => {
  fetchLicenses();
  
  // Search filter
  searchInput.addEventListener('input', () => {
    filterAndRender();
  });
  
  // Refresh button
  btnRefresh.addEventListener('click', (e) => {
    e.preventDefault();
    fetchLicenses();
  });
});

// Fetch all keys from REST API
async function fetchLicenses() {
  setLoadingState();
  try {
    const response = await fetch('/api/licenses');
    if (!response.ok) throw new Error('Failed to fetch licenses');
    allLicenses = await response.json();
    updateStats();
    filterAndRender();
  } catch (error) {
    console.error('Error fetching licenses:', error);
    licensesListEl.innerHTML = `
      <tr>
        <td colspan="6" class="table-loading font-danger">
          <i data-lucide="alert-triangle"></i> Error loading licenses. Please make sure the server is running.
        </td>
      </tr>
    `;
    lucide.createIcons();
  }
}

// Compute counts for statistic panels
function updateStats() {
  const total = allLicenses.length;
  let bound = 0;
  let unused = 0;
  let deactivated = 0;

  const now = new Date();

  allLicenses.forEach(lic => {
    if (!lic.isActive) {
      deactivated++;
    } else if (lic.deviceId) {
      bound++;
    } else {
      unused++;
    }
  });

  statTotal.textContent = total;
  statBound.textContent = bound;
  statUnused.textContent = unused;
  statDeactivated.textContent = deactivated;
}

// Set list table loading view
function setLoadingState() {
  licensesListEl.innerHTML = `
    <tr>
      <td colspan="6" class="table-loading">
        <i data-lucide="loader" class="spinner"></i> Loading licenses...
      </td>
    </tr>
  `;
  lucide.createIcons();
}

// Filter licenses based on search box input
function filterAndRender() {
  const query = searchInput.value.trim().toLowerCase();
  if (!query) {
    renderLicenses(allLicenses);
    return;
  }
  
  const filtered = allLicenses.filter(lic => {
    const keyMatch = lic.key.toLowerCase().includes(query);
    const deviceMatch = (lic.deviceId || '').toLowerCase().includes(query);
    return keyMatch || deviceMatch;
  });
  
  renderLicenses(filtered);
}

// Render the licenses to the table
function renderLicenses(licenses) {
  if (licenses.length === 0) {
    licensesListEl.innerHTML = `
      <tr>
        <td colspan="6" class="table-loading">
          No licenses found.
        </td>
      </tr>
    `;
    lucide.createIcons();
    return;
  }

  const now = new Date();

  const rows = licenses.map(lic => {
    // Determine status badge
    let statusClass = 'unused';
    let statusText = 'Unused';

    if (!lic.isActive) {
      statusClass = 'revoked';
      statusText = 'Deactivated';
    } else if (lic.deviceId) {
      if (lic.expiryDate && new Date(lic.expiryDate) < now) {
        statusClass = 'expired';
        statusText = 'Expired';
      } else {
        statusClass = 'active';
        statusText = 'Active';
      }
    }

    const boundDevice = lic.deviceId 
      ? `<span class="device-code">${escapeHTML(lic.deviceId)}</span>`
      : `<span style="color: var(--text-dark); font-style: italic;">None</span>`;

    const createdDate = new Date(lic.createdAt).toLocaleDateString(undefined, {
      year: 'numeric',
      month: 'short',
      day: 'numeric'
    });

    const expirationDate = lic.expiryDate
      ? new Date(lic.expiryDate).toLocaleDateString(undefined, {
          year: 'numeric',
          month: 'short',
          day: 'numeric'
        })
      : `<span style="color: var(--text-dark);">Never</span>`;

    return `
      <tr>
        <td>
          <span class="key-code" onclick="copyToClipboard('${escapeHTML(lic.key)}')" title="Click to Copy">
            ${escapeHTML(lic.key)} <i data-lucide="copy" style="width: 12px; height: 12px; opacity: 0.5;"></i>
          </span>
        </td>
        <td>
          <span class="badge ${statusClass}">${statusText}</span>
        </td>
        <td>${boundDevice}</td>
        <td>${createdDate}</td>
        <td>${expirationDate}</td>
        <td>
          <div style="display: flex; gap: 8px;">
            <button class="btn-icon" onclick="openEditModal('${escapeHTML(lic.key)}')" title="Edit Key">
              <i data-lucide="pencil"></i>
            </button>
            <button class="btn-icon danger" onclick="handleDeleteLicense('${escapeHTML(lic.key)}')" title="Delete Key">
              <i data-lucide="trash-2"></i>
            </button>
          </div>
        </td>
      </tr>
    `;
  });

  licensesListEl.innerHTML = rows.join('');
  lucide.createIcons();
}

// Copy helper
function copyToClipboard(text) {
  navigator.clipboard.writeText(text);
  // Show a tiny non-intrusive alert
  const originalTitle = document.title;
  document.title = "Copied Key!";
  setTimeout(() => {
    document.title = originalTitle;
  }, 1000);
}

// Handle key generation form submit
async function handleGenerate(e) {
  e.preventDefault();
  const count = document.getElementById('generate-count').value;
  try {
    const response = await fetch('/api/licenses', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ generateCount: count })
    });
    const result = await response.json();
    if (result.success) {
      closeModal('modal-generate');
      fetchLicenses();
    } else {
      alert(result.message || 'Error generating keys');
    }
  } catch (error) {
    console.error('Error generating keys:', error);
    alert('Network error generating keys');
  }
}

// Handle custom key generation form submit
async function handleCreateCustom(e) {
  e.preventDefault();
  const customKey = document.getElementById('custom-key').value;
  try {
    const response = await fetch('/api/licenses', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ customKey })
    });
    const result = await response.json();
    if (result.success) {
      closeModal('modal-custom');
      document.getElementById('custom-key').value = '';
      fetchLicenses();
    } else {
      alert(result.message || 'Key already exists');
    }
  } catch (error) {
    console.error('Error creating custom key:', error);
    alert('Network error creating custom key');
  }
}

// Open Edit modal with details filled
function openEditModal(keyName) {
  const lic = allLicenses.find(l => l.key === keyName);
  if (!lic) return;

  document.getElementById('edit-key-id').value = lic.key;
  document.getElementById('edit-key-display').value = lic.key;
  document.getElementById('edit-device-id').value = lic.deviceId || '';
  document.getElementById('edit-is-active').checked = lic.isActive;

  if (lic.expiryDate) {
    // Format to yyyy-MM-dd for HTML date input
    const date = new Date(lic.expiryDate);
    const yyyy = date.getFullYear();
    const mm = String(date.getMonth() + 1).padStart(2, '0');
    const dd = String(date.getDate()).padStart(2, '0');
    document.getElementById('edit-expiry-date').value = `${yyyy}-${mm}-${dd}`;
  } else {
    document.getElementById('edit-expiry-date').value = '';
  }

  openModal('modal-edit');
}

// Click unbind button inside edit modal
function unbindDevice() {
  document.getElementById('edit-device-id').value = '';
}

// Save edits
async function handleSaveEdit(e) {
  e.preventDefault();
  const key = document.getElementById('edit-key-id').value;
  const deviceId = document.getElementById('edit-device-id').value;
  const expiryInput = document.getElementById('edit-expiry-date').value;
  const isActive = document.getElementById('edit-is-active').checked;

  let expiryDate = '';
  if (expiryInput) {
    // Convert to ISO string at midnight UTC
    expiryDate = new Date(expiryInput).toISOString();
  }

  try {
    const response = await fetch(`/api/licenses/${key}`, {
      method: 'PUT',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ deviceId, expiryDate, isActive })
    });
    const result = await response.json();
    if (result.success) {
      closeModal('modal-edit');
      fetchLicenses();
    } else {
      alert(result.message || 'Error updating key');
    }
  } catch (error) {
    console.error('Error updating license:', error);
    alert('Network error updating key details');
  }
}

// Delete key
async function handleDeleteLicense(key) {
  const confirmDel = confirm(`Are you sure you want to permanently delete license key:\n${key}?`);
  if (!confirmDel) return;

  try {
    const response = await fetch(`/api/licenses/${key}`, {
      method: 'DELETE'
    });
    const result = await response.json();
    if (result.success) {
      fetchLicenses();
    } else {
      alert(result.message || 'Error deleting key');
    }
  } catch (error) {
    console.error('Error deleting license:', error);
    alert('Network error deleting key');
  }
}

// Modal helper controls
function openModal(id) {
  const modal = document.getElementById(id);
  if (modal) modal.classList.add('open');
}

function closeModal(id) {
  const modal = document.getElementById(id);
  if (modal) modal.classList.remove('open');
}
