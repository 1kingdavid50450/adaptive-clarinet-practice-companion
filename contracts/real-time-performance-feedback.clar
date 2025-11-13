;; Real-Time Performance Feedback Contract
;; Manages performance metrics, feedback data, and achievement tracking for clarinet practice

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-already-exists (err u102))
(define-constant err-invalid-input (err u103))
(define-constant err-unauthorized (err u104))

;; Performance accuracy thresholds
(define-constant pitch-accuracy-threshold u5) ;; 5 cents
(define-constant rhythm-precision-threshold u10) ;; 10ms
(define-constant min-score u0)
(define-constant max-score u100)

;; Data Variables
(define-data-var total-sessions uint u0)
(define-data-var total-achievements-awarded uint u0)

;; Data Maps

;; User profile with overall statistics
(define-map user-profiles
    principal
    {
        username: (string-ascii 50),
        total-practice-time: uint,
        sessions-completed: uint,
        average-pitch-score: uint,
        average-rhythm-score: uint,
        average-tone-score: uint,
        achievements-earned: uint,
        level: uint,
        created-at: uint
    }
)

;; Individual practice session data
(define-map practice-sessions
    { user: principal, session-id: uint }
    {
        start-time: uint,
        duration: uint,
        pitch-accuracy: uint,
        rhythm-precision: uint,
        tone-quality: uint,
        notes-played: uint,
        errors-detected: uint,
        overall-score: uint,
        feedback-generated: bool
    }
)

;; Performance feedback for each session
(define-map session-feedback
    { user: principal, session-id: uint }
    {
        pitch-feedback: (string-ascii 200),
        rhythm-feedback: (string-ascii 200),
        tone-feedback: (string-ascii 200),
        improvement-suggestions: (string-ascii 300),
        timestamp: uint
    }
)

;; Achievement tracking
(define-map user-achievements
    { user: principal, achievement-id: uint }
    {
        achievement-name: (string-ascii 100),
        achievement-type: (string-ascii 50),
        earned-at: uint,
        achievement-value: uint
    }
)

;; Leaderboard entries
(define-map leaderboard-entries
    principal
    {
        rank: uint,
        total-score: uint,
        best-streak: uint,
        last-updated: uint
    }
)

;; Progress tracking over time
(define-map progress-milestones
    { user: principal, milestone-id: uint }
    {
        milestone-name: (string-ascii 100),
        target-value: uint,
        current-value: uint,
        completion-percentage: uint,
        achieved: bool,
        achieved-at: (optional uint)
    }
)

;; Public Functions

;; Register a new user profile
(define-public (register-user (username (string-ascii 50)))
    (let
        (
            (user tx-sender)
        )
        (asserts! (is-none (map-get? user-profiles user)) err-already-exists)
        (ok (map-set user-profiles
            user
            {
                username: username,
                total-practice-time: u0,
                sessions-completed: u0,
                average-pitch-score: u0,
                average-rhythm-score: u0,
                average-tone-score: u0,
                achievements-earned: u0,
                level: u1,
                created-at: stacks-block-height
            }
        ))
    )
)

;; Record a new practice session
(define-public (record-practice-session 
    (duration uint)
    (pitch-accuracy uint)
    (rhythm-precision uint)
    (tone-quality uint)
    (notes-played uint)
    (errors-detected uint))
    (let
        (
            (user tx-sender)
            (session-id (+ (var-get total-sessions) u1))
            (overall-score (calculate-overall-score pitch-accuracy rhythm-precision tone-quality))
        )
        (asserts! (is-some (map-get? user-profiles user)) err-not-found)
        (asserts! (<= pitch-accuracy max-score) err-invalid-input)
        (asserts! (<= rhythm-precision max-score) err-invalid-input)
        (asserts! (<= tone-quality max-score) err-invalid-input)
        
        (map-set practice-sessions
            { user: user, session-id: session-id }
            {
                start-time: stacks-block-height,
                duration: duration,
                pitch-accuracy: pitch-accuracy,
                rhythm-precision: rhythm-precision,
                tone-quality: tone-quality,
                notes-played: notes-played,
                errors-detected: errors-detected,
                overall-score: overall-score,
                feedback-generated: false
            }
        )
        
        (var-set total-sessions session-id)
        (try! (update-user-statistics user pitch-accuracy rhythm-precision tone-quality duration))
        (ok session-id)
    )
)

;; Generate and store feedback for a session
(define-public (generate-feedback
    (session-id uint)
    (pitch-feedback (string-ascii 200))
    (rhythm-feedback (string-ascii 200))
    (tone-feedback (string-ascii 200))
    (improvement-suggestions (string-ascii 300)))
    (let
        (
            (user tx-sender)
        )
        (asserts! (is-some (map-get? practice-sessions { user: user, session-id: session-id })) err-not-found)
        
        (map-set session-feedback
            { user: user, session-id: session-id }
            {
                pitch-feedback: pitch-feedback,
                rhythm-feedback: rhythm-feedback,
                tone-feedback: tone-feedback,
                improvement-suggestions: improvement-suggestions,
                timestamp: stacks-block-height
            }
        )
        
        (map-set practice-sessions
            { user: user, session-id: session-id }
            (merge (unwrap-panic (map-get? practice-sessions { user: user, session-id: session-id }))
                { feedback-generated: true })
        )
        
        (ok true)
    )
)

;; Award achievement to user
(define-public (award-achievement
    (user principal)
    (achievement-name (string-ascii 100))
    (achievement-type (string-ascii 50))
    (achievement-value uint))
    (let
        (
            (achievement-id (+ (var-get total-achievements-awarded) u1))
            (profile (unwrap! (map-get? user-profiles user) err-not-found))
        )
        (map-set user-achievements
            { user: user, achievement-id: achievement-id }
            {
                achievement-name: achievement-name,
                achievement-type: achievement-type,
                earned-at: stacks-block-height,
                achievement-value: achievement-value
            }
        )
        
        (map-set user-profiles
            user
            (merge profile { achievements-earned: (+ (get achievements-earned profile) u1) })
        )
        
        (var-set total-achievements-awarded achievement-id)
        (ok achievement-id)
    )
)

;; Update leaderboard entry
(define-public (update-leaderboard (total-score uint) (best-streak uint))
    (let
        (
            (user tx-sender)
        )
        (asserts! (is-some (map-get? user-profiles user)) err-not-found)
        
        (ok (map-set leaderboard-entries
            user
            {
                rank: u0,
                total-score: total-score,
                best-streak: best-streak,
                last-updated: stacks-block-height
            }
        ))
    )
)

;; Create progress milestone
(define-public (create-milestone
    (milestone-id uint)
    (milestone-name (string-ascii 100))
    (target-value uint))
    (let
        (
            (user tx-sender)
        )
        (asserts! (is-some (map-get? user-profiles user)) err-not-found)
        
        (ok (map-set progress-milestones
            { user: user, milestone-id: milestone-id }
            {
                milestone-name: milestone-name,
                target-value: target-value,
                current-value: u0,
                completion-percentage: u0,
                achieved: false,
                achieved-at: none
            }
        ))
    )
)

;; Update milestone progress
(define-public (update-milestone-progress (milestone-id uint) (current-value uint))
    (let
        (
            (user tx-sender)
            (milestone (unwrap! (map-get? progress-milestones { user: user, milestone-id: milestone-id }) err-not-found))
            (target (get target-value milestone))
            (percentage (/ (* current-value u100) target))
            (is-achieved (>= current-value target))
        )
        (ok (map-set progress-milestones
            { user: user, milestone-id: milestone-id }
            (merge milestone {
                current-value: current-value,
                completion-percentage: percentage,
                achieved: is-achieved,
                achieved-at: (if is-achieved (some stacks-block-height) none)
            })
        ))
    )
)

;; Read-only Functions

;; Get user profile
(define-read-only (get-user-profile (user principal))
    (ok (map-get? user-profiles user))
)

;; Get practice session details
(define-read-only (get-practice-session (user principal) (session-id uint))
    (ok (map-get? practice-sessions { user: user, session-id: session-id }))
)

;; Get session feedback
(define-read-only (get-session-feedback (user principal) (session-id uint))
    (ok (map-get? session-feedback { user: user, session-id: session-id }))
)

;; Get user achievement
(define-read-only (get-user-achievement (user principal) (achievement-id uint))
    (ok (map-get? user-achievements { user: user, achievement-id: achievement-id }))
)

;; Get leaderboard entry
(define-read-only (get-leaderboard-entry (user principal))
    (ok (map-get? leaderboard-entries user))
)

;; Get progress milestone
(define-read-only (get-progress-milestone (user principal) (milestone-id uint))
    (ok (map-get? progress-milestones { user: user, milestone-id: milestone-id }))
)

;; Get total sessions count
(define-read-only (get-total-sessions)
    (ok (var-get total-sessions))
)

;; Private Functions

;; Calculate overall performance score
(define-private (calculate-overall-score (pitch uint) (rhythm uint) (tone uint))
    (/ (+ (+ pitch rhythm) tone) u3)
)

;; Update user statistics after session
(define-private (update-user-statistics 
    (user principal)
    (pitch-score uint)
    (rhythm-score uint)
    (tone-score uint)
    (duration uint))
    (let
        (
            (profile (unwrap! (map-get? user-profiles user) err-not-found))
            (sessions (get sessions-completed profile))
            (new-sessions (+ sessions u1))
            (total-time (+ (get total-practice-time profile) duration))
            (new-pitch-avg (/ (+ (* (get average-pitch-score profile) sessions) pitch-score) new-sessions))
            (new-rhythm-avg (/ (+ (* (get average-rhythm-score profile) sessions) rhythm-score) new-sessions))
            (new-tone-avg (/ (+ (* (get average-tone-score profile) sessions) tone-score) new-sessions))
        )
        (ok (map-set user-profiles
            user
            (merge profile {
                total-practice-time: total-time,
                sessions-completed: new-sessions,
                average-pitch-score: new-pitch-avg,
                average-rhythm-score: new-rhythm-avg,
                average-tone-score: new-tone-avg
            })
        ))
    )
)

