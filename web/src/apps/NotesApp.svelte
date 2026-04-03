<script lang="ts">
  import { onMount, onDestroy } from 'svelte'
  import { localeStore } from '$lib/stores/localeStore.svelte'
  import { developmentStore } from '$lib/stores/developmentStore.svelte'
  import { fetchApi } from '$lib/utils/api'
  import { Editor } from '@tiptap/core'
  import StarterKit from '@tiptap/starter-kit'

  let { appReady, changeWindowTitle, metadata }: {
    appReady: () => void
    changeWindowTitle: (newTitle: string) => void
    metadata?: Record<string, any>
  } = $props()

  interface Note {
    id: number
    title: string
    content: string
    color: string
    pinned: boolean
    created_at: string
    updated_at: string
  }

  const COLORS = ['#FFE56D', '#FF6B6B', '#5BBD6B', '#7C8AED', '#B56BFF', '#8B8D9A']

  const MOCK_NOTES: Note[] = [
    { id: 1, title: 'Shopping List', content: '<ul><li>Milk, eggs, bread</li><li>Butter, cheese</li><li><strong>Don\'t forget</strong> the orange juice!</li></ul>', color: '#FFE56D', pinned: true, created_at: '2024-01-15T10:30:00', updated_at: '2024-01-15T12:00:00' },
    { id: 2, title: 'Meeting Notes', content: '<p>Discuss <strong>project timeline</strong></p><ol><li>Review budget allocations</li><li>Assign new tasks to team</li><li>Follow-up next week</li></ol>', color: '#7C8AED', pinned: true, created_at: '2024-01-14T09:00:00', updated_at: '2024-01-14T11:30:00' },
    { id: 3, title: 'Ideas', content: '<p>New app concept: <em>habit tracker</em> with social features</p><p>Research competitor apps</p>', color: '#5BBD6B', pinned: false, created_at: '2024-01-13T14:00:00', updated_at: '2024-01-13T14:00:00' },
    { id: 4, title: 'Reminder', content: '<p>Call the mechanic about the <s>Tuesday</s> <strong>Friday</strong> car service appointment</p>', color: '#FF6B6B', pinned: false, created_at: '2024-01-12T08:00:00', updated_at: '2024-01-12T08:00:00' },
  ]

  let nextMockId = 100

  let notes = $state<Note[]>([])
  let selectedNoteId = $state<number | null>(null)
  let searchQuery = $state('')
  let isLoading = $state(true)
  let deleteConfirmId = $state<number | null>(null)
  let saveTimeout: ReturnType<typeof setTimeout> | null = null
  let editor = $state<Editor | null>(null)
  let editorElement: HTMLDivElement | undefined = $state()
  let editorNoteId: number | null = null
  let isBold = $state(false)
  let isItalic = $state(false)
  let isStrike = $state(false)
  let isBulletList = $state(false)
  let isOrderedList = $state(false)
  let isHeading = $state(false)

  let filteredNotes = $derived.by(() => {
    if (!searchQuery.trim()) return notes
    const q = searchQuery.toLowerCase()
    return notes.filter(n =>
      n.title.toLowerCase().includes(q) || stripHtml(n.content).toLowerCase().includes(q)
    )
  })

  let selectedNote = $derived.by(() => {
    if (selectedNoteId === null) return null
    return notes.find(n => n.id === selectedNoteId) || null
  })

  function stripHtml(html: string): string {
    if (!html) return ''
    return html.replace(/<[^>]*>/g, ' ').replace(/\s+/g, ' ').trim()
  }

  function formatDate(dateStr: string): string {
    try {
      const d = new Date(dateStr)
      const now = new Date()
      const isToday = d.toDateString() === now.toDateString()
      if (isToday) {
        return d.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
      }
      return d.toLocaleDateString([], { month: 'short', day: 'numeric' })
    } catch {
      return dateStr
    }
  }

  function getPreview(content: string): string {
    const text = stripHtml(content)
    if (!text) return ''
    return text.length > 60 ? text.substring(0, 60) + '...' : text
  }

  function updateToolbarState() {
    if (!editor) return
    isBold = editor.isActive('bold')
    isItalic = editor.isActive('italic')
    isStrike = editor.isActive('strike')
    isBulletList = editor.isActive('bulletList')
    isOrderedList = editor.isActive('orderedList')
    isHeading = editor.isActive('heading', { level: 3 })
  }

  function createEditor(content: string) {
    destroyEditor()
    if (!editorElement) return

    editor = new Editor({
      element: editorElement,
      extensions: [
        StarterKit.configure({
          heading: { levels: [3] },
        }),
      ],
      content: content || '',
      editorProps: {
        attributes: {
          class: 'notes-tiptap-content lscrollbar',
        },
      },
      onUpdate: ({ editor: ed }) => {
        const html = ed.getHTML()
        if (selectedNoteId !== null) {
          const note = notes.find(n => n.id === selectedNoteId)
          if (note) {
            const updated = { ...note, content: html }
            notes = notes.map(n => n.id === updated.id ? updated : n)
            scheduleSave(updated.id)
          }
        }
        updateToolbarState()
      },
      onSelectionUpdate: () => {
        updateToolbarState()
      },
      onTransaction: () => {
        updateToolbarState()
      },
    })
  }

  function destroyEditor() {
    if (editor) {
      editor.destroy()
      editor = null
    }
  }

  $effect(() => {
    const note = selectedNote
    if (note && editorElement) {
      if (editorNoteId !== note.id) {
        editorNoteId = note.id
        createEditor(note.content)
      }
    } else {
      editorNoteId = null
      destroyEditor()
    }
  })

  async function loadNotes() {
    isLoading = true
    const result = await fetchApi<Note[]>(
      'notesGetAll',
      { method: 'POST', body: JSON.stringify({}) },
      MOCK_NOTES
    )
    notes = result || []
    isLoading = false
  }

  async function createNote() {
    const mockNote: Note = {
      id: nextMockId++,
      title: '',
      content: '',
      color: '#FFE56D',
      pinned: false,
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString()
    }

    const result = await fetchApi<Note>(
      'notesCreate',
      { method: 'POST', body: JSON.stringify({ title: '', content: '', color: '#FFE56D' }) },
      mockNote
    )

    if (result && !('error' in result)) {
      notes = [result, ...notes]
      selectedNoteId = result.id
    }
  }

  function scheduleSave(noteId: number) {
    if (saveTimeout) clearTimeout(saveTimeout)
    saveTimeout = setTimeout(() => {
      const current = notes.find(n => n.id === noteId)
      if (current) saveNote(current)
    }, 600)
  }

  async function saveNote(note: Note) {
    const mockResult = { ...note, updated_at: new Date().toISOString() }
    const result = await fetchApi<Note>(
      'notesUpdate',
      { method: 'POST', body: JSON.stringify({
        id: note.id,
        title: note.title,
        content: note.content,
        color: note.color
      })},
      mockResult
    )

    if (result && !('error' in result)) {
      const localNote = notes.find(n => n.id === result.id)
      const merged = localNote ? { ...result, pinned: localNote.pinned } : result
      notes = notes.map(n => n.id === merged.id ? merged : n)
    }
  }

  async function togglePin(note: Note) {
    if (saveTimeout) {
      clearTimeout(saveTimeout)
      saveTimeout = null
    }

    const newPinned = !note.pinned
    const updated = { ...note, pinned: newPinned, updated_at: new Date().toISOString() }

    notes = notes.map(n => n.id === note.id ? updated : n)
    notes = sortNotes(notes)

    const result = await fetchApi<{ success?: boolean; error?: string; pinned?: boolean }>(
      'notesTogglePin',
      { method: 'POST', body: JSON.stringify({
        id: note.id,
        pinned: newPinned ? 1 : 0
      })},
      { success: true, pinned: newPinned }
    )

    if (!result || result.error) {
      notes = notes.map(n => n.id === note.id ? { ...n, pinned: note.pinned } : n)
      notes = sortNotes(notes)
    }
  }

  async function deleteNote(id: number) {
    const mockResult = { success: true }
    const result = await fetchApi<{ success?: boolean; error?: string }>(
      'notesDelete',
      { method: 'POST', body: JSON.stringify({ id }) },
      mockResult
    )

    if (result && 'success' in result) {
      notes = notes.filter(n => n.id !== id)
      if (selectedNoteId === id) {
        selectedNoteId = null
      }
      deleteConfirmId = null
    }
  }

  function setColor(note: Note, color: string) {
    const updated = { ...note, color }
    notes = notes.map(n => n.id === note.id ? updated : n)
    scheduleSave(updated.id)
  }

  function onTitleInput(e: Event) {
    if (!selectedNote) return
    const value = (e.target as HTMLInputElement).value
    const updated = { ...selectedNote, title: value }
    notes = notes.map(n => n.id === updated.id ? updated : n)
    scheduleSave(updated.id)
  }

  function sortNotes(list: Note[]): Note[] {
    return [...list].sort((a, b) => {
      if (a.pinned !== b.pinned) return a.pinned ? -1 : 1
      return new Date(b.updated_at).getTime() - new Date(a.updated_at).getTime()
    })
  }

  function selectNote(id: number) {
    selectedNoteId = id
    deleteConfirmId = null
  }

  function toggleBold() { editor?.chain().focus().toggleBold().run() }
  function toggleItalic() { editor?.chain().focus().toggleItalic().run() }
  function toggleStrike() { editor?.chain().focus().toggleStrike().run() }
  function toggleBulletList() { editor?.chain().focus().toggleBulletList().run() }
  function toggleOrderedList() { editor?.chain().focus().toggleOrderedList().run() }
  function toggleHeading() { editor?.chain().focus().toggleHeading({ level: 3 }).run() }

  onMount(() => {
    changeWindowTitle(localeStore.t('notes_title'))
    appReady()
    loadNotes()
  })

  onDestroy(() => {
    destroyEditor()
    if (saveTimeout) clearTimeout(saveTimeout)
  })
</script>

<div class="flex-1 flex bg-[#16171C] select-none overflow-hidden font-['Gilroy',Inter,sans-serif] relative">
  <div class="w-[220px] min-w-[220px] flex flex-col bg-[#1A1B21] border-r border-[#2D2F3A]">
    <div class="flex items-center justify-between pt-[14px] px-3 pb-2 shrink-0">
      <span class="text-[#F0F0F5] font-bold text-[15px]">{localeStore.t('notes_title')}</span>
      <!-- svelte-ignore a11y_consider_explicit_label -->
      <button type="button" class="w-7 h-7 flex items-center justify-center bg-[#5BBD6B] border-none rounded-lg text-[#16171C] cursor-pointer transition-colors duration-150 hover:bg-[#4DAD5D]" onclick={createNote} title={localeStore.t('notes_new_note')}>
        <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><path d="M12 5v14"/><path d="M5 12h14"/></svg>
      </button>
    </div>

    <div class="relative px-3 pb-2 shrink-0">
      <svg class="absolute left-5 top-1/2 -translate-y-[calc(50%+4px)] text-[#50525E] pointer-events-none" xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="11" cy="11" r="8"/><path d="m21 21-4.3-4.3"/></svg>
      <input
        type="text"
        class="w-full bg-[#252730] border border-[#2D2F3A] rounded-lg text-[#F0F0F5] text-xs py-[7px] pr-[10px] pl-[30px] outline-none font-inherit transition-colors duration-150 box-border focus:border-[#5BBD6B] placeholder:text-[#50525E]"
        placeholder={localeStore.t('notes_search_placeholder')}
        bind:value={searchQuery}
      />
    </div>

    <div class="flex-1 overflow-y-auto flex flex-col gap-[2px] px-[6px] pb-[6px] min-h-0 lscrollbar">
      {#if isLoading}
        <div class="flex-1 flex items-center justify-center"><div class="w-5 h-5 border-2 border-[#2D2F3A] border-t-[#8B8D9A] rounded-full animate-spin"></div></div>
      {:else if filteredNotes.length === 0}
        <div class="text-[#50525E] text-xs text-center py-6 px-3">{localeStore.t('notes_no_notes')}</div>
      {:else}
        {#each filteredNotes as note (note.id)}
          <!-- svelte-ignore a11y_consider_explicit_label -->
          <button
            type="button"
            class="flex w-full border rounded-xl overflow-hidden cursor-pointer text-left transition-colors duration-150 shrink-0 {selectedNoteId === note.id ? 'border-[#5BBD6B]' : 'border-transparent hover:border-[#2D2F3A]'}"
            style="background: linear-gradient(135deg, {note.color}10 0%, transparent 60%)"
            onclick={() => selectNote(note.id)}
          >
            <div class="flex-1 min-w-0 py-2 px-[10px] flex flex-col gap-[2px]">
              <div class="flex items-center justify-between gap-1">
                <span class="text-[#F0F0F5] text-xs font-semibold truncate flex-1 min-w-0">{note.title || localeStore.t('notes_title_placeholder')}</span>
                {#if note.pinned}
                  <svg class="text-[#8B8D9A] shrink-0" xmlns="http://www.w3.org/2000/svg" width="12" height="12" viewBox="0 0 24 24" fill="currentColor" stroke="none"><path d="M16 2l-4 4-4-2-5 5 3 3L2 16l4 4 4-4 3 3 5-5-2-4 4-4-4-4z"/></svg>
                {/if}
              </div>
              <span class="text-[#6B6D7A] text-[11px] truncate">{getPreview(note.content)}</span>
              <div class="flex items-center gap-[5px] mt-[3px]">
                <span class="w-[7px] h-[7px] rounded-full shrink-0" style="background-color: {note.color}"></span>
                <span class="text-[#3E404B] text-[10px] font-medium">{formatDate(note.updated_at)}</span>
              </div>
            </div>
          </button>
        {/each}
      {/if}
    </div>
  </div>

  <div class="flex-1 flex flex-col min-w-0 p-[10px] gap-2">
    {#if selectedNote}
      <div class="flex items-center gap-2 shrink-0">
        <input
          type="text"
          class="flex-1 bg-transparent border-none text-[#F0F0F5] text-lg font-bold font-inherit outline-none p-0 min-w-0 placeholder:text-[#3E404B]"
          placeholder={localeStore.t('notes_title_placeholder')}
          value={selectedNote.title}
          oninput={onTitleInput}
          maxlength="255"
        />
        <div class="flex items-center gap-1 shrink-0">
          <!-- svelte-ignore a11y_consider_explicit_label -->
          <button
            type="button"
            class="w-8 h-8 flex items-center justify-center bg-none border border-[#2D2F3A] rounded-lg cursor-pointer transition-colors duration-150 {selectedNote.pinned ? 'text-[#FFE56D] !border-[#FFE56D] bg-[rgba(255,229,109,0.08)]' : 'text-[#8B8D9A] hover:text-[#F0F0F5] hover:border-[#3A3D4A]'}"
            onclick={() => selectedNote && togglePin(selectedNote)}
            title={selectedNote.pinned ? localeStore.t('notes_unpin') : localeStore.t('notes_pin')}
          >
            <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="{selectedNote.pinned ? 'currentColor' : 'none'}" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 17v5"/><path d="M9 10.76a2 2 0 0 1-1.11 1.79l-1.78.9A2 2 0 0 0 5 15.24V16a1 1 0 0 0 1 1h12a1 1 0 0 0 1-1v-.76a2 2 0 0 0-1.11-1.79l-1.78-.9A2 2 0 0 1 15 10.76V7a1 1 0 0 1 1-1 1 1 0 0 0 1-1V4a2 2 0 0 0-2-2H9a2 2 0 0 0-2 2v1a1 1 0 0 0 1 1 1 1 0 0 1 1 1z"/></svg>
          </button>

          {#if deleteConfirmId === selectedNote.id}
            <div class="flex items-center gap-1">
              <span class="text-[#E55B5B] text-[11px] font-medium whitespace-nowrap">{localeStore.t('notes_delete_confirm')}</span>
              <!-- svelte-ignore a11y_consider_explicit_label -->
              <button type="button" class="w-7 h-7 flex items-center justify-center border border-[#2D2F3A] rounded-md cursor-pointer bg-none transition-colors duration-150 text-[#5BBD6B] hover:border-[#5BBD6B]" onclick={() => selectedNote && deleteNote(selectedNote.id)}>
                <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M20 6 9 17l-5-5"/></svg>
              </button>
              <!-- svelte-ignore a11y_consider_explicit_label -->
              <button type="button" class="w-7 h-7 flex items-center justify-center border border-[#2D2F3A] rounded-md cursor-pointer bg-none transition-colors duration-150 text-[#8B8D9A] hover:text-[#E55B5B] hover:border-[#E55B5B]" onclick={() => { deleteConfirmId = null }}>
                <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M18 6 6 18"/><path d="m6 6 12 12"/></svg>
              </button>
            </div>
          {:else}
            <!-- svelte-ignore a11y_consider_explicit_label -->
            <button type="button" class="w-8 h-8 flex items-center justify-center text-[#8B8D9A] bg-none border border-[#2D2F3A] rounded-lg cursor-pointer transition-colors duration-150 hover:text-[#E55B5B] hover:border-[#E55B5B]" onclick={() => selectedNote && (deleteConfirmId = selectedNote.id)}>
              <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 6h18"/><path d="M19 6v14c0 1-1 2-2 2H7c-1 0-2-1-2-2V6"/><path d="M8 6V4c0-1 1-2 2-2h4c1 0 2 1 2 2v2"/></svg>
            </button>
          {/if}
        </div>
      </div>

      <div class="flex items-center gap-[2px] shrink-0 py-1 px-[6px] bg-[#1E2028] border border-[#2D2F3A] border-b-0 rounded-t-[10px]">
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
        <div class="flex-1"></div>
        <div class="flex items-center gap-[3px]">
          {#each COLORS as color}
            <!-- svelte-ignore a11y_consider_explicit_label -->
            <button
              type="button"
              class="notes-tb-color w-[22px] h-[22px] flex items-center justify-center bg-none border-none rounded-md cursor-pointer p-0 transition-colors duration-150 hover:bg-[#252730] {selectedNote.color === color ? 'notes-tb-color-active !bg-[#252730]' : ''}"
              onclick={() => selectedNote && setColor(selectedNote, color)}
            >
              <span class="notes-tb-color-fill w-[14px] h-[14px] rounded block transition-shadow duration-150" style="background-color: {color}"></span>
            </button>
          {/each}
        </div>
      </div>

      <div class="notes-editor-wrap flex-1 min-h-0 flex flex-col overflow-hidden bg-[#1E2028] border border-[#2D2F3A] border-t-0 rounded-b-[10px]">
        <div bind:this={editorElement} class="notes-tiptap-container"></div>
      </div>
    {:else}
      <div class="flex-1 flex flex-col items-center justify-center gap-3 text-[#50525E]">
        <svg xmlns="http://www.w3.org/2000/svg" width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1" stroke-linecap="round" stroke-linejoin="round" opacity="0.3"><path d="M12 17v5"/><path d="M9 10.76a2 2 0 0 1-1.11 1.79l-1.78.9A2 2 0 0 0 5 15.24V16a1 1 0 0 0 1 1h12a1 1 0 0 0 1-1v-.76a2 2 0 0 0-1.11-1.79l-1.78-.9A2 2 0 0 1 15 10.76V7a1 1 0 0 1 1-1 1 1 0 0 0 1-1V4a2 2 0 0 0-2-2H9a2 2 0 0 0-2 2v1a1 1 0 0 0 1 1 1 1 0 0 1 1 1z"/></svg>
        <span class="text-[13px] font-medium">{localeStore.t('notes_select_note')}</span>
      </div>
    {/if}
  </div>
</div>

<style>
  .notes-tb-color-active .notes-tb-color-fill {
    box-shadow: 0 0 0 2px #1E2028, 0 0 0 3.5px currentColor;
  }

  .notes-editor-wrap :global(.notes-tiptap-container) {
    flex: 1;
    display: flex;
    flex-direction: column;
    min-height: 0;
  }
  .notes-editor-wrap :global(.tiptap) {
    flex: 1;
    color: #C8C9CF;
    font-size: 13px;
    line-height: 1.65;
    padding: 8px 10px;
    outline: none;
    font-family: 'Gilroy', Inter, sans-serif;
    overflow-y: auto;
    min-height: 0;
    user-select: text;
  }
  .notes-editor-wrap :global(.tiptap p) {
    margin: 0 0 4px;
  }
  .notes-editor-wrap :global(.tiptap h3) {
    color: #F0F0F5;
    font-size: 15px;
    font-weight: 700;
    margin: 0 0 6px;
  }
  .notes-editor-wrap :global(.tiptap ul),
  .notes-editor-wrap :global(.tiptap ol) {
    padding-left: 20px;
    margin: 0 0 4px;
  }
  .notes-editor-wrap :global(.tiptap li) {
    margin: 0 0 2px;
  }
  .notes-editor-wrap :global(.tiptap li p) {
    margin: 0;
  }
  .notes-editor-wrap :global(.tiptap s) {
    color: #50525E;
  }
  .notes-editor-wrap :global(.tiptap p.is-editor-empty:first-child::before) {
    content: attr(data-placeholder);
    float: left;
    color: #3E404B;
    pointer-events: none;
    height: 0;
  }
</style>
