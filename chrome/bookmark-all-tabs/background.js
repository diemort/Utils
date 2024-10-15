// Create a context menu item
chrome.runtime.onInstalled.addListener(function () {
  chrome.contextMenus.create({
    id: "bookmarkAllTabs",
    title: "Bookmark All Tabs",
    contexts: ["all"]
  });
});

// Handle the context menu click event
chrome.contextMenus.onClicked.addListener(function (info, tab) {
  if (info.menuItemId === "bookmarkAllTabs") {
    bookmarkAllTabs();
  }
});

// Handle the toolbar button click (single left-click)
chrome.action.onClicked.addListener(function () {
  bookmarkAllTabs();
});

// Function to bookmark all tabs
function bookmarkAllTabs() {
  chrome.windows.getAll({ populate: true }, function (windows) {
    function getOrCreateMemoryFolder(callback) {
      chrome.bookmarks.search({ title: 'Memory' }, function (results) {
        if (results.length > 0) {
          callback(results[0]);
        } else {
          chrome.bookmarks.create({ title: 'Memory' }, callback);
        }
      });
    }

    getOrCreateMemoryFolder(function (memoryFolder) {
      // Search for and delete existing "Chrome Window" folders
      chrome.bookmarks.getChildren(memoryFolder.id, function (children) {
        const windowFolders = children.filter(child => child.title.startsWith("Chrome Window"));

        windowFolders.forEach(function (folder) {
          chrome.bookmarks.removeTree(folder.id);
        });

        // Create new folders for each window
        windows.forEach(function (window, windowIndex) {
          const windowFolderTitle = `Chrome Window ${windowIndex + 1}`;
          chrome.bookmarks.create({
            parentId: memoryFolder.id,
            title: windowFolderTitle
          }, function (windowFolder) {
            const pinnedTabs = [];
            const groupedTabs = {};
            const ungroupedTabs = [];

            // Organize tabs into pinned, grouped, and ungrouped
            window.tabs.forEach(function (tab) {
              if (tab.pinned) {
                pinnedTabs.push(tab);
              } else if (tab.groupId !== -1) {
                if (!groupedTabs[tab.groupId]) {
                  groupedTabs[tab.groupId] = [];
                }
                groupedTabs[tab.groupId].push(tab);
              } else {
                ungroupedTabs.push(tab);
              }
            });

            // Save pinned tabs first
            pinnedTabs.forEach(function (tab) {
              chrome.bookmarks.create({
                parentId: windowFolder.id,
                title: tab.title,
                url: tab.url
              });
            });

            // Save grouped tabs next
            if (chrome.tabGroups) {
              Object.keys(groupedTabs).forEach(function (groupId) {
                chrome.tabGroups.get(parseInt(groupId), function (group) {
                  if (chrome.runtime.lastError) {
                    console.error(`Failed to retrieve group: ${chrome.runtime.lastError.message}`);
                    return;
                  }

                  if (group) {
                    const groupTitle = group.title || `Group ${groupId}`;
                    chrome.bookmarks.create({
                      parentId: windowFolder.id,
                      title: groupTitle
                    }, function (groupFolder) {
                      groupedTabs[groupId].forEach(function (tab) {
                        chrome.bookmarks.create({
                          parentId: groupFolder.id,
                          title: tab.title,
                          url: tab.url
                        });
                      });
                    });
                  }
                });
              });
            } else {
              console.warn('Tab Groups API is not available.');
            }

            // Save ungrouped tabs last
            ungroupedTabs.forEach(function (tab) {
              chrome.bookmarks.create({
                parentId: windowFolder.id,
                title: tab.title,
                url: tab.url
              });
            });
          });
        });
      });
    });
  });
}