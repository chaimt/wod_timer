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
task test               # unit tests in the simulator (start it first)
task deploy-simulator   # build + launch simulator + run
task deploy-watch       # copy to a USB-connected watch (needs libmtp)
task icon               # regenerate the launcher icon
```

Store package: `monkeyc -e -r -f monkey.jungle -o bin/wodtimer.iq -y developer_key`.

## Connect IQ Store description

Paste into the store listing (2440 of 4000 characters):

```text
WOD Timer is a simple, no-nonsense workout timer for cross-training, functional fitness, HIIT and circuits. Choose the WOD type, set the time and press START.

TIMERS
• AMRAP – As Many Rounds As Possible. Set a time (default 20:00) and the clock counts down. Tap the screen or press LAP to count each round.
• FOR TIME – Do the work as fast as possible while the clock counts up. Add an optional time cap, or leave it open and stop the clock when you finish. Tap or press LAP to count rounds.
• EMOM – Every Minute On the Minute. Set the total time and the interval length (for example 10 x 1:00, or every 1:30). A new interval starts with a beep and vibration, and the screen shows the current round and the total time left.
• TABATA / HIIT – Set work time, rest time and rounds (default 20 s work / 10 s rest x 8). WORK shows in green, REST in red, and there is no wasted rest after the last round.

BIG, CLEAR DISPLAY
• Huge clock you can read mid-burpee
• Phase shown in color: GET READY, WORK, REST, DONE
• Progress ring around the bezel for the current interval
• Round counter (ROUND 3/8 or ROUNDS 5)
• Total time left or elapsed, plus live heart rate

SOUNDS AND VIBRATION
• Get-ready countdown before the workout starts (0–30 s, default 10 s)
• 3-2-1 beeps before every phase change
• Distinct tones for work, rest and the finish
• The screen wakes up at every phase change
• Sounds and vibration can each be turned on or off

WORKOUT LOG
• Every saved WOD is logged on the watch: type, result (time or rounds), plan and date
• Keeps your last 50 workouts
• Each timer remembers the settings you used last

GARMIN CONNECT
Optionally record each workout as a Garmin HIIT activity (AMRAP, EMOM or Tabata sub-sport) with heart rate and calories. Each round is saved as a lap, so you get a per-round split table in Garmin Connect. Recording can be turned off in Settings.

CONTROLS
• START – start, pause and resume
• BACK / LAP – count a round (AMRAP and For Time); in other modes it pauses and opens the menu
• Tap the screen – count a round
• Pause, then choose Resume, Save or Discard
Workouts in progress are saved if the app is closed, so you never lose a WOD.

SETTINGS
Change the get-ready countdown, sounds, vibration and activity recording on the watch or in the Connect IQ app on your phone.

Built for functional fitness, cross-training WODs, metcons, HIIT, interval training, weightlifting, circuits and running intervals.
```
