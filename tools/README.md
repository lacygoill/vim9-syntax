This script must be used to generate/update the import file:

    import/vim9Language.vim

To do so, run this shell command while in the `tools/` directory:

    $ vim -Nu NONE +'set runtimepath=' -S GenerateImport.vim
