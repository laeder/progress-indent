" Vim indent file
" Language:     Progress
" Maintainer:   Mikael Asp Somkane <mikael@laeder.se>
" Created:      2014 Apr 11
" Last Change:  2014 Apr 11

echom "nu da"

if exists("b:did_indent")
    finish
endif

let b:did_indent = 1

setlocal indentexpr=GetProgressIndent(v:lnum)
setlocal indentkeys&
setlocal indentkeys+==IF,=FOR,=DO,=ELSE,=END,=CASE,=REPEAT,=PROCEDURE,=FUNCTION

if exists("*GetProgressIndent")
    finish
endif

function s:AddLineToLog(line)
    echom a:line
    call writefile([a:line], "/temp/vim_indent.log", "a")
    return 1
endfunction

function s:GetPrevNonCommentLineNum(line_num)
    let re_comment = '^\(\s*\)'
    let nline = a:line_num
    let nline = prevnonblank(nline-1)
    return nline
endfunction

function s:GetConditionLoopIndent(indnt, prev_codeline, this_codeline)
    let ind = a:indnt + &shiftwidth
    if a:this_codeline =~ '^\s*DO'
        let ind = ind - &shiftwidth
    endif
    return ind
endfunction

function s:GetBlockIndent(indnt, line_num)
    let re_block = '^\s*\<\(FOR\|CASE\|REPEAT\|DO\|FUNCTION\|PROCEDURE\)\>'
    let lnum = a:line_num
    let indnt = a:indnt

    call s:AddLineToLog("inne i getblockindent")
    call s:AddLineToLog("lnum: ".lnum." indnt: ".indnt)
    while lnum > 0
        let lnum = prevnonblank(lnum-1)
        let line = getline(lnum)
        call s:AddLineToLog("lnum ".lnum." line ".line)
        if line =~ re_block
            let indnt = indent(lnum) + &shiftwidth
            break
        endif
    endwhile
    return indnt
endfunction

function s:GetRunIndent(indnt, line_num)
    let re_run = '\s*RUN'
    let lnum = a:line_num
    let indnt = a:indnt

    call s:AddLineToLog("inne i getrunindent")
    call s:AddLineToLog("lnum: ".lnum." indnt: ".indnt)
    while lnum > 0
        let lnum = prevnonblank(lnum-1)
        let line = getline(lnum)
        call s:AddLineToLog("lnum ".lnum." line ".line)
        if line =~ re_run
            let indnt = indent(lnum)
            break
        endif
    endwhile
    return indnt
endfunction


function s:GetCommaIndent(line_num)
    let re_for = '\s*FOR'
    let re_run = '\s*RUN'

    s:AddLineToLog("inne i GetCommaIndent")

    let lnum = a:line_num
    while lnum > 0
        let lnum = prevnonblank(lnum-1)
        let line = getline(lnum)
        if line =~ re_for
            s:AddLineToLog("indent för for")
            let indnt = indent(lnum) + &shiftwidth
            break
        elseif line =~ re_run
            s:AddLineToLog("indent för run".stridx(line, '('))
            let indnt = stridx(line, '(') + 1
            break
        endif
    endwhile

    return indnt
endfunction

function GetProgressIndent(line_num)
    if a:line_num == 0
        call s:AddLineToLog("det blir en return")
        return 0
    endif

    let re_block = '^\s*\<\(FOR\|CASE\|REPEAT\|DO\)\>'
    let re_condition = '^\s*\<\(IF\|ELSE\|WHEN\)\>.*[^.]\s*$'
    let re_comma = ',\s*$'
    let re_run_finished = '^\s*\(INPUT\|OUTPUT\).*[.]\s*$'
    let re_block_starts = ':\s*$'

    let this_codeline = getline(a:line_num)
    call s:AddLineToLog("this ".this_codeline)
    let prev_codeline_num = s:GetPrevNonCommentLineNum(a:line_num)
    let prev_codeline = getline(prev_codeline_num)
    call s:AddLineToLog("prev ".prev_codeline)
    let pp_codeline_num = s:GetPrevNonCommentLineNum(prev_codeline_num)
    let pp_codeline = getline(pp_codeline_num)
    let indnt = indent(prev_codeline_num)

    " block or condition
    if prev_codeline =~ re_condition || prev_codeline =~ re_block
        let indnt = s:GetConditionLoopIndent(indnt, prev_codeline, this_codeline)
    elseif prev_codeline =~ re_block_starts
       let indnt = s:GetBlockIndent(indnt, a:line_num)
    " an INPUT or OUTPUT finishes a RUN statement
    elseif prev_codeline =~ re_run_finished
        call s:AddLineToLog("ska köra getruntindent")
        let indnt = s:GetRunIndent(indnt, a:line_num)
    " end of condition without a block
    elseif pp_codeline =~ re_condition
        let indnt = indnt - &shiftwidth
    " ends with a comma
    elseif prev_codeline =~ re_comma
        let indnt = s:GetCommaIndent(a:line_num)
    endif

    " end
    if this_codeline =~ '^\s*END'
        return indnt - &shiftwidth
    endif

    return indnt
endfunction


