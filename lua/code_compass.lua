local tests = require('tests.tests')
local code_compass_get_refs = require('code_compass.code_compass_get_refs')
local code_compass_get_def = require('code_compass.code_compass_get_def')

return {
  find_references = code_compass_get_refs.find_references,
  find_definition = code_compass_get_def.find_definition,
  run_tests = tests.run_tests,
}
