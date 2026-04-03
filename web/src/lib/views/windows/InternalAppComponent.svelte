<script lang="ts">
  import type { InternalApp } from '$lib/types/app.types'

  let { app, metadata, appReady, changeWindowTitle }: {
    app: InternalApp
    metadata?: Record<string, any>
    appReady: () => void
    changeWindowTitle: (newTitle: string) => void
  } = $props()
</script>

{#if app.component}
  {@const Component = app.component}
  <Component
    {appReady}
    {changeWindowTitle}
    {metadata}
  />
{/if}
