<script lang="ts">
  import { iconUrl } from '$lib/utils/url.utils'
  import type { AppType } from '$lib/types/app.types'
  import { localeStore } from '$lib/stores/localeStore.svelte'
  import ImageGallery from '$lib/components/ImageGallery.svelte'

  let { app, onclose, oninstall, onremove }: {
    app: AppType
    onclose?: () => void
    oninstall?: (app: AppType) => void
    onremove?: (app: AppType) => void
  } = $props()

  let images = $derived(
    app.appstore?.images
      ? app.appstore.images.map((i) => ({
          src: i,
          alt: 'Preview image'
        }))
      : []
  )
</script>

<div
  class="lscrollbar absolute inset-0 z-50 overflow-auto bg-[#16171C]"
>
  {#if app.needsUpdate}
    <div class="flex items-center justify-center gap-2 bg-[#E4A832] py-2.5 text-center text-sm font-medium text-white">
      <i class="fa-solid fa-circle-exclamation text-xs"></i>
      {localeStore.t('app_store_new_version_available_overlay')}
    </div>
  {/if}

  <div class="relative flex h-44 items-center bg-[#1E2028] px-10">
    <button
      type="button"
      aria-label="Close"
      class="absolute right-3 top-3 flex h-8 w-8 items-center justify-center rounded-lg text-[#8B8D9A] transition-colors hover:bg-[#252730] hover:text-[#F0F0F5]"
      onclick={onclose}
    >
      <i class="fa-solid fa-xmark text-sm"></i>
    </button>
    <div class="flex flex-1 items-center gap-5">
      <img src={iconUrl(app.icon)} class="h-20 w-20 rounded-2xl" alt={app.name} />
      <div class="flex flex-1 flex-col gap-1">
        <h2 class="text-xl font-semibold text-[#F0F0F5]">{app.name}</h2>
        {#if app.appstore?.author}
          <span class="text-xs text-[#8B8D9A]">{app.appstore.author}</span>
        {/if}
        <span class="break-words text-sm text-[#8B8D9A]">
          {app.appstore?.description ?? ''}
        </span>
      </div>
      {#if !app.isInstalled && !app.isDefaultApp}
        <button
          type="button"
          class="rounded-lg bg-[#5BBD6B] px-5 py-2 text-sm font-medium text-white transition-colors hover:bg-[#4DAD5D] disabled:opacity-50"
          disabled={app.isInstalling}
          onclick={() => oninstall?.(app)}
        >
          {#if app.isInstalling}
            <i class="fa-solid fa-spinner fa-spin"></i>
          {:else}
            Install
          {/if}
        </button>
      {/if}
      {#if app.isInstalled && !app.isDefaultApp}
        <button
          type="button"
          class="rounded-lg bg-[#2D2F3A] px-5 py-2 text-sm font-medium text-[#F0F0F5] transition-colors hover:bg-[#3a3c4a] disabled:opacity-50"
          disabled={app.isInstalling}
          onclick={() => onremove?.(app)}
        >
          {#if app.isInstalling}
            <i class="fa-solid fa-spinner fa-spin"></i>
          {:else}
            Remove
          {/if}
        </button>
      {/if}
    </div>
  </div>
  <div class="flex flex-col gap-8 px-10 py-6">
    <div class="flex flex-col gap-2">
      <span class="text-xs font-medium uppercase tracking-wide text-[#8B8D9A]">{localeStore.t('app_store_overlay_description')}</span>
      <p class="text-sm leading-relaxed text-[#F0F0F5]">
        {app.appstore?.description ?? ''}
      </p>
    </div>

    {#if images.length > 0}
      <div class="flex flex-col gap-2">
        <span class="text-xs font-medium uppercase tracking-wide text-[#8B8D9A]">{localeStore.t('app_store_overlay_preview')}</span>
        <ImageGallery {images} />
      </div>
    {/if}
  </div>
</div>
