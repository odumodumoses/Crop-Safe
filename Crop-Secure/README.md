# CropShield: Parametric Agricultural Insurance Protocol

## Overview

CropShield is an automated blockchain-based agricultural insurance platform that delivers instant crop protection through weather-triggered parametric claims. The protocol eliminates traditional insurance bureaucracy by using oracle-verified weather data to automatically trigger payouts when environmental conditions exceed predefined crop-specific risk thresholds.

## Key Features

- **Automated Claims Processing**: Weather-triggered payouts without manual intervention
- **Multi-Crop Support**: Customizable risk parameters for different crop varieties
- **Transparent Operations**: Decentralized claim processing with full blockchain transparency
- **Oracle Integration**: Trusted weather data providers for accurate measurements
- **Parametric Triggers**: Instant payouts based on objective weather conditions

## Smart Contract Architecture

### Core Components

1. **Insurance Policies**: Farmer coverage tracking with customizable parameters
2. **Weather Archive**: Historical weather data submitted by authorized oracles
3. **Risk Thresholds**: Crop-specific environmental limits that trigger payouts
4. **Oracle Registry**: Authorized weather data providers management

### Data Structures

#### Agricultural Insurance Policies
```clarity
{
  total-premium-amount: uint,
  maximum-coverage-payout: uint,
  insured-crop-variety: string-ascii,
  farm-area-hectares: uint,
  coverage-start-block: uint,
  coverage-end-block: uint,
  policy-currently-active: bool,
  insurance-claim-settled: bool
}
```

#### Weather Archive
```clarity
{
  measured-rainfall-millimeters: uint,
  recorded-temperature-scaled: int,
  measured-wind-velocity-kmh: uint,
  data-submitting-oracle: principal,
  measurement-unix-timestamp: uint
}
```

#### Crop Risk Thresholds
```clarity
{
  minimum-rainfall-threshold: uint,
  maximum-rainfall-threshold: uint,
  minimum-temperature-threshold: int,
  maximum-temperature-threshold: int,
  maximum-wind-speed-threshold: uint
}
```

## Protocol Functions

### Public Functions

#### For Farmers

**establish-agricultural-insurance-policy**
- Creates new insurance coverage for farmers
- Parameters: premium amount, maximum payout, crop variety, farm area, coverage duration
- Validates minimum premium requirements and crop type support

**execute-parametric-insurance-claim**
- Triggers automatic payout based on weather conditions
- Requires triggering weather event block height
- Validates claim eligibility against environmental thresholds

**terminate-insurance-policy**
- Cancels active policy with proportional premium refund
- Calculates refund based on remaining coverage period

#### For Weather Oracles

**record-weather-measurements**
- Submits verified weather data to blockchain archive
- Parameters: block height, rainfall, temperature, wind speed, timestamp
- Restricted to authorized oracles only

#### For Protocol Administrators

**authorize-weather-oracle**
- Grants weather data submission privileges to new oracles

**revoke-oracle-authorization**
- Removes oracle data submission privileges

**configure-crop-environmental-thresholds**
- Sets risk parameters for different crop varieties
- Defines drought, flood, frost, heat, and wind damage thresholds

**adjust-minimum-premium-requirement**
- Updates minimum premium amount for new policies

**modify-claim-processing-fee**
- Changes service fee for claim processing

**modify-protocol-operational-status**
- Enables or disables protocol operations

**transfer-protocol-administration**
- Transfers administrative control to new address

**execute-emergency-fund-withdrawal**
- Emergency mechanism for protocol fund access

### Read-Only Functions

- `get-protocol-administrator`: Returns current administrator address
- `get-farmer-insurance-policy`: Retrieves farmer's policy details
- `get-historical-weather-data`: Fetches weather data for specific block
- `check-oracle-authorization-status`: Verifies oracle permissions
- `get-crop-risk-thresholds`: Returns environmental limits for crop types
- `get-protocol-operational-status`: Checks if protocol is active
- `get-complete-protocol-configuration`: Returns full protocol settings
- `evaluate-insurance-claim-eligibility`: Validates claim conditions
- `calculate-policy-cancellation-refund`: Computes early termination refund

## Error Codes

| Code | Constant | Description |
|------|----------|-------------|
| 100 | ERR-UNAUTHORIZED-ACCESS | Insufficient permissions |
| 101 | ERR-DUPLICATE-POLICY-EXISTS | Policy already exists for farmer |
| 102 | ERR-POLICY-RECORD-NOT-FOUND | No policy found for address |
| 103 | ERR-INSURANCE-COVERAGE-EXPIRED | Policy coverage period ended |
| 104 | ERR-POLICY-STATUS-INACTIVE | Policy is not active |
| 105 | ERR-CLAIM-PREVIOUSLY-PROCESSED | Claim already settled |
| 106 | ERR-PREMIUM-AMOUNT-INSUFFICIENT | Premium below minimum requirement |
| 107 | ERR-PROTOCOL-CURRENTLY-DISABLED | Protocol operations suspended |
| 108 | ERR-INVALID-INPUT-PARAMETERS | Invalid function parameters |
| 109 | ERR-ORACLE-NOT-AUTHORIZED | Oracle lacks data submission rights |
| 110 | ERR-WEATHER-DATA-ALREADY-EXISTS | Weather data already recorded |
| 111 | ERR-WEATHER-RECORD-NOT-FOUND | No weather data for specified block |
| 112 | ERR-CROP-TYPE-NOT-CONFIGURED | Crop thresholds not set |
| 113 | ERR-ORACLE-ALREADY-AUTHORIZED | Oracle already has permissions |
| 114 | ERR-CROP-TYPE-NOT-SUPPORTED | Unsupported crop variety |
| 115 | ERR-RISK-CONFIGURATION-INVALID | Invalid risk threshold settings |

## Usage Examples

### Creating an Insurance Policy

```clarity
(establish-agricultural-insurance-policy
  u500000    ;; Premium: 0.5 STX
  u2000000   ;; Max payout: 2 STX
  "wheat"    ;; Crop type
  u100       ;; Farm area: 100 hectares
  u8760      ;; Coverage: ~1 year in blocks
)
```

### Submitting Weather Data

```clarity
(record-weather-measurements
  u12345     ;; Block height
  u25        ;; Rainfall: 25mm
  200        ;; Temperature: 20.0°C (scaled)
  u15        ;; Wind speed: 15 km/h
  u1640995200 ;; Unix timestamp
)
```

### Configuring Crop Thresholds

```clarity
(configure-crop-environmental-thresholds
  "wheat"    ;; Crop type
  u10        ;; Drought threshold: <10mm rainfall
  u200       ;; Flood threshold: >200mm rainfall
  -50        ;; Frost threshold: <-5°C
  400        ;; Heat threshold: >40°C
  u80        ;; Wind damage threshold: >80 km/h
)
```

## Deployment Requirements

### Prerequisites
- Stacks blockchain environment
- Administrative wallet with sufficient STX for deployment
- Weather oracle infrastructure setup

### Initial Configuration Steps

1. Deploy contract with administrator wallet
2. Configure minimum premium and processing fees
3. Set up crop-specific risk thresholds
4. Authorize weather data oracles
5. Enable protocol operations

### Oracle Integration

Weather oracles must be authorized before submitting data:
- Temperature values are scaled (multiply by 10, e.g., 25.5°C = 255)
- Rainfall measured in millimeters
- Wind speed in kilometers per hour
- Timestamp in Unix format

## Security Considerations

- Only authorized oracles can submit weather data
- Administrator functions are restricted to protocol owner
- Claims require valid policy and triggering weather conditions
- Premium payments are held in contract until claims or refunds
- Emergency withdrawal mechanism for protocol maintenance