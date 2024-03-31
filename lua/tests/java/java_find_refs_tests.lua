local function after_test1(script_path, passed, failed, after, res)
  res[1]['fname'] = nil
  res[1]['path'] = res[1].path:gmatch("[^/]+$")()
  local actual = vim.inspect(res)
  local expected = vim.inspect({{
    col = 44,
    line = 'Arrays.asList("a", "b").forEach(Test2::transformString);',
    lnum = 22,
    path = "Test.java"
  }})
  if actual == expected then
    table.insert(passed, 1)
  else
    table.insert(failed, 1)
  end
  after(passed, failed)
end

local function run_find_refs_tests(after)
  vim.fn.setpos('.', {0, 12, 21, 0}) -- 'String >transformString<('
  require'code_compass'.find_references({matches_callback = function(res) after_test1(script_path, {}, {}, after, res) end})
end

return {
  run_find_refs_tests = run_find_refs_tests,
}
