<script lang="ts">
  let { size = '2rem' }: { size?: string } = $props()
</script>

<div
  class="inline-block animate-spin rounded-full border-2 border-gray-600 border-t-blue-400"
  style="width: {size}; height: {size};"
></div>
