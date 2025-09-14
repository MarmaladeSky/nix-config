{
  lib,
  desktop-file-utils,
  fetchFromGitHub,
  gobject-introspection,
  gtk3,
  libpwquality,
  meson,
  ninja,
  pkg-config,
  python313Packages,
  shared-mime-info,
  wrapGAppsHook3,
}:

python313Packages.buildPythonApplication rec {
  pname = "revelation";
  version = "0.5.5";

  src = fetchFromGitHub {
    owner = "mikelolasagasti";
    repo = "revelation";
    rev = "revelation-${version}";
    hash = "sha256-J3H0qm/zh0WaJ90oIYbbVh/+d5u0ye5nAJw3LUfJkR4=";
  };

  format = "other";

  nativeBuildInputs = [
    desktop-file-utils
    gobject-introspection
    meson
    ninja
    pkg-config
    shared-mime-info
    wrapGAppsHook3
  ];

  buildInputs = [
    gobject-introspection
    gtk3
  ];

  propagatedBuildInputs = with python313Packages; [
    defusedxml
    pycairo
    pycryptodomex
    pygobject3
    python313Packages.libpwquality
  ];

  meta = with lib; {
    description = "Revelation password manager for the GNOME desktop";
    homepage = "https://revelation.olasagasti.info";
    license = licenses.gpl2Only;
    platforms = platforms.linux;
    mainProgram = "revelation";
  };
}
