" Neovim config file

" Redefine the user's vimrc' file to mean this file (~/.config/nvim/init.vim).
let $MYVIMRC = stdpath('config') . '/init.vim'

" Install and activate plugins.
exec 'source ' . stdpath('config') . '/plugins.vim'

" Private functions {{{

" Source a file in the plugin-config dir.
function! s:SourcePluginConfigFile(file)
  " Directory containing extra configuration files for plugins installed with
  " vim-plug. We decide when and how to load these files. Neovim does not load
  " them automatically.
  let l:plugin_config_dir = stdpath('config') . '/plug-config'

  if a:file =~ '\.vim$'
    silent execute 'source ' . l:plugin_config_dir . '/' . a:file
  elseif a:file =~ '\.lua$'
    silent execute 'luafile ' . l:plugin_config_dir . '/' . a:file
  endif
endfunction
" }}}

" Source plugin configuration files. {{{
"
" We don't want to keep these files in the standard 'plugin/' directory because
" those files are not guaranteed to load in a given order, and may even load
" asynchronously. We want to control when and where we load these plugin
" configuration files so that we don't encounter strange errors when Neovim
" first loads.

call s:SourcePluginConfigFile('airline.vim')
call s:SourcePluginConfigFile('awesome_terminal_fonts.vim')
call s:SourcePluginConfigFile('ctrlp.vim')
call s:SourcePluginConfigFile('emmet.vim')
call s:SourcePluginConfigFile('fugitive.vim')
call s:SourcePluginConfigFile('fzf.vim')
call s:SourcePluginConfigFile('gina.vim')
call s:SourcePluginConfigFile('gitgutter.vim')
call s:SourcePluginConfigFile('gundo.vim')
call s:SourcePluginConfigFile('incsearch-easymotion.vim')
call s:SourcePluginConfigFile('incsearch.vim')
call s:SourcePluginConfigFile('indent_guides.vim')
call s:SourcePluginConfigFile('latex.vim')
call s:SourcePluginConfigFile('nerdcommenter.vim')
call s:SourcePluginConfigFile('nerdtree.vim')
call s:SourcePluginConfigFile('tagbar.vim')
call s:SourcePluginConfigFile('tmuxline.vim')
call s:SourcePluginConfigFile('ultisnips.vim')
call s:SourcePluginConfigFile('vim-easymotion.vim')
call s:SourcePluginConfigFile('vim_latex_live_preview.vim')

" Load the autocompletion engine
call s:SourcePluginConfigFile('nvim-compe.lua')

" Load the LSP configuration file.
call s:SourcePluginConfigFile('lsp.lua')

" This one should always come last!!!
call s:SourcePluginConfigFile('colorscheme.vim')
" }}}

" vim:foldenable:foldmethod=marker:foldlevel=0
