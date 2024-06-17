# environment vars
export XDG_CONFIG_HOME="${HOME}/.config"
export EDITOR=vim

export PATH="${HOME}/.local/bin:${PATH}"      # pip install <pkg> --user  # user flag installs bin here (eg. pipenv, tox etc)
export PIPENV_VENV_IN_PROJECT=1               # forces pipenv to use "the-projects-root/.venv" to store venv


# start dwm
startx

