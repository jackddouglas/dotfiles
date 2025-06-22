{ pkgs, inputs, ... }:
{
  programs.tmux = {
    enable = true;
    baseIndex = 1;
    clock24 = true;
    mouse = true;
    plugins = with pkgs; [
      tmuxPlugins.vim-tmux-navigator
      { plugin = inputs.minimal-tmux.packages.${pkgs.system}.default; }
      # {
      #   plugin = tmuxPlugins.dracula;
      #   extraConfig = ''
      #     set -g @dracula-colors "
      #     # Dracula Color Pallette
      #     white='#A3A3A3'
      #     gray='#2A2A2A'
      #     dark_gray='#A3A3A3'
      #     light_purple='#8B7EC8'
      #     dark_purple='#324757'
      #     cyan='#3E3E3E'
      #     green='#525252'
      #     orange='#525252'
      #     red='#D14D41'
      #     pink='#343331'
      #     yellow='#324757'
      #     "
      #
      #     set -g @dracula-show-fahrenheit false
      #     set -g @dracula-fixed-location "London"
      #     set -g @dracula-show-location false
      #   '';
      # }
    ];
    prefix = "C-Space";
    shell = "${pkgs.zsh}/bin/zsh";
    shortcut = "Space";
    terminal = "tmux-256color";
    tmuxinator.enable = true;
    extraConfig = ''
      unbind r
      bind r source-file /Users/jackdouglas/.config/tmux/tmux.conf

      unbind L
      bind -r L next-layout

      set -g mode-keys vi
      set -g mouse on
      bind-key h select-pane -L
      bind-key j select-pane -D
      bind-key k select-pane -U
      bind-key l select-pane -R

      # increase lines of window history
      set-option -g history-limit 5000

      set -sg escape-time 10
      set -g status-position bottom

      # numbering windows/panes
      set -g base-index 1
      setw -g pane-base-index 1
      set -g renumber-windows on

      # more intuitive split commands
      bind-key "|" split-window -h -c "#{pane_current_path}"
      bind-key "\\" split-window -fh -c "#{pane_current_path}"

      bind-key "-" split-window -v -c "#{pane_current_path}"
      bind-key "_" split-window -fv -c "#{pane_current_path}"

      # swap windows
      bind -r "<" swap-window -d -t -1
      bind -r ">" swap-window -d -t +1

      # keep current path
      bind c new-window -c "#{pane_current_path}"

      # toggle windows/sessions
      bind Space last-window
      bind-key C-Space switch-client -l

      # resizing
      bind -r C-j resize-pane -D 15
      bind -r C-k resize-pane -U 15
      bind -r C-h resize-pane -L 15
      bind -r C-l resize-pane -R 15

      # show/hide status
      bind-key b set-option status

      # minimal theme
      set -g @minimal-tmux-fg "#3F7EB6"
      set -g @minimal-tmux-bg "#12253B"

      source-file /Users/jackdouglas/.config/tmux/tmux.conf
    '';
  };
}
