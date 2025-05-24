;; Emissions Calculation Contract
;; Quantifies carbon footprint based on transportation data

(define-constant ERR_INVALID_DATA (err u200))
(define-constant ERR_ZERO_DISTANCE (err u201))

;; Emission factors (grams CO2 per km)
(define-constant GASOLINE_FACTOR u250)
(define-constant DIESEL_FACTOR u280)
(define-constant ELECTRIC_FACTOR u50)
(define-constant HYBRID_FACTOR u150)

;; Data structures
(define-map emission-records
  { operator: principal, trip-id: uint }
  {
    vehicle-id: (string-ascii 50),
    distance: uint,
    fuel-type: (string-ascii 20),
    emissions: uint,
    timestamp: uint
  }
)

(define-data-var trip-counter uint u0)

;; Calculate emissions based on fuel type and distance
(define-private (get-emission-factor (fuel-type (string-ascii 20)))
  (if (is-eq fuel-type "gasoline")
    GASOLINE_FACTOR
    (if (is-eq fuel-type "diesel")
      DIESEL_FACTOR
      (if (is-eq fuel-type "electric")
        ELECTRIC_FACTOR
        (if (is-eq fuel-type "hybrid")
          HYBRID_FACTOR
          u200 ;; default factor
        )
      )
    )
  )
)

;; Calculate total emissions for a trip
(define-public (calculate-emissions
  (operator principal)
  (vehicle-id (string-ascii 50))
  (distance uint)
  (fuel-type (string-ascii 20))
)
  (begin
    (asserts! (> distance u0) ERR_ZERO_DISTANCE)
    (let (
      (emission-factor (get-emission-factor fuel-type))
      (total-emissions (* distance emission-factor))
      (trip-id (+ (var-get trip-counter) u1))
    )
      (var-set trip-counter trip-id)
      (map-set emission-records
        { operator: operator, trip-id: trip-id }
        {
          vehicle-id: vehicle-id,
          distance: distance,
          fuel-type: fuel-type,
          emissions: total-emissions,
          timestamp: block-height
        }
      )
      (ok {
        trip-id: trip-id,
        emissions: total-emissions,
        distance: distance
      })
    )
  )
)

;; Get emission record
(define-read-only (get-emission-record (operator principal) (trip-id uint))
  (map-get? emission-records { operator: operator, trip-id: trip-id })
)

;; Calculate total emissions for an operator
(define-read-only (get-total-emissions (operator principal))
  (let ((current-trip (var-get trip-counter)))
    (fold calculate-operator-total (list u1 u2 u3 u4 u5) { operator: operator, total: u0 })
  )
)

(define-private (calculate-operator-total (trip-id uint) (acc { operator: principal, total: uint }))
  (let ((record (map-get? emission-records { operator: (get operator acc), trip-id: trip-id })))
    (match record
      some-record {
        operator: (get operator acc),
        total: (+ (get total acc) (get emissions some-record))
      }
      { operator: (get operator acc), total: (get total acc) }
    )
  )
)
