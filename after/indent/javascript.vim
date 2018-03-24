" Description: Vim lit-html indent file
" Language: JavaScript
" Maintainer: Jon Smithers <mail@jonsmithers.link>

" Save the current JavaScript indentexpr.
let b:litHtmlOriginalIndentExpression = &indentexpr

" import xml indent
if exists('b:did_indent')
  let s:did_indent=b:did_indent
  unlet b:did_indent
endif
exe 'runtime! indent/xml.vim'
if exists('s:did_indent')
  let b:did_indent=s:did_indent
endif

" import css indent
if exists('b:did_indent')
  let s:did_indent=b:did_indent
  unlet b:did_indent
endif
exe 'runtime! indent/css.vim'
if exists('s:did_indent')
  let b:did_indent=s:did_indent
endif

setlocal indentexpr=GetLitHtmlIndent()

" JS indentkeys
setlocal indentkeys=0{,0},0),0],0\,,!^F,o,O,e
" XML indentkeys
setlocal indentkeys+=*<Return>,<>>,<<>,/
" lit-html indentkeys
setlocal indentkeys+=`

" Multiline end tag regex (line beginning with '>' or '/>')
let s:endtag = '^\s*\/\?>\s*;\='

" Get syntax stack at StartOfLine
fu! SynSOL(lnum)
  return map(synstack(a:lnum, 1), "synIDattr(v:val, 'name')")
endfu

" Get syntax stack at EndOfLine
fu! SynEOL(lnum)
  let l:lnum = prevnonblank(a:lnum)
  let l:col = strlen(getline(l:lnum))
  return map(synstack(l:lnum, l:col), "synIDattr(v:val, 'name')")
endfu

fu! IsSyntaxCss(synstack)
  return get(a:synstack, -1) =~# '^css' || get(a:synstack, -1) =~# '^litHtmlStyleTag$'
endfu

" Does synstack end with an xml syntax attribute
fu! IsSynstackXml(synstack)
  return get(a:synstack, -1) =~# '^xml'
endfu

fu! IsSynstackInsideJsx(synstack)
  for l:syntaxAttribute in reverse(a:synstack)
    if (l:syntaxAttribute =~# '^jsx')
      return v:true
    endif
  endfor
  return v:false
endfu

" Dispatch to indent method for js/html/css, then make minor corrections
fu! GetLitHtmlIndent()
  let l:currLineSynstack = SynEOL(v:lnum)
  let l:prevLineSynstack = SynEOL(v:lnum - 1)

  if (IsSynstackXml(l:currLineSynstack) && !IsSynstackInsideJsx(l:currLineSynstack))

    let l:indent = XmlIndentGet(v:lnum, 0)

    " indent first line inside lit-html template
    if getline(v:lnum-1) =~# 'html`$'
      let l:indent += &shiftwidth
    endif

  elseif (IsSyntaxCss(l:currLineSynstack))

    let l:indent = GetCSSIndent()

    " indent first line of css after <script>
    if (IsSynstackXml(l:prevLineSynstack))
      let l:indent += &shiftwidth
    endif

  else
    if len(b:litHtmlOriginalIndentExpression)
      let l:indent = eval(b:litHtmlOriginalIndentExpression)
      if (IsSynstackXml(l:prevLineSynstack))
        let l:indent -= &shiftwidth
      endif
    else
      let l:indent = cindent(v:lnum)
    endif
  endif

  return l:indent
endfu