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
      prompt_title = title,
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

local function find_references(opts)
  local word = vim.fn.expand('<cword>')

  local query = nil
  if vim.bo.filetype == 'java' then
    query = compass_java_get_refs.get_references_query()
  end

  if query ~= nil then
    helpers.run_and_parse_ast_grep(word, query, "References", opts, function(matches)
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
