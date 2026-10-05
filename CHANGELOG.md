# Changelog

All notable changes to this module are listed here. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the module uses [semantic versioning](https://semver.org/): a new major version means callers must change their code.

## [Unreleased]

## [1.0.0] - 2026-10-05

Initial release.

### Added

- A VPC peering connection between two VPCs in the same account and Region, in different Regions, in different accounts, or both, accepted automatically with the accepter account's provider.
- Routes to the other VPC's primary IPv4 CIDR block in the route tables you list on each side, keyed by names you choose, so route tables created in the same run can be used.
- Remote DNS resolution, off by default, turned on separately for each side.
- A `Name` tag built from the two VPCs' names, or one you choose.
- `region` and `accepter.region`, for each VPC's Region, without configuring another provider.
- A `metadata` output with everything the module created, including the connection's ID and both sides' accounts and Regions.
- Offline tests, and examples for peering in one account and Region, across Regions, and across accounts.

[Unreleased]: https://github.com/AutomateTheCloud/terraform-aws-vpc_peering/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/AutomateTheCloud/terraform-aws-vpc_peering/releases/tag/v1.0.0
