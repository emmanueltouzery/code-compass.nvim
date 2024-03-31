local locals = require("java.compass_java_locals")

local function get_field_access_query()
  local word = vim.fn.expand('<cword>')
  local references_pattern = [[
id: query
language: Java
rule:
  any:
    - pattern: #word#

      inside:
        kind: variable_declarator
  ]]
  return references_pattern:gsub('#word#', word)
end

local function ts_node_get_classname(bufnr, node)
  local cur_node = node
  while cur_node ~= nil and cur_node:type() ~= "class_declaration" do
    cur_node = cur_node:parent()
  end
  if cur_node ~= nil and cur_node:type() == "class_declaration" then
    -- get the class name
    local row1, col1, row2, col2 = cur_node:named_child(1):range()
    return vim.api.nvim_buf_get_text(bufnr, row1, col1, row2, col2, {})[1]
  end
  return nil
end

local function get_default_query()
  local word = vim.fn.expand('<cword>')
  local find_def_pattern = [[
  id: query
  language: Java
  rule:
    any:
      - pattern: #word#

        inside:
          kind: method_declaration
      - pattern: #word#

        inside:
          kind: class_declaration
      - pattern: #word#

        inside:
          kind: interface_declaration
      - pattern: #word#

        inside:
          kind: annotation_type_declaration
      - pattern: #word#

        inside:
          kind: enum_declaration
  ]]
  return find_def_pattern:gsub('#word#', word)
end

local function get_definition_method_reference(ts_node, parent1)
  -- this is a method reference Class::method, and the cursor is on the method
  local methodName = vim.fn.expand('<cword>')
  local row1, col1, row2, col2 = ts_node:prev_sibling():prev_sibling():range()
  local bufnr = vim.api.nvim_win_get_buf(0)
  local className = vim.api.nvim_buf_get_text(bufnr, row1, col1, row2, col2, {})[1]
  if className == "this" then
    -- replace by the current class name
    className = ts_node_get_classname(bufnr, parent1)
  end

  local find_method_reference_def_pattern = [[
    id: query
    language: Java

    utils:
      is-method-identifier:
        inside:
          kind: method_declaration

    rule:
      pattern: #methodName#
      matches: is-method-identifier
      inside:
        stopBy:
          kind: class_declaration
        has:
          pattern: #className#
  ]]
  return find_method_reference_def_pattern:gsub('#methodName#', methodName):gsub('#className#', className)
end

local function get_definition_field_access(ts_node, parent1)
  -- it could be a static field access, Class.FIELD, or a non-static instance.FIELD.
  -- treesitter doesn't know. Let's optimistically try Class.FIELD. If it is in fact
  -- instance.field, then we'll catch that with find_field_access() as a final fallback.
  local fieldName = vim.fn.expand('<cword>')
  local row1, col1, row2, col2 = ts_node:prev_sibling():prev_sibling():range()
  local bufnr = vim.api.nvim_win_get_buf(0)
  local fieldOwner = vim.api.nvim_buf_get_text(bufnr, row1, col1, row2, col2, {})[1]

  if fieldOwner == "this" then
    -- replace by the current class name
    fieldOwner = ts_node_get_classname(bufnr, parent1)
  end

  local find_definition_field_def_pattern = [[
    id: query
    language: Java

    utils:
      is-field-identifier:
        inside:
          stopBy:
            kind: field_declaration
          kind: field_declaration

    rule:
      pattern: #fieldName#
      matches: is-field-identifier
      inside:
        stopBy:
          kind: class_declaration
        has:
          pattern: #className#
  ]]
  return find_definition_field_def_pattern:gsub('#fieldName#', fieldName):gsub('#className#', fieldOwner)
end

local function get_definition_type()
  local bufnr = 0
  local word = vim.fn.expand('<cword>')
  -- if it's a class, let's try to discriminate through package imports
  local q = vim.treesitter.query.parse("java", [[
(import_declaration
  (scoped_identifier
    name: (identifier) @identifier (#eq? @identifier "]] .. word .. [[")))
  ]])

  local parser = require('nvim-treesitter.parsers').get_parser(bufnr, "java")
  local syntax_tree = parser:parse()[1]
  local iter = q:iter_captures(syntax_tree:root(), bufnr, 0, -1)
  local package_statement = nil
  for _capture, node, _metadata in iter do
    local row1, col1, row2, col2 = node:range()
    package_statement = vim.api.nvim_buf_get_lines(bufnr, row1, row1+1, false)[1]
      :gsub("import", "package")
      :gsub("." .. word, "")
  end
  if package_statement == nil then
    return get_default_query()
  end
  local find_def_pattern = [[
    id: query
    language: Java

    utils:
      is-in-package:
        inside:
          stopBy:
            kind: package_declaration
          has:
            pattern: #package#

    rule:
      any:
        - pattern: #word#
          matches: is-in-package

          inside:
            kind: class_declaration
        - pattern: #word#
          matches: is-in-package

          inside:
            kind: interface_declaration
        - pattern: #word#
          matches: is-in-package

          inside:
            kind: enum_declaration
    ]]
    return find_def_pattern:gsub('#package#', package_statement):gsub('#word#', word)
end

local function get_definition_query()
  local ts_utils = require("nvim-treesitter.ts_utils")
  local ts_node = ts_utils.get_node_at_cursor()
  local parent1 = ts_node:parent()
  if parent1:type() == "method_reference" then
    return get_definition_method_reference(ts_node, parent1)
  elseif parent1:type() == "field_access" then
    return get_definition_field_access(ts_node, parent1)
  elseif parent1:type() == "object_creation_expression" or ts_node:type() == "type_identifier" then
    return get_definition_type()
  else
    return get_default_query()
  end
end

local function get_references_query()
  local word = vim.fn.expand('<cword>')
  local references_pattern = [[
id: query
language: Java
rule:
  any:
    - pattern: #word#

      inside:
        kind: method_invocation
    - pattern: #word#

      inside:
        kind: method_reference

    - pattern:
        context: new #word#($$PARAMS)
        selector: type_identifier

      inside:
        kind: object_creation_expression

    - pattern: #word#

      inside:
        kind: field_access
  ]]
  return references_pattern:gsub('#word#', word)
end

return {
  get_references_query = get_references_query,
  get_definition_query = get_definition_query,
  get_field_access_query = get_field_access_query,
  find_local_declarations = locals.find_local_declarations,
}
