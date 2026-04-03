<script lang="ts">
  import { onMount } from 'svelte'
  import { laptopStore } from '$lib/stores/laptopStore.svelte'
  import { localeStore } from '$lib/stores/localeStore.svelte'

  let { changeWindowTitle }: {
    changeWindowTitle: (newTitle: string) => void
  } = $props()

  onMount(() => {
    changeWindowTitle(localeStore.t('settings_devices_title'))
  })
</script>

<div class="lscrollbar flex flex-1 flex-col gap-4 overflow-auto">
  <h2 class="text-base font-semibold text-[#F0F0F5]">
    {localeStore.t('settings_devices_tab_label')}
  </h2>

  {#if laptopStore.installedDevices.length > 0}
    <div class="divide-y divide-[#2D2F3A] rounded-xl bg-[#1E2028]">
      {#each laptopStore.installedDevices as device}
        <div class="flex items-center gap-3 px-4 py-3">
          <div class="flex h-9 w-9 shrink-0 items-center justify-center rounded-lg bg-[#2D2F3A]">
            <i class="fa-solid fa-server text-sm text-[#8B8D9A]"></i>
          </div>
          <div class="flex flex-col">
            <span class="text-sm font-medium text-[#F0F0F5]">{device.metadata.deviceLabel}</span>
            <span class="text-[11px] text-[#8B8D9A]">
              {localeStore.t('settings_devices_slot')}: {device.slot}
            </span>
          </div>
        </div>
      {/each}
    </div>
  {:else}
    <div class="flex flex-1 flex-col items-center justify-center gap-3">
      <div class="flex h-12 w-12 items-center justify-center rounded-full bg-[#2D2F3A]">
        <i class="fa-solid fa-circle-xmark text-xl text-[#50525E]"></i>
      </div>
      <span class="text-sm text-[#8B8D9A]">{localeStore.t('settings_devices_no_devices')}</span>
    </div>
  {/if}
</div>
