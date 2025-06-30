# Metrics Exporter

A Factorio mod that exports comprehensive game metrics to JSON files for external analysis and monitoring.

## What it does

This mod automatically collects and exports detailed information about your factory every 30 seconds, including:

- **Entities**: State and performance of assembling machines, mining drills, furnaces, and transport belts.
- **Power**: Detailed electric network statistics, power generation, and individual entity consumption.
- **Resources**: Surface resource quantities and production rates.
- **Research**: Technology progress and lab activity.
- **Logistics & Circuits**: State of logistic networks and circuit conditions.
- **Military & Enemies**: Location and state of enemy units and player military assets.
- **Players**: Inventory contents and player positions.
- **Rockets**: Silo status and launch history.
- **Production**: Force-level production, consumption, and pollution statistics.

## Output

The mod generates JSON files in Factorio's `script-output` folder containing:

- Timestamped snapshots of your entire factory state.
- **Entity-level details**: Status, position, recipes, and module bonuses.
- **Force-level statistics**: Research progress, production/consumption rates, and rockets launched.
- **Surface-wide metrics**: Pollution levels, resource distribution, and entity counts.
- **Electric network analysis**: Power production, consumption, and satisfaction levels.
- **Military intelligence**: Positions of enemy units and player defenses.

## Use cases

- Monitor factory performance over time
- Analyze production bottlenecks
- Track research progress
- Export data for external dashboards or analysis tools
- Debug factory efficiency issues

## Example Data Pipeline: S3 and ClickHouse Cloud

A powerful use case for this mod is to build a real-time monitoring and analytics pipeline. Here’s an example setup using AWS S3 and ClickHouse Cloud:

1. **Automated Export**: A `cron` job on your machine regularly copies the JSON files from the `script-output` folder to an AWS S3 bucket.
2. **Data Ingestion**: ClickHouse Cloud is configured with a ClickPipe to automatically detect and stream new JSON files from the S3 bucket.
3. **Data Warehousing**: The data is streamed into a ClickHouse data warehouse, ready for complex analytical queries and real-time dashboarding.

This setup allows you to build powerful, scalable analytics on top of your Factorio factory's metrics.

## Installation

1. Download and place in your Factorio mods folder
2. Enable the mod in-game
3. JSON files will be automatically generated in the script-output folder every half minute
