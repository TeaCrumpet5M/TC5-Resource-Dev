# tc5_jobs

Drop-in dynamic jobs resource for TC5.

## Commands
- /tc5_job
- /tc5_duty
- /tc5_setjob [id] [job] [grade]

## Notes
- Jobs can be registered at runtime with exports['tc5_jobs']:RegisterJob({...})
- This package ships with unemployed and police by default
- Multi-shop mechanic jobs are registered by the tc5_mechanicjob resource
