// Application State
let allLicenses = [];
let keyToDelete = '';

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
const loginContainer = document.getElementById('login-container');
const appContainer = document.getElementById('app-container');
const formLogin = document.getElementById('form-login');
const loginError = document.getElementById('login-error');
const loginErrorMsg = document.getElementById('login-error-msg');
const btnLogout = document.getElementById('btn-logout');

// Stats Counters
const statTotal = document.getElementById('stat-total');
const statBound = document.getElementById('stat-bound');
const statUnused = document.getElementById('stat-unused');
const statDeactivated = document.getElementById('stat-deactivated');

// Check authentication token status and toggle views
function checkAuthStatus() {
  const token = localStorage.getItem('admin_token');
  if (token) {
    loginContainer.style.display = 'none';
    appContainer.style.display = 'flex';
    fetchLicenses();
  } else {
    loginContainer.style.display = 'flex';
    appContainer.style.display = 'none';
  }
}

// Helper to get authenticated headers
function getAuthHeaders() {
  const token = localStorage.getItem('admin_token');
  return {
    'Content-Type': 'application/json',
    'Authorization': `Bearer ${token}`
  };
}

// Handle login failure or expired session
function handleUnauthorized() {
  localStorage.removeItem('admin_token');
  checkAuthStatus();
}

// Handle authentication login
async function handleLogin(event) {
  event.preventDefault();
  loginError.style.display = 'none';
  
  const usernameInput = document.getElementById('login-username');
  const passwordInput = document.getElementById('login-password');
  const username = usernameInput.value.trim();
  const password = passwordInput.value;
  
  try {
    const response = await fetch('/api/login', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ username, password })
    });
    
    const result = await response.json();
    if (response.ok && result.success) {
      localStorage.setItem('admin_token', result.token);
      usernameInput.value = '';
      passwordInput.value = '';
      checkAuthStatus();
    } else {
      loginErrorMsg.textContent = result.message || 'Invalid username or password';
      loginError.style.display = 'flex';
    }
  } catch (error) {
    console.error('Login error:', error);
    loginErrorMsg.textContent = 'Server communication error. Please try again.';
    loginError.style.display = 'flex';
  }
}

// Handle administrative logout
function handleLogout() {
  localStorage.removeItem('admin_token');
  checkAuthStatus();
}

// Initialization
document.addEventListener('DOMContentLoaded', () => {
  checkAuthStatus();
  
  // Search filter
  searchInput.addEventListener('input', () => {
    filterAndRender();
  });
  
  // Refresh button
  btnRefresh.addEventListener('click', (e) => {
    e.preventDefault();
    fetchLicenses();
  });

  // Logout button
  if (btnLogout) {
    btnLogout.addEventListener('click', (e) => {
      e.preventDefault();
      handleLogout();
    });
  }

  // Mobile drawer controls
  const btnMenuToggle = document.getElementById('btn-menu-toggle');
  const sidebarMenu = document.getElementById('sidebar-menu');
  const sidebarBackdrop = document.getElementById('sidebar-backdrop');
  
  if (btnMenuToggle && sidebarMenu && sidebarBackdrop) {
    btnMenuToggle.addEventListener('click', () => {
      sidebarMenu.classList.add('open');
      sidebarBackdrop.classList.add('active');
    });
    
    sidebarBackdrop.addEventListener('click', () => {
      sidebarMenu.classList.remove('open');
      sidebarBackdrop.classList.remove('active');
    });

    // Close drawer when navigation links are clicked
    const drawerLinks = sidebarMenu.querySelectorAll('.nav-item');
    drawerLinks.forEach(link => {
      link.addEventListener('click', () => {
        sidebarMenu.classList.remove('open');
        sidebarBackdrop.classList.remove('active');
      });
    });
  }

  // Custom delete confirm button
  document.getElementById('btn-confirm-delete').addEventListener('click', submitDeleteLicense);
});

// Fetch all keys from REST API
async function fetchLicenses() {
  setLoadingState();
  try {
    const response = await fetch('/api/licenses', {
      headers: getAuthHeaders()
    });
    if (response.status === 401) {
      handleUnauthorized();
      return;
    }
    if (!response.ok) throw new Error('Failed to fetch licenses');
    allLicenses = await response.json();
    updateStats();
    filterAndRender();
  } catch (error) {
    console.error('Error fetching licenses:', error);
    licensesListEl.innerHTML = `
      <tr>
        <td colspan="7" class="table-loading font-danger">
          <i data-lucide="alert-triangle"></i> Error loading licenses. Please make sure you are signed in and the server is running.
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
      <td colspan="7" class="table-loading">
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
    const clientMatch = (lic.clientName || '').toLowerCase().includes(query);
    return keyMatch || deviceMatch || clientMatch;
  });
  
  renderLicenses(filtered);
}

// Render the licenses to the table
function renderLicenses(licenses) {
  if (licenses.length === 0) {
    licensesListEl.innerHTML = `
      <tr>
        <td colspan="7" class="table-loading">
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

    const clientName = lic.clientName 
      ? `<span style="font-weight: 600;">${escapeHTML(lic.clientName)}</span>`
      : `<span style="color: var(--text-dark); font-style: italic;">Unassigned</span>`;

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
        <td>${clientName}</td>
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
  const clientName = document.getElementById('generate-client-name').value;
  try {
    const response = await fetch('/api/licenses', {
      method: 'POST',
      headers: getAuthHeaders(),
      body: JSON.stringify({ generateCount: count, clientName })
    });
    if (response.status === 401) {
      handleUnauthorized();
      return;
    }
    const result = await response.json();
    if (result.success) {
      closeModal('modal-generate');
      document.getElementById('generate-client-name').value = '';
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
  const clientName = document.getElementById('custom-client-name').value;
  try {
    const response = await fetch('/api/licenses', {
      method: 'POST',
      headers: getAuthHeaders(),
      body: JSON.stringify({ customKey, clientName })
    });
    if (response.status === 401) {
      handleUnauthorized();
      return;
    }
    const result = await response.json();
    if (result.success) {
      closeModal('modal-custom');
      document.getElementById('custom-key').value = '';
      document.getElementById('custom-client-name').value = '';
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
  document.getElementById('edit-client-name').value = lic.clientName || '';
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
  const clientName = document.getElementById('edit-client-name').value;
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
      headers: getAuthHeaders(),
      body: JSON.stringify({ deviceId, expiryDate, isActive, clientName })
    });
    if (response.status === 401) {
      handleUnauthorized();
      return;
    }
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

// Open delete confirmation modal
function handleDeleteLicense(key) {
  keyToDelete = key;
  document.getElementById('delete-key-display').textContent = key;
  openModal('modal-delete');
}

// Perform license key deletion
async function submitDeleteLicense() {
  if (!keyToDelete) return;

  try {
    const response = await fetch(`/api/licenses/${keyToDelete}`, {
      method: 'DELETE',
      headers: getAuthHeaders()
    });
    if (response.status === 401) {
      handleUnauthorized();
      return;
    }
    const result = await response.json();
    if (result.success) {
      closeModal('modal-delete');
      keyToDelete = '';
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
