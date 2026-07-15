RegisterNUICallback('yellowpagesGetListings', function(data, cb)
    cb(lib.callback.await('fd_laptop:server:yellowpagesGetListings', false, data))
end)

RegisterNUICallback('yellowpagesCreateListing', function(data, cb)
    cb(lib.callback.await('fd_laptop:server:yellowpagesCreateListing', false, data))
end)

RegisterNUICallback('yellowpagesUpdateListing', function(data, cb)
    cb(lib.callback.await('fd_laptop:server:yellowpagesUpdateListing', false, data))
end)

RegisterNUICallback('yellowpagesDeleteListing', function(data, cb)
    cb(lib.callback.await('fd_laptop:server:yellowpagesDeleteListing', false, data))
end)

RegisterNUICallback('yellowpagesGetReviews', function(data, cb)
    cb(lib.callback.await('fd_laptop:server:yellowpagesGetReviews', false, data))
end)

RegisterNUICallback('yellowpagesCreateReview', function(data, cb)
    cb(lib.callback.await('fd_laptop:server:yellowpagesCreateReview', false, data))
end)

RegisterNUICallback('yellowpagesUpdateReview', function(data, cb)
    cb(lib.callback.await('fd_laptop:server:yellowpagesUpdateReview', false, data))
end)

RegisterNUICallback('yellowpagesDeleteReview', function(data, cb)
    cb(lib.callback.await('fd_laptop:server:yellowpagesDeleteReview', false, data))
end)

RegisterNUICallback('yellowpagesReportReview', function(data, cb)
    cb(lib.callback.await('fd_laptop:server:yellowpagesReportReview', false, data))
end)
