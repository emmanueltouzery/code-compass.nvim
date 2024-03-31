local function add_captures(bufnr, iter, matches)
  for _capture, node, _metadata in iter do
    local row1, col1, row2, col2 = node:range()
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

local function attempt_import_declaration_java(syntax_tree, bufnr, matches, word)
  local q = vim.treesitter.query.parse("java", [[
(import_declaration
  (scoped_identifier
    (identifier) @identifier (#eq? @identifier "]] .. word .. [[")))
  ]])
  local iter = q:iter_captures(syntax_tree:root(), bufnr, 0, -1)
  add_captures(bufnr, iter, matches)
  return matches
end

local function find_local_declarations()
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
  add_captures(bufnr, iter, matches)
  if #matches == 0 then
    return attempt_import_declaration_java(syntax_tree, bufnr, matches, word)
  else
    return matches
  end
end

return {
  find_local_declarations = find_local_declarations,
}
