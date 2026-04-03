<script lang="ts">
  import { onMount, onDestroy } from 'svelte'
  import { localeStore } from '$lib/stores/localeStore.svelte'
  import { fetchApi } from '$lib/utils/api'
  import { Editor } from '@tiptap/core'
  import StarterKit from '@tiptap/starter-kit'

  let { fromAddress, onclose, onsent }: {
    fromAddress: string
    onclose: () => void
    onsent: () => void
  } = $props()

  let toAddress = $state('')
  let subject = $state('')
  let sending = $state(false)
  let error = $state('')
  let editor = $state<Editor | null>(null)
  let editorElement: HTMLDivElement | undefined = $state()
  let isBold = $state(false)
  let isItalic = $state(false)
  let isStrike = $state(false)
  let isBulletList = $state(false)
  let isOrderedList = $state(false)
  let isHeading = $state(false)

  function updateToolbarState() {
    if (!editor) return
    isBold = editor.isActive('bold')
    isItalic = editor.isActive('italic')
    isStrike = editor.isActive('strike')
    isBulletList = editor.isActive('bulletList')
    isOrderedList = editor.isActive('orderedList')
    isHeading = editor.isActive('heading', { level: 3 })
  }

  function createEditor() {
    if (!editorElement) return
    editor = new Editor({
      element: editorElement,
      extensions: [
        StarterKit.configure({
          heading: { levels: [3] },
        }),
      ],
      content: '',
      editorProps: {
        attributes: {
          class: 'compose-tiptap-content lscrollbar',
        },
      },
      onUpdate: () => updateToolbarState(),
      onSelectionUpdate: () => updateToolbarState(),
      onTransaction: () => updateToolbarState(),
    })
  }

  function destroyEditor() {
    if (editor) {
      editor.destroy()
      editor = null
    }
  }

  async function handleSend() {
    error = ''
    const to = toAddress.trim()

    if (!to) {
      error = localeStore.t('email_to') + ' is required'
      return
    }

    if (!to.includes('@')) {
      error = localeStore.t('email_setup_invalid_username')
      return
    }

    sending = true

    const body = editor?.getHTML() || ''

    const result = await fetchApi<{ success?: boolean; bounced?: boolean; error?: string }>(
      'emailSend',
      { method: 'POST', body: JSON.stringify({ fromAddress, toAddress: to, subject, body }) },
      { success: true }
    )

    sending = false

    if (!result || result.error) {
      if (result?.error === 'rate_limited') {
        error = localeStore.t('email_rate_limited')
      } else {
        error = result?.error || 'Failed to send'
      }
      return
    }

    onsent()
  }

  function toggleBold() { editor?.chain().focus().toggleBold().run() }
  function toggleItalic() { editor?.chain().focus().toggleItalic().run() }
  function toggleStrike() { editor?.chain().focus().toggleStrike().run() }
  function toggleBulletList() { editor?.chain().focus().toggleBulletList().run() }
  function toggleOrderedList() { editor?.chain().focus().toggleOrderedList().run() }
  function toggleHeading() { editor?.chain().focus().toggleHeading({ level: 3 }).run() }

  onMount(() => {
    createEditor()
  })

  onDestroy(() => {
    destroyEditor()
  })
</script>

<div class="absolute inset-0 bg-black/50 flex items-center justify-center z-50 p-5">
  <div class="w-full max-w-[520px] max-h-full bg-[#16171C] border border-[#2D2F3A] rounded-2xl flex flex-col overflow-hidden">
    <div class="flex items-center justify-between px-4 py-3 border-b border-[#2D2F3A] shrink-0">
      <span class="text-[#F0F0F5] text-sm font-bold">{localeStore.t('email_compose')}</span>
      <!-- svelte-ignore a11y_consider_explicit_label -->
      <button type="button" class="w-7 h-7 flex items-center justify-center bg-none border-none text-[#8B8D9A] cursor-pointer rounded-md transition-colors duration-150 hover:text-[#F0F0F5] hover:bg-[#252730]" onclick={onclose}>
        <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M18 6 6 18"/><path d="m6 6 12 12"/></svg>
      </button>
    </div>

    <div class="flex flex-col shrink-0">
      <div class="flex items-center gap-2 py-2 px-4 border-b border-[#1E2028]">
        <span class="text-[#50525E] text-xs font-medium shrink-0 min-w-[55px]">{localeStore.t('email_from')}:</span>
        <span class="text-[#8B8D9A] text-xs font-medium">{fromAddress}</span>
      </div>
      <div class="flex items-center gap-2 py-2 px-4 border-b border-[#1E2028]">
        <span class="text-[#50525E] text-xs font-medium shrink-0 min-w-[55px]">{localeStore.t('email_to')}:</span>
        <input
          type="text"
          class="flex-1 bg-transparent border-none text-[#F0F0F5] text-xs outline-none font-inherit p-0 min-w-0 placeholder:text-[#3E404B]"
          placeholder="user@mail.com"
          bind:value={toAddress}
        />
      </div>
      <div class="flex items-center gap-2 py-2 px-4 border-b border-[#1E2028]">
        <span class="text-[#50525E] text-xs font-medium shrink-0 min-w-[55px]">{localeStore.t('email_subject')}:</span>
        <input
          type="text"
          class="flex-1 bg-transparent border-none text-[#F0F0F5] text-xs outline-none font-inherit p-0 min-w-0 placeholder:text-[#3E404B]"
          placeholder={localeStore.t('email_subject_placeholder')}
          bind:value={subject}
          maxlength={500}
        />
      </div>
    </div>

    <div class="flex items-center gap-[2px] shrink-0 py-1 px-3 border-b border-[#1E2028]">
      <!-- svelte-ignore a11y_consider_explicit_label -->
      <button type="button" class="w-7 h-7 flex items-center justify-center bg-none border-none rounded-md cursor-pointer transition-colors duration-150 hover:text-[#F0F0F5] hover:bg-[#252730] {isHeading ? 'text-[#F0F0F5] !bg-[#2D2F3A]' : 'text-[#8B8D9A]'}" onclick={toggleHeading} title={localeStore.t('toolbar_heading')}>
        <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M4 12h8"/><path d="M4 18V6"/><path d="M12 18V6"/><path d="m17 12 3-2v8"/></svg>
      </button>
      <div class="w-px h-[18px] bg-[#2D2F3A] mx-1 shrink-0"></div>
      <!-- svelte-ignore a11y_consider_explicit_label -->
      <button type="button" class="w-7 h-7 flex items-center justify-center bg-none border-none rounded-md cursor-pointer transition-colors duration-150 hover:text-[#F0F0F5] hover:bg-[#252730] {isBold ? 'text-[#F0F0F5] !bg-[#2D2F3A]' : 'text-[#8B8D9A]'}" onclick={toggleBold} title={localeStore.t('toolbar_bold')}>
        <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><path d="M6 12h9a4 4 0 0 1 0 8H7a1 1 0 0 1-1-1V5a1 1 0 0 1 1-1h7a4 4 0 0 1 0 8"/></svg>
      </button>
      <!-- svelte-ignore a11y_consider_explicit_label -->
      <button type="button" class="w-7 h-7 flex items-center justify-center bg-none border-none rounded-md cursor-pointer transition-colors duration-150 hover:text-[#F0F0F5] hover:bg-[#252730] {isItalic ? 'text-[#F0F0F5] !bg-[#2D2F3A]' : 'text-[#8B8D9A]'}" onclick={toggleItalic} title={localeStore.t('toolbar_italic')}>
        <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="19" x2="10" y1="4" y2="4"/><line x1="14" x2="5" y1="20" y2="20"/><line x1="15" x2="9" y1="4" y2="20"/></svg>
      </button>
      <!-- svelte-ignore a11y_consider_explicit_label -->
      <button type="button" class="w-7 h-7 flex items-center justify-center bg-none border-none rounded-md cursor-pointer transition-colors duration-150 hover:text-[#F0F0F5] hover:bg-[#252730] {isStrike ? 'text-[#F0F0F5] !bg-[#2D2F3A]' : 'text-[#8B8D9A]'}" onclick={toggleStrike} title={localeStore.t('toolbar_strikethrough')}>
        <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M16 4H9a3 3 0 0 0-2.83 4"/><path d="M14 12a4 4 0 0 1 0 8H6"/><line x1="4" x2="20" y1="12" y2="12"/></svg>
      </button>
      <div class="w-px h-[18px] bg-[#2D2F3A] mx-1 shrink-0"></div>
      <!-- svelte-ignore a11y_consider_explicit_label -->
      <button type="button" class="w-7 h-7 flex items-center justify-center bg-none border-none rounded-md cursor-pointer transition-colors duration-150 hover:text-[#F0F0F5] hover:bg-[#252730] {isBulletList ? 'text-[#F0F0F5] !bg-[#2D2F3A]' : 'text-[#8B8D9A]'}" onclick={toggleBulletList} title={localeStore.t('toolbar_bullet_list')}>
        <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="8" x2="21" y1="6" y2="6"/><line x1="8" x2="21" y1="12" y2="12"/><line x1="8" x2="21" y1="18" y2="18"/><line x1="3" x2="3.01" y1="6" y2="6"/><line x1="3" x2="3.01" y1="12" y2="12"/><line x1="3" x2="3.01" y1="18" y2="18"/></svg>
      </button>
      <!-- svelte-ignore a11y_consider_explicit_label -->
      <button type="button" class="w-7 h-7 flex items-center justify-center bg-none border-none rounded-md cursor-pointer transition-colors duration-150 hover:text-[#F0F0F5] hover:bg-[#252730] {isOrderedList ? 'text-[#F0F0F5] !bg-[#2D2F3A]' : 'text-[#8B8D9A]'}" onclick={toggleOrderedList} title={localeStore.t('toolbar_numbered_list')}>
        <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="10" x2="21" y1="6" y2="6"/><line x1="10" x2="21" y1="12" y2="12"/><line x1="10" x2="21" y1="18" y2="18"/><path d="M4 6h1v4"/><path d="M4 10h2"/><path d="M6 18H4c0-1 2-2 2-3s-1-1.5-2-1"/></svg>
      </button>
    </div>

    <div class="compose-editor-wrap flex-1 min-h-[120px] max-h-[260px] flex flex-col overflow-hidden">
      <div bind:this={editorElement} class="compose-tiptap-container"></div>
    </div>

    {#if error}
      <p class="text-[#E55B5B] text-xs m-0 pt-[6px] px-4 pb-0 shrink-0">{error}</p>
    {/if}

    <div class="flex items-center gap-2 px-4 py-3 border-t border-[#2D2F3A] shrink-0">
      <!-- svelte-ignore a11y_consider_explicit_label -->
      <button type="button" class="py-2 px-5 bg-[#7C8AED] text-white border-none rounded-lg text-xs font-semibold font-inherit cursor-pointer transition-colors duration-150 hover:bg-[#6B79DC] disabled:opacity-50 disabled:cursor-not-allowed" onclick={handleSend} disabled={sending}>
        {sending ? localeStore.t('email_sending') : localeStore.t('email_send')}
      </button>
      <!-- svelte-ignore a11y_consider_explicit_label -->
      <button type="button" class="py-2 px-4 bg-none border border-[#2D2F3A] rounded-lg text-[#8B8D9A] text-xs font-medium font-inherit cursor-pointer transition-colors duration-150 hover:text-[#C8C9CF] hover:border-[#3A3D4A]" onclick={onclose}>
        {localeStore.t('email_cancel')}
      </button>
    </div>
  </div>
</div>

<style>
  .compose-editor-wrap :global(.compose-tiptap-container) {
    flex: 1;
    display: flex;
    flex-direction: column;
    min-height: 0;
  }
  .compose-editor-wrap :global(.tiptap) {
    flex: 1;
    color: #C8C9CF;
    font-size: 13px;
    line-height: 1.65;
    padding: 10px 16px;
    outline: none;
    font-family: 'Gilroy', Inter, sans-serif;
    overflow-y: auto;
    min-height: 0;
    user-select: text;
  }
  .compose-editor-wrap :global(.tiptap p) {
    margin: 0 0 4px;
  }
  .compose-editor-wrap :global(.tiptap h3) {
    color: #F0F0F5;
    font-size: 15px;
    font-weight: 700;
    margin: 0 0 6px;
  }
  .compose-editor-wrap :global(.tiptap ul),
  .compose-editor-wrap :global(.tiptap ol) {
    padding-left: 20px;
    margin: 0 0 4px;
  }
  .compose-editor-wrap :global(.tiptap li) {
    margin: 0 0 2px;
  }
  .compose-editor-wrap :global(.tiptap li p) {
    margin: 0;
  }
  .compose-editor-wrap :global(.tiptap p.is-editor-empty:first-child::before) {
    content: 'Write your message...';
    float: left;
    color: #3E404B;
    pointer-events: none;
    height: 0;
  }
</style>
