# Round Four gameplay update

This source update expands the railway to **100 fixed yards in thirteen
districts**. The original 48 yard dictionaries and their stored solutions are
unchanged. Yards 49–100 add Copper Viaduct, Juniper Summit, Amber Foundry,
Moonwater Sidings, Highland Mail, Aurora Exchange and the four-yard Lantern
Crown finale. The new route graphs progress from seven to eleven turnouts,
with ordered/multi-wagon sidings, cross-yard bypasses, loops and signed capacity
bridges. Each JSON graph contains its actual solution, trace and par; the same
RailModel used in play verifies it. New district palettes reuse suitable existing
licensed scenery and original district music; no new music recordings are claimed.

## Direction and presentation

Turnout chips, world labels and earned hints say **L/R** for screen-left/right
from the player's fixed camera perspective, independent of train heading.
Labels compare the real projected fork directions; swapping branch indices
does not swap their meaning. Long manifests and turnout rows scroll horizontally.
The Home page uses a dedicated portrait dusk-valley illustration with readable
opaque controls. This branding illustration is not a gameplay screenshot.

## Energy and advertising

- Capacity 12; starting a new campaign/daily/replay ticket costs 2.
- Continue an already paid saved route, Pause, Preview, Step, Undo and Reset
  cost nothing. Reset reuses the ticket and preserves its assisted status.
- A once-only successful delivery restores 1; each newly earned dispatcher
  level restores 3 in the same durable transaction as XP/coins.
- Restore 1 every five completed minutes, including time away. Partial intervals
  persist and regeneration stops at capacity. Backward clock changes issue no
  new energy. Local-clock progression is not server-authoritative.
- Home offers an optional native rewarded full refill. There is no daily watch
  cap: each request receives a persisted new serial. Only its actual earned
  callback can refill; unearned, stale and repeated callbacks cannot grant.
  Web/unavailable service paths never simulate a reward. Pending/endcard/
  dismissal stay gated until an explicit neutral Resume.
- The existing measured Home banner remains outside content in its safe bottom
  reserve. Interstitial eligibility occurs after **every fifth durably completed
  puzzle**, using the persisted clear count across launches. No extra timed cap
  is added; actual display still requires an available SDK ad.

Version1 genuine profiles migrate by adding a full energy balance and request
receipts while retaining existing currency, XP, drafts, progression and settings.
Malformed partial energy fields are rejected rather than silently replenished.
The new paid ticket and initial resumable draft share one atomic save; no second write can strand a charged load. Atomic-save failure rolls back ticket cost, grants and callback receipts. No
retroactive currency or XP grants are added.

## Evidence and pending validation

Run isolated `tests/test_round_four.gd` in addition to the existing model/UI,
audio, SDK lifetime and service suites. Fixtures cover offline/rollback time,
legacy migration, atomic failures, cold callback idempotence, all 52 actual new
solutions, geometric L/R and the live scene's paid ticket/Reset/long-yard layout.
Synthetic callback fixtures are not native AdMob evidence.

At this source checkpoint the Round Four native build/affected gameplay,
actual earned energy refill, fifth-completion ad, phone/tablet visual captures
and final package/exact-commit hosted CI remain coordinator delivery gates.
Existing accepted screenshots and APKs retain their original older provenance.
Physical-device, audible output, interactive Web, production services and
store-release acceptance require their own evidence. Existing strict native-log
qualifications are not cleared by these source tests.

## Focused music pause-state follow-up / qualified verification

Music remains enabled. The focused follow-up avoids redundant pause-state assignments while leaving the gameplay and service rules above intact. Its source is `1c00d2b892bebf916c5e1400d7ecad69440dfb24`; its [exact hosted CI](https://github.com/EthannYakabuski/switchyard-lanterns/actions/runs/40146600612) passed. The actual accepted AAB/Web003 components and qualified test package are recorded in `../HANDOFF.txt`. Earlier named-source tests and frozen exports do not establish this follow-up's runtime acceptance.

Corrected Web runtime findings: Bounded isolated Chrome Web003 observations: Campaign and the first yard opened. The point control toggled observer-left/right; free Reset restored the opening points without spending more energy. Home/Continue restored the same draft without another energy charge. Real Dispatch completed the first yard with three stars, one wagon, +50 brass, +30 XP and +1 energy. No createBuffer recurrence was recorded during the 361-second check. Full original audio and project playback configuration were retained.
Remaining browser and platform limits: Only the first yard was completed; all 100 boards and 13 districts were not played. Missing symbol glyphs remain in locked-star text/toasts; the principal controls and result stars were readable. Headless tab changes kept both pages visible and focused; actual hidden/focus-loss and music pause/resume transitions remain unverified. These are bounded Chrome Web003 observations, not Android screenshots or native/device, audible-output, SDK/ad, production-service or release acceptance. No cold browser restart was tested.

Affected Android/native checks, real SDK callbacks and current-build Android screenshots remain unverified. Physical-device play, audible-output and production services are separate acceptance work. Preserve all old APK/capture provenance and full third-party notices.
