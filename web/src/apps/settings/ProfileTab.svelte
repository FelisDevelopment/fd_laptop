<script lang="ts">
  import { onMount } from 'svelte'
  import { settingsStore } from '$lib/stores/settingsStore.svelte'
  import { notificationsStore } from '$lib/stores/notificationsStore.svelte'
  import { localeStore } from '$lib/stores/localeStore.svelte'
  import { fetchApi } from '$lib/utils/api'
  import { settingsBus } from '$lib/utils/eventBus'
  import { nonEmpty, object, pipe, string, url, safeParse } from 'valibot'
  import type { ProfileUpdateResponse } from '$lib/types/profile.types'
  import Avatar from '$lib/components/Avatar.svelte'

  let { changeWindowTitle }: {
    changeWindowTitle: (newTitle: string) => void
  } = $props()

  let isLoading = $state(false)
  let nickname = $state(settingsStore.username)
  let profilePicture = $state(settingsStore.profilePicture || '')
  let errors = $state<Record<string, string>>({})

  const schema = object({
    nickname: pipe(
      string(localeStore.t('settings_profile_nickname_a_string')),
      nonEmpty(localeStore.t('settings_profile_nickname_not_empty'))
    ),
    profilePicture: pipe(
      string(localeStore.t('settings_profile_profile_picture_a_string')),
      nonEmpty(localeStore.t('settings_profile_profile_picture_not_empty')),
      url(localeStore.t('settings_profile_profile_picture_valid_url'))
    )
  })

  function resetForm() {
    nickname = settingsStore.username
    profilePicture = settingsStore.profilePicture || ''
    errors = {}
  }

  async function saveProfile() {
    errors = {}

    const result = safeParse(schema, { nickname, profilePicture })

    if (!result.success) {
      for (const issue of result.issues) {
        const path = issue.path?.[0]?.key
        if (path && typeof path === 'string') {
          errors[path] = issue.message
        }
      }
      return
    }

    if (settingsStore.username === nickname && settingsStore.profilePicture === profilePicture) {
      return
    }

    isLoading = true

    const data = await fetchApi<ProfileUpdateResponse>(
      'updateUserSettings',
      {
        method: 'POST',
        body: JSON.stringify({
          nickname,
          profile_picture: profilePicture
        })
      },
      { success: true, error: undefined }
    )

    const { success, error } = data as ProfileUpdateResponse

    isLoading = false

    if (!success) {
      errors = { nickname: error || 'Error' }
      return
    }

    notificationsStore.show({
      summary: localeStore.t('settings_profile_updated_title'),
      detail: localeStore.t('settings_profile_updated_description')
    })

    settingsBus.emit('updated')
  }

  let isUnchanged = $derived(
    settingsStore.username === nickname && settingsStore.profilePicture === profilePicture
  )

  onMount(() => {
    changeWindowTitle(localeStore.t('settings_profile_title'))
  })
</script>

<div class="flex flex-1 flex-col gap-4 overflow-auto">
  <h2 class="text-base font-semibold text-[#F0F0F5]">
    {localeStore.t('settings_profile_tab_label')}
  </h2>

  <div class="flex items-center gap-4 rounded-xl bg-[#1E2028] px-4 py-4">
    <Avatar
      image={settingsStore.profilePicture}
      icon={settingsStore.profilePicture ? undefined : 'fa-solid fa-user'}
      size="xlarge"
    />
    <div class="flex flex-col">
      <span class="text-sm font-semibold text-[#F0F0F5]">{settingsStore.username}</span>
      {#if settingsStore.job}
        <span class="text-xs text-[#8B8D9A]">{settingsStore.job}</span>
      {/if}
    </div>
  </div>

  <div class="rounded-xl bg-[#1E2028] p-4">
    <div class="mb-3 flex items-center justify-between">
      <span class="text-xs font-medium uppercase tracking-wide text-[#8B8D9A]">
        {localeStore.t('settings_profile_tab_label')}
      </span>
      <button type="button" aria-label="Reset" onclick={resetForm} class="text-xs text-[#8B8D9A] transition-colors hover:text-[#F0F0F5]">
        <i class="fa-solid fa-rotate text-xs"></i>
      </button>
    </div>

    <div class="flex flex-col gap-3">
      <div class="flex flex-col gap-1">
        <label for="nickname" class="text-xs font-medium text-[#8B8D9A]">
          {localeStore.t('settings_profile_nickname_field_label')}
        </label>
        <input
          id="nickname"
          bind:value={nickname}
          placeholder={localeStore.t('settings_profile_nickname_field_placeholder')}
          class="w-full rounded-lg border bg-[#16171C] px-3 py-2 text-sm text-[#F0F0F5] outline-none transition-colors focus:border-[#7C8AED] {errors.nickname ? 'border-[#E55B5B]' : 'border-[#2D2F3A]'}"
        />
        {#if errors.nickname}
          <small class="text-[#E55B5B]">{errors.nickname}</small>
        {/if}
      </div>
      <div class="flex flex-col gap-1">
        <label for="profilePicture" class="text-xs font-medium text-[#8B8D9A]">
          {localeStore.t('settings_profile_profile_picture_field_label')}
        </label>
        <input
          id="profilePicture"
          bind:value={profilePicture}
          placeholder={localeStore.t('settings_profile_profile_picture_field_placeholder')}
          class="w-full rounded-lg border bg-[#16171C] px-3 py-2 text-sm text-[#F0F0F5] outline-none transition-colors focus:border-[#7C8AED] {errors.profilePicture ? 'border-[#E55B5B]' : 'border-[#2D2F3A]'}"
        />
        {#if errors.profilePicture}
          <small class="text-[#E55B5B]">{errors.profilePicture}</small>
        {/if}
      </div>
    </div>

    <button
      type="button"
      class="mt-4 w-full rounded-lg bg-[#5BBD6B] px-4 py-2 text-sm font-medium text-white transition-colors hover:bg-[#4DAD5D] disabled:opacity-50"
      onclick={saveProfile}
      disabled={isLoading || isUnchanged}
    >
      {#if isLoading}
        <i class="fa-solid fa-spinner fa-spin"></i>
      {:else}
        {localeStore.t('settings_profile_save_button')}
      {/if}
    </button>
  </div>
</div>
