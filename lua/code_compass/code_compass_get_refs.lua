local helpers = require('code_compass.helpers')
local compass_java_get_refs = require('code_compass.java.compass_java_get_refs')

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
        { width = 9, },
        { remaining = true },
      },
    }
    local make_display = function(entry)
      return displayer {
        { Str.truncate(entry.path, 35, "…", -1), "TelescopeResultsIdentifier" },
        { entry.query_name },
        { entry.line, "Special" },
      }
    end

    pickers.new(opts, {
      prompt_title = "References",
      finder = finders.new_table {
        results = matches,
        entry_maker = function(entry)
          entry.name = entry.fname
          entry.ordinal = entry.query_name .. " " .. entry.fname .. " " .. entry.line
          entry.display = make_display
          return entry
        end,
      },
      previewer = conf.grep_previewer(opts),
      sorter = conf.generic_sorter(opts),
    }):find()
  end
end

local function find_references(opts)
  local word = vim.fn.expand('<cword>')

  local query = nil
  if vim.bo.filetype == 'java' then
    query = compass_java_get_refs.get_references_query()
  end

  if query ~= nil then
    helpers.run_and_parse_ast_grep(word, query, opts, function(matches)
      table.sort(matches, function(m1, m2)
        if m2.query_name > m1.query_name then
          return true
        end
        if m2.query_name < m1.query_name then
          return false
        end
        if m2.path > m1.path then
          return true
        end
        if m2.path < m1.path then
          return false
        end
        if m2.fname > m1.fname then
          return true
        end
        if m2.fname < m1.fname then
          return false
        end
        if m2.lnum > m1.lnum then
          return true
        end
        if m2.lnum < m1.lnum then
          return false
        end
        if m2.col > m1.col then
          return true
        end
        if m2.col < m1.col then
          return false
        end
        if m2.line > m1.line then
          return true
        end
        if m2.line < m1.line then
          return false
        end
        return false
      end)
      if opts ~= nil and opts.matches_callback ~= nil then
        opts.matches_callback(matches)
      else
        picker_finish(matches)
      end
    end)
  end
end

return {
  find_references = find_references,
}
