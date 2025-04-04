;; School Placement Contract
;; Facilitates appropriate educational assignments

;; Define data vars and maps
(define-map placement-records
  { student-id: (string-ascii 36) }
  {
    school-id: (string-ascii 36),
    assigned-grade: (string-ascii 20),
    placement-date: (string-ascii 10),
    placement-type: (string-ascii 20),
    special-needs: (string-utf8 200),
    status: (string-ascii 20)
  }
)

;; Define participating schools
(define-map participating-schools
  { school-id: (string-ascii 36) }
  {
    name: (string-utf8 100),
    country: (string-utf8 50),
    curriculum: (string-utf8 50),
    capacity: uint,
    is-active: bool
  }
)

;; Define authorized placement authorities
(define-map authorized-authorities
  { authority-address: principal }
  { is-authorized: bool }
)

;; Error codes
(define-constant ERR_UNAUTHORIZED u1)
(define-constant ERR_ALREADY_EXISTS u2)
(define-constant ERR_NOT_FOUND u3)
(define-constant ERR_INVALID_SCHOOL u4)

;; Check if caller is an authorized authority
(define-private (is-authorized (caller principal))
  (default-to false (get is-authorized (map-get? authorized-authorities { authority-address: caller })))
)

;; Register a new authorized authority
(define-public (register-authority (authority principal))
  (begin
    (asserts! (is-authorized tx-sender) (err ERR_UNAUTHORIZED))
    (ok (map-set authorized-authorities { authority-address: authority } { is-authorized: true }))
  )
)

;; Register a new participating school
(define-public (register-school
  (school-id (string-ascii 36))
  (name (string-utf8 100))
  (country (string-utf8 50))
  (curriculum (string-utf8 50))
  (capacity uint))

  (begin
    (asserts! (is-authorized tx-sender) (err ERR_UNAUTHORIZED))
    (asserts! (is-none (map-get? participating-schools { school-id: school-id })) (err ERR_ALREADY_EXISTS))

    (ok (map-set participating-schools
      { school-id: school-id }
      {
        name: name,
        country: country,
        curriculum: curriculum,
        capacity: capacity,
        is-active: true
      }
    ))
  )
)

;; Create a school placement for a student
(define-public (create-placement
  (student-id (string-ascii 36))
  (school-id (string-ascii 36))
  (assigned-grade (string-ascii 20))
  (placement-date (string-ascii 10))
  (placement-type (string-ascii 20))
  (special-needs (string-utf8 200)))

  (begin
    (asserts! (is-authorized tx-sender) (err ERR_UNAUTHORIZED))
    (asserts! (is-none (map-get? placement-records { student-id: student-id })) (err ERR_ALREADY_EXISTS))
    (asserts! (is-some (map-get? participating-schools { school-id: school-id })) (err ERR_INVALID_SCHOOL))

    (ok (map-set placement-records
      { student-id: student-id }
      {
        school-id: school-id,
        assigned-grade: assigned-grade,
        placement-date: placement-date,
        placement-type: placement-type,
        special-needs: special-needs,
        status: "active"
      }
    ))
  )
)

;; Update a student's placement
(define-public (update-placement
  (student-id (string-ascii 36))
  (school-id (string-ascii 36))
  (assigned-grade (string-ascii 20))
  (placement-type (string-ascii 20))
  (special-needs (string-utf8 200)))

  (begin
    (asserts! (is-authorized tx-sender) (err ERR_UNAUTHORIZED))
    (asserts! (is-some (map-get? placement-records { student-id: student-id })) (err ERR_NOT_FOUND))
    (asserts! (is-some (map-get? participating-schools { school-id: school-id })) (err ERR_INVALID_SCHOOL))

    (let ((existing-record (unwrap! (map-get? placement-records { student-id: student-id }) (err ERR_NOT_FOUND))))
      (ok (map-set placement-records
        { student-id: student-id }
        {
          school-id: school-id,
          assigned-grade: assigned-grade,
          placement-date: (get placement-date existing-record),
          placement-type: placement-type,
          special-needs: special-needs,
          status: (get status existing-record)
        }
      ))
    )
  )
)

;; Get student placement information
(define-read-only (get-placement (student-id (string-ascii 36)))
  (map-get? placement-records { student-id: student-id })
)

;; Change placement status (active, transferred, completed)
(define-public (update-placement-status (student-id (string-ascii 36)) (new-status (string-ascii 20)))
  (begin
    (asserts! (is-authorized tx-sender) (err ERR_UNAUTHORIZED))

    (let ((existing-record (unwrap! (map-get? placement-records { student-id: student-id }) (err ERR_NOT_FOUND))))
      (ok (map-set placement-records
        { student-id: student-id }
        {
          school-id: (get school-id existing-record),
          assigned-grade: (get assigned-grade existing-record),
          placement-date: (get placement-date existing-record),
          placement-type: (get placement-type existing-record),
          special-needs: (get special-needs existing-record),
          status: new-status
        }
      ))
    )
  )
)

;; Get school information
(define-read-only (get-school (school-id (string-ascii 36)))
  (map-get? participating-schools { school-id: school-id })
)

;; Initialize contract with first authorized authority (contract deployer)
(map-set authorized-authorities { authority-address: tx-sender } { is-authorized: true })
