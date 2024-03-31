local function script_path()
  local str = debug.getinfo(2, 'S').source:sub(2)
  return str:match('(.*/)')
end

local function tests_end(passed, failed)
  if #failed == 0 then
    print("All tests passed!")
  else
    print("Failed tests: " .. vim.inspect(failed))
  end
end

local function after_test3(script_path, passed, failed, res)
  res[1]['fname'] = nil
  local actual = vim.inspect(res)
  print(actual)
  local expected = vim.inspect({{
    bufnr = 0,
    col = 19,
    line = "import com.example.External;",
    lnum = 1,
    path = "lua/tests/java/Test.java"
  }})
  if actual == expected then
    table.insert(passed, 3)
  else
    table.insert(failed, 3)
  end
  tests_end(passed, failed)
end

local function after_test2(script_path, passed, failed, res)
  res[1]['fname'] = nil
  local actual = vim.inspect(res)
  local expected = vim.inspect({{
    bufnr = 0,
    col = 8,
    line = "    int localVar = 2;",
    lnum = 8,
    path = "lua/tests/java/Test.java"
  }})
  if actual == expected then
    table.insert(passed, 2)
  else
    table.insert(failed, 2)
  end
  vim.fn.setpos('.', {0, 10, 8, 0}) -- '>External< val'
  require'code_compass'.find_definition({matches_callback = function(res) after_test3(script_path, passed, failed, res) end})
end

local function after_test1(script_path, passed, failed, res)
  res[1]['fname'] = nil
  local actual = vim.inspect(res)
  local expected = vim.inspect({{
    bufnr = 0,
    col = 17,
    line = "  private String field;",
    lnum = 5,
    path = "lua/tests/java/Test.java"
  }})
  if actual == expected then
    table.insert(passed, 1)
  else
    table.insert(failed, 1)
  end
  vim.fn.setpos('.', {0, 8, 12, 0}) -- 'int >localVar<'
  require'code_compass'.find_definition({matches_callback = function(res) after_test2(script_path, passed, failed, res) end})
end

local function run_tests()
  print("running tests!")
  local script_path = script_path()
  vim.cmd(":e " .. script_path .. "Test.java")
  vim.fn.setpos('.', {0, 11, 14, 0}) -- 'return >field<'
  require'code_compass'.find_definition({matches_callback = function(res) after_test1(script_path, {}, {}, res) end})
end

return {
  run_tests = run_tests,
}
