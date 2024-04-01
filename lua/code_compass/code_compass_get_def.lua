local helpers = require('code_compass.helpers')
local compass_java_get_def = require('code_compass.java.compass_java_get_def')

local function picker_finish(matches)
  if #matches == 0 then
    vim.notify("No matches found", vim.log.levels.ERROR)
  elseif #matches == 1 then
    local fbuf = matches[1].bufnr or find_buf_for_fname(matches[1].path)
    if fbuf ~= nil then
      vim.api.nvim_win_set_buf(0, fbuf)
    else
      vim.cmd(":e " .. matches[1].path)
    end
    vim.fn.setpos('.', {0, matches[1].lnum, matches[1].col+1, 0})
    vim.cmd[[ norm! zz]]
  else
    local pickers = require "telescope.pickers"
    local finders = require "telescope.finders"
    local conf = require("telescope.config").values
    local entry_display = require("telescope.pickers.entry_display")
    local Str = require'plenary.strings'
    local opts = {}

    local displayer = entry_display.create {
      separator = " ",
      items = {
        { width = 35, },
        { remaining = true },
      },
    }
    local make_display = function(entry)
      return displayer {
        { Str.truncate(entry.path, 35, "…", -1), "TelescopeResultsIdentifier" },
        { entry.line, "Special" },
      }
    end

    pickers.new(opts, {
      prompt_title = "Definitions",
      finder = finders.new_table {
        results = matches,
        entry_maker = function(entry)
          entry.name = entry.fname
          entry.ordinal = entry.fname
          entry.display = make_display
          return entry
        end,
      },
      previewer = conf.grep_previewer(opts),
      sorter = conf.generic_sorter(opts),
    }):find()
  end
end

local function find_local_declarations()
  local matches = {}
  if vim.bo.filetype == 'java' then
    matches = compass_java_get_def.find_local_declarations()
  end

  local filtered_matches = {}
  local cur_line = vim.fn.line('.')
  -- keep only matches up to the current row (cannot use variables
  -- defined later on), and keep only the last one such (the same
  -- variable name can be used multiple times in the current file, we
  -- want the latest declaration before the current line)
  local latest_match = nil
  for _, match in ipairs(matches) do
    if match.lnum <= cur_line then
      latest_match = match
    else
      break
    end
  end
  if latest_match ~= nil then
    return { latest_match }
  else
    return {}
  end
end

local function run_finish(matches, opts)
  if #matches == 0 then
    -- couldn't find global declarations, could be a local variable
    -- or a field of the current class
    matches = find_local_declarations()
  end
  local get_field_access_query = nil
  if #matches == 0 then
    if vim.bo.filetype == 'java' then
      get_field_access_query = compass_java_get_def.get_field_access_query
    end
  end
  if #matches == 0 and get_field_access_query ~= nil then
    -- still couldn't find anything. it could be accessing a field on
    -- another class (for instance a public final field)
    -- i don't like to check that too early, because i could grab
    -- a field on a completely unrelated class.. but if nothing else
    -- worked, let's try this now
    local word = vim.fn.expand('<cword>')
    helpers.run_and_parse_ast_grep(word, {get_field_access_query()}, opts, function(matches)
      if opts ~= nil and opts.matches_callback ~= nil then
        opts.matches_callback(matches)
      else
        picker_finish(matches)
      end
    end)
    return
  end
  if opts ~= nil and opts.matches_callback ~= nil then
    opts.matches_callback(matches)
  else
    picker_finish(matches)
  end
end

local function find_definition(opts)
  local word = vim.fn.expand('<cword>')

  local query = nil
  if vim.bo.filetype == 'java' then
    queries = compass_java_get_def.get_definition_queries()
  end

  if queries ~= nil and #queries > 0 then
    helpers.run_and_parse_ast_grep(word, queries, opts, function(res) run_finish(res, opts) end)
  end
end

return {
  find_definition = find_definition,
}
