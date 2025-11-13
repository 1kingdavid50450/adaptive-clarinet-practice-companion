;; Adaptive Curriculum Generation Contract
;; Creates daily practice routines, adjusts difficulty dynamically, and manages learning goals

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u200))
(define-constant err-not-found (err u201))
(define-constant err-already-exists (err u202))
(define-constant err-invalid-input (err u203))
(define-constant err-unauthorized (err u204))
(define-constant err-invalid-difficulty (err u205))

;; Difficulty levels
(define-constant difficulty-beginner u1)
(define-constant difficulty-intermediate u2)
(define-constant difficulty-advanced u3)
(define-constant difficulty-expert u4)

;; Exercise types
(define-constant exercise-type-technical u1)
(define-constant exercise-type-theory u2)
(define-constant exercise-type-ear-training u3)
(define-constant exercise-type-repertoire u4)

;; Data Variables
(define-data-var total-routines uint u0)
(define-data-var total-exercises uint u0)
(define-data-var total-learning-goals uint u0)

;; Data Maps

;; Student learning profile
(define-map student-profiles
    principal
    {
        current-level: uint,
        learning-goals: (list 10 uint),
        weak-areas: (list 5 uint),
        strong-areas: (list 5 uint),
        practice-frequency: uint,
        last-assessment: uint,
        total-routines-completed: uint
    }
)

;; Daily practice routine
(define-map practice-routines
    { student: principal, routine-id: uint }
    {
        created-at: uint,
        difficulty-level: uint,
        total-duration: uint,
        exercises-count: uint,
        completed: bool,
        completion-score: uint,
        adaptive-adjustments: uint
    }
)

;; Individual exercises within routines
(define-map exercises
    { routine-key: { student: principal, routine-id: uint }, exercise-index: uint }
    {
        exercise-type: uint,
        exercise-name: (string-ascii 150),
        difficulty: uint,
        duration: uint,
        target-accuracy: uint,
        completed: bool,
        actual-performance: uint
    }
)

;; Learning goals and progress
(define-map learning-goals
    { student: principal, goal-id: uint }
    {
        goal-description: (string-ascii 200),
        target-skill-level: uint,
        current-skill-level: uint,
        deadline: uint,
        priority: uint,
        active: bool,
        achieved: bool
    }
)

;; Skill area tracking
(define-map skill-areas
    { student: principal, area-id: uint }
    {
        area-name: (string-ascii 100),
        current-proficiency: uint,
        target-proficiency: uint,
        practice-sessions: uint,
        last-practiced: uint,
        improvement-rate: uint
    }
)

;; Exercise recommendations
(define-map exercise-recommendations
    { student: principal, recommendation-id: uint }
    {
        recommended-exercise: (string-ascii 150),
        reason: (string-ascii 200),
        priority-score: uint,
        difficulty-level: uint,
        estimated-duration: uint,
        applied: bool
    }
)

;; Difficulty adjustment history
(define-map difficulty-adjustments
    { student: principal, adjustment-id: uint }
    {
        routine-id: uint,
        previous-difficulty: uint,
        new-difficulty: uint,
        reason: (string-ascii 150),
        performance-score: uint,
        timestamp: uint
    }
)

;; Public Functions

;; Initialize student profile
(define-public (initialize-student-profile (starting-level uint))
    (let
        (
            (student tx-sender)
        )
        (asserts! (is-none (map-get? student-profiles student)) err-already-exists)
        (asserts! (and (>= starting-level difficulty-beginner) (<= starting-level difficulty-expert)) err-invalid-difficulty)
        
        (ok (map-set student-profiles
            student
            {
                current-level: starting-level,
                learning-goals: (list),
                weak-areas: (list),
                strong-areas: (list),
                practice-frequency: u0,
                last-assessment: stacks-block-height,
                total-routines-completed: u0
            }
        ))
    )
)

;; Create new practice routine
(define-public (create-practice-routine
    (difficulty-level uint)
    (total-duration uint)
    (exercises-count uint))
    (let
        (
            (student tx-sender)
            (routine-id (+ (var-get total-routines) u1))
        )
        (asserts! (is-some (map-get? student-profiles student)) err-not-found)
        (asserts! (and (>= difficulty-level difficulty-beginner) (<= difficulty-level difficulty-expert)) err-invalid-difficulty)
        (asserts! (> exercises-count u0) err-invalid-input)
        
        (map-set practice-routines
            { student: student, routine-id: routine-id }
            {
                created-at: stacks-block-height,
                difficulty-level: difficulty-level,
                total-duration: total-duration,
                exercises-count: exercises-count,
                completed: false,
                completion-score: u0,
                adaptive-adjustments: u0
            }
        )
        
        (var-set total-routines routine-id)
        (ok routine-id)
    )
)

;; Add exercise to routine
(define-public (add-exercise-to-routine
    (routine-id uint)
    (exercise-index uint)
    (exercise-type uint)
    (exercise-name (string-ascii 150))
    (difficulty uint)
    (duration uint)
    (target-accuracy uint))
    (let
        (
            (student tx-sender)
            (routine-key { student: student, routine-id: routine-id })
        )
        (asserts! (is-some (map-get? practice-routines routine-key)) err-not-found)
        (asserts! (and (>= difficulty difficulty-beginner) (<= difficulty difficulty-expert)) err-invalid-difficulty)
        
        (ok (map-set exercises
            { routine-key: routine-key, exercise-index: exercise-index }
            {
                exercise-type: exercise-type,
                exercise-name: exercise-name,
                difficulty: difficulty,
                duration: duration,
                target-accuracy: target-accuracy,
                completed: false,
                actual-performance: u0
            }
        ))
    )
)

;; Complete exercise with performance data
(define-public (complete-exercise
    (routine-id uint)
    (exercise-index uint)
    (actual-performance uint))
    (let
        (
            (student tx-sender)
            (routine-key { student: student, routine-id: routine-id })
            (exercise-key { routine-key: routine-key, exercise-index: exercise-index })
            (exercise (unwrap! (map-get? exercises exercise-key) err-not-found))
        )
        (ok (map-set exercises
            exercise-key
            (merge exercise {
                completed: true,
                actual-performance: actual-performance
            })
        ))
    )
)

;; Complete routine and update statistics
(define-public (complete-routine (routine-id uint) (completion-score uint))
    (let
        (
            (student tx-sender)
            (routine-key { student: student, routine-id: routine-id })
            (routine (unwrap! (map-get? practice-routines routine-key) err-not-found))
            (profile (unwrap! (map-get? student-profiles student) err-not-found))
        )
        (map-set practice-routines
            routine-key
            (merge routine {
                completed: true,
                completion-score: completion-score
            })
        )
        
        (map-set student-profiles
            student
            (merge profile {
                total-routines-completed: (+ (get total-routines-completed profile) u1)
            })
        )
        
        (ok true)
    )
)

;; Create learning goal
(define-public (create-learning-goal
    (goal-description (string-ascii 200))
    (target-skill-level uint)
    (deadline uint)
    (priority uint))
    (let
        (
            (student tx-sender)
            (goal-id (+ (var-get total-learning-goals) u1))
        )
        (asserts! (is-some (map-get? student-profiles student)) err-not-found)
        
        (map-set learning-goals
            { student: student, goal-id: goal-id }
            {
                goal-description: goal-description,
                target-skill-level: target-skill-level,
                current-skill-level: u0,
                deadline: deadline,
                priority: priority,
                active: true,
                achieved: false
            }
        )
        
        (var-set total-learning-goals goal-id)
        (ok goal-id)
    )
)

;; Update learning goal progress
(define-public (update-goal-progress (goal-id uint) (current-skill-level uint))
    (let
        (
            (student tx-sender)
            (goal (unwrap! (map-get? learning-goals { student: student, goal-id: goal-id }) err-not-found))
            (target (get target-skill-level goal))
            (is-achieved (>= current-skill-level target))
        )
        (ok (map-set learning-goals
            { student: student, goal-id: goal-id }
            (merge goal {
                current-skill-level: current-skill-level,
                achieved: is-achieved,
                active: (not is-achieved)
            })
        ))
    )
)

;; Track skill area progress
(define-public (track-skill-area
    (area-id uint)
    (area-name (string-ascii 100))
    (current-proficiency uint)
    (target-proficiency uint))
    (let
        (
            (student tx-sender)
        )
        (asserts! (is-some (map-get? student-profiles student)) err-not-found)
        
        (ok (map-set skill-areas
            { student: student, area-id: area-id }
            {
                area-name: area-name,
                current-proficiency: current-proficiency,
                target-proficiency: target-proficiency,
                practice-sessions: u0,
                last-practiced: stacks-block-height,
                improvement-rate: u0
            }
        ))
    )
)

;; Update skill area after practice
(define-public (update-skill-area
    (area-id uint)
    (new-proficiency uint)
    (improvement-rate uint))
    (let
        (
            (student tx-sender)
            (skill (unwrap! (map-get? skill-areas { student: student, area-id: area-id }) err-not-found))
        )
        (ok (map-set skill-areas
            { student: student, area-id: area-id }
            (merge skill {
                current-proficiency: new-proficiency,
                practice-sessions: (+ (get practice-sessions skill) u1),
                last-practiced: stacks-block-height,
                improvement-rate: improvement-rate
            })
        ))
    )
)

;; Generate exercise recommendation
(define-public (generate-recommendation
    (recommended-exercise (string-ascii 150))
    (reason (string-ascii 200))
    (priority-score uint)
    (difficulty-level uint)
    (estimated-duration uint))
    (let
        (
            (student tx-sender)
            (recommendation-id (+ (var-get total-exercises) u1))
        )
        (asserts! (is-some (map-get? student-profiles student)) err-not-found)
        
        (map-set exercise-recommendations
            { student: student, recommendation-id: recommendation-id }
            {
                recommended-exercise: recommended-exercise,
                reason: reason,
                priority-score: priority-score,
                difficulty-level: difficulty-level,
                estimated-duration: estimated-duration,
                applied: false
            }
        )
        
        (var-set total-exercises recommendation-id)
        (ok recommendation-id)
    )
)

;; Record difficulty adjustment
(define-public (record-difficulty-adjustment
    (routine-id uint)
    (previous-difficulty uint)
    (new-difficulty uint)
    (reason (string-ascii 150))
    (performance-score uint))
    (let
        (
            (student tx-sender)
            (adjustment-id (+ u1 (default-to u0 (get-adjustment-count student))))
        )
        (asserts! (is-some (map-get? student-profiles student)) err-not-found)
        (asserts! (is-some (map-get? practice-routines { student: student, routine-id: routine-id })) err-not-found)
        
        (ok (map-set difficulty-adjustments
            { student: student, adjustment-id: adjustment-id }
            {
                routine-id: routine-id,
                previous-difficulty: previous-difficulty,
                new-difficulty: new-difficulty,
                reason: reason,
                performance-score: performance-score,
                timestamp: stacks-block-height
            }
        ))
    )
)

;; Read-only Functions

;; Get student profile
(define-read-only (get-student-profile (student principal))
    (ok (map-get? student-profiles student))
)

;; Get practice routine
(define-read-only (get-practice-routine (student principal) (routine-id uint))
    (ok (map-get? practice-routines { student: student, routine-id: routine-id }))
)

;; Get exercise details
(define-read-only (get-exercise (student principal) (routine-id uint) (exercise-index uint))
    (ok (map-get? exercises { routine-key: { student: student, routine-id: routine-id }, exercise-index: exercise-index }))
)

;; Get learning goal
(define-read-only (get-learning-goal (student principal) (goal-id uint))
    (ok (map-get? learning-goals { student: student, goal-id: goal-id }))
)

;; Get skill area
(define-read-only (get-skill-area (student principal) (area-id uint))
    (ok (map-get? skill-areas { student: student, area-id: area-id }))
)

;; Get exercise recommendation
(define-read-only (get-recommendation (student principal) (recommendation-id uint))
    (ok (map-get? exercise-recommendations { student: student, recommendation-id: recommendation-id }))
)

;; Get difficulty adjustment
(define-read-only (get-difficulty-adjustment (student principal) (adjustment-id uint))
    (ok (map-get? difficulty-adjustments { student: student, adjustment-id: adjustment-id }))
)

;; Get total routines count
(define-read-only (get-total-routines)
    (ok (var-get total-routines))
)

;; Private Functions

;; Get adjustment count for student
(define-private (get-adjustment-count (student principal))
    (let
        (
            (check-id u1)
        )
        (if (is-some (map-get? difficulty-adjustments { student: student, adjustment-id: check-id }))
            (some check-id)
            none
        )
    )
)

