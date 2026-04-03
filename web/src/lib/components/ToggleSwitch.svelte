<script lang="ts">
  let { checked = $bindable(false), onLabel, offLabel }: {
    checked?: boolean
    onLabel?: string
    offLabel?: string
  } = $props()
</script>

<div class="flex items-center gap-2">
  {#if onLabel || offLabel}
    <span class="text-xs text-[#8B8D9A]">
      {checked ? onLabel : offLabel}
    </span>
  {/if}
  <button
    type="button"
    class="relative inline-flex h-6 w-11 shrink-0 items-center rounded-full transition-colors duration-150 {checked ? 'bg-[#5BBD6B]' : 'bg-[#2D2F3A]'}"
    onclick={() => checked = !checked}
    role="switch"
    aria-label="Toggle"
    aria-checked={checked}
  >
    <span
      class="inline-block h-5 w-5 transform rounded-full bg-white shadow transition-transform duration-150 {checked ? 'translate-x-[1.375rem]' : 'translate-x-0.5'}"
    ></span>
  </button>
</div>
