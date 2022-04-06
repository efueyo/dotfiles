return {
  settings = {
    gopls = {
      analyses = {
          unusedparams = true,
      },
      staticcheck = true,
      buildFlags = {"-tags=wireinject"}
    },
  },
}


