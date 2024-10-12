local function fix_fname_path(res)
  for _, v in ipairs(res) do
    v['fname'] = nil
    v['path'] = v.path:gmatch("[^/]+$")()
  end
end

local function after_test10(script_path, passed, failed, after, res)
  fix_fname_path(res)
  local actual = vim.inspect(res)
  local expected = vim.inspect({{
    col = 11,
    line = "   throw new Test2.Nested(\"bad\");",
    lnum = 95,
    path = "Test.java",
    query_name = "create"
  }})
  if actual == expected then
    table.insert(passed, 10)
  else
    table.insert(failed, 10)
  end
  after(passed, failed)
end

local function after_test9(script_path, passed, failed, after, res)
  fix_fname_path(res)
  local actual = vim.inspect(res)
  local expected = vim.inspect({{
    col = 11,
    line = "   throw new Test2.Nested(\"bad\");",
    lnum = 95,
    path = "Test.java",
    query_name = "create"
  }})
  if actual == expected then
    table.insert(passed, 9)
  else
    table.insert(failed, 9)
  end
  after(passed, failed)
  vim.fn.setpos('.', {0, 31, 13, 0}) -- 'public >Nested<(String p) {}'
  require'code_compass'.find_references({matches_callback = function(res) after_test10(script_path, passed, failed, after, res) end})
end


local function after_test8(script_path, passed, failed, after, res)
  fix_fname_path(res)
  local actual = vim.inspect(res)
  local expected = vim.inspect({{
    col = 17,
    line = "   return this.field;",
    lnum = 21,
    path = "Test2.java",
    query_name = "use"
  }})
  if actual == expected then
    table.insert(passed, 8)
  else
    table.insert(failed, 8)
  end
  after(passed, failed)
  vim.fn.setpos('.', {0, 30, 25, 0}) -- 'public static class >Nested< {'
  require'code_compass'.find_references({matches_callback = function(res) after_test9(script_path, passed, failed, after, res) end})
end

local function after_test7(script_path, passed, failed, after, res)
  fix_fname_path(res)
  local actual = vim.inspect(res)
  local expected = vim.inspect({{
    col = 10,
    line = "   (new Test2()).function1();",
    lnum = 17,
    path = "Test.java",
    query_name = "create"
  }, {
    col = 23,
    line = "   Test2 myVar = new Test2();",
    lnum = 39,
    path = "Test.java",
    query_name = "create"
  }, {
    col = 37,
    line = '   Arrays.asList("a", "b").forEach(Test2::new);',
    lnum = 60,
    path = "Test.java",
    query_name = "create"
  }})
  if actual == expected then
    table.insert(passed, 7)
  else
    table.insert(failed, 7)
  end
  vim.fn.setpos('.', {0, 18, 20, 0}) -- 'private String >field<(;'
  require'code_compass'.find_references({matches_callback = function(res) after_test8(script_path, passed, failed, after, res) end})
end

local function after_test6(script_path, passed, failed, after, res)
  fix_fname_path(res)
  local actual = vim.inspect(res)
  local expected = vim.inspect({{
    col = 5,
    line = "   anyName();",
    lnum = 14,
    path = "Test2.java",
    query_name = "invocatn"
  }})
  if actual == expected then
    table.insert(passed, 6)
  else
    table.insert(failed, 6)
  end
  vim.fn.setpos('.', {0, 24, 13, 0}) -- 'public >Test2<('
  require'code_compass'.find_references({matches_callback = function(res) after_test7(script_path, passed, failed, after, res) end})
end

local function after_test5(script_path, passed, failed, after, res)
  fix_fname_path(res)
  local actual = vim.inspect(res)
  local expected = vim.inspect({{
    col = 27,
    line = "   TestEnum v = TestEnum.V1;",
    lnum = 18,
    path = "Test.java",
    query_name = "field",
  }})
  if actual == expected then
    table.insert(passed, 5)
  else
    table.insert(failed, 5)
  end
  vim.fn.setpos('.', {0, 20, 17, 0}) -- 'void >anyName<('
  require'code_compass'.find_references({matches_callback = function(res) after_test6(script_path, passed, failed, after, res) end})
end

local function after_test4(script_path, passed, failed, after, res)
  fix_fname_path(res)
  local actual = vim.inspect(res)
  local expected = vim.inspect({{
    col = 10,
    line = "   (new Test2()).function1();",
    lnum = 17,
    path = "Test.java",
    query_name = "create"
  }, {
    col = 23,
    line = "   Test2 myVar = new Test2();",
    lnum = 39,
    path = "Test.java",
    query_name = "create"
  }, {
    col = 37,
    line = '   Arrays.asList("a", "b").forEach(Test2::new);',
    lnum = 60,
    path = "Test.java",
    query_name = "create"
  }, {
    col = 33,
    line = "   External var = new External(Test2.MY_CONST);",
    lnum = 12,
    path = "Test.java",
    query_name = "field"
  }, {
    col = 46,
    line = " private List<Integer> vals = Arrays.asList(Test2.MY_CONST);",
    lnum = 43,
    path = "Test.java",
    query_name = "field"
  }, {
    col = 44,
    line = "blic class Test extends Test2 implements Test2 {",
    lnum = 5,
    path = "Test.java",
    query_name = "implemnt"
  }, {
    col = 27,
    line = "blic class Test extends Test2 implements Test2 {",
    lnum = 5,
    path = "Test.java",
    query_name = "inherit"
  }, {
    col = 5,
    line = '   Test2.transformString("te");',
    lnum = 34,
    path = "Test.java",
    query_name = "invocatn"
  }, {
    col = 5,
    line = "   Test2.overloaded();",
    lnum = 71,
    path = "Test.java",
    query_name = "invocatn"
  }, {
    col = 5,
    line = '   Test2.overloaded("test");',
    lnum = 72,
    path = "Test.java",
    query_name = "invocatn"
  }, {
    col = 37,
    line = '   Arrays.asList("a", "b").forEach(Test2::transformString);',
    lnum = 24,
    path = "Test.java",
    query_name = "meth_ref"
  }})
  if actual == expected then
    table.insert(passed, 4)
  else
    table.insert(failed, 4)
  end
  vim.fn.setpos('.', {0, 8, 6, 0}) -- '>V1<,'
  require'code_compass'.find_references({matches_callback = function(res) after_test5(script_path, passed, failed, after, res) end})
end

local function after_test3(script_path, passed, failed, after, res)
  fix_fname_path(res)
  local actual = vim.inspect(res)
  local expected = vim.inspect({{
    col = 39,
    line = "   External var = new External(Test2.MY_CONST);",
    lnum = 12,
    path = "Test.java",
    query_name = "use"
  }, {
    col = 52,
    line = " private List<Integer> vals = Arrays.asList(Test2.MY_CONST);",
    lnum = 43,
    path = "Test.java",
    query_name = "use"
  }, {
    col = 20,
    line = "   int localVar = MY_CONST;",
    lnum = 13,
    path = "Test2.java",
    query_name = "use"
  }})
  if actual == expected then
    table.insert(passed, 3)
  else
    table.insert(failed, 3)
  end
  vim.fn.setpos('.', {0, 1, 16, 0}) -- 'class >Test2< {'
  require'code_compass'.find_references({matches_callback = function(res) after_test4(script_path, passed, failed, after, res) end})
end

local function after_test2(script_path, passed, failed, after, res)
  fix_fname_path(res)
  local actual = vim.inspect(res)
  local expected = vim.inspect({{
    col = 19,
    line = "   (new Test2()).function1();",
    lnum = 17,
    path = "Test.java",
    query_name = "invocatn",
  }})
  if actual == expected then
    table.insert(passed, 2)
  else
    table.insert(failed, 2)
  end
  vim.fn.setpos('.', {0, 3, 23, 0}) -- 'int >MY_CONST< ='
  require'code_compass'.find_references({matches_callback = function(res) after_test3(script_path, passed, failed, after, res) end})
end

local function after_test1(script_path, passed, failed, after, res)
  fix_fname_path(res)
  local actual = vim.inspect(res)
  local expected = vim.inspect({{
    col = 11,
    line = '   Test2.transformString("te");',
    lnum = 34,
    path = "Test.java",
    query_name = "invocatn",
  }, {
    col = 11,
    line = '   myVar.transformString("te");',
    lnum = 40,
    path = "Test.java",
    query_name = "invocatn"
  }, {
    col = 44,
    line = '   Arrays.asList("a", "b").forEach(Test2::transformString);',
    lnum = 24,
    path = "Test.java",
    query_name = "meth_ref",
  }, { -- TODO this match is wrong.. this is refering to transformString in another class
    col = 43,
    line = '   Arrays.asList("a", "b").forEach(this::transformString);',
    lnum = 33,
    path = "Test.java",
    query_name = "meth_ref",
  }})
  if actual == expected then
    table.insert(passed, 1)
  else
    table.insert(failed, 1)
  end
  vim.fn.setpos('.', {0, 5, 21, 0}) -- 'void >function1<()'
  require'code_compass'.find_references({matches_callback = function(res) after_test2(script_path, passed, failed, after, res) end})
end

local function run_find_refs_tests(after)
  vim.fn.setpos('.', {0, 12, 21, 0}) -- 'String >transformString<('
  require'code_compass'.find_references({matches_callback = function(res) after_test1(script_path, {}, {}, after, res) end})
end

return {
  run_find_refs_tests = run_find_refs_tests,
}
