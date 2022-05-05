local q = require'vim.treesitter.query'
local parse_query = vim.treesitter.parse_query
local ts_locals = require "nvim-treesitter.locals"
local ts_utils = require "nvim-treesitter.ts_utils"

local lang = 'go'


local get_ts_root = function ()
  local bufnr = 0 -- 0 means current buffer
  local language_tree = vim.treesitter.get_parser(bufnr)
  local syntax_tree = language_tree:parse()
  local root = syntax_tree[1]:root()
  return bufnr, root
end

local M = {}
M.find_structs = function ()
  local query = parse_query(lang, [[
    (type_declaration
      (type_spec
        name: (type_identifier) @struct_name
        type: (struct_type)
      )
    )
  ]])
  local bufnr, root = get_ts_root()
  local res = {}
  for _, captures, _ in query:iter_matches(root, bufnr) do
    table.insert(res, q.get_node_text(captures[1], bufnr))
  end
  return res
end

M.find_interfaces = function ()
  local query = parse_query(lang, [[
    (type_declaration
      (type_spec
        name: (type_identifier) @interface_name
        type: (interface_type)
      )
    )
  ]])
  local bufnr, root = get_ts_root()
  local res = {}
  for _, captures, _ in query:iter_matches(root, bufnr) do
    table.insert(res, q.get_node_text(captures[1], bufnr))
  end
  return res
end



local default_value_from_type = function (t)
  if t == "int" then
    return "0"
  elseif t == "error" then
    return "err"
  elseif t == "bool" then
    return "false"
  elseif t == "string" then
    return '""'
  elseif string.find(t, "*", 1, true) then --starts with * => a pointer
    return "nil"
  elseif string.find(t, "[", 1, true) then --starts with [ => a slice
    return "nil"
  end
  return t .. "{}" -- an empty struct
end

-- ret_values returns a list of initialized values for the function where the cursor is
M.ret_values = function ()
  local query = parse_query(lang, [[
   [
    (method_declaration result: (
     [
      (parameter_list
       (parameter_declaration
        type: (_) @res
       )
      )
      [(type_identifier) (qualified_type) (pointer_type)(slice_type)(map_type)] @res
    ]
   ))
   (function_declaration result: (
     [
      (parameter_list
       (parameter_declaration
        type: (_) @res
       )
      )
      [(type_identifier) (qualified_type) (pointer_type)(slice_type)(map_type)] @res
    ]
   ))
   (func_literal result: (
     [
      (parameter_list
       (parameter_declaration
        type: (_) @res
       )
      )
      [(type_identifier) (qualified_type) (pointer_type)(slice_type)(map_type)] @res
    ]
   ))
   ]
  ]])
  local cursor_node = ts_utils.get_node_at_cursor()
  local scope = ts_locals.get_scope_tree(cursor_node, 0)
  local function_node
  for _, v in ipairs(scope) do
    if v:type() == "function_declaration" or v:type() == "method_declaration" or v:type() == "func_literal" then
      function_node = v
      break
    end
  end
  local res = {}
  if function_node == nil then
    return res
  end
  for _, node in query:iter_captures(function_node, 0) do
    table.insert(res, default_value_from_type(q.get_node_text(node, 0)))
  end
  return res

end


-- find_structs_info returns a table where each element has the form:
--
-- {
--   name = "StructName"
--   fields: {
--     { fname: "theFieldName1", ftype: "theFieldType1"},
--     { fname: "theFieldName2", ftype: "theFieldType2"},
--   }
-- }
--
--
M.find_structs_info = function ()
  local query = parse_query(lang, [[
    (type_declaration
      (type_spec
        name: (type_identifier) @struct_name
        type:
          (struct_type
            (field_declaration_list
              (field_declaration
                name: (field_identifier) @field_name
                type: [
                  (type_identifier)
                  (qualified_type)
                  (slice_type)
                  (map_type)
                  (pointer_type)
                ] @field_type
              )
            )
          )
      )
    )
  ]])
  local bufnr, root = get_ts_root()
  local structs = {}
  for _, captures, _ in query:iter_matches(root, bufnr) do
    local struct_name = q.get_node_text(captures[1], bufnr)
    local field_name = q.get_node_text(captures[2], bufnr)
    local field_type = q.get_node_text(captures[3], bufnr)
    if structs[struct_name] == nil then
      structs[struct_name] = { name = struct_name, fields = {}}
    end
    table.insert(structs[struct_name].fields, {fname= field_name, ftype = field_type})
  end
  local res = {}
  for _, struct_info in pairs(structs) do
    table.insert(res, struct_info)
  end
  return res
end

return M
