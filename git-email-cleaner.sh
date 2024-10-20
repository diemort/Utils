#!/bin/bash

# Ensure you have a clean working directory
git checkout main
# Rewrite the commit history to change the author email
git filter-branch --env-filter \
'
OLD_EMAIL="my.personal@email.me"
CORRECT_NAME="My Username"
CORRECT_EMAIL="12345678+username@users.noreply.github.com"
if [ "$GIT_COMMITTER_EMAIL" = "$OLD_EMAIL" ]
then
    export GIT_COMMITTER_NAME="$CORRECT_NAME"
    export GIT_COMMITTER_EMAIL="$CORRECT_EMAIL"
fi
if [ "$GIT_AUTHOR_EMAIL" = "$OLD_EMAIL" ]
then
    export GIT_AUTHOR_NAME="$CORRECT_NAME"
    export GIT_AUTHOR_EMAIL="$CORRECT_EMAIL"
fi
' --tag-name-filter cat -- --branches --tags
# Force push the changes to the repository
git push --force --tags origin 'refs/heads/*'
