local function add_captures(bufnr, start_line, iter, matches)
  for _capture, node, _metadata in iter do
    local row1, col1, row2, col2 = node:range()
    local p1 = node:parent()
    local type = p1 and p1:parent() and p1:parent():type()
    -- fields can be declared before the scope start
    if type == "field_declaration" or row1 >= start_line then
      table.insert(matches, {
        lnum = row1+1,
        col = col1,
        path = vim.fn.expand('%'),
        fname = vim.fn.expand('%:p'),
        bufnr = bufnr,
        line = vim.api.nvim_buf_get_lines(bufnr, row1, row1+1, false)[1]
      })
    end
  end
end

-- for instance
--    mProcessingThread = new Thread(new Runnable() {
--      @Override
--      public void run() { .. }
--
-- yes, run() is a method declaration, but it's not where i should stop
-- when i'm looking for the scope start -> ignore it for that purpose
local function is_not_local_lambda(node)
  local cur_node = node
  while cur_node ~= nil and cur_node:type() ~= "object_creation_expression" do
    cur_node = cur_node:parent()
  end
  return cur_node == nil or cur_node:type() ~= "object_creation_expression"
end

local function find_scope_start_line(syntax_tree, bufnr)
  local cur_scope_start = 0
  local lnum = vim.fn.line('.') -- TODO bufnr but i read the line from the current window
  local q = vim.treesitter.query.parse("java", [[
(method_declaration) @capture

(constructor_declaration) @capture
  ]])
  local iter = q:iter_captures(syntax_tree:root(), bufnr, 0, -1)
  for _capture, node, _metadata in iter do
    if is_not_local_lambda(node) then
      local row1, col1, row2, col2 = node:range()
      if row1 < lnum and row1 > cur_scope_start then
        cur_scope_start = row1
      end
    end
  end
  return cur_scope_start
end

local function attempt_import_declaration_java(syntax_tree, bufnr, matches, word)
  local q = vim.treesitter.query.parse("java", [[
(import_declaration
  (scoped_identifier
    (identifier) @identifier (#eq? @identifier "]] .. word .. [[")))
  ]])
  local iter = q:iter_captures(syntax_tree:root(), bufnr, 0, -1)
  add_captures(bufnr, 0, iter, matches)
  return matches
end

local function find_all_local_declarations()
  local word = vim.fn.expand('<cword>')
  local bufnr = 0

  local q = vim.treesitter.query.parse("java", [[
(local_variable_declaration
  declarator:
    (variable_declarator
      name: (identifier) @identifier (#eq? @identifier "]] .. word .. [[")))

(field_declaration
  declarator:
    (variable_declarator
      name: (identifier) @identifier (#eq? @identifier "]] .. word .. [[")))

(formal_parameter
  name: (identifier) @identifier (#eq? @identifier "]] .. word .. [["))

(catch_formal_parameter
  name: (identifier) @identifier (#eq? @identifier "]] .. word .. [["))

(inferred_parameters
  (identifier) @identifier (#eq? @identifier "]] .. word .. [[")) ; (x,y) -> ...

(lambda_expression
  parameters: (identifier) @identifier (#eq? @identifier "]] .. word .. [[")) ; x -> ...
  ]])

  local parser = require('nvim-treesitter.parsers').get_parser(bufnr, "java")
  local syntax_tree = parser:parse()[1]
  local iter = q:iter_captures(syntax_tree:root(), bufnr, 0, -1)
  local module_fnames = {vim.fn.expand('%:p')} -- immediately add the current file
  local matches = {}
  local start_line = find_scope_start_line(syntax_tree, bufnr)
  add_captures(bufnr, start_line, iter, matches)
  if #matches == 0 then
    return attempt_import_declaration_java(syntax_tree, bufnr, matches, word)
  else
    return matches
  end
end

local function find_local_declarations()
  local matches = find_all_local_declarations()

  local filtered_matches = {}
  local cur_line = vim.fn.line('.')
  -- keep only matches up to the current row (cannot use variables
  -- defined later on), and keep only the last one such (the same
  -- variable name can be used multiple times in the current file, we
  -- want the latest declaration before the current line)
  local latest_match = nil
  for _, match in ipairs(matches) do
    if match.lnum <= cur_line then
      latest_match = match
    else
      break
    end
  end
  if latest_match ~= nil then
    return { latest_match }
  else
    return {}
  end
end



local function find_import(class_name, opts)
  local bufnr = 0
  local matches = {}
  local parser = require('nvim-treesitter.parsers').get_parser(bufnr, "java")
  local syntax_tree = parser:parse()[1]
  return attempt_import_declaration_java(syntax_tree, bufnr, matches, class_name)
end

return {
  find_local_declarations = find_local_declarations,
  find_import = find_import,
}
