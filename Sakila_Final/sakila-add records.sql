insert into dbo.country(country)
values ('El Salvador')

insert into dbo.city(city, country_id)
values ('San Salvador',
        110)

insert into dbo.category(name)
values ('Thriller')

insert into dbo.language(name)
values ('Korean')

insert into dbo.film(title,
                     description,
                     release_year,
                     language_id,
                     original_language_id,
                     rental_duration,
                     rental_rate,
                     length,
                     replacement_cost,
                     rating,
                     special_features,
                     last_update)
values ('PARASITE',
        'A poor family, the Kims, con their way into becoming the servants of a rich family, the Parks. ' +
        'But their easy life gets complicated when their deception is threatened with exposure.',
        2019,
        7,
        7,
        3,
        4.99,
        132,
        20.99,
        'R',
        'Trailers',
        getdate())

insert into dbo.store(manager_staff_id, address_id)
values (2,
        1)

insert into dbo.customer(store_id,
                         first_name,
                         last_name,
                         email,
                         address_id,
                         active,
                         create_date,
                         last_update)
values (1,
        'André',
        'Araujo',
        'aaraujo@my.wctc.edu',
        5,
        1,
        getdate(),
        getdate())

update dbo.customer
set first_name = 'ANDRÉ',
    last_name  = 'ARAUJO',
    address_id = 100
where customer_id = 601

insert into dbo.rental(rental_date,
                       inventory_id,
                       customer_id,
                       return_date,
                       staff_id,
                       last_update)
values ('2020-4-12',
        2,
        601,
        '2020-4-15',
        1,
        getdate())

select *
from dbo.rental r
         left join SakilaDW_AGA.dbo.DimDate ddrent on cast(r.rental_date as date) = ddrent.Date
where rental_id = 16050


dbcc checkident ('FactRental', reseed, 0)

insert into dbo.payment(customer_id,
                        staff_id,
                        rental_id,
                        amount,
                        payment_date)
values (601,
        1,
        16050,
        4.99,
        '2020-4-12')



insert into dbo.rental(rental_date,
                       inventory_id,
                       customer_id,
                       return_date,
                       staff_id,
                       last_update)
values ('2020-4-16',
        2,
        601,
        '2020-4-17',
        1,
        getdate())

insert into dbo.payment(customer_id,
                        staff_id,
                        rental_id,
                        amount,
                        payment_date)
values (601,
        1,
        16051,
        4.99,
        '2020-4-16')