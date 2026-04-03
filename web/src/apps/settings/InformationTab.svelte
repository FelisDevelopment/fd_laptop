<script lang="ts">
  import { onMount } from 'svelte'
  import { laptopStore } from '$lib/stores/laptopStore.svelte'
  import { localeStore } from '$lib/stores/localeStore.svelte'

  let { changeWindowTitle }: {
    changeWindowTitle: (newTitle: string) => void
  } = $props()

  onMount(() => {
    changeWindowTitle(localeStore.t('settings_information_title'))
  })
</script>

<div class="flex flex-1 flex-col gap-4 overflow-auto">
  <h2 class="text-base font-semibold text-[#F0F0F5]">
    {localeStore.t('settings_system_information_tab_label')}
  </h2>

  <div class="flex flex-1 flex-col items-center justify-center gap-4">
    {#if !laptopStore.needsUpdate}
      <div class="flex h-14 w-14 items-center justify-center rounded-full bg-[#5BBD6B]/20">
        <i class="fa-solid fa-circle-check text-2xl text-[#5BBD6B]"></i>
      </div>
      <span class="text-center text-sm text-[#F0F0F5]">
        {localeStore.t('settings_information_uptodate')}
      </span>
    {:else}
      <div class="flex h-14 w-14 items-center justify-center rounded-full bg-[#E4A832]/20">
        <i class="fa-solid fa-exclamation-circle text-2xl text-[#E4A832]"></i>
      </div>
      <span class="text-center text-sm text-[#F0F0F5]">
        {localeStore.t('settings_information_needs_update')}
      </span>
    {/if}
  </div>
</div>
