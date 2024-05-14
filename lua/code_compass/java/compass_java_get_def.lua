local locals = require("code_compass.java.compass_java_locals")
local helpers = require('code_compass.helpers')

local function run_finish(matches, opts)
  if #matches == 0 then
    -- couldn't find global declarations, could be a local variable
    -- or a field of the current class
    matches = locals.find_local_declarations()
  end
  local get_field_access_query = nil
  if #matches == 0 then
    if vim.bo.filetype == 'java' then
      get_field_access_query = get_field_access_query
    end
  end
  if #matches == 0 and get_field_access_query ~= nil then
    -- still couldn't find anything. it could be accessing a field on
    -- another class (for instance a public final field)
    -- i don't like to check that too early, because i could grab
    -- a field on a completely unrelated class.. but if nothing else
    -- worked, let's try this now
    local word = vim.fn.expand('<cword>')
    helpers.run_and_parse_ast_grep(word, {get_field_access_query()}, opts, function(matches)
      if opts ~= nil and opts.matches_callback ~= nil then
        opts.matches_callback(matches)
      else
        helpers.picker_finish(matches)
      end
    end)
    return
  end
  if opts ~= nil and opts.matches_callback ~= nil then
    opts.matches_callback(matches)
  else
    helpers.picker_finish(matches)
  end
end

local function queries_with_local_fallback(queries, word, opts)
  if queries ~= nil and #queries > 0 then
    helpers.run_and_parse_ast_grep(word, queries, opts, function(res) run_finish(res, opts) end)
  else
    -- no query, try locals
    run_finish(locals.find_local_declarations(), opts)
  end
end

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

local function get_definition_method_reference_classname(className, parent1)
  local methodName = vim.fn.expand('<cword>')
  if className == "this" then
    -- replace by the current class name
    local bufnr = vim.api.nvim_win_get_buf(0)
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
  return {
    find_method_reference_def_pattern:gsub('#methodName#', methodName):gsub('#className#', className),
    -- get_default_query() as fallback because maybe we inherit and the definition is in a superclass
    get_default_query()
  }
end

local function get_definition_method_reference(ts_node, parent1)
  -- this is a method reference Class::method, and the cursor is on the method
  local methodName = vim.fn.expand('<cword>')
  local row1, col1, row2, col2 = ts_node:prev_sibling():prev_sibling():range()
  local bufnr = vim.api.nvim_win_get_buf(0)
  local className = vim.api.nvim_buf_get_text(bufnr, row1, col1, row2, col2, {})[1]
  return get_definition_method_reference_classname(className, ts_node)
end

local function get_superclass(node)
  local parent = node
  while parent ~= nil and parent:type() ~= "class_declaration" do
    parent = parent:parent()
  end
  if parent ~= nil then
    for node in parent:iter_children() do
      if node:type() == "superclass" then
        for child_node in node:iter_children() do
          if child_node:type() == "type_identifier" then
            local row1, col1, row2, col2 = child_node:range()
            return vim.api.nvim_buf_get_text(0, row1, col1, row2, col2, {})[1]
          end
        end
      end
    end
  end
  return nil
end

local function get_next_superclasses(sofar, superclass, callback)
  local find_superclass_pattern = [[
    id: superclass
    language: Java

    rule:
      kind: type_identifier
      inside:
        kind: superclass
        inside:
          kind: class_declaration
          has:
            pattern: #className#
  ]]
  helpers.run_and_parse_ast_grep(superclass, {find_superclass_pattern:gsub("#className#", superclass)}, opts, function(res)
    if #res >= 1 then
      -- TODO could be multiple matches.. would have to loop
      local className = helpers.str_sub(res[1].line, res[1].col+1):gmatch("([A-Z]%w+)")()
      table.insert(sofar, className)
      get_next_superclasses(sofar, className, callback)
    else
      callback(sofar)
    end
  end)
end

local function get_all_superclasses(node, callback)
  local level1 = get_superclass(node)
  if level1 == nil then
    return {}
  end
  local superclasses = {level1}
  get_next_superclasses({level1}, level1, callback)
end

local function get_definition_field_access(ts_node, parent1, opts)
  -- it could be a static field access, Class.FIELD, or a non-static instance.FIELD.
  -- treesitter doesn't know. Let's optimistically try Class.FIELD. If it is in fact
  -- and instance field, we expect it should be a local field of the current class,
  -- and it'll be covered by the local declarations final fallback, and finally as
  -- a worst-case, by get_field_access_query()
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
        all:
          - inside:
              stopBy:
                kind: field_declaration
              kind: field_declaration
          - inside:
              stopBy:
                kind: variable_declarator
              has:
                field: name
                pattern: #fieldName#
      is-enum-field:
        inside:
          stopBy:
            kind: enum_constant
          kind: enum_constant

    rule:
      any:
        - pattern: #fieldName#
          matches: is-field-identifier
          inside:
            stopBy:
              kind: class_declaration
            has:
              pattern: #className#
        - pattern: #fieldName#
          matches: is-enum-field
          inside:
            stopBy:
              kind: enum_declaration
            has:
              pattern: #className#
  ]]
  get_all_superclasses(parent1, function(superclasses)
    -- no defaulting to default queries here: this is field access,
    -- let's not search fields by name across the entire codebase,
    -- let's default to only the current file (locals) by default
    local candidates = {
      find_definition_field_def_pattern:gsub('#fieldName#', fieldName):gsub('#className#', fieldOwner),
    }
    for _, superclass in ipairs(superclasses) do
      local fmt = find_definition_field_def_pattern:gsub('#fieldName#', fieldName):gsub('#className#', superclass)
      table.insert(candidates, fmt)
    end
    queries_with_local_fallback(candidates, fieldName, opts)
  end)
end

local function get_definition_method_invocation(ts_node, parent1)
  -- it could be a static field access, Class.FIELD, or a non-static instance.FIELD.
  -- treesitter doesn't know. Let's optimistically try Class.FIELD.
  local methodName = vim.fn.expand('<cword>')
  local row1, col1, row2, col2 = ts_node:prev_sibling():prev_sibling():range()
  local bufnr = vim.api.nvim_win_get_buf(0)
  local fieldOwner = vim.api.nvim_buf_get_text(bufnr, row1, col1, row2, col2, {})[1]

  if fieldOwner == "this" then
    -- replace by the current class name
    fieldOwner = ts_node_get_classname(bufnr, parent1)
  end

  local find_definition_method_def_pattern = [[
    id: query
    language: Java

    utils:
      is-method-identifier:
        inside:
          kind: method_declaration

    rule:
      any:
        - pattern: #methodName#
          matches: is-method-identifier
          inside:
            stopBy:
              kind: class_declaration
            has:
              pattern: #className#
  ]]
  return {
    find_definition_method_def_pattern:gsub('#methodName#', methodName):gsub('#className#', fieldOwner),
    -- get_default_query() as fallback because maybe we inherit and the definition is in a superclass
    get_default_query()
  }
end

local function get_definition_type_no_package(word)
  local find_def_pattern = [[
    id: query
    language: Java

    rule:
      any:
        - pattern: #word#

          inside:
            kind: class_declaration
        - pattern: #word#

          inside:
            kind: interface_declaration
        - pattern: #word#

          inside:
            kind: enum_declaration
    ]]
    return find_def_pattern:gsub('#word#', word)
end

local function get_definition_type(parent1)
  local bufnr = 0
  local word = vim.fn.expand('<cword>')

  if word == "this" then
    -- replace by the current class name
    local bufnr = vim.api.nvim_win_get_buf(0)
    word = ts_node_get_classname(bufnr, parent1)
  end

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
    return {get_definition_type_no_package(word), get_default_query()}
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
    return {
      find_def_pattern:gsub('#package#', package_statement):gsub('#word#', word),
      get_default_query()
    }
end

local function constructors(class_name)
  local ctor_pattern = [[
    id: ctor
    language: Java
    rule:
        inside:
           kind: constructor_declaration
        pattern: #word#
  ]]
  return {
    ctor_pattern:gsub('#word#', class_name),
    get_default_query()
  }
end

local function constructor_invocation(parent1, opts)
  local superclass = get_superclass(parent1)
  if superclass ~= nil then
    helpers.run_and_parse_ast_grep(superclass, constructors(superclass), opts, function(res)
      if #res > 0 then
        run_finish(res, opts)
      else
        -- couldn't find a constructor in the whole project. Assume the parent class is
        -- provided by a dependency and search for the import statement.
        run_finish(locals.find_import(superclass), opts)
      end
    end)
  end
end

local function get_definition(opts)
  local word = vim.fn.expand('<cword>')
  local ts_utils = require("nvim-treesitter.ts_utils")
  local ts_node = ts_utils.get_node_at_cursor()
  local parent1 = ts_node:parent()
  if parent1:type() == "method_reference" and ts_node:prev_sibling() ~= nil then
     queries_with_local_fallback(get_definition_method_reference(ts_node, parent1), word, opts)
  elseif parent1:type() == "method_reference" and ts_node:prev_sibling() == nil then
    queries_with_local_fallback(get_definition_type(parent1), word, opts)
  elseif parent1:type() == "field_access" and ts_node:prev_sibling() ~= nil then
    get_definition_field_access(ts_node, parent1, opts)
  elseif parent1:type() == "method_invocation" and ts_node:prev_sibling() ~= nil then
    queries_with_local_fallback(get_definition_method_invocation(ts_node, parent1), word, opts)
  elseif parent1:type() == "method_invocation"
      and ts_node:prev_sibling() == nil
      and ts_node:next_sibling():type() == "argument_list" then
    -- [X]()
    -- presumably a method of the current class.. could also be inherited so let's allow other files
    queries_with_local_fallback(get_definition_method_reference_classname("this", ts_node), word, opts)
  elseif parent1:type() == "method_invocation"
      and ts_node:prev_sibling() == nil
      and ts_node:next_sibling():type() ~= "argument_list" then
    -- [X].method()
    -- it could be a class if it's a static method call, or a local variable presumably
    if vim.fn.expand('<cword>'):sub(1, 1):match('[A-Z]') then
      -- capitalized => assume class
      queries_with_local_fallback(get_definition_type(parent1), word, opts)
    else
      -- assume local
      queries_with_local_fallback(nil, word, opts)
    end
  elseif parent1:type() == "object_creation_expression" or ts_node:type() == "type_identifier" then
    queries_with_local_fallback(get_definition_type(parent1), word, opts)
  elseif parent1:type() == "explicit_constructor_invocation" and ts_node:type() == "super" then
    constructor_invocation(parent1, opts)
  else
    queries_with_local_fallback({get_default_query()}, word, opts)
  end
end

return {
  get_field_access_query = get_field_access_query,
  get_definition = get_definition,
}
