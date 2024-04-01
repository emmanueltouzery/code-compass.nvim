local function get_references_query()
  local word = vim.fn.expand('<cword>')
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
  any:
    - pattern: #word#

      inside:
        kind: method_reference

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
  ]] -- using regex for inheritance is crappy, i'd have expected pattern to work but it doesn't.
  return references_pattern:gsub('#word#', word)
end

return {
  get_references_query = get_references_query,
}
