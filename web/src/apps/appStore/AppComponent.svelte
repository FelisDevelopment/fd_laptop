<script lang="ts">
  import { iconUrl } from '$lib/utils/url.utils'
  import type { AppType } from '$lib/types/app.types'
  import { localeStore } from '$lib/stores/localeStore.svelte'
  import { tooltip } from '$lib/utils/tooltip'

  let { app, onopenview, oninstall, onremove }: {
    app: AppType
    onopenview?: () => void
    oninstall?: () => void
    onremove?: () => void
  } = $props()
</script>

<!-- svelte-ignore a11y_click_events_have_key_events -->
<!-- svelte-ignore a11y_no_static_element_interactions -->
<div
  class="flex cursor-pointer gap-3 rounded-xl bg-[#1E2028] p-4 text-left transition-colors hover:bg-[#252730] active:bg-[#1a1b22]"
  onclick={onopenview}
>
  <div class="h-14 w-14 flex-shrink-0">
    <img src={iconUrl(app.icon)} class="h-14 w-14 rounded-xl object-contain" alt={app.name} />
  </div>
  <div class="flex flex-1 flex-col gap-2 overflow-hidden">
    <div>
      <div class="flex items-center gap-2">
        <h3 class="text-sm font-semibold text-[#F0F0F5]">{app.name}</h3>
        {#if app.needsUpdate}
          <span
            class="rounded-full bg-[#E4A832]/20 px-1.5 py-0.5 text-[10px] font-medium text-[#E4A832]"
            use:tooltip={localeStore.t('app_store_new_version_available')}
          >
            {localeStore.t('app_store_update_button')}
          </span>
        {/if}
      </div>
      <p class="truncate text-xs text-[#8B8D9A]">
        {app.appstore?.description ?? ''}
      </p>
    </div>
    <!-- svelte-ignore a11y_click_events_have_key_events -->
    <!-- svelte-ignore a11y_no_static_element_interactions -->
    <div class="flex gap-2" onclick={(e) => e.stopPropagation()}>
      {#if !app.isInstalled && !app.isDefaultApp}
        <button
          type="button"
          class="rounded-lg bg-[#5BBD6B] px-3 py-1 text-xs font-medium text-white transition-colors hover:bg-[#4DAD5D] disabled:opacity-50"
          disabled={app.isInstalling}
          onclick={(e) => { e.stopPropagation(); oninstall?.() }}
        >
          {#if app.isInstalling}
            <i class="fa-solid fa-spinner fa-spin text-xs"></i>
          {:else}
            {localeStore.t('app_store_install_button')}
          {/if}
        </button>
      {/if}
      {#if app.isInstalled && !app.isDefaultApp}
        <button
          type="button"
          class="rounded-lg bg-[#2D2F3A] px-3 py-1 text-xs font-medium text-[#F0F0F5] transition-colors hover:bg-[#3a3c4a] disabled:opacity-50"
          disabled={app.isInstalling}
          onclick={(e) => { e.stopPropagation(); onremove?.() }}
        >
          {#if app.isInstalling}
            <i class="fa-solid fa-spinner fa-spin text-xs"></i>
          {:else}
            {localeStore.t('app_store_remove_button')}
          {/if}
        </button>
      {/if}
    </div>
  </div>
</div>
