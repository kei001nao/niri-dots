if status is-interactive

    # Load Moondust theme
    fish_config theme choose moondust

    # Initialize Starship for colors/modules
    starship init fish | source

    # Optional: run Fastfetch once at terminal start
    fastfetch

end
