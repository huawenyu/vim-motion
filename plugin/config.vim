" Version:      1.0

if exists("s:init") || &compatible
    finish
else
    let s:init = 1
    silent! let s:log = logger#getLogger(expand('<sfile>:t'))
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
    " error
    if column == 0
        return
    endif

    let lastline = line('$')

    " check logfile
    let is_log = 0
    let cur_str = getline('.')
    if cur_str =~? '^T@'
        let is_log = 1
    endif

    " if is_log
    "     let indent = column - 1
    " else
    "     let indent = s:Indent(line, is_log)
    " endif

    " indent by cursor position (only by-space), or by builtin indent (by-space/tab)
    "let indent = (column - 1) * &tabstop
    "let indent = s:Indent(line, is_log)
    let indent = strdisplaywidth(getline('.')) - strdisplaywidth(getline('.')[col('.')-1:])
    silent! call s:log.debug("isLog=", is_log, " column=", column, " indent=", indent, " lowerlevel=", a:lowerlevel, " skipblanks=", a:skipblanks)

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

        let curr_indent = s:Indent(line, is_log)
        silent! call s:log.debug("curr-indent=", curr_indent, " len=", strlen(getline(line)))
        if ( (! a:lowerlevel && curr_indent == indent) ||
                    \ (a:lowerlevel && s:Indent(line, is_log) < indent))
            if (! a:skipblanks || strlen(getline(line)) > 0)
                if (a:exclusive)
                    let line = line - stepvalue
                endif
                "exe line
                " column different when tabs
                "   exe "normal " column . "|"
                "exe "normal " column . "l"

                "exe "normal "..line.."m]"
                "exe "normal `]"
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

    nnoremap <silent> <buffer> <a-p> :call <SID>NextIndent(0, 0, 0, 1)<CR>
    nnoremap <silent> <buffer> <a-n> :call <SID>NextIndent(0, 1, 0, 1)<CR>
    "nnoremap <silent> <buffer> <a-P> :call <SID>NextIndent(0, 0, 1, 1)<CR>
    "nnoremap <silent> <buffer> <a-N> :call <SID>NextIndent(0, 1, 1, 1)<CR>
    vnoremap <silent> <buffer> <a-p> <Esc>:call <SID>NextIndent(0, 0, 0, 1)<CR>m'gv''
    vnoremap <silent> <buffer> <a-n> <Esc>:call <SID>NextIndent(0, 1, 0, 1)<CR>m'gv''
    "vnoremap <silent> <buffer> <a-P> <Esc>:call <SID>NextIndent(0, 0, 1, 1)<CR>m'gv''
    "vnoremap <silent> <buffer> <a-N> <Esc>:call <SID>NextIndent(0, 1, 1, 1)<CR>m'gv''
    onoremap <silent> <buffer> <a-p> :call <SID>NextIndent(0, 0, 0, 1)<CR>
    onoremap <silent> <buffer> <a-n> :call <SID>NextIndent(0, 1, 0, 1)<CR>
    "onoremap <silent> <buffer> <a-P> :call <SID>NextIndent(1, 0, 1, 1)<CR>
    "onoremap <silent> <buffer> <a-N> :call <SID>NextIndent(1, 1, 1, 1)<CR>

    nnoremap vip :call <SID>SelectIndent()<CR>
else
    "command! -bar VimMotionPrev    call <SID>NextIndent(0, 0, 0, 1)
    "command! -bar VimMotionNext    call <SID>NextIndent(0, 1, 0, 1)

    map <silent> <Plug>_JumpPrevIndent :\<C-U>call <SID>NextIndent(0, 0, 0, 1) <cr>
    map <silent> <Plug>_JumpNextIndent :\<C-U>call <SID>NextIndent(0, 1, 0, 1) <cr>
endif


" Depend on plugin https://github.com/skywind3000/vim-preview
function! VimMotionPreview()
    if !exists(":PreviewTag")
        echomsg "Please install plugin 'skywind3000/vim-preview'!"
        return
    endif

    let l:wtype = win_gettype()
    if l:wtype == ""
        let l:cur_id = win_getid()
        " Check right window.
        wincmd l
        let l:alt_id = win_getid()
        if l:alt_id != l:cur_id
            set previewwindow
            call win_gotoid(l:cur_id)
        endif
        exec ":PreviewTag "..utils#GetSelected('n')
    elseif l:wtype == "preview"
        let oline = line('.')
        let opos = getpos('.')
        exec ":ptag "..utils#GetSelected('n')
        let cline = line('.')
        if cline != oline
            norm zz
        else
            call setpos('.', opos)
        endif
    endif

endfun


function! VimMotionTag()
    let oline = line('.')
    let opos = getpos('.')
    exec ":tag "..utils#GetSelected('n')
    let cline = line('.')
    if cline != oline
        norm zz
    else
        call setpos('.', opos)
    endif
endfun
