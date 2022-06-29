return {
  settings = {
    gopls = {
      analyses = {
          unusedparams = true,
          shadow = true,
      },
      staticcheck = true,
      buildFlags = {"-tags=wireinject"}
    },
  },
}


