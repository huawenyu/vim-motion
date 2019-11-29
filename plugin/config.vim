" Version:      1.0

if exists('g:loaded_vim_motion') || &compatible
  finish
else
  let g:loaded_vim_motion = 'yes'
endif



function! s:Indent(linenum, islog)
    if a:islog
        let cur_str = getline(a:linenum)
        if cur_str =~? '^T@'
            " Non-greed: replace '.*' with '.\{-}'
            let cur_str2 = substitute(cur_str, '^T@.\{-}-  ', '  ', '')
            let off_set = match(cur_str, cur_str2)
            let indent = match(cur_str2, '\S')
            return off_set + indent
        endif
    endif
    return indent(a:linenum)
endfunction

" Jump to the next or previous line that has the same level or a lower
" level of indentation than the current line.
"
" exclusive (bool): true: Motion is exclusive
"                   false: Motion is inclusive
" fwd (bool): true: Go to next line
"             false: Go to previous line
" lowerlevel (bool): true: Go to line with lower indentation level
"                    false: Go to line with the same indentation level
" skipblanks (bool): true: Skip blank lines
"                    false: Don't skip blank lines
function! s:NextIndent(exclusive, fwd, lowerlevel, skipblanks)
    let line = line('.')
    let column = col('.')
    let lastline = line('$')

    " check logfile
    let is_log = 0
    let cur_str = getline('.')
    if cur_str =~? '^T@'
        let is_log = 1
    endif

    " indent by cursor position (only by-space), or by builtin indent (by-space/tab)
    if is_log
        let indent = column - 1
    else
        let indent = s:Indent(line, is_log)
    endif

    let stepvalue = a:fwd ? 1 : -1
    while (line > 0 && line <= lastline)
        let line = line + stepvalue

        " if logfile, skip non-log lines
        if is_log == 1
            let cur_str = getline(line)
            if cur_str !~? '^T@'
                continue
            endif
        endif

        if ( ! a:lowerlevel && s:Indent(line, is_log) == indent ||
                    \ a:lowerlevel && s:Indent(line, is_log) < indent)
            if (! a:skipblanks || strlen(getline(line)) > 0)
                if (a:exclusive)
                    let line = line - stepvalue
                endif
                "exe line
                " column different when tabs
                "   exe "normal " column . "|"
                "exe "normal " column . "l"
                call cursor(line, column)
                return
            endif
        endif
    endwhile
endfunction

function s:SelectIndent()
    let cur_line = line(".")
    let cur_ind = indent(cur_line)
    let line = cur_line
    while indent(line - 1) >= cur_ind
        let line = line - 1
    endw
    " Select above line
    let line = line - 1
    exe "normal " . line . "G"
    exe "normal V"
    let line = cur_line
    while indent(line + 1) >= cur_ind
        let line = line + 1
    endw
    " Select below line
    let line = line + 1
    exe "normal " . line . "G"
endfunction


if exists("g:vim_motion_maps") && g:vim_motion_maps
    " Moving back and forth between lines of same or lower indentation.
    nnoremap <silent> <a-p> :call <SID>NextIndent(0, 0, 0, 1)<CR>
    nnoremap <silent> <a-n> :call <SID>NextIndent(0, 1, 0, 1)<CR>
    nnoremap <silent> <a-P> :call <SID>NextIndent(0, 0, 1, 1)<CR>
    nnoremap <silent> <a-N> :call <SID>NextIndent(0, 1, 1, 1)<CR>
    vnoremap <silent> <a-p> <Esc>:call <SID>NextIndent(0, 0, 0, 1)<CR>m'gv''
    vnoremap <silent> <a-n> <Esc>:call <SID>NextIndent(0, 1, 0, 1)<CR>m'gv''
    vnoremap <silent> <a-P> <Esc>:call <SID>NextIndent(0, 0, 1, 1)<CR>m'gv''
    vnoremap <silent> <a-N> <Esc>:call <SID>NextIndent(0, 1, 1, 1)<CR>m'gv''
    onoremap <silent> <a-p> :call <SID>NextIndent(0, 0, 0, 1)<CR>
    onoremap <silent> <a-n> :call <SID>NextIndent(0, 1, 0, 1)<CR>
    onoremap <silent> <a-P> :call <SID>NextIndent(1, 0, 1, 1)<CR>
    onoremap <silent> <a-N> :call <SID>NextIndent(1, 1, 1, 1)<CR>
    "nnoremap <silent> [l :call <SID>NextIndent(0, 0, 0, 1)<CR>
    "nnoremap <silent> ]l :call <SID>NextIndent(0, 1, 0, 1)<CR>
    "nnoremap <silent> [L :call <SID>NextIndent(0, 0, 1, 1)<CR>
    "nnoremap <silent> ]L :call <SID>NextIndent(0, 1, 1, 1)<CR>
    "vnoremap <silent> [l <Esc>:call <SID>NextIndent(0, 0, 0, 1)<CR>m'gv''
    "vnoremap <silent> ]l <Esc>:call <SID>NextIndent(0, 1, 0, 1)<CR>m'gv''
    "vnoremap <silent> [L <Esc>:call <SID>NextIndent(0, 0, 1, 1)<CR>m'gv''
    "vnoremap <silent> ]L <Esc>:call <SID>NextIndent(0, 1, 1, 1)<CR>m'gv''
    "onoremap <silent> [l :call <SID>NextIndent(0, 0, 0, 1)<CR>
    "onoremap <silent> ]l :call <SID>NextIndent(0, 1, 0, 1)<CR>
    "onoremap <silent> [L :call <SID>NextIndent(1, 0, 1, 1)<CR>
    "onoremap <silent> ]L :call <SID>NextIndent(1, 1, 1, 1)<CR>

    nnoremap vip :call <SID>SelectIndent()<CR>
endif

