;; Minimal Cross-Chain Identity Contract
;; Simplified version focusing on core identity features with enhanced functionality

;; Error codes
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-IDENTITY-EXISTS (err u101))
(define-constant ERR-IDENTITY-NOT-FOUND (err u102))
(define-constant ERR-INVALID-CHAIN (err u103))
(define-constant ERR-USERNAME-TAKEN (err u104))
(define-constant ERR-INVALID-USERNAME (err u105))
(define-constant ERR-PROFILE-INACTIVE (err u106))
(define-constant ERR-LINK-EXISTS (err u107))

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant MIN-USERNAME-LENGTH u3)
(define-constant MAX-USERNAME-LENGTH u50)
(define-constant BASE-REPUTATION u100)

;; Supported chains (using map for extensibility)
(define-map supported-chains uint { name: (string-ascii 20), active: bool })
(map-set supported-chains u1 { name: "ethereum", active: true })
(map-set supported-chains u2 { name: "solana", active: true })
(map-set supported-chains u3 { name: "cosmos", active: true })
(map-set supported-chains u4 { name: "bitcoin", active: true })
(map-set supported-chains u5 { name: "polygon", active: true })

;; Core identity storage
(define-map user-profiles
    principal
    {
        username: (string-ascii 50),
        created-at: uint,
        last-updated: uint,
        profile-hash: (optional (buff 32)),
        is-active: bool,
        reputation: uint,
        verified-chains: uint, ;; Count of verified chains
        total-links: uint
    }
)

;; Username registry for uniqueness
(define-map username-registry (string-ascii 50) principal)

;; Cross-chain addresses
(define-map chain-links
    { user: principal, chain: uint }
    {
        address: (string-ascii 128),
        verified: bool,
        added-at: uint,
        verified-at: (optional uint),
        proof-method: (optional (string-ascii 50))
    }
)

;; Simple social connections
(define-map connections
    { from: principal, to: principal }
    {
        connection-type: uint, ;; 1=follow, 2=trust
        created-at: uint
    }
)

;; Stats and counters
(define-data-var total-users uint u0)
(define-data-var total-connections uint u0)
(define-data-var total-verifications uint u0)
(define-data-var contract-admin principal CONTRACT-OWNER)

;; Admin functions
(define-public (set-admin (new-admin principal))
    (begin
        (asserts! (is-eq tx-sender (var-get contract-admin)) ERR-NOT-AUTHORIZED)
        (var-set contract-admin new-admin)
        (ok true)
    )
)

(define-public (add-supported-chain (chain-id uint) (name (string-ascii 20)))
    (begin
        (asserts! (is-eq tx-sender (var-get contract-admin)) ERR-NOT-AUTHORIZED)
        (map-set supported-chains chain-id { name: name, active: true })
        (ok true)
    )
)

(define-public (toggle-chain (chain-id uint))
    (begin
        (asserts! (is-eq tx-sender (var-get contract-admin)) ERR-NOT-AUTHORIZED)
        (let ((chain-info (unwrap! (map-get? supported-chains chain-id) ERR-INVALID-CHAIN)))
            (map-set supported-chains chain-id
                (merge chain-info { active: (not (get active chain-info)) })
            )
            (ok true)
        )
    )
)

;; Core Functions
(define-public (register (username (string-ascii 50)))
    (begin
        (asserts! (is-none (map-get? user-profiles tx-sender)) ERR-IDENTITY-EXISTS)
        (asserts! (is-none (map-get? username-registry username)) ERR-USERNAME-TAKEN)
        (asserts! (>= (len username) MIN-USERNAME-LENGTH) ERR-INVALID-USERNAME)
        (asserts! (<= (len username) MAX-USERNAME-LENGTH) ERR-INVALID-USERNAME)
        
        ;; Register username
        (map-set username-registry username tx-sender)
        
        ;; Create profile
        (map-set user-profiles tx-sender {
            username: username,
            created-at: block-height,
            last-updated: block-height,
            profile-hash: none,
            is-active: true,
            reputation: BASE-REPUTATION,
            verified-chains: u0,
            total-links: u0
        })
        
        (var-set total-users (+ (var-get total-users) u1))
        (ok true)
    )
)

(define-public (update-profile (profile-hash (buff 32)))
    (let ((profile (unwrap! (map-get? user-profiles tx-sender) ERR-IDENTITY-NOT-FOUND)))
        (asserts! (get is-active profile) ERR-PROFILE-INACTIVE)
        (map-set user-profiles tx-sender
            (merge profile {
                profile-hash: (some profile-hash),
                last-updated: block-height
            })
        )
        (ok true)
    )
)

(define-public (deactivate-profile)
    (let ((profile (unwrap! (map-get? user-profiles tx-sender) ERR-IDENTITY-NOT-FOUND)))
        (map-set user-profiles tx-sender
            (merge profile {
                is-active: false,
                last-updated: block-height
            })
        )
        (ok true)
    )
)

(define-public (reactivate-profile)
    (let ((profile (unwrap! (map-get? user-profiles tx-sender) ERR-IDENTITY-NOT-FOUND)))
        (map-set user-profiles tx-sender
            (merge profile {
                is-active: true,
                last-updated: block-height
            })
        )
        (ok true)
    )
)

(define-public (add-chain-address (chain uint) (address (string-ascii 128)) (proof-method (optional (string-ascii 50))))
    (let ((profile (unwrap! (map-get? user-profiles tx-sender) ERR-IDENTITY-NOT-FOUND))
          (chain-info (unwrap! (map-get? supported-chains chain) ERR-INVALID-CHAIN)))
        (asserts! (get is-active profile) ERR-PROFILE-INACTIVE)
        (asserts! (get active chain-info) ERR-INVALID-CHAIN)
        (asserts! (is-none (map-get? chain-links { user: tx-sender, chain: chain })) ERR-LINK-EXISTS)
        
        (map-set chain-links 
            { user: tx-sender, chain: chain }
            {
                address: address,
                verified: false,
                added-at: block-height,
                verified-at: none,
                proof-method: proof-method
            }
        )
        
        ;; Update profile stats
        (map-set user-profiles tx-sender
            (merge profile {
                total-links: (+ (get total-links profile) u1),
                last-updated: block-height
            })
        )
        
        (ok true)
    )
)

(define-public (verify-chain-address (user principal) (chain uint))
    (let ((link (unwrap! (map-get? chain-links { user: user, chain: chain }) ERR-IDENTITY-NOT-FOUND))
          (profile (unwrap! (map-get? user-profiles user) ERR-IDENTITY-NOT-FOUND)))
        (asserts! (is-eq tx-sender (var-get contract-admin)) ERR-NOT-AUTHORIZED)
        (asserts! (not (get verified link)) ERR-NOT-AUTHORIZED) ;; Prevent double verification
        
        (map-set chain-links 
            { user: user, chain: chain }
            (merge link { 
                verified: true,
                verified-at: (some block-height)
            })
        )
        
        ;; Update user reputation and stats
        (map-set user-profiles user
            (merge profile {
                reputation: (+ (get reputation profile) u50), ;; Bonus for verification
                verified-chains: (+ (get verified-chains profile) u1),
                last-updated: block-height
            })
        )
        
        (var-set total-verifications (+ (var-get total-verifications) u1))
        (ok true)
    )
)

;; Social features
(define-public (add-connection (to-user principal) (connection-type uint))
    (let ((from-profile (unwrap! (map-get? user-profiles tx-sender) ERR-IDENTITY-NOT-FOUND))
          (to-profile (unwrap! (map-get? user-profiles to-user) ERR-IDENTITY-NOT-FOUND)))
        (asserts! (get is-active from-profile) ERR-PROFILE-INACTIVE)
        (asserts! (get is-active to-profile) ERR-PROFILE-INACTIVE)
        (asserts! (not (is-eq tx-sender to-user)) ERR-NOT-AUTHORIZED)
        (asserts! (or (is-eq connection-type u1) (is-eq connection-type u2)) ERR-NOT-AUTHORIZED)
        
        (map-set connections
            { from: tx-sender, to: to-user }
            {
                connection-type: connection-type,
                created-at: block-height
            }
        )
        
        (var-set total-connections (+ (var-get total-connections) u1))
        (ok true)
    )
)

(define-public (remove-connection (to-user principal))
    (begin
        (asserts! (is-some (map-get? connections { from: tx-sender, to: to-user })) ERR-IDENTITY-NOT-FOUND)
        (map-delete connections { from: tx-sender, to: to-user })
        (var-set total-connections (- (var-get total-connections) u1))
        (ok true)
    )
)

;; Utility functions
(define-private (calculate-user-score (user principal))
    (match (map-get? user-profiles user)
        profile (let (
            (base-score (get reputation profile))
            (chain-bonus (* (get verified-chains profile) u25))
            (age-bonus (/ (- block-height (get created-at profile)) u1000))
        )
            (+ base-score chain-bonus age-bonus)
        )
        u0
    )
)

;; Read functions
(define-read-only (get-profile (user principal))
    (map-get? user-profiles user)
)

(define-read-only (get-profile-by-username (username (string-ascii 50)))
    (match (map-get? username-registry username)
        user (map-get? user-profiles user)
        none
    )
)

(define-read-only (get-username-owner (username (string-ascii 50)))
    (map-get? username-registry username)
)

(define-read-only (get-chain-address (user principal) (chain uint))
    (map-get? chain-links { user: user, chain: chain })
)

(define-read-only (get-connection (from-user principal) (to-user principal))
    (map-get? connections { from: from-user, to: to-user })
)

(define-read-only (get-supported-chain (chain-id uint))
    (map-get? supported-chains chain-id)
)

(define-read-only (get-user-score (user principal))
    (calculate-user-score user)
)

(define-read-only (is-username-available (username (string-ascii 50)))
    (is-none (map-get? username-registry username))
)

(define-read-only (get-total-users)
    (var-get total-users)
)

(define-read-only (get-total-connections)
    (var-get total-connections)
)

(define-read-only (get-total-verifications)
    (var-get total-verifications)
)

(define-read-only (get-contract-stats)
    {
        total-users: (var-get total-users),
        total-connections: (var-get total-connections),
        total-verifications: (var-get total-verifications),
        contract-admin: (var-get contract-admin)
    }
)