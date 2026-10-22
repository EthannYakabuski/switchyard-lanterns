# Authored railway content

`boards.json` is the campaign source of truth: 48 fixed yards in six districts,
eight per district. There is no random campaign generator at runtime. Each yard
contains its actual node positions, directed track connections, cargo sequence,
opening points, stored solution switches, expected solution trace and par steps.
The branch routes include distinct merges, buffers, sidings and early station
connections. `RailModel` alone decides both preview and actual dispatch results;
the diorama animates the exact emitted edge and coupling events.

From Canal Mail onward, 24 yards include 29 signed capacity bridges. MAX counts
wagons already coupled at entry, excluding the engine. Some equal-cargo branches
are distinguished by their actual load limits; the first such yard teaches this
before dispatch. The simulator rejects overloaded entry and retains free Undo
and Reset. There is no multi-train collision simulation.

Editing a yard requires updating its real graph and solving it through that same
model. The mandatory `tests/test_rail_model.gd` checks every complete stored
solution, trace, order, preview immutability and a full-state fingerprint against
the other 47 yards. A passing source fixture is not a native-play claim.

The camera fits the projected rail, train and label envelope of its actual live
viewport, rather than an oversized floor. Train/Fit controls retain an optional
close view for longer yards. Numbered turnouts have matching large bottom chips
and projected world touch targets. The supplied train models face +Z. All rails
use the same actual one-metre Kenney track scene batched along the exact baked
movement curve, with continuous steel strips across graph-node joins; there is
no mixed imported-straight-root offset convention. Scenery uses actual model
units, with readable tree/depot scales and a coherent dusk lighting palette.
This is an ordered routing puzzle, not a freeform reversing, uncoupling or
railway-physics simulation. The Home hero is explicitly brand illustration;
actual yards, trains, gameplay and captured results remain real 3D scenes.

`catalog.json` supplies the stable 20 achievement and three leaderboard keys,
human-readable names/criteria and distinct marketing icon paths. Backend values
belong in the documented platform configuration, never this catalog. Local
progression works without native services. Campaign efficiency records exclude
earned route hints, while ordinary campaign completion remains available.

Gameplay saves use `user://railway_v1.json` with a versioned integer schema,
verified atomic staging and the previous verified `.bak`. Unreadable originals
are kept privately under a digest-suffixed `.unreadable-…` filename. Never track
or publish those profiles. Awards, login post, daily freight goals and new run IDs
roll back on failed writes. A 25-brass level gift is included in that same
transaction for each newly crossed XP level, with no retroactive profile award
or extra save-schema field. The result UI offers Retry save before continuing.
Validated drafts retain recent free Undo history across cold reloads; Undo
cannot remove an earned hint's assisted flag from that run.
Actual pending native-ad input and earned callbacks stay paused through the
endcard/dismissal and require an explicit Resume action afterward.

Selected Kenney train, Nature Kit, City Kit Industrial, Modular Buildings and UI
Pack assets are inventoried under `assets/kenney/manifest.json`; their complete
CC0 notices are in `LICENSES/Assets`. Actual art/audio provenance lives in the
separate art/audio documentation. Native builds, captures and final handoff
acceptance are recorded by the coordinator, separately from these source tests.
