# Security

## Reporting a vulnerability

Report security problems privately, not in a public issue. On GitHub, open the repository's **Security** tab and choose **Report a vulnerability**. Only the maintainers can see the report.

Include what you found, how to reproduce it, and what an attacker could do with it.

## What counts

A security problem in this module is anything that opens more of a network than its inputs say it should: for example, a route added to a route table the caller did not list, a route to a wider CIDR block than the other VPC's, remote DNS resolution turned on without being asked for, or a validation that lets an unsafe value through.

## Supported versions

Fixes are made to the latest release.
