<script lang="ts">
  let { image, icon, size = 'normal', onclick }: {
    image?: string
    icon?: string
    size?: 'normal' | 'xlarge'
    onclick?: (e: MouseEvent) => void
  } = $props()

  let sizeClasses = $derived(
    size === 'xlarge' ? 'h-16 w-16 text-2xl' : 'h-8 w-8 text-sm'
  )
</script>

<!-- svelte-ignore a11y_click_events_have_key_events -->
<!-- svelte-ignore a11y_no_static_element_interactions -->
<div
  class="flex items-center justify-center overflow-hidden rounded-full bg-[#2D2F3A] text-[#8B8D9A] {sizeClasses} {onclick ? 'cursor-pointer' : ''} {size === 'xlarge' ? 'ring-2 ring-[#2D2F3A]' : ''}"
  onclick={onclick}
>
  {#if image}
    <img src={image} alt="Avatar" class="h-full w-full object-cover" />
  {:else if icon}
    <i class={icon}></i>
  {:else}
    <i class="fa-solid fa-user"></i>
  {/if}
</div>
