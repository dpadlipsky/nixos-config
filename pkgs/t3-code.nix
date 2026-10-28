{ lib, fetchurl, symlinkJoin, makeDesktopItem, makeWrapper, appimageTools, codex }:

let
  # Pinned by t3code-update (packages/updaters).
  pin = lib.importJSON ./t3-code.json;
  inherit (pin) version;

  t3Source = fetchurl pin.sources.appimage;

  t3Contents = appimageTools.extract {
    pname = "t3code-desktop";
    inherit version;
    src = t3Source;
  };

  t3Desktop = appimageTools.wrapType2 {
    pname = "t3code-desktop";
    inherit version;
    src = t3Source;
    extraPkgs = p: [ codex p.git p.nodejs_24 ];
    profile = ''
      export PATH="${codex}/bin:$PATH"
    '';
  };
in
symlinkJoin {
  name = "t3code-${version}";
  nativeBuildInputs = [ makeWrapper ];
  paths = [
    t3Desktop
    (makeDesktopItem {
      name = "t3code";
      desktopName = "T3 Code (Nightly)";
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
    # Claude's sdk-* entrypoints drain the 5h usage window faster; label T3's
    # Claude sessions with a custom name (pingdotgg/t3code#25597).
    wrapProgram $out/bin/t3code-desktop \
      --set APPIMAGE "$out/bin/t3code-desktop" \
      --set T3CODE_DISABLE_AUTO_UPDATE 1 \
      --set CLAUDE_CODE_ENTRYPOINT t3-code
    install -Dm644 ${t3Contents}/t3code.png $out/share/icons/hicolor/512x512/apps/t3code.png
  '';
}
