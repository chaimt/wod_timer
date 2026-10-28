# WOD Timer

Connect IQ watch app modeled on the [SmartWOD Timer](https://play.google.com/store/apps/details?id=net.smartwod.timer)
phone app: timers for the common functional-fitness / cross-training workouts,
with a round counter, sound and vibration cues and a workout log. Every WOD
can also be recorded as a Garmin **HIIT** activity (AMRAP / EMOM / Tabata
sub-sport, one lap per round) that syncs to Garmin Connect.

## Timers

| Type | Settings | Behavior |
|------|----------|----------|
| **AMRAP** | Time (default 20:00) | Counts down; tap / LAP adds a round. |
| **For Time** | Time cap (default none) | Counts up until you stop it, or until the cap; tap / LAP adds a round. |
| **EMOM** | Total time, interval (default 10:00 every 1:00) | Counts down each interval and beeps at every new one. A shorter final interval counts as a round. |
| **Tabata** | Work, rest, rounds (default 20 s / 10 s x 8) | Alternates WORK (green) and REST (red); no rest after the last round. |

Each WOD remembers its last-used settings. A get-ready countdown (default 10 s)
runs before the workout.

## Controls (button watches, e.g. Forerunner 965)

| Button | Before start | Running | Paused / done |
|--------|--------------|---------|---------------|
| START | start | pause | resume / open Save menu |
| BACK (LAP) | leave | +1 round (AMRAP, For Time); otherwise pause + menu | Resume / Save / Discard menu |
| Tap screen | start | +1 round (AMRAP, For Time) | menu |
| Hold UP (menu) | – | pause + menu | menu |

Discard needs a second press. If the app is closed mid-workout, the workout is
saved rather than lost.

## Screens

- **Timer**: phase label (GET READY / WORK / REST / DONE), a large clock, the
  round counter (`ROUND 3/8` or `ROUNDS 5`), a secondary clock (total time
  left / elapsed / cap), live heart rate, and a bezel ring showing progress
  through the phase in the phase's color. For an uncapped For Time, the ring
  sweeps once per minute.
- **Cues**: 3-2-1 ticks before every phase change, a high tone and vibration
  for work, a low tone for rest, and a rising jingle at the finish. Phase
  changes also wake the display.
- **Workout Log**: the last 50 saved WODs (result, time, plan, date). Clearing
  the log needs a second press.
- **Settings** (on the watch or in the Connect IQ phone app): countdown
  length, sounds, vibration, and whether to record a Garmin Connect activity.

## Layout

```
source/
  WodApp.mc            entry point; saves an in-progress WOD on exit
  WodFormat.mc         enums + pure formatting ("12:34", "AMRAP", dates)
  WodConfig.mc         per-type settings, editable field specs, persistence
  WodEngine.mc         pure state machine: elapsed ms -> phase / round / progress
  WodSession.mc        start/pause/resume, cues, laps, FIT recording, logging
  Alerts.mc            tones, vibration, display wake
  Settings.mc          typed access to properties.xml
  WorkoutLog.mc        Storage-backed log + pure labels
  TimerView.mc         workout screen        TimerDelegate.mc  workout controls
  MainMenu.mc          home menu             SetupMenu.mc      per-WOD setup
  ValuePicker.mc       numeric field editor  FinishMenu.mc     Resume / Save / Discard
  LogMenu.mc           log list + result screen
  SettingsMenu.mc      on-watch settings
  *Test.mc             unit tests (Run No Evil)
resources/             strings, settings, launcher icon
tools/gen_icon.py      regenerates the launcher icon (stdlib only)
scripts/               build / test / simulator / USB deploy
```

All geometry is fractional, so one layout covers the 260 px MIP and the
360–454 px AMOLED round watches listed in `manifest.xml`.

## Build and run

You need the Connect IQ SDK and a `developer_key` in the project root
(git-ignored, never committed).

```bash
task build              # debug .prg for the first manifest device (fr965)
task package            # store .iq for every manifest device -> bin/wodtimer.iq
task test               # unit tests in the simulator (start it first)
task deploy-simulator   # build + launch simulator + run
task deploy-watch       # copy to a USB-connected watch (needs libmtp)
task icon               # regenerate the launcher icon
```

Upload `bin/wodtimer.iq` at https://apps.garmin.com/en-US/developer/upload.
