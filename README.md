# Switchyard Lanterns

**Round Four source:** [100-yard campaign, observer L/R, energy and advertising rules](docs/ROUND_FOUR.md). Source tests do not replace the pending affected native/build validation.

A cozy 3D freight-routing puzzle made with Godot 4.5.1 Compatibility. Set the
points, collect each manifest in order, and bring the little train home through
lantern-lit valley yards.

**Development status:** Round Four source tests verify all 100 solutions,
energy/save/callback rules and affected scene layout. Fresh Round Four native
gameplay, screenshots where visuals changed, build packages and exact-commit
hosted CI remain delivery gates. The earlier qualified cleanup/source delivery
was published at `d68547fe` and exact CI
[39922117656](https://github.com/EthannYakabuski/switchyard-lanterns/actions/runs/39922117656)
passed; that run does not validate this later gameplay update.

Historical qualified test packages remain at
`build/first-pass-qualified-20261023/packages/`, with exact source/runtime hashes
in `LOCAL_PACKAGE_RECEIPT.json`. They and the 18 genuine accepted screenshots
retain their older provenance. Normal earlier cleanup exit had no retained SDK
resources/ObjectDB warnings, while a separate Godot GLES3/emulator shutdown
diagnostic and physical/production acceptance remain qualified. See
[HANDOFF.txt](HANDOFF.txt), [acceptance details](docs/QA_STATUS.md) and
[screenshot provenance](marketing/screenshots/MANIFEST.json).

- 100 fixed authored yards across thirteen districts, with stored solutions tested by
  the same simulator used for Preview and actual train movement.
- Untimed planning; L/R indicate screen-left/right from your viewpoint. Tap a numbered lantern
  or its large bottom chip. Dispatch, Pause, Step, Preview, free Undo and Reset
  remain free within the same paid ticket. Signed bridges count already-coupled wagons.
  Train view provides a readable close view; Fit yard restores the whole route.
- Saved energy (12 capacity, 2 per new ticket; 1 per five minutes offline, 1 per
  completed puzzle and 3 per new level), repeatable native-earned full refills,
  and an interstitial opportunity every fifth completion. Dispatcher XP with a 25-brass gift for every newly earned level, cosmetic
  engine liveries, campaign mastery, a curated Daily
  Dispatch, daily freight goals and a seven-day login post.
- Original district music, sound effects, actual licensed Kenney train/scenery
  scenes, illustrated marketing artwork, and a local 20-achievement journal.
- Google Play Games and AdMob adapters with test configuration. Local offline
  progress remains playable when native services are unavailable.

Open `project.godot` in Godot **4.5.1**. Android is primary; Web is supported where
feasible. No Windows distribution is planned. Current tested export constraints
are min API 24 / target API 35, which do not establish current Play eligibility.

Start development with [AGENTS.md](AGENTS.md), the [design](docs/DESIGN.md),
[content/model guide](game/CONTENT.md), and [platform setup](docs/PLATFORM_SETUP.md).
Achievement and leaderboard names, criteria and icon paths are in
`game/catalog.json` and [the platform mapping](docs/PLATFORM_CATALOG.md).
Production IDs, consent/store declarations, signing and real-device validation
remain owner setup. AdMob's manifest App ID is a `project.godot` setting separate
from JSON metadata; a `test_mode` label does not turn production units into test
requests. The plugin's registered demo default may be omitted from serialized
project settings; verify the effective setting and exported manifest when changing
to production.

After a normal import, run `tests/test_rail_model.gd`, `tests/test_ui.gd`,
`tests/test_audio_assets.gd`, `tests/test_round_four.gd`, `tests/test_ad_load_lifetime.gd`, and
`platform/tests/services_smoke.gd` with `--headless --path . --script <path>` in
isolated test data directories. Never run fixtures against a genuine profile.
The hosted workflow performs isolated checks and preserves strict errors/leak
diagnostics. Native gameplay and genuine ad callbacks require separate testing.
The platform smoke fixture checks service contracts and local fallbacks; it does
not prove a production sign-in, real ad callback, consent result or native SDK flow.

Original code is Apache 2.0; see [LICENSE](LICENSE). Preserve `NOTICE`, all
`LICENSES`, and asset/plugin notices with redistributions. Build outputs, private
profiles, raw QA, signing material and backups are local artifacts, not source.
