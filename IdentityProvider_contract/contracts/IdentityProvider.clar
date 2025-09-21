
;; title: IdentityProvider
;; version: 1.0.0
;; summary: Address reputation system for digital identity providers
;; description: Smart contract that manages accuracy and security scoring for identity providers

;; traits
;;

;; token definitions
;;

;; constants
;;
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_PROVIDER_NOT_FOUND (err u101))
(define-constant ERR_PROVIDER_ALREADY_EXISTS (err u102))
(define-constant ERR_INVALID_SCORE (err u103))
(define-constant ERR_INVALID_NAME (err u104))
(define-constant ERR_PROVIDER_NOT_ACTIVE (err u105))

;; Score ranges
(define-constant MIN_SCORE u0)
(define-constant MAX_SCORE u100)
(define-constant DEFAULT_SCORE u50)

;; data vars
;;
(define-data-var contract-owner principal CONTRACT_OWNER)

;; data maps
;;
;; Provider information storage
(define-map providers
  principal
  {
    name: (string-ascii 50),
    accuracy-score: uint,
    security-score: uint,
    total-verifications: uint,
    successful-verifications: uint,
    is-active: bool,
    registration-block: uint
  }
)

;; Provider reputation history
(define-map reputation-history
  { provider: principal, block-height-recorded: uint }
  {
    accuracy-score: uint,
    security-score: uint,
    event-type: (string-ascii 20)
  }
)

;; Verification records
(define-map verification-records
  { provider: principal, verification-id: uint }
  {
    requester: principal,
    success: bool,
    timestamp: uint,
    accuracy-impact: int,
    security-impact: int
  }
)

;; Track verification counter for each provider
(define-map verification-counters principal uint)

;; public functions
;;

;; Register a new identity provider
(define-public (register-provider (name (string-ascii 50)))
  (let (
    (provider tx-sender)
    (current-block block-height)
  )
    ;; Check if provider already exists
    (asserts! (is-none (map-get? providers provider)) ERR_PROVIDER_ALREADY_EXISTS)
    ;; Validate name length
    (asserts! (> (len name) u0) ERR_INVALID_NAME)

    ;; Register the provider
    (map-set providers provider {
      name: name,
      accuracy-score: DEFAULT_SCORE,
      security-score: DEFAULT_SCORE,
      total-verifications: u0,
      successful-verifications: u0,
      is-active: true,
      registration-block: current-block
    })

    ;; Initialize verification counter
    (map-set verification-counters provider u0)

    ;; Record initial reputation
    (map-set reputation-history
      { provider: provider, block-height-recorded: current-block }
      {
        accuracy-score: DEFAULT_SCORE,
        security-score: DEFAULT_SCORE,
        event-type: "registration"
      }
    )

    (ok provider)
  )
)

;; Update provider reputation scores
(define-public (update-reputation
  (provider principal)
  (accuracy-score uint)
  (security-score uint)
  (event-type (string-ascii 20))
)
  (let (
    (caller tx-sender)
    (current-block block-height)
    (provider-data (unwrap! (map-get? providers provider) ERR_PROVIDER_NOT_FOUND))
  )
    ;; Only contract owner can update reputation
    (asserts! (is-eq caller (var-get contract-owner)) ERR_UNAUTHORIZED)
    ;; Validate scores
    (asserts! (and (>= accuracy-score MIN_SCORE) (<= accuracy-score MAX_SCORE)) ERR_INVALID_SCORE)
    (asserts! (and (>= security-score MIN_SCORE) (<= security-score MAX_SCORE)) ERR_INVALID_SCORE)
    ;; Check if provider is active
    (asserts! (get is-active provider-data) ERR_PROVIDER_NOT_ACTIVE)

    ;; Update provider scores
    (map-set providers provider (merge provider-data {
      accuracy-score: accuracy-score,
      security-score: security-score
    }))

    ;; Record reputation history
    (map-set reputation-history
      { provider: provider, block-height-recorded: current-block }
      {
        accuracy-score: accuracy-score,
        security-score: security-score,
        event-type: event-type
      }
    )

    (ok true)
  )
)

;; Record a verification event
(define-public (record-verification
  (provider principal)
  (success bool)
  (accuracy-impact int)
  (security-impact int)
)
  (let (
    (caller tx-sender)
    (provider-data (unwrap! (map-get? providers provider) ERR_PROVIDER_NOT_FOUND))
    (current-counter (default-to u0 (map-get? verification-counters provider)))
    (new-counter (+ current-counter u1))
    (current-total (get total-verifications provider-data))
    (current-successful (get successful-verifications provider-data))
    (new-total (+ current-total u1))
    (new-successful (if success (+ current-successful u1) current-successful))
  )
    ;; Check if provider is active
    (asserts! (get is-active provider-data) ERR_PROVIDER_NOT_ACTIVE)

    ;; Record verification
    (map-set verification-records
      { provider: provider, verification-id: new-counter }
      {
        requester: caller,
        success: success,
        timestamp: block-height,
        accuracy-impact: accuracy-impact,
        security-impact: security-impact
      }
    )

    ;; Update verification counters
    (map-set verification-counters provider new-counter)

    ;; Update provider verification stats
    (map-set providers provider (merge provider-data {
      total-verifications: new-total,
      successful-verifications: new-successful
    }))

    (ok new-counter)
  )
)

;; Deactivate a provider (admin only)
(define-public (deactivate-provider (provider principal))
  (let (
    (caller tx-sender)
    (provider-data (unwrap! (map-get? providers provider) ERR_PROVIDER_NOT_FOUND))
  )
    ;; Only contract owner can deactivate
    (asserts! (is-eq caller (var-get contract-owner)) ERR_UNAUTHORIZED)

    ;; Deactivate provider
    (map-set providers provider (merge provider-data {
      is-active: false
    }))

    (ok true)
  )
)

;; Reactivate a provider (admin only)
(define-public (reactivate-provider (provider principal))
  (let (
    (caller tx-sender)
    (provider-data (unwrap! (map-get? providers provider) ERR_PROVIDER_NOT_FOUND))
  )
    ;; Only contract owner can reactivate
    (asserts! (is-eq caller (var-get contract-owner)) ERR_UNAUTHORIZED)

    ;; Reactivate provider
    (map-set providers provider (merge provider-data {
      is-active: true
    }))

    (ok true)
  )
)

;; Transfer contract ownership (admin only)
(define-public (transfer-ownership (new-owner principal))
  (let (
    (caller tx-sender)
  )
    ;; Only current owner can transfer
    (asserts! (is-eq caller (var-get contract-owner)) ERR_UNAUTHORIZED)

    ;; Transfer ownership
    (var-set contract-owner new-owner)

    (ok new-owner)
  )
)

;; read only functions
;;

;; Get provider information
(define-read-only (get-provider (provider principal))
  (map-get? providers provider)
)

;; Get provider reputation scores
(define-read-only (get-provider-reputation (provider principal))
  (match (map-get? providers provider)
    provider-data (some {
      accuracy-score: (get accuracy-score provider-data),
      security-score: (get security-score provider-data),
      is-active: (get is-active provider-data)
    })
    none
  )
)

;; Get provider verification stats
(define-read-only (get-verification-stats (provider principal))
  (match (map-get? providers provider)
    provider-data (some {
      total-verifications: (get total-verifications provider-data),
      successful-verifications: (get successful-verifications provider-data),
      success-rate: (if (> (get total-verifications provider-data) u0)
        (/ (* (get successful-verifications provider-data) u100) (get total-verifications provider-data))
        u0
      )
    })
    none
  )
)

;; Get reputation history for a specific block
(define-read-only (get-reputation-history (provider principal) (block-height-recorded uint))
  (map-get? reputation-history { provider: provider, block-height-recorded: block-height-recorded })
)

;; Get verification record
(define-read-only (get-verification-record (provider principal) (verification-id uint))
  (map-get? verification-records { provider: provider, verification-id: verification-id })
)

;; Get current verification counter for provider
(define-read-only (get-verification-counter (provider principal))
  (default-to u0 (map-get? verification-counters provider))
)

;; Check if provider is active
(define-read-only (is-provider-active (provider principal))
  (match (map-get? providers provider)
    provider-data (get is-active provider-data)
    false
  )
)

;; Get contract owner
(define-read-only (get-contract-owner)
  (var-get contract-owner)
)

;; Calculate overall reputation score (weighted average)
(define-read-only (get-overall-reputation (provider principal))
  (match (map-get? providers provider)
    provider-data
    (let (
      (accuracy (get accuracy-score provider-data))
      (security (get security-score provider-data))
      ;; Weight accuracy 60% and security 40%
      (weighted-score (/ (+ (* accuracy u60) (* security u40)) u100))
    )
      (some weighted-score)
    )
    none
  )
)

;; private functions
;;

;; Helper function to validate score range
(define-private (is-valid-score (score uint))
  (and (>= score MIN_SCORE) (<= score MAX_SCORE))
)
