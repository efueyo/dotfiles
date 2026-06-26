local q = require("vim.treesitter")
local parse_query = vim.treesitter.query.parse

local lang = "go"

local get_ts_root = function()
	local bufnr = 0 -- 0 means current buffer
	local language_tree = vim.treesitter.get_parser(bufnr)
	local syntax_tree = language_tree:parse()
	local root = syntax_tree[1]:root()
	return bufnr, root
end

local M = {}
M.find_structs = function()
	local query = parse_query(
		lang,
		[[
    (type_declaration
      (type_spec
        name: (type_identifier) @struct_name
        type: (struct_type)
      )
    )
  ]]
	)
	local bufnr, root = get_ts_root()
	local res = {}
	-- Single capture (@struct_name); iter_captures yields one node at a time,
	-- avoiding the list-of-nodes semantics `iter_matches` gained in Neovim 0.11+.
	for _, node in query:iter_captures(root, bufnr) do
		table.insert(res, q.get_node_text(node, bufnr))
	end
	return res
end

M.find_interfaces = function()
	local query = parse_query(
		lang,
		[[
    (type_declaration
      (type_spec
        name: (type_identifier) @interface_name
        type: (interface_type)
      )
    )
  ]]
	)
	local bufnr, root = get_ts_root()
	local res = {}
	-- Single capture (@interface_name); see find_structs for why iter_captures.
	for _, node in query:iter_captures(root, bufnr) do
		table.insert(res, q.get_node_text(node, bufnr))
	end
	return res
end

local default_value_from_type = function(t)
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
	elseif string.find(t, "<-", 1, true) then --starts with <- => a channel
		return "nil"
	end
	return t .. "{}" -- an empty struct
end

-- ret_values returns a list of initialized values for the function where the cursor is
M.ret_values = function()
	local query = parse_query(
		lang,
		[[
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
  ]]
	)
	local cur_node = vim.treesitter.get_node()
	local function_node
	while cur_node do
		if
			cur_node:type() == "function_declaration"
			or cur_node:type() == "method_declaration"
			or cur_node:type() == "func_literal"
		then
			function_node = cur_node
			break
		end
		cur_node = cur_node:parent()
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
M.find_structs_info = function()
	local query = parse_query(
		lang,
		[[
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
  ]]
	)
	local bufnr, root = get_ts_root()
	local capture_names = query.captures
	local structs = {}
	local order = {}
	local current
	-- iter_captures yields captures in document order: each @struct_name is
	-- followed by its (@field_name, @field_type) pairs. Group them as we go
	-- rather than relying on iter_matches, whose multi-node capture semantics
	-- changed in Neovim 0.11+.
	for id, node in query:iter_captures(root, bufnr) do
		local cname = capture_names[id]
		local text = q.get_node_text(node, bufnr)
		if cname == "struct_name" then
			if structs[text] == nil then
				structs[text] = { name = text, fields = {} }
				table.insert(order, text)
			end
			current = structs[text]
		elseif cname == "field_name" and current then
			table.insert(current.fields, { fname = text, ftype = nil })
		elseif cname == "field_type" and current and #current.fields > 0 then
			current.fields[#current.fields].ftype = text
		end
	end
	local res = {}
	for _, name in ipairs(order) do
		table.insert(res, structs[name])
	end
	return res
end

return M
