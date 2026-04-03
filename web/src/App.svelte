<script lang="ts">
  import { onMount } from 'svelte'
  import { developmentStore } from '$lib/stores/developmentStore.svelte'
  import { laptopStore } from '$lib/stores/laptopStore.svelte'
  import { notificationsStore } from '$lib/stores/notificationsStore.svelte'
  import { settingsStore } from '$lib/stores/settingsStore.svelte'
  import Laptop from '$lib/views/Laptop.svelte'
  import DevelopmentToolbar from '$lib/devComponents/DevelopmentToolbar.svelte'

  let showLaptop = $derived(laptopStore.isOpen || notificationsStore.shouldBeShown(laptopStore.isOpen, settingsStore.doNotDisturb))

  onMount(() => {
    if (developmentStore.isDevEnv) {
      developmentStore.applyDevelopmentStyles()
    }

    laptopStore.init()
  })
</script>

<div class={showLaptop ? '' : 'hidden'}>
  <Laptop />
</div>
{#if developmentStore.isDevEnv}
  <DevelopmentToolbar />
{/if}
