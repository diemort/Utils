document.addEventListener('DOMContentLoaded', restoreOptions);
document.getElementById('save').addEventListener('click', saveOptions);

function saveOptions() {
    const urls = [
        {
            name: document.getElementById('name1').value.trim(),
            url: document.getElementById('url1').value.trim()
        },
        {
            name: document.getElementById('name2').value.trim(),
            url: document.getElementById('url2').value.trim()
        }
    ];

    chrome.storage.sync.set({ urls }, () => {
        const status = document.getElementById('status');
        status.textContent = 'Options saved.';
        setTimeout(() => status.textContent = '', 1500);
    });
}

function restoreOptions() {
    chrome.storage.sync.get(
        {
            urls: [
                { name: 'Left', url: 'https://example.com' },
                { name: 'Right', url: 'https://example.org' }
            ]
        },
        (data) => {
            document.getElementById('name1').value = data.urls[0].name;
            document.getElementById('url1').value = data.urls[0].url;
            document.getElementById('name2').value = data.urls[1].name;
            document.getElementById('url2').value = data.urls[1].url;
        }
    );
}