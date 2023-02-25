vim9script

# DO NOT EDIT THIS FILE DIRECTLY.
# It is meant to be generated by ./tools/GenerateImport.vim

# builtin_func {{{1

const builtin_func_list: list<string> =<< trim END
    abs
    acos
    add
    and
    appendbufline
    argc
    argidx
    arglistid
    argv
    asin
    assert_beeps
    assert_equal
    assert_equalfile
    assert_exception
    assert_fails
    assert_false
    assert_inrange
    assert_match
    assert_nobeep
    assert_notequal
    assert_notmatch
    assert_report
    assert_true
    atan
    atan2
    autocmd_add
    autocmd_delete
    autocmd_get
    balloon_gettext
    balloon_show
    balloon_split
    blob2list
    browsedir
    bufadd
    bufexists
    buffer_exists
    buffer_name
    buffer_number
    buflisted
    bufload
    bufloaded
    bufname
    bufnr
    bufwinid
    bufwinnr
    byte2line
    byteidx
    byteidxcomp
    ceil
    ch_canread
    ch_close
    ch_close_in
    ch_evalexpr
    ch_evalraw
    ch_getbufnr
    ch_getjob
    ch_info
    ch_log
    ch_logfile
    ch_open
    ch_read
    ch_readblob
    ch_readraw
    ch_sendexpr
    ch_sendraw
    ch_setoptions
    ch_status
    changenr
    char2nr
    charclass
    charcol
    charidx
    cindent
    clearmatches
    col
    complete
    complete_add
    complete_check
    complete_info
    cos
    cosh
    count
    cscope_connection
    cursor
    deepcopy
    deletebufline
    did_filetype
    diff_filler
    diff_hlID
    digraph_get
    digraph_getlist
    digraph_set
    digraph_setlist
    echoraw
    empty
    environ
    escape
    eventhandler
    executable
    exepath
    exists
    exists_compiled
    exp
    expand
    expandcmd
    extend
    extendnew
    feedkeys
    file_readable
    filereadable
    filewritable
    finddir
    findfile
    flatten
    flattennew
    float2nr
    floor
    fmod
    fnameescape
    fnamemodify
    foldclosed
    foldclosedend
    foldlevel
    foldtext
    foldtextresult
    foreground
    fullcommand
    funcref
    garbagecollect
    get
    getbufinfo
    getbufline
    getbufoneline
    getbufvar
    getcellwidths
    getchangelist
    getchar
    getcharmod
    getcharpos
    getcharsearch
    getcharstr
    getcmdcompltype
    getcmdline
    getcmdpos
    getcmdscreenpos
    getcmdtype
    getcmdwintype
    getcompletion
    getcurpos
    getcursorcharpos
    getcwd
    getenv
    getfontname
    getfperm
    getfsize
    getftime
    getftype
    getimstatus
    getjumplist
    getline
    getloclist
    getmarklist
    getmatches
    getmousepos
    getmouseshape
    getpid
    getpos
    getqflist
    getreg
    getreginfo
    getregtype
    getscriptinfo
    gettabinfo
    gettabvar
    gettabwinvar
    gettagstack
    gettext
    getwininfo
    getwinpos
    getwinposx
    getwinposy
    getwinvar
    glob
    glob2regpat
    globpath
    has
    has_key
    haslocaldir
    hasmapto
    highlightID
    highlight_exists
    histadd
    histdel
    histget
    histnr
    hlID
    hlexists
    hlget
    hlset
    hostname
    iconv
    indent
    index
    indexof
    input
    inputdialog
    inputlist
    inputrestore
    inputsave
    inputsecret
    interrupt
    invert
    isabsolutepath
    isdirectory
    isinf
    islocked
    isnan
    items
    job_getchannel
    job_info
    job_setoptions
    job_start
    job_status
    job_stop
    js_decode
    js_encode
    json_decode
    json_encode
    keys
    keytrans
    last_buffer_nr
    len
    libcall
    libcallnr
    line
    line2byte
    lispindent
    list2blob
    list2str
    listener_add
    listener_flush
    listener_remove
    localtime
    log
    log10
    maparg
    mapcheck
    maplist
    mapnew
    mapset
    matchadd
    matchaddpos
    matcharg
    matchdelete
    matchend
    matchfuzzy
    matchfuzzypos
    matchlist
    matchstr
    matchstrpos
    max
    menu_info
    min
    mkdir
    nextnonblank
    nr2char
    or
    pathshorten
    popup_atcursor
    popup_beval
    popup_clear
    popup_close
    popup_create
    popup_dialog
    popup_filter_menu
    popup_filter_yesno
    popup_findecho
    popup_findinfo
    popup_findpreview
    popup_getoptions
    popup_getpos
    popup_hide
    popup_list
    popup_locate
    popup_menu
    popup_move
    popup_notification
    popup_setoptions
    popup_settext
    popup_show
    pow
    prevnonblank
    printf
    prompt_getprompt
    prompt_setcallback
    prompt_setinterrupt
    prompt_setprompt
    prop_add
    prop_add_list
    prop_clear
    prop_find
    prop_list
    prop_remove
    prop_type_add
    prop_type_change
    prop_type_delete
    prop_type_get
    prop_type_list
    pum_getpos
    pumvisible
    py3eval
    pyxeval
    rand
    range
    readblob
    readdir
    readdirex
    readfile
    reduce
    reg_executing
    reg_recording
    reltime
    reltimefloat
    reltimestr
    remote_expr
    remote_foreground
    remote_peek
    remote_read
    remote_send
    remote_startserver
    remove
    rename
    repeat
    resolve
    reverse
    round
    screenattr
    screenchar
    screenchars
    screencol
    screenpos
    screenrow
    screenstring
    search
    searchcount
    searchdecl
    searchpair
    searchpairpos
    searchpos
    server2client
    serverlist
    setbufline
    setbufvar
    setcellwidths
    setcharpos
    setcharsearch
    setcmdline
    setcmdpos
    setcursorcharpos
    setenv
    setfperm
    setline
    setloclist
    setmatches
    setpos
    setqflist
    setreg
    settabvar
    settabwinvar
    settagstack
    setwinvar
    sha256
    shellescape
    shiftwidth
    sign_define
    sign_getdefined
    sign_getplaced
    sign_jump
    sign_place
    sign_placelist
    sign_undefine
    sign_unplace
    sign_unplacelist
    simplify
    sin
    sinh
    slice
    sound_clear
    sound_playevent
    sound_playfile
    sound_stop
    soundfold
    spellbadword
    spellsuggest
    sqrt
    srand
    state
    str2float
    str2list
    str2nr
    strcharlen
    strcharpart
    strchars
    strdisplaywidth
    strftime
    strgetchar
    stridx
    string
    strlen
    strpart
    strptime
    strridx
    strtrans
    strwidth
    submatch
    swapfilelist
    swapinfo
    synID
    synIDattr
    synIDtrans
    synconcealed
    synstack
    system
    systemlist
    tabpagebuflist
    tabpagenr
    tabpagewinnr
    tagfiles
    taglist
    tan
    tanh
    tempname
    term_dumpdiff
    term_dumpload
    term_dumpwrite
    term_getaltscreen
    term_getansicolors
    term_getattr
    term_getcursor
    term_getjob
    term_getline
    term_getscrolled
    term_getsize
    term_getstatus
    term_gettitle
    term_gettty
    term_list
    term_scrape
    term_sendkeys
    term_setansicolors
    term_setapi
    term_setkill
    term_setrestore
    term_setsize
    term_start
    term_wait
    terminalprops
    test_alloc_fail
    test_autochdir
    test_feedinput
    test_garbagecollect_now
    test_garbagecollect_soon
    test_getvalue
    test_gui_event
    test_ignore_error
    test_mswin_event
    test_null_blob
    test_null_channel
    test_null_dict
    test_null_function
    test_null_job
    test_null_list
    test_null_partial
    test_null_string
    test_option_not_set
    test_override
    test_refcount
    test_setmouse
    test_settime
    test_srand_seed
    test_unknown
    test_void
    timer_info
    timer_pause
    timer_start
    timer_stop
    timer_stopall
    tolower
    toupper
    tr
    trim
    trunc
    typename
    undofile
    undotree
    uniq
    values
    virtcol
    virtcol2col
    visualmode
    wildmenumode
    win_execute
    win_findbuf
    win_getid
    win_gettype
    win_gotoid
    win_id2tabwin
    win_id2win
    win_move_separator
    win_move_statusline
    win_screenpos
    win_splitmove
    winbufnr
    wincol
    windowsversion
    winheight
    winlayout
    winline
    winnr
    winrestcmd
    winrestview
    winsaveview
    winwidth
    wordcount
    writefile
    xor
    debugbreak
    luaeval
    mzeval
    perleval
    pyeval
    rubyeval
END

export const builtin_func: string = builtin_func_list->join()

# builtin_func_ambiguous {{{1

const builtin_func_ambiguous_list: list<string> =<< trim END
    append
    browse
    call
    chdir
    confirm
    copy
    delete
    eval
    execute
    filter
    function
    insert
    join
    map
    match
    mode
    sort
    split
    substitute
    swapname
    type
END

export const builtin_func_ambiguous: string = builtin_func_ambiguous_list->join("\\|")

# collation_class {{{1

const collation_class_list: list<string> =<< trim END
    alnum
    alpha
    backspace
    blank
    cntrl
    digit
    escape
    fname
    graph
    ident
    keyword
    lower
    print
    punct
    return
    space
    tab
    upper
    xdigit
END

export const collation_class: string = collation_class_list->join("\\|")

# command_address_type {{{1

const command_address_type_list: list<string> =<< trim END
    arguments
    buffers
    lines
    loaded_buffers
    other
    quickfix
    tabs
    windows
END

export const command_address_type: string = command_address_type_list->join("\\|")

# command_can_be_before {{{1

export const command_can_be_before: string = '\%([ \t\n]\@=\|\c<\%(bar\|cr\)>\)\%(\s*\%([-+*/%]=\|=\s\|=<<\|\.\.=\)\|\_s*\%(->\|[-+*/%]\%(\s\+\)\@>[^|<]\)\)\@!'

# command_complete_type {{{1

const command_complete_type_list: list<string> =<< trim END
    arglist
    augroup
    behave
    breakpoint
    buffer
    color
    command
    compiler
    cscope
    customlist
    custom
    diff_buffer
    dir
    environment
    event
    expression
    file_in_path
    filetype
    file
    function
    help
    highlight
    history
    locale
    mapclear
    mapping
    menu
    messages
    option
    packadd
    runtime
    scriptnames
    shellcmd
    sign
    syntax
    syntime
    tag_listfiles
    tag
    user
    var
END

export const command_complete_type: string = command_complete_type_list->join("\\|")

# command_modifier {{{1

const command_modifier_list: list<string> =<< trim END
    abo\%[veleft]
    bel\%[owright]
    bo\%[tright]
    bro\%[wse]
    conf\%[irm]
    hid\%[e]
    keepa\%[lt]
    keepj\%[umps]
    ke\%[epmarks]
    keepp\%[atterns]
    lefta\%[bove]
    leg\%[acy]
    loc\%[kmarks]
    noa\%[utocmd]
    nos\%[wapfile]
    rightb\%[elow]
    san\%[dbox]
    sil\%[ent]
    tab
    to\%[pleft]
    uns\%[ilent]
    verb\%[ose]
    vert\%[ical]
    vim9\%[cmd]
END

export const command_modifier: string = command_modifier_list->join("\\|")

# command_name {{{1

const command_name_list: list<string> =<< trim END
    al[l]
    am[enu]
    an[oremenu]
    arga[dd]
    argded[upe]
    argd[elete]
    arge[dit]
    argg[lobal]
    argl[ocal]
    ar[gs]
    argu[ment]
    as[cii]
    aun[menu]
    bN[ext]
    bad[d]
    ba[ll]
    balt
    bd[elete]
    be[have]
    bf[irst]
    bl[ast]
    bm[odified]
    bn[ext]
    bp[revious]
    breaka[dd]
    breakd[el]
    breakl[ist]
    br[ewind]
    b[uffer]
    buffers
    bun[load]
    bw[ipeout]
    cN[ext]
    cNf[ile]
    cabo[ve]
    cad[dbuffer]
    cadde[xpr]
    caddf[ile]
    caf[ter]
    cal[l]
    cbe[fore]
    cbel[ow]
    cbo[ttom]
    cb[uffer]
    cc
    ccl[ose]
    ce[nter]
    cex[pr]
    cf[ile]
    cfir[st]
    cgetb[uffer]
    cgete[xpr]
    cg[etfile]
    changes
    che[ckpath]
    checkt[ime]
    chi[story]
    cla[st]
    cle[arjumps]
    cl[ist]
    clo[se]
    cme[nu]
    cnew[er]
    cn[ext]
    cnf[ile]
    cnoreme[nu]
    col[der]
    colo[rscheme]
    comc[lear]
    comp[iler]
    cope[n]
    cpf[ile]
    cp[revious]
    cq[uit]
    cr[ewind]
    cs[cope]
    cst[ag]
    cunme[nu]
    cw[indow]
    deb[ug]
    debugg[reedy]
    def
    defc[ompile]
    defe[r]
    delc[ommand]
    d[elete]
    delf[unction]
    delm[arks]
    diffg[et]
    diffo[ff]
    diffp[atch]
    diffpu[t]
    diffs[plit]
    difft[his]
    dif[fupdate]
    disa[ssemble]
    di[splay]
    dj[ump]
    dl[ist]
    dr[op]
    ds[earch]
    dsp[lit]
    ea[rlier]
    ec[ho]
    echoc[onsole]
    echoe[rr]
    echom[sg]
    echon
    echow[indow]
    e[dit]
    em[enu]
    enddef
    endf[unction]
    ene[w]
    ev[al]
    ex
    exe[cute]
    exi[t]
    exu[sage]
    f[ile]
    files
    filt[er]
    fin[d]
    fir[st]
    fix[del]
    fo[ld]
    foldc[lose]
    folddoc[losed]
    foldd[oopen]
    foldo[pen]
    fu[nction]
    go[to]
    gr[ep]
    grepa[dd]
    gu[i]
    gv[im]
    ha[rdcopy]
    h[elp]
    helpc[lose]
    helpf[ind]
    helpg[rep]
    helpt[ags]
    his[tory]
    ho[rizontal]
    ij[ump]
    il[ist]
    ime[nu]
    inoreme[nu]
    int[ro]
    is[earch]
    isp[lit]
    iunme[nu]
    j[oin]
    ju[mps]
    lN[ext]
    lNf[ile]
    lab[ove]
    laddb[uffer]
    lad[dexpr]
    laddf[ile]
    laf[ter]
    lan[guage]
    la[st]
    lat[er]
    lbe[fore]
    lbel[ow]
    lbo[ttom]
    lb[uffer]
    lcl[ose]
    lcs[cope]
    le[ft]
    lex[pr]
    lf[ile]
    lfir[st]
    lgetb[uffer]
    lgete[xpr]
    lg[etfile]
    lgr[ep]
    lgrepa[dd]
    lh[elpgrep]
    lhi[story]
    l[ist]
    ll
    lla[st]
    lli[st]
    lmak[e]
    lnew[er]
    lne[xt]
    lnf[ile]
    loadk[eymap]
    lo[adview]
    lockv[ar]
    lol[der]
    lop[en]
    lpf[ile]
    lp[revious]
    lr[ewind]
    ls
    lt[ag]
    luad[o]
    luaf[ile]
    lw[indow]
    mak[e]
    marks
    mat[ch]
    me[nu]
    menut[ranslate]
    mes[sages]
    mk[exrc]
    mks[ession]
    mksp[ell]
    mkvie[w]
    mkv[imrc]
    mzf[ile]
    mz[scheme]
    nbc[lose]
    nb[key]
    nbs[tart]
    new
    n[ext]
    nme[nu]
    nnoreme[nu]
    noh[lsearch]
    noreme[nu]
    nu[mber]
    nunme[nu]
    ol[dfiles]
    ome[nu]
    on[ly]
    onoreme[nu]
    opt[ions]
    ounme[nu]
    ow[nsyntax]
    pa[ckadd]
    packl[oadall]
    pc[lose]
    ped[it]
    pe[rl]
    perld[o]
    po[p]
    popu[p]
    pp[op]
    pre[serve]
    prev[ious]
    p[rint]
    profd[el]
    prof[ile]
    pro[mptfind]
    promptr[epl]
    ps[earch]
    ptN[ext]
    pt[ag]
    ptf[irst]
    ptj[ump]
    ptl[ast]
    ptn[ext]
    ptp[revious]
    ptr[ewind]
    pts[elect]
    pu[t]
    pw[d]
    py3
    py3d[o]
    py3f[ile]
    pyd[o]
    pyf[ile]
    pyx
    pyxd[o]
    pyxf[ile]
    qa[ll]
    q[uit]
    quita[ll]
    r[ead]
    rec[over]
    redi[r]
    red[o]
    redr[aw]
    redraws[tatus]
    redrawt[abline]
    reg[isters]
    res[ize]
    ret[ab]
    rew[ind]
    ri[ght]
    rub[y]
    rubyd[o]
    rubyf[ile]
    rund[o]
    ru[ntime]
    rv[iminfo]
    sN[ext]
    sal[l]
    sa[rgument]
    sav[eas]
    sbN[ext]
    sba[ll]
    sbf[irst]
    sbl[ast]
    sbm[odified]
    sbn[ext]
    sbp[revious]
    sbr[ewind]
    sb[uffer]
    scripte[ncoding]
    sc[riptnames]
    scriptv[ersion]
    scs[cope]
    setf[iletype]
    sf[ind]
    sfir[st]
    sh[ell]
    sig[n]
    si[malt]
    sla[st]
    sl[eep]
    sm[agic]
    sme[nu]
    smi[le]
    sn[ext]
    sno[magic]
    snoreme[nu]
    sor[t]
    so[urce]
    spelld[ump]
    spe[llgood]
    spelli[nfo]
    spellra[re]
    spellr[epall]
    spellu[ndo]
    spellw[rong]
    sp[lit]
    spr[evious]
    sr[ewind]
    sta[g]
    startg[replace]
    star[tinsert]
    startr[eplace]
    stj[ump]
    st[op]
    stopi[nsert]
    sts[elect]
    sun[hide]
    sunme[nu]
    sus[pend]
    sv[iew]
    sw[apname]
    sync[bind]
    synti[me]
    tN[ext]
    tabN[ext]
    tabc[lose]
    tabe[dit]
    tabf[ind]
    tabfir[st]
    tabl[ast]
    tabm[ove]
    tabnew
    tabn[ext]
    tabo[nly]
    tabp[revious]
    tabr[ewind]
    tabs
    ta[g]
    tags
    tcl
    tcld[o]
    tclf[ile]
    te[aroff]
    ter[minal]
    tf[irst]
    this
    tj[ump]
    tl[ast]
    tlm[enu]
    tln[oremenu]
    tlu[nmenu]
    tm[enu]
    tn[ext]
    tp[revious]
    tr[ewind]
    ts[elect]
    tu[nmenu]
    u[ndo]
    undoj[oin]
    undol[ist]
    unh[ide]
    unlo[ckvar]
    unme[nu]
    up[date]
    ve[rsion]
    vie[w]
    vim9s[cript]
    vi[sual]
    viu[sage]
    vme[nu]
    vne[w]
    vnoreme[nu]
    vs[plit]
    vunme[nu]
    wN[ext]
    wa[ll]
    winp[os]
    wi[nsize]
    wn[ext]
    wp[revious]
    wq
    wqa[ll]
    w[rite]
    wu[ndo]
    wv[iminfo]
    xa[ll]
    xme[nu]
    xnoreme[nu]
    xr[estore]
    xunme[nu]
    y[ank]
    addd
END

export const command_name: string = command_name_list->join()

# default_highlighting_group {{{1

const default_highlighting_group_list: list<string> =<< trim END
    ColorColumn
    CurSearch
    Cursor
    CursorColumn
    CursorIM
    CursorLine
    CursorLineFold
    CursorLineNr
    CursorLineSign
    DiffAdd
    DiffChange
    DiffDelete
    DiffText
    Directory
    EndOfBuffer
    ErrorMsg
    FoldColumn
    Folded
    IncSearch
    LineNr
    LineNrAbove
    LineNrBelow
    MatchParen
    Menu
    MessageWindow
    ModeMsg
    MoreMsg
    NonText
    Normal
    Pmenu
    PmenuSbar
    PmenuSel
    PmenuThumb
    PopupNotification
    Question
    QuickFixLine
    Scrollbar
    Search
    SignColumn
    SpecialKey
    SpellBad
    SpellCap
    SpellLocal
    SpellRare
    StatusLine
    StatusLineNC
    StatusLineTerm
    StatusLineTermNC
    TOhtmlProgress
    TabLine
    TabLineFill
    TabLineSel
    Terminal
    Title
    Tooltip
    User1
    User2
    User3
    User4
    User5
    User6
    User7
    User8
    User9
    VertSplit
    Visual
    VisualNOS
    WarningMsg
    WildMenu
    debugBreakpoint
    debugPC
END

export const default_highlighting_group: string = default_highlighting_group_list->join()

# event {{{1

const event_list: list<string> =<< trim END
    BufAdd
    BufCreate
    BufDelete
    BufEnter
    BufFilePost
    BufFilePre
    BufHidden
    BufLeave
    BufNew
    BufNewFile
    BufRead
    BufReadCmd
    BufReadPost
    BufReadPre
    BufUnload
    BufWinEnter
    BufWinLeave
    BufWipeout
    BufWrite
    BufWriteCmd
    BufWritePost
    BufWritePre
    CmdUndefined
    CmdlineChanged
    CmdlineEnter
    CmdlineLeave
    CmdwinEnter
    CmdwinLeave
    ColorScheme
    ColorSchemePre
    CompleteChanged
    CompleteDone
    CompleteDonePre
    CursorHold
    CursorHoldI
    CursorMoved
    CursorMovedI
    DiffUpdated
    DirChanged
    DirChangedPre
    EncodingChanged
    ExitPre
    FileAppendCmd
    FileAppendPost
    FileAppendPre
    FileChangedRO
    FileChangedShell
    FileChangedShellPost
    FileEncoding
    FileReadCmd
    FileReadPost
    FileReadPre
    FileType
    FileWriteCmd
    FileWritePost
    FileWritePre
    FilterReadPost
    FilterReadPre
    FilterWritePost
    FilterWritePre
    FocusGained
    FocusLost
    FuncUndefined
    GUIEnter
    GUIFailed
    InsertChange
    InsertCharPre
    InsertEnter
    InsertLeave
    InsertLeavePre
    MenuPopup
    ModeChanged
    OptionSet
    QuickFixCmdPost
    QuickFixCmdPre
    QuitPre
    RemoteReply
    SafeState
    SafeStateAgain
    SessionLoadPost
    ShellCmdPost
    ShellFilterPost
    SigUSR1
    SourceCmd
    SourcePost
    SourcePre
    SpellFileMissing
    StdinReadPost
    StdinReadPre
    SwapExists
    Syntax
    TabClosed
    TabEnter
    TabLeave
    TabNew
    TermChanged
    TermResponse
    TerminalOpen
    TerminalWinOpen
    TextChanged
    TextChangedI
    TextChangedP
    TextChangedT
    TextYankPost
    User
    VimEnter
    VimLeave
    VimLeavePre
    VimResized
    VimResume
    VimSuspend
    WinClosed
    WinEnter
    WinLeave
    WinNew
    WinResized
    WinScrolled
END

export const event: string = event_list->join()

# ex_special_characters {{{1

const ex_special_characters_list: list<string> =<< trim END
    abuf
    afile
    cWORD
    cexpr
    cfile
    cword
    sfile
    slnum
    stack
    amatch
    client
    script
    sflnum
END

export const ex_special_characters: string = ex_special_characters_list->join("\\|")

# increment_invalid {{{1

export const increment_invalid: string = '\%(++\|--\)\%(\%(\%([bgstvw]:\)\=\h\w*\|&\%([lg]:\)\=[a-z]\{2,}\)\s*\_[[|.]\)\@!'

# key_name {{{1

const key_name_list: list<string> =<< trim END
    BS
    BackSpace
    Bslash
    CR
    CSI
    CursorHold
    DecMouse
    Del
    Delete
    Down
    Drop
    End
    Enter
    Esc
    FocusGained
    FocusLost
    Help
    Home
    Ignore
    Ins
    Insert
    LF
    Left
    LeftDrag
    LeftMouse
    LeftMouseNM
    LeftRelease
    LeftReleaseNM
    LineFeed
    MiddleDrag
    MiddleMouse
    MiddleRelease
    Mouse
    MouseDown
    MouseMove
    MouseUp
    NL
    NetMouse
    NewLine
    Nop
    Nul
    PageDown
    PageUp
    PasteEnd
    PasteStart
    Plug
    Return
    Right
    RightDrag
    RightMouse
    RightRelease
    SID
    SNR
    ScriptCmd
    ScrollWheelDown
    ScrollWheelLeft
    ScrollWheelRight
    ScrollWheelUp
    SgrMouse
    SgrMouseRelease
    Space
    Tab
    Undo
    Up
    UrxvtMouse
    X1Drag
    X1Mouse
    X1Release
    X2Drag
    X2Mouse
    X2Release
    k0
    k1
    k2
    k3
    k4
    k5
    k6
    k7
    k8
    k9
    kDel
    kDivide
    kEnd
    kEnter
    kHome
    kInsert
    kMinus
    kMultiply
    kPageDown
    kPageUp
    kPlus
    kPoint
    lt
    xCSI
    xDown
    xEnd
    xF1
    xF2
    xF3
    xF4
    xHome
    xLeft
    xRight
    xUp
    zEnd
    zHome
    F\d\{1,2}
    .
END

export const key_name: string = key_name_list->join("\\|")

# lambda_end {{{1

export const lambda_end: string = ')\ze\%(:.\{-}\)\=\s\+=>'

# lambda_start {{{1

export const lambda_start: string = '(\ze\%(\s*\h\w*\%([^(]\|\%(\<func\)\@4<=(\)*\|\s*\.\.\._\)\=)\%(:.\{-}\)\=\s\+=>'

# logical_not {{{1

export const logical_not: string = '/\w\@1<!![~=]\@!!*/'

# mark_valid {{{1

export const mark_valid: string = '[a-zA-Z''`[\]<>0-9"^.(){}]'

# maybe_dict_literal_key {{{1

export const maybe_dict_literal_key: string = '/\%([{\n]\|[^ \t\n,{\\]\@1<!\s\)\@1<=[^ \t{(''"]\+\ze\%(:\_s\)\@=/'

# most_operators {{{1

export const most_operators: string = '"\%(\_s\)\@1<=\%([-+*/%]\|\.\.\|||\|&&\|??\=\|<<\|>>\|\%([=!]=\|[<>]=\=\|[=!]\~\|is\|isnot\)[?#]\=\)\_s\@=\%(\s*[|<]\)\@!"'

# option {{{1

const option_list: list<string> =<< trim END
    aleph
    al
    allowrevins
    ari
    noallowrevins
    noari
    altkeymap
    akm
    noaltkeymap
    noakm
    ambiwidth
    ambw
    antialias
    anti
    noantialias
    noanti
    autochdir
    acd
    noautochdir
    noacd
    autoshelldir
    asd
    noautoshelldir
    noasd
    arabic
    arab
    noarabic
    noarab
    arabicshape
    arshape
    noarabicshape
    noarshape
    autoindent
    ai
    noautoindent
    noai
    autoread
    ar
    noautoread
    noar
    autowrite
    aw
    noautowrite
    noaw
    autowriteall
    awa
    noautowriteall
    noawa
    background
    bg
    backspace
    bs
    backup
    bk
    nobackup
    nobk
    backupcopy
    bkc
    backupdir
    bdir
    backupext
    bex
    backupskip
    bsk
    balloondelay
    bdlay
    ballooneval
    beval
    noballooneval
    nobeval
    balloonevalterm
    bevalterm
    noballoonevalterm
    nobevalterm
    balloonexpr
    bexpr
    belloff
    bo
    binary
    bin
    nobinary
    nobin
    bomb
    nobomb
    breakat
    brk
    breakindent
    bri
    nobreakindent
    nobri
    breakindentopt
    briopt
    browsedir
    bsdir
    bufhidden
    bh
    buflisted
    bl
    nobuflisted
    nobl
    buftype
    bt
    casemap
    cmp
    cdhome
    cdh
    nocdhome
    nocdh
    cdpath
    cd
    cedit
    charconvert
    ccv
    cindent
    cin
    nocindent
    nocin
    cinkeys
    cink
    cinoptions
    cino
    cinwords
    cinw
    cinscopedecls
    cinsd
    clipboard
    cb
    cmdheight
    ch
    cmdwinheight
    cwh
    colorcolumn
    cc
    columns
    co
    comments
    com
    commentstring
    cms
    compatible
    cp
    nocompatible
    nocp
    complete
    cpt
    completefunc
    cfu
    completeslash
    csl
    completeopt
    cot
    completepopup
    cpp
    concealcursor
    cocu
    conceallevel
    cole
    confirm
    cf
    noconfirm
    nocf
    copyindent
    ci
    nocopyindent
    noci
    cpoptions
    cpo
    cryptmethod
    cm
    cscopepathcomp
    cspc
    cscopeprg
    csprg
    cscopequickfix
    csqf
    cscoperelative
    csre
    nocscoperelative
    nocsre
    cscopetag
    cst
    nocscopetag
    nocst
    cscopetagorder
    csto
    cscopeverbose
    csverb
    nocscopeverbose
    nocsverb
    cursorbind
    crb
    nocursorbind
    nocrb
    cursorcolumn
    cuc
    nocursorcolumn
    nocuc
    cursorline
    cul
    nocursorline
    nocul
    cursorlineopt
    culopt
    debug
    define
    def
    delcombine
    deco
    nodelcombine
    nodeco
    dictionary
    dict
    diff
    nodiff
    dex
    diffexpr
    dip
    diffopt
    digraph
    dg
    nodigraph
    nodg
    directory
    dir
    display
    dy
    eadirection
    ead
    ed
    edcompatible
    noed
    noedcompatible
    emoji
    emo
    noemoji
    noemo
    encoding
    enc
    endoffile
    eof
    noendoffile
    noeof
    endofline
    eol
    noendofline
    noeol
    equalalways
    ea
    noequalalways
    noea
    equalprg
    ep
    errorbells
    eb
    noerrorbells
    noeb
    errorfile
    ef
    errorformat
    efm
    esckeys
    ek
    noesckeys
    noek
    eventignore
    ei
    expandtab
    et
    noexpandtab
    noet
    exrc
    ex
    noexrc
    noex
    fileencoding
    fenc
    fileencodings
    fencs
    fileformat
    ff
    fileformats
    ffs
    fileignorecase
    fic
    nofileignorecase
    nofic
    filetype
    ft
    fillchars
    fcs
    fixendofline
    fixeol
    nofixendofline
    nofixeol
    fkmap
    fk
    nofkmap
    nofk
    foldclose
    fcl
    foldcolumn
    fdc
    foldenable
    fen
    nofoldenable
    nofen
    foldexpr
    fde
    foldignore
    fdi
    foldlevel
    fdl
    foldlevelstart
    fdls
    foldmarker
    fmr
    foldmethod
    fdm
    foldminlines
    fml
    foldnestmax
    fdn
    foldopen
    fdo
    foldtext
    fdt
    formatexpr
    fex
    formatlistpat
    flp
    formatoptions
    fo
    formatprg
    fp
    fsync
    fs
    nofsync
    nofs
    gdefault
    gd
    nogdefault
    nogd
    grepformat
    gfm
    grepprg
    gp
    guicursor
    gcr
    guifont
    gfn
    guifontset
    gfs
    guifontwide
    gfw
    guiheadroom
    ghr
    guiligatures
    gli
    guioptions
    go
    guipty
    noguipty
    guitablabel
    gtl
    guitabtooltip
    gtt
    helpfile
    hf
    helpheight
    hh
    helplang
    hlg
    hidden
    hid
    nohidden
    nohid
    highlight
    hl
    history
    hi
    hkmap
    hk
    nohkmap
    nohk
    hkmapp
    hkp
    nohkmapp
    nohkp
    hlsearch
    hls
    nohlsearch
    nohls
    icon
    noicon
    iconstring
    ignorecase
    ic
    noignorecase
    noic
    imactivatefunc
    imaf
    imactivatekey
    imak
    imcmdline
    imc
    noimcmdline
    noimc
    imdisable
    imd
    noimdisable
    noimd
    iminsert
    imi
    imsearch
    ims
    imstatusfunc
    imsf
    imstyle
    imst
    include
    inc
    includeexpr
    inex
    incsearch
    is
    noincsearch
    nois
    indentexpr
    inde
    indentkeys
    indk
    infercase
    inf
    noinfercase
    noinf
    insertmode
    im
    noinsertmode
    noim
    isfname
    isf
    isident
    isi
    iskeyword
    isk
    isprint
    isp
    joinspaces
    js
    nojoinspaces
    nojs
    key
    keymap
    kmp
    keymodel
    km
    keyprotocol
    kpc
    keywordprg
    kp
    langmap
    lmap
    langmenu
    lm
    langnoremap
    lnr
    nolangnoremap
    nolnr
    langremap
    lrm
    nolangremap
    nolrm
    laststatus
    ls
    lazyredraw
    lz
    nolazyredraw
    nolz
    linebreak
    lbr
    nolinebreak
    nolbr
    lines
    linespace
    lsp
    lisp
    nolisp
    lispoptions
    lop
    lispwords
    lw
    list
    nolist
    listchars
    lcs
    lpl
    nolpl
    loadplugins
    noloadplugins
    luadll
    macatsui
    nomacatsui
    magic
    nomagic
    makeef
    mef
    makeencoding
    menc
    makeprg
    mp
    matchpairs
    mps
    matchtime
    mat
    maxcombine
    mco
    maxfuncdepth
    mfd
    maxmapdepth
    mmd
    maxmem
    mm
    maxmempattern
    mmp
    maxmemtot
    mmt
    menuitems
    mis
    mkspellmem
    msm
    modeline
    ml
    nomodeline
    noml
    modelineexpr
    mle
    nomodelineexpr
    nomle
    modelines
    mls
    modifiable
    ma
    nomodifiable
    noma
    modified
    mod
    nomodified
    nomod
    more
    nomore
    mouse
    mousefocus
    mousef
    nomousefocus
    nomousef
    mousehide
    mh
    nomousehide
    nomh
    mousemodel
    mousem
    mousemoveevent
    mousemev
    nomousemoveevent
    nomousemev
    mouseshape
    mouses
    mousetime
    mouset
    mzschemedll
    mzschemegcdll
    mzquantum
    mzq
    nrformats
    nf
    number
    nu
    nonumber
    nonu
    numberwidth
    nuw
    omnifunc
    ofu
    opendevice
    odev
    noopendevice
    noodev
    operatorfunc
    opfunc
    osfiletype
    oft
    packpath
    pp
    paragraphs
    para
    paste
    nopaste
    pastetoggle
    pt
    pex
    patchexpr
    patchmode
    pm
    path
    pa
    perldll
    preserveindent
    pi
    nopreserveindent
    nopi
    previewheight
    pvh
    previewpopup
    pvp
    previewwindow
    nopreviewwindow
    pvw
    nopvw
    printdevice
    pdev
    printencoding
    penc
    printexpr
    pexpr
    printfont
    pfn
    printheader
    pheader
    printmbcharset
    pmbcs
    printmbfont
    pmbfn
    printoptions
    popt
    prompt
    noprompt
    pumheight
    ph
    pumwidth
    pw
    pythondll
    pythonhome
    pythonthreedll
    pythonthreehome
    pyxversion
    pyx
    quickfixtextfunc
    qftf
    quoteescape
    qe
    readonly
    ro
    noreadonly
    noro
    redrawtime
    rdt
    regexpengine
    re
    relativenumber
    rnu
    norelativenumber
    nornu
    remap
    noremap
    renderoptions
    rop
    report
    restorescreen
    rs
    norestorescreen
    nors
    revins
    ri
    norevins
    nori
    rightleft
    rl
    norightleft
    norl
    rightleftcmd
    rlc
    rubydll
    ruler
    ru
    noruler
    noru
    rulerformat
    ruf
    runtimepath
    rtp
    scroll
    scr
    scrollbind
    scb
    noscrollbind
    noscb
    scrollfocus
    scf
    noscrollfocus
    noscf
    scrolljump
    sj
    scrolloff
    so
    scrollopt
    sbo
    sections
    sect
    secure
    nosecure
    selection
    sel
    selectmode
    slm
    sessionoptions
    ssop
    shell
    sh
    shellcmdflag
    shcf
    shellpipe
    sp
    shellquote
    shq
    shellredir
    srr
    shellslash
    ssl
    noshellslash
    nossl
    shelltemp
    stmp
    noshelltemp
    nostmp
    shelltype
    st
    shellxescape
    sxe
    shellxquote
    sxq
    shiftround
    sr
    noshiftround
    nosr
    shiftwidth
    sw
    shortmess
    shm
    shortname
    sn
    noshortname
    nosn
    showbreak
    sbr
    showcmd
    sc
    noshowcmd
    nosc
    showcmdloc
    sloc
    showfulltag
    sft
    noshowfulltag
    nosft
    showmatch
    sm
    noshowmatch
    nosm
    showmode
    smd
    noshowmode
    nosmd
    showtabline
    stal
    sidescroll
    ss
    sidescrolloff
    siso
    signcolumn
    scl
    smartcase
    scs
    nosmartcase
    noscs
    smartindent
    si
    nosmartindent
    nosi
    smarttab
    sta
    nosmarttab
    nosta
    smoothscroll
    sms
    nosmoothscroll
    nosms
    softtabstop
    sts
    spell
    nospell
    spellcapcheck
    spc
    spellfile
    spf
    spelllang
    spl
    spelloptions
    spo
    spellsuggest
    sps
    splitbelow
    sb
    nosplitbelow
    nosb
    splitkeep
    spk
    splitright
    spr
    nosplitright
    nospr
    startofline
    sol
    nostartofline
    nosol
    statusline
    stl
    suffixes
    su
    suffixesadd
    sua
    swapfile
    swf
    noswapfile
    noswf
    swapsync
    sws
    switchbuf
    swb
    synmaxcol
    smc
    syntax
    syn
    tabline
    tal
    tabpagemax
    tpm
    tabstop
    ts
    tagbsearch
    tbs
    notagbsearch
    notbs
    tagcase
    tc
    tagfunc
    tfu
    taglength
    tl
    tagrelative
    tr
    notagrelative
    notr
    tags
    tag
    tagstack
    tgst
    notagstack
    notgst
    tcldll
    term
    termbidi
    tbidi
    notermbidi
    notbidi
    termencoding
    tenc
    termguicolors
    tgc
    notermguicolors
    notgc
    termwinkey
    twk
    termwinscroll
    twsl
    termwinsize
    tws
    termwintype
    twt
    terse
    noterse
    textauto
    ta
    notextauto
    nota
    textmode
    tx
    notextmode
    notx
    textwidth
    tw
    thesaurus
    tsr
    thesaurusfunc
    tsrfu
    tildeop
    top
    notildeop
    notop
    timeout
    to
    notimeout
    noto
    ttimeout
    nottimeout
    timeoutlen
    tm
    ttimeoutlen
    ttm
    title
    notitle
    titlelen
    titleold
    titlestring
    toolbar
    tb
    toolbariconsize
    tbis
    ttybuiltin
    tbi
    nottybuiltin
    notbi
    ttyfast
    tf
    nottyfast
    notf
    ttymouse
    ttym
    ttyscroll
    tsl
    ttytype
    tty
    undodir
    udir
    undofile
    noundofile
    udf
    noudf
    undolevels
    ul
    undoreload
    ur
    updatecount
    uc
    updatetime
    ut
    varsofttabstop
    vsts
    vartabstop
    vts
    verbose
    vbs
    verbosefile
    vfile
    viewdir
    vdir
    viewoptions
    vop
    viminfo
    vi
    viminfofile
    vif
    virtualedit
    ve
    visualbell
    vb
    novisualbell
    novb
    warn
    nowarn
    weirdinvert
    wiv
    noweirdinvert
    nowiv
    whichwrap
    ww
    wildchar
    wc
    wildcharm
    wcm
    wildignore
    wig
    wildignorecase
    wic
    nowildignorecase
    nowic
    wildmenu
    wmnu
    nowildmenu
    nowmnu
    wildmode
    wim
    wildoptions
    wop
    winaltkeys
    wak
    wincolor
    wcr
    window
    wi
    winheight
    wh
    winfixheight
    wfh
    nowinfixheight
    nowfh
    winfixwidth
    wfw
    nowinfixwidth
    nowfw
    winminheight
    wmh
    winminwidth
    wmw
    winptydll
    winwidth
    wiw
    wrap
    nowrap
    wrapmargin
    wm
    wrapscan
    ws
    nowrapscan
    nows
    write
    nowrite
    writeany
    wa
    nowriteany
    nowa
    writebackup
    wb
    nowritebackup
    nowb
    writedelay
    wd
    xtermcodes
    noxtermcodes
END

export const option: string = option_list->join()

# option_can_be_after {{{1

export const option_can_be_after: string = '\%(\%(^\|[-+ \t!([>]\)\@1<=\|{\@1<=\)'

# option_modifier {{{1

export const option_modifier: string = '\%(&\%(vim\)\=\|[<?!]\)\%(\_s\||\)\@='

# option_sigil {{{1

export const option_sigil: string = '&\%([gl]:\)\='

# option_terminal {{{1

const option_terminal_list: list<string> =<< trim END
    t_8b
    t_8f
    t_8u
    t_AB
    t_AF
    t_AL
    t_AU
    t_BD
    t_BE
    t_CS
    t_CV
    t_Ce
    t_Co
    t_Cs
    t_DL
    t_Ds
    t_EC
    t_EI
    t_F1
    t_F2
    t_F3
    t_F4
    t_F5
    t_F6
    t_F7
    t_F8
    t_F9
    t_GP
    t_IE
    t_IS
    t_K1
    t_K3
    t_K4
    t_K5
    t_K6
    t_K7
    t_K8
    t_K9
    t_KA
    t_KB
    t_KC
    t_KD
    t_KE
    t_KF
    t_KG
    t_KH
    t_KI
    t_KJ
    t_KK
    t_KL
    t_PE
    t_PS
    t_RB
    t_RC
    t_RF
    t_RI
    t_RK
    t_RS
    t_RT
    t_RV
    t_Ri
    t_SC
    t_SH
    t_SI
    t_SR
    t_ST
    t_Sb
    t_Sf
    t_Si
    t_TE
    t_TI
    t_Te
    t_Ts
    t_Us
    t_VS
    t_WP
    t_WS
    t_XM
    t_ZH
    t_ZR
    t_al
    t_bc
    t_cd
    t_ce
    t_ci
    t_cl
    t_cm
    t_cs
    t_cv
    t_da
    t_db
    t_dl
    t_ds
    t_ed
    t_el
    t_f1
    t_f2
    t_f3
    t_f4
    t_f5
    t_f6
    t_f7
    t_f8
    t_f9
    t_fd
    t_fe
    t_fs
    t_il
    t_k1
    t_k2
    t_k3
    t_k4
    t_k5
    t_k6
    t_k7
    t_k8
    t_k9
    t_kB
    t_kD
    t_kI
    t_kN
    t_kP
    t_kb
    t_kd
    t_ke
    t_kh
    t_kl
    t_kr
    t_ks
    t_ku
    t_le
    t_mb
    t_md
    t_me
    t_mr
    t_ms
    t_nd
    t_op
    t_se
    t_so
    t_sr
    t_tb
    t_te
    t_ti
    t_tp
    t_ts
    t_u7
    t_ue
    t_us
    t_ut
    t_vb
    t_ve
    t_vi
    t_vs
    t_xn
    t_xs
END

export const option_terminal: string = option_terminal_list->join()

# option_terminal_special {{{1

const option_terminal_special_list: list<string> =<< trim END
    t_#2
    t_#4
    t_%1
    t_%i
    t_&8
    t_*7
    t_@7
    t_k;
END

export const option_terminal_special: string = option_terminal_special_list->join("\\|")

# option_valid {{{1

export const option_valid: string = '\%([a-z]\{2,}\>\|t_[a-zA-Z0-9#%*:@_]\{2}\)'

# pattern_delimiter {{{1

export const pattern_delimiter: string = '[^-+*/%.:# \t[:alnum:]\"|]\@=.\|->\@!\%(=\s\)\@!\|[+*/%]\%(=\s\)\@!'

# wincmd_valid {{{1

export const wincmd_valid: string = '/\s\@1<=\%([-\]+:<=>FHJKLPRSTW^_bcdfhijklnopqrstvwxz}|]\|gF\|gT\|g]\|gf\|gt\|g}\)\_s\@=/'
