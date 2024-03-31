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

local function get_definition_query()
  local ts_utils = require("nvim-treesitter.ts_utils")
  local ts_node = ts_utils.get_node_at_cursor()
  local parent1 = ts_node:parent()
  if parent1:type() == "method_reference" then
    -- this is a method reference Class::method, and the cursor is on the method
    local methodName = vim.fn.expand('<cword>')
    local row1, col1, row2, col2 = ts_node:prev_sibling():prev_sibling():range()
    local bufnr = vim.api.nvim_win_get_buf(0)
    local className = vim.api.nvim_buf_get_text(bufnr, row1, col1, row2, col2, {})[1]
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
  elseif parent1:type() == "field_access" then
    -- it could be a static field access, Class.FIELD, or a non-static instance.FIELD.
    -- treesitter doesn't know. Let's optimistically try Class.FIELD. If it is in fact
    -- instance.field, then we'll catch that with find_field_access() as a final fallback.
    local fieldName = vim.fn.expand('<cword>')
    local row1, col1, row2, col2 = ts_node:prev_sibling():prev_sibling():range()
    local bufnr = vim.api.nvim_win_get_buf(0)
    local fieldOwner = vim.api.nvim_buf_get_text(bufnr, row1, col1, row2, col2, {})[1]

    if fieldOwner == "this" then
      local cur_node = parent1
      -- replace by the current class name
      while cur_node ~= nil and cur_node:type() ~= "class_declaration" do
        cur_node = cur_node:parent()
      end
      if cur_node:type() == "class_declaration" then
        -- get the class name
        local row1, col1, row2, col2 = cur_node:named_child(1):range()
        fieldOwner = vim.api.nvim_buf_get_text(bufnr, row1, col1, row2, col2, {})[1]
      end
    end
    print(fieldOwner)

    local find_method_reference_def_pattern = [[
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
    return find_method_reference_def_pattern:gsub('#fieldName#', fieldName):gsub('#className#', fieldOwner)
  else
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
