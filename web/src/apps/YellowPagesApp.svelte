<script lang="ts">
  import { onMount } from 'svelte'
  import { localeStore } from '$lib/stores/localeStore.svelte'
  import { fetchApi } from '$lib/utils/api'
  import { MockListings, MockReviews } from '../mock/yellowpages.mock'

  let { appReady, changeWindowTitle, metadata }: {
    appReady: () => void
    changeWindowTitle: (newTitle: string) => void
    metadata?: Record<string, any>
  } = $props()

  interface Listing {
    id: number
    name: string
    description?: string
    phone?: string
    imageUrl?: string
    status: string
    isOwner: boolean
    avgRating: number
    reviewCount: number
    createdAt?: string
  }

  interface Review {
    id: number
    rating: number
    comment?: string
    username: string
    isOwn: boolean
    reported: boolean
    createdAt?: string
  }

  const STAR_PATH = 'M12 2l3.09 6.26L22 9.27l-5 4.87L18.18 21 12 17.77 5.82 21 7 14.14l-5-4.87 6.91-1.01L12 2z'

  let nextMockListingId = 100
  let nextMockReviewId = 100

  let view = $state<'list' | 'detail' | 'form'>('list')
  let listings = $state<Listing[]>([])
  let listingsLoading = $state(true)
  let searchText = $state('')
  let selected = $state<Listing | null>(null)
  let listingDeleteConfirm = $state(false)

  let reviews = $state<Review[]>([])
  let reviewsLoading = $state(false)

  let reviewRating = $state(0)
  let reviewComment = $state('')
  let reviewSubmitting = $state(false)
  let reviewFormError = $state('')

  let editingOwnReview = $state(false)
  let editRating = $state(0)
  let editComment = $state('')
  let editSubmitting = $state(false)
  let editError = $state('')
  let ownReviewDeleteConfirm = $state(false)

  let formMode = $state<'create' | 'edit'>('create')
  let formName = $state('')
  let formDescription = $state('')
  let formPhone = $state('')
  let formImageUrl = $state('')
  let formSubmitting = $state(false)
  let formError = $state('')

  let phoneCopied = $state(false)

  let filteredListings = $derived.by(() => {
    const q = searchText.trim().toLowerCase()
    if (!q) return listings
    return listings.filter(l =>
      l.name.toLowerCase().includes(q) || (l.description || '').toLowerCase().includes(q)
    )
  })

  let ownReview = $derived(reviews.find(r => r.isOwn) || null)
  let otherReviews = $derived(selected?.isOwner ? reviews : reviews.filter(r => !r.isOwn))

  function starStates(rating: number): ('full' | 'half' | 'empty')[] {
    const floor = Math.floor(rating)
    const frac = rating - floor
    return Array.from({ length: 5 }, (_, i) => {
      if (i < floor) return 'full'
      if (i === floor && frac >= 0.5) return 'half'
      return 'empty'
    })
  }

  function errorMessage(result: unknown, fallback: string): string {
    if (result && typeof result === 'object' && 'error' in result) {
      const value = (result as { error?: unknown }).error
      if (typeof value === 'string' && value) return value
    }
    return fallback
  }

  function refreshSelectedRating() {
    if (!selected) return
    const count = reviews.length
    const avg = count === 0 ? 0 : Math.round((reviews.reduce((s, r) => s + r.rating, 0) / count) * 10) / 10
    selected = { ...selected, avgRating: avg, reviewCount: count }
  }

  async function loadListings() {
    listingsLoading = true
    const result = await fetchApi<Listing[]>(
      'yellowpagesGetListings',
      { method: 'POST', body: '{}' },
      MockListings
    )
    listings = Array.isArray(result) ? result : []
    listingsLoading = false
  }

  async function loadReviews(listingId: number) {
    reviewsLoading = true
    const result = await fetchApi<Review[]>(
      'yellowpagesGetReviews',
      { method: 'POST', body: JSON.stringify({ listingId }) },
      MockReviews
    )
    reviews = Array.isArray(result) ? result : []
    reviewsLoading = false
  }

  function openDetail(listing: Listing) {
    selected = listing
    view = 'detail'
    listingDeleteConfirm = false
    reviewRating = 0
    reviewComment = ''
    reviewFormError = ''
    editingOwnReview = false
    ownReviewDeleteConfirm = false
    phoneCopied = false
    loadReviews(listing.id)
  }

  function backToList() {
    view = 'list'
    selected = null
    loadListings()
  }

  function openCreateForm() {
    formMode = 'create'
    formName = ''
    formDescription = ''
    formPhone = ''
    formImageUrl = ''
    formError = ''
    view = 'form'
  }

  function openEditForm() {
    if (!selected) return
    formMode = 'edit'
    formName = selected.name
    formDescription = selected.description || ''
    formPhone = selected.phone || ''
    formImageUrl = selected.imageUrl || ''
    formError = ''
    view = 'form'
  }

  function cancelForm() {
    view = selected ? 'detail' : 'list'
  }

  async function submitListingForm() {
    if (!formName.trim() || formSubmitting) return
    formSubmitting = true
    formError = ''

    const isEdit = formMode === 'edit' && selected

    const mockResult: Listing = isEdit
      ? { ...selected!, name: formName.trim(), description: formDescription.trim() || undefined, phone: formPhone.trim() || undefined, imageUrl: formImageUrl.trim() || undefined }
      : { id: nextMockListingId++, name: formName.trim(), description: formDescription.trim() || undefined, phone: formPhone.trim() || undefined, imageUrl: formImageUrl.trim() || undefined, status: 'pending', isOwner: true, avgRating: 0, reviewCount: 0 }

    const body = isEdit
      ? { id: selected!.id, name: formName.trim(), description: formDescription.trim() || null, phone: formPhone.trim() || null, imageUrl: formImageUrl.trim() || null }
      : { name: formName.trim(), description: formDescription.trim() || null, phone: formPhone.trim() || null, imageUrl: formImageUrl.trim() || null }

    const result = await fetchApi<Listing>(
      isEdit ? 'yellowpagesUpdateListing' : 'yellowpagesCreateListing',
      { method: 'POST', body: JSON.stringify(body) },
      mockResult
    )

    if (!result || 'error' in result) {
      formError = errorMessage(result, localeStore.t('yellowpages_save_failed'))
    } else if (isEdit) {
      listings = listings.map(l => l.id === result.id ? result : l)
      selected = result
      view = 'detail'
    } else {
      listings = [result, ...listings]
      view = 'list'
    }

    formSubmitting = false
  }

  async function deleteListing() {
    if (!selected) return
    const result = await fetchApi<{ success?: boolean; error?: string }>(
      'yellowpagesDeleteListing',
      { method: 'POST', body: JSON.stringify({ id: selected.id }) },
      { success: true }
    )

    if (result && result.success) {
      const deletedId = selected.id
      listings = listings.filter(l => l.id !== deletedId)
      selected = null
      listingDeleteConfirm = false
      view = 'list'
    }
  }

  function copyPhone(phone: string) {
    navigator.clipboard?.writeText(phone)
    phoneCopied = true
    setTimeout(() => { phoneCopied = false }, 1500)
  }

  async function submitReview() {
    if (!selected || reviewRating < 1 || reviewSubmitting) return
    reviewSubmitting = true
    reviewFormError = ''

    const mockResult: Review = {
      id: nextMockReviewId++,
      rating: reviewRating,
      comment: reviewComment.trim() || undefined,
      username: 'You',
      isOwn: true,
      reported: false
    }

    const result = await fetchApi<Review>(
      'yellowpagesCreateReview',
      { method: 'POST', body: JSON.stringify({ listingId: selected.id, rating: reviewRating, comment: reviewComment.trim() || null }) },
      mockResult
    )

    if (!result || 'error' in result) {
      reviewFormError = errorMessage(result, localeStore.t('yellowpages_save_failed'))
    } else {
      reviews = [result, ...reviews]
      reviewRating = 0
      reviewComment = ''
      refreshSelectedRating()
    }

    reviewSubmitting = false
  }

  function startEditOwnReview(review: Review) {
    editingOwnReview = true
    editRating = review.rating
    editComment = review.comment || ''
    editError = ''
  }

  async function submitEditOwnReview() {
    if (!ownReview || editRating < 1 || editSubmitting) return
    editSubmitting = true
    editError = ''

    const mockResult: Review = { ...ownReview, rating: editRating, comment: editComment.trim() || undefined }

    const result = await fetchApi<Review>(
      'yellowpagesUpdateReview',
      { method: 'POST', body: JSON.stringify({ id: ownReview.id, rating: editRating, comment: editComment.trim() || null }) },
      mockResult
    )

    if (!result || 'error' in result) {
      editError = errorMessage(result, localeStore.t('yellowpages_save_failed'))
    } else {
      reviews = reviews.map(r => r.id === result.id ? result : r)
      editingOwnReview = false
      refreshSelectedRating()
    }

    editSubmitting = false
  }

  async function deleteOwnReview() {
    if (!ownReview) return
    const reviewId = ownReview.id
    const result = await fetchApi<{ success?: boolean; error?: string }>(
      'yellowpagesDeleteReview',
      { method: 'POST', body: JSON.stringify({ id: reviewId }) },
      { success: true }
    )

    if (result && result.success) {
      reviews = reviews.filter(r => r.id !== reviewId)
      ownReviewDeleteConfirm = false
      refreshSelectedRating()
    }
  }

  async function reportReview(review: Review) {
    const result = await fetchApi<{ success?: boolean; error?: string }>(
      'yellowpagesReportReview',
      { method: 'POST', body: JSON.stringify({ id: review.id }) },
      { success: true }
    )

    if (result && result.success) {
      reviews = reviews.map(r => r.id === review.id ? { ...r, reported: true } : r)
    }
  }

  onMount(() => {
    changeWindowTitle(localeStore.t('yellowpages_title'))
    appReady()
    loadListings()
  })
</script>

{#snippet starRow(rating: number, size: number = 12)}
  <div class="flex items-center gap-[1px] shrink-0">
    {#each starStates(rating) as state, i (i)}
      {#if state === 'full'}
        <svg width={size} height={size} viewBox="0 0 24 24" fill="#E4A832" stroke="none"><path d={STAR_PATH} /></svg>
      {:else if state === 'half'}
        <div class="relative shrink-0" style="width:{size}px;height:{size}px">
          <svg class="absolute inset-0" width={size} height={size} viewBox="0 0 24 24" fill="#3A3D4A" stroke="none"><path d={STAR_PATH} /></svg>
          <div class="absolute inset-0 overflow-hidden" style="width:50%">
            <svg width={size} height={size} viewBox="0 0 24 24" fill="#E4A832" stroke="none"><path d={STAR_PATH} /></svg>
          </div>
        </div>
      {:else}
        <svg width={size} height={size} viewBox="0 0 24 24" fill="#3A3D4A" stroke="none"><path d={STAR_PATH} /></svg>
      {/if}
    {/each}
  </div>
{/snippet}

{#snippet ratingPicker(current: number, size: number, onSelect: (n: number) => void)}
  <div class="flex items-center gap-1">
    {#each [1, 2, 3, 4, 5] as n (n)}
      <!-- svelte-ignore a11y_consider_explicit_label -->
      <button type="button" class="bg-none border-none p-0 cursor-pointer transition-colors duration-150" onclick={() => onSelect(n)}>
        <svg width={size} height={size} viewBox="0 0 24 24" fill={current >= n ? '#E4A832' : '#3A3D4A'} stroke="none"><path d={STAR_PATH} /></svg>
      </button>
    {/each}
  </div>
{/snippet}

{#snippet monogram(name: string, size: string)}
  <div class="{size} rounded-lg bg-[#E4A832]/15 text-[#E4A832] flex items-center justify-center font-bold shrink-0">{name.charAt(0).toUpperCase()}</div>
{/snippet}

<div class="flex-1 flex flex-col bg-[#16171C] select-none overflow-hidden font-['Gilroy',Inter,sans-serif] relative p-4">
  {#if view === 'list'}
    <div class="flex items-center justify-between mb-3 shrink-0">
      <span class="text-[#F0F0F5] font-bold text-base">{localeStore.t('yellowpages_title')}</span>
      <!-- svelte-ignore a11y_consider_explicit_label -->
      <button type="button" class="flex items-center gap-1 py-[6px] px-3 text-xs font-semibold text-[#16171C] bg-[#E4A832] border-none rounded-lg cursor-pointer transition-colors duration-150 hover:bg-[#C99527]" onclick={openCreateForm}>
        <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><path d="M12 5v14" /><path d="M5 12h14" /></svg>
        {localeStore.t('yellowpages_new_listing')}
      </button>
    </div>

    <div class="relative mb-3 shrink-0">
      <svg class="absolute left-3 top-1/2 -translate-y-1/2 text-[#50525E] pointer-events-none" xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="11" cy="11" r="8" /><path d="m21 21-4.3-4.3" /></svg>
      <input
        type="text"
        class="w-full bg-[#252730] border border-[#2D2F3A] rounded-lg text-[#F0F0F5] text-[13px] py-2 pr-[10px] pl-8 outline-none font-inherit transition-colors duration-150 box-border focus:border-[#E4A832] placeholder:text-[#50525E]"
        placeholder={localeStore.t('yellowpages_search_placeholder')}
        bind:value={searchText}
      />
    </div>

    <div class="flex-1 overflow-y-auto flex flex-col gap-2 min-h-0 lscrollbar">
      {#if listingsLoading}
        <div class="flex-1 flex items-center justify-center"><div class="w-[22px] h-[22px] border-2 border-[#2D2F3A] border-t-[#8B8D9A] rounded-full animate-spin"></div></div>
      {:else if listings.length === 0}
        <div class="flex-1 flex items-center justify-center text-[#50525E] text-[13px]">{localeStore.t('yellowpages_no_listings')}</div>
      {:else if filteredListings.length === 0}
        <div class="flex-1 flex items-center justify-center text-[#50525E] text-[13px]">{localeStore.t('yellowpages_no_results')}</div>
      {:else}
        {#each filteredListings as listing (listing.id)}
          <!-- svelte-ignore a11y_consider_explicit_label -->
          <button type="button" class="flex items-center gap-3 w-full text-left bg-[#1E2028] border border-[#2D2F3A] rounded-xl p-3 cursor-pointer transition-colors duration-150 shrink-0 hover:border-[#3A3D4A] hover:bg-[#252730]" onclick={() => openDetail(listing)}>
            {#if listing.imageUrl}
              <img class="w-12 h-12 rounded-lg object-cover shrink-0" src={listing.imageUrl} alt={listing.name} />
            {:else}
              {@render monogram(listing.name, 'w-12 h-12 text-lg')}
            {/if}
            <div class="flex-1 min-w-0 flex flex-col gap-1">
              <div class="flex items-center gap-2 flex-wrap">
                <span class="text-[#F0F0F5] text-[13px] font-semibold truncate">{listing.name}</span>
                {#if listing.isOwner && listing.status === 'pending'}
                  <span class="text-[10px] font-semibold text-[#E4A832] bg-[rgba(228,168,50,0.12)] py-[2px] px-[6px] rounded shrink-0">{localeStore.t('yellowpages_pending')}</span>
                {/if}
              </div>
              {#if listing.description}
                <span class="text-[#8B8D9A] text-[11px] truncate">{listing.description}</span>
              {/if}
              <div class="flex items-center gap-3 flex-wrap mt-[2px]">
                <div class="flex items-center gap-1">
                  {@render starRow(listing.avgRating)}
                  <span class="text-[#50525E] text-[11px] font-medium">({listing.reviewCount})</span>
                </div>
                {#if listing.phone}
                  <div class="flex items-center gap-1 py-[2px] px-[6px] bg-[#252730] rounded text-[#8B8D9A] text-[10px] font-medium">
                    <svg xmlns="http://www.w3.org/2000/svg" width="10" height="10" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M13.832 16.568a1 1 0 0 0 1.213-.303l.355-.465A2 2 0 0 1 17 15h3a2 2 0 0 1 2 2v3a2 2 0 0 1-2 2A18 18 0 0 1 2 4a2 2 0 0 1 2-2h3a2 2 0 0 1 2 2v3a2 2 0 0 1-.8 1.6l-.468.351a1 1 0 0 0-.292 1.233 14 14 0 0 0 6.392 6.384" /></svg>
                    <span>{listing.phone}</span>
                  </div>
                {/if}
              </div>
            </div>
          </button>
        {/each}
      {/if}
    </div>
  {:else if view === 'detail' && selected}
    <div class="flex items-center justify-between mb-3 shrink-0">
      <!-- svelte-ignore a11y_consider_explicit_label -->
      <button type="button" class="w-8 h-8 flex items-center justify-center bg-[#1E2028] border border-[#2D2F3A] rounded-lg text-[#8B8D9A] cursor-pointer transition-colors duration-150 hover:text-[#F0F0F5] hover:border-[#3A3D4A]" onclick={backToList}>
        <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="m12 19-7-7 7-7" /><path d="M19 12H5" /></svg>
      </button>

      {#if selected.isOwner}
        <div class="flex items-center gap-2">
          {#if listingDeleteConfirm}
            <span class="text-[#E55B5B] text-xs font-medium">{localeStore.t('yellowpages_delete_confirm')}</span>
            <!-- svelte-ignore a11y_consider_explicit_label -->
            <button type="button" class="w-7 h-7 flex items-center justify-center border border-[#2D2F3A] rounded-md cursor-pointer bg-none transition-colors duration-150 text-[#5BBD6B] hover:border-[#5BBD6B]" onclick={deleteListing}>
              <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M20 6 9 17l-5-5" /></svg>
            </button>
            <!-- svelte-ignore a11y_consider_explicit_label -->
            <button type="button" class="w-7 h-7 flex items-center justify-center border border-[#2D2F3A] rounded-md cursor-pointer bg-none transition-colors duration-150 text-[#8B8D9A] hover:text-[#E55B5B] hover:border-[#E55B5B]" onclick={() => { listingDeleteConfirm = false }}>
              <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M18 6 6 18" /><path d="m6 6 12 12" /></svg>
            </button>
          {:else}
            <!-- svelte-ignore a11y_consider_explicit_label -->
            <button type="button" class="flex items-center gap-1 py-[6px] px-3 text-xs font-medium text-[#8B8D9A] bg-none border border-[#2D2F3A] rounded-lg cursor-pointer transition-colors duration-150 hover:text-[#F0F0F5] hover:border-[#3A3D4A]" onclick={openEditForm}>
              <svg xmlns="http://www.w3.org/2000/svg" width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M21.174 6.812a1 1 0 0 0-3.986-3.986L3.842 16.174a2 2 0 0 0-.5.83l-1.321 4.352a.5.5 0 0 0 .623.622l4.353-1.32a2 2 0 0 0 .83-.497z" /><path d="m15 5 4 4" /></svg>
              {localeStore.t('yellowpages_edit')}
            </button>
            <!-- svelte-ignore a11y_consider_explicit_label -->
            <button type="button" class="flex items-center gap-1 py-[6px] px-3 text-xs font-medium text-[#8B8D9A] bg-none border border-[#2D2F3A] rounded-lg cursor-pointer transition-colors duration-150 hover:text-[#E55B5B] hover:border-[#E55B5B]" onclick={() => { listingDeleteConfirm = true }}>
              <svg xmlns="http://www.w3.org/2000/svg" width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 6h18" /><path d="M19 6v14c0 1-1 2-2 2H7c-1 0-2-1-2-2V6" /><path d="M8 6V4c0-1 1-2 2-2h4c1 0 2 1 2 2v2" /></svg>
              {localeStore.t('yellowpages_delete')}
            </button>
          {/if}
        </div>
      {/if}
    </div>

    <div class="flex-1 overflow-y-auto flex flex-col gap-3 min-h-0 lscrollbar">
      <div class="flex items-center gap-3 shrink-0">
        {#if selected.imageUrl}
          <img class="w-16 h-16 rounded-xl object-cover shrink-0" src={selected.imageUrl} alt={selected.name} />
        {:else}
          {@render monogram(selected.name, 'w-16 h-16 text-2xl')}
        {/if}
        <div class="flex flex-col gap-1 min-w-0">
          <span class="text-[#F0F0F5] font-bold text-base truncate">{selected.name}</span>
          <div class="flex items-center gap-2">
            {@render starRow(selected.avgRating, 14)}
            <span class="text-[#50525E] text-xs font-medium">{selected.reviewCount} {localeStore.t('yellowpages_rating_count')}</span>
          </div>
        </div>
      </div>

      {#if selected.phone}
        <div class="flex items-center gap-2 shrink-0">
          <svg class="text-[#8B8D9A]" xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M13.832 16.568a1 1 0 0 0 1.213-.303l.355-.465A2 2 0 0 1 17 15h3a2 2 0 0 1 2 2v3a2 2 0 0 1-2 2A18 18 0 0 1 2 4a2 2 0 0 1 2-2h3a2 2 0 0 1 2 2v3a2 2 0 0 1-.8 1.6l-.468.351a1 1 0 0 0-.292 1.233 14 14 0 0 0 6.392 6.384" /></svg>
          <span class="text-[#C8C9CF] text-[13px] font-medium">{selected.phone}</span>
          <!-- svelte-ignore a11y_consider_explicit_label -->
          <button
            type="button"
            class="py-1 px-[10px] text-[11px] font-semibold text-[#16171C] bg-[#E4A832] border-none rounded-md cursor-pointer transition-colors duration-150 {phoneCopied ? 'opacity-70' : 'hover:bg-[#C99527]'}"
            onclick={() => selected && copyPhone(selected.phone!)}
          >
            {localeStore.t('yellowpages_call')}
          </button>
        </div>
      {/if}

      {#if selected.description}
        <p class="text-[#8B8D9A] text-[13px] leading-[1.6] shrink-0">{selected.description}</p>
      {/if}

      <div class="flex flex-col gap-2 pt-3 border-t border-[#2D2F3A] shrink-0">
        <span class="text-[#F0F0F5] font-bold text-sm">{localeStore.t('yellowpages_reviews')}</span>

        {#if reviewsLoading}
          <div class="py-5 flex items-center justify-center"><div class="w-5 h-5 border-2 border-[#2D2F3A] border-t-[#8B8D9A] rounded-full animate-spin"></div></div>
        {:else}
          {#if !selected.isOwner}
            {#if ownReview}
              <div class="bg-[#1E2028] border border-[#2D2F3A] rounded-xl p-3 flex flex-col gap-2">
                <div class="flex items-center justify-between gap-2">
                  <span class="text-[#E4A832] text-xs font-semibold">{localeStore.t('yellowpages_already_reviewed')}</span>
                  {#if !editingOwnReview}
                    <div class="flex items-center gap-1">
                      {#if ownReviewDeleteConfirm}
                        <span class="text-[#E55B5B] text-[11px] font-medium">{localeStore.t('yellowpages_review_delete_confirm')}</span>
                        <!-- svelte-ignore a11y_consider_explicit_label -->
                        <button type="button" class="w-6 h-6 flex items-center justify-center border border-[#2D2F3A] rounded-md cursor-pointer bg-none transition-colors duration-150 text-[#5BBD6B] hover:border-[#5BBD6B]" onclick={deleteOwnReview}>
                          <svg xmlns="http://www.w3.org/2000/svg" width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M20 6 9 17l-5-5" /></svg>
                        </button>
                        <!-- svelte-ignore a11y_consider_explicit_label -->
                        <button type="button" class="w-6 h-6 flex items-center justify-center border border-[#2D2F3A] rounded-md cursor-pointer bg-none transition-colors duration-150 text-[#8B8D9A] hover:text-[#E55B5B] hover:border-[#E55B5B]" onclick={() => { ownReviewDeleteConfirm = false }}>
                          <svg xmlns="http://www.w3.org/2000/svg" width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M18 6 6 18" /><path d="m6 6 12 12" /></svg>
                        </button>
                      {:else}
                        <!-- svelte-ignore a11y_consider_explicit_label -->
                        <button type="button" class="w-6 h-6 flex items-center justify-center text-[#8B8D9A] bg-none border border-[#2D2F3A] rounded-md cursor-pointer transition-colors duration-150 hover:text-[#F0F0F5] hover:border-[#3A3D4A]" onclick={() => startEditOwnReview(ownReview!)}>
                          <svg xmlns="http://www.w3.org/2000/svg" width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M21.174 6.812a1 1 0 0 0-3.986-3.986L3.842 16.174a2 2 0 0 0-.5.83l-1.321 4.352a.5.5 0 0 0 .623.622l4.353-1.32a2 2 0 0 0 .83-.497z" /><path d="m15 5 4 4" /></svg>
                        </button>
                        <!-- svelte-ignore a11y_consider_explicit_label -->
                        <button type="button" class="w-6 h-6 flex items-center justify-center text-[#8B8D9A] bg-none border border-[#2D2F3A] rounded-md cursor-pointer transition-colors duration-150 hover:text-[#E55B5B] hover:border-[#E55B5B]" onclick={() => { ownReviewDeleteConfirm = true }}>
                          <svg xmlns="http://www.w3.org/2000/svg" width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 6h18" /><path d="M19 6v14c0 1-1 2-2 2H7c-1 0-2-1-2-2V6" /><path d="M8 6V4c0-1 1-2 2-2h4c1 0 2 1 2 2v2" /></svg>
                        </button>
                      {/if}
                    </div>
                  {/if}
                </div>

                {#if editingOwnReview}
                  {@render ratingPicker(editRating, 18, (n) => editRating = n)}
                  <label class="sr-only" for="yp-edit-comment">{localeStore.t('yellowpages_review_comment_placeholder')}</label>
                  <textarea id="yp-edit-comment" class="bg-[#252730] border border-[#2D2F3A] rounded-lg text-[#F0F0F5] text-[13px] py-2 px-[10px] outline-none font-inherit transition-colors duration-150 focus:border-[#E4A832] resize-y min-h-[60px]" bind:value={editComment} rows="3" maxlength="300" placeholder={localeStore.t('yellowpages_review_comment_placeholder')}></textarea>
                  {#if editError}
                    <span class="text-[#E55B5B] text-xs font-medium">{editError}</span>
                  {/if}
                  <div class="flex items-center gap-2">
                    <button type="button" class="py-[6px] px-3 text-xs font-bold text-[#16171C] bg-[#E4A832] border-none rounded-lg cursor-pointer transition-colors duration-150 enabled:hover:bg-[#C99527] disabled:opacity-50 disabled:cursor-default" onclick={submitEditOwnReview} disabled={editRating < 1 || editSubmitting}>
                      {localeStore.t('yellowpages_save')}
                    </button>
                    <button type="button" class="py-[6px] px-3 text-xs font-semibold text-[#8B8D9A] bg-none border border-[#2D2F3A] rounded-lg cursor-pointer transition-colors duration-150 hover:text-[#F0F0F5] hover:border-[#3A3D4A]" onclick={() => { editingOwnReview = false }}>
                      {localeStore.t('yellowpages_cancel')}
                    </button>
                  </div>
                {:else}
                  {@render starRow(ownReview.rating, 14)}
                  {#if ownReview.comment}
                    <p class="text-[#8B8D9A] text-xs leading-[1.5]">{ownReview.comment}</p>
                  {/if}
                {/if}
              </div>
            {:else}
              <div class="bg-[#1E2028] border border-[#2D2F3A] rounded-xl p-3 flex flex-col gap-2">
                <span class="text-[#8B8D9A] text-xs font-semibold">{localeStore.t('yellowpages_write_review')}</span>
                {@render ratingPicker(reviewRating, 22, (n) => reviewRating = n)}
                <label class="sr-only" for="yp-new-comment">{localeStore.t('yellowpages_review_comment_placeholder')}</label>
                <textarea id="yp-new-comment" class="bg-[#252730] border border-[#2D2F3A] rounded-lg text-[#F0F0F5] text-[13px] py-2 px-[10px] outline-none font-inherit transition-colors duration-150 focus:border-[#E4A832] resize-y min-h-[60px]" bind:value={reviewComment} rows="3" maxlength="300" placeholder={localeStore.t('yellowpages_review_comment_placeholder')}></textarea>
                {#if reviewFormError}
                  <span class="text-[#E55B5B] text-xs font-medium">{reviewFormError}</span>
                {/if}
                <button type="button" class="py-[6px] px-3 text-xs font-bold text-[#16171C] bg-[#E4A832] border-none rounded-lg cursor-pointer transition-colors duration-150 self-start enabled:hover:bg-[#C99527] disabled:opacity-50 disabled:cursor-default" onclick={submitReview} disabled={reviewRating < 1 || reviewSubmitting}>
                  {localeStore.t('yellowpages_submit_review')}
                </button>
              </div>
            {/if}
          {/if}

          {#each otherReviews as review (review.id)}
            <div class="bg-[#1E2028] border border-[#2D2F3A] rounded-xl p-3 flex flex-col gap-1">
              <div class="flex items-center justify-between gap-2">
                <span class="text-[#F0F0F5] text-xs font-semibold truncate">{review.username}</span>
                {#if selected.isOwner}
                  {#if review.reported}
                    <span class="text-[10px] text-[#50525E] font-semibold shrink-0">{localeStore.t('yellowpages_reported')}</span>
                  {:else}
                    <!-- svelte-ignore a11y_consider_explicit_label -->
                    <button type="button" class="flex items-center gap-1 text-[#8B8D9A] text-[10px] font-semibold bg-none border-none cursor-pointer shrink-0 transition-colors duration-150 hover:text-[#E55B5B]" onclick={() => reportReview(review)}>
                      <svg xmlns="http://www.w3.org/2000/svg" width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M4 15s1-1 4-1 5 2 8 2 4-1 4-1V3s-1 1-4 1-5-2-8-2-4 1-4 1z" /><line x1="4" x2="4" y1="22" y2="15" /></svg>
                      {localeStore.t('yellowpages_report')}
                    </button>
                  {/if}
                {/if}
              </div>
              {@render starRow(review.rating, 12)}
              {#if review.comment}
                <p class="text-[#8B8D9A] text-xs leading-[1.5]">{review.comment}</p>
              {/if}
            </div>
          {/each}

          {#if reviews.length === 0}
            <div class="text-[#50525E] text-[13px] text-center py-4">{localeStore.t('yellowpages_no_reviews')}</div>
          {/if}
        {/if}
      </div>
    </div>
  {:else if view === 'form'}
    <div class="flex items-center justify-between mb-4 shrink-0">
      <!-- svelte-ignore a11y_consider_explicit_label -->
      <button type="button" class="w-8 h-8 flex items-center justify-center bg-[#1E2028] border border-[#2D2F3A] rounded-lg text-[#8B8D9A] cursor-pointer transition-colors duration-150 hover:text-[#F0F0F5] hover:border-[#3A3D4A]" onclick={cancelForm}>
        <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="m12 19-7-7 7-7" /><path d="M19 12H5" /></svg>
      </button>
      <span class="text-[#F0F0F5] font-bold text-base">{formMode === 'edit' ? localeStore.t('yellowpages_edit') : localeStore.t('yellowpages_new_listing')}</span>
      <div class="w-8"></div>
    </div>

    <div class="flex-1 overflow-y-auto flex flex-col gap-3 min-h-0 lscrollbar">
      <div class="flex flex-col gap-1">
        <label class="text-[#8B8D9A] text-xs font-semibold" for="yp-name">{localeStore.t('yellowpages_field_name')}</label>
        <input id="yp-name" type="text" class="bg-[#252730] border border-[#2D2F3A] rounded-lg text-[#F0F0F5] text-[13px] py-2 px-[10px] outline-none font-inherit transition-colors duration-150 focus:border-[#E4A832]" bind:value={formName} maxlength="60" />
      </div>
      <div class="flex flex-col gap-1">
        <label class="text-[#8B8D9A] text-xs font-semibold" for="yp-description">{localeStore.t('yellowpages_field_description')}</label>
        <textarea id="yp-description" class="bg-[#252730] border border-[#2D2F3A] rounded-lg text-[#F0F0F5] text-[13px] py-2 px-[10px] outline-none font-inherit transition-colors duration-150 focus:border-[#E4A832] resize-y min-h-[70px]" bind:value={formDescription} rows="4" maxlength="500"></textarea>
      </div>
      <div class="flex flex-col gap-1">
        <label class="text-[#8B8D9A] text-xs font-semibold" for="yp-phone">{localeStore.t('yellowpages_field_phone')}</label>
        <input id="yp-phone" type="text" class="bg-[#252730] border border-[#2D2F3A] rounded-lg text-[#F0F0F5] text-[13px] py-2 px-[10px] outline-none font-inherit transition-colors duration-150 focus:border-[#E4A832]" bind:value={formPhone} maxlength="32" />
      </div>
      <div class="flex flex-col gap-1">
        <label class="text-[#8B8D9A] text-xs font-semibold" for="yp-image">{localeStore.t('yellowpages_field_image')}</label>
        <input id="yp-image" type="text" class="bg-[#252730] border border-[#2D2F3A] rounded-lg text-[#F0F0F5] text-[13px] py-2 px-[10px] outline-none font-inherit transition-colors duration-150 focus:border-[#E4A832]" bind:value={formImageUrl} placeholder="https://..." />
      </div>
      {#if formError}
        <span class="text-[#E55B5B] text-xs font-medium">{formError}</span>
      {/if}
      <div class="flex items-center gap-2 mt-1">
        <button
          type="button"
          class="flex-1 py-[10px] text-[13px] font-bold text-[#16171C] bg-[#E4A832] border-none rounded-lg cursor-pointer transition-colors duration-150 enabled:hover:bg-[#C99527] disabled:opacity-50 disabled:cursor-default"
          onclick={submitListingForm}
          disabled={!formName.trim() || formSubmitting}
        >
          {localeStore.t('yellowpages_save')}
        </button>
        <button
          type="button"
          class="py-[10px] px-4 text-[13px] font-semibold text-[#8B8D9A] bg-none border border-[#2D2F3A] rounded-lg cursor-pointer transition-colors duration-150 hover:text-[#F0F0F5] hover:border-[#3A3D4A]"
          onclick={cancelForm}
        >
          {localeStore.t('yellowpages_cancel')}
        </button>
      </div>
    </div>
  {/if}
</div>
