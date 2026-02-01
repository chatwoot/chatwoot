{pkgs}: {
  channel = "stable-24.05";
  packages = [
    pkgs.pnpm
    pkgs.nodejs_20
    pkgs.ruby_3_2
    pkgs.bundler
    pkgs.rbenv
    pkgs.sudo
    pkgs.google-cloud-sdk
    pkgs.gh
    pkgs.terraform
  ];
  idx.extensions = [
    "svelte.svelte-vscode"
    "vue.volar"
  ];
  idx.previews = {
    previews = {
      web = {
        command = [
          "npm"
          "run"
          "dev"
          "--"
          "--port"
          "$PORT"
          "--host"
          "0.0.0.0"
        ];
        manager = "web";
      };
    };
  };
}
