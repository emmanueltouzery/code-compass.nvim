local java_tests = require('tests.java.java_tests')

local function run_tests()
  java_tests.run_tests()
end

return {
  run_tests = run_tests,
}
