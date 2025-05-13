{pkgs, ...}: {
  enable = true;
  user = "taylor";
  directory = "/home/taylor";
  files = {
    # zsh
    ".zshrc" = {
      enable = true;
      executable = false;
      clobber = true;
      target = ".zshrc";
      # source = ./files/zsh/default.zshrc;
      text = ''
        ${builtins.readFile ./files/zsh/default.zshrc}
        source ${pkgs.zsh-vi-mode}/share/zsh-vi-mode/zsh-vi-mode.plugin.zsh
        source ${pkgs.zsh-autosuggestions}/share/zsh-autosuggestions/zsh-autosuggestions.zsh
      '';
    };

    # oh-my-posh
    ".config/oh-my-posh/zen.toml" = {
      enable = true;
      executable = false;
      clobber = true;
      target = ".config/oh-my-posh/zen.toml";
      source = ./files/oh-my-posh/default.toml;
    };

    # git
    ".gitconfig" = {
      enable = true;
      executable = false;
      clobber = true;
      target = ".gitconfig";
      source = ./files/git/default.gitconfig;
    };
  };
}
