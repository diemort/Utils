const checkInterval = 1; // minutes

chrome.runtime.onInstalled.addListener(() => {
    chrome.alarms.create("checkURLs", { periodInMinutes: checkInterval });
    checkURLs();
});

chrome.alarms.onAlarm.addListener((alarm) => {
    if (alarm.name === "checkURLs") {
        checkURLs();
    }
});

async function checkURLs() {
    const urls = await getURLs();
    const statuses = await Promise.all(
        urls.map(async ({ url }) => {
            if (!url) return false;
            try {
                const res = await fetch(url, { method: "HEAD", cache: "no-cache" });
                return res.ok;
            } catch {
                return false;
            }
        })
    );

    await updateIcon(statuses);
    await updateTooltip(urls, statuses);

    // Save statuses for popup
    chrome.storage.local.set({ statuses });
}

function getURLs() {
    return new Promise((resolve) => {
        chrome.storage.sync.get(
            {
                urls: [
                    { url: "https://example.com", name: "Left" },
                    { url: "https://example.org", name: "Right" }
                ]
            },
            (data) => resolve(data.urls)
        );
    });
}

function updateTooltip(urls, statuses) {
    const tooltip = `${urls[0].name || "Left"}: ${statuses[0] ? "OK" : "FAIL"}, ` +
                    `${urls[1].name || "Right"}: ${statuses[1] ? "OK" : "FAIL"}`;
    chrome.action.setTitle({ title: tooltip });
}

function updateIcon([leftStatus, rightStatus]) {
    const canvas = new OffscreenCanvas(32, 32);
    const ctx = canvas.getContext("2d");

    const slitWidth = 16; // Half the icon width (32)

    // Left slit (fills left half)
    ctx.fillStyle = leftStatus ? "green" : "red";
    ctx.fillRect(0, 0, slitWidth, 32);

    // Right slit (fills right half)
    ctx.fillStyle = rightStatus ? "green" : "red";
    ctx.fillRect(16, 0, slitWidth, 32);

    const imageData = ctx.getImageData(0, 0, 32, 32);
    chrome.action.setIcon({ imageData });
}