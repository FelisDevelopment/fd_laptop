import type { AppType } from '../types/app.types'

export const findByLetter = (letter: string) => (element: any) => element.letter === letter

export const groupApps = (apps: AppType[]) => {
  const transformed = []

  for (let i = 0; i < apps.length; i++) {
    const letter = apps[i].name.split('')[0]
    const elIndex = transformed.findIndex(findByLetter(letter))
    if (elIndex > -1) {
      transformed[elIndex].data.push(apps[i])
    } else {
      transformed.push({
        letter,
        data: [apps[i]]
      })
    }
  }

  return transformed.sort((a, b) => (a.letter > b.letter ? 1 : -1))
}
