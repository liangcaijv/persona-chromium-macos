# persona-chromium-macos

macOS build tree for a fingerprint-controllable Chromium used by the
`persona-profiles` project. It is a fork of
[ungoogled-chromium-macos](https://github.com/ungoogled-software/ungoogled-chromium-macos)
with the fingerprint patch set from
[pocchian/fingerprint-chromium-macos-x86_64](https://github.com/pocchian/fingerprint-chromium-macos-x86_64)
(originating from [adryfish/fingerprint-chromium](https://github.com/adryfish/fingerprint-chromium))
plus this repository's own patches (numbered from 019). See
`patches/extra/fingerprint/SOURCE.md` for provenance and hashes. The patches
are source-level and architecture independent.

Branches are named `fp-<chromium version>`; one branch serves both arm64 and
x86_64. The default branch is upstream's and is not used for builds.

## Build (local, the primary path)

Same requirements as upstream's README: Xcode 26 (opened once, license
accepted, `xcodebuild -downloadComponent MetalToolchain`), Homebrew
`python@3.13 ninja coreutils readline node`, `pip3 install PySocks httplib2`.
Python must be 3.13 or older for depot_tools.

```sh
git clone --recurse-submodules -b fp-<version> https://github.com/liangcaijv/persona-chromium-macos.git
cd persona-chromium-macos
export PATH="/opt/homebrew/opt/python@3.13/libexec/bin:$PATH"
MACOS_AD_HOC_SIGNING=1 ./build.sh arm64     # about 3-5 h on an M1 Max; dmg lands in build/
MACOS_AD_HOC_SIGNING=1 ./build.sh x86_64    # cross-build on Apple silicon
```

If only signing or packaging failed, rerun `MACOS_AD_HOC_SIGNING=1 ./sign_and_package_app.sh`.

## Build (GitHub Actions, optional)

Actions → "Build persona-chromium macOS binaries" → Run workflow on the
`fp-…` branch and choose the architecture. The upstream chained workflow
splits the build into ≤5 h jobs. Free hosted arm64 runners (`macos-15`) have
3 vCPUs and 7 GB and are not verified to finish; the Intel runner path
(`macos-15-intel`) took about 37 h in an upstream-style run.

## Release

Done from the build machine after `build.sh` finishes:

```sh
gh release create kernel-<version> release/*.dmg release/*.hashes.md \
  --target fp-<version> --title "kernel-<version>" --notes-file release/release-notes.md
```

Rebuilds of the same version get a `-r2`, `-r3` … suffix on the tag.

## Updating to a new Chromium version

```sh
git fetch upstream --tags
git checkout -b fp-<new> <new upstream tag>
git submodule update --init
git checkout fp-<old> -- patches/extra/fingerprint devutils/import_fingerprint_patches.sh \
  .github/workflows/build.yml .github/scripts/github_prepare_artifacts.sh README.md
# re-append the fingerprint entries to patches/series, then:
./devutils/check_patch_files.sh
```

If a patch no longer applies, `build.sh` fails within the first hour while
applying patches; fix the patch and rerun.

## Signing

Builds are ad-hoc signed and not notarized. Clear quarantine before first
launch: `xattr -cr Chromium.app`.

## License

BSD-3-Clause for this repository's scripts and patches; Chromium and
ungoogled-chromium carry their own licenses.
