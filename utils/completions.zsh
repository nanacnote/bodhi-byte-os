_bodhi_completion()
{
    local curcontext="$curcontext" state line
    typeset -A opt_args

    _arguments '1: :->command' '*: :->args'

    case $state in
        command)
            _values "commands" \
                help \
                save-pkglist \
                apply-symlinks \
                install-dwm \
                install-st \
                install-dmenu \
                install-slock \
                install-dwmblocks \
                install-svkbd \
                install-bleuz-alsa \
                install-whisper
            ;;
        args)
            case $words[2] in
                *)
                    _values "options" ""
                    ;;
            esac
            ;;
    esac
}

_dwm_status_bar()
{
    local curcontext="$curcontext" state line
    typeset -A opt_args

    _arguments '1: :->command' '*: :->args'

    case $state in
        command)
            _values "commands" \
                status \
                start \
                refresh
            ;;
        args)
            case $words[2] in
                *)
                    _values "options" ""
                    ;;
            esac
            ;;
    esac
}


_qemu_vm_manager_completion()
{
    local curcontext="$curcontext" state line
    typeset -A opt_args

    _arguments '1: :->command' '*: :->args'

    case $state in
        command)
            _values "commands" \
                install \
                start \
                stop \
                status \
                create-bridge \
                remove-bridge \
                mount-qcow \
                umount-qcow
            ;;
        args)
            case $words[2] in
                install)
                    _values "options" --iso --pre
                    ;;
                start)
                    _values "options" --img --vid --port --if
                    ;;
                mount-qcow)
                    _values "options" --qcow-path
                    ;;
            esac
            ;;
    esac
}


compdef _qemu_vm_manager_completion qvm
compdef _dwm_status_bar dwm-status-bar
compdef _bodhi_completion bodhi

