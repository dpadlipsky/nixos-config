{ lib, stdenv, fetchurl, autoPatchelfHook }:

stdenv.mkDerivation {
  pname = "antigravity-cli";
  version = "1.1.27";

  src = fetchurl {
    url = "https://storage.googleapis.com/antigravity-public/antigravity-cli/1.1.27-5211191891591168/linux-x64/cli_linux_x64.tar.gz";
    sha512 = "793d4b9ea2c08d9a7e50bafa02cfc8c19424bd60d6e83f91408d45f9c6d4ce79a5d576fede5bef164d823abf84f81359a14b4ca665952c47b0a7cfd743bb69c0";
  };

  nativeBuildInputs = [ autoPatchelfHook ];
  sourceRoot = ".";
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    install -Dm755 antigravity $out/bin/agy
    runHook postInstall
  '';

  meta = {
    description = "Google Antigravity command-line coding agent";
    homepage = "https://antigravity.google/product/antigravity-cli";
    license = lib.licenses.unfree;
    platforms = [ "x86_64-linux" ];
    mainProgram = "agy";
  };
}
