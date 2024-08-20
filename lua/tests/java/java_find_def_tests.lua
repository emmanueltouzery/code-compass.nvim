local function fix_fname_path(res)
  for _, v in ipairs(res) do
    v['fname'] = nil
    v['path'] = v.path:gmatch("[^/]+$")()
  end
end

local function after_test32(script_path, passed, failed, after, res)
  fix_fname_path(res)
  local actual = vim.inspect(res)
  local expected = vim.inspect(
  {{
    bufnr = 0,
    col = 8,
    line = "    int val = 5;",
    lnum = 85,
    path = "Test.java"
  }})
  if actual == expected then
    table.insert(passed, 32)
  else
    table.insert(failed, 32)
  end
  after(passed, failed)
end

local function after_test31(script_path, passed, failed, after, res)
  fix_fname_path(res)
  local actual = vim.inspect(res)
  local expected = vim.inspect(
  {{
    col = 15,
    line = "   public void testOverloaded(String p) {",
    lnum = 78,
    path = "Test.java",
    query_name = "query"
  }})
  if actual == expected then
    table.insert(passed, 31)
  else
    table.insert(failed, 31)
  end
  vim.fn.setpos('.', {0, 89, 29, 0}) -- 'System.out.println(>val<);'
  require'code_compass'.find_definition({matches_callback = function(res) after_test32(script_path, passed, failed, after, res) end})
end

local function after_test30(script_path, passed, failed, after, res)
  fix_fname_path(res)
  local actual = vim.inspect(res)
  local expected = vim.inspect(
  {{
    col = 15,
    line = "   public void testOverloaded() {",
    lnum = 75,
    path = "Test.java",
    query_name = "query"
  }})
  if actual == expected then
    table.insert(passed, 30)
  else
    table.insert(failed, 30)
  end
  vim.fn.setpos('.', {0, 83, 13, 0}) -- '>testOverloaded<("test");'
  require'code_compass'.find_definition({matches_callback = function(res) after_test31(script_path, passed, failed, after, res) end})
end


local function after_test29(script_path, passed, failed, after, res)
  fix_fname_path(res)
  local actual = vim.inspect(res)
  local expected = vim.inspect(
  {{
    col = 15,
    line = " public void overloaded(String param) { }",
    lnum = 28,
    path = "Test2.java",
    query_name = "query"
  }})
  if actual == expected then
    table.insert(passed, 29)
  else
    table.insert(failed, 29)
  end
  vim.fn.setpos('.', {0, 82, 13, 0}) -- '>testOverloaded<();'
  require'code_compass'.find_definition({matches_callback = function(res) after_test30(script_path, passed, failed, after, res) end})
end

local function after_test28(script_path, passed, failed, after, res)
  fix_fname_path(res)
  local actual = vim.inspect(res)
  local expected = vim.inspect(
  {{
    col = 15,
    line = " public void overloaded() { }",
    lnum = 26,
    path = "Test2.java",
    query_name = "query"
  }})
  if actual == expected then
    table.insert(passed, 28)
  else
    table.insert(failed, 28)
  end
  vim.fn.setpos('.', {0, 72, 14, 0}) -- 'Test2.>overloaded<("test");'
  require'code_compass'.find_definition({matches_callback = function(res) after_test29(script_path, passed, failed, after, res) end})
end

local function after_test27(script_path, passed, failed, after, res)
  fix_fname_path(res)
  local actual = vim.inspect(res)
  local expected = vim.inspect(
  {{
    col = 20,
    line = "protected String test3Field;",
    lnum = 2,
    path = "Test3.java",
    query_name = "query"
  }})
  if actual == expected then
    table.insert(passed, 27)
  else
    table.insert(failed, 27)
  end
  vim.fn.setpos('.', {0, 71, 14, 0}) -- 'Test2.>overloaded<();'
  require'code_compass'.find_definition({matches_callback = function(res) after_test28(script_path, passed, failed, after, res) end})
end

local function after_test26(script_path, passed, failed, after, res)
  fix_fname_path(res)
  local actual = vim.inspect(res)
  local expected = vim.inspect(
  {{
    col = 20,
    line = "protected String test3Field;",
    lnum = 2,
    path = "Test3.java",
    query_name = "query"
  }})
  if actual == expected then
    table.insert(passed, 26)
  else
    table.insert(failed, 26)
  end
  vim.fn.setpos('.', {0, 67, 16, 0}) -- 'return >test3Field<;'
  require'code_compass'.find_definition({matches_callback = function(res) after_test27(script_path, passed, failed, after, res) end})
end


local function after_test25(script_path, passed, failed, after, res)
  fix_fname_path(res)
  local actual = vim.inspect(res)
  local expected = vim.inspect(
  {{
    col = 20,
    line = "protected String test3Field;",
    lnum = 2,
    path = "Test3.java",
    query_name = "query"
  }})
  if actual == expected then
    table.insert(passed, 25)
  else
    table.insert(failed, 25)
  end
  vim.fn.setpos('.', {0, 66, 11, 0}) -- '>test3Field<.reverse();'
  require'code_compass'.find_definition({matches_callback = function(res) after_test26(script_path, passed, failed, after, res) end})
end

local function after_test24(script_path, passed, failed, after, res)
  fix_fname_path(res)
  local actual = vim.inspect(res)
  local expected = vim.inspect(
  {{
    bufnr = 0,
    col = 19,
    line = "import com.example.External;",
    lnum = 1,
    path = "Test.java"
  }})
  if actual == expected then
    table.insert(passed, 24)
  else
    table.insert(failed, 24)
  end
  vim.fn.setpos('.', {0, 65, 28, 0}) -- 'this.>test3Field<;'
  require'code_compass'.find_definition({matches_callback = function(res) after_test25(script_path, passed, failed, after, res) end})
end


local function after_test23(script_path, passed, failed, after, res)
  fix_fname_path(res)
  local actual = vim.inspect(res)
  local expected = vim.inspect(
  {{
    col = 10,
    line = " public Test2() {}",
    lnum = 24,
    path = "Test2.java",
    query_name = "ctor"
  }})
  if actual == expected then
    table.insert(passed, 23)
  else
    table.insert(failed, 23)
  end
  vim.fn.setpos('.', {0, 59, 10, 0}) -- '>super<();'
  require'code_compass'.find_definition({matches_callback = function(res) after_test24(script_path, passed, failed, after, res) end})
end

local function after_test22(script_path, passed, failed, after, res)
  fix_fname_path(res)
  local actual = vim.inspect(res)
  local expected = vim.inspect(
  {{
    bufnr = 0,
    col = 17,
    line = "  private String field;",
    lnum = 7,
    path = "Test.java"
  }})
  if actual == expected then
    table.insert(passed, 22)
  else
    table.insert(failed, 22)
  end
  vim.fn.setpos('.', {0, 54, 6, 0}) -- '>super<();'
  require'code_compass'.find_definition({matches_callback = function(res) after_test23(script_path, passed, failed, after, res) end})
end

local function after_test21(script_path, passed, failed, after, res)
  fix_fname_path(res)
  local actual = vim.inspect(res)
  local expected = vim.inspect(
  {{
    col = 18,
    line = "   private String testMethodRefThis() {",
    lnum = 32,
    path = "Test.java",
    query_name = "query"
  }})
  if actual == expected then
    table.insert(passed, 21)
  else
    table.insert(failed, 21)
  end
  vim.fn.setpos('.', {0, 50, 16, 0}) -- 'return >field<;'
  require'code_compass'.find_definition({matches_callback = function(res) after_test22(script_path, passed, failed, after, res) end})
end


local function after_test20(script_path, passed, failed, after, res)
  fix_fname_path(res)
  local actual = vim.inspect(res)
  local expected = vim.inspect(
  {{
    col = 14,
    line = " public class Test2 extends Test3 {",
    lnum = 1,
    path = "Test2.java",
    query_name = "query"
  }})
  if actual == expected then
    table.insert(passed, 20)
  else
    table.insert(failed, 20)
  end
  vim.fn.setpos('.', {0, 49, 15, 0}) -- '>testMethodRefThis<('
  require'code_compass'.find_definition({matches_callback = function(res) after_test21(script_path, passed, failed, after, res) end})
end

local function after_test19(script_path, passed, failed, after, res)
  fix_fname_path(res)
  local actual = vim.inspect(res)
  local expected = vim.inspect(
  {{
    bufnr = 0,
    col = 27,
    line = "  private void modif(Test2 transformString) {",
    lnum = 46,
    path = "Test.java"
  }})
  if actual == expected then
    table.insert(passed, 19)
  else
    table.insert(failed, 19)
  end
  vim.fn.setpos('.', {0, 34, 7, 0}) -- '>Test2<.transformString('
  require'code_compass'.find_definition({matches_callback = function(res) after_test20(script_path, passed, failed, after, res) end})
end


local function after_test18(script_path, passed, failed, after, res)
  fix_fname_path(res)
  local actual = vim.inspect(res)
  local expected = vim.inspect(
  {{
    col = 17,
    line = "   public String transformString(String input) {",
    lnum = 12,
    path = "Test2.java",
    query_name = "query"
  }, {
    col = 17,
    line = "   public String transformString(String input) {",
    lnum = 27,
    path = "Test.java",
    query_name = "query"
  }})
  if actual == expected then
    table.insert(passed, 18)
  else
    table.insert(failed, 18)
  end
  vim.fn.setpos('.', {0, 48, 8, 0}) -- 'transformString.>transformString(<'
  require'code_compass'.find_definition({matches_callback = function(res) after_test19(script_path, passed, failed, after, res) end})
end


local function after_test17(script_path, passed, failed, after, res)
  fix_fname_path(res)
  local actual = vim.inspect(res)
  local expected = vim.inspect(
  {{
    col = 17,
    line = "   public String transformString(String input) {",
    lnum = 12,
    path = "Test2.java",
    query_name = "query"
  }})
  if actual == expected then
    table.insert(passed, 17)
  else
    table.insert(failed, 17)
  end
  vim.fn.setpos('.', {0, 40, 18, 0}) -- 'myVar.>transformString(<'
  require'code_compass'.find_definition({matches_callback = function(res) after_test18(script_path, passed, failed, after, res) end})
end

local function after_test16(script_path, passed, failed, after, res)
  fix_fname_path(res)
  local actual = vim.inspect(res)
  local expected = vim.inspect(
  {{
    col = 5,
    line = "  V1,",
    lnum = 8,
    path = "Test2.java",
    query_name = "query"
  }})
  if actual == expected then
    table.insert(passed, 16)
  else
    table.insert(failed, 16)
  end
  vim.fn.setpos('.', {0, 34, 20, 0}) -- 'Test2.>transformString(<'
  require'code_compass'.find_definition({matches_callback = function(res) after_test17(script_path, passed, failed, after, res) end})
end

local function after_test15(script_path, passed, failed, after, res)
  fix_fname_path(res)
  local actual = vim.inspect(res)
  local expected = vim.inspect(
  {{
    col = 15,
    line = "   public enum TestEnum {",
    lnum = 7,
    path = "Test2.java",
    query_name = "query"
  }})
  if actual == expected then
    table.insert(passed, 15)
  else
    table.insert(failed, 15)
  end
  vim.fn.setpos('.', {0, 18, 27, 0}) -- 'TestEnum.>V1<'
  require'code_compass'.find_definition({matches_callback = function(res) after_test16(script_path, passed, failed, after, res) end})
end

local function after_test14(script_path, passed, failed, after, res)
  fix_fname_path(res)
  local actual = vim.inspect(res)
  local expected = vim.inspect(
  {{
    col = 14,
    line = " public class Test extends Test2 implements Test2 {",
    lnum = 5,
    path = "Test.java",
    query_name = "query"
  }})
  if actual == expected then
    table.insert(passed, 14)
  else
    table.insert(failed, 14)
  end
  vim.fn.setpos('.', {0, 18, 19, 0}) -- '>TestEnum<.V1'
  require'code_compass'.find_definition({matches_callback = function(res) after_test15(script_path, passed, failed, after, res) end})
end

local function after_test13(script_path, passed, failed, after, res)
  fix_fname_path(res)
  local actual = vim.inspect(res)
  local expected = vim.inspect(
  {{
    col = 14,
    line = " public class Test2 extends Test3 {",
    lnum = 1,
    path = "Test2.java",
    query_name = "query"
  }})
  if actual == expected then
    table.insert(passed, 13)
  else
    table.insert(failed, 13)
  end
  vim.fn.setpos('.', {0, 33, 38, 0}) -- '>this<::transformString'
  require'code_compass'.find_definition({matches_callback = function(res) after_test14(script_path, passed, failed, after, res) end})
end

local function after_test12(script_path, passed, failed, after, res)
  fix_fname_path(res)
  local actual = vim.inspect(res)
  local expected = vim.inspect(
  {{
    bufnr = 0,
    col = 17,
    line = "import java.util.Arrays;",
    lnum = 3,
    path = "Test.java"
  }})
  if actual == expected then
    table.insert(passed, 12)
  else
    table.insert(failed, 12)
  end
  vim.fn.setpos('.', {0, 24, 39, 0}) -- '>Test2<.transformString'
  require'code_compass'.find_definition({matches_callback = function(res) after_test13(script_path, passed, failed, after, res) end})
end

local function after_test11(script_path, passed, failed, after, res)
  fix_fname_path(res)
  local actual = vim.inspect(res)
  local expected = vim.inspect(
  {{
    col = 14,
    line = "public class ClassOne {",
    lnum = 3,
    path = "PackageOneClassOne.java",
    query_name = "query",
  }})
  if actual == expected then
    table.insert(passed, 11)
  else
    table.insert(failed, 11)
  end
  vim.fn.setpos('.', {0, 33, 6, 0}) -- '>Arrays<.asList()'
  require'code_compass'.find_definition({matches_callback = function(res) after_test12(script_path, passed, failed, after, res) end})
end

local function after_test10(script_path, passed, failed, after, res)
  fix_fname_path(res)
  local actual = vim.inspect(res)
  local expected = vim.inspect(
  {{
    col = 17,
    line = "   public String transformString(String input) {",
    lnum = 27,
    path = "Test.java",
    query_name = "query",
  }})
  if actual == expected then
    table.insert(passed, 10)
  else
    table.insert(failed, 10)
  end
  -- it must use the package name to filter the matches
  vim.fn.setpos('.', {0, 35, 29, 0}) -- 'new >ClassOne<()'
  require'code_compass'.find_definition({matches_callback = function(res) after_test11(script_path, passed, failed, after, res) end})
end

local function after_test9(script_path, passed, failed, after, res)
  fix_fname_path(res)
  local actual = vim.inspect(res)
  local expected = vim.inspect(
  {{
    col = 18,
    line = "private String field;",
    lnum = 7,
    path = "Test.java",
    query_name = "query",
  }})
  if actual == expected then
    table.insert(passed, 9)
  else
    table.insert(failed, 9)
  end
  vim.fn.setpos('.', {0, 33, 55, 0}) -- 'this::>transformString<'
  require'code_compass'.find_definition({matches_callback = function(res) after_test10(script_path, passed, failed, after, res) end})
end

local function after_test8(script_path, passed, failed, after, res)
  fix_fname_path(res)
  local actual = vim.inspect(res)
  local expected = vim.inspect({{
    col = 17,
    line = "   public String transformString(String input) {",
    lnum = 12,
    path = "Test2.java",
    query_name = "query",
  }})
  if actual == expected then
    table.insert(passed, 8)
  else
    table.insert(failed, 8)
  end
  vim.fn.setpos('.', {0, 29, 19, 0}) -- 'this.>field<'
  require'code_compass'.find_definition({matches_callback = function(res) after_test9(script_path, passed, failed, after, res) end})
end

local function after_test7(script_path, passed, failed, after, res)
  fix_fname_path(res)
  local actual = vim.inspect(res)
  local expected = vim.inspect({{
    col = 15,
    line = "   public enum TestEnum {",
    lnum = 7,
    path = "Test2.java",
    query_name = "query",
  }})
  if actual == expected then
    table.insert(passed, 7)
  else
    table.insert(failed, 7)
  end
  vim.fn.setpos('.', {0, 24, 52, 0}) -- 'Test2::>transformString<'
  require'code_compass'.find_definition({matches_callback = function(res) after_test8(script_path, passed, failed, after, res) end})
end

local function after_test6(script_path, passed, failed, after, res)
  fix_fname_path(res)
  local actual = vim.inspect(res)
  local expected = vim.inspect({{
    col = 21,
    line = "public static int MY_CONST = 16;",
    lnum = 3,
    path = "Test2.java",
    query_name = "query",
  }})
  if actual == expected then
    table.insert(passed, 6)
  else
    table.insert(failed, 6)
  end
  vim.fn.setpos('.', {0, 18, 8, 0}) -- '>TestEnum< v'
  require'code_compass'.find_definition({matches_callback = function(res) after_test7(script_path, passed, failed, after, res) end})
end

local function after_test5(script_path, passed, failed, after, res)
  fix_fname_path(res)
  local actual = vim.inspect(res)
  local expected = vim.inspect({{
    col = 14,
    line = " public class Test2 extends Test3 {",
    lnum = 1,
    path = "Test2.java",
    query_name = "query",
  }})
  if actual == expected then
    table.insert(passed, 5)
  else
    table.insert(failed, 5)
  end
  vim.fn.setpos('.', {0, 12, 43, 0}) -- 'Test2.>MY_CONST<'
  require'code_compass'.find_definition({matches_callback = function(res) after_test6(script_path, passed, failed, after, res) end})
end

local function after_test4(script_path, passed, failed, after, res)
  fix_fname_path(res)
  local actual = vim.inspect(res)
  local expected = vim.inspect({{
    col = 15,
    line = "public void function1() {}",
    lnum = 5,
    path = "Test2.java",
    query_name = "query",
  }})
  if actual == expected then
    table.insert(passed, 4)
  else
    table.insert(failed, 4)
  end
  vim.fn.setpos('.', {0, 17, 11, 0}) -- 'new >Test2<()'
  require'code_compass'.find_definition({matches_callback = function(res) after_test5(script_path, passed, failed, after, res) end})
end

local function after_test3(script_path, passed, failed, after, res)
  fix_fname_path(res)
  local actual = vim.inspect(res)
  local expected = vim.inspect({{
    bufnr = 0,
    col = 19,
    line = "import com.example.External;",
    lnum = 1,
    path = "Test.java"
  }})
  if actual == expected then
    table.insert(passed, 3)
  else
    table.insert(failed, 3)
  end
  vim.fn.setpos('.', {0, 17, 24, 0}) -- '.>function1<()'
  require'code_compass'.find_definition({matches_callback = function(res) after_test4(script_path, passed, failed, after, res) end})
end

local function after_test2(script_path, passed, failed, after, res)
  fix_fname_path(res)
  local actual = vim.inspect(res)
  local expected = vim.inspect({{
    bufnr = 0,
    col = 8,
    line = "    int localVar = 2;",
    lnum = 10,
    path = "Test.java"
  }})
  if actual == expected then
    table.insert(passed, 2)
  else
    table.insert(failed, 2)
  end
  vim.fn.setpos('.', {0, 12, 8, 0}) -- '>External< val'
  require'code_compass'.find_definition({matches_callback = function(res) after_test3(script_path, passed, failed, after, res) end})
end

local function after_test1(script_path, passed, failed, after, res)
  fix_fname_path(res)
  local actual = vim.inspect(res)
  local expected = vim.inspect({{
    bufnr = 0,
    col = 17,
    line = "  private String field;",
    lnum = 7,
    path = "Test.java"
  }})
  if actual == expected then
    table.insert(passed, 1)
  else
    table.insert(failed, 1)
  end
  vim.fn.setpos('.', {0, 10, 12, 0}) -- 'int >localVar<'
  require'code_compass'.find_definition({matches_callback = function(res) after_test2(script_path, passed, failed, after, res) end})
end

local function run_find_def_tests(after)
  vim.fn.setpos('.', {0, 13, 14, 0}) -- 'return >field<'
  require'code_compass'.find_definition({matches_callback = function(res) after_test1(script_path, {}, {}, after, res) end})
end

return {
  run_find_def_tests = run_find_def_tests,
}
