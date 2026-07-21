# Retail Inventory Analytics: A POS-Based Restocking Strategy (2022-2024)
A retail sales analysis for a family-owned convenience store, used to inform beer restocking decisions.

## Background and Overview
The shop owner has obseved the declining in beer Leo sales over the past three years (2022-2024). She needs a clearer and data-driven basis for restocking such product.
Current restocking strategy relies on intuition, leading to potential stockouts or overstock. The store carries Leo Beer across three SKUs (Bottle*12, Can320ml*24, Can490ml*12).
Without a consolidated view of sales trends by format, season, and customer type,
it is difficult to know how much to order, when to order more ahead of demand spikes, and which formats are gaining or losing share.

### Business Questions
How should the shop owner adjust its beer restocking strategy to reduce stockouts during peak demand while avoiding overstock of declining formats?
This is broken down into three sub-questions:
- **Segment Performance:** Which packaging variants are trending upward or downward, and by what margin?
- **Seasonality:** When do sales spike, and how much extra stock is needed ahead of those periods?
- **Reorder point:** At what inventory level should the next order be placed, given average demand, its variability, and lead time?
- **Forecast:** How many standard packs, by SKU, is the shop likely to have in the upcoming restocking cycle?

### Objectives
This project aims to answer the business questions above by:
- Evaluating segment performance to determine which pack formats are gaining or losing share.
- Identifying seasonal demand patterns to determine when and by how much stock needs to increase ahead of peak periods.
- Determining a reorder point (safety stock) per format to translate demand data into a concrete restocking trigger.
- Forecasting short-term demand by format to guide order quantities for the next restocking cycle

### Tools
- **SQLite:** [Full SQL_pipeline](beer_inventory_pipeline.sql)
- **Tableau Public:** [Interactive beer inventory dashboard](https://public.tableau.com/app/profile/mongkon.thongchaithanawut5618/viz/BeerInventoryDashboard/BeerInventoryRestocking).

## Data Overview
This project uses raw POS transaction exports from the shop, covering 2022–2024 (three annual extracts, unioned into a single sales table).
- **Scope:** ~400K recorded items across the shop's full product range. This project filters down to Leo Beer SKUs only, across bottle and can SKUs
- **Units sold:** the shop sells both wholesale and retail quantities, so raw unit counts are not directly comparable across records. This is why sales are standardized into a common "pack"
- **Availability:** raw data is proprietary (real shop sales records) and is not included in this repository. Only the SQL pipeline and aggregated, non-identifying output are shared.

## Executive Summary: Business Insights

### Volume & format shift
- Total sales durring 2022–2024: 46,274 standard packs.
- Bottle*12 remains the largest SKU by volume but is declining (-8.0% YoY).
- Can320ml*24 is growing (+8.5% YoY).
- Can 490ml*12 is growing fastest (+30.2% YoY).

### Seasonality
- Sales peak sharply in April and December (~65–68 avg. standard packs/month) These sales roughly double the low season of August–September (~25–30 avg. standard packs/month).
- Peaks align with Songkran (April) and Year End to New Year (December), indicating a predictable and recurring pattern rather than noise.

### Reoder point
- Reorder *Bottle*12*,  *Can 490ml*12*, and *Can 320ml*24* at ~150, ~45, and ~20 std packs remaining, respectively
- Bottle's much higher trigger point is driven by its higher sales volume, not by it being disproportionately unpredictable. All three SKUs show similar day-to-day variability relative to their own average demand (~70% coefficient of variation)

### Order forcast

## Recommendations

### SKU mix
- Shift stock allocation toward cans, particularly Can490ml*12 given its +30.2% YoY growth. Please check whether current order volumes already reflect this trend or are lagging behind actual sell-through.
- Gradually reduce bottle order volumes in proportion to its -8.0% YoY decline to avoid overstock.

### Reorder point 
- Set reorder triggers by SKU, based on a 3-day supplier lead time and 95% service level:
    - **Bottle*12:** Reorder once stock falls to ~150 standard packs or below
    - **Can 490ml*12:** Reorder once stock falls to ~45 standard packs or below
    - **Can 320ml*24:** Reorder once stock falls to ~20 standard packs or below

- These thresholds assume the lead time and demand variability observed over 2022–2024 hold going forward; if the supplier's delivery time changes, the triggers should be recalculated

## forecast (to be added once analysis is complete)
