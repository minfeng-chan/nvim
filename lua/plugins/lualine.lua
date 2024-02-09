return {
  "nvim-lualine/lualine.nvim",
  opts = function(_, opts)
    local kind_icons = {
      clock = "󰥔 ",
      ls_inactive = "󰒎 ",
      ls_active = "󰒍 ",
    }

    local colors = {
      cmp_border = "#181924",
      none = "NONE",
      bg_dark = "#1f2335",
      bg_alt = "#1a1b26",
      bg = "#24283b",
      bg_br = "#292e42",
      terminal_black = "#414868",
      fg = "#c0caf5",
      fg_dark = "#a9b1d6",
      fg_gutter = "#3b4261",
      dark3 = "#545c7e",
      comment = "#565f89",
      dark5 = "#737aa2",
      blue0 = "#3d59a1",
      blue = "#7aa2f7",
      cyan = "#7dcfff",
      blue1 = "#2ac3de",
      blue2 = "#0db9d7",
      blue5 = "#89ddff",
      blue6 = "#B4F9F8",
      blue7 = "#394b70",
      violet = "#bb9af7",
      magenta = "#bb9af7",
      magenta2 = "#ff007c",
      purple = "#9d7cd8",
      orange = "#ff9e64",
      yellow = "#e0af68",
      hlargs = "#e0af68",
      green = "#9ece6a",
      green1 = "#73daca",
      green2 = "#41a6b5",
      teal = "#1abc9c",
      red = "#f7768e",
      red1 = "#db4b4b",
      -- git = { change = "#6183bb", add = "#449dab", delete = "#914c54", conflict = "#bb7a61" },
      git = { change = "#6183bb", add = "#449dab", delete = "#f7768e", conflict = "#bb7a61" },
      gitSigns = { add = "#164846", change = "#394b70", delete = "#823c41" },
    }

    local function clock()
      return kind_icons.clock .. os.date("%H:%M")
    end

    local function diff_source()
      local gitsigns = vim.b.gitsigns_status_dict
      if gitsigns then
        return {
          added = gitsigns.added,
          modified = gitsigns.changed,
          removed = gitsigns.removed,
        }
      end
    end

    local function testing()
      if vim.g.testing_status == "running" then
        return " "
      end
      if vim.g.testing_status == "fail" then
        return ""
      end
      if vim.g.testing_status == "pass" then
        return " "
      end
      return nil
    end

    local _time = os.date("*t")

    -- Config
    opts.options = {
      icons_enabled = true,
      theme = "auto",
      component_separators = { left = "", right = "" },
      section_separators = { left = "", right = "" },
      disabled_filetypes = {
        statusline = {},
        winbar = {},
      },
      ignore_focus = {},
      always_divide_middle = true,
      globalstatus = false,
      refresh = {
        statusline = 1000,
        tabline = 1000,
        winbar = 1000,
      },
    }
    opts.sections = {
      lualine_a = { "mode" },
      lualine_b = { "branch", "diagnostics" },
      lualine_c = { "filename" },
      lualine_x = { "encoding", "fileformat", "filetype" },
      lualine_y = {},
      lualine_z = { "location" },
    }
    opts.inactive_sections = {
      lualine_a = {},
      lualine_b = {},
      lualine_c = { "filename" },
      lualine_x = { "location" },
      lualine_y = {},
      lualine_z = {},
    }
    opts.tabline = {}
    opts.winbar = {}
    opts.inactive_winbar = {}
    opts.extensions = {}

    local conditions = {
      buffer_not_empty = function()
        return vim.fn.empty(vim.fn.expand("%:t")) ~= 1
      end,
      hide_in_width = function()
        return vim.o.columns > 80
      end,
      hide_small = function()
        return vim.o.columns > 140
      end,
      check_git_workspace = function()
        local filepath = vim.fn.expand("%:p:h")
        local gitdir = vim.fn.finddir(".git", filepath .. ";")
        return gitdir and #gitdir > 0 and #gitdir < #filepath
      end,
    }

    -- Inserts a component in lualine_c at left section
    local function ins_left(component)
      table.insert(opts.sections.lualine_c, component)
    end

    -- Inserts a component in lualine_x ot right section
    local function ins_right(component)
      table.insert(opts.sections.lualine_x, component)
    end

    ins_left({
      "diff",
      source = diff_source,
      symbols = { added = "  ", modified = " ", removed = " " },
      diff_color = {
        added = { fg = colors.git.add, bg = colors.bg },
        modified = { fg = colors.git.change, bg = colors.bg },
        removed = { fg = colors.git.delete, bg = colors.bg },
      },
      color = {},
      cond = nil,
    })

    ins_left({
      provider = function()
        return testing()
      end,
      enabled = function()
        return testing() ~= nil
      end,
      hl = {
        fg = colors.fg,
      },
      left_sep = " ",
      right_sep = {
        str = " |",
        hl = { fg = colors.fg },
      },
    })

    ins_right({
      function()
        return ""
      end,
      color = function()
        local buf = vim.api.nvim_get_current_buf()
        local ts = vim.treesitter.highlighter.active[buf]
        return { fg = ts and not vim.tbl_isempty(ts) and colors.green or colors.red, bg = colors.bg }
      end,
      cond = conditions.hide_in_width,
    })

    ins_right({
      function(msg)
        msg = msg or kind_icons.ls_inactive .. "LS Inactive"
        local buf_clients = vim.lsp.get_active_clients()
        if next(buf_clients) == nil then
          if type(msg) == "boolean" or #msg == 0 then
            return kind_icons.ls_inactive .. "LS Inactive"
          end
          return msg
        end
        local buf_ft = vim.bo.filetype
        local buf_client_names = {}
        local only_lsp = ""
        local lsp_icon = kind_icons.ls_active

        for _, client in pairs(buf_clients) do
          if client.name ~= "null-ls" then
            local _added_client = client.name
            only_lsp = only_lsp .. _added_client
            _added_client = string.sub(client.name, 1, 7)
            table.insert(buf_client_names, _added_client)
          end
        end

        local function list_registered_providers_names(filetype)
          local s = require("null-ls.sources")
          local available_sources = s.get_available(filetype)
          local registered = {}
          for _, source in pairs(available_sources) do
            for method in pairs(source.methods) do
              registered[method] = registered[method] or {}
              table.insert(registered[method], source.name)
            end
          end
          return registered
        end

        local function list_supported_formatters(filetype)
          local registered = list_registered_providers_names(filetype)
          return registered[require("null-ls").methods.FORMATTING] or {}
        end

        -- add formatter
        local supported_formatters = {}
        for _, fmt in pairs(list_supported_formatters(buf_ft)) do
          local _added_formatter = fmt
          _added_formatter = string.sub(fmt, 1, 4)
          table.insert(supported_formatters, _added_formatter)
        end
        vim.list_extend(buf_client_names, supported_formatters)

        local function list_supported_linters(filetype)
          local registered_providers = list_registered_providers_names(filetype)
          local providers_for_methods = vim.tbl_flatten(vim.tbl_map(function(m)
            return registered_providers[m] or {}
          end, {
            require("null-ls").methods.DIAGNOSTICS,
            require("null-ls").methods.DIAGNOSTICS_ON_OPEN,
            require("null-ls").methods.DIAGNOSTICS_ON_SAVE,
          }))

          return providers_for_methods
        end

        -- add linter
        local supported_linters = {}
        for _, lnt in pairs(list_supported_linters(buf_ft)) do
          local _added_linter = lnt
          _added_linter = string.sub(lnt, 1, 4)
          table.insert(supported_linters, _added_linter)
        end
        vim.list_extend(buf_client_names, supported_linters)

        if conditions.hide_small() then
          return lsp_icon .. table.concat(buf_client_names, ", ")
        elseif conditions.hide_in_width() then
          return only_lsp
        else
          return string.sub(only_lsp, 1, 5)
        end
      end,
      color = { fg = colors.fg, bg = colors.bg },
      cond = conditions.hide_in_width,
    })
    ins_right({
      function()
        local function format_file_size(file)
          local size = vim.fn.getfsize(file)
          if size <= 0 then
            return ""
          end
          local sufixes = { "b", "k", "m", "g" }
          local i = 1
          while size > 1024 do
            size = size / 1024
            i = i + 1
          end
          return string.format("%.1f%s", size, sufixes[i])
        end

        local file = vim.fn.expand("%:p")
        if string.len(file) == 0 then
          return ""
        end
        return format_file_size(file)
      end,
      color = { fg = colors.fg, bg = colors.bg },
      cond = conditions.buffer_not_empty and conditions.hide_small,
    })

    table.insert(opts.sections.lualine_y, {
      clock,
      cond = conditions.hide_small,
      color = { fg = colors.blue, bg = colors.bg },
    })

    table.insert(opts.sections.lualine_z, {
      function()
        local current_line = vim.fn.line(".")
        local total_lines = vim.fn.line("$")
        local chars = { "__", "▁▁", "▂▂", "▃▃", "▄▄", "▅▅", "▆▆", "▇▇", "██" }
        local line_ratio = current_line / total_lines
        local index = math.ceil(line_ratio * #chars)
        return chars[index]
      end,
      padding = 0,
      color = { fg = colors.yellow, bg = colors.bg },
      cond = nil,
    })
  end,
}
