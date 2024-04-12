# [4.2.4] - 2023-07-20

## Added

## Changed

## Fixed
- fix: add lacking 's' to exist
- fix: change wrong :cropIdentifier.code with the correct scatterer :code
- fix wasting IDS when inserting Sscatterers


## Removed

## Notes
Tag added after image creation (The version has been updated to hub on july 2023)


# [4.2.3] - 2022-01-27

## Added

## Changed

## Fixed
- Bug fix ID 3748-pkt309-TeamEretico | Dev | Apache Log4j Security Vulnerabilities

## Removed


# [4.2.2] - 2021-10-26

## Added

## Changed
- Change periodic_properties attribute from LOS_Z_ANG to LOS_AZ_ANG
## Fixed

## Removed

# [4.2.1] - 2021-09-09

## Added
- Add corner_reflector handling to import
- Add attributes to periodic_properties ACL_LOS, V_LOS_STD, INC_ANG, LOS_Z_ANG, SEA_LOS, D_STD_LOS, UPDT_FLAG, VELR_L_M VELR_STD_M, VR_L_LIN, VR_STD_LIN, COHR_L_M
## Changed
- Change acceleration to read it from shapefile;
## Fixed
- Fix acceleration computing when there are missing measures in more than one year of the global period
## Removed

# [4.2.0] - 2019-03-05

## Added

## Changed
- Import to support the new database schema
- Readme

## Fixed
- Logs

## Removed

# [4.1.0] - 2018-11-19

## Added
- Add step to handle periodic thematization
- Add step to import scatterer

## Changed
- Align to new ps identifier schema

## Fixed

## Removed

# [4.0.0] - 2018-09-28
---
## Added
- Add DB connection pool
- Add Thread pool
- Handle amplitude data

## Changed
- Support 4.0.0 db
- Improve parallelization
