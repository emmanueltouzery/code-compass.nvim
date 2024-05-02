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

local function get_references_queries()
  local word = vim.fn.expand('<cword>')
  local ts_utils = require("nvim-treesitter.ts_utils")
  local ts_node = ts_utils.get_node_at_cursor()
  local parent1 = ts_node:parent()
  if parent1:type() == "variable_declarator" then
    return get_variable_queries(word)
  elseif parent1:type() == "method_declaration" then
    return get_method_queries(word)
  elseif parent1:type() == "constructor_declaration" then
    return get_create_queries(word)
  else
    return {get_default_query(word)}
  end
end

return {
  get_references_queries = get_references_queries,
}
