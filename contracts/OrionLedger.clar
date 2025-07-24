;; OrionLedger - Immutable Property Registry
;; A decentralized platform for registering and verifying property ownership on-chain

;; Constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_PROPERTY_NOT_FOUND (err u101))
(define-constant ERR_PROPERTY_ALREADY_EXISTS (err u102))
(define-constant ERR_INVALID_OWNER (err u103))
(define-constant ERR_TRANSFER_FAILED (err u104))
(define-constant ERR_INVALID_METADATA (err u105))

;; Data Variables
(define-data-var next-property-id uint u1)

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