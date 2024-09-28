{ config, pkgs, ... }:

{
  home.username = "efueyo";
  home.homeDirectory = "/home/efueyo";
  home.stateVersion = "24.11";
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
}
