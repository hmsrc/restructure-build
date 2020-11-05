# Build ReStructure

A Dockerfile and scripts to build ReStructure and commit it to a repository

Copy `build-vars-sample.sh` to `build-vars.sh` and edit it with your details.

If you need to commit the built version to a different *production* repository, specify the `PROD_REPO_URL`
environment variable with the URL to the repo.

Set up a file `.netrc` to include login credentials to any private git repos (the original source
and optionally the production repo) to allow the container to clone, pull and push your code. The file 
contents should look like:

    machine github.com login mygithubid password myplaintextpassword
    machine hostname.of.prod.repo login prodrepouserid password anotherplaintextpassword

Protect the plaintext file with:

    chmod 600 .netrc

If you use `.netrc` for your git authentication anyway, then a symlink will suffice:

    ln -s ~/.netrc ./.netrc

Ensure that `build-vars.sh` and `.netrc` are not committed to source control. Check the `.gitignore` file.

Build the container with:

    build . -t consected/restructure-build




