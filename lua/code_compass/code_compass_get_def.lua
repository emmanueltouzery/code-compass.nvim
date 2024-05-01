local helpers = require('code_compass.helpers')
local compass_java_get_def = require('code_compass.java.compass_java_get_def')

local function find_definition(opts)
  if vim.bo.filetype == 'java' then
    compass_java_get_def.get_definition(opts)
  end
end

return {
  find_definition = find_definition,
}
