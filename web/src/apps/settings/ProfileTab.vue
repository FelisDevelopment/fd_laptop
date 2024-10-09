<script setup lang="ts">
import type { InternalAppWindowBinds } from '../../types/window.types'
import { useForm } from 'vee-validate'
import { useSettings } from '../../stores/settings.store'
import { onMounted, ref } from 'vue'
import { toTypedSchema } from '@vee-validate/valibot'
import { nonEmpty, object, pipe, string, url } from 'valibot'
import { useApi } from '../../composables/useApi'
import { useNotifications } from '../../stores/notifications.store'
import { useEventBus } from '@vueuse/core'
import Avatar from 'primevue/avatar'
import Button from 'primevue/button'
import InputText from 'primevue/inputtext'
import type { ProfileUpdateResponse } from '../../types/profile.types'
import { useLocale } from '../../stores/locale.store'

const notif = useNotifications()
const settings = useSettings()
const locale = useLocale()
const props = defineProps<Omit<InternalAppWindowBinds, 'appReady' | 'app'>>()
const bus = useEventBus('settings')

const isLoading = ref<boolean>(false)

const { errors, defineField, handleSubmit, setFieldError, resetForm } = useForm({
  validationSchema: toTypedSchema(
    object({
      nickname: pipe(
        string(locale.t('settings_profile_nickname_a_string')),
        nonEmpty(locale.t('settings_profile_nickname_not_empty'))
      ),
      profilePicture: pipe(
        string(locale.t('settings_profile_profile_picture_a_string')),
        nonEmpty(locale.t('settings_profile_profile_picture_not_empty')),
        url(locale.t('settings_profile_profile_picture_valid_url'))
      )
    })
  ),
  initialValues: {
    nickname: settings.username,
    profilePicture: settings.profilePicture
  }
})

const [nickname] = defineField('nickname')
const [profilePicture] = defineField('profilePicture')

const saveProfile = handleSubmit(async (values) => {
  if (settings.username === values.nickname && settings.profilePicture === values.profilePicture) {
    return
  }

  isLoading.value = true

  const { data } = await useApi<ProfileUpdateResponse>(
    'updateUserSettings',
    {
      method: 'POST',
      body: JSON.stringify({
        nickname: values.nickname,
        profile_picture: values.profilePicture
      })
    },
    undefined,
    {
      success: true,
      error: undefined
    }
  )

  const { success, error } = data.value as ProfileUpdateResponse

  isLoading.value = false

  if (!success) {
    setFieldError('nickname', error)

    return
  }

  notif.show({
    summary: locale.t('settings_profile_updated_title'),
    detail: locale.t('settings_profile_updated_description')
  })

  bus.emit('updated')
})

onMounted(() => {
  props.changeWindowTitle(locale.t('settings_profile_title'))
})
</script>
<template>
  <div class="flex flex-1 flex-col items-center justify-center gap-5">
    <div class="flex flex-col items-center justify-between gap-3">
      <Avatar v-if="!settings.profilePicture" icon="pi pi-user" size="xlarge" class="border" />
      <Avatar v-else :image="settings.profilePicture" size="xlarge" />
      <span>
        {{ settings.username }}
      </span>
    </div>
    <div
      class="flex w-full flex-col items-center justify-between gap-10 rounded-lg bg-gray-300 p-4 dark:bg-gray-800"
    >
      <div class="flex w-full flex-col gap-3">
        <div class="flex w-full flex-col gap-1">
          <div class="flex items-center justify-between">
            <label for="nickname">{{ locale.t('settings_profile_nickname_field_label') }}</label>
            <a href="#" @click.prevent="resetForm()" v-tooltip.top="'Reset'">
              <i class="pi pi-refresh text-xs"></i>
            </a>
          </div>
          <InputText
            id="nickname"
            fluid
            aria-describedby="nickname-help"
            :placeholder="locale.t('settings_profile_nickname_field_placeholder')"
            v-model="nickname"
            :invalid="!!errors.nickname"
          />
          <small class="text-red-200" v-show="errors.nickname" v-text="errors.nickname"></small>
        </div>
        <div class="flex w-full flex-col gap-1">
          <label for="profileUrl">
            {{ locale.t('settings_profile_profile_picture_field_label') }}
          </label>
          <InputText
            id="profilePicture"
            fluid
            aria-describedby="profile-picture-url"
            :placeholder="locale.t('settings_profile_profile_picture_field_placeholder')"
            v-model="profilePicture"
            :invalid="!!errors.profilePicture"
          />
          <small
            class="text-red-200"
            v-show="errors.profilePicture"
            v-text="errors.profilePicture"
          ></small>
        </div>
      </div>
      <Button
        @click.prevent="saveProfile"
        :label="locale.t('settings_profile_save_button')"
        fluid
        :loading="isLoading"
        :disabled="
          isLoading ||
          (settings.username === nickname && settings.profilePicture === profilePicture)
        "
      />
    </div>
  </div>
</template>
