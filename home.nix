{ config, pkgs, ... }:

{
  home.username = "efueyo";
  home.homeDirectory = "/home/efueyo";
  home.stateVersion = "24.05";
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
  xdg.configFile."nvim".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/repos/dotfiles/nvim";
  xdg.configFile."wezterm".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/repos/dotfiles/wezterm";
  xdg.configFile."fish".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/repos/dotfiles/fish";
  xdg.configFile."starship.toml".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/repos/dotfiles/starship/starship.toml";
}
