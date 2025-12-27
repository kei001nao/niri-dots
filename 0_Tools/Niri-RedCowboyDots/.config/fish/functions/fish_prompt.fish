function fish_prompt    
        echo

        set -l retc red
        test $status = 0; and set retc green
    
        set -q __fish_git_prompt_showupstream
        or set -g __fish_git_prompt_showupstream auto
    
        function _nim_prompt_wrapper
                set retc $argv[1]
                set -l field_name $argv[2]
                set -l field_value $argv[3]
        
                set_color --underline normal
                set_color $retc

                echo -n '✮༻ '
                set_color --underline normal
                test -n $field_name
                and echo -n $field_name:
                echo -n $field_value
                echo -n '༺ ✮'
        end
    
        set_color -o green
        echo -n '《✧╞══ '
    
        if functions -q fish_is_root_user; and fish_is_root_user
                set_color -o red
        else
                set_color -o yellow
        end
    
        echo -n $USER
        set_color -o green
        echo -n @
    
        if test -z "$SSH_CLIENT"
                set_color -o grey
        else
                set_color -o blue
        end
    
        echo -n (prompt_hostname)
        set_color -o red
        echo -n ' 𐚁 : '
        echo -n (prompt_pwd)
        set_color -o green
        echo -n ' ══╡✧》 '
    
        # Date
        _nim_prompt_wrapper $retc '' (date +%X)
    
        # Vi-mode
    
        if test "$fish_key_bindings" = fish_vi_key_bindings
                or test "$fish_key_bindings" = fish_hybrid_key_bindings
                set -l mode
                switch $fish_bind_mode
                        case default
                                set mode (set_color --bold red)N
                        case insert
                                set mode (set_color --bold green)I
                        case replace_one
                                set mode (set_color --bold green)R
                        case replace
                                set mode (set_color --bold cyan)R
                        case visual
                                set mode (set_color --bold magenta)V
                end
                set mode $mode(set_color normal)
                _nim_prompt_wrapper $retc '' $mode
        end
    
        # Virtual Environment
        set -q VIRTUAL_ENV_DISABLE_PROMPT
        or set -g VIRTUAL_ENV_DISABLE_PROMPT true
        set -q VIRTUAL_ENV
        and _nim_prompt_wrapper $retc V (path basename "$VIRTUAL_ENV")
    
        # git
        set -l prompt_git (fish_git_prompt '%s')
        test -n "$prompt_git"
        and _nim_prompt_wrapper $retc G $prompt_git
    
        # Battery status
        type -q acpi
        and acpi -a 2>/dev/null | string match -rq off
        and _nim_prompt_wrapper $retc B (acpi -b | cut -d' ' -f 4-)
    
        # New line
        echo
    
        # Background jobs
        set_color normal
    
        for job in (jobs)
                set_color $retc
                echo -n '󰳳 '
                set_color brown
                echo $job
        end
    
        set_color --bold -o red
        echo -n ' ╭̔ᴝ═ ҉  --⁍ '
        set_color normal
end
