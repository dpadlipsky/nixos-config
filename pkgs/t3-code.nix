{ fetchurl, symlinkJoin, makeDesktopItem, makeWrapper, appimageTools, codex }:

let
  t3Source = fetchurl {
    url = "https://github.com/pingdotgg/t3code/releases/download/v0.0.40/T3-Code-0.0.40-x86_64.AppImage";
    hash = "sha256-i/X9RMt/rQxDGR1U/v35dKgifVBQXsuKvPdjJiCfJko=";
  };

  t3Contents = appimageTools.extract {
    pname = "t3code-desktop";
    version = "0.0.40";
    src = t3Source;
  };

  t3Desktop = appimageTools.wrapType2 {
    pname = "t3code-desktop";
    version = "0.0.40";
    src = t3Source;
    extraPkgs = p: [ codex p.git p.nodejs_24 ];
    profile = ''
      export PATH="${codex}/bin:$PATH"
    '';
  };
in
symlinkJoin {
  name = "t3code-0.0.40";
  nativeBuildInputs = [ makeWrapper ];
  paths = [
    t3Desktop
    (makeDesktopItem {
      name = "t3code";
      desktopName = "T3 Code";
      comment = "T3 Code desktop app";
      exec = "t3code-desktop %U";
      icon = "t3code";
      terminal = false;
      categories = [ "Development" ];
      startupWMClass = "t3code";
      mimeTypes = [ "x-scheme-handler/t3code" "x-scheme-handler/t3code-dev" ];
    })
  ];
  postBuild = ''
    # T3 regenerates its OAuth URL handler on startup using APPIMAGE, falling
    # back to the extracted Electron binary when unset. Route callbacks through
    # the Nix FHS launcher so they have the same runtime as the original app.
    wrapProgram $out/bin/t3code-desktop \
      --set APPIMAGE "$out/bin/t3code-desktop" \
      --set T3CODE_DISABLE_AUTO_UPDATE 1
    install -Dm644 ${t3Contents}/t3code.png $out/share/icons/hicolor/512x512/apps/t3code.png
  '';
}
