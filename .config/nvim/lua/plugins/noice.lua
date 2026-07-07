return {
  {
    "folke/noice.nvim",
    opts = {
      routes = {
        -- Redirect shell command outputs to a notify popup so they are always visible
        {
          filter = {
            event = "msg_show",
            kind = "shell_out",
          },
          view = "notify",
        },
      },
    },
  },
}
