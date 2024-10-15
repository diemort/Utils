const { Zotero } = require('zotero');

function openDialog() {
    // Use the new dialog creation method for Zotero 6
    Zotero.UI.showModal('dialog.html', {
        title: 'Search and Replace',
        width: 400,
        height: 300,
        buttons: [
            { label: 'Cancel', action: 'cancel' },
            { label: 'Replace', action: 'replace' }
        ]
    });
}

function searchAndReplace(searchStr, replaceStr, scope) {
    const items = scope === 'all' 
        ? await Zotero.Items.getAll() 
        : scope === 'collection' 
        ? await Zotero.Collections.getCurrentCollection().getItems() 
        : await Zotero.SelectedItems.get();

    items.forEach(item => {
        for (const field in item) {
            if (typeof item[field] === 'string') {
                item[field] = item[field].replace(new RegExp(searchStr, 'g'), replaceStr);
            }
        }

        // Handle attachments as before
        if (item.attachments) {
            item.attachments.forEach(attachment => {
                let originalFilename = attachment.getField('title');
                let newFilename = originalFilename.replace(new RegExp(searchStr, 'g'), replaceStr);
                attachment.setField('title', newFilename);
                attachment.save();
            });
        }

        item.save();
    });
}

// Create a button in the Zotero toolbar
Zotero.UI.createToolbarButton('searchReplace', 'Search and Replace', openDialog);