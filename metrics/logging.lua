-- Centralized Logging Helper Module
local logging = {}

-- Configuration: Set to false to disable all debug logging
local DEBUG_ENABLED = false

-- Log levels
local LOG_LEVELS = {
  DEBUG = 1,
  INFO = 2,
  WARN = 3,
  ERROR = 4
}

-- Current log level (only messages at this level or higher will be shown)
local CURRENT_LOG_LEVEL = LOG_LEVELS.DEBUG

-- Helper function to check if logging is enabled for a given level
local function should_log(level)
  return DEBUG_ENABLED and level >= CURRENT_LOG_LEVEL
end

-- Main logging function
local function log_message(level, category, message)
  if not should_log(level) then
    return
  end

  local level_names = {
    [LOG_LEVELS.DEBUG] = "DEBUG",
    [LOG_LEVELS.INFO] = "INFO",
    [LOG_LEVELS.WARN] = "WARN",
    [LOG_LEVELS.ERROR] = "ERROR"
  }

  local prefix = "[METRICS:" .. level_names[level] .. "]"
  if category then
    prefix = prefix .. "[" .. category .. "]"
  end

  game.print(prefix .. " " .. message)
end

-- Public logging functions
function logging.debug(category, message)
  log_message(LOG_LEVELS.DEBUG, category, message)
end

function logging.info(category, message)
  log_message(LOG_LEVELS.INFO, category, message)
end

function logging.warn(category, message)
  log_message(LOG_LEVELS.WARN, category, message)
end

function logging.error(category, message)
  log_message(LOG_LEVELS.ERROR, category, message)
end

-- Convenience functions for common categories
function logging.collection(message)
  logging.debug("COLLECTION", message)
end

function logging.export(message)
  logging.info("EXPORT", message)
end

function logging.surface(surface_name, message)
  logging.debug("SURFACE:" .. surface_name, message)
end

function logging.force(force_name, message)
  logging.debug("FORCE:" .. force_name, message)
end

-- Configuration functions
function logging.enable()
  DEBUG_ENABLED = true
end

function logging.disable()
  DEBUG_ENABLED = false
end

function logging.is_enabled()
  return DEBUG_ENABLED
end

function logging.set_level(level_name)
  local level = LOG_LEVELS[string.upper(level_name)]
  if level then
    CURRENT_LOG_LEVEL = level
  else
    logging.error("LOGGING", "Invalid log level: " .. tostring(level_name))
  end
end

return logging
