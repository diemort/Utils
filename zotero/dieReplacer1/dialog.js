document.getElementById('replaceButton').addEventListener('click', function() {
    const searchStr = document.getElementById('search').value;
    const replaceStr = document.getElementById('replace').value;
    const scope = document.getElementById('scope').value;

    // Call the search and replace function
    searchAndReplace(searchStr, replaceStr, scope);
});