/* ============================================================
   BEER INVENTORY RESTOCKING PIPELINE
   Source: shop POS exports, 2022-2024 
   Output: monthly, standardized-pack sales by beer format
   ============================================================ */

-- ------------------------------------------------------------
-- STEP 1: Consolidate three years of raw POS exports
-- ------------------------------------------------------------
DROP TABLE IF EXISTS sale;

CREATE TABLE sale AS
SELECT * FROM d65
UNION ALL
SELECT * FROM d66
UNION ALL
SELECT * FROM d67;


-- -------------------------------------------------------------------------
-- STEP 2: Data quality check: item code vs. item name
-- Some item codes map to multiple item-name spellings/variants.
-- This check confirms that, despite name variation, each code
-- consistently maps to a single unit of sale. 
-- So `code` (not `names`) is the reliable key for identifying a unique SKU.
-- -------------------------------------------------------------------------
SELECT
    s.code,
    s.names,
    c.n_names,
    s.a02,
    s.unit
FROM sale AS s
JOIN (
    SELECT code, COUNT(DISTINCT names) AS n_names
    FROM sale
    GROUP BY code
) AS c
    ON s.code = c.code
WHERE s.names LIKE '%ลีโอ%'
ORDER BY s.code;


-- ------------------------------------------------------------
-- STEP 3: Filter to Leo Beer records, keep only needed columns
-- ------------------------------------------------------------

CREATE TABLE beer AS
SELECT
    bill,
    CCODE,
    code,
    names     AS item,
    A02       AS qty,
    UNIT      AS unit,
    A01       AS prc,
    TOTAL,
    BSUM,
    JSUM,
    CUSTCODE,
    SORT      AS cus_name,
    DDX1      AS d,
    MMX1      AS m,
    YYX1      AS y,
    DMY
FROM sale
WHERE names LIKE '%ลีโอ%';


-- ------------------------------------------------------------
-- STEP 4: Build item dimension (lookup) table
-- Maps each code/unit combination to:
--   qty2       = number of base units (cans/bottles) per sold unit
--   item_type  = product family (can320 / can490 / bottle)
-- Mapping is based on manual review of packaging conventions
-- for each SKU.
-- ------------------------------------------------------------

CREATE TABLE item_dim AS
SELECT DISTINCT code, item, unit
FROM beer;

ALTER TABLE item_dim ADD COLUMN qty2 INTEGER;
ALTER TABLE item_dim ADD COLUMN item_type TEXT;

UPDATE item_dim
SET
    qty2 = CASE
        WHEN code = '88990127'                                 THEN 12
        WHEN code = '8850999009674' AND unit = 'กระป๋อง'          THEN 1
        WHEN code = '8850999009674' AND unit IN ('แพค', 'แพค*6')  THEN 6
        WHEN code = '8850999009681'                                THEN 12
        WHEN code = '8850999141008'                                THEN 1
        WHEN code = '8850999141015'                                THEN 12
        WHEN code = '8850999143002' AND unit = 'กระป๋อง'          THEN 1
        WHEN code = '8850999143002' AND unit IN ('แพค', 'แพค*6')  THEN 6
        WHEN code = '8850999143026'                                THEN 24
    END,
    item_type = CASE
        WHEN code IN ('88990127', '8850999143002', '8850999143026') THEN 'can320'
        WHEN code IN ('8850999009674', '8850999009681')             THEN 'can490'
        WHEN code IN ('8850999141008', '8850999141015')             THEN 'bottle'
    END;

-- QA check: any SKU without a mapping means a new/unrecognized
-- code appeared in this data pull and needs manual review before
-- it silently drops out of the standardized totals downstream.
SELECT *
FROM item_dim
WHERE qty2 IS NULL OR item_type IS NULL;


-- ------------------------------------------------------------
-- STEP 5: Join standardized quantity and item type into `beer`
-- ------------------------------------------------------------
ALTER TABLE beer ADD COLUMN qty2 INTEGER;
ALTER TABLE beer ADD COLUMN item_type TEXT;

UPDATE beer AS b
SET
    qty2      = i.qty2,
    item_type = i.item_type
FROM item_dim AS i
WHERE b.code = i.code AND b.item = i.item;


-- ------------------------------------------------------------
-- STEP 6: Parse Thai Buddhist-calendar date string (DD/MM/YY)
-- into ISO format, then aggregate sales by year-month and
-- product type for visualization.
-- ------------------------------------------------------------

WITH parsed AS (
    SELECT
        DATE(
            (CAST(substr(DMY, 7, 2) AS INTEGER) + 2000) || '-' ||
            substr(DMY, 4, 2) || '-' ||
            substr(DMY, 1, 2)
        )                       AS ymd,
        y,
        m,
        item_type,
        qty,
        qty2,
        CUSTCODE               AS member,
        CASE item_type          -- packs per case by SKU
            WHEN 'can320' THEN 24.0
            WHEN 'can490' THEN 12.0
            WHEN 'bottle' THEN 12.0
            ELSE NULL            -- pop up unmapped item_types instead
                                 -- of silently going NULL downstream
        END                     AS unit_pack
    FROM beer
)
SELECT
    ymd,
    y,
    m,
    item_type,
    SUM(qty * qty2)                                              AS qty_tot,      -- base units sold (cans/bottles)
    SUM(qty * qty2) / unit_pack                                  AS std_pack,     -- standardized case-equivalent packs
    COUNT(*)                                                     AS tot_order,
    COUNT(member)                                                AS mem_order,
    SUM(CASE WHEN member IS NULL THEN 1 ELSE 0 END)              AS nonmem_order,
    SUM(CASE WHEN member IS NOT NULL THEN qty * qty2 ELSE 0 END) / unit_pack AS mem_std_pack,
    SUM(CASE WHEN member IS NULL     THEN qty * qty2 ELSE 0 END) / unit_pack AS nonmem_std_pack
FROM parsed
GROUP BY ymd, item_type
ORDER BY ymd, item_type;

-- Export result set to CSV for use in the Tableau dashboard.
