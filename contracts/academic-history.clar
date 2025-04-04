;; Academic History Contract
;; Securely stores previous schooling information

;; Define data vars and maps
(define-map academic-records
  { student-id: (string-ascii 36), record-id: (string-ascii 36) }
  {
    school-name: (string-utf8 100),
    country: (string-utf8 50),
    start-date: (string-ascii 10),
    end-date: (string-ascii 10),
    grade-level: (string-ascii 20),
    curriculum: (string-utf8 50)
  }
)

;; Define authorized parties
(define-map authorized-issuers
  { issuer-address: principal }
  { is-authorized: bool }
)

;; Error codes
(define-constant ERR_UNAUTHORIZED u1)
(define-constant ERR_ALREADY_EXISTS u2)
(define-constant ERR_NOT_FOUND u3)

;; Check if caller is an authorized issuer
(define-private (is-authorized (caller principal))
  (default-to false (get is-authorized (map-get? authorized-issuers { issuer-address: caller })))
)

;; Register a new authorized issuer
(define-public (register-issuer (issuer principal))
  (begin
    (asserts! (is-authorized tx-sender) (err ERR_UNAUTHORIZED))
    (ok (map-set authorized-issuers { issuer-address: issuer } { is-authorized: true }))
  )
)

;; Add an academic record for a student
(define-public (add-academic-record
  (student-id (string-ascii 36))
  (record-id (string-ascii 36))
  (school-name (string-utf8 100))
  (country (string-utf8 50))
  (start-date (string-ascii 10))
  (end-date (string-ascii 10))
  (grade-level (string-ascii 20))
  (curriculum (string-utf8 50)))

  (begin
    (asserts! (is-authorized tx-sender) (err ERR_UNAUTHORIZED))
    (asserts! (is-none (map-get? academic-records { student-id: student-id, record-id: record-id })) (err ERR_ALREADY_EXISTS))

    (ok (map-set academic-records
      { student-id: student-id, record-id: record-id }
      {
        school-name: school-name,
        country: country,
        start-date: start-date,
        end-date: end-date,
        grade-level: grade-level,
        curriculum: curriculum
      }
    ))
  )
)

;; Update an existing academic record
(define-public (update-academic-record
  (student-id (string-ascii 36))
  (record-id (string-ascii 36))
  (school-name (string-utf8 100))
  (country (string-utf8 50))
  (start-date (string-ascii 10))
  (end-date (string-ascii 10))
  (grade-level (string-ascii 20))
  (curriculum (string-utf8 50)))

  (begin
    (asserts! (is-authorized tx-sender) (err ERR_UNAUTHORIZED))
    (asserts! (is-some (map-get? academic-records { student-id: student-id, record-id: record-id })) (err ERR_NOT_FOUND))

    (ok (map-set academic-records
      { student-id: student-id, record-id: record-id }
      {
        school-name: school-name,
        country: country,
        start-date: start-date,
        end-date: end-date,
        grade-level: grade-level,
        curriculum: curriculum
      }
    ))
  )
)

;; Get a specific academic record
(define-read-only (get-academic-record (student-id (string-ascii 36)) (record-id (string-ascii 36)))
  (map-get? academic-records { student-id: student-id, record-id: record-id })
)

;; Initialize contract with first authorized issuer (contract deployer)
(map-set authorized-issuers { issuer-address: tx-sender } { is-authorized: true })
