{ config, pkgs, ... }:

{
  home.username = "efueyo";
  home.homeDirectory = "/home/efueyo";
  home.stateVersion = "24.05";
  home.sessionPath = [ "$HOME/bin" ];
  programs.home-manager.enable = true;
  programs.git = {
    enable = true;
    userName = "efueyo";
    userEmail = "efueyo@lang.ai";
    extraConfig = {
      rerere = { enable = true; };
      init = { defaultBranch = "main"; };
      pull = { rebase = true; };
      push = { autoSetupRemote = true; };
    };
  };
  programs.tmux = {
    enable = true;
    baseIndex = 1;
    plugins = with pkgs.tmuxPlugins; [
      sensible
      catppuccin
      vim-tmux-navigator
    ];
  };
  home.file.".tmux.conf".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/repos/dotfiles/tmux/tmux.conf";
  home.file."bin".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/repos/dotfiles/bin";
  xdg.configFile."nvim".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/repos/dotfiles/nvim";
  xdg.configFile."wezterm".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/repos/dotfiles/wezterm";
  xdg.configFile."fish".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/repos/dotfiles/fish";
  xdg.configFile."starship.toml".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/repos/dotfiles/starship/starship.toml";
}
