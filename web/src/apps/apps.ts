import type { Component } from 'svelte'

// eslint-disable-next-line @typescript-eslint/no-explicit-any
type AnyComponent = Component<any>

type ComponentLoader = () => Promise<{ default: AnyComponent }>

const loaders: Record<string, ComponentLoader> = {
  settings: () => import('../apps/SettingsApp.svelte'),
  app_store: () => import('../apps/AppStoreApp.svelte'),
  calculator: () => import('../apps/CalculatorApp.svelte'),
  spellme: () => import('../apps/SpellMeApp.svelte'),
  calendar: () => import('../apps/CalendarApp.svelte'),
  notes: () => import('../apps/NotesApp.svelte'),
  email: () => import('../apps/EmailApp.svelte'),
  yellowpages: () => import('../apps/YellowPagesApp.svelte'),
}

const loadedApps: Record<string, AnyComponent> = {}

export const getAppComponent = async (id: string): Promise<AnyComponent | undefined> => {
  if (loadedApps[id]) {
    return loadedApps[id]
  }

  const loader = loaders[id]
  if (!loader) {
    return undefined
  }

  const mod = await loader()
  loadedApps[id] = mod.default
  return mod.default
}

export function hasAppComponent(id: string): boolean {
  return id in loaders
}

export const apps: Record<string, AnyComponent> = loadedApps
