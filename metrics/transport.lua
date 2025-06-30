-- Transport and Belt Metrics Module
local transport = {}

function transport.collect(surface)
  local transport_data = {
    inserters = {},
    trains = {},
    stations = {}
  }

  -- Inserters
  for _, entity in pairs(surface.find_entities_filtered { type = "inserter" }) do
    local inserter_data = {
      unit_number = entity.unit_number,
      name = entity.name,
      position = { x = entity.position.x, y = entity.position.y },
      direction = entity.direction,
      status = tostring(entity.status)
    }

    -- What the inserter is currently holding
    if entity.held_stack and entity.held_stack.valid_for_read then
      inserter_data.held_stack = {
        name = entity.held_stack.name,
        count = entity.held_stack.count
      }
    end

    table.insert(transport_data.inserters, inserter_data)
  end

  -- Train stations
  for _, entity in pairs(surface.find_entities_filtered { type = "train-stop" }) do
    local station_data = {
      unit_number = entity.unit_number,
      name = entity.name,
      position = { x = entity.position.x, y = entity.position.y },
      backer_name = entity.backer_name,
      trains_count = entity.trains_count,
      trains_limit = entity.trains_limit or 0
    }

    table.insert(transport_data.stations, station_data)
  end
  -- Locomotives and cargo wagons
  for _, entity in pairs(surface.find_entities_filtered { type = "locomotive" }) do
    local train_data = {
      unit_number = entity.unit_number,
      name = entity.name,
      position = { x = entity.position.x, y = entity.position.y },
      orientation = entity.orientation,
      speed = entity.speed or 0
    }

    -- Safe train access
    if entity.train then
      train_data.manual_mode = entity.train.manual_mode or false
      train_data.state = tostring(entity.train.state or "unknown")

      if entity.train.schedule and entity.train.schedule.records then
        train_data.schedule_records_count = #entity.train.schedule.records
      else
        train_data.schedule_records_count = 0
      end
    end

    table.insert(transport_data.trains, train_data)
  end

  return transport_data
end

return transport
