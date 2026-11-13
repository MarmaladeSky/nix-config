{
  nix-apple-dev,
  stdenv,
  fetchpatch,
}:
let
  inherit (nix-apple-dev.packages.${stdenv.hostPlatform.system}) apple-dev xtool;

  upstreamCommit =
    rev: hash:
    fetchpatch {
      url = "https://github.com/xtool-org/xtool/commit/${rev}.patch";
      excludes = [
        "Package.swift"
        "Package.resolved"
      ];
      inherit hash;
    };

  # Apple rejects the Apple ID login of xtool 1.20.1 with -80045
  # (xtool-org/xtool#329, #378); these are the fixes released in 1.22.2-1.24.0.
  xtoolWithLoginFixes = xtool.overrideAttrs (old: {
    patches = old.patches ++ [
      (upstreamCommit "fae19812754f115be4f96b48e2eae8ec1f821ef9" "sha256-/4xlEwQeUsS83YNES7bZzJqrJe5FzzKbuzlzY6Ux4DI=")
      (upstreamCommit "65bf3cc5a1240fea53ac0748d29a01878222a6ce" "sha256-ka1JlOzmzMNSD8FLd9ZsuhfTc89KYB92ilxTt9fgEok=")
      (upstreamCommit "2afd5307a4097ee5151d0765a9e0adb5241906d7" "sha256-//krolK7adg73vypE2+Y1ji54krlzik5gQ1omC63n40=")
      (upstreamCommit "8c46156e27fcd5874acfa3725b29defdee809184" "sha256-F7qqK7dMj+ecTisvBb59dLSBhffXeQRu7OoXtyFTXhQ=")
      (upstreamCommit "e3ce2c402ec142d0d1bd0a0c9a20eb9c2ae8827c" "sha256-tFWvLto2yunO+HTssny/cD1mhPbH2vpWvrkU3pyj++Q=")
      (upstreamCommit "70e1568fdfcb20b560774057cd783f02361293b9" "sha256-3GWwE20G2bqjnW7QOtuyGPYw8saUapeWhYy0UGDmcmI=")
    ];
  });
in
apple-dev.override {
  tools = map (tool: if tool == xtool then xtoolWithLoginFixes else tool) apple-dev.tools;
}
