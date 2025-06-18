document.addEventListener('DOMContentLoaded', async () => {
    const statusDiv = document.getElementById('status');

    const { urls = [] } = await chrome.storage.sync.get('urls');
    const { statuses = [false, false] } = await chrome.storage.local.get('statuses');

    urls.forEach((entry, index) => {
        const div = document.createElement('div');
        const status = statuses[index] ? '🟢 OK' : '🔴 FAIL';
        const statusClass = statuses[index] ? 'ok' : 'fail';
        div.className = 'status-line';
        div.innerHTML = `<strong>${entry.name || `URL ${index + 1}`}</strong>: 
                         <span class="${statusClass}">${status}</span>`;
        statusDiv.appendChild(div);
    });

    // Handle click to open options page in a full tab
    const openOptions = document.getElementById('open-options');
    if (openOptions) {
        openOptions.addEventListener('click', () => {
            chrome.runtime.openOptionsPage();
        });
    }
});