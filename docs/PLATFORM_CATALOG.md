# Switchyard Lanterns: service catalog

`game/catalog.json` is the source of truth. Enter production IDs only as values of the same symbolic keys in `platform/config.json`; never rename the keys to backend IDs. All committed values are blank and PGS is disabled.

## Achievements

| Key | Name | Description / score | Icon |
| --- | --- | --- | --- |
| first_dispatch | A Lantern Lit | Complete your first ordered delivery. (clears >= 1) | marketing/achievements/first_dispatch.png |
| full_consist | A Proper Little Train | Deliver a manifest containing at least three wagons. (largest_manifest >= 3) | marketing/achievements/full_consist.png |
| pine_certified | Pine Junction Keeper | Complete all eight Pine Junction yards. (district_0 >= 8) | marketing/achievements/pine_certified.png |
| orchard_certified | Orchard Branch Keeper | Complete all eight Orchard Branch yards. (district_1 >= 8) | marketing/achievements/orchard_certified.png |
| canal_certified | Canal Works Keeper | Complete all eight Canal Works yards. (district_2 >= 8) | marketing/achievements/canal_certified.png |
| quarry_certified | Quarry Loop Keeper | Complete all eight Quarry Loop yards. (district_3 >= 8) | marketing/achievements/quarry_certified.png |
| midnight_certified | Midnight Crossing Keeper | Complete all eight Midnight Crossing yards. (district_4 >= 8) | marketing/achievements/midnight_certified.png |
| grand_certified | Grand Dispatcher | Complete all eight Grand Dispatch yards. (district_5 >= 8) | marketing/achievements/grand_certified.png |
| clean_first | Polished Brass | Earn three mastery stars in one yard without a route hint. (perfect >= 1) | marketing/achievements/clean_first.png |
| clean_five | Five Bright Signals | Earn three mastery stars in five different yards. (perfect >= 5) | marketing/achievements/clean_five.png |
| clean_twenty | The Golden Timetable | Earn three mastery stars in twenty different yards. (perfect >= 20) | marketing/achievements/clean_twenty.png |
| cargo_25 | Freight Friend | Deliver 25 wagons. (cargo_total >= 25) | marketing/achievements/cargo_25.png |
| cargo_100 | Valley Supplier | Deliver 100 wagons. (cargo_total >= 100) | marketing/achievements/cargo_100.png |
| dispatch_25 | Reliable Rails | Complete 25 dispatches. (clears >= 25) | marketing/achievements/dispatch_25.png |
| dispatch_100 | Railway Regular | Complete 100 dispatches. (clears >= 100) | marketing/achievements/dispatch_100.png |
| daily_first | Morning Papers | Complete one Daily Dispatch. (daily_clears >= 1) | marketing/achievements/daily_first.png |
| daily_seven | Seven Days of Freight | Complete Daily Dispatches on seven different dates. (daily_clears >= 7) | marketing/achievements/daily_seven.png |
| level_five | Lantern Warden | Reach dispatcher level 5. (level >= 5) | marketing/achievements/level_five.png |
| level_ten | Valley Steward | Reach dispatcher level 10. (level >= 10) | marketing/achievements/level_ten.png |
| all_yards | Every Light Is Home | Complete all 100 authored campaign yards. (campaign_cleared >= 100) | marketing/achievements/all_yards.png |

## Leaderboards

| Key | Name | Description / score | Icon |
| --- | --- | --- | --- |
| campaign_stars | Lantern Mastery | Highest total of unassisted campaign mastery stars. (campaign_stars; higher is better) | marketing/leaderboards/campaign_stars.png |
| dispatches | Valley Dispatches | Total genuine completed dispatches. (clears; higher is better) | marketing/leaderboards/dispatches.png |
| dispatcher_xp | Dispatcher Experience | Lifetime dispatcher experience earned through play. (xp; higher is better) | marketing/leaderboards/dispatcher_xp.png |
