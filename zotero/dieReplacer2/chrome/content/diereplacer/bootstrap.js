var dieReplacer = {
  init: function() {
    // Log initialization
    Zotero.debug("Die Replacer initializing...");

    // XUL overlay for menu item
    window.addEventListener('load', function() {
      // Delay to make sure the interface is loaded
      setTimeout(function() {
        dieReplacer.addMenuItem();
      }, 500);
    });
  },

  addMenuItem: function() {
    Zotero.debug("Adding menu item for Die Replacer...");
    // No need to manually add menu, XUL overlay handles this
  },

  openDialog: function() {
    Zotero.debug("Opening Search and Replace dialog...");
    window.openDialog('chrome://diereplacer/content/dialog.html', 'SearchReplace', 'chrome,centerscreen,modal');
  }
};

// Initialize the plugin when Zotero loads
window.addEventListener('load', dieReplacer.init, false);

Components.utils.import("resource://gre/modules/Services.jsm");

Services.scriptloader.loadSubScript('chrome://diereplacer/content/style.css', window);