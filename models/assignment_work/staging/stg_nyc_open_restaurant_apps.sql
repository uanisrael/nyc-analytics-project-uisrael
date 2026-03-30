-- Clean and standardize NYC Open Restaurant Applications data
-- One row per application

WITH source AS (
    SELECT *
    FROM {{ source('restaurant_raw', 'source_nyc_open_restaurant_apps') }}
),

cleaned AS (
    SELECT
        *,

        -- Identifiers
        CAST(objectid AS STRING) AS application_id,

        -- Location
        UPPER(TRIM(CAST(borough AS STRING))) AS borough_clean,
        NULL AS zip_code_clean,

        -- Time
        CAST(time_of_submission AS TIMESTAMP) AS submission_timestamp,

        -- Approval fields
        CASE 
            WHEN LOWER(CAST(approved_for_sidewalk_seating AS STRING)) = 'yes' THEN TRUE
            ELSE FALSE
        END AS approved_for_sidewalk,

        CASE 
            WHEN LOWER(CAST(approved_for_roadway_seating AS STRING)) = 'yes' THEN TRUE
            ELSE FALSE
        END AS approved_for_roadway,

        -- Metadata
        CURRENT_TIMESTAMP() AS _stg_loaded_at

    FROM source
    WHERE borough IS NOT NULL

    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY objectid
        ORDER BY time_of_submission DESC
    ) = 1
)

SELECT * FROM cleaned