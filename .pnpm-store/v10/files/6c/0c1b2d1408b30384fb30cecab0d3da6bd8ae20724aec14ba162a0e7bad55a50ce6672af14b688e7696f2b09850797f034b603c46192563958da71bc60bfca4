'use strict';

// packages/themes/src/tailwindcss/genesis/index.ts
var genesis_default = {
  // Global styles apply to _all_ inputs with matching section keys
  global: {
    fieldset: "max-w-md border border-gray-400 rounded px-2 pb-1",
    help: "text-xs text-gray-500",
    inner: "formkit-disabled:bg-gray-200 formkit-disabled:cursor-not-allowed formkit-disabled:pointer-events-none",
    input: "appearance-none bg-transparent focus:outline-none focus:ring-0 focus:shadow-none",
    label: "block mb-1 font-bold text-sm",
    legend: "font-bold text-sm",
    loaderIcon: "inline-flex items-center w-4 text-gray-600 animate-spin",
    message: "text-red-500 mb-1 text-xs",
    messages: "list-none p-0 mt-1 mb-0",
    outer: "mb-4 formkit-disabled:opacity-50",
    prefixIcon: "w-10 flex self-stretch grow-0 shrink-0 rounded-tl rounded-bl border-r border-gray-400 bg-white bg-gradient-to-b from-transparent to-gray-200 [&>svg]:w-full [&>svg]:max-w-[1em] [&>svg]:max-h-[1em] [&>svg]:m-auto",
    suffixIcon: "w-7 pr-3 p-3 flex self-stretch grow-0 shrink-0 [&>svg]:w-full [&>svg]:max-w-[1em] [&>svg]:max-h-[1em] [&>svg]:m-auto"
  },
  // Family styles apply to all inputs that share a common family
  "family:box": {
    decorator: "block relative h-5 w-5 mr-2 rounded bg-white bg-gradient-to-b from-transparent to-gray-200 ring-1 ring-gray-400 peer-checked:ring-blue-500 text-transparent peer-checked:text-blue-500",
    decoratorIcon: "flex p-[3px] w-full h-full absolute top-1/2 left-1/2 -translate-y-1/2 -translate-x-1/2",
    help: "mb-2 mt-1.5",
    input: "absolute w-0 h-0 overflow-hidden opacity-0 pointer-events-none peer",
    inner: "$remove:formkit-disabled:bg-gray-200",
    label: "$reset text-sm text-gray-700 mt-1 select-none",
    wrapper: "flex items-center mb-1"
  },
  "family:button": {
    input: "$reset inline-flex items-center bg-blue-600 text-white text-sm font-normal py-3 px-6 rounded focus-visible:outline-2 focus-visible:outline-blue-600 focus-visible:outline-offset-2 formkit-disabled:bg-gray-400 formkit-loading:before:w-4 formkit-loading:before:h-4 formkit-loading:before:mr-2 formkit-loading:before:border formkit-loading:before:border-2 formkit-loading:before:border-r-transparent formkit-loading:before:rounded-3xl formkit-loading:before:border-white formkit-loading:before:animate-spin",
    wrapper: "mb-1",
    prefixIcon: "$reset block w-4 mr-2 stretch",
    suffixIcon: "$reset block w-4 ml-2 stretch"
  },
  "family:dropdown": {
    dropdownWrapper: "my-2 w-full shadow-lg rounded [&::-webkit-scrollbar]:hidden",
    emptyMessageInner: "flex items-center justify-center text-sm p-2 text-center w-full text-gray-500 [&>span]:mr-3 [&>span]:ml-0",
    inner: "max-w-md relative flex ring-1 ring-gray-400 focus-within:ring-blue-500 focus-within:ring-2 rounded mb-2 formkit-disabled:focus-within:ring-gray-400 formkit-disabled:focus-within:ring-1 [&>span:first-child]:focus-within:text-blue-500",
    input: "w-full px-3 py-2",
    listbox: "bg-white shadow-lg rounded overflow-hidden",
    listboxButton: "flex w-12 self-stretch justify-center mx-auto",
    listitem: 'pl-7 relative hover:bg-gray-300 data-[is-active="true"]:bg-gray-300 aria-selected:bg-blue-600 aria-selected:text-white data-[is-active="true"]:aria-selected:bg-blue-600 data-[is-active="true"]:aria-selected:bg-blue-700',
    loaderIcon: "ml-auto",
    loadMoreInner: "flex items-center justify-center text-sm p-2 text-center w-full text-blue-500 formkit-loading:text-gray-500 cursor-pointer [&>span]:mr-3 [&>span]:ml-0",
    option: "p-2.5",
    optionLoading: "pl-2.5 text-gray-400",
    placeholder: "p-2.5 text-gray-400",
    selector: "flex w-full justify-between items-center min-h-[2.625em] [&u] cursor-default",
    selection: "flex w-full",
    selectedIcon: "block absolute top-1/2 left-2 w-3 -translate-y-1/2",
    selectIcon: "flex box-content w-4 px-2 self-stretch grow-0 shrink-0 [&>svg]:w-[1em] cursor-pointer"
  },
  "family:text": {
    inner: "flex items-center max-w-md ring-1 ring-gray-400 focus-within:ring-blue-500 focus-within:ring-2 [&>label:first-child]:focus-within:text-blue-500 rounded mb-1",
    input: "w-full px-3 py-2 border-none text-base text-gray-700 placeholder-gray-400"
  },
  "family:date": {
    inner: "flex items-center max-w-md ring-1 ring-gray-400 focus-within:ring-blue-500 focus-within:ring-2 [&>label:first-child]:focus-within:text-blue-500 rounded mb-1",
    input: "w-full px-3 py-2 border-none text-gray-700 placeholder-gray-400"
  },
  // Specific styles apply only to a given input type
  color: {
    inner: "flex max-w-[5.5em] w-full formkit-prefix-icon:max-w-[7.5em] formkit-suffix-icon:formkit-prefix-icon:max-w-[10em]",
    input: "$reset appearance-none w-full cursor-pointer border-none rounded p-0 m-0 bg-transparent [&::-webkit-color-swatch-wrapper]:p-0 [&::-webkit-color-swatch]:border-none",
    suffixIcon: "min-w-[2.5em] pr-0 pl-0 m-auto"
  },
  file: {
    fileItem: "flex items-center text-gray-800 mb-1 last:mb-0",
    fileItemIcon: "w-4 mr-2 shrink-0",
    fileList: 'shrink grow peer px-3 py-2 formkit-multiple:data-[has-multiple="true"]:mb-6',
    fileName: "break-all grow text-ellipsis",
    fileRemove: "relative z-[2] ml-auto text-[0px] hover:text-red-500 pl-2 peer-data-[has-multiple=true]:text-sm peer-data-[has-multiple=true]:text-blue-500 peer-data-[has-multiple=true]:ml-3 peer-data-[has-multiple=true]:mb-2 formkit-multiple:bottom-[0.15em] formkit-multiple:pl-0 formkit-multiple:ml-0 formkit-multiple:left-[1em] formkit-multiple:formkit-prefix-icon:left-[3.75em]",
    fileRemoveIcon: "block text-base w-3 relative z-[2]",
    inner: "relative max-w-md cursor-pointer formkit-multiple:[&>button]:absolute",
    input: "cursor-pointer text-transparent absolute top-0 right-0 left-0 bottom-0 opacity-0 z-[2]",
    noFiles: "flex w-full items-center px-3 py-2 text-gray-400",
    noFilesIcon: "w-4 mr-2"
  },
  radio: {
    decorator: "rounded-full",
    decoratorIcon: "w-5 p-[5px]"
  },
  range: {
    inner: "$reset flex items-center max-w-md",
    input: "$reset w-full mb-1 h-2 p-0 rounded-full",
    prefixIcon: "$reset w-4 mr-1 flex self-stretch grow-0 shrink-0 [&>svg]:max-w-[1em] [&>svg]:max-h-[1em] [&>svg]:m-auto",
    suffixIcon: "$reset w-4 ml-1 flex self-stretch grow-0 shrink-0 [&>svg]:max-w-[1em] [&>svg]:max-h-[1em] [&>svg]:m-auto"
  },
  select: {
    inner: "flex relative max-w-md items-center rounded mb-1 ring-1 ring-gray-400 focus-within:ring-blue-500 focus-within:ring-2 [&>span:first-child]:focus-within:text-blue-500",
    input: 'w-full pl-3 pr-8 py-2 border-none text-base text-gray-700 placeholder-gray-400 formkit-multiple:p-0 data-[placeholder="true"]:text-gray-400 formkit-multiple:data-[placeholder="true"]:text-inherit',
    selectIcon: "flex p-[3px] shrink-0 w-5 mr-2 -ml-[1.5em] h-full pointer-events-none [&>svg]:w-[1em]",
    option: "formkit-multiple:p-3 formkit-multiple:text-sm text-gray-700"
  },
  textarea: {
    inner: "flex max-w-md rounded mb-1 ring-1 ring-gray-400 focus-within:ring-blue-500 [&>label:first-child]:focus-within:text-blue-500",
    input: "block w-full h-32 px-3 py-3 border-none text-base text-gray-700 placeholder-gray-400 focus:shadow-outline"
  },
  // PRO input styles
  autocomplete: {
    closeIcon: "block grow-0 shrink-0 w-3 mr-3.5",
    inner: "relative",
    option: "grow text-ellipsis",
    selectionWrapper: `
      absolute left-0 top-0 right-0 bottom-0 flex rounded bg-gray-100
      formkit-multiple:static formkit-multiple:mt-0 formkit-multiple:mb-2 formkit-multiple:max-w-md
    `
  },
  colorpicker: {
    outer: `
      group
      formkit-disabled:cursor-not-allowed
    `,
    help: `
      group-[[data-inline]]:-mt-1 
      group-[[data-inline]]:mb-2
    `,
    inner: `
      relative
      inline-flex
      group-[[data-inline]]:shadow-none
      group-[[data-inline]]:!ring-1
      group-[[data-inline]]:!ring-gray-400
    `,
    swatchPreview: `
      w-full
      flex
      justify-start
      items-center
      p-3
      rounded-md
      text-sm
      cursor-pointer
      outline-none
    `,
    canvasSwatchPreviewWrapper: `
      relative
      before:content-['']
      before:absolute
      before:top-0
      before:left-0
      before:w-full
      before:h-full
      before:rounded-sm
      before:shadow-[inset_0_0_0_1px_rgba(0,0,0,0.2)]
      before:z-[2]
    `,
    canvasSwatchPreview: `
      rounded
      aspect-[2/1]
      w-10
    `,
    valueString: `
      inline-block
      ml-2
      mr-1
    `,
    panel: `
      flex
      flex-col
      max-w-[300px]
      p-2
      rounded
      bg-white
      touch-manipulation
      absolute
      w-[100vw]
      top-full
      left-0
      border
      shadow-xl
      z-10
      group-[[data-inline]]:static
      group-[[data-inline]]:w-auto
      group-[[data-inline]]:shadow-none
      group-[[data-inline]]:z-auto
      [@media(max-width:431px)_and_(hover:none)]:group-[&:not([data-inline])]:!fixed
      [@media(max-width:431px)_and_(hover:none)]:group-[&:not([data-inline])]:top-auto
      [@media(max-width:431px)_and_(hover:none)]:group-[&:not([data-inline])]:max-w-none
      [@media(max-width:431px)_and_(hover:none)]:group-[&:not([data-inline])]:bottom-0
      [@media(max-width:431px)_and_(hover:none)]:group-[&:not([data-inline])]:left-0
      [@media(max-width:431px)_and_(hover:none)]:group-[&:not([data-inline])]:rounded-none
    `,
    panelClose: `
      flex
      justify-end
      items-center
      mb-1
      -mt-1
      border-none
      bg-none
      border-b
      w-[calc(100%+1rem)]
      -ml-2
      pt-0
      pr-2
      pb-1
      pl-2
    `,
    closeIcon: `
      w-[2rem]
      aspect-square
      p-1
      rounded-full
      border
      [&>svg]:w-full
      [&>svg]:aspect-square
      [&>svg]:max-w-none
      [&>svg]:max-h-none
    `,
    controlGroup: `
      grid
      [grid-template-areas:'a_a_a'_'b_c_e'_'b_d_e']
      mb-2
    `,
    canvas: `
      block
      w-full
    `,
    canvasLS: `
      aspect-[2/1]
      cursor-pointer
      rounded-sm
    `,
    LS: `
      [grid-area:a]
      relative
      mb-2
    `,
    preview: `
      [grid-area:b]
      w-8
      inline-flex
      relative
      rounded
      overflow-hidden
      aspect-square
      rounded-sm
      after:content-['']
      after:absolute
      after:top-0
      after:left-0
      after:w-full
      after:h-full
      after:rounded-sm
      after:shadow-[inset_0_0_0_1px_rgba(0,0,0,0.2)]
    `,
    hue: `
      [grid-area:c]
      relative
      inline-flex
      h-3/4
      ml-2
    `,
    alpha: `
      [grid-area:d]
      relative
      inline-flex
      h-3/4
      ml-2
    `,
    eyeDropper: `
      [grid-area:e]
      p-1.5
      ml-2
      inline-flex
      self-center
      justify-self-center
      aspect-square
      rounded-sm
      border
      cursor-pointer
      content-center
      items-center
    `,
    eyeDropperIcon: `
      w-auto
      [&>svg]:w-5
    `,
    control: `
      absolute
      bg-white
      shadow-[0_0_0_2px_rgba(255,255,255,1),0_0_0_3px_rgba(0,0,0,0.2)]
      -translate-x-1/2
      -translate-y-1/2
      pointer-events-none
      data-[prevent-focus-style]:shadow-[0_0_0_2px_rgba(255,255,255,1),0_0_0_3px_rgba(0,0,0,0.2)]
      focus-visible:outline-none
      focus-visible:shadow-[0_0_0_2px_rgba(255,255,255,1),0_0_0_3px_rgba(0,0,0,0.2),0_0_0_4px_rgba(59,130,246,1),0_0_0_5px_rgba(0,0,0,1)]
    `,
    controlLS: `
      w-[10px]
      h-[10px]
      rounded-full
    `,
    controlHue: `
      w-[4px]
      h-[calc(100%-2px)]
      top-1/2
      rounded-[1px]
    `,
    controlAlpha: `
      w-[4px]
      h-[calc(100%-2px)]
      top-1/2
      rounded-[1px]
    `,
    formatField: `
      flex
      items-center
      justify-center
      grow
    `,
    colorInputGroup: `
      flex
      items-center
      justify-center
      grow
    `,
    fieldGroup: `
      flex
      flex-col
      items-center
      justify-center
      w-full
      mr-1
      [&>input]:p-1
      [&>input]:text-sm
      [&>input]:m-0
      [&>input]:grow
      [&>input]:shrink
      [&>input]:w-full
      [&>input]:border
      [&>input]:rounded-sm
      [&>input]:text-center
      [&>input]:appearance-none
      [&>input::-webkit-outer-spin-button]:appearance-none 
      [&>input::-webkit-inner-spin-button]:appearance-none
      [&>input::-webkit-inner-spin-button]:m-0
      [&>input:focus]:outline-none
      [&>input:focus]:ring
      [&>input:focus]:ring-blue-500
      max-[431px]:[&>input]:text-base
    `,
    fieldLabel: `
      text-xs
      mt-1
      opacity-50
    `,
    formatSwitcher: `
      flex
      justify-end
      self-start
      mt-1
      uppercase
      shrink-0
      p-1
      rounded-sm
      select-none
    `,
    switchIcon: `
      [&>svg]:w-3
    `,
    swatches: `
      flex
      flex-wrap
      w[calc(100%+0.5rem)]
      -ml-1
      pt-2
      pb-2
      mt-2
      -mb-2
      border-t
      overflow-auto
      max-h-[200px]
      select-none
      first:-mt-2
      first:border-t-0
    `,
    swatchGroup: `
      flex
      flex-wrap
      w-full
      mb-2
      last:mb-0
    `,
    swatchGroupLabel: `
      block
      w-full
      text-sm
      opacity-50
    `,
    swatch: `
      relative
      w-full
      max-w-[calc((100%/10)-0.5rem)]
      aspect-square
      m-1
      cursor-pointer
      before:content-['']
      before:absolute
      before:top-0
      before:left-0
      before:w-full
      before:h-full
      before:rounded-sm
      before:shadow-[inset_0_0_0_1px_rgba(0,0,0,0.2)]
      before:pointer-events-none
      before:z-[2]
      data-[active='true']:after:content-['']
      data-[active='true']:after:block
      data-[active='true']:after:absolute
      data-[active='true']:after:w-1.5
      data-[active='true']:after:h-1.5
      data-[active='true']:after:top-1/2
      data-[active='true']:after:left-1/2
      data-[active='true']:after:pointer-events-none
      data-[active='true']:after:rounded-full
      data-[active='true']:after:-translate-x-1/2
      data-[active='true']:after:-translate-y-1/2
      data-[active='true']:after:bg-white
      data-[active='true']:after:z-[2]
      data-[active='true']:after:ring-1
      data-[active='true']:after:ring-[rgba(0,0,0,0.33)]
      [&>canvas]:block
      [&>canvas]:w-full
      [&>canvas]:aspect-square
      [&>canvas]:rounded-sm
      [&>canvas:focus-visible]:outline-none
      [&>canvas:focus-visible]:shadow-[0_0_0_2px_rgba(255,255,255,1),0_0_0_4px_rgba(59,130,246,1)]
    `
  },
  datepicker: {
    inner: "relative",
    panelWrapper: "absolute top-[calc(100%_+_0.5em)] shadow-[0_0_1.25em_rgba(0,0,0,.25)] rounded-md p-5 bg-white z-10",
    panelHeader: "grid grid-cols-[2.5em_1fr_2.5em] justify-center items-center border-b-2 mb-4 pb-4",
    input: "selection:bg-blue-400",
    monthsHeader: "flex items-center justify-center col-start-2 col-end-2",
    timeHeader: "flex items-center justify-center col-start-2 col-end-2",
    overlayPlaceholder: "text-gray-400",
    months: "flex flex-wrap",
    month: `
      flex items-center justify-center
      w-[calc(33%_-_1em)] m-2 p-2 rounded-md
      bg-gray-200
      aria-selected:bg-blue-500 aria-selected:text-white
      focus:outline focus:outline-2 focus:outline-blue-500 focus:outline-offset-2 focus:bg-white focus:text-black
      data-[is-extra=true]:opacity-25
      formkit-disabled:opacity-50 formkit-disabled:cursor-default formkit-disabled:pointer-events-none
    `,
    yearsHeader: "flex items-center justify-center col-start-2 col-end-2",
    years: "flex flex-wrap max-w-[35em]",
    year: `
      flex items-center justify-center
      w-[calc(20%_-_1em)] m-2 p-2 rounded-md
      bg-gray-200
      aria-selected:bg-blue-500 aria-selected:text-white
      focus:outline focus:outline-2 focus:outline-blue-500 focus:outline-offset-2 focus:bg-white focus:text-black
      data-[is-extra=true]:opacity-25
      formkit-disabled:opacity-50 formkit-disabled:cursor-default formkit-disabled:pointer-events-none
    `,
    weekDays: "flex",
    weekDay: "flex w-[2.25em] h-[1em] m-1 items-center justify-center rounded-md font-medium lowercase",
    week: "flex formkit-disabled:opacity-50 formkit-disabled:cursor-default formkit-disabled:pointer-events-none",
    dayCell: `
      flex items-center justify-center
      w-[2.25em] h-[2.25em] m-1 p-2 rounded-md
      bg-gray-200
      aria-selected:bg-blue-500 aria-selected:text-white
      focus:outline focus:outline-2 focus:outline-blue-500 focus:outline-offset-2 focus:bg-white focus:text-black
      data-[is-extra=true]:opacity-25
      formkit-disabled:opacity-50 formkit-disabled:cursor-default formkit-disabled:pointer-events-none
    `,
    timeInput: "w-full border-2 border-gray-300 rounded-md p-2 my-[2em] focus-visible:outline-blue-500",
    daysHeader: "flex items-center justify-center",
    prev: "mr-auto px-3 py-1 hover:bg-gray-100 hover:rounded-lg col-start-1 col-end-1",
    prevLabel: "hidden",
    prevIcon: "flex w-3 select-none [&>svg]:w-full",
    dayButton: "appearance-none cursor-pointer px-3 py-1 border-2 rounded-lg mx-1 hover:border-blue-500",
    monthButton: "appearance-none cursor-pointer px-3 py-1 border-2 rounded-lg mx-1 hover:border-blue-500",
    yearButton: "appearance-none cursor-pointer px-3 py-1 border-2 rounded-lg mx-1 hover:border-blue-500",
    next: "ml-auto px-3 py-1 hover:bg-gray-100 hover:rounded col-start-3 col-end-3",
    nextLabel: "hidden",
    nextIcon: "flex w-3 select-none [&>svg]:w-full",
    openButton: `
      appearance-none border-0 bg-transparent flex p-0 self-stretch cursor-pointer
      focus-visible:outline-none focus-visible:text-white focus-visible:bg-blue-500
    `,
    calendarIcon: "flex w-8 grow-0 shrink-0 self-stretch select-none [&>svg]:w-full [&>svg]:m-auto [&>svg]:max-h-[1em] [&>svg]:max-w-[1em]"
  },
  dropdown: {
    tagsWrapper: "max-w-[calc(100%_-_35px)]",
    tags: "flex items-center flex-wrap gap-1 mx-2 my-1.5",
    tag: "flex items-center rounded-full bg-gray-200 text-xs text-black py-1 px-2.5 cursor-default",
    tagLabel: "px-1",
    selectionsWrapper: "flex w-[calc(100%_-_35px)] overflow-hidden",
    selections: "inline-flex items-center px-2.5",
    selectionsItem: "whitespace-nowrap mr-1 last:mr-0",
    truncationCount: "flex items-center whitespace-nowrap justify-center rounded text-white bg-gray-500 font-bold text-xs px-1 py-0.5",
    removeSelection: "block w-2.5 my-1 cursor-pointer"
  },
  rating: {
    inner: "relative flex items-center w-[8em] formkit-disabled:bg-transparent",
    itemsWrapper: "w-full",
    onItems: "text-yellow-400",
    onItemWrapper: "[&>*]:w-full [&>svg]:h-auto [&>svg]:max-w-none [&>svg]:max-h-none",
    offItems: "text-gray-500",
    offItemWrapper: "[&>*]:w-full [&>svg]:h-auto [&>svg]:max-w-none [&>svg]:max-h-none"
  },
  repeater: {
    content: "grow p-3 flex flex-col align-center",
    controlLabel: "absolute opacity-0 pointer-events-none",
    controls: "flex flex-col items-center justify-center bg-gray-100 p-3",
    downControl: "hover:text-blue-500 disabled:hover:text-inherit disabled:opacity-25",
    fieldset: "py-4 px-5",
    help: "mb-2 mt-1.5",
    item: "flex w-full mb-1 rounded border border-gray-200",
    moveDownIcon: "block w-3 my-1",
    moveUpIcon: "block w-3 my-1",
    removeControl: "hover:text-blue-500 disabled:hover:text-inherit disabled:opacity-25",
    removeIcon: "block w-5 my-1",
    upControl: "hover:text-blue-500 disabled:hover:text-inherit disabled:opacity-25"
  },
  slider: {
    outer: "max-w-md",
    help: "mt-0 mb-1",
    sliderInner: 'flex items-center py-1 [&>.formkit-max-value]:mb-0 [&>.formkit-max-value]:ml-8 [&>.formkit-max-value]:shrink [&>.formkit-max-value]:grow-0 [&>.formkit-icon]:bg-none [&>.formkit-icon]:border-none [&>.formkit-icon]:p-0 [&>.formkit-icon]:w-4 [&>.formkit-prefix-icon]:mr-2 [&>.formkit-suffix-icon]:ml-2 [&[data-has-mark-labels="true"]_.formkit-track]:mb-4',
    track: "grow relative z-[3] py-1 user-select-none",
    trackWrapper: "px-[2px] rounded-full bg-gray-200",
    trackInner: "h-[6px] mx-[2px] relative",
    fill: "h-full rounded-full absolute top-0 mx-[-4px] bg-blue-500",
    marks: "absolute pointer-events-none left-0 right-0 top-0 bottom-0",
    mark: 'absolute top-1/2 w-[3px] h-[3px] rounded-full -translate-x-1/2 -translate-y-1/2 bg-gray-400 data-[active="true"]:bg-white',
    markLabel: "absolute top-[calc(100%+0.5em)] left-1/2 text-gray-400 text-[0.66em] -translate-x-1/2",
    handles: "m-0 p-0 list-none",
    handle: 'group w-4 h-4 rounded-full bg-white absolute top-1/2 left-0 z-[2] -translate-x-1/2 -translate-y-1/2 shadow-[inset_0_0_0_1px_rgba(0,0,0,0.1),0_1px_2px_0_rgba(0,0,0,0.8)] focus-visible:outline-0 focus-visible:ring-2 ring-blue-500 data-[is-target="true"]:z-[3]',
    tooltip: 'absolute bottom-full left-1/2 -translate-x-1/2 -translate-y-[4px] bg-blue-500 text-white py-1 px-2 text-xs leading-none whitespace-nowrap rounded-sm opacity-0 pointer-events-none transition-opacity after:content-[""] after:absolute after:top-full after:left-1/2 after:-translate-x-1/2 after:-translate-y-[1px] after:border-4 after:border-transparent after:border-t-blue-500 group-hover:opacity-100 group-focus-visible:opacity-100 group-data-[show-tooltip="true"]:opacity-100',
    linkedValues: "flex items-start justify-between",
    minValue: 'grow max-w-[45%] mb-0 relative [&_.formkit-inner::after]:content-[""] [&_.formkit-inner::after]:absolute [&_.formkit-inner::after]:left-[105%] [&_.formkit-inner::after]:-translate-y-1/2 [&_.formkit-inner::after]:w-[10%] [&_.formkit-inner::after]:h-[1px] [&_.formkit-inner::after]:bg-gray-500',
    maxValue: "grow max-w-[45%] mb-0 relative",
    chart: "relative z-[2] mb-2 flex justify-between items-center w-full aspect-[3/1]",
    chartBar: 'absolute bottom-0 h-full bg-gray-400 opacity-[.66] data-[active="false"]:opacity-[.25]'
  },
  taglist: {
    input: "px-1 py-1 w-[0%] grow",
    removeSelection: "w-2.5 mx-1 self-center text-black leading-none",
    tag: "flex items-center my-1 p-1 bg-gray-200 text-xs rounded-full",
    tagWrapper: "mr-1 focus:outline-none focus:text-white [&>div]:focus:bg-blue-500 [&>div>button]:focus:text-white",
    tagLabel: "pl-2 pr-1",
    tags: "flex items-center flex-wrap w-full py-1.5 px-2"
  },
  toggle: {
    altLabel: "block w-full mb-1 font-bold text-sm",
    inner: "$reset inline-block mr-2",
    input: "peer absolute opacity-0 pointer-events-none",
    innerLabel: "text-[10px] font-bold absolute left-full top-1/2 -translate-x-full -translate-y-1/2 px-1",
    thumb: "relative left-0 aspect-square rounded-full transition-all w-5 bg-gray-100",
    track: "p-0.5 min-w-[3em] relative rounded-full transition-all bg-gray-400 peer-checked:bg-blue-500 peer-checked:[&>div:last-child]:left-full peer-checked:[&>div:last-child]:-translate-x-full peer-checked:[&>div:first-child:not(:last-child)]:left-0 peer-checked:[&>div:first-child:not(:last-child)]:translate-x-0",
    valueLabel: "font-bold text-sm",
    wrapper: "flex flex-wrap items-center mb-1"
  },
  togglebuttons: {
    input: `
      !text-black !bg-white
      relative flex ring-1 ring-gray-400 text-center align-center justify-center transition-colors
      group-data-[vertical="true"]/options:w-full
      group-data-[vertical="true"]/options:rounded-none
      group-data-[vertical="false"]/options:rounded-none
      focus-visible:z-10
      disabled:filter-grayscale
      disabled:!bg-gray-200
      disabled:!text-gray-700
      disabled:opacity-50
      disabled:cursor-not-allowed
      formkit-disabled:opacity-100
      aria-pressed:!bg-blue-600
      aria-pressed:!text-white
    `,
    options: `
      group/options
      inline-flex
      data-[vertical="true"]:flex-col
    `,
    option: `
      group/option
      group-data-[vertical="true"]/options:[&>*]:first:rounded-tl
      group-data-[vertical="true"]/options:[&>*]:first:rounded-tr
      group-data-[vertical="true"]/options:[&>*]:last:rounded-bl
      group-data-[vertical="true"]/options:[&>*]:last:rounded-br
      group-data-[vertical="false"]/options:[&>*]:first:rounded-tl
      group-data-[vertical="false"]/options:[&>*]:first:rounded-bl
      group-data-[vertical="false"]/options:[&>*]:last:rounded-tr
      group-data-[vertical="false"]/options:[&>*]:last:rounded-br
    `
  },
  transferlist: {
    outer: `
      [&_.dnd-placeholder]:bg-blue-500 [&_.dnd-placeholder]:text-white
      [&_.dnd-placeholder_svg]:text-white
      [&_.dnd-children-hidden]:w-full [&_.dnd-children-hidden]:p-0 [&_.dnd-children-hidden]:flex [&_.dnd-children-hidden]:flex-col [&_.dnd-children-hidden]:border-none
      [&_.dnd-children-hidden_span]:hidden
      [&_.dnd-children-hidden_.formkit-transferlist-option]:hidden
      [&_.dnd-multiple-selections_span]:inline-block
      [&_.dnd-multiple-selections_.formkit-transferlist-option]:inline-block
    `,
    fieldset: "$reset max-w-2xl",
    wrapper: "flex max-h-[350px] flex-col sm:flex-row justify-between w-full max-w-none",
    help: "pb-2",
    transferlist: "sm:w-3/5 shadow-md flex flex-col min-h-[350px] max-h-[350px] border rounded overflow-hidden select-none bg-gray-50",
    transferlistHeader: "flex bg-gray-100 justify-between items-center border-b p-3",
    transferlistHeaderItemCount: "ml-auto text-sm",
    transferlistListItems: "list-none bg-gray-50 h-full sm:max-w-xs overflow-x-hidden overflow-y-auto",
    transferlistListItem: "pl-8 relative aria-selected:bg-blue-600 aria-selected:data-[is-active=true]:bg-blue-600 aria-selected:text-white aria-selected:data-[is-active=true]:text-white first:-mt-px first:border-t py-2 px-3 flex relative border-b bg-white data-[is-active=true]:text-blue-500 data-[is-active=true]:bg-gray-100 cursor-pointer group-data-[is-max=true]:cursor-not-allowed items-center",
    transferlistOption: "text-sm",
    transferControls: "flex sm:flex-col justify-center mx-auto my-2 sm:mx-2 sm:my-auto border rounded",
    transferlistButton: "text-sm disabled:cursor-not-allowed disabled:bg-gray-200 disabled:opacity-50 first:rounded-l last:rounded-r sm:first:rounded-t sm:last:rounded-b appearance-none p-2 m-0 cursor-pointer h-10 border-none rounded-none bg-gray-50 hover:outline disabled:hover:outline-none hover:outline-1 hover:outline-black hover:text-blue-500 disabled:hover:text-current hover:z-10",
    sourceEmptyMessage: "appearance-none border-none w-full p-0 m-0 text-center text-gray-500 italic",
    sourceListItems: "group-data-[is-max=true]:opacity-50",
    targetEmptyMessage: "appearance-none border-none w-full p-0 m-0 text-center text-gray-500 italic",
    emptyMessageInner: "flex items-center justify-center p-2 text-sm",
    transferlistControls: "bg-white px-3 py-2 border-b",
    transferlistSearch: "flex border rounded items-center",
    transferlistSearchInput: "border-none p-1 w-full bg-transparent outline-none text-sm",
    controlLabel: "hidden",
    selectedIcon: "w-3 absolute left-3 select-none",
    fastForwardIcon: "w-10 flex select-none [&>svg]:m-auto [&>svg]:w-full [&>svg]:max-w-[1rem] [&>svg]:max-h-[1rem] rotate-90 sm:rotate-0",
    moveRightIcon: "w-10 flex select-none [&>svg]:m-auto [&>svg]:w-full [&>svg]:max-w-[1rem] [&>svg]:max-h-[1rem] rotate-90 sm:rotate-0",
    moveLeftIcon: "w-10 flex select-none [&>svg]:m-auto [&>svg]:w-full [&>svg]:max-w-[1rem] [&>svg]:max-h-[1rem] rotate-90 sm:rotate-0",
    rewindIcon: "w-10 flex select-none [&>svg]:m-auto [&>svg]:w-full [&>svg]:max-w-[1rem] [&>svg]:max-h-[1rem] rotate-90 sm:rotate-0"
  }
};

module.exports = genesis_default;
//# sourceMappingURL=out.js.map
//# sourceMappingURL=index.cjs.map