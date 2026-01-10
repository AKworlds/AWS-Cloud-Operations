# Decision 04: Encryption Strategy

## Context

ITAR/DFARS compliance requires encryption for data at rest and in transit. Need to balance security requirements with performance impact.

## Options Considered

1. **Default AWS Encryption** - Simple but less control
2. **Customer Managed Keys (CMK)** - Full control, audit capability
3. **Third-party HSM** - Maximum security, higher complexity

## Decision

**AWS KMS with Customer Managed Keys (AES-256-GCM)**

## Implementation

### EBS Volumes
All three volumes encrypted with dedicated CMK:
- Automatic encryption at rest
- Keys never leave KMS
- Full audit trail in CloudTrail

### Key Policy
```json
{
  "Effect": "Allow",
  "Principal": {"Service": "ec2.amazonaws.com"},
  "Action": [
    "kms:Encrypt",
    "kms:Decrypt",
    "kms:GenerateDataKey*"
  ],
  "Resource": "*",
  "Condition": {
    "StringEquals": {
      "kms:ViaService": "ec2.us-east-1.amazonaws.com"
    }
  }
}
```

## Compliance Mapping

| Requirement | Implementation |
|-------------|----------------|
| ITAR Data Protection | AES-256 encryption at rest |
| DFARS 252.204-7012 | FIPS 140-2 validated modules |
| Audit Trail | CloudTrail logging all key usage |
| Key Rotation | Annual automatic rotation enabled |

## Trade-offs

- Slight performance overhead (minimal with modern CPUs)
- Additional cost for KMS API calls
- Key management complexity

## Lessons Learned

Compliance doesn't have to mean complexity. AWS native tools often meet requirements without third-party solutions.
