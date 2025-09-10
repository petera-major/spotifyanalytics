USE spotify_fitness;

-- intensity of workout vs genre music
CREATE OR REPLACE VIEW v_intensity_vs_genre AS
SELECT
  CASE
    WHEN w.avg_heart_rate >= 140 OR w.workout_minutes >= 60 THEN 'High'
    WHEN w.avg_heart_rate >= 125 OR w.workout_minutes >= 40 THEN 'Medium'
    ELSE 'Low'
  END AS intensity_bucket,
  COALESCE(t.genre, 'Unknown') AS genre,
  COUNT(*) AS plays
FROM workouts w
JOIN workout_music wm ON wm.workout_id = w.workout_id
JOIN tracks t         ON t.track_id   = wm.track_id
GROUP BY intensity_bucket, genre
ORDER BY intensity_bucket, plays DESC;

CREATE OR REPLACE VIEW v_track_mood_buckets AS
SELECT
  track_id,
  CASE
    WHEN energy >= 0.7 AND danceability >= 0.7 THEN 'Uplifting'
    WHEN energy < 0.4  AND danceability < 0.4  THEN 'Calm/Sad'
    WHEN energy >= 0.7                         THEN 'Hype'
    WHEN danceability >= 0.7                   THEN 'Groovy'
    ELSE 'Neutral'
  END AS mood_label
FROM tracks;

-- dominant mood per workout 
CREATE OR REPLACE VIEW v_workout_dominant_mood AS
SELECT workout_id, mood_label
FROM (
  SELECT
    wm.workout_id,
    mb.mood_label,
    ROW_NUMBER() OVER (
      PARTITION BY wm.workout_id
      ORDER BY COUNT(*) DESC
    ) AS rn
  FROM workout_music wm
  LEFT JOIN v_track_mood_buckets mb
         ON mb.track_id = wm.track_id
  GROUP BY wm.workout_id, mb.mood_label
) x
WHERE rn = 1;


-- my wellness by each day in accordance to sleep
CREATE OR REPLACE VIEW v_day_wellness AS
SELECT
  workout_date AS day,
  hours_slept,
  steps,
  avg_heart_rate,
LEAD(hours_slept) OVER (ORDER BY workout_date) AS next_day_sleep
FROM workouts;