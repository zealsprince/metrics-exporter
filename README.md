# Metrics Exporter

A Factorio mod that exports comprehensive game metrics to JSON files for external analysis and monitoring.

## What it does

This mod automatically collects and exports detailed information about your factory every minute, including:

- Entity states and performance (assembling machines, mining drills, inserters)
- Power generation and distribution
- Research progress and technology status
- Factory statistics and pollution levels
- Resource production and consumption rates

## Output

The mod generates JSON files in Factorio's script-output folder containing:

- Timestamped snapshots of your entire factory state
- Entity-level details like status, position, recipes, and bonuses
- Force-level statistics including research progress and rockets launched
- Surface-wide metrics such as pollution and entity counts

## Use cases

- Monitor factory performance over time
- Analyze production bottlenecks
- Track research progress
- Export data for external dashboards or analysis tools
- Debug factory efficiency issues

## Installation

1. Download and place in your Factorio mods folder
2. Enable the mod in-game
3. JSON files will be automatically generated in the script-output folder every minute

## Technical details

- Export interval: 60 seconds (3600 ticks)
- Compatible with Factorio 2.0
- Minimal performance impact
- No dependencies required
