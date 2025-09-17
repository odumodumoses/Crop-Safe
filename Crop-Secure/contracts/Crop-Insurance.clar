;; CropShield: Parametric Agricultural Insurance Protocol Smart Contract
;; 
;; An automated blockchain-based agricultural insurance platform that delivers
;; instant crop protection through weather-triggered parametric claims. The protocol
;; eliminates traditional insurance bureaucracy by using oracle-verified weather data
;; to automatically trigger payouts when environmental conditions exceed predefined
;; crop-specific risk thresholds. Supports multiple crop varieties with customizable
;; risk parameters and provides transparent, decentralized claim processing for farmers.

;; Protocol administration and core system configuration
(define-data-var protocol-administrator principal tx-sender)
(define-data-var minimum-policy-premium uint u100000)
(define-data-var claim-processing-fee uint u10000)
(define-data-var protocol-operational-status bool true)

;; Insurance policy data structure for tracking farmer coverage
(define-map agricultural-insurance-policies
  principal
  {
    total-premium-amount: uint,
    maximum-coverage-payout: uint,
    insured-crop-variety: (string-ascii 20),
    farm-area-hectares: uint,
    coverage-start-block: uint,
    coverage-end-block: uint,
    policy-currently-active: bool,
    insurance-claim-settled: bool
  }
)

;; Historical weather measurements submitted by authorized oracles
(define-map blockchain-weather-archive
  uint
  {
    measured-rainfall-millimeters: uint,
    recorded-temperature-scaled: int,
    measured-wind-velocity-kmh: uint,
    data-submitting-oracle: principal,
    measurement-unix-timestamp: uint
  }
)

;; Registry of trusted weather data providers
(define-map authorized-weather-oracles principal bool)

;; Environmental risk thresholds that trigger insurance payouts per crop type
(define-map crop-environmental-thresholds
  (string-ascii 20)
  {
    minimum-rainfall-threshold: uint,
    maximum-rainfall-threshold: uint,
    minimum-temperature-threshold: int,
    maximum-temperature-threshold: int,
    maximum-wind-speed-threshold: uint
  }
)

;; Comprehensive error code definitions for transaction failures
(define-constant ERR-UNAUTHORIZED-ACCESS (err u100))
(define-constant ERR-DUPLICATE-POLICY-EXISTS (err u101))
(define-constant ERR-POLICY-RECORD-NOT-FOUND (err u102))
(define-constant ERR-INSURANCE-COVERAGE-EXPIRED (err u103))
(define-constant ERR-POLICY-STATUS-INACTIVE (err u104))
(define-constant ERR-CLAIM-PREVIOUSLY-PROCESSED (err u105))
(define-constant ERR-PREMIUM-AMOUNT-INSUFFICIENT (err u106))
(define-constant ERR-PROTOCOL-CURRENTLY-DISABLED (err u107))
(define-constant ERR-INVALID-INPUT-PARAMETERS (err u108))
(define-constant ERR-ORACLE-NOT-AUTHORIZED (err u109))
(define-constant ERR-WEATHER-DATA-ALREADY-EXISTS (err u110))
(define-constant ERR-WEATHER-RECORD-NOT-FOUND (err u111))
(define-constant ERR-CROP-TYPE-NOT-CONFIGURED (err u112))
(define-constant ERR-ORACLE-ALREADY-AUTHORIZED (err u113))
(define-constant ERR-CROP-TYPE-NOT-SUPPORTED (err u114))
(define-constant ERR-RISK-CONFIGURATION-INVALID (err u115))

;; Retrieve current protocol administrator address
(define-read-only (get-protocol-administrator)
  (var-get protocol-administrator)
)

;; Query specific farmer's insurance policy details
(define-read-only (get-farmer-insurance-policy (farmer-wallet-address principal))
  (map-get? agricultural-insurance-policies farmer-wallet-address)
)

;; Fetch weather measurements for a specific blockchain block
(define-read-only (get-historical-weather-data (blockchain-block-height uint))
  (map-get? blockchain-weather-archive blockchain-block-height)
)

;; Verify if weather oracle has data submission authorization
(define-read-only (check-oracle-authorization-status (oracle-wallet-address principal))
  (default-to false (map-get? authorized-weather-oracles oracle-wallet-address))
)

;; Retrieve environmental risk thresholds for specific crop variety
(define-read-only (get-crop-risk-thresholds (crop-type-identifier (string-ascii 20)))
  (map-get? crop-environmental-thresholds crop-type-identifier)
)

;; Check current operational status of the insurance protocol
(define-read-only (get-protocol-operational-status)
  (var-get protocol-operational-status)
)

;; Get comprehensive protocol configuration and fee structure
(define-read-only (get-complete-protocol-configuration)
  {
    required-minimum-premium: (var-get minimum-policy-premium),
    claim-processing-service-fee: (var-get claim-processing-fee),
    system-currently-operational: (var-get protocol-operational-status),
    current-administrator: (var-get protocol-administrator)
  }
)

;; Comprehensive insurance claim eligibility verification engine
(define-read-only (evaluate-insurance-claim-eligibility 
    (policy-holder-address principal) 
    (weather-event-block-height uint))
  (let (
    (farmer-policy-record (map-get? agricultural-insurance-policies policy-holder-address))
    (weather-event-data (map-get? blockchain-weather-archive weather-event-block-height))
  )
    (match farmer-policy-record
      policy-information
      (match weather-event-data
        weather-measurements
        (match (map-get? crop-environmental-thresholds (get insured-crop-variety policy-information))
          environmental-risk-limits
          (and
            ;; Verify policy is currently active and valid
            (get policy-currently-active policy-information)
            (not (get insurance-claim-settled policy-information))
            ;; Confirm weather event occurred during coverage period
            (>= weather-event-block-height (get coverage-start-block policy-information))
            (<= weather-event-block-height (get coverage-end-block policy-information))
            ;; Check if any environmental threshold was exceeded
            (or
              ;; Insufficient rainfall causing drought conditions
              (< (get measured-rainfall-millimeters weather-measurements) 
                 (get minimum-rainfall-threshold environmental-risk-limits))
              ;; Excessive rainfall causing flood conditions
              (> (get measured-rainfall-millimeters weather-measurements) 
                 (get maximum-rainfall-threshold environmental-risk-limits))
              ;; Temperature below crop survival threshold
              (< (get recorded-temperature-scaled weather-measurements) 
                 (get minimum-temperature-threshold environmental-risk-limits))
              ;; Temperature above crop tolerance threshold
              (> (get recorded-temperature-scaled weather-measurements) 
                 (get maximum-temperature-threshold environmental-risk-limits))
              ;; Wind speed exceeding crop damage threshold
              (> (get measured-wind-velocity-kmh weather-measurements) 
                 (get maximum-wind-speed-threshold environmental-risk-limits))
            )
          )
          false
        )
        false
      )
      false
    )
  )
)

;; Calculate proportional refund for early policy cancellation
(define-read-only (calculate-policy-cancellation-refund 
    (policy-holder-address principal) 
    (cancellation-block-height uint))
  (match (map-get? agricultural-insurance-policies policy-holder-address)
    farmer-policy-details
    (let (
      (total-coverage-duration 
        (- (get coverage-end-block farmer-policy-details) 
           (get coverage-start-block farmer-policy-details)))
      (remaining-coverage-duration 
        (- (get coverage-end-block farmer-policy-details) 
           cancellation-block-height))
    )
      (if (> remaining-coverage-duration u0)
        (/ (* (get total-premium-amount farmer-policy-details) remaining-coverage-duration) 
           total-coverage-duration)
        u0)
    )
    u0
  )
)

;; Establish new parametric agricultural insurance coverage
(define-public (establish-agricultural-insurance-policy
    (premium-payment-amount uint)
    (maximum-payout-coverage uint)
    (crop-variety-identifier (string-ascii 20))
    (insured-farm-area-hectares uint)
    (coverage-duration-blocks uint))
  (let (
    (policy-expiration-block (+ block-height coverage-duration-blocks))
  )
    ;; Validate system status and policy parameters
    (asserts! (var-get protocol-operational-status) ERR-PROTOCOL-CURRENTLY-DISABLED)
    (asserts! (is-none (map-get? agricultural-insurance-policies tx-sender)) ERR-DUPLICATE-POLICY-EXISTS)
    (asserts! (>= premium-payment-amount (var-get minimum-policy-premium)) ERR-PREMIUM-AMOUNT-INSUFFICIENT)
    (asserts! (> maximum-payout-coverage premium-payment-amount) ERR-INVALID-INPUT-PARAMETERS)
    (asserts! (> insured-farm-area-hectares u0) ERR-INVALID-INPUT-PARAMETERS)
    (asserts! (> coverage-duration-blocks u0) ERR-INVALID-INPUT-PARAMETERS)
    (asserts! (is-some (map-get? crop-environmental-thresholds crop-variety-identifier)) ERR-CROP-TYPE-NOT-SUPPORTED)
    
    ;; Transfer premium payment to protocol contract
    (try! (stx-transfer? premium-payment-amount tx-sender (as-contract tx-sender)))
    
    ;; Register new insurance policy in blockchain storage
    (map-set agricultural-insurance-policies tx-sender {
      total-premium-amount: premium-payment-amount,
      maximum-coverage-payout: maximum-payout-coverage,
      insured-crop-variety: crop-variety-identifier,
      farm-area-hectares: insured-farm-area-hectares,
      coverage-start-block: block-height,
      coverage-end-block: policy-expiration-block,
      policy-currently-active: true,
      insurance-claim-settled: false
    })
    
    (ok true)
  )
)

;; Execute automated insurance claim based on weather conditions
(define-public (execute-parametric-insurance-claim (triggering-weather-event-block uint))
  (let (
    (insurance-claimant tx-sender)
    (claimant-policy-record (map-get? agricultural-insurance-policies insurance-claimant))
  )
    ;; Perform initial validation checks
    (asserts! (var-get protocol-operational-status) ERR-PROTOCOL-CURRENTLY-DISABLED)
    (asserts! (is-some claimant-policy-record) ERR-POLICY-RECORD-NOT-FOUND)
    
    (let (
      (policy-comprehensive-details (unwrap-panic claimant-policy-record))
    )
      ;; Validate policy status and coverage timeline
      (asserts! (get policy-currently-active policy-comprehensive-details) ERR-POLICY-STATUS-INACTIVE)
      (asserts! (not (get insurance-claim-settled policy-comprehensive-details)) ERR-CLAIM-PREVIOUSLY-PROCESSED)
      (asserts! (<= (get coverage-start-block policy-comprehensive-details) triggering-weather-event-block) ERR-INVALID-INPUT-PARAMETERS)
      (asserts! (>= (get coverage-end-block policy-comprehensive-details) triggering-weather-event-block) ERR-INSURANCE-COVERAGE-EXPIRED)
      (asserts! (is-some (map-get? blockchain-weather-archive triggering-weather-event-block)) ERR-WEATHER-RECORD-NOT-FOUND)
      
      ;; Confirm claim meets parametric trigger conditions
      (asserts! (evaluate-insurance-claim-eligibility insurance-claimant triggering-weather-event-block) ERR-INVALID-INPUT-PARAMETERS)
      
      ;; Deduct claim processing service fee
      (try! (stx-transfer? (var-get claim-processing-fee) tx-sender (as-contract tx-sender)))
      
      ;; Transfer insurance payout to farmer
      (try! (as-contract (stx-transfer? (get maximum-coverage-payout policy-comprehensive-details) tx-sender insurance-claimant)))
      
      ;; Update policy status to prevent duplicate claims
      (map-set agricultural-insurance-policies insurance-claimant 
        (merge policy-comprehensive-details { insurance-claim-settled: true }))
      
      (ok true)
    )
  )
)

;; Terminate insurance policy and receive proportional premium refund
(define-public (terminate-insurance-policy)
  (let (
    (policy-terminating-farmer tx-sender)
    (current-farmer-policy (map-get? agricultural-insurance-policies policy-terminating-farmer))
  )
    ;; Validate system status and policy existence
    (asserts! (var-get protocol-operational-status) ERR-PROTOCOL-CURRENTLY-DISABLED)
    (asserts! (is-some current-farmer-policy) ERR-POLICY-RECORD-NOT-FOUND)
    
    (let (
      (policy-termination-details (unwrap-panic current-farmer-policy))
      (calculated-refund-amount (calculate-policy-cancellation-refund policy-terminating-farmer block-height))
    )
      (asserts! (get policy-currently-active policy-termination-details) ERR-POLICY-STATUS-INACTIVE)
      (asserts! (not (get insurance-claim-settled policy-termination-details)) ERR-CLAIM-PREVIOUSLY-PROCESSED)
      
      ;; Issue refund if farmer is entitled to partial premium return
      (if (> calculated-refund-amount u0)
        (try! (as-contract (stx-transfer? calculated-refund-amount tx-sender policy-terminating-farmer)))
        true)
      
      ;; Mark policy as inactive in blockchain records
      (map-set agricultural-insurance-policies policy-terminating-farmer 
        (merge policy-termination-details { policy-currently-active: false }))
      
      (ok true)
    )
  )
)

;; Submit verified weather measurements to blockchain archive
(define-public (record-weather-measurements
    (measurement-block-height uint)
    (rainfall-measurement-mm uint)
    (temperature-measurement-scaled int)
    (wind-speed-measurement-kmh uint)
    (data-collection-timestamp uint))
  (let (
    (submitting-oracle-address tx-sender)
  )
    ;; Verify oracle authorization and data integrity
    (asserts! (var-get protocol-operational-status) ERR-PROTOCOL-CURRENTLY-DISABLED)
    (asserts! (check-oracle-authorization-status submitting-oracle-address) ERR-ORACLE-NOT-AUTHORIZED)
    (asserts! (is-none (map-get? blockchain-weather-archive measurement-block-height)) ERR-WEATHER-DATA-ALREADY-EXISTS)
    
    ;; Validate weather measurement parameters
    (asserts! (>= rainfall-measurement-mm u0) ERR-INVALID-INPUT-PARAMETERS)
    (asserts! (>= wind-speed-measurement-kmh u0) ERR-INVALID-INPUT-PARAMETERS)
    (asserts! (>= data-collection-timestamp u0) ERR-INVALID-INPUT-PARAMETERS)
    (asserts! (and (>= temperature-measurement-scaled (- 0 500)) 
                   (<= temperature-measurement-scaled 1000)) ERR-INVALID-INPUT-PARAMETERS)
    
    ;; Archive weather data in blockchain storage
    (map-set blockchain-weather-archive measurement-block-height {
      measured-rainfall-millimeters: rainfall-measurement-mm,
      recorded-temperature-scaled: temperature-measurement-scaled,
      measured-wind-velocity-kmh: wind-speed-measurement-kmh,
      data-submitting-oracle: submitting-oracle-address,
      measurement-unix-timestamp: data-collection-timestamp
    })
    
    (ok true)
  )
)

;; Authorize new weather data provider oracle
(define-public (authorize-weather-oracle (oracle-wallet-address principal))
  (begin
    (asserts! (is-eq tx-sender (var-get protocol-administrator)) ERR-UNAUTHORIZED-ACCESS)
    (asserts! (not (check-oracle-authorization-status oracle-wallet-address)) ERR-ORACLE-ALREADY-AUTHORIZED)
    
    (map-set authorized-weather-oracles oracle-wallet-address true)
    (ok true)
  )
)

;; Revoke weather oracle data submission privileges
(define-public (revoke-oracle-authorization (oracle-wallet-address principal))
  (begin
    (asserts! (is-eq tx-sender (var-get protocol-administrator)) ERR-UNAUTHORIZED-ACCESS)
    (asserts! (check-oracle-authorization-status oracle-wallet-address) ERR-ORACLE-NOT-AUTHORIZED)
    
    (map-delete authorized-weather-oracles oracle-wallet-address)
    (ok true)
  )
)

;; Configure environmental risk thresholds for specific crop varieties
(define-public (configure-crop-environmental-thresholds
    (crop-type-name (string-ascii 20))
    (drought-rainfall-threshold uint)
    (flood-rainfall-threshold uint)
    (frost-temperature-threshold int)
    (heat-temperature-threshold int)
    (wind-damage-threshold uint))
  (begin
    ;; Verify administrator privileges and parameter validity
    (asserts! (is-eq tx-sender (var-get protocol-administrator)) ERR-UNAUTHORIZED-ACCESS)
    (asserts! (> flood-rainfall-threshold drought-rainfall-threshold) ERR-RISK-CONFIGURATION-INVALID)
    (asserts! (< frost-temperature-threshold heat-temperature-threshold) ERR-RISK-CONFIGURATION-INVALID)
    (asserts! (> wind-damage-threshold u0) ERR-RISK-CONFIGURATION-INVALID)
    (asserts! (not (is-eq crop-type-name "")) ERR-CROP-TYPE-NOT-SUPPORTED)
    (asserts! (>= drought-rainfall-threshold u0) ERR-RISK-CONFIGURATION-INVALID)
    
    ;; Store environmental risk configuration for crop type
    (map-set crop-environmental-thresholds crop-type-name {
      minimum-rainfall-threshold: drought-rainfall-threshold,
      maximum-rainfall-threshold: flood-rainfall-threshold,
      minimum-temperature-threshold: frost-temperature-threshold,
      maximum-temperature-threshold: heat-temperature-threshold,
      maximum-wind-speed-threshold: wind-damage-threshold
    })
    (ok true)
  )
)

;; Modify minimum premium requirement for new policies
(define-public (adjust-minimum-premium-requirement (updated-minimum-premium uint))
  (begin
    (asserts! (is-eq tx-sender (var-get protocol-administrator)) ERR-UNAUTHORIZED-ACCESS)
    (asserts! (> updated-minimum-premium u0) ERR-INVALID-INPUT-PARAMETERS)
    
    (var-set minimum-policy-premium updated-minimum-premium)
    (ok true)
  )
)

;; Update claim processing service fee structure
(define-public (modify-claim-processing-fee (updated-processing-fee uint))
  (begin
    (asserts! (is-eq tx-sender (var-get protocol-administrator)) ERR-UNAUTHORIZED-ACCESS)
    (asserts! (>= updated-processing-fee u0) ERR-INVALID-INPUT-PARAMETERS)
    
    (var-set claim-processing-fee updated-processing-fee)
    (ok true)
  )
)

;; Enable or disable protocol operational status
(define-public (modify-protocol-operational-status (operational-status bool))
  (begin
    (asserts! (is-eq tx-sender (var-get protocol-administrator)) ERR-UNAUTHORIZED-ACCESS)
    
    (var-set protocol-operational-status operational-status)
    (ok true)
  )
)

;; Transfer protocol administrative control to new address
(define-public (transfer-protocol-administration (new-administrator-address principal))
  (begin
    (asserts! (is-eq tx-sender (var-get protocol-administrator)) ERR-UNAUTHORIZED-ACCESS)
    (asserts! (not (is-eq new-administrator-address tx-sender)) ERR-INVALID-INPUT-PARAMETERS)
    
    (var-set protocol-administrator new-administrator-address)
    (ok true)
  )
)

;; Emergency protocol fund withdrawal mechanism
(define-public (execute-emergency-fund-withdrawal (withdrawal-amount uint))
  (begin
    (asserts! (is-eq tx-sender (var-get protocol-administrator)) ERR-UNAUTHORIZED-ACCESS)
    (asserts! (> withdrawal-amount u0) ERR-INVALID-INPUT-PARAMETERS)
    
    (try! (as-contract (stx-transfer? withdrawal-amount tx-sender (var-get protocol-administrator))))
    (ok true)
  )
)