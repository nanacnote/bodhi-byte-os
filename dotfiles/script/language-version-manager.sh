#!/bin/bash

curl https://pyenv.run | bash
curl https://get.sdkman.io?rcupdate=false | bash
NVM_DIR="${HOME}/.nvm" PROFILE=/dev/null bash -c 'curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash'
