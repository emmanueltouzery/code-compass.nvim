local helpers = require('code_compass.helpers')

local function get_create_queries(word)
  local create_pattern = [[
id: create
language: Java
rule:
  any:
    - pattern:
        context: new #word#($$PARAMS)
        selector: type_identifier

      inside:
        kind: object_creation_expression
    - pattern:
        context: #word#::new
        selector: method_reference
  ]]
  return {create_pattern:gsub('#word#', word)}
end

local function get_default_query(word)
  local references_pattern = [[
id: invocatn
language: Java
rule:
  any:
    - pattern: #word#

      inside:
        kind: method_invocation
---
id: meth_ref
language: Java
rule:
  all:
    - pattern: #word#

      inside:
        kind: method_reference
    - not:
        inside:
          pattern:
            context: #word#::new
            selector: method_reference

---
id: create
language: Java
rule:
  any:
    - pattern:
        context: new #word#($$PARAMS)
        selector: type_identifier

      inside:
        kind: object_creation_expression
    - pattern:
        context: #word#::new
        selector: method_reference

---
id: field
language: Java
rule:
  any:
    - pattern: #word#

      inside:
        kind: field_access

---
id: inherit
language: Java
rule:
  all:
    - kind: type_identifier
      inside:
        stopBy:
          kind: superclass
        kind: superclass
    - regex: #word#

---
id: implemnt
language: Java
rule:
  all:
    - kind: type_identifier
      inside:
        stopBy:
          kind: super_interfaces
        kind: super_interfaces
    - regex: #word#
  ]] -- using regex for inheritance+implement is crappy, i'd have expected pattern to work but it doesn't.
  return references_pattern:gsub('#word#', word)
end

local function get_method_queries(word)
  local references_pattern = [[
id: invocatn
language: Java
rule:
    inside:
      kind: method_invocation
    pattern: #word#
    precedes:
      kind: argument_list
---
id: meth_ref
language: Java
rule:
  all:
    - pattern: #word#

      inside:
        kind: method_reference
    - not:
        pattern:
          context: #word#::new
          selector: method_reference

  ]]
  return {references_pattern:gsub('#word#', word)}
end

-- more lenient for variables, to catch more cases
-- the not is to make sure we don't catch declarations
-- of variables by that name (we only want references)
local function get_variable_queries(word)
  local references_pattern = [[
id: use
language: Java
rule:
  all:
    - kind: identifier
    - pattern: #word#
    - not:
        inside:
          kind: variable_declarator
          has:
            field: name
            pattern: #word#
  ]] -- using regex for inheritance+implement is crappy, i'd have expected pattern to work but it doesn't.
  return {references_pattern:gsub('#word#', word), get_default_query(word)}
end

local function get_references(opts, callback)
  local word = vim.fn.expand('<cword>')
  local bufnr = 0
  local ts_utils = require("nvim-treesitter.ts_utils")
  local ts_node = ts_utils.get_node_at_cursor()
  local parent1 = ts_node:parent()
  if parent1:type() == "variable_declarator"
      and parent1:parent():type() == "field_declaration" then
    local modifiers = nil
    for child in parent1:parent():iter_children() do
      if child:type() == "modifiers" then
        modifiers = child
        break
      end
    end
    if modifiers then
      local row1, col1, row2, col2 = modifiers:range()
      local modifiers_contents = vim.api.nvim_buf_get_text(bufnr, row1, col1, row2, col2, {})[1]
      if modifiers:type() == "modifiers" and modifiers_contents:match("private") then
        -- private field, let's only keep results in the current file
        local run_opts = { search_list = "./" .. vim.fn.expand('%') }
        helpers.run_and_parse_ast_grep(word, get_variable_queries(word), run_opts, callback)
      else
        helpers.run_and_parse_ast_grep(word, get_variable_queries(word), opts, callback)
      end
    else
      helpers.run_and_parse_ast_grep(word, get_variable_queries(word), opts, callback)
    end
  elseif parent1:type() == "variable_declarator" then
    helpers.run_and_parse_ast_grep(word, get_variable_queries(word), opts, callback)
  elseif parent1:type() == "method_declaration" then
    helpers.run_and_parse_ast_grep(word, get_method_queries(word), opts, callback)
  elseif parent1:type() == "constructor_declaration" then
    helpers.run_and_parse_ast_grep(word, get_create_queries(word), opts, callback)
  else
    helpers.run_and_parse_ast_grep(word, {get_default_query(word)}, opts, callback)
  end
end

return {
  get_references = get_references,
}
