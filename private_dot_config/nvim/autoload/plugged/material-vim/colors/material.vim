" WARNING: Do not edit this file directly - it is built from the src directory

" ==================================================================
" HIGHLIGHT HELPER
" ==================================================================

function! s:highlight_helper(...)
  let l:syntax_group = a:1
  let l:foreground_color = a:2
  let l:background_color = empty(a:3) ? "#263238" : a:3
  let l:gui = a:0 == 3 ? "None" : a:4

  exec "highlight " . l:syntax_group . " guifg=" . l:foreground_color . " guibg=" . l:background_color . " gui=" . l:gui . " cterm=NONE term=NONE"
endfunction


" ==================================================================
" RESET
" ==================================================================

" CORE
set background=dark
highlight clear
set termguicolors
set fillchars+=vert:│
syntax on
syntax reset
let g:colors_name = "material"
call s:highlight_helper("Normal", "#FFFFFF", "")

" NEOVIM TERMINAL MODE
let g:terminal_color_0 = "#263238"
let g:terminal_color_1 = "#FF5252"
let g:terminal_color_2 = "#69F0AE"
let g:terminal_color_3 = "#FFD740"
let g:terminal_color_4 = "#40C4FF"
let g:terminal_color_5 = "#FF4081"
let g:terminal_color_6 = "#64FCDA"
let g:terminal_color_7 = "#FFFFFF"
let g:terminal_color_8 = "#B0BEC5"
let g:terminal_color_9 = "#FF8A80"
let g:terminal_color_10 = "#B9F6CA"
let g:terminal_color_11 = "#FFE57F"
let g:terminal_color_12 = "#80D8FF"
let g:terminal_color_13 = "#FF80AB"
let g:terminal_color_14 = "#A7FDEB"
let g:terminal_color_15 = "#FFFFFF"


" ==================================================================
" UI GROUPS
" ==================================================================

" USER ACTION NEEDED
call s:highlight_helper("Error", "#FF5252", "")
call s:highlight_helper("ErrorMsg", "#FF5252", "")
call s:highlight_helper("WarningMsg", "#FF5252", "")
call s:highlight_helper("SpellBad", "#FF5252", "")
call s:highlight_helper("SpellCap", "#FF5252", "")
call s:highlight_helper("Todo", "#FF5252", "")
call s:highlight_helper("NeomakeErrorSign", "#FF5252", "")
call s:highlight_helper("NeomakeWarningSign", "#FF5252", "")

" USER CURRENT STATE
call s:highlight_helper("MatchParen", "#64FCDA", "NONE")
call s:highlight_helper("CursorLineNr", "#64FCDA", "")
call s:highlight_helper("Visual", "#263238", "#64FCDA")
call s:highlight_helper("VisualNOS", "#263238", "#64FCDA")
call s:highlight_helper("Folded", "#64FCDA", "")
call s:highlight_helper("FoldColumn", "#64FCDA", "")
call s:highlight_helper("IncSearch", "#64FCDA", "#1E272C")
call s:highlight_helper("Search", "#64FCDA", "#1E272C")
call s:highlight_helper("WildMenu", "#1E272C", "#64FCDA")
call s:highlight_helper("Question", "#64FCDA", "")
call s:highlight_helper("MoreMsg", "#64FCDA", "")
call s:highlight_helper("ModeMsg", "#64FCDA", "")
call s:highlight_helper("StatusLine", "#64FCDA", "#1E272C")
call s:highlight_helper("PmenuSel", "#556873", "#64FCDA")
call s:highlight_helper("PmenuThumb", "#64FCDA", "#64FCDA")
call s:highlight_helper("CtrlPMatch", "#263238", "#64FCDA")

" VERSION CONTROL
call s:highlight_helper("DiffAdd", "#263238", "#69F0AE")
call s:highlight_helper("DiffChange", "#263238", "#FF8A80")
call s:highlight_helper("DiffDelete", "#FF5252", "")
call s:highlight_helper("DiffText", "#263238", "#FF8A80", "BOLD")
call s:highlight_helper("GitGutterAdd", "#69F0AE", "")
call s:highlight_helper("GitGutterChange", "#FF8A80", "")
call s:highlight_helper("GitGutterChangeDelete", "#FF8A80", "")
call s:highlight_helper("GitGutterDelete", "#FF5252", "")

" OTHER
call s:highlight_helper("SignColumn", "NONE", "")
call s:highlight_helper("LineNr", "#6A7D89", "")
call s:highlight_helper("CursorLine", "NONE", "#556873")
call s:highlight_helper("CursorColumn", "NONE", "#556873")
call s:highlight_helper("EndOfBuffer", "#556873", "")
call s:highlight_helper("VertSplit", "#1E272C", "")
call s:highlight_helper("StatusLineNC", "#6A7D89", "#1E272C")
call s:highlight_helper("Pmenu", "#FFFFFF", "#556873")
call s:highlight_helper("PmenuSbar", "#B0BEC5", "#B0BEC5")
call s:highlight_helper("ColorColumn", "#556873", "")
call s:highlight_helper("CtrlPStats", "#FF8A80", "")
call s:highlight_helper("fzf1", "#263238", "#556873")
call s:highlight_helper("fzf2", "#263238", "#556873")
call s:highlight_helper("fzf3", "#263238", "#556873")
call s:highlight_helper("EasyMotionTarget", "#FF5252", "", "BOLD")
call s:highlight_helper("EasyMotionTarget2First", "#FF8A80", "")
call s:highlight_helper("EasyMotionTarget2Second", "#FFD740", "")
call s:highlight_helper("EasyMotionShade", "#B0BEC5", "")


" ==================================================================
" SYNTAX GROUPS
" ==================================================================

" CONSTANT
call s:highlight_helper("Constant", "#64FCDA", "")
call s:highlight_helper("Directory", "#64FCDA", "")
call s:highlight_helper("jsObjectBraces", "#64FCDA", "")
call s:highlight_helper("jsBrackets", "#64FCDA", "")
call s:highlight_helper("jsObjectValue", "#64FCDA", "")
call s:highlight_helper("jsParen", "#64FCDA", "")
call s:highlight_helper("jsParenSwitch", "#64FCDA", "")
call s:highlight_helper("jsParenIfElse", "#64FCDA", "")
call s:highlight_helper("jsBracket", "#64FCDA", "")
call s:highlight_helper("jsTernaryIf", "#64FCDA", "")
call s:highlight_helper("jsTemplateString", "#64FCDA", "")
call s:highlight_helper("jsTemplateVar", "#64FCDA", "")
call s:highlight_helper("cssAttr", "#64FCDA", "")
call s:highlight_helper("cssAttrRegion", "#64FCDA", "")
call s:highlight_helper("cssAttributeSelector", "#64FCDA", "")
call s:highlight_helper("htmlTitle", "#64FCDA", "")
call s:highlight_helper("htmlH1", "#64FCDA", "")
call s:highlight_helper("htmlH2", "#64FCDA", "")
call s:highlight_helper("htmlH3", "#64FCDA", "")
call s:highlight_helper("htmlH4", "#64FCDA", "")
call s:highlight_helper("htmlH5", "#64FCDA", "")
call s:highlight_helper("htmlH6", "#64FCDA", "")
call s:highlight_helper("htmlLink", "#64FCDA", "")
call s:highlight_helper("markdownCode", "#64FCDA", "")
call s:highlight_helper("markdownCodeBlock", "#64FCDA", "")
call s:highlight_helper("xmlString", "#64FCDA", "")
call s:highlight_helper("netrwPlain", "#64FCDA", "")
call s:highlight_helper("netrwDir", "#64FCDA", "")
call s:highlight_helper("shDerefSimple", "#64FCDA", "")

" IDENTIFIER
call s:highlight_helper("Identifier", "#40C4FF", "")
call s:highlight_helper("jsVariableDef", "#40C4FF", "")
call s:highlight_helper("jsObject", "#40C4FF", "")
call s:highlight_helper("jsObjectKey", "#40C4FF", "")
call s:highlight_helper("jsObjectStringKey", "#40C4FF", "")
call s:highlight_helper("jsFuncArgs", "#40C4FF", "")
call s:highlight_helper("jsDestructuringBlock", "#40C4FF", "")
call s:highlight_helper("jsDestructuringArray", "#40C4FF", "")
call s:highlight_helper("jsDestructuringPropertyValue", "#40C4FF", "")
call s:highlight_helper("jsSpreadExpression", "#40C4FF", "")
call s:highlight_helper("jsImportContainer", "#40C4FF", "")
call s:highlight_helper("jsExportContainer", "#40C4FF", "")
call s:highlight_helper("jsModuleGroup", "#40C4FF", "")
call s:highlight_helper("cssClassName", "#40C4FF", "")
call s:highlight_helper("cssIdentifier", "#40C4FF", "")
call s:highlight_helper("htmlTagName", "#40C4FF", "")
call s:highlight_helper("htmlSpecialTagName", "#40C4FF", "")
call s:highlight_helper("htmlTag", "#40C4FF", "")
call s:highlight_helper("htmlEndTag", "#40C4FF", "")
call s:highlight_helper("jsonKeyword", "#40C4FF", "")
call s:highlight_helper("xmlAttrib", "#40C4FF", "")
call s:highlight_helper("netrwExe", "#40C4FF", "")
call s:highlight_helper("shFunction", "#40C4FF", "")
call s:highlight_helper("typescriptVariableDeclaration", "#40C4FF", "")
call s:highlight_helper("typescriptCall", "#40C4FF", "")

" STATEMENT
call s:highlight_helper("Statement", "#FFD740", "")
call s:highlight_helper("jsFuncCall", "#FFD740", "")
call s:highlight_helper("jsOperator", "#FFD740", "")
call s:highlight_helper("jsSpreadOperator", "#FFD740", "")
call s:highlight_helper("cssFunctionName", "#FFD740", "")
call s:highlight_helper("cssProp", "#FFD740", "")
call s:highlight_helper("htmlArg", "#FFD740", "")
call s:highlight_helper("jsxRegion", "#FFD740", "")
call s:highlight_helper("xmlTag", "#FFD740", "")
call s:highlight_helper("xmlEndTag", "#FFD740", "")
call s:highlight_helper("xmlTagName", "#FFD740", "")
call s:highlight_helper("xmlEqual", "#FFD740", "")
call s:highlight_helper("shCmdSubRegion", "#FFD740", "")
call s:highlight_helper("typescriptOperator", "#FFD740", "")
call s:highlight_helper("typescriptOpSymbols", "#FFD740", "")
call s:highlight_helper("typescriptProp", "#FFD740", "")

" TYPE
call s:highlight_helper("Type", "#69F0AE", "")
call s:highlight_helper("jsFunction", "#69F0AE", "")
call s:highlight_helper("jsStorageClass", "#69F0AE", "")
call s:highlight_helper("jsNan", "#69F0AE", "")
call s:highlight_helper("shFunctionKey", "#69F0AE", "")
call s:highlight_helper("typescriptEnumKeyword", "#69F0AE", "")
call s:highlight_helper("typescriptVariable", "#69F0AE", "")
call s:highlight_helper("typescriptFuncKeyword", "#69F0AE", "")
call s:highlight_helper("typescriptDefault", "#69F0AE", "")

" GLOBAL
call s:highlight_helper("PreProc", "#FF4081", "")
call s:highlight_helper("jsGlobalObjects", "#FF4081", "")
call s:highlight_helper("jsThis", "#FF4081", "")
call s:highlight_helper("cssTagName", "#FF4081", "")
call s:highlight_helper("jsGlobalNodeObjects", "#FF4081", "")
call s:highlight_helper("cssFontDescriptor", "#FF4081", "")
call s:highlight_helper("typescriptGlobal", "#FF4081", "")
call s:highlight_helper("typescriptExport", "#FF4081", "")
call s:highlight_helper("typescriptImport", "#FF4081", "")

" EMPHASIS
call s:highlight_helper("Underlined", "#FF80AB", "")
call s:highlight_helper("markdownItalic", "#FF80AB", "")
call s:highlight_helper("markdownBold", "#FF80AB", "")
call s:highlight_helper("markdownBoldItalic", "#FF80AB", "")

" SPECIAL
call s:highlight_helper("Special", "#FF8A80", "")
call s:highlight_helper("SpecialKey", "#FF8A80", "")
call s:highlight_helper("NonText", "#FF8A80", "")
call s:highlight_helper("Title", "#FF8A80", "")
call s:highlight_helper("jsBraces", "#FF8A80", "")
call s:highlight_helper("jsFuncBraces", "#FF8A80", "")
call s:highlight_helper("jsDestructuringBraces", "#FF8A80", "")
call s:highlight_helper("jsClassBraces", "#FF8A80", "")
call s:highlight_helper("jsParens", "#FF8A80", "")
call s:highlight_helper("jsFuncParens", "#FF8A80", "")
call s:highlight_helper("jsArrowFunction", "#FF8A80", "")
call s:highlight_helper("jsModuleAsterisk", "#FF8A80", "")
call s:highlight_helper("cssBraces", "#FF8A80", "")
call s:highlight_helper("cssBraces", "#FF8A80", "")
call s:highlight_helper("markdownHeadingDelimiter", "#FF8A80", "")
call s:highlight_helper("markdownH1", "#FF8A80", "")
call s:highlight_helper("markdownH2", "#FF8A80", "")
call s:highlight_helper("markdownH3", "#FF8A80", "")
call s:highlight_helper("markdownH4", "#FF8A80", "")
call s:highlight_helper("markdownH5", "#FF8A80", "")
call s:highlight_helper("markdownH6", "#FF8A80", "")
call s:highlight_helper("markdownRule", "#FF8A80", "")
call s:highlight_helper("markdownListMarker", "#FF8A80", "")
call s:highlight_helper("markdownOrderedListMarker", "#FF8A80", "")
call s:highlight_helper("markdownLinkText", "#FF8A80", "")
call s:highlight_helper("markdownCodeDelimiter", "#FF8A80", "")
call s:highlight_helper("netrwClassify", "#FF8A80", "")
call s:highlight_helper("netrwVersion", "#FF8A80", "")
call s:highlight_helper("typescriptParens", "#FF8A80", "")
call s:highlight_helper("typescriptBraces", "#FF8A80", "")
call s:highlight_helper("typescriptArrowFunc", "#FF8A80", "")

" TRIVIAL
call s:highlight_helper("Comment", "#B0BEC5", "")
call s:highlight_helper("Ignore", "#B0BEC5", "")
call s:highlight_helper("Conceal", "#B0BEC5", "")
call s:highlight_helper("Noise", "#B0BEC5", "")
call s:highlight_helper("jsNoise", "#B0BEC5", "")
call s:highlight_helper("cssClassNameDot", "#B0BEC5", "")
call s:highlight_helper("jsonQuote", "#B0BEC5", "")
call s:highlight_helper("shQuote", "#B0BEC5", "")
call s:highlight_helper("typescriptEndColons", "#B0BEC5", "")
call s:highlight_helper("typescriptTemplateSB", "#B0BEC5", "")