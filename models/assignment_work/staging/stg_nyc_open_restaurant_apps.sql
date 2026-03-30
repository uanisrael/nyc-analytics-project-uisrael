-- Clean and standardize NYC Open Restaurant Applications data
-- One row per application

WITH source AS (
    SELECT *
    FROM {{ source('raw', 'source_nyc_open_restaurant_apps') }}
),

cleaned AS (
    SELECT
        -- Keep all other columns except ones we are transforming
        * EXCEPT (
            objectid,
            restaurant_name,
            borough,
            zip_code,
            time_of_submission,
            approved_for_sidewalk_seating,
            approved_for_roadway_seating
        ),

        -- Identifiers
        CAST(objectid AS STRING) AS application_id,

        -- Restaurant info
        CAST(restaurant_name AS STRING) AS restaurant_name,

        -- Location
        UPPER(TRIM(CAST(borough AS STRING))) AS borough,
        CAST(zip_code AS STRING) AS zip_code,

        -- Time
        CAST(time_of_submission AS TIMESTAMP) AS time_of_submission,

        -- Convert approvals to clean TRUE/FALSE
        CASE 
            WHEN LOWER(approved_for_sidewalk_seating) = 'yes' THEN TRUE
            ELSE FALSE
        END AS approved_for_sidewalk,

        CASE 
            WHEN LOWER(approved_for_roadway_seating) = 'yes' THEN TRUE
            ELSE FALSE
        END AS approved_for_roadway,

        -- Metadata
        CURRENT_TIMESTAMP() AS _stg_loaded_at

    FROM source

    -- Basic filter
    WHERE borough IS NOT NULL

    -- Deduplicate
    QUALIFY ROW_NUMBER() OVER (PARTITION BY objectid ORDER BY time_of_submission DESC) = 1
)

SELECT * FROM cleaned