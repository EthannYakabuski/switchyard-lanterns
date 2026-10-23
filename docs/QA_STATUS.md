# Android acceptance: SDK cleanup verified; EGL diagnostic open

Status on 2026-10-23: the focused normal-exit SDK resource cleanup passed native
verification. A separate emulator EGL shutdown error persists, so the full native
strict-log gate is NOT clean. Local packaging is verified through the receipt
below; publication/exact-source CI and owner/device acceptance remain pending.

## Pinned replacement artifacts

Runtime source: `a7d8f776c603eca86adbb7c0ace3d9ec24191f1c`.
Accepted export root: `build/first-pass-a7d8f776-loader-cleanup-001/`.

- Android `android/switchyard-lanterns-debug.apk`:199,784,516bytes; SHA256
  `49D9D95B776FCEF93423A7F1ED5F8BC124D599E547EF3E2EF4407BDB19D24BB7`.
- Web `web/index.html`: SHA256
  `7DC47A9852C35B8CD1619D12760E58A320C7C5BA52132B6DA274CFFEB0CE513E`.
  Keep all 29 verified Web bundle members and complete matching notices.

Both exports passed pinned-source/stable-input, strict-error and bundle gates.
Android 21 members / Web 29 members each include 20 license/support files. Android
warnings included scan-thread abort, Gradle path-check/URI and manifest warnings;
accepted does not mean warning-free. APK is debug/test, arm64-v8a + x86, not a
production-signed release. HTML identity alone does not cover its sibling files.

## Qualified local test packages

Local test package location: `build/first-pass-qualified-20261023/packages/`.
`LOCAL_PACKAGE_RECEIPT.json` identifies the verified archive hashes, exact audited
source-package commit, unchanged a7 runtime and member inventory. If absent,
packaging is incomplete.
Consult and verify that receipt rather than guessing a source commit or treating
another CI APK as the native-tested binary. Original C42 capture provenance and
prior artifacts remain preserved. Package completion does not pass the full
native strict-log gate, establish production/device acceptance or publish source.

## Fresh-guest actual normal exit

After user-assisted task-host recovery, all current genuine profiles were restored
exactly from verified backups. This is restoration across host restart, not
retention in a discarded transient session. On the restored fresh guest:

- a7 Home and normal Save and exit completed without System UI ANR.
- The application process exited normally.
- Retained SDK-resource warnings: 0. ObjectDB leak warnings: 0.
- The main save was byte-identical before/after exit, retaining 235 brass / 126 XP and
  the assisted yard 5 hint draft at step 0. No reward, claim or train movement was
  replayed to produce this observation.

This closes the previously observed five-SDK-script/ObjectDB warning for the
checked normal exit. It is actual native evidence, not only the lifetime fixture.
It does not establish every possible concurrent loaded-ad ownership scenario or
repeat all earlier gameplay/ad flows on a7.

A separate `eglCodecCommon` VAO 7 shutdown error persists even on Home-only exit.
It is independent of the now-zero SDK resource diagnostics. Read-only diagnosis
is continuing; no cause or fix is claimed. Do not suppress it, infer an audio
cause, or describe the full native strict-log gate as clean. Earlier ANRs occurred
before host recovery; they are not the current Home/exit result. No device
performance or broad stability claim follows from this short check.

## Earlier genuine gameplay and screenshot provenance

C42 source: `c42bbc4abd8f5c46c0fb06b6b7717a54fe0caeb5`; original CI APK SHA256
`F2274B8013A5165445BE0036B9C554A8CE5D6C29746B2CD892348E3237BC11D8`.
Separate genuine C42 observations:

- Same-build cold mid-route draft retained byte-identical data without restore.
- Yard 3 unassisted three-star delivery: 7 steps / 2 wagons, +55 brass / +33 XP; result close
  paid nothing further. Yard 4 three stars/1 wagon, +50 / +30, ending 235 / 126 with 4 clears
  and 6 wagons.
- Real test interstitial returned to neutral Resume; Resume/result close preserved
  the award.
- Unearned hint dismissal granted nothing. Separate actual earned hint saved
  behind the endcard while train stayed at step 0; dismissal required explicit
  Resume, and Back saved the assisted draft with no brass/XP change.
- Normal C42 exit saved but reported five retained SDK script resources/ObjectDB
  warning, motivating the now-tested lifetime cleanup. Its separate EGL message
  is not claimed cured by that fix.

Earlier E79 tutorial/level gift progress was genuinely earned then restored across
signer replacement. Earning, restoration and cold retention remain separate.
All 18 accepted unaltered screenshots retain C42/APK provenance in
`marketing/screenshots/MANIFEST.json`: six each logical phone/seven-inch/ten-inch,
not physical tablets or a7 images. Original display/rotation overrides are restored.

## Source checks, publication and remaining work

The Room-matched adapter changes pending-loader ownership, not vendor files,
gameplay, saves, audio, renderer or service IDs. Local 92 lifetime, 46 UI/lifecycle
and service checks passed with strict diagnostics. Earlier
[C42 CI 39870567054 passed](https://github.com/EthannYakabuski/switchyard-lanterns/actions/runs/39870567054):
577 model / all 48 solutions, 46 UI, 29 audio, services, exports/notices. The a7 public push
was denied before execution; public main remains C42 at last verification. Exact
a7/final-source public CI remains pending. Do not substitute the earlier CI result.

Next: verify that package receipt, then manually publish the audited intended
source/docs commit and verify exact-source CI. Retain the EGL qualification and
owner/device follow-up without weakening strict checks. Complete any justified regression if that investigation
requires a change. Verify the receipt before calling local packaging complete; neither that check
nor source CI establishes final native or production-ready acceptance. Physical-device behavior, audible output,
interactive Web, production services and actual disconnected-device play remain
unverified. Emulator audio is disabled. Min API 24 / target API 35 is the tested engine/export
constraint, not current Play eligibility. Owner service setup is documented in
`docs/PLATFORM_SETUP.md`; publication/signing/privacy/backend values remain owner
configuration. No public raw logs, private paths, profiles or process IDs belong
in this document or the package.

## GLES3 shutdown qualification

The observed `eglCodecCommon` VAO 7 diagnostic remains in the normal native exit log. Godot 4.5.1 contains a duplicated canvas-VAO deletion in its [GLES3 destructor](https://github.com/godotengine/godot/blob/4.5.1-stable/drivers/gles3/rasterizer_canvas_gles3.cpp#L2624-L2638), tracked [upstream](https://github.com/godotengine/godot/issues/121191). This strongly fits the emulator client-state message, but the numeric VAO owner was not mapped by a call stack. No engine, renderer, GPU setting or logging check was changed. The SDK retained-resource warning is separately verified resolved. The full native strict-log gate remains false.
