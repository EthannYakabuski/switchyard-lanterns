# Switchyard Lanterns

A cozy 3D freight-routing puzzle made with Godot 4.5.1 Compatibility. Set the
points, collect each manifest in order, and bring the little train home through
lantern-lit valley yards.

**Development status:** gameplay source is implemented. The revised presentation
and level-up gifts passed 577 model, 46 UI/lifecycle, 29 audio and platform service
checks with no strict diagnostics or warnings. Earlier hosted Linux CI also
verified mixer-aware test teardown. The corrective APK and genuine Android
visual/play acceptance remain pending, along with final packages and six
screenshots per device profile; source fixtures do not establish native results.

- 48 fixed authored yards across six districts, with stored solutions tested by
  the same simulator used for Preview and actual train movement.
- Untimed planning; A is the left siding and B the right. Tap a numbered lantern
  or its large bottom chip. Dispatch, Pause, Step, Preview, free Undo and Reset
  remain available without ads. Signed bridges count already-coupled wagons.
  Train view provides a readable close view; Fit yard restores the whole route.
- Dispatcher XP with a 25-brass gift for every newly earned level, cosmetic
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
`tests/test_audio_assets.gd`, and
`platform/tests/services_smoke.gd` with `--headless --path . --script <path>` in
isolated test data directories. Never run fixtures against a genuine profile.
The hosted workflow performs isolated checks and preserves strict errors/leak
diagnostics. Native gameplay and genuine ad callbacks require separate testing.
The platform smoke fixture checks service contracts and local fallbacks; it does
not prove a production sign-in, real ad callback, consent result or native SDK flow.

Original code is Apache 2.0; see [LICENSE](LICENSE). Preserve `NOTICE`, all
`LICENSES`, and asset/plugin notices with redistributions. Build outputs, private
profiles, raw QA, signing material and backups are local artifacts, not source.
