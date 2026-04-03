<script lang="ts">
  import TaskbarApps from './TaskbarApps.svelte'
  import Clock from './Clock.svelte'
  import Notifications from './Notifications.svelte'
</script>

<div class="z-10 flex items-center">
  <TaskbarApps />
  <Clock />
  <Notifications />
</div>
