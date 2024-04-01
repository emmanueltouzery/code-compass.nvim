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
    -- - pattern:
    --     context: #word#
    --     selector: type_identifier
  return references_pattern:gsub('#word#', word)
end

return {
  get_references_query = get_references_query,
}
