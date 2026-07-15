export interface MockListing {
  id: number
  name: string
  description?: string
  phone?: string
  imageUrl?: string
  status: string
  isOwner: boolean
  avgRating: number
  reviewCount: number
}

export interface MockReview {
  id: number
  rating: number
  comment?: string
  username: string
  isOwn: boolean
  reported: boolean
}

export const MockListings: MockListing[] = [
  { id: 1, name: "Benny's Motorworks", description: 'Custom rides, tuning, and repairs. Fast turnaround, fair prices.', phone: '555-0142', status: 'approved', isOwner: false, avgRating: 4.5, reviewCount: 12 },
  { id: 2, name: 'Pillbox Pharmacy', description: 'Prescriptions, first aid, and wellness supplies in the heart of the city.', phone: '555-0199', status: 'approved', isOwner: false, avgRating: 3.8, reviewCount: 6 },
  { id: 3, name: 'Sandy Shores Towing', description: '24/7 towing and roadside recovery across Blaine County.', phone: '555-0177', status: 'approved', isOwner: true, avgRating: 5, reviewCount: 3 },
  { id: 4, name: 'The Tequila Nightclub', description: 'Bottle service, live DJs, and the best nights in Los Santos.', phone: '555-0121', status: 'approved', isOwner: false, avgRating: 4.1, reviewCount: 21 },
  { id: 5, name: 'My New Detailing Shop', description: 'Just opened, awaiting listing approval.', phone: '555-0100', status: 'pending', isOwner: true, avgRating: 0, reviewCount: 0 }
]

export const MockReviews: MockReview[] = [
  { id: 1, rating: 5, comment: 'Fixed my Sultan overnight, runs like new.', username: 'Marcus Reyes', isOwn: false, reported: false },
  { id: 2, rating: 4, comment: 'Good work, a little pricey but worth it.', username: 'Dana Whitmore', isOwn: true, reported: false },
  { id: 3, rating: 2, comment: 'Waited two hours past my appointment.', username: 'Klausas Petrauskas', isOwn: false, reported: true }
]
