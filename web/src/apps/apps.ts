import { defineAsyncComponent, shallowRef, type ShallowRef } from 'vue'

export const apps: Record<string, ShallowRef> = {
  settings: shallowRef(
    defineAsyncComponent(
      () =>
        import(
          /* webpackChunkName: "SettingsApp" */
          '../apps/SettingsApp.vue'
        )
    )
  ),
  app_store: shallowRef(
    defineAsyncComponent(
      () =>
        import(
          /* webpackChunkName: "AppStoreApp" */
          '../apps/AppStoreApp.vue'
        )
    )
  )
}
