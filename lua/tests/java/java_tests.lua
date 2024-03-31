local java_find_def_tests = require('tests.java.java_find_def_tests')
local java_find_refs_tests = require('tests.java.java_find_refs_tests')

local function script_path()
  local str = debug.getinfo(2, 'S').source:sub(2)
  return str:match('(.*/)')
end

local function find_refs_tests_end(passed, failed)
  if #failed == 0 then
    print("All tests passed!")
  else
    print("Failed find refs tests: " .. vim.inspect(failed))
  end
end

local function find_def_tests_end(passed, failed)
  if #failed == 0 then
    print("All find def tests passed!")
  else
    print("Failed find def tests: " .. vim.inspect(failed))
    return
  end
  vim.cmd(":e " .. script_path() .. "Test2.java")
  java_find_refs_tests.run_find_refs_tests(find_refs_tests_end)
end

local function run_tests()
  print("running tests!")
  vim.cmd(":e " .. script_path() .. "Test.java")
  java_find_def_tests.run_find_def_tests(find_def_tests_end)
end

return {
  run_tests = run_tests,
}
