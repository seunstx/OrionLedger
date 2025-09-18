;; OrionLedger - Immutable Property Registry with Escrow System and Dispute Resolution
;; A decentralized platform for registering and verifying property ownership on-chain

;; Constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_PROPERTY_NOT_FOUND (err u101))
(define-constant ERR_PROPERTY_ALREADY_EXISTS (err u102))
(define-constant ERR_INVALID_OWNER (err u103))
(define-constant ERR_TRANSFER_FAILED (err u104))
(define-constant ERR_INVALID_METADATA (err u105))
(define-constant ERR_ESCROW_NOT_FOUND (err u106))
(define-constant ERR_ESCROW_ALREADY_EXISTS (err u107))
(define-constant ERR_INSUFFICIENT_FUNDS (err u108))
(define-constant ERR_ESCROW_NOT_ACTIVE (err u109))
(define-constant ERR_ALREADY_SIGNED (err u110))
(define-constant ERR_INVALID_SIGNATORY (err u111))
(define-constant ERR_ESCROW_EXPIRED (err u112))
(define-constant ERR_INVALID_PRICE (err u113))
(define-constant ERR_INVALID_DURATION (err u114))
(define-constant ERR_DISPUTE_NOT_FOUND (err u115))
(define-constant ERR_DISPUTE_ALREADY_EXISTS (err u116))
(define-constant ERR_INVALID_EVIDENCE (err u117))
(define-constant ERR_DISPUTE_NOT_ACTIVE (err u118))
(define-constant ERR_INVALID_ARBITRATOR (err u119))
(define-constant ERR_DISPUTE_EXPIRED (err u120))
(define-constant ERR_ALREADY_VOTED (err u121))
(define-constant ERR_NOT_ARBITRATOR (err u122))
(define-constant ERR_INVALID_RULING (err u123))

;; Data Variables
(define-data-var next-property-id uint u1)
(define-data-var next-escrow-id uint u1)
(define-data-var next-dispute-id uint u1)

;; Property NFT Definition
(define-non-fungible-token property-deed uint)

;; Property Registry Map
(define-map property-registry
    uint
    {
        address: (string-ascii 256),
        coordinates: {lat: int, lng: int},
        property-type: (string-ascii 64),
        area-sqft: uint,
        registration-date: uint,
        last-verified: uint
    }
)

;; Property History Map
(define-map property-history
    {property-id: uint, history-id: uint}
    {
        previous-owner: principal,
        new-owner: principal,
        transfer-date: uint,
        transfer-type: (string-ascii 32)
    }
)

;; Property History Counter
(define-map property-history-count uint uint)

;; Escrow Registry Map
(define-map escrow-registry
    uint
    {
        property-id: uint,
        seller: principal,
        buyer: principal,
        arbiter: principal,
        sale-price: uint,
        deposit-amount: uint,
        created-at: uint,
        expires-at: uint,
        status: (string-ascii 32),
        seller-signed: bool,
        buyer-signed: bool,
        arbiter-signed: bool
    }
)

;; Escrow Funds Map
(define-map escrow-funds uint uint)

;; Property to Escrow Mapping
(define-map property-escrow uint uint)

;; Dispute Registry Map
(define-map dispute-registry
    uint
    {
        property-id: uint,
        claimant: principal,
        respondent: principal,
        dispute-type: (string-ascii 64),
        created-at: uint,
        expires-at: uint,
        status: (string-ascii 32),
        arbitrators: (list 5 principal),
        arbitrator-count: uint,
        votes-for-claimant: uint,
        votes-for-respondent: uint,
        ruling: (optional (string-ascii 32))
    }
)

;; Dispute Evidence Map
(define-map dispute-evidence
    {dispute-id: uint, evidence-id: uint}
    {
        submitter: principal,
        evidence-hash: (string-ascii 64),
        description: (string-ascii 256),
        submitted-at: uint
    }
)

;; Dispute Evidence Counter
(define-map dispute-evidence-count uint uint)

;; Arbitrator Votes Map
(define-map arbitrator-votes
    {dispute-id: uint, arbitrator: principal}
    {
        vote: (string-ascii 32),
        voted-at: uint,
        reasoning: (string-ascii 256)
    }
)

;; Property to Dispute Mapping
(define-map property-dispute uint uint)

;; Read-only functions

;; Get property details by ID
(define-read-only (get-property-details (property-id uint))
    (map-get? property-registry property-id)
)

;; Get property owner
(define-read-only (get-property-owner (property-id uint))
    (nft-get-owner? property-deed property-id)
)

;; Get total properties registered
(define-read-only (get-total-properties)
    (- (var-get next-property-id) u1)
)

;; Get property history count
(define-read-only (get-property-history-count (property-id uint))
    (default-to u0 (map-get? property-history-count property-id))
)

;; Get specific property history entry
(define-read-only (get-property-history-entry (property-id uint) (history-id uint))
    (map-get? property-history {property-id: property-id, history-id: history-id})
)

;; Verify property ownership
(define-read-only (verify-ownership (property-id uint) (owner principal))
    (match (nft-get-owner? property-deed property-id)
        current-owner (is-eq current-owner owner)
        false
    )
)

;; Get escrow details
(define-read-only (get-escrow-details (escrow-id uint))
    (map-get? escrow-registry escrow-id)
)

;; Get escrow by property ID
(define-read-only (get-property-escrow (property-id uint))
    (map-get? property-escrow property-id)
)

;; Get total escrows created
(define-read-only (get-total-escrows)
    (- (var-get next-escrow-id) u1)
)

;; Check if escrow is expired
(define-read-only (is-escrow-expired (escrow-id uint))
    (match (map-get? escrow-registry escrow-id)
        escrow-data 
        (> stacks-block-height (get expires-at escrow-data))
        false
    )
)

;; Get escrow funds balance
(define-read-only (get-escrow-funds (escrow-id uint))
    (default-to u0 (map-get? escrow-funds escrow-id))
)

;; Check if all parties have signed
(define-read-only (all-parties-signed (escrow-id uint))
    (match (map-get? escrow-registry escrow-id)
        escrow-data
        (and 
            (get seller-signed escrow-data)
            (get buyer-signed escrow-data)
            (get arbiter-signed escrow-data)
        )
        false
    )
)

;; Get dispute details
(define-read-only (get-dispute-details (dispute-id uint))
    (map-get? dispute-registry dispute-id)
)

;; Get dispute by property ID
(define-read-only (get-property-dispute (property-id uint))
    (map-get? property-dispute property-id)
)

;; Get total disputes created
(define-read-only (get-total-disputes)
    (- (var-get next-dispute-id) u1)
)

;; Check if dispute is expired
(define-read-only (is-dispute-expired (dispute-id uint))
    (match (map-get? dispute-registry dispute-id)
        dispute-data 
        (> stacks-block-height (get expires-at dispute-data))
        false
    )
)

;; Get dispute evidence count
(define-read-only (get-dispute-evidence-count (dispute-id uint))
    (default-to u0 (map-get? dispute-evidence-count dispute-id))
)

;; Get specific dispute evidence entry
(define-read-only (get-dispute-evidence-entry (dispute-id uint) (evidence-id uint))
    (map-get? dispute-evidence {dispute-id: dispute-id, evidence-id: evidence-id})
)

;; Get arbitrator vote
(define-read-only (get-arbitrator-vote (dispute-id uint) (arbitrator principal))
    (map-get? arbitrator-votes {dispute-id: dispute-id, arbitrator: arbitrator})
)

;; Check if arbitrator has voted
(define-read-only (has-arbitrator-voted (dispute-id uint) (arbitrator principal))
    (is-some (map-get? arbitrator-votes {dispute-id: dispute-id, arbitrator: arbitrator}))
)

;; Check if principal is arbitrator for dispute
(define-read-only (is-arbitrator (dispute-id uint) (arbitrator principal))
    (match (map-get? dispute-registry dispute-id)
        dispute-data
        (is-some (index-of (get arbitrators dispute-data) arbitrator))
        false
    )
)

;; Public functions

;; Register new property
(define-public (register-property 
    (address (string-ascii 256))
    (lat int)
    (lng int)
    (property-type (string-ascii 64))
    (area-sqft uint))
    (let
        (
            (property-id (var-get next-property-id))
            (current-block stacks-block-height)
        )
        ;; Validate inputs
        (asserts! (> (len address) u0) ERR_INVALID_METADATA)
        (asserts! (> (len property-type) u0) ERR_INVALID_METADATA)
        (asserts! (> area-sqft u0) ERR_INVALID_METADATA)
        
        ;; Mint NFT to sender
        (match (nft-mint? property-deed property-id tx-sender)
            success
            (begin
                ;; Store property details
                (map-set property-registry property-id
                    {
                        address: address,
                        coordinates: {lat: lat, lng: lng},
                        property-type: property-type,
                        area-sqft: area-sqft,
                        registration-date: current-block,
                        last-verified: current-block
                    }
                )
                
                ;; Initialize history
                (map-set property-history-count property-id u1)
                (map-set property-history 
                    {property-id: property-id, history-id: u1}
                    {
                        previous-owner: tx-sender,
                        new-owner: tx-sender,
                        transfer-date: current-block,
                        transfer-type: "initial-registration"
                    }
                )
                
                ;; Increment property counter
                (var-set next-property-id (+ property-id u1))
                (ok property-id)
            )
            error ERR_TRANSFER_FAILED
        )
    )
)

;; Transfer property ownership
(define-public (transfer-property (property-id uint) (new-owner principal))
    (let
        (
            (current-owner (unwrap! (nft-get-owner? property-deed property-id) ERR_PROPERTY_NOT_FOUND))
            (history-count (get-property-history-count property-id))
            (new-history-id (+ history-count u1))
            (current-block stacks-block-height)
        )
        ;; Verify sender is current owner
        (asserts! (is-eq tx-sender current-owner) ERR_UNAUTHORIZED)
        (asserts! (not (is-eq current-owner new-owner)) ERR_INVALID_OWNER)
        
        ;; Check if property has active escrow or dispute
        (asserts! (is-none (map-get? property-escrow property-id)) ERR_ESCROW_ALREADY_EXISTS)
        (asserts! (is-none (map-get? property-dispute property-id)) ERR_DISPUTE_ALREADY_EXISTS)
        
        ;; Transfer NFT
        (match (nft-transfer? property-deed property-id current-owner new-owner)
            success
            (begin
                ;; Record transfer in history
                (map-set property-history-count property-id new-history-id)
                (map-set property-history
                    {property-id: property-id, history-id: new-history-id}
                    {
                        previous-owner: current-owner,
                        new-owner: new-owner,
                        transfer-date: current-block,
                        transfer-type: "direct-transfer"
                    }
                )
                (ok true)
            )
            error ERR_TRANSFER_FAILED
        )
    )
)

;; Update property verification timestamp
(define-public (verify-property (property-id uint))
    (let
        (
            (property-data (unwrap! (map-get? property-registry property-id) ERR_PROPERTY_NOT_FOUND))
            (current-block stacks-block-height)
        )
        ;; Only property owner or contract owner can verify
        (asserts! 
            (or 
                (is-eq tx-sender CONTRACT_OWNER)
                (verify-ownership property-id tx-sender)
            ) 
            ERR_UNAUTHORIZED
        )
        
        ;; Update verification timestamp
        (map-set property-registry property-id
            (merge property-data {last-verified: current-block})
        )
        (ok true)
    )
)

;; Update property metadata (owner only)
(define-public (update-property-metadata
    (property-id uint)
    (new-address (string-ascii 256))
    (new-property-type (string-ascii 64))
    (new-area-sqft uint))
    (let
        (
            (property-data (unwrap! (map-get? property-registry property-id) ERR_PROPERTY_NOT_FOUND))
        )
        ;; Verify ownership
        (asserts! (verify-ownership property-id tx-sender) ERR_UNAUTHORIZED)
        
        ;; Validate inputs
        (asserts! (> (len new-address) u0) ERR_INVALID_METADATA)
        (asserts! (> (len new-property-type) u0) ERR_INVALID_METADATA)
        (asserts! (> new-area-sqft u0) ERR_INVALID_METADATA)
        
        ;; Update metadata
        (map-set property-registry property-id
            (merge property-data 
                {
                    address: new-address,
                    property-type: new-property-type,
                    area-sqft: new-area-sqft,
                    last-verified: stacks-block-height
                }
            )
        )
        (ok true)
    )
)

;; Create escrow for property sale
(define-public (create-escrow
    (property-id uint)
    (buyer principal)
    (arbiter principal)
    (sale-price uint)
    (deposit-amount uint)
    (duration-blocks uint))
    (let
        (
            (escrow-id (var-get next-escrow-id))
            (current-block stacks-block-height)
            (expires-at (+ current-block duration-blocks))
        )
        ;; Validate inputs
        (asserts! (> sale-price u0) ERR_INVALID_PRICE)
        (asserts! (<= deposit-amount sale-price) ERR_INVALID_METADATA)
        (asserts! (> duration-blocks u0) ERR_INVALID_DURATION)
        (asserts! (not (is-eq tx-sender buyer)) ERR_INVALID_OWNER)
        (asserts! (not (is-eq tx-sender arbiter)) ERR_INVALID_OWNER)
        (asserts! (not (is-eq buyer arbiter)) ERR_INVALID_OWNER)
        
        ;; Verify sender owns the property
        (asserts! (verify-ownership property-id tx-sender) ERR_UNAUTHORIZED)
        
        ;; Check if property already has active escrow or dispute
        (asserts! (is-none (map-get? property-escrow property-id)) ERR_ESCROW_ALREADY_EXISTS)
        (asserts! (is-none (map-get? property-dispute property-id)) ERR_DISPUTE_ALREADY_EXISTS)
        
        ;; Create escrow
        (map-set escrow-registry escrow-id
            {
                property-id: property-id,
                seller: tx-sender,
                buyer: buyer,
                arbiter: arbiter,
                sale-price: sale-price,
                deposit-amount: deposit-amount,
                created-at: current-block,
                expires-at: expires-at,
                status: "active",
                seller-signed: false,
                buyer-signed: false,
                arbiter-signed: false
            }
        )
        
        ;; Map property to escrow
        (map-set property-escrow property-id escrow-id)
        
        ;; Initialize escrow funds
        (map-set escrow-funds escrow-id u0)
        
        ;; Increment escrow counter
        (var-set next-escrow-id (+ escrow-id u1))
        (ok escrow-id)
    )
)

;; Deposit funds to escrow (buyer only)
(define-public (deposit-to-escrow (escrow-id uint) (amount uint))
    (let
        (
            (escrow-data (unwrap! (map-get? escrow-registry escrow-id) ERR_ESCROW_NOT_FOUND))
            (current-funds (get-escrow-funds escrow-id))
            (new-balance (+ current-funds amount))
        )
        ;; Validate escrow is active and not expired
        (asserts! (is-eq (get status escrow-data) "active") ERR_ESCROW_NOT_ACTIVE)
        (asserts! (<= stacks-block-height (get expires-at escrow-data)) ERR_ESCROW_EXPIRED)
        
        ;; Only buyer can deposit
        (asserts! (is-eq tx-sender (get buyer escrow-data)) ERR_UNAUTHORIZED)
        
        ;; Validate deposit amount
        (asserts! (> amount u0) ERR_INVALID_METADATA)
        (asserts! (<= new-balance (get deposit-amount escrow-data)) ERR_INVALID_METADATA)
        
        ;; Transfer STX to contract
        (match (stx-transfer? amount tx-sender (as-contract tx-sender))
            success
            (begin
                ;; Update escrow funds
                (map-set escrow-funds escrow-id new-balance)
                (ok true)
            )
            error ERR_INSUFFICIENT_FUNDS
        )
    )
)

;; Sign escrow agreement
(define-public (sign-escrow (escrow-id uint))
    (let
        (
            (escrow-data (unwrap! (map-get? escrow-registry escrow-id) ERR_ESCROW_NOT_FOUND))
        )
        ;; Validate escrow is active and not expired
        (asserts! (is-eq (get status escrow-data) "active") ERR_ESCROW_NOT_ACTIVE)
        (asserts! (<= stacks-block-height (get expires-at escrow-data)) ERR_ESCROW_EXPIRED)
        
        ;; Check if sender is a valid signatory
        (asserts! 
            (or 
                (is-eq tx-sender (get seller escrow-data))
                (is-eq tx-sender (get buyer escrow-data))
                (is-eq tx-sender (get arbiter escrow-data))
            ) 
            ERR_INVALID_SIGNATORY
        )
        
        ;; Update signature based on sender role
        (if (is-eq tx-sender (get seller escrow-data))
            (begin
                (asserts! (not (get seller-signed escrow-data)) ERR_ALREADY_SIGNED)
                (map-set escrow-registry escrow-id
                    (merge escrow-data {seller-signed: true})
                )
                (ok "seller-signed")
            )
            (if (is-eq tx-sender (get buyer escrow-data))
                (begin
                    (asserts! (not (get buyer-signed escrow-data)) ERR_ALREADY_SIGNED)
                    (map-set escrow-registry escrow-id
                        (merge escrow-data {buyer-signed: true})
                    )
                    (ok "buyer-signed")
                )
                (begin
                    (asserts! (not (get arbiter-signed escrow-data)) ERR_ALREADY_SIGNED)
                    (map-set escrow-registry escrow-id
                        (merge escrow-data {arbiter-signed: true})
                    )
                    (ok "arbiter-signed")
                )
            )
        )
    )
)

;; Complete escrow and transfer property
(define-public (complete-escrow (escrow-id uint))
    (let
        (
            (escrow-data (unwrap! (map-get? escrow-registry escrow-id) ERR_ESCROW_NOT_FOUND))
            (property-id (get property-id escrow-data))
            (seller (get seller escrow-data))
            (buyer (get buyer escrow-data))
            (sale-price (get sale-price escrow-data))
            (escrow-balance (get-escrow-funds escrow-id))
            (history-count (get-property-history-count property-id))
            (new-history-id (+ history-count u1))
            (current-block stacks-block-height)
        )
        ;; Validate escrow conditions
        (asserts! (is-eq (get status escrow-data) "active") ERR_ESCROW_NOT_ACTIVE)
        (asserts! (<= stacks-block-height (get expires-at escrow-data)) ERR_ESCROW_EXPIRED)
        (asserts! (all-parties-signed escrow-id) ERR_UNAUTHORIZED)
        (asserts! (>= escrow-balance (get deposit-amount escrow-data)) ERR_INSUFFICIENT_FUNDS)
        
        ;; Only buyer can complete the escrow
        (asserts! (is-eq tx-sender buyer) ERR_UNAUTHORIZED)
        
        ;; Transfer remaining balance from buyer to contract
        (let ((remaining-amount (- sale-price escrow-balance)))
            (if (> remaining-amount u0)
                (unwrap! (stx-transfer? remaining-amount buyer (as-contract tx-sender)) ERR_INSUFFICIENT_FUNDS)
                true
            )
        )
        
        ;; Transfer property NFT
        (match (as-contract (nft-transfer? property-deed property-id seller buyer))
            success
            (begin
                ;; Transfer funds to seller
                (unwrap! (as-contract (stx-transfer? sale-price tx-sender seller)) ERR_TRANSFER_FAILED)
                
                ;; Update escrow status
                (map-set escrow-registry escrow-id
                    (merge escrow-data {status: "completed"})
                )
                
                ;; Remove property escrow mapping
                (map-delete property-escrow property-id)
                
                ;; Clear escrow funds
                (map-set escrow-funds escrow-id u0)
                
                ;; Record transfer in history
                (map-set property-history-count property-id new-history-id)
                (map-set property-history
                    {property-id: property-id, history-id: new-history-id}
                    {
                        previous-owner: seller,
                        new-owner: buyer,
                        transfer-date: current-block,
                        transfer-type: "escrow-transfer"
                    }
                )
                
                (ok true)
            )
            error ERR_TRANSFER_FAILED
        )
    )
)

;; Cancel escrow (seller, buyer, or arbiter can cancel)
(define-public (cancel-escrow (escrow-id uint))
    (let
        (
            (escrow-data (unwrap! (map-get? escrow-registry escrow-id) ERR_ESCROW_NOT_FOUND))
            (property-id (get property-id escrow-data))
            (buyer (get buyer escrow-data))
            (escrow-balance (get-escrow-funds escrow-id))
        )
        ;; Validate caller authority
        (asserts! 
            (or 
                (is-eq tx-sender (get seller escrow-data))
                (is-eq tx-sender (get buyer escrow-data))
                (is-eq tx-sender (get arbiter escrow-data))
                (> stacks-block-height (get expires-at escrow-data))
            ) 
            ERR_UNAUTHORIZED
        )
        
        ;; Only cancel if active
        (asserts! (is-eq (get status escrow-data) "active") ERR_ESCROW_NOT_ACTIVE)
        
        ;; Refund deposited funds to buyer
        (if (> escrow-balance u0)
            (unwrap! (as-contract (stx-transfer? escrow-balance tx-sender buyer)) ERR_TRANSFER_FAILED)
            true
        )
        
        ;; Update escrow status
        (map-set escrow-registry escrow-id
            (merge escrow-data {status: "cancelled"})
        )
        
        ;; Remove property escrow mapping
        (map-delete property-escrow property-id)
        
        ;; Clear escrow funds
        (map-set escrow-funds escrow-id u0)
        
        (ok true)
    )
)

;; Create dispute for property ownership
(define-public (create-dispute
    (property-id uint)
    (respondent principal)
    (dispute-type (string-ascii 64))
    (arbitrators (list 5 principal))
    (duration-blocks uint))
    (let
        (
            (dispute-id (var-get next-dispute-id))
            (current-block stacks-block-height)
            (expires-at (+ current-block duration-blocks))
            (arbitrator-count (len arbitrators))
        )
        ;; Validate inputs
        (asserts! (is-some (map-get? property-registry property-id)) ERR_PROPERTY_NOT_FOUND)
        (asserts! (> (len dispute-type) u0) ERR_INVALID_METADATA)
        (asserts! (and (>= arbitrator-count u3) (<= arbitrator-count u5)) ERR_INVALID_ARBITRATOR)
        (asserts! (> duration-blocks u0) ERR_INVALID_DURATION)
        (asserts! (not (is-eq tx-sender respondent)) ERR_INVALID_OWNER)
        
        ;; Check if property already has active dispute or escrow
        (asserts! (is-none (map-get? property-dispute property-id)) ERR_DISPUTE_ALREADY_EXISTS)
        (asserts! (is-none (map-get? property-escrow property-id)) ERR_ESCROW_ALREADY_EXISTS)
        
        ;; Create dispute
        (map-set dispute-registry dispute-id
            {
                property-id: property-id,
                claimant: tx-sender,
                respondent: respondent,
                dispute-type: dispute-type,
                created-at: current-block,
                expires-at: expires-at,
                status: "active",
                arbitrators: arbitrators,
                arbitrator-count: arbitrator-count,
                votes-for-claimant: u0,
                votes-for-respondent: u0,
                ruling: none
            }
        )
        
        ;; Map property to dispute
        (map-set property-dispute property-id dispute-id)
        
        ;; Initialize evidence counter
        (map-set dispute-evidence-count dispute-id u0)
        
        ;; Increment dispute counter
        (var-set next-dispute-id (+ dispute-id u1))
        (ok dispute-id)
    )
)

;; Submit evidence for dispute
(define-public (submit-evidence
    (dispute-id uint)
    (evidence-hash (string-ascii 64))
    (description (string-ascii 256)))
    (let
        (
            (dispute-data (unwrap! (map-get? dispute-registry dispute-id) ERR_DISPUTE_NOT_FOUND))
            (evidence-count (get-dispute-evidence-count dispute-id))
            (new-evidence-id (+ evidence-count u1))
            (current-block stacks-block-height)
        )
        ;; Validate dispute is active and not expired
        (asserts! (is-eq (get status dispute-data) "active") ERR_DISPUTE_NOT_ACTIVE)
        (asserts! (<= stacks-block-height (get expires-at dispute-data)) ERR_DISPUTE_EXPIRED)
        
        ;; Only claimant or respondent can submit evidence
        (asserts! 
            (or 
                (is-eq tx-sender (get claimant dispute-data))
                (is-eq tx-sender (get respondent dispute-data))
            ) 
            ERR_UNAUTHORIZED
        )
        
        ;; Validate evidence inputs
        (asserts! (> (len evidence-hash) u0) ERR_INVALID_EVIDENCE)
        (asserts! (> (len description) u0) ERR_INVALID_EVIDENCE)
        
        ;; Store evidence
        (map-set dispute-evidence
            {dispute-id: dispute-id, evidence-id: new-evidence-id}
            {
                submitter: tx-sender,
                evidence-hash: evidence-hash,
                description: description,
                submitted-at: current-block
            }
        )
        
        ;; Update evidence counter
        (map-set dispute-evidence-count dispute-id new-evidence-id)
        
        (ok new-evidence-id)
    )
)

;; Arbitrator vote on dispute
(define-public (vote-on-dispute
    (dispute-id uint)
    (vote (string-ascii 32))
    (reasoning (string-ascii 256)))
    (let
        (
            (dispute-data (unwrap! (map-get? dispute-registry dispute-id) ERR_DISPUTE_NOT_FOUND))
            (current-block stacks-block-height)
        )
        ;; Validate dispute is active and not expired
        (asserts! (is-eq (get status dispute-data) "active") ERR_DISPUTE_NOT_ACTIVE)
        (asserts! (<= stacks-block-height (get expires-at dispute-data)) ERR_DISPUTE_EXPIRED)
        
        ;; Only arbitrators can vote
        (asserts! (is-arbitrator dispute-id tx-sender) ERR_NOT_ARBITRATOR)
        
        ;; Check if arbitrator has already voted
        (asserts! (not (has-arbitrator-voted dispute-id tx-sender)) ERR_ALREADY_VOTED)
        
        ;; Validate vote
        (asserts! 
            (or 
                (is-eq vote "claimant")
                (is-eq vote "respondent")
            ) 
            ERR_INVALID_RULING
        )
        
        ;; Validate reasoning
        (asserts! (> (len reasoning) u0) ERR_INVALID_METADATA)
        
        ;; Record vote
        (map-set arbitrator-votes
            {dispute-id: dispute-id, arbitrator: tx-sender}
            {
                vote: vote,
                voted-at: current-block,
                reasoning: reasoning
            }
        )
        
        ;; Update vote counts and check for majority
        (let
            (
                (new-claimant-votes 
                    (if (is-eq vote "claimant") 
                        (+ (get votes-for-claimant dispute-data) u1)
                        (get votes-for-claimant dispute-data)
                    )
                )
                (new-respondent-votes
                    (if (is-eq vote "respondent")
                        (+ (get votes-for-respondent dispute-data) u1)
                        (get votes-for-respondent dispute-data)
                    )
                )
                (total-arbitrators (get arbitrator-count dispute-data))
                (majority-threshold (/ (+ total-arbitrators u1) u2))
            )
            
            ;; Update dispute with new vote counts
            (map-set dispute-registry dispute-id
                (merge dispute-data 
                    {
                        votes-for-claimant: new-claimant-votes,
                        votes-for-respondent: new-respondent-votes
                    }
                )
            )
            
            ;; Check if majority reached and finalize dispute
            (if (>= new-claimant-votes majority-threshold)
                (finalize-dispute dispute-id "claimant")
                (if (>= new-respondent-votes majority-threshold)
                    (finalize-dispute dispute-id "respondent")
                    (ok vote)
                )
            )
        )
    )
)

;; Finalize dispute with ruling (internal function)
(define-private (finalize-dispute (dispute-id uint) (ruling (string-ascii 32)))
    (let
        (
            (dispute-data (unwrap! (map-get? dispute-registry dispute-id) ERR_DISPUTE_NOT_FOUND))
            (property-id (get property-id dispute-data))
            (claimant (get claimant dispute-data))
            (current-owner (unwrap! (nft-get-owner? property-deed property-id) ERR_PROPERTY_NOT_FOUND))
            (history-count (get-property-history-count property-id))
            (new-history-id (+ history-count u1))
            (current-block stacks-block-height)
        )
        
        ;; Update dispute status and ruling
        (map-set dispute-registry dispute-id
            (merge dispute-data 
                {
                    status: "resolved",
                    ruling: (some ruling)
                }
            )
        )
        
        ;; Remove property dispute mapping
        (map-delete property-dispute property-id)
        
        ;; Transfer property if claimant wins and is not current owner
        (if (and (is-eq ruling "claimant") (not (is-eq claimant current-owner)))
            (match (as-contract (nft-transfer? property-deed property-id current-owner claimant))
                success
                (begin
                    ;; Record transfer in history
                    (map-set property-history-count property-id new-history-id)
                    (map-set property-history
                        {property-id: property-id, history-id: new-history-id}
                        {
                            previous-owner: current-owner,
                            new-owner: claimant,
                            transfer-date: current-block,
                            transfer-type: "dispute-resolution"
                        }
                    )
                    (ok ruling)
                )
                error ERR_TRANSFER_FAILED
            )
            (ok ruling)
        )
    )
)

;; Close expired dispute
(define-public (close-expired-dispute (dispute-id uint))
    (let
        (
            (dispute-data (unwrap! (map-get? dispute-registry dispute-id) ERR_DISPUTE_NOT_FOUND))
            (property-id (get property-id dispute-data))
        )
        ;; Check if dispute is expired
        (asserts! (> stacks-block-height (get expires-at dispute-data)) ERR_UNAUTHORIZED)
        (asserts! (is-eq (get status dispute-data) "active") ERR_DISPUTE_NOT_ACTIVE)
        
        ;; Update dispute status
        (map-set dispute-registry dispute-id
            (merge dispute-data {status: "expired"})
        )
        
        ;; Remove property dispute mapping
        (map-delete property-dispute property-id)
        
        (ok true)
    )
)