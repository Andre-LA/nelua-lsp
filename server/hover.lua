local sstream = require("nelua.utils.sstream")

local analyze_ast = require("utils.analyze_ast")
local logger = require("utils.logger")
local response = require("utils.response")

---@param current_file string
---@param current_line integer
---@param current_char integer
local function find_pos(current_file, current_line, current_char)
  local i = 0
  local pos = 0
  for line in current_file:gmatch("[^\r\n]*\r?\n") do
    if i == current_line then
      pos = pos + current_char
      return pos + 1
    end
    i = i + 1
    pos = pos + #line
  end
  return pos + 1
end

---@param node table
---@param pos integer
---@param foundnodes table
---@return table?
local function find_nodes_by_pos(node, pos, foundnodes)
  if type(node) ~= "table" then
    return
  end
  if node._astnode and node.pos and pos >= node.pos and node.endpos and pos < node.endpos then
    foundnodes[#foundnodes + 1] = node
  end
  for i = 1, node.nargs or #node do
    find_nodes_by_pos(node[i], pos, foundnodes)
  end
  return foundnodes
end

---@param request_id integer
---@param documents table<string, string>
---@param current_uri string
---@param current_file string
---@param current_file_path string
---@param current_line integer
---@param current_char integer
return function(request_id, documents, current_uri, current_file, current_file_path, current_line, current_char)
  current_file = current_file or documents[current_uri]
  local content = ""
  local ast, err = analyze_ast(current_file, current_file_path)
  if ast then
    local ss = sstream()
    local pos = find_pos(current_file, current_line, current_char)

    local found_nodes = find_nodes_by_pos(ast, pos, {})
    local lastnode = assert(found_nodes)[#found_nodes]

    -- for k, v in pairs(lastnode) do
    --   logger.log(tostring(k) .. "  k")
    --   logger.log(tostring(v) .. "  v")
    -- end

    if lastnode.attr.name then
      ss:addmany(lastnode.attr.name, "\n```nelua\n", "Type: ", lastnode.attr.type, "\n```")
      content = ss:tostring()
    elseif lastnode.attr.type and tostring(lastnode.attr.type) == "string" then
      ss:addmany("```nelua\n", #lastnode.attr.value, " bytes", "\n```")
      content = ss:tostring()
    end
  else
    logger.log(err)
  end
  local hover_response = response.hover(request_id, content)
  io.write(hover_response)
  io.flush()
end
