<script lang="ts">
  interface GalleryImage {
    src: string
    alt: string
  }

  let { images = [] }: { images?: GalleryImage[] } = $props()

  let currentIndex = $state(0)
  let lightboxOpen = $state(false)

  function prev() {
    currentIndex = currentIndex > 0 ? currentIndex - 1 : images.length - 1
  }

  function next() {
    currentIndex = currentIndex < images.length - 1 ? currentIndex + 1 : 0
  }

  function openLightbox(index: number) {
    currentIndex = index
    lightboxOpen = true
  }

  function closeLightbox() {
    lightboxOpen = false
  }

  function handleLightboxKeydown(e: KeyboardEvent) {
    if (e.key === 'Escape') closeLightbox()
    else if (e.key === 'ArrowLeft') prev()
    else if (e.key === 'ArrowRight') next()
  }
</script>

{#if images.length > 0}
  <div class="flex gap-3 overflow-x-auto p-2">
    {#each images as image, i}
      <button
        type="button"
        aria-label="View image {i + 1}"
        class="group relative flex-shrink-0 overflow-hidden rounded-xl ring-1 ring-white/10 transition-colors duration-150 hover:ring-[#7C8AED]/50 {i === currentIndex ? 'ring-2 ring-[#7C8AED]' : ''}"
        onclick={() => openLightbox(i)}
      >
        <img
          src={image.src}
          alt={image.alt}
          class="h-36 w-64 object-cover"
        />
      </button>
    {/each}
  </div>

  {#if lightboxOpen}
    <!-- svelte-ignore a11y_no_static_element_interactions -->
    <div
      class="fixed inset-0 z-[100] flex items-center justify-center bg-black/80"
      onkeydown={handleLightboxKeydown}
      onclick={closeLightbox}
    >
      <!-- svelte-ignore a11y_no_static_element_interactions -->
      <!-- svelte-ignore a11y_click_events_have_key_events -->
      <div
        class="relative max-h-[85vh] max-w-[90vw]"
        onclick={(e) => e.stopPropagation()}
      >
        <button
          type="button"
          aria-label="Close"
          class="absolute -right-3 -top-3 z-10 flex h-8 w-8 items-center justify-center rounded-full bg-[#1E2028] text-[#F0F0F5] shadow-md transition-colors hover:bg-[#252730]"
          onclick={closeLightbox}
        >
          <i class="fa-solid fa-xmark text-sm"></i>
        </button>

        {#key currentIndex}
          <img
            src={images[currentIndex].src}
            alt={images[currentIndex].alt}
            class="max-h-[85vh] max-w-[90vw] rounded-2xl object-contain shadow-lg"
          />
        {/key}

        {#if images.length > 1}
          <button
            type="button"
            aria-label="Previous image"
            class="absolute -left-5 top-1/2 flex h-10 w-10 -translate-y-1/2 items-center justify-center rounded-full bg-[#1E2028] text-[#F0F0F5] shadow-md transition-colors hover:bg-[#252730]"
            onclick={prev}
          >
            <i class="fa-solid fa-chevron-left text-sm"></i>
          </button>
          <button
            type="button"
            aria-label="Next image"
            class="absolute -right-5 top-1/2 flex h-10 w-10 -translate-y-1/2 items-center justify-center rounded-full bg-[#1E2028] text-[#F0F0F5] shadow-md transition-colors hover:bg-[#252730]"
            onclick={next}
          >
            <i class="fa-solid fa-chevron-right text-sm"></i>
          </button>

          <div class="mt-4 flex justify-center gap-2">
            {#each images as _, i}
              <button
                type="button"
                aria-label="Go to image {i + 1}"
                class="h-2 rounded-full transition-colors duration-150 {i === currentIndex ? 'w-6 bg-white' : 'w-2 bg-white/40'}"
                onclick={() => currentIndex = i}
              ></button>
            {/each}
          </div>
        {/if}
      </div>
    </div>
  {/if}
{/if}
