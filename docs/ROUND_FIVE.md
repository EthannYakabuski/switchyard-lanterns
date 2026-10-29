# Round Five energy sources

The recurring flat +1 energy per completed puzzle is removed. A completed puzzle may still earn XP and thereby a real dispatcher promotion; each new level grants the existing +3 energy. Daily login/freight claims grant no direct energy, though their XP may also cause a promotion. Timed and offline recovery now uses 600-second intervals, twice the prior wait, with the existing12-energy cap. New tickets cost2; current-ticket retries, Continue, Undo and Reset stay free. The existing native-earned callback can refill to capacity, with its durable request/settlement serial preventing duplicate grants.

Existing saved energy, timestamps, records, coins, XP, daily claims and callback receipts retain their schema and are not reset. The new interval applies to future recovery calculations; clock rollback grants nothing.

Acceptance source tests: tests/test_round_five.gd covers result-without-promotion, allowed promotions, daily sources, recharge boundaries/offline/cap, earned/unearned/duplicate handlers and cold persistence. Existing Round Four migration/save-failure, model, UI and service tests remain applicable. Tests use isolated fixtures, not a real rewarded ad or production account; affected native/device, Web gameplay and audible validation remain separate. Current result/commit/CI will be recorded in the private Round Five receipt.
