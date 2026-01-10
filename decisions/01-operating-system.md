# Decision 01: Operating System Selection

## Context

Needed an OS for aerospace CFD simulations that meets ITAR/DFARS compliance requirements while supporting high-performance computing workloads.

## Options Considered

1. **Ubuntu Server** - Popular, large community
2. **RHEL** - Enterprise support, compliance certifications
3. **Amazon Linux 2023** - AWS-native, FIPS validated

## Decision

**Amazon Linux 2023**

## Rationale

- **FIPS 140-2 Validated**: Cryptographic modules certified for government work
- **AWS-Optimized Kernel**: Better performance on EC2 instances
- **Native Integration**: Seamless SSM, CloudWatch, and other AWS service support
- **Cost**: No additional licensing fees
- **Long-term Support**: 5-year support lifecycle

## Trade-offs

- Less community documentation than Ubuntu
- Some third-party tools may need adaptation
- AWS lock-in considerations

## Validation

Verified FIPS mode activation with:
```bash
fips-mode-setup --check
# Output: FIPS mode is enabled
```
