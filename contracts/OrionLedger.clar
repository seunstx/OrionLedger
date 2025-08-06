;; OrionLedger - Immutable Property Registry with Escrow System
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

;; Data Variables
(define-data-var next-property-id uint u1)
(define-data-var next-escrow-id uint u1)

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
        
        ;; Check if property has active escrow
        (asserts! (is-none (map-get? property-escrow property-id)) ERR_ESCROW_ALREADY_EXISTS)
        
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
        
        ;; Check if property already has active escrow
        (asserts! (is-none (map-get? property-escrow property-id)) ERR_ESCROW_ALREADY_EXISTS)
        
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