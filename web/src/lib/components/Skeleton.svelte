<script lang="ts">
  let { height = '1rem' }: { height?: string } = $props()
</script>

<div
  class="animate-pulse rounded-lg bg-gray-700"
  style="height: {height};"
></div>
