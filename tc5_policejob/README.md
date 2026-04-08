# tc5_policejob

Police job resource for the TC5 framework.

## What changed in this version
- Police is now registered as a real `tc5_jobs` job.
- Grade and duty come from `tc5_jobs`.
- Badge number and callsign are kept in a separate table: `tc5_police_profiles`.
- Hiring, grade changes, and firing now update the shared jobs system.
- The TC5 black/red/white UI theme is kept for the police panel.

## Dependencies
- oxmysql
- tc5_core
- tc5_ui
- tc5_jobs
- optional: tc5_eye

## Commands
- `/pd` open the police panel
- `/pdduty` toggle duty
- `/pdreturn` store the current police vehicle
- `/pdhire [id] [badge] [callsign]` hire a player into police
- `/pdgrade [id] [grade]` set a police grade
- `/pdfire [id]` remove a player from police

## How it works now
- `tc5_jobs` stores: job name, grade, and duty.
- `tc5_police_profiles` stores: badge number and callsign.
- The police resource checks `tc5_jobs` for access control.

## Install
1. Replace your current `tc5_jobs` and `tc5_policejob` with the new versions.
2. Import `tc5_jobs.sql` from the jobs package if needed.
3. Import `install.sql` from this police package.
4. Ensure order is:
   - `tc5_core`
   - `tc5_ui`
   - `tc5_jobs`
   - `tc5_policejob`
5. Restart the resources.

## Example flow
- `/pdhire 1 1204 A-12`
- `/pdgrade 1 2`
- player uses `/pdduty`
- player opens `/pd`
