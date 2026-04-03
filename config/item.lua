return {
    -- Useable item, can be `false` to disable it
    item = 'laptop',

    slots = 10,
    weight = 1000,

    attachment = {
        animation = {
            dict = 'amb@code_human_in_bus_passenger_idles@female@tablet@idle_a',
            name = 'idle_a',
            flag = 49,
        },
        model = 'prop_tablet_facade',
        bone = 28422,
        coords = {
            position = vector3(-0.05, 0.0, 0.0),
            rotation = vector3(0.0, -90.0, 0.0),
        }
    }
}
--  laptop model
-- attachment = {
--     animation = {
--         dict = 'missheistdockssetup1clipboard@base',
--         name = 'base',
--         flag = 49,
--     },
--     model = 'prop_laptop_facade',
--     bone = 42,
--     coords = {
--         position = vector3(0.10, 0.15, 0.07),
--         rotation = vector3(10.0, 0.0, 0.0),
--     }
-- }
