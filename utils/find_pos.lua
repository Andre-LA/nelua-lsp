---@param current_file string
---@param current_line integer
---@param current_char integer
---@return integer
return function(current_file, current_line, current_char)
  local i = 0
  local pos = 0
  for line in current_file:gmatch("[^\r\n]*\r?\n") do
    if i == current_line then
      pos = pos + current_char
      break
    end
    i = i + 1
    pos = pos + #line
  end
  return pos + 1
end
