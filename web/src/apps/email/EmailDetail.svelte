<script lang="ts">
  import { onMount } from 'svelte'
  import { localeStore } from '$lib/stores/localeStore.svelte'
  import { fetchApi } from '$lib/utils/api'

  interface Email {
    id: number
    owner_address: string
    from_address: string
    to_address: string
    subject: string
    body: string
    folder: string
    is_read: boolean
    created_at: string
  }

  let { email, onback, ondelete }: {
    email: Email
    onback: () => void
    ondelete: (id: number) => void
  } = $props()

  let deleteConfirm = $state(false)

  function formatDate(dateStr: string): string {
    try {
      const d = new Date(dateStr)
      return d.toLocaleDateString([], { year: 'numeric', month: 'short', day: 'numeric', hour: '2-digit', minute: '2-digit' })
    } catch {
      return dateStr
    }
  }

  onMount(() => {
    if (!email.is_read) {
      fetchApi<{ success?: boolean }>(
        'emailMarkRead',
        { method: 'POST', body: JSON.stringify({ id: email.id }) },
        { success: true }
      )
    }
  })
</script>

<div class="flex-1 flex flex-col min-w-0 min-h-0">
  <div class="flex items-center justify-between py-[10px] px-[14px] border-b border-[#1E2028] shrink-0">
    <!-- svelte-ignore a11y_consider_explicit_label -->
    <button type="button" class="flex items-center gap-[6px] bg-none border-none text-[#8B8D9A] text-xs font-medium font-inherit cursor-pointer py-1 px-2 rounded-md transition-colors duration-150 hover:text-[#F0F0F5] hover:bg-[#252730]" onclick={onback}>
      <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="m12 19-7-7 7-7"/><path d="M19 12H5"/></svg>
      <span>{localeStore.t('email_back')}</span>
    </button>

    <div class="flex items-center gap-1">
      {#if deleteConfirm}
        <span class="text-[#E55B5B] text-[11px] font-medium mr-1">{localeStore.t('email_delete_confirm')}</span>
        <!-- svelte-ignore a11y_consider_explicit_label -->
        <button type="button" class="w-7 h-7 flex items-center justify-center border border-[#2D2F3A] rounded-md cursor-pointer bg-none transition-colors duration-150 text-[#5BBD6B] hover:border-[#5BBD6B]" onclick={() => ondelete(email.id)}>
          <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M20 6 9 17l-5-5"/></svg>
        </button>
        <!-- svelte-ignore a11y_consider_explicit_label -->
        <button type="button" class="w-7 h-7 flex items-center justify-center border border-[#2D2F3A] rounded-md cursor-pointer bg-none transition-colors duration-150 text-[#8B8D9A] hover:text-[#E55B5B] hover:border-[#E55B5B]" onclick={() => { deleteConfirm = false }}>
          <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M18 6 6 18"/><path d="m6 6 12 12"/></svg>
        </button>
      {:else}
        <!-- svelte-ignore a11y_consider_explicit_label -->
        <button type="button" class="flex items-center gap-[6px] bg-none border border-[#2D2F3A] rounded-lg text-[#8B8D9A] text-[11px] font-medium font-inherit cursor-pointer py-[5px] px-[10px] transition-colors duration-150 hover:text-[#E55B5B] hover:border-[#E55B5B]" onclick={() => { deleteConfirm = true }}>
          <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 6h18"/><path d="M19 6v14c0 1-1 2-2 2H7c-1 0-2-1-2-2V6"/><path d="M8 6V4c0-1 1-2 2-2h4c1 0 2 1 2 2v2"/></svg>
          <span>{localeStore.t('email_delete')}</span>
        </button>
      {/if}
    </div>
  </div>

  <div class="flex-1 overflow-y-auto py-4 px-5 min-h-0 lscrollbar">
    <h2 class="text-[#F0F0F5] text-[17px] font-bold m-0 mb-3 break-words">{email.subject || localeStore.t('email_no_subject')}</h2>
    <div class="flex flex-col gap-1 pb-[14px] mb-[14px] border-b border-[#2D2F3A]">
      <div class="flex items-center gap-[6px]">
        <span class="text-[#50525E] text-xs font-medium shrink-0">{localeStore.t('email_from')}:</span>
        <span class="text-[#C8C9CF] text-xs font-medium">{email.from_address}</span>
      </div>
      <div class="flex items-center gap-[6px]">
        <span class="text-[#50525E] text-xs font-medium shrink-0">{localeStore.t('email_to')}:</span>
        <span class="text-[#C8C9CF] text-xs font-medium">{email.to_address}</span>
      </div>
      <div class="flex items-center gap-[6px]">
        <span class="text-[#50525E] text-[11px] font-medium">{formatDate(email.created_at)}</span>
      </div>
    </div>
    <div class="email-detail-content text-[#C8C9CF] text-[13px] leading-[1.65] break-words select-text">
      {@html email.body}
    </div>
  </div>
</div>

<style>
  .email-detail-content :global(p) {
    margin: 0 0 6px;
  }
  .email-detail-content :global(h3) {
    color: #F0F0F5;
    font-size: 15px;
    font-weight: 700;
    margin: 0 0 6px;
  }
  .email-detail-content :global(ul),
  .email-detail-content :global(ol) {
    padding-left: 20px;
    margin: 0 0 6px;
  }
  .email-detail-content :global(strong) {
    color: #F0F0F5;
  }
  .email-detail-content :global(a) {
    color: #7C8AED;
  }
</style>
