;; Credential Verification Contract
;; Validates authenticity of prior learning

;; Define data vars and maps
(define-map verified-credentials
  { student-id: (string-ascii 36), credential-id: (string-ascii 36) }
  {
    issuer: principal,
    credential-type: (string-utf8 50),
    subject: (string-utf8 50),
    date-issued: (string-ascii 10),
    hash: (buff 32),
    is-verified: bool
  }
)

;; Define authorized verifiers
(define-map authorized-verifiers
  { verifier-address: principal }
  { is-authorized: bool }
)

;; Error codes
(define-constant ERR_UNAUTHORIZED u1)
(define-constant ERR_ALREADY_EXISTS u2)
(define-constant ERR_NOT_FOUND u3)

;; Check if caller is an authorized verifier
(define-private (is-authorized (caller principal))
  (default-to false (get is-authorized (map-get? authorized-verifiers { verifier-address: caller })))
)

;; Register a new authorized verifier
(define-public (register-verifier (verifier principal))
  (begin
    (asserts! (is-authorized tx-sender) (err ERR_UNAUTHORIZED))
    (ok (map-set authorized-verifiers { verifier-address: verifier } { is-authorized: true }))
  )
)

;; Issue a new credential
(define-public (issue-credential
  (student-id (string-ascii 36))
  (credential-id (string-ascii 36))
  (credential-type (string-utf8 50))
  (subject (string-utf8 50))
  (date-issued (string-ascii 10))
  (credential-hash (buff 32)))

  (begin
    (asserts! (is-authorized tx-sender) (err ERR_UNAUTHORIZED))
    (asserts! (is-none (map-get? verified-credentials { student-id: student-id, credential-id: credential-id })) (err ERR_ALREADY_EXISTS))

    (ok (map-set verified-credentials
      { student-id: student-id, credential-id: credential-id }
      {
        issuer: tx-sender,
        credential-type: credential-type,
        subject: subject,
        date-issued: date-issued,
        hash: credential-hash,
        is-verified: true
      }
    ))
  )
)

;; Verify an existing credential
(define-public (verify-credential (student-id (string-ascii 36)) (credential-id (string-ascii 36)) (verified bool))
  (begin
    (asserts! (is-authorized tx-sender) (err ERR_UNAUTHORIZED))

    (let ((existing-credential (unwrap! (map-get? verified-credentials { student-id: student-id, credential-id: credential-id }) (err ERR_NOT_FOUND))))
      (ok (map-set verified-credentials
        { student-id: student-id, credential-id: credential-id }
        {
          issuer: (get issuer existing-credential),
          credential-type: (get credential-type existing-credential),
          subject: (get subject existing-credential),
          date-issued: (get date-issued existing-credential),
          hash: (get hash existing-credential),
          is-verified: verified
        }
      ))
    )
  )
)

;; Check if a credential is verified
(define-read-only (is-credential-verified (student-id (string-ascii 36)) (credential-id (string-ascii 36)))
  (default-to false (get is-verified (map-get? verified-credentials { student-id: student-id, credential-id: credential-id })))
)

;; Get credential details
(define-read-only (get-credential (student-id (string-ascii 36)) (credential-id (string-ascii 36)))
  (map-get? verified-credentials { student-id: student-id, credential-id: credential-id })
)

;; Validate credential against provided hash
(define-read-only (validate-credential-hash
  (student-id (string-ascii 36))
  (credential-id (string-ascii 36))
  (provided-hash (buff 32)))

  (let ((credential (map-get? verified-credentials { student-id: student-id, credential-id: credential-id })))
    (if (is-some credential)
      (is-eq (get hash (unwrap! credential false)) provided-hash)
      false
    )
  )
)

;; Initialize contract with first authorized verifier (contract deployer)
(map-set authorized-verifiers { verifier-address: tx-sender } { is-authorized: true })
