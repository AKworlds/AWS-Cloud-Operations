# Compliance Notes

## ITAR/DFARS Requirements Mapping

This document maps compliance requirements to specific implementations in this environment.

## ITAR (International Traffic in Arms Regulations)

### Data Protection Requirements

| Requirement | Implementation | Evidence |
|-------------|----------------|----------|
| Encryption at rest | AES-256 via KMS CMK | EBS volume encryption status |
| Encryption in transit | TLS 1.2+ for all AWS API calls | VPC flow logs, CloudTrail |
| Access control | IAM policies, Security Groups | IAM policy documents |
| US persons only | AWS GovCloud consideration | Region selection |

### Audit Requirements

| Requirement | Implementation | Retention |
|-------------|----------------|-----------|
| Access logging | CloudTrail | 7 years |
| Key usage | KMS CloudTrail events | 7 years |
| System changes | AWS Config | 7 years |

## DFARS 252.204-7012

### Covered Defense Information (CDI) Handling

| Control | Implementation |
|---------|----------------|
| 3.1.1 - Limit access | IAM least privilege |
| 3.1.2 - Limit transactions | Security group rules |
| 3.5.3 - MFA | IAM MFA enforcement |
| 3.13.11 - FIPS encryption | Amazon Linux 2023 FIPS mode |

### Incident Response

Preparation for cyber incident reporting:
1. CloudTrail logs preserved in separate account
2. VPC flow logs enabled
3. GuardDuty alerts configured
4. 72-hour reporting procedure documented

## FIPS 140-2 Validation

### Verified Components

```bash
# Verify FIPS mode
$ fips-mode-setup --check
FIPS mode is enabled

# Verify crypto modules
$ openssl version
OpenSSL 3.0.x (FIPS)
```

### AWS Services in FIPS Mode

| Service | FIPS Endpoint |
|---------|---------------|
| KMS | kms-fips.us-east-1.amazonaws.com |
| S3 | s3-fips.us-east-1.amazonaws.com |
| EC2 | ec2-fips.us-east-1.amazonaws.com |

## Audit Checklist

For compliance audits, provide:

- [ ] CloudTrail logs for specified period
- [ ] KMS key policies and usage logs
- [ ] IAM policy documents
- [ ] Security group configurations
- [ ] VPC flow logs
- [ ] AWS Config compliance snapshots
- [ ] Inspector vulnerability reports

## References

- [AWS ITAR Reference Architecture](https://aws.amazon.com/compliance/itar/)
- [DFARS 252.204-7012 Text](https://www.acquisition.gov/dfars/252.204-7012)
- [NIST SP 800-171](https://csrc.nist.gov/publications/detail/sp/800-171/rev-2/final)
