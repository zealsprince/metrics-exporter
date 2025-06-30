-- Global settings (stored in global table for persistence)
local DEFAULT_SETTINGS = {
  auto_export_enabled = true,   -- Whether automatic exports are enabled
  export_interval_seconds = 30, -- How often to export (in seconds)
  file_output_enabled = true,   -- Whether to write files to disk
  admin_only_control = true     -- Whether only admins can change export settings
}

-- Import the modular metrics system and logging
local metrics = require("metrics.init")
local logging = require("metrics.logging")

-- Helper functions for settings management
local function get_settings()
  -- Ensure global table exists (it might not during early game lifecycle)
  if not global then
    return DEFAULT_SETTINGS -- Return defaults if global not available
  end

  if not global.metrics_settings then
    global.metrics_settings = {}
    for key, value in pairs(DEFAULT_SETTINGS) do
      global.metrics_settings[key] = value
    end
  end
  return global.metrics_settings
end

-- Ensure settings are initialized (safe to call anytime)
local function ensure_settings_initialized()
  if global and not global.metrics_settings then
    get_settings() -- This will initialize settings if global is available
  end
end

local function is_admin_or_allowed(command)
  if not command or not command.player_index then
    return true -- Console command
  end

  local player = game.get_player(command.player_index)
  local settings = get_settings()

  -- If we can't access settings, default to admin-only for safety
  local admin_only = settings.admin_only_control
  if admin_only == nil then
    admin_only = DEFAULT_SETTINGS.admin_only_control
  end

  if admin_only and not player.admin then
    return false
  end

  return true
end

local function update_export_timer()
  local settings = get_settings()

  -- Clear existing timer
  script.on_nth_tick(nil)

  -- Set new timer if auto export is enabled
  if settings.auto_export_enabled then
    local interval_ticks = settings.export_interval_seconds * 60 -- Convert to ticks
    script.on_nth_tick(interval_ticks, function(event)
      -- Only export if auto export is still enabled (settings might have changed)
      local current_settings = get_settings()
      if current_settings.auto_export_enabled then
        -- Use _G to access the global function by name (avoids forward reference)
        local export_func = _G["export_state"]
        if export_func then
          pcall(export_func, nil) -- nil indicates automatic export
        end
      end
    end)
    logging.info("AUTO_EXPORT", "Automatic export enabled (every " .. settings.export_interval_seconds .. " seconds)")
  else
    logging.info("AUTO_EXPORT", "Automatic export disabled")
  end
end

-- Safe version for on_load (when global table is not accessible)
local function update_export_timer_on_load()
  -- Clear existing timer
  script.on_nth_tick(nil)

  -- Set default timer - settings will be applied when first export runs
  local default_interval_ticks = DEFAULT_SETTINGS.export_interval_seconds * 60
  script.on_nth_tick(default_interval_ticks, function(event)
    -- Check settings when the timer actually runs (global will be available then)
    local current_settings = get_settings()
    if current_settings.auto_export_enabled then
      -- Use _G to access the global function by name (avoids forward reference)
      local export_func = _G["export_state"]
      if export_func then
        pcall(export_func, nil) -- nil indicates automatic export
      end
    end
  end)
end

function export_state(command)
  -- Check if command was called by a player and if they are admin
  if command and command.player_index then
    local player = game.get_player(command.player_index)
    if not player.admin then
      logging.error("AUTH", "Only admins can use this command")
      return
    end
  end

  -- Determine if this is an automatic or manual export
  local export_type = command and "manual" or "automatic"
  logging.info("EXPORT", "Starting " .. export_type .. " export...")

  local state = metrics.collect_all()
  local timestamp = game.tick
  local padded_timestamp = string.format("%012d", timestamp) -- Zero-pad to 12 digits for long-term data collection
  local iso_time = string.format("%04d-%02d-%02d_%02d-%02d-%02d",
    2000 + math.floor(timestamp / (60 * 60 * 24 * 365)),     -- Rough year
    math.floor((timestamp / (60 * 60 * 24 * 30)) % 12) + 1,  -- Rough month
    math.floor((timestamp / (60 * 60 * 24)) % 30) + 1,       -- Rough day
    math.floor((timestamp / (60 * 60)) % 24),                -- Hour
    math.floor((timestamp / 60) % 60),                       -- Minute
    math.floor(timestamp % 60)                               -- Second
  )

  -- Add debugging information
  local force_count = 0
  for _ in pairs(state.global_statistics.forces) do
    force_count = force_count + 1
  end

  logging.collection("Collected data for " .. #game.surfaces .. " surfaces and " .. force_count .. " forces")

  -- Check if enhanced metrics are present
  for surface_name, surface_data in pairs(state.surfaces) do
    if surface_data.enemies then
      logging.surface(surface_name, "Enemies data collected")

      -- Add detailed debugging for enemy types
      if surface_data.enemies.summary then
        local summary = surface_data.enemies.summary
        logging.surface(surface_name, "Enemy counts: Spawners=" ..
          (summary.total_spawners or 0) .. ", Units=" .. (summary.total_units or 0) ..
          ", Worms=" .. (summary.total_worms or 0) .. ", Nests=" .. (summary.total_nests or 0))
      end

      -- Check if nests data exists and has content
      if surface_data.enemies.nests then
        local nest_types = {}
        for nest_type, _ in pairs(surface_data.enemies.nests) do
          table.insert(nest_types, nest_type)
        end
        if #nest_types > 0 then
          logging.surface(surface_name, "Nest types found: " .. table.concat(nest_types, ", "))
        else
          logging.surface(surface_name, "Nests table exists but is empty")
        end
      else
        logging.warn("SURFACE:" .. surface_name, "Nests data is nil")
      end
    else
      logging.warn("SURFACE:" .. surface_name, "No enemies data")
    end

    if surface_data.statistics and surface_data.statistics.resources then
      logging.surface(surface_name, "Resources data collected")
    else
      logging.warn("SURFACE:" .. surface_name, "No resources data")
    end
  end

  for force_name, force_data in pairs(state.global_statistics.forces) do
    if force_data.item_production then
      logging.force(force_name, "Production data collected")
    else
      logging.warn("FORCE:" .. force_name, "No production data")
    end
  end

  -- Optionally write to organized files
  local settings = get_settings()
  if settings and settings.file_output_enabled then
    local world_exchange_string = game.get_map_exchange_string()
    -- Create a simple hash of the world identifier for folder naming
    local world_id = tostring(string.len(world_exchange_string))
    for i = 1, string.len(world_exchange_string) do
      world_id = world_id .. string.format("%02x", string.byte(world_exchange_string, i) % 256)
      if string.len(world_id) >= 16 then break end -- Limit to reasonable length
    end
    local base_folder = "metrics-exporter/" .. world_id .. "/"

    -- Use the new modular export system
    local exports = metrics.export_organized_data(state, base_folder, padded_timestamp)

    -- Write all export files
    logging.export("Creating " .. #exports .. " export files...")
    for _, export_data in pairs(exports) do
      helpers.write_file(export_data.file, helpers.table_to_json(export_data.data))
      logging.debug("EXPORT", "Exported: " .. export_data.file)
    end

    logging.export("Export complete! Files written to script-output folder.")
  end
end

-- Function to register the periodic export handler
local function register_export_handler()
  update_export_timer()
end

-- Safe version for on_load
local function register_export_handler_on_load()
  update_export_timer_on_load()
end

-- Register event handlers on init (new game)
script.on_init(function()
  -- Initialize settings in global table
  if global and not global.metrics_settings then
    global.metrics_settings = {}
    for key, value in pairs(DEFAULT_SETTINGS) do
      global.metrics_settings[key] = value
    end
  end
  register_export_handler()
end)

-- Register event handlers on load (existing game)
script.on_load(function()
  -- Only re-setup event handlers - no game access allowed here!
  -- Use safe version that doesn't access global table
  register_export_handler_on_load()
end)

-- Handle mod configuration changes (updates, etc.)
script.on_configuration_changed(function(event)
  -- Re-initialize settings if they don't exist
  if global and not global.metrics_settings then
    global.metrics_settings = {}
    for key, value in pairs(DEFAULT_SETTINGS) do
      global.metrics_settings[key] = value
    end
  end

  -- Refresh the export timer with current settings
  register_export_handler()

  logging.info("CONFIG", "Mod configuration updated, settings refreshed")
end)

-- Add the command correctly, per the API
commands.add_command(
  "metrics-exporter-export",                     -- command name (no slash)
  "Export comprehensive factory state as JSON.", -- help text
  export_state                                   -- function to call
)

-- Add logging control commands
commands.add_command(
  "metrics-exporter-debug-on",
  "Enable metrics debug logging",
  function(command)
    logging.enable()
    logging.info("Debug logging enabled")
  end
)

commands.add_command(
  "metrics-exporter-debug-off",
  "Disable metrics debug logging",
  function(command)
    logging.disable()
    logging.info("Debug logging disabled")
  end
)

commands.add_command(
  "metrics-exporter-debug-level",
  "Set logging level (DEBUG, INFO, WARN, ERROR)",
  function(command)
    if command.parameter then
      logging.set_level(command.parameter)
      logging.info("Log level set to " .. string.upper(command.parameter))
    else
      logging.info("Usage: /metrics-exporter-debug-level <level>")
      logging.info("Available levels: DEBUG, INFO, WARN, ERROR")
    end
  end
)

-- Add export control commands
commands.add_command(
  "metrics-exporter-auto",
  "Enable/disable automatic metrics export (admin only)",
  function(command)
    ensure_settings_initialized()
    if not is_admin_or_allowed(command) then
      logging.error("AUTH", "Only admins can change export settings")
      return
    end

    local settings = get_settings()
    settings.auto_export_enabled = not settings.auto_export_enabled
    update_export_timer()

    local status = settings.auto_export_enabled and "enabled" or "disabled"
    logging.info("EXPORT_CONTROL", "Automatic export " .. status)
  end
)

commands.add_command(
  "metrics-exporter-interval",
  "Set automatic export interval in seconds (admin only, minimum 10)",
  function(command)
    ensure_settings_initialized()
    if not is_admin_or_allowed(command) then
      logging.error("AUTH", "Only admins can change export settings")
      return
    end

    if not command.parameter then
      local settings = get_settings()
      logging.info("EXPORT_CONTROL", "Current export interval: " .. settings.export_interval_seconds .. " seconds")
      logging.info("EXPORT_CONTROL", "Usage: /metrics-exporter-interval <seconds>")
      return
    end

    local interval = tonumber(command.parameter)
    if not interval or interval < 10 then
      logging.error("EXPORT_CONTROL", "Invalid interval. Must be a number >= 10 seconds")
      return
    end

    local settings = get_settings()
    settings.export_interval_seconds = interval
    update_export_timer()

    logging.info("EXPORT_CONTROL", "Export interval set to " .. interval .. " seconds")
  end
)

commands.add_command(
  "metrics-exporter-files",
  "Enable/disable writing export files to disk (admin only)",
  function(command)
    ensure_settings_initialized()
    if not is_admin_or_allowed(command) then
      logging.error("AUTH", "Only admins can change export settings")
      return
    end

    local settings = get_settings()
    settings.file_output_enabled = not settings.file_output_enabled

    local status = settings.file_output_enabled and "enabled" or "disabled"
    logging.info("EXPORT_CONTROL", "File output " .. status)
  end
)

commands.add_command(
  "metrics-exporter-status",
  "Show current metrics export settings",
  function(command)
    ensure_settings_initialized()
    local settings = get_settings()

    logging.info("SETTINGS", "=== Metrics Exporter Status ===")
    logging.info("SETTINGS", "Auto export: " .. (settings.auto_export_enabled and "ENABLED" or "DISABLED"))
    logging.info("SETTINGS", "Export interval: " .. settings.export_interval_seconds .. " seconds")
    logging.info("SETTINGS", "File output: " .. (settings.file_output_enabled and "ENABLED" or "DISABLED"))
    logging.info("SETTINGS", "Admin only control: " .. (settings.admin_only_control and "YES" or "NO"))

    if command and command.player_index then
      local player = game.get_player(command.player_index)
      local can_control = is_admin_or_allowed(command)
      logging.info("SETTINGS", "You can control settings: " .. (can_control and "YES" or "NO"))
    end
  end
)

commands.add_command(
  "metrics-exporter-help",
  "Show all available metrics exporter commands",
  function(command)
    ensure_settings_initialized()
    logging.info("HELP", "=== Metrics Exporter Commands ===")
    logging.info("HELP", "/metrics-exporter-export - Export metrics now (admin only)")
    logging.info("HELP", "/metrics-exporter-status - Show current export settings")
    logging.info("HELP", "/metrics-exporter-auto - Enable/disable automatic exports (admin only)")
    logging.info("HELP", "/metrics-exporter-interval <seconds> - Set export interval (admin only)")
    logging.info("HELP", "/metrics-exporter-files - Enable/disable file writing (admin only)")
    logging.info("HELP", "/metrics-exporter-refresh - Refresh automatic export timer (admin only)")
    logging.info("HELP", "/metrics-exporter-debug-on - Enable debug logging")
    logging.info("HELP", "/metrics-exporter-debug-off - Disable debug logging")
    logging.info("HELP", "/metrics-exporter-debug-level <level> - Set log level")
    logging.info("HELP", "/metrics-exporter-help - Show this help")

    if command and command.player_index then
      local can_control = is_admin_or_allowed(command)
      if not can_control then
        logging.info("HELP", "Note: Commands marked (admin only) require admin privileges")
      end
    end
  end
)

commands.add_command(
  "metrics-exporter-refresh",
  "Refresh the automatic export timer (admin only)",
  function(command)
    ensure_settings_initialized()
    if not is_admin_or_allowed(command) then
      logging.error("AUTH", "Only admins can refresh the timer")
      return
    end

    update_export_timer()
    logging.info("EXPORT_CONTROL", "Export timer refreshed")
  end
)
