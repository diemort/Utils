document.getElementById('bookmarkButton').addEventListener('click', function () {
  chrome.runtime.sendMessage({ command: 'bookmarkTabs' });
});