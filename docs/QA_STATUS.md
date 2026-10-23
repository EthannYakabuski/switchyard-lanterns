# Android acceptance status

Status on 2026-10-23: final delivery is in progress. A native shutdown diagnostic
remains open; source CI success is not a claim that every native gate passed.

## Tested build

Gameplay source: `c42bbc4abd8f5c46c0fb06b6b7717a54fe0caeb5`.
[Exact-source CI passed](https://github.com/EthannYakabuski/switchyard-lanterns/actions/runs/39870567054):
577 model checks including all 48 authored solutions, 46 UI/lifecycle checks,
29 audio checks, platform contracts, Android/Web exports and notices. The Android
export included a scan-thread warning. Strict resource/error checks remain enabled.

Tested CI debug APK: `build/first-pass-ci-c42bbc4a-run39870567054/android/game-debug.apk`.
SHA256: `F2274B8013A5165445BE0036B9C554A8CE5D6C29746B2CD892348E3237BC11D8`.
The final source/docs commit may differ from this tested gameplay build.

## Genuine native observations

- A mid-route draft survived a cold launch of this same APK with byte-identical
  profile data at the checked point. No restoration was used for that cold check.
- The first non-tutorial ordered delivery completed unassisted with three stars,
  seven steps and two wagons. It added 55 brass/33 XP, taking the genuine bank
  from 130/63 to 185/96. Closing the result added nothing further.
- The next yard completed with three stars and one wagon, adding 50 brass/30 XP
  for 235 brass/126 XP, four total clears and six wagons. Its real test
  interstitial returned to a neutral Resume prompt. Resume and result close
  left the saved award unchanged.
- One real rewarded-hint dismissal was unearned and granted nothing. A separate
  completion attempt received the native earned event and saved an assisted hint.
  The train stayed at step zero behind the endcard and after dismissal, with no
  brass/XP change. Explicit neutral Resume was required; Back saved that draft.
- Android Back exposed the normal exit confirmation. Save and exit returned to
  the Android launcher and preserved the genuine profile. However, its shutdown
  log reported five resources still in use and an ObjectDB leak warning. Verbose review identified retained interstitial/rewarded AdMob loader and
  callback scripts, plus MobileSingletonPlugin. A focused ownership cleanup is
  under review. A separate emulator EGL vertex-array diagnostic occurred at
  shutdown; it is recorded separately from those SDK resources.

The earlier tutorial progress and level-2 gift were genuinely earned on the E79
predecessor build. Its 130-brass/63-XP profile was restored exactly when the debug
signer changed. This is restoration across that replacement, separately from the
same-C42 cold-retention evidence; no progression or reward was manufactured.

## Screenshots and remaining limits

`marketing/screenshots/` has six unaltered real views per phone, seven-inch and
ten-inch logical emulator profile: Home, campaign, planned yard, cargo play,
genuine result and progression. The manifest records actual pixel hashes and
source/APK provenance. These are display profiles, not physical tablet tests.
The task display overrides were restored after captures.

Physical-device behavior, audible balance/looping, interactive Web play,
production services and an actual disconnected-device session remain unverified.
The emulator has audio output disabled. Imported loop metadata and source
fixtures do not establish audible output or native offline behavior. Production
IDs, signing, consent/privacy declarations and Google Play publication remain
owner work. Min API 24/target API 35 are tested engine export constraints, not a
release-eligibility assertion.

Finish the shutdown investigation, relevant native regression, final archives,
handoff, audited publication and exact-commit CI before issuing final readiness.
